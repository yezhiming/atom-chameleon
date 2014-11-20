remote = require 'remote'
dialog = remote.require 'dialog'

DebugServer = require './debug-server'
Scaffolder = require './scaffold'
Downloader = require './utils/download'
Unzip = require './utils/unzip'

ProgressView = require './progress-view'
RunOnServerView = require './run-on-server-view'
ServerStatusView = require './server-status-view'

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

      pv = new ProgressView(this)
      pv.attach()

      Scaffolder.createProject(destPath)
      .on 'message', (message) ->
        pv.setTitle(message)
      .on 'progress', (progress) ->
        pv.setProgress(progress)
      .on 'finish', ->
        pv.destroy()
        atom.open {pathsToOpen: [destPath]}

  cmdInstall: ->

    pv = new ProgressView(this)
    pv.attach()

    Scaffolder.installFramework()
    .on 'message', (message) ->
      pv.setTitle(message)
    .on 'progress', (progress) ->
      pv.setProgress(progress)
    .on 'finish', ->
      pv.destroy()

  cmdRunOnServer: ->
    @runOnServerView = new RunOnServerView()
    @runOnServerView.attach()
    @runOnServerView.on 'createServer', (event, rootPath, destPath, httpPort, pushState)=>
      @debugServer.start(rootPath, destPath, httpPort, pushState)
