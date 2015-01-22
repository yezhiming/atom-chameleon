fs = require 'fs'
request = require 'request'
Q = require 'q'
localPort = require 'local-port'


module.exports =
class BuildManager

  activate: ->
    atom.workspaceView.command "atom-chameleon:run-on-server", => @cmdRunOnServer()
    atom.workspaceView.command "atom-chameleon:emulator", (data, httpPort) => @cmdLaunchEmulator(data, httpPort)
    @_setupDebugServer()

  deactivate: ->
    @runOnServerView?.destroy()
    @serverStatusView?.destroy()

    for i of @debugServer
      if @debugServer.hasOwnProperty(i)
        @debugServer[i]?.stop()

  _setupDebugServer: ->

    unless @serverStatusView and @debugServer and @emulatorView
      EmulatorView = require './emulator-view'
      @emulatorView = new EmulatorView()

      @serverStatusView = {}
      @debugServer = {}

      # ServerStatusView = require './server-status-view'
      # @serverStatusView = new ServerStatusView()
      # @serverStatusView.on 'stopServer', => @debugServer.stop()
      #
      # DebugServer = require './debug-server'
      # @debugServer = new DebugServer()
      # @debugServer.on 'start', => @serverStatusView.attach()
      # @debugServer.on 'stop', => @serverStatusView.destroy()


  cmdRunOnServer: ->
    RunOnServerView = require './run-on-server-view'
    @runOnServerView = new RunOnServerView()
    @runOnServerView.attach()
    @runOnServerView.on 'createServer', (event, rootPath, destPath, httpPort, pushState, api) =>
      # 开启debug server
      localPort.isPortTaken httpPort, (err, taken) =>
        if err
          console.error err
        else if taken
          alert "port:#{httpPort} in use, retrying..."
        else
          # 每个debugServer都有自己的状态栏和express调试服务
          DebugServer = require './debug-server'
          debugServer = new DebugServer()

          ServerStatusView = require './server-status-view'
          serverStatusView = new ServerStatusView()

          serverStatusView.on 'stopServer', => # 关闭状态栏后关闭debugServer
            debugServer.stop (httpPort) =>
              delete @serverStatusView["p#{httpPort}"]
              delete @debugServer["p#{httpPort}"]

          debugServer.on 'start', => serverStatusView.attach()
          debugServer.on 'stop', => serverStatusView.destroy()

          # 绑定debugServer、serverStatusView
          @debugServer["p#{httpPort}"] = debugServer
          @serverStatusView["p#{httpPort}"] = serverStatusView

          debugServer.start
            rootPath: rootPath
            defaultPage: destPath
            httpPort: httpPort
            pushState: pushState
            api: api


  cmdLaunchEmulator: (data, httpPort) ->
    # data.cancelable: true 表示没传httpPort，即快捷键打开
    if Object.keys(@debugServer).length is 0
      return alert "please launch debug server."
    else if !(typeof @debugServer["p#{httpPort}"] is 'undefined') and typeof @debugServer["p#{httpPort}"].offline() is 'undefined'
      return alert "please launch debug server."

    if !(typeof @debugServer["p#{httpPort}"] is 'undefined') and @debugServer["p#{httpPort}"].offline() and @emulatorView.isHidden()
      console.log 'webview 已经隐藏了不需要展开.'
      if @debugServer["p#{httpPort}"].closeServer is "after"
        alert "please launch debug server."
    else
      @emulatorView.toggle()
