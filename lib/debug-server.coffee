{EventEmitter} = require 'events'
_ = require 'underscore'

{allowUnsafeEval} = require 'loophole'
express = allowUnsafeEval -> require 'express'

module.exports =
class DebugServer extends EventEmitter

  start: (rootPath, destPath, httpPort, pushState)->

    app = express()
    app.use express.static(rootPath)

    if pushState
      app.get '*', (req, res) ->
        console.log "http server get #{req.path}, with pushState"
        fs.exists path.resolve(rootPath, req.path), (exists) ->
          if exists
            res.sendFile path.resolve(destPath)
          else
            res.send 404
    else
      app.get '/', (req, res) =>
        console.log "http server get '/', without pushState"
        res.redirect @selectedIndexFile.text()

    @server = app.listen httpPort

    #socket management, useful for graceful shutdown
    #ref: http://stackoverflow.com/questions/14626636/how-do-i-shutdown-a-node-js-https-server-immediately
    @sockets = {}
    nextSocketId = 0
    @server.on 'connection', (socket)=>
      socketId = nextSocketId++
      @sockets[socketId] = socket
      console.log "socket #{socketId} opend"

      socket.once 'close', =>
        console.log "socket #{socketId} closed"
        delete @sockets[socketId]

      socket.setTimeout 4000

    console.log 'server run'
    @emit 'start'

  stop: ->
    _.each @sockets, (v, k, l)=>
      console.log "socket #{k} destroyed."
      v.destroy()

    @server.close -> console.log "server closed."
    @emit 'stop'
