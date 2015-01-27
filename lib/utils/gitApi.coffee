Q = require 'q'
request = require 'request'
GitHubApi = require 'github'
{exec} = require 'child_process'
{EOL} = require 'os'
fse = require 'fs-extra'
fs = require 'fs'
github = null
gogs = {}

# api.github.com
github_init = ->
  github = new GitHubApi
    #  required
    version: '3.0.0'
    # optional
    debug: false
    timeout: 30000
    headers: 'user-agent': 'chameleon-ide'
  # TODO 获取解密的密码重新认证 github_authenticate()

github_authenticate = (options) ->
  console.log "#{options.username}: github is authenticating..."
  github.authenticate
    type: "basic"
    username: options.username
    password: options.password

  githubStr = JSON.stringify
    username: options.username
    safe: true
  localStorage.github = githubStr
  # 可以存储加密的密码


# gogs模拟登入获取cookies
gogs_login = (options) ->
  if gogs.username and gogs.password
    options.username = gogs.username
    options.password = gogs.password
  else
    gogs.username = options.username
    gogs.password = options.password

  Q.Promise (resolve, reject, notify) ->
    console.log "gogs authenticate: POST #{module.exports.gogsApi}/user/login"
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
    console.log "gogs fetch csrf: GET #{module.exports.gogsApi}/"
    request.get
      headers:
          Cookie: cookies
      url: "#{module.exports.gogsApi}/"
      , (err, httpResponse, body) ->
          reject(err) if err
          try
            uname = httpResponse.toJSON().body
            uname = uname.substr uname.indexOf '<li class=\"right\" id=\"header-nav-user\">'
            uname = uname.substring uname.indexOf('<a href=\"\/') + '<a href=\"\/'.length, uname.indexOf('\" class=\"text-bold\">')
            console.log "截取html用户名：#{uname}"

            csrf = httpResponse.toJSON().headers['set-cookie'][0].split(';')[0].split('=')[1].replace(/%3D/g, '=')
            resolve
              login: uname
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
      console.log "gogs create token: POST #{module.exports.gogsApi}/user/settings/applications"
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
            # 缓存token，不必每次都去获取
            gogs['token'] = token
            gogs['login'] = msg.login
            localStorage.setItem('gogs', JSON.stringify gogs)
            resolve(token)


