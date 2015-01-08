Q = require 'q'
_ = require 'underscore'
request = require 'request'
# github
GitHubApi = require 'github'
github = null
github_flag =
  safe: false

# gogs
gogsApi = 'https://try.gogs.io'
gogs_flag = {}


# api.github.com
github_init = ->
  github = new GitHubApi
    #  required
    version: '3.0.0'
    # optional
    debug: false
    timeout: 15000
    headers: 'user-agent': 'chameleon-ide'

github_authenticate = (options) ->
  github_init() unless github
  console.log "#{options.username}: github is authenticating..."
  github.authenticate
    type: "basic"
    username: options.username
    password: options.password
  github_flag["username"] = options.username
  github_flag["safe"] = true


# gogs模拟登入获取cookies
gogs_login = (options) ->
  Q.Promise (resolve, reject, notify) ->
    console.log "gogs authenticate: POST #{gogsApi}/user/login}"
    request.post
      url: "#{gogsApi}/user/login"
      form:
        uname: options.username
        password: options.password
      , (err, httpResponse, body) ->
          reject(err) if err
          # if httpResponse.statusCode is 200
          resolve(httpResponse.headers['set-cookie'])

# gogs模拟登入获取csrf
gogs_csrf = (cookies) ->
  Q.Promise (resolve, reject, notify) ->
    console.log "gogs fetch csrf: GET #{gogsApi}/}"
    request.get
      headers:
          Cookie: cookies
      url: "#{gogsApi}/"
      , (err, httpResponse, body) ->
          reject(err) if err
          try
            csrf = httpResponse.toJSON().headers['set-cookie'][0].split(';')[0].split('=')[1].replace(/%3D/g, '=')
            resolve
              cookies: cookies
              csrf: csrf
          catch e
            reject e

# gogs生成accessToken
gogs_authenticate = (msg) ->
  Q.Promise (resolve, reject, notify) ->
    if localStorage.getItem 'gogs_token'
      console.log "localStorage token：#{localStorage.getItem 'gogs_token'}"
      gogs_flag['token'] = localStorage.getItem 'gogs_token'
      resolve(gogs_flag['token'])
    else
      console.log "gogs create token: POST #{gogsApi}/user/settings/applications}"
      console.log msg
      request.post
        url: "#{gogsApi}/user/settings/applications"
        headers:
            Cookie: msg.cookies
        form:
          type: 'token'
          name: 'chameloenIDE(Mistaken delete!)'
          _csrf: msg.csrf
      , (err, httpResponse, body) ->
          reject(err) if err
          if httpResponse.statusCode is 302
            # decodeURIComponent 解码url
            macaron_flash = decodeURIComponent httpResponse.toJSON().headers['set-cookie'][1]
            token = macaron_flash.split('&success')[0].replace 'macaron_flash=info=', ''
            console.log "token: #{token}"
            resolve(token)
            # 缓存token，不必每次都去生成
            localStorage.gogs_token = token


module.exports =

  github: ->
    # 如果仓库已经存在，则返回错误
    createRepos: (msg) ->
      console.log "ready Pick up data："
      console.log msg
      callMyself = arguments.callee
      if msg.options.username is github_flag.username and github_flag.safe
        Q.Promise (resolve, reject, notify) ->
          # msg {name (String): Required}
          console.log "github creates repos..."
          github.repos.create msg, (err, data) ->
            if err
              github_flag.safe = false # eg：用户输错帐号密码重新验证 Etc.
              reject(err)
            resolve(data)
      else
        github_authenticate msg.options
        callMyself(msg)


  gogs: ->
    # 如果仓库已经存在，则api自动提示
    createRepos: (msg) ->
      callMyself = arguments.callee
      console.log "ready Pick up data："
      console.log msg
      # 匹配是否同一个用户的token后开始创建仓库
      if msg.options.username is gogs_flag.username and gogs_flag.token
        console.log "gogs create repos: POST #{gogsApi}/api/v1/user/repos"
        Q.Promise (resolve, reject, notify) ->
          request
            method: 'POST'
            url: "#{gogsApi}/api/v1/user/repos"
            headers:
                Authorization: "token #{gogs_flag.token}"
                'Content-Type': 'application/json; charset=utf8'
            json: true
            body: msg
            , (err, httpResponse, body) ->
                reject(err) if err
                if httpResponse.statusCode is 403
                  delete gogs_flag.token
                  # localStorage 仅限制再atom上可以使用，因为是window属性
                  localStorage.removeItem('gogs_token')
                  resolve message: 'Invalid token.'
                resolve(body) if httpResponse.statusCode is 200 or httpResponse.statusCode is 422
      else
        gogs_login(msg.options)
        .then (cookies) ->
          gogs_csrf cookies
        .then (obj) ->
          gogs_authenticate obj
        .then (token) ->
          gogs_flag['username'] = msg.options.username
          gogs_flag['token'] = token # 保存用户token，如果用户再web界面删除的话，要重新保存
          callMyself(msg)
