{EventEmitter} = require 'events'

path = require 'path'
fs = require 'fs-plus'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'
ncp = require 'ncp'

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
