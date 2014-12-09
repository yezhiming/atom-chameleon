{EventEmitter} = require 'events'

path = require 'path'
fs = require 'fs-extra'

Q = require 'q'

download = require '../utils/download'
unzip = require '../utils/unzip'

butterflyURL = "https://github.com/yezhiming/butterfly/archive/master.zip"

module.exports =
  createProjectPromise: (options)->

    destPath = path.resolve options.path, options.name
    packagePath = atom.packages.getActivePackage('atom-butterfly').path
    scaffoldPath = "#{packagePath}/scaffold"

    #promises
    copyProject = -> Q.nfcall(fs.copy, "#{scaffoldPath}/butterfly-project", destPath)
    copyRatchet = -> Q.nfcall(fs.copy, "#{scaffoldPath}/ratchet", "#{destPath}/ratchet") if options.ratchet
    copyBootstrap = -> Q.nfcall(fs.copy, "#{scaffoldPath}/bootstrap", "#{destPath}/bootstrap") if options.bootstrap
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
    deleteZip = -> Q.nfcall(fs.remove, targetZipFile)
    deleteFramework = -> Q.nfcall(fs.remove, targetFolder)
    unzipFramework = -> unzip(targetZipFile, installToPath)
    downloadZip = ->
      #proxy the downloadPromise, transfer the indeterminate progress into message progress
      Q.Promise (resolve, reject, notify) ->
        download(butterflyURL, targetZipFile)
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