module.exports =

  # https://bsl.foreveross.com/gogs(8001)
  gogsApi: 'https://try.gogs.io',

  # 生成默认的公、密钥到userhome/.ssh
  generateKeyPair: (options) ->
    Q.Promise (resolve, reject, notify) ->
      # 遵循ssh-kengen规范
      fse.ensureDirSync "#{options.home}/.ssh"
      # 关闭确认公钥设置
      if (!fs.existsSync "#{options.home}/.ssh/config") or (!fs.readFileSync "#{options.home}/.ssh/config", encoding: 'utf8'.contains 'StrictHostKeyChecking no')
        fs.appendFileSync "#{options.home}/.ssh/config", "#{EOL}StrictHostKeyChecking no#{EOL}UserKnownHostsFile /dev/null#{EOL}"
      msg = {}
      if fs.existsSync "#{options.home}/.ssh/id_rsa_#{options.username}.pub"
        console.log 'reset rsa KeyPair...'
        pubKey = fs.readFileSync "#{options.home}/.ssh/id_rsa_#{options.username}.pub", encoding:'utf8'
        msg.public = pubKey
        localStorage["#{options.username}_installedSshKey"] = JSON.stringify msg
        return resolve(pubKey)
      # 生成默认的公、密钥到userhome/.ssh
      console.log 'generating rsa KeyPair...'
      # 根据github规则，公钥名称暂时写死id_rsa
      cp = exec "ssh-keygen -t rsa -C #{options.username}@github.com -f #{options.home}/.ssh/id_rsa_#{options.username} -N ''", options.options, (error, stdout, stderr) ->
        if error
          reject(error)
        else
          console.log stdout.toString()
          console.log stderr.toString()
          pubKey = fs.readFileSync "#{options.home}/.ssh/id_rsa_#{options.username}.pub", encoding:'utf8'
          msg.public = pubKey
          localStorage["#{options.username}_installedSshKey"] = JSON.stringify msg
          resolve(pubKey)


  github: ->
    # 获取用户信息
    getUser: (msg) ->
      callMyself = arguments.callee
      github_init() unless github
      githubObj = JSON.parse localStorage.getItem 'github' # 匹配是否同一个用户的token后开始创建仓库
      if githubObj and githubObj.safe
        Q.Promise (resolve, reject, notify) ->
          console.log "github fetch user..."
          github.user.get msg, (err, data) ->
            if err
              # eg：用户输错帐号密码重新验证 Etc.
              localStorage.removeItem('github') # localStorage 仅限制再atom上可以使用，因为是window属性
              return reject(err)
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
      github_init() unless github
      githubObj = JSON.parse localStorage.getItem 'github' # 匹配是否同一个用户的token后开始创建仓库
      if githubObj and githubObj.safe
        Q.Promise (resolve, reject, notify) ->
          unless msg.key or msg.title
            reject new Error 'params: title (String): Required and key (String): Required.'
          console.log "github creates ssh key..."
          github.user.createKey msg, (err, data) ->
            if (err and err.message.indexOf 'key is already in use' != -1) or !err
              keyObj = JSON.parse localStorage.getItem "#{msg.options.username}_installedSshKey"
              keyObj["#{msg.options.username}_gitHubFlag"] = true
              localStorage["#{msg.options.username}_installedSshKey"] = JSON.stringify keyObj
              resolve
                result: true
                message: data
                type: 'github'
              # 校验keypair
              # home = process.env.USERPROFILE || process.env.HOME || process.env.HOMEPATH
              # option =
              #   maxBuffer: 1024*1024*1
              # option.env = path: atom.config.get('atom-chameleon.gitCloneEnvironmentPath') if atom.config.get('atom-chameleon.gitCloneEnvironmentPath') # 一般mac不需要配置
              # exec "eval \"$(ssh-agent -s)\" && ssh-add #{home}/.ssh/id_rsa_#{msg.options.username} && ssh -T git@github.com", option, (error, stdout, stderr) ->
              #   console.log('Program stdout: %s', stdout.toString())
              #   console.log('Program stderr: %s', stderr.toString())
              #   if error
              #     resolve
              #       result: false
              #       message: stderr.toString()
              #       type: 'github'
              #   else
              #     resolve
              #       result: true
              #       message: stdout.toString()
              #       type: 'github'
            else if err
              # eg：用户输错帐号密码重新验证 Etc.
              localStorage.removeItem('github') # localStorage 仅限制再atom上可以使用，因为是window属性
              reject(err)
      else
        github_authenticate msg.options
        callMyself(msg)

    # 如果仓库已经存在，则返回错误
    createRepos: (msg) ->
      callMyself = arguments.callee
      github_init() unless github
      githubObj = JSON.parse localStorage.getItem 'github' # 匹配是否同一个用户的token后开始创建仓库
      if githubObj and githubObj.safe
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
            else if err
              # eg：用户输错帐号密码重新验证 Etc.
              localStorage.removeItem 'github'
              reject(err)
            else
              resolve
                result: true
                message: data
                type: 'github'
      else
        github_authenticate msg.options
        callMyself(msg)


  gogs: ->
    # 获取用户信息
    getUser: (msg)->
      callMyself = arguments.callee
      gogs = JSON.parse localStorage.getItem 'gogs'

      if gogs
        Q.Promise (resolve, reject, notify) ->
          resolve
            result: true
            message: gogs.login
            type: 'gogs'
      else
        gogs_login(msg.options)
        .then (cookies) ->
          gogs_csrf cookies
        .then (obj) ->
          gogs_authenticate obj
        .then (token) ->
          callMyself(msg)


    # 上传公钥到服务器
    createSshKey: (msg) ->
      callMyself = arguments.callee
      gogs = JSON.parse localStorage.getItem 'gogs' # 匹配是否同一个用户的token后开始创建仓库
      if gogs and gogs.token
        console.log "gogs creates ssh key: POST #{module.exports.gogsApi}/user/settings/ssh"
        Q.Promise (resolve, reject, notify) ->
          request
            method: 'POST'
            url: "#{module.exports.gogsApi}/user/settings/ssh"
            headers:
                Cookie: msg.cookies
            form:
              title: msg.title
              content: msg.content
              _csrf: msg.csrf
            , (err, httpResponse, body) ->
                return reject(err) if err
                # 不管服务器是否存在key则只要用户不删除本地的公钥密钥对即可
                keyObj = JSON.parse localStorage.getItem "#{msg.options.username}_installedSshKey"
                keyObj["#{msg.options.username}_gogsFlag"] = true
                localStorage["#{msg.options.username}_installedSshKey"] = JSON.stringify keyObj
                if httpResponse.statusCode is 302
                  resolve
                    result: true
                    message: body
                    type: 'gogs'
                else if httpResponse.statusCode is 200 or body.contains 'SSH 密钥已经被使用。'
                  resolve
                    result: false
                    message: body
                    type: 'gogs'
                # 校验keypair
                # home = process.env.USERPROFILE || process.env.HOME || process.env.HOMEPATH
                # option =
                #   maxBuffer: 1024*1024*1
                # option.env = path: atom.config.get('atom-chameleon.gitCloneEnvironmentPath') if atom.config.get('atom-chameleon.gitCloneEnvironmentPath') # 一般mac不需要配置
                # exec "eval \"$(ssh-agent -s)\" && ssh-add #{home}/.ssh/id_rsa_#{msg.options.username} && ssh -T git@#{module.exports.gogsApi.replace('https://', '')}", option, (error, stdout, stderr) ->
                #   console.log('Program stdout: %s', stdout.toString())
                #   console.log('Program stderr: %s', stderr.toString())
                #   if error
                #     resolve
                #       result: false
                #       message: stderr.toString()
                #       type: 'gogs'
                #   else
                #     resolve
                #       result: true
                #       message: stdout.toString()
                #       type: 'gogs'
      else
        gogs_login(msg.options)
        .then (cookies) ->
          gogs_csrf cookies
        .then (obj) ->
          msg.cookie = obj.cookie
          msg.csrf = obj.csrf
          callMyself msg


    # 如果仓库已经存在，则api自动提示
    createRepos: (msg) ->
      callMyself = arguments.callee
      gogs = JSON.parse localStorage.getItem 'gogs' # 匹配是否同一个用户的token后开始创建仓库
      if gogs and gogs.token
        console.log "gogs creates repos: POST #{module.exports.gogsApi}/api/v1/user/repos"
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
                else if httpResponse.statusCode is 422
                  resolve
                    result: false
                    message: body
                    type: 'gogs'
                else if httpResponse.statusCode is 200
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
