{EventEmitter} = require 'events'
path = require 'path'
fs = require 'fs'
_ = require 'underscore'

{allowUnsafeEval, allowUnsafeNewFunction} = require 'loophole'
express = allowUnsafeEval -> require 'express'
# logger = require 'morgan'
bodyParser = allowUnsafeEval -> require 'body-parser'

HttpProxy = require './proxy-middleware'

module.exports =
class DebugServer extends EventEmitter

  #
  # params:
  #   rootPath
  #   pushState
  #   defaultPage
  #   httpPort
  #
  start: (options) ->
    @lineoff = false
    app = express()
    # app.use logger('dev')

    if options.pushState
      app.get '*', (req, res) ->
        console.log "http server get #{req.path}, with pushState"
        fs.exists path.resolve(options.rootPath, req.path), (exists) ->
          if exists
            res.sendFile path.resolve(options.defaultPage)
          else
            res.send 404
    else
      # NOTE1: redirect to index.html, but express just works without it, -_-
      app.get '/', (req, res) ->
        console.log "http server get '/', without pushState"
        res.redirect path.relative options.rootPath, options.defaultPage

    if options.api
      api = allowUnsafeEval -> require options.api
      api(app)

    # 2333 resolve NOTE1 express static middleware default active.  -> "/" mapping index.html
    app.use express.static path.resolve options.rootPath

    # proxy to chameloen-paas
    app.use HttpProxy {
      "^\/mam\/": {host: "115.28.1.119", port: 18860},
      "^\/system\/api\/": {host: "115.28.1.119", port: 18860}
    }

    # 代理请求之后，这样不会破坏http结构
    app.use(bodyParser.json())
    # TODO 暂时没用到表单提交的contentType
    # 如果不注释，windows系统会报错［第一次点击时，系统会报错，第二次后就没问题］
    # app.use(bodyParser.urlencoded())
    router = express.Router()
    (require './cordova-emulate')(router, options.rootPath)
    app.use(router)

    @server = app.listen options.httpPort

    # # 端口被占用 TODO 只要再次监听后，会报错，前一次再点击关闭时，不能回收端口，正常情况下是没问题的
    # if (@server.listeners 'error').length is 0
    #   console.log 'bind [error] event...'
    #   @server.on 'error', (e) =>
    #     if e.code is 'EADDRINUSE'
    #       # @stop()
    #       alert 'Address in use, retrying...'

    # 开启debug webview
    if (@server.listeners 'listening').length is 0
      console.log 'bind [listening] event...'
      @server.on 'listening', =>
        console.log "Debug Server listening..."
        @server.httpPort = options.httpPort # holeway
        atom.workspaceView.trigger("atom-chameleon:emulator", options.httpPort)


    #socket management, useful for graceful shutdown
    #ref: http://stackoverflow.com/questions/14626636/how-do-i-shutdown-a-node-js-https-server-immediately
    @sockets = {}
    nextSocketId = 0
    @server.on 'connection', (socket)=>
      socketId = nextSocketId++
      @sockets[socketId] = socket
      # console.log "socket #{socketId} opend"

      socket.once 'close', =>
        # console.log "socket #{socketId} closed"
        delete @sockets[socketId]

      socket.setTimeout 4000

    console.log 'server run'
    @emit 'start'

  stop: (cb) ->
    _.each @sockets, (v, k, l) =>
      console.log "socket #{k} destroyed."
      v.destroy()

    @server?.close =>
      console.log "server closed."
      @lineoff = true
      @closeServer = "before"
      # 关闭debug webview
      atom.workspaceView.trigger("atom-chameleon:emulator", @server.httpPort)
      @closeServer = "after"

      cb(@server.httpPort)
    # 关闭状态栏
    @emit 'stop'

  offline: ->
    console.log "offline: #{@lineoff}"
    @lineoff
