Q = require 'q'
_ = require 'underscore'
request = require 'request'
# github
GitHubApi = require 'github'
github = null
github_flag =
  safe: false

# gogs
gogsApi = 'https://172.16.1.27:3000'
gogs_flag =
  safe: false


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
  console.log "#{options.username}: github authenticate..."
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
          if httpResponse.statusCode is 200
            resolve(httpResponse.headers['Set-Cookie'])

# gogs创建token
gogs_authenticate = (cookies)->
  Q.Promise (resolve, reject, notify) ->
    console.log "gogs create token: POST #{gogsApi}/user/settings/applications}"

    request.post
      url: "#{gogsApi}/user/settings/applications"
      form:
        type: 'token'
        uname: 'chameloenIDE(Mistaken delete!)'
        _csrf: cookies._csrf
    , (err, httpResponse, body) ->
        reject(err) if err
        if httpResponse.statusCode is 200
          temp = "<div class=\"alert alert-blue alert-radius block\"><i class=\"octicon octicon-info\"></i>*</div>"
          body = body.substr body.indexOf temp  + temp.length
          token = body.substr 0, body.indexOf '</div>'
          resolve(token)


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
            reject(err) if err
            resolve(data)
      else
        github_authenticate msg.options
        callMyself(msg)


  gogs: ->
    # 如果仓库已经存在，则api自动提示
    createRepos: (msg) ->
      console.log "ready Pick up data："
      console.log msg
      callMyself = arguments.callee
      # 匹配是否同一个用户的token后开始创建仓库
      if gogs.flag.safe and msg.options.username is gogs_flag.username
        console.log "gogs create token: POST #{gogsApi}/api/v1/user/repos"
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
                resolve(data) if httpResponse.statusCode is 200
      else
        Q.Promise (resolve, reject, notify) ->
          gogs_login(msg.options)
          .then (cookies) ->
            gogs_authenticate()
          .then (token) ->
            gogs_flag.username = msg.options.username
            gogs_flag.token = token # 保存用户token，如果用户再web界面删除的话，要重新保存
            gogs.flag.safe = true
            callMyself(msg)
          .then ->
            console.log '创建仓库完毕...'
            done()
          .catch (err) ->
            gogs.flag.safe = false
            console.trace err.stack
            done(err)
