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
  start: (options)->

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

    # 2333resolve NOTE1 express static middleware default active.  -> "/" mapping index.html
    app.use express.static path.resolve options.rootPath
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
    (require './cordova-emulate')(router, options.rootPath) #TODO: copy一份
    app.use(router)

    @server = app.listen options.httpPort

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

  stop: ->
    _.each @sockets, (v, k, l)=>
      console.log "socket #{k} destroyed."
      v.destroy()

    @server?.close -> console.log "server closed."
    @emit 'stop'
