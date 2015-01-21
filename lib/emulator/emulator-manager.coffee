fs = require 'fs'
request = require 'request'
Q = require 'q'

module.exports =
class BuildManager

  activate: ->
    atom.workspaceView.command "atom-chameleon:run-on-server", => @cmdRunOnServer()
    atom.workspaceView.command "atom-chameleon:emulator", => @cmdLaunchEmulator()
    @_setupDebugServer()

  deactivate: ->
    @runOnServerView?.destroy()
    @serverStatusView?.destroy()

    @debugServer?.stop()

  cmdRunOnServer: ->
    RunOnServerView = require './run-on-server-view'
    @runOnServerView = new RunOnServerView()
    @runOnServerView.attach()
    @runOnServerView.on 'createServer', (event, rootPath, destPath, httpPort, pushState, api)=>
      @debugServer.start {
        rootPath: rootPath
        defaultPage: destPath
        httpPort: httpPort
        pushState: pushState
        api: api
      }

  _setupDebugServer: ->
    unless @serverStatusView and @debugServer
      ServerStatusView = require './server-status-view'
      @serverStatusView = new ServerStatusView()
      @serverStatusView.on 'stopServer', => @debugServer.stop()

      
      DebugServer = require './debug-server'
      @debugServer = new DebugServer()
      @debugServer.on 'start', => @serverStatusView.attach()
      @debugServer.on 'stop', => @serverStatusView.detach()

  cmdLaunchEmulator: ->

    if typeof @debugServer.offline() is 'undefined'
      return alert "please launch debug server."

    if typeof @emulatorView is 'undefined' and (!@debugServer.offline())
      EmulatorView = require './emulator-view'
      @emulatorView = new EmulatorView()
    else if @debugServer.offline() and @emulatorView.isHidden()
      if @debugServer.closeServer is "after"
        alert "please launch debug server."
    else
      @emulatorView.toggle()
