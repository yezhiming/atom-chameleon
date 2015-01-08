Q = require 'q'
request = require 'request'
GitHubApi = require 'github'
github = null

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

  githubStr = JSON.stringify
    username: options.username
    safe: true
  localStorage.github = githubStr


# gogs模拟登入获取cookies
gogs_login = (options) ->
  Q.Promise (resolve, reject, notify) ->
    console.log "gogs authenticate: POST #{module.exports.gogsApi}/user/login}"
    request.post
      url: "#{module.exports.gogsApi}/user/login"
      form:
        uname: options.username
        password: options.password
      , (err, httpResponse, body) ->
          reject(err) if err
          # if httpResponse.statusCode is 200
          localStorage.gogs = JSON.stringify username: options.username
          resolve(httpResponse.headers['set-cookie'])

# gogs模拟登入获取csrf
gogs_csrf = (cookies) ->
  Q.Promise (resolve, reject, notify) ->
    console.log "gogs fetch csrf: GET #{module.exports.gogsApi}/}"
    request.get
      headers:
          Cookie: cookies
      url: "#{module.exports.gogsApi}/"
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
    gogs = JSON.parse localStorage.getItem 'gogs'
    if gogs.token
      resolve(gogs.token)
    else
      console.log "gogs create token: POST #{module.exports.gogsApi}/user/settings/applications}"
      # console.log msg
      request.post
        url: "#{module.exports.gogsApi}/user/settings/applications"
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
            # 缓存token，不必每次都去生成
            gogs['token'] = token
            localStorage.setItem('gogs', JSON.stringify gogs)
            resolve(token)


module.exports =

  gogsApi: 'https://try.gogs.io',

  github: ->

    # 上传公钥到服务器
    getUser: (msg) ->
      callMyself = arguments.callee
      githubObj = JSON.parse localStorage.getItem 'github' # 匹配是否同一个用户的token后开始创建仓库
      if github and githubObj and msg.options.username is githubObj.username and githubObj.safe
        Q.Promise (resolve, reject, notify) ->
          console.log "github fetch user..."
          github.user.get msg, (err, data) ->
            if err
              # eg：用户输错帐号密码重新验证 Etc.
              localStorage.removeItem('github') # localStorage 仅限制再atom上可以使用，因为是window属性
              reject(err)
            resolve
              result: true
              message: data
              type: 'github'
      else
        github_authenticate msg.options
        callMyself(msg)

    # 上传公钥到服务器
    createSshKey: (msg) ->
      callMyself = arguments.callee
      githubObj = JSON.parse localStorage.getItem 'github' # 匹配是否同一个用户的token后开始创建仓库
      if github and githubObj and msg.options.username is githubObj.username and githubObj.safe
        Q.Promise (resolve, reject, notify) ->
          unless msg.key or msg.title
            reject new Error 'params: title (String): Required and key (String): Required.'
          console.log "github creates ssh key..."
          github.user.createKey msg, (err, data) ->
            if err
              # eg：用户输错帐号密码重新验证 Etc.
              localStorage.removeItem('github') # localStorage 仅限制再atom上可以使用，因为是window属性
              reject(err)
            resolve
              result: true
              message: data
              type: 'github'
      else
        github_authenticate msg.options
        callMyself(msg)

    # 如果仓库已经存在，则返回错误
    createRepos: (msg) ->
      callMyself = arguments.callee
      githubObj = JSON.parse localStorage.getItem 'github' # 匹配是否同一个用户的token后开始创建仓库
      if githubObj and msg.options.username is githubObj.username and githubObj.safe
        Q.Promise (resolve, reject, notify) ->
          unless msg.name
            reject new Error 'params: name (String): Required.'
          console.log "github creates repos..."
          github.repos.create msg, (err, data) ->
            if err and err.toJSON().code is 422 and (err.toJSON().message.indexOf 'name already exists on this account') != -1
              resolve
                result: false
                message: err.toJSON()
                type: 'github'
            if err
              # eg：用户输错帐号密码重新验证 Etc.
              localStorage.removeItem('github') # localStorage 仅限制再atom上可以使用，因为是window属性
              reject(err)
            resolve
              result: true
              message: data
              type: 'github'
      else
        github_authenticate msg.options
        callMyself(msg)


  gogs: ->
    # 如果仓库已经存在，则api自动提示
    createRepos: (msg) ->
      callMyself = arguments.callee
      gogs = JSON.parse localStorage.getItem 'gogs' # 匹配是否同一个用户的token后开始创建仓库
      if gogs and msg.options.username is gogs.username and gogs.token
        console.log "gogs create repos: POST #{module.exports.gogsApi}/api/v1/user/repos"
        Q.Promise (resolve, reject, notify) ->
          request
            method: 'POST'
            url: "#{module.exports.gogsApi}/api/v1/user/repos"
            headers:
                Authorization: "token #{gogs.token}"
                'Content-Type': 'application/json; charset=utf8'
            json: true
            body: msg
            , (err, httpResponse, body) ->
                reject(err) if err
                if httpResponse.statusCode is 403
                  localStorage.removeItem('gogs') # localStorage 仅限制再atom上可以使用，因为是window属性
                  reject new Error 'code: 422 , message: Invalid token.'
                if httpResponse.statusCode is 422
                  resolve
                    result: false
                    message: body
                    type: 'gogs'
                if httpResponse.statusCode is 200
                  resolve
                    result: true
                    message: body
                    type: 'gogs'
      else
        gogs_login(msg.options)
        .then (cookies) ->
          gogs_csrf cookies
        .then (obj) ->
          gogs_authenticate obj
        .then (token) ->
          callMyself(msg)
