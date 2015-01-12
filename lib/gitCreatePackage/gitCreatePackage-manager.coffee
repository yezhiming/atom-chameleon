path = require 'path'
fs = require 'fs-extra'
os = require 'os'
uuid = require 'uuid'
request = require 'request'
_ = require 'underscore'

ProgressView = require '../utils/progress-view'

gitApi_create = require '../utils/gitApi_create'

Q = require 'q'
{github, gogs, gogsApi, generateKeyPair} = require '../utils/gitApi'
{execFile} = require 'child_process'

module.exports =
class GitCreatePackageManager

  activate: ->
    atom.workspaceView.command "atom-butterfly:gitCreatePackage", => @gitCreatePackage()
    console.log "GitCreatePackageManager activate"

  gitCreatePackage: ->
    GitCreatePackageWizardView = require './gitCreatePackage-wizard-view'
    gitCreatePackageWizardView = new GitCreatePackageWizardView().attach()

    pv = new ProgressView("Create git package...")

    info = null
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
      console.log "tmpDir: #{tmpDir}"
      fs.copySync selectPath, tmpDir

      _.extend(options, gitPath: tmpDir)
    .then (options) -> # upload ssh key
      info = options
      # ide保证installedSshKey一定会存在localStorage
      keyObj = JSON.parse localStorage.getItem 'installedSshKey'
      if keyObj.gitHubFlag is 'new' and info.repo is 'github'
        # TODO 由于github只匹配key不匹配名字，所以每次上传都可以重复，可以考虑保存id先删除
        github().createSshKey
          options:
            username: options.account
            password: options.password
          key: keyObj.public
          title: "chameleonIDE foreveross inc.(#{atom.config.get('atom-butterfly.puzzleAccessToken')})"
      else if keyObj.gogsFlag is 'new' and info.repo is 'gogs'
        console.log "TODO"
    .then (data) -> # 获取用户名
      # data：上传服务器的key，成功后返回的内容，由于github只匹配key不匹配名字，所以每次上传都可以重复，可以考虑保存id先删除
      if info.repo is 'github'
        github().getUser
          options:
            username: info.account
            password: info.password
      else if info.repo is 'gogs'
        console.log('TODO')
    .then (obj) -> # 创建仓库
      pv.setTitle "在#{info.repo}上创建库"
      if obj.result and obj.type is 'github'
        info.username = obj.message.login
        github().createRepos
          options:
            username: info.account
            password: info.password
          name: info.packageName
          description: info.describe
          private: false
          auto_init: true
      else if obj.result and obj.type is 'gogs'
        info.username = obj.message.name
        gogs().createRepos
          options:
            username: info.account
            password: info.password
          Name: info.packageName
          Description: info.describe
          Private: false
          AutoInit: true
          License: 'MIT License'
    .then (obj) -> # 开始同步仓库资源
      if obj.type is 'gogs'
        # git@try.gogs.io:heyanjiemao/test.git
        repoUrl = "git@#{gogsApi.replace('https://', '')}:#{info.username}/#{info.packageName}.git"
      else if obj.type is 'github'
        # repoUrl = "https://github.com/#{info.account}/#{info.packageName}.git"
        repoUrl = "git@github.com:#{info.username}/#{info.packageName}.git"
      options =
        async: true
      gitPath = atom.config.get('atom-butterfly.gitCloneEnvironmentPath') # 设置git环境变量
      options['env'] = path: gitPath if gitPath and gitPath != ''
      # push资源到仓库
      gitApi_create info.gitPath, repoUrl, options, info.describe
    # .then (repoUrl) ->
      # info.repoUrl = repoUrl
      # 开始发布到chameleon packagesManager
      # server = atom.config.get('atom-butterfly.puzzleServerAddress')
      # r = request.post {url:"#{server}/api/packages", timeout: 1000*60*10}, (err, httpResponse, body) ->
      #       reject(err) if err
      #       if httpResponse and httpResponse.statusCode is 201
      #         resolve
      #           result: true
      #           statusCode: 201
      #           body: body
      #       else if httpResponse and httpResponse.statusCode is 403
      #         resolve
      #           result: false
      #           statusCode: 403
      #           body: body
      # form = r.form()
      # form.append "access_token", "#{atom.config.get('atom-butterfly.puzzleAccessToken')}"
      # form.append "name", info.packageName
      # form.append "repository_url", repoUrl
      # form.append "description", info.describe || info.packageName
      # form.append "previews", info.previews if info.previews
      # form.append "tags", info.tags if info.tags
    .then (obj) ->
      # TODO 是否更新此package
      if obj.statusCode is 403
        console.log 'update this package...'

    .progress (notify) ->
      console.log notify.stdout if notify.stdout
      console.error notify.stderr if notify.stderr
    .catch (error) ->
      alert("#{error}")
      if error.message.indexOf 'Permission denied (publickey)' != 1
        home = process.env.USERPROFILE || process.env.HOME || process.env.HOMEPATH
        generateKeyPair(home) # 重新生成key
      else
        console.trace error.stack
        done(error)
    .finally ->
      console.log "publish package finally."
      pv.destroy()
