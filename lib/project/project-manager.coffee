fs = require 'fs-extra'
path = require 'path'
Q = require 'q'
ProgressView = require '../utils/progress-view'
download = require '../utils/download'
unzip = require '../utils/unzip'

butterflyURL = "https://github.com/yezhiming/butterfly/archive/master.zip"

module.exports =
class PackageManager

  activate: ->
    atom.workspaceView.command "atom-butterfly:create-package", => @cmdCreatePackage()
    atom.workspaceView.command "atom-butterfly:install", => @cmdInstall()

  deactivate: ->

  cmdInstall: ->

    pv = new ProgressView("Install Butterfly.js...")
    pv.attach()

    @installFramework()
    .progress (progress)->
      pv.setTitle(progress.message) if progress.message
      pv.setProgress(progress.progress) if progress.progress
    .then ->
      pv.destroy()
    .catch (err) ->
      alert "err: #{err}"
      console.trace err.stack

  installFramework: (installToPath = atom.project.path)->

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
