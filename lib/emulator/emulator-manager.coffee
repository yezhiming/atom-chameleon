fs = require 'fs'
request = require 'request'
Q = require 'q'

module.exports =
class BuildManager

  activate: ->
    atom.workspaceView.command "atom-chameleon:run-on-server", => @cmdRunOnServer()
    atom.workspaceView.command "atom-chameleon:emulator", => @cmdLaunchEmulator()

  deactivate: ->
    @runOnServerView?.destroy()
    @serverStatusView?.destroy()

    @debugServer?.stop()

  cmdRunOnServer: ->

    @_setupDebugServer()

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

    unless @serverStatusView
      ServerStatusView = require './server-status-view'
      @serverStatusView = new ServerStatusView()
      @serverStatusView.on 'stopServer', => @debugServer.stop()

    unless @debugServer
      DebugServer = require './debug-server'
      @debugServer = new DebugServer()
      @debugServer.on 'start', => @serverStatusView.attach()
      @debugServer.on 'stop', => @serverStatusView.detach()

  cmdLaunchEmulator: ->
    unless @debugServer
      DebugServer = require './debug-server'
      @debugServer = new DebugServer()
      @debugServer.on 'start', => @serverStatusView.attach()
      @debugServer.on 'stop', => @serverStatusView.detach()

    if typeof @debugServer.offline() is 'undefined'
      return alert "please launch debug server."

    unless @emulatorView?
      EmulatorView = require './emulator-view'
      @emulatorView = new EmulatorView()
    # 如果webview没有隐藏 或 debug server开启
    unless @debugServer.offline() and @emulatorView.isHidden()
      @emulatorView.toggle()

    if @debugServer.offline()
      console.log '回收debugServer.'
      @debugServer = null
