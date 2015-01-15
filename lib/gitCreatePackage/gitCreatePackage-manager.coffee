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
{github, gogs, gogsApi, generateKeyPair} = require '../utils/gitApi'

module.exports =
class GitCreatePackageManager

  activate: ->
    atom.workspaceView.command "atom-butterfly:gitCreatePackage", => @gitCreatePackage()
    # console.log "GitCreatePackageManager activate"


  gitCreatePackage: ->
    GitCreatePackageWizardView = require './gitCreatePackage-wizard-view'
    gitCreatePackageWizardView = new GitCreatePackageWizardView()

    LoginView = require './gitCreatePackage-login-view'
    loginView = new LoginView()

    pv = new ProgressView("Create a package...")

    info = null

    gitCreatePackageWizardView.attach()
    gitCreatePackageWizardView.finishPromise()

    .then (options) ->
      gitCreatePackageWizardView.destroy()

      loginView.mergeOptions options
      atom.workspaceView.append loginView
      loginView.finishPromise()

    .then (options) ->
      loginView.destroy()
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

    .then (options) -> # upload ssh key
      info = options
      keyObj = JSON.parse localStorage.getItem 'installedSshKey' # ide保证installedSshKey一定会存在localStorage
      if keyObj.gitHubFlag is 'new' and info.repo is 'github'
        pv.setTitle "Upload IDE public key to github"
        # 由于github只匹配key内容不匹配名字
        github().createSshKey
          options:
            username: options.account
            password: options.password
          key: keyObj.public
          title: "chameleonIDE foreveross inc.(#{atom.config.get('atom-butterfly.puzzleAccessToken')})"
      else if keyObj.gogsFlag is 'new' and info.repo is 'gogs'
        pv.setTitle "Upload IDE public key to gogs"
        console.log "TODO"

    .then (data) -> # 获取用户名
      if info.repo is 'github'
        github().getUser
          options:
            username: info.account
            password: info.password
      else if info.repo is 'gogs'
        console.log('TODO')

    .then (obj) -> # 创建仓库
      pv.setTitle "#{info.repo} create package: #{info.packageName}"
      if obj.result and obj.type is 'github'
        info.username = obj.message.login # 添加github用户名
        github().createRepos
          options:
            username: info.account
            password: info.password
          name: info.packageName
          description: info.describe
          private: false
          auto_init: false
      else if obj.result and obj.type is 'gogs'
        info.username = obj.message.name # 添加gogs用户名
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
      pv.setTitle "Synchronizer package :#{info.repo}"
      if obj.type is 'gogs'
        # git@try.gogs.io:heyanjiemao/test.git
        repoSshUrl = "git@#{gogsApi.replace('https://', '')}:#{info.username}/#{info.packageName}.git"
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
        maxBuffer: 1024*1024*10
      gitPath = atom.config.get('atom-butterfly.gitCloneEnvironmentPath') # 设置git环境变量
      options['env'] = path: gitPath if gitPath and gitPath
      # push资源到仓库
      gitApi_create info.gitPath, repoSshUrl, options, info.describe

    .then ->
      pv.setTitle "Add package：#{info.packageName}"
      server = atom.config.get('atom-butterfly.puzzleServerAddress')
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
        form.append "access_token", "#{atom.config.get('atom-butterfly.puzzleAccessToken')}"
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
      alert "#{error}"
      if error.message.indexOf('Permission denied (publickey)') != -1
        home = process.env.USERPROFILE || process.env.HOME || process.env.HOMEPATH
        generateKeyPair(home) # 重新上传key
      else
        console.trace error.stack
        done(error)
    .finally ->
      console.log "publish package finally."
      pv.destroy()
