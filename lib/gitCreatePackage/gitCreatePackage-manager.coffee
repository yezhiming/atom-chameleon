path = require 'path'
fs = require 'fs-extra'
os = require 'os'
uuid = require 'uuid'
request = require 'request'
_ = require 'underscore'

{$, $$} = require 'atom'


ProgressView = require '../utils/progress-view'
gitApi_create = require '../utils/gitApi_create'

Q = require 'q'
{github, gogs, gogsApi, gogsProtocol, generateKeyPair} = require '../utils/gitApi'

module.exports =
class GitCreatePackageManager

  activate: ->
    atom.workspaceView.command "atom-chameleon:gitCreatePackage", => @gitCreatePackage()
    # console.log "GitCreatePackageManager activate"

  gitCreatePackage: ->
    GitCreatePackageWizardView = require './gitCreatePackage-wizard-view'
    gitCreatePackageWizardView = new GitCreatePackageWizardView()

    pv = new ProgressView("Create a package...")

    info = null

    gitCreatePackageWizardView.attach()
    gitCreatePackageWizardView.finishPromise()
    .then (options) ->
      gitCreatePackageWizardView.destroy()
      pv.attach()
      selectPath = atom.packages.getActivePackage('tree-view').mainModule.treeView.selectedPath
      if require('fs').statSync(selectPath).isFile()
        tmpfile = path.resolve os.tmpdir(), uuid.v1()
      else
        tmpfile = os.tmpdir()

      tmpDir = path.resolve tmpfile, path.basename(selectPath)
      if fs.existsSync tmpDir
        fs.removeSync tmpDir
      fs.copySync selectPath, tmpDir

      if require('fs').statSync(selectPath).isFile()
        gitPath = tmpfile
      else
        gitPath = tmpDir
      _.extend(options, gitPath: gitPath)

    .then (options) -> # 验证用户有效性、获取用户名
      info = options
      if info.repo is 'github'
        github().getUser
          options:
            username: info.account
            password: info.password
      else if info.repo is 'gogs'
        gogs().getUser
          options:
            username: info.account
            password: info.password

    .then (obj) -> # generateKeyPair? 每个帐号有自己的keypair
      if obj.result and obj.type is 'github'
        info.username = obj.message.login # 添加github用户名
      else if obj.result and obj.type is 'gogs'
        info.username = obj.message # 添加gogs用户名
      # generateKeyPair
      home = process.env.USERPROFILE || process.env.HOME || process.env.HOMEPATH
      info.home = home
      options =
        maxBuffer: 1024*1024*5
      options.env = path: atom.config.get('atom-chameleon.gitCloneEnvironmentPath') if atom.config.get('atom-chameleon.gitCloneEnvironmentPath') # 一般mac不需要配置
      info.option = options

      keyObj = JSON.parse localStorage.getItem "#{info.account}_installedSshKey"
      unless keyObj and keyObj.public
        # 生成默认的公、密钥到userhome/.ssh
        generateKeyPair
          home: info.home
          username: info.account
          option: info.option

    .then (options) -> # upload ssh key
      # {info.account}_gitHubFlag = true 表示此用户成功上传过publickey
      keyObj = JSON.parse localStorage.getItem "#{info.account}_installedSshKey"
      if info.repo is 'github' and (!keyObj["#{info.account}_gitHubFlag"])
        pv.setTitle "Upload chameleonIDE public key to github."
        # 由于github只匹配key内容不匹配名字
        github().createSshKey
          options:
            username: info.account
            password: info.password
          key: keyObj.public
          title: "chameleonIDE foreveross inc.(#{atom.config.get('atom-chameleon.puzzleAccessToken')})"
      else if info.repo is 'gogs' and (!keyObj["#{info.account}_gogsFlag"])
        pv.setTitle "Upload chameleonIDE public key to gogs."
        # 由于github只匹配key内容不匹配名字
        gogs().createSshKey
          options:
            username: info.account
            password: info.password
          content: keyObj.public
          title: "chameleonIDE foreveross inc.(#{atom.config.get('atom-chameleon.puzzleAccessToken')})"

    .then (data) -> # 创建仓库 TODO data对象来判断keypair校验成功
      pv.setTitle "#{info.repo} create package: #{info.packageName}"
      if info.repo is 'github'
        github().createRepos
          options:
            username: info.account
            password: info.password
          name: info.packageName
          description: info.describe
          private: false
          auto_init: false
      else if info.repo is 'gogs'
        gogs().createRepos
          options:
            username: info.account
            password: info.password
          Name: info.packageName
          Description: info.describe
          Private: false
          AutoInit: false
          License: 'MIT License'

    .then (obj) -> # 开始同步仓库资源
      pv.setTitle "Synchronous package:#{info.repo}"
      if obj.type is 'gogs'
        # git@try.gogs.io:heyanjiemao/test.git
        repoSshUrl = "git@#{gogsApi.replace(gogsProtocol, '')}:#{info.username}/#{info.packageName}.git"
        repohttpsUrl = "#{gogsApi}/#{info.username}/#{info.packageName}.git"
      else if obj.type is 'github'
        # repoSshUrl = "https://github.com/#{info.account}/#{info.packageName}.git"
        repoSshUrl = "git@github.com:#{info.username}/#{info.packageName}.git"
        repohttpsUrl = "https://github.com/#{info.username}/#{info.packageName}.git"
      info.repoSshUrl = repoSshUrl
      info.repohttpsUrl = repohttpsUrl
      options =
        async: true
        timeout: 1000*60*10
      gitPath = atom.config.get('atom-chameleon.gitCloneEnvironmentPath') # 设置git环境变量
      options['env'] = path: gitPath if gitPath and gitPath
      # push资源到仓库
      gitApi_create info.gitPath, repoSshUrl, options, info.describe, info.home, info.account

    .then ->
      pv.setTitle "Add package：#{info.packageName}"
      server = atom.config.get('atom-chameleon.puzzleServerAddress')
      Q.Promise (resolve, reject, notify) ->
        # 开始发布到chameleon packagesManager
        r = request.post {url:"#{server}/api/packages", timeout: 1000*60*10}, (err, httpResponse, body) ->
          return reject(err) if err
          if httpResponse and httpResponse.statusCode is 201
            resolve
              result: true
              statusCode: 201
              body: body
          else if httpResponse and httpResponse.statusCode is 403
            resolve
              result: false
              statusCode: 403
              body: body
        form = r.form()
        form.append "access_token", "#{atom.config.get('atom-chameleon.puzzleAccessToken')}"
        form.append "name", info.packageName
        form.append "author", info.username
        form.append "repository_url", info.repoSshUrl
        form.append "home_url", info.repohttpsUrl
        form.append "description", info.describe || info.packageName
        form.append "previews", info.previews if info.previews
        form.append "tags", info.tags if info.tags

    .then (obj) ->
      # TODO 是否更新此package # if obj.statusCode is 403
      bodyJson = $.parseJSON(obj.body)
      if info.repo is 'github'
        bodyJson.package.https = "https://github.com/#{info.username}/#{info.packageName}.git"
        bodyJson.package.subversion = "https://github.com/#{info.username}/#{info.packageName}"
      else if info.repo is 'gogs'
        bodyJson.package.https = "#{gogsApi}/#{info.username}/#{info.packageName}.git"
        bodyJson.package.subversion = "#{gogsApi}/#{info.username}/#{info.packageName}"

      unless obj.result
        alert body.message
      else
        ResultView = require './gitCreatePackage-result-view'
        resultView = new ResultView()
        resultView.setValues bodyJson
        atom.workspaceView.append resultView

    .catch (error) ->
      if error.message.indexOf('Permission denied (publickey)') != -1 # 清除git客户端ssh交互缓存
        generateKeyPair
          home: info.home # 重新上传key
          username: info.account
          info.options
        alert "reset chameleon IDE publickey, please try again..."
      else if error.code = 128 and error.message.indexOf('Permission to ') != -1 and error.message.indexOf(' denied to ') != -1
        # 这种情况是由于git提供商帐号（eg: github帐号）后台已经手动上传默认id_ras.pub 等默认公钥类型，导致了ssh-add不能清除ssh交互缓存，一直会与此帐号同步资源，导致错误发生。
        # 参考：https://help.github.com/articles/generating-ssh-keys/
        alert "This kind of situation is due to the git provider the user (eg: github's user) are manually upload id_ras.pub etc.
          the default public key types such as pub, led to the SSH-add tools don't remove the SSH interaction cache, have been with this account will be resources, lead to errors.
          Reference: https://help.github.com/articles/generating-ssh-keys/"
      else
        error.code = 500 unless error.code
        alert "{code: #{error.code}, error: #{error}}"
      console.trace error.stack
      done(error)
    .finally ->
      console.log "publish package finally."
      pv.destroy()
