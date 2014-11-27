{EventEmitter} = require 'events'

path = require 'path'
fs = require 'fs-plus'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'
ncp = require 'ncp'

Q = require 'q'

Downloader = require './utils/download'
Unzip = require './utils/unzip'

butterflyURL = "https://github.com/yezhiming/butterfly/archive/master.zip"

module.exports =
  createProjectPromise: (options)->

    destPath = path.resolve options.path, options.name
    packagePath = atom.packages.getActivePackage('atom-butterfly').path
    scaffoldPath = "#{packagePath}/scaffold"

    #promises
    copyProject = -> Q.nfcall(ncp, "#{scaffoldPath}/butterfly-project", destPath)
    copyRatchet = -> Q.nfcall(ncp, "#{scaffoldPath}/ratchet", "#{destPath}/ratchet") if options.ratchet
    copyBootstrap = -> Q.nfcall(ncp, "#{scaffoldPath}/bootstrap", "#{destPath}/bootstrap") if options.bootstrap
    installFramework = -> module.exports.installFrameworkPromise(destPath)

    #flow
    copyProject()
    .then copyRatchet
    .then copyBootstrap
    .then installFramework
    .then -> Q(destPath) #report project path

  installFrameworkPromise: (installToPath = atom.project.path)->

    targetFolder = path.resolve(installToPath, 'butterfly')
    targetZipFile = path.resolve(installToPath, 'butterfly.zip')

    #promises
    deleteZip = -> Q.nfcall(rimraf, targetZipFile)
    deleteFramework = -> Q.nfcall(rimraf, targetFolder)
    unzipFramework = -> Unzip.unzipPromise(targetZipFile, installToPath)
    downloadZip = ->
      #proxy the downloadPromise, transfer the indeterminate progress into message progress
      Q.Promise (resolve, reject, notify) ->
        Downloader.downloadPromise(butterflyURL, targetZipFile)
        .then resolve, reject, (progress) ->
          if progress.indeterminate
            notify 'message': "Download butterfly.js...(#{progress / 1000}k)"
          else
            notify progress

    #flow
    deleteZip()
    .then downloadZip
    .then deleteFramework
    .then unzipFramework
    .then deleteZip

  createProject: (options)->

    events = new EventEmitter()

    destPath = path.resolve options.path, options.name
    packagePath = atom.packages.getActivePackage('atom-butterfly').path
    scaffoldPath = "#{packagePath}/scaffold"

    fs.copy "#{scaffoldPath}/butterfly-project", destPath, =>
      @installFramework destPath
      .on 'message', (message) -> events.emit 'message', message
      .on 'progress', (progress) -> events.emit 'progress', progress
      .on 'finish', ->

        queue = new SequenceTaskQueue()

        if options.ratchet
          queue.add (next)->
            fs.copy "#{scaffoldPath}/ratchet", "#{destPath}/ratchet", ->
              next()

        if options.bootstrap
          queue.add (next)->
            fs.copy "#{scaffoldPath}/bootstrap", "#{destPath}/bootstrap", =>

        queue.execute().on 'finish', ->
          events.emit 'finish'

    return events

  installFramework: (installToPath = atom.project.path)->

    events = new EventEmitter()

    targetFolder = path.resolve(installToPath, 'butterfly')
    targetZipFile = path.resolve(installToPath, 'butterfly.zip')

    rimraf targetZipFile, =>

      events.emit 'message', "Download butterfly.js..."
      Downloader.download(butterflyURL, targetZipFile)
      .on 'progress', (progress) ->
        events.emit 'progress', progress
      .on 'indeterminate', (received) ->
        events.emit 'message', "Download butterfly.js...(#{received / 1000}k)"
      .on 'finish', ->
        rimraf targetFolder, ->

          events.emit 'message', "Unzip..."
          Unzip.unzip(targetZipFile, installToPath).on 'finish', ->

            fs.unlink targetZipFile, ->
              events.emit 'message', "Finish."
              events.emit 'finish'

    return events
