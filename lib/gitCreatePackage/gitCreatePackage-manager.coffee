path = require 'path'
fs = require 'fs-extra'
os = require 'os'
uuid = require 'uuid'
request = require 'request'
_ = require 'underscore'

ProgressView = require '../utils/progress-view'

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
      fs.copySync selectPath, tmpDir

      _.extend(options, gitPath: tmpDir)
    .then (options) -> # upload ssh key
      info = options
      # ide保证installedSshKey一定会存在localStorage
      keyObj = JSON.parse localStorage.getItem 'installedSshKey'
      if keyObj.flag is 'new' and info.repo is 'github'
        github().createSshKey
          options:
            username: options.account
            password: options.password
          key: keyObj.public
          title: 'chameleonIDE foreveross inc.'
      else if keyObj.flag is 'new' and info.repo is 'gogs'
        console.log "TODO"
    .then (key) -> # 获取用户名
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
      else if obj.result and obj.type is 'gogs'
        info.username = obj.message.name
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
      if obj.type is 'gogs'
        repoUrl = "#{gogsApi}/#{info.username}/#{info.packageName}.git"
      else if obj.type is 'github'
        # repoUrl = "https://github.com/#{info.account}/#{info.packageName}.git"
        repoUrl = "git@github.com:#{info.username}/#{info.packageName}.git"

      Q.Promise (resolve, reject, notify) ->
        args = [info.gitPath
        repoUrl
        info.describe]
        options =
          maxBuffer: 1024*1024*10
        gitPath = atom.config.get('atom-butterfly.gitCloneEnvironmentPath') # 设置git环境变量
        options['env'] = path: gitPath if gitPath and gitPath != ''

        if obj.result # 创建仓库成功
          file = '/lib/utils/gitApi_create.sh'
        else # 仓库已经存在
          file = '/lib/utils/gitApi_update.sh'
        file = "#{atom.getConfigDirPath()}/packages/atom-butterfly#{file}"

        console.log "execFile: #{file} #{args.join(' ') if args}"
        cp = execFile file, args, options, (error, stdout, stderr) ->
          console.log stdout.toString()
          console.log stderr.toString()
          if error then reject(error) else resolve(repoUrl)
          # error.code = 1 即非正常退出
    # .then (repoUrl) ->
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
