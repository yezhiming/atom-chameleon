rimraf = require 'rimraf'
fs = require 'fs-plus'
path = require 'path'
mkdirp = require 'mkdirp'

remote = require 'remote'
dialog = remote.require 'dialog'

DebugServer = require './debug-server'
scaffolder = require './scaffold'
Downloader = require './utils/download'
Unzip = require './utils/unzip'

ProgressView = require './progress-view'
RunOnServerView = require './run-on-server-view'
ServerStatusView = require './server-status-view'

butterflyURL = "https://github.com/yezhiming/butterfly/archive/master.zip"

module.exports =

  activate: (state) ->
    atom.workspaceView.command "atom-butterfly:install", => @cmdInstall()
    atom.workspaceView.command "atom-butterfly:debug", => @cmdDebug()

    atom.workspaceView.command "atom-butterfly:create-project", => @cmdCreateProject()
    atom.workspaceView.command "atom-butterfly:run-on-server", => @cmdRunOnServer()

    @_setupDebugServer()

  _setupDebugServer: ->
    @serverStatusView = new ServerStatusView()
    @serverStatusView.on 'stopServer', => @debugServer.stop()

    @debugServer = new DebugServer()
    @debugServer.on 'start', => @serverStatusView.attach()
    @debugServer.on 'stop', => @serverStatusView.detach()

  deactivate: ->
    @runOnServerView.destroy()
    @serverStatusView.destroy()

    @debugServer.stop()

  serialize: ->

  cmdDebug: ->

  cmdCreateProject: ->
    dialog.showSaveDialog title: 'Create Project', defaultPath: atom.project.path, (destPath) =>

      return unless destPath
      console.log 'save to : %s', destPath

      mkdirp destPath, =>
        @cmdInstall destPath, ->
          atom.open {pathsToOpen: [destPath]}

  cmdRunOnServer: ->
    @runOnServerView = new RunOnServerView()
    @runOnServerView.attach()
    @runOnServerView.on 'createServer', (event, rootPath, destPath, httpPort, pushState)=>
      @debugServer.start(rootPath, destPath, httpPort, pushState)

  cmdInstall: (installToPath = atom.project.path, onFinish)->

    pv = new ProgressView(this)
    pv.attach()
    pv.setTitle("Download butterfly.js...")

    targetFolder = path.resolve(installToPath, 'butterfly')
    targetZipFile = path.resolve(installToPath, 'butterfly.zip')

    rimraf targetZipFile, =>

      Downloader.download(butterflyURL, targetZipFile)
      .on 'progress', ->
        pv.setProgress(progress)
      .on 'finish', =>
        rimraf targetFolder, =>

          pv.setTitle("Unzip...")
          Unzip.unzip targetZipFile, installToPath, =>

            fs.unlink targetZipFile, ->
              pv.destroy()
              onFinish()
