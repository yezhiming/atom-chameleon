http = require 'http'
_ = require 'underscore'


module.exports = (options) ->

  return (req, res, next) ->

    # 查找符合规则的代理配置
    k = _.chain(options).keys().find (k) ->
      req.url.match new RegExp(k)
    .value()

    unless k
      next()

    else
      server_config = options[k]

      console.log "proxy #{req.url} to #{server_config.host}"

      request = http.request
        host: server_config.host
        port: server_config.port
        path: req.url
        method: req.method
        headers: {
          'content-type': req.headers['content-type'] || 'text/html;charset=UTF-8'
        }
      , (response) ->
        res.writeHead response.statusCode, response.headers
        response.pipe(res)
        response.on 'data', (data) ->
          console.log "代理转发[服务器]响应: #{data.toString()}"

      req.on 'data', (data) ->
        request.write(data)
        console.log "代理转发[客户端]请求体：#{data.toString()}"

      req.on 'end', -> request.end()
