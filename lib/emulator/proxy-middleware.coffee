http = require('http')

module.exports = (req, res, next) ->
  if req.url.match /^\/mam\//g

    console.log "proxy to #{req.protocol}://115.28.1.119:18860#{req.path}"

    request = http.request
      host: '115.28.1.119'
      port: 18860
      path: req.url
      method: req.method
      headers: {
        'content-type': req.headers['content-type']
      }
    , (response) ->
      res.writeHead reponse.statusCode, response.headers
      response.pipe(res)
      response.on 'data', (data) ->
        console.log "代理转发[服务器]响应: #{data.toString()}"

    req.on 'data', (data) ->
      request.write(data)
      console.log "代理转发[客户端]请求体：#{data.toString()}"

    req.on 'end', -> request.end()

  else
    next()
