fs = require 'fs-extra'
path = require 'path'
Q = require 'q'
ProgressView = require '../utils/progress-view'
download = require '../utils/download'
unzip = require '../utils/unzip'

butterflyURL = "https://github.com/yezhiming/butterfly/archive/master.zip"

fsremove = Q.denodeify fs.remove

module.exports =
class PackageManager

  activate: ->
    atom.workspaceView.command "atom-chameleon:install", => @cmdInstall()

  deactivate: ->

  cmdInstall: ->

    pv = new ProgressView("Install Butterfly.js...")
    
    # 检测是否存在网络
    (require "../../utils/checkNetwork")("http", "http://www.baidu.com")
    .then =>
      pv.attach()
      @installFramework()
    .progress (progress)->
      pv.setTitle(progress.message) if progress.message
      pv.setProgress(progress.progress) if progress.progress
    .catch (err) ->
      alert "#{err}"
      console.trace err.stack
    .finally ->
      pv.destroy()

  installFramework: (installToPath = atom.project.path)->

    targetFolder = path.resolve(installToPath, 'butterfly')
    targetZipFile = path.resolve(installToPath, 'butterfly.zip')

    #flow
    fsremove(targetZipFile)
    .then -> download(butterflyURL, targetZipFile)
    .then -> fsremove(targetFolder)
    .then -> unzip(targetZipFile, targetFolder)
    .then -> fsremove(targetZipFile)
    #proxy the downloadPromise, transfer the indeterminate progress into message progress
    .progress (progress) ->
      if progress.indeterminate
        'message': "Download butterfly.js...(#{progress.indeterminate / 1000}k)"
      else
        progress
