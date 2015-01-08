path = require 'path'
fs = require 'fs-extra'
os = require 'os'
uuid = require 'uuid'

_ = require 'underscore'

Q = require 'q'
{github, gogs, gogsApi} = require '../utils/gitApi'

module.exports =
class GitCreatePackageManager

  activate: ->
    atom.workspaceView.command "atom-butterfly:gitCreatePackage", => @gitCreatePackage()
    console.log "GitCreatePackageManager activate"


  gitCreatePackage: ->
    GitCreatePackageWizardView = require './gitCreatePackage-wizard-view'
    gitCreatePackageWizardView = new GitCreatePackageWizardView().attach()
    info = null
    gitCreatePackageWizardView.finishPromise()
    .then (options) ->
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
    .then (options) ->
      info = options
      if options.repo is 'github'
        github().createRepos
          options:
            username: options.account
            password: options.password
          name: options.packageName
          description: options.describe
          private: false
          auto_init:true
      else if options.repo is 'gogs'
        gogs().createRepos
          options:
            username: options.account
            password: options.password
          Name: options.packageName
          Description: options.describe
          Private: false
          AutoInit: true
          License: 'MIT License'
    .then (obj) ->
      # 开始同步仓库资源
      if obj.type is 'gogs'
        repoUrl = "#{gogsApi}/#{info.account}/#{info.packageName}.git"
      else if obj.type is 'github'
        repoUrl = "https://github.com/#{info.account}/#{info.packageName}.git"

      Q.Promise (resolve, reject, notify) ->
        notify stdout: "execFile: #{file} #{args.join(' ') if args}"

        args = [info.gitPath
        info.describe
        repoUrl]
        options:
          maxBuffer: 1024*1024*10
          env: path: atom.config.get('atom-butterfly.gitCloneEnvironmentPath') # 设置git环境变量
        if obj.result # 创建仓库成功
          file = 'gitApi_create.sh'
        else # 仓库已经存在
          file = 'gitApi_update.sh'
        cp = require 'child_process'.execFile file, args, options, (error, stdout, stderr) ->
          if error then reject(error) else resolve()

        cp.on 'exit', (code, signal)->
          console.log "code:#{code}   signal： #{signal}"
          if signal is 'SIGTERM' and code == null
            reject new Error "SIGTERM"
          else
            resolve(repoUrl)

        cp.stdout.on 'data', (data) -> notify stdout: data.toString()
        cp.stderr.on 'data', (data) -> notify stderr: data.toString()
    .then (repoUrl)->
      # 开始发布到chameleon packagesManager
      server = atom.config.get('atom-butterfly.puzzleServerAddress')
      r = request.post {url:"#{server}/api/packages", timeout: 1000*60*10}, (err, httpResponse, body) ->
        reject(err) if err
        if httpResponse.statusCode is 201
          resolve
            result: true
            statusCode: 201
            body: body
        else if httpResponse.statusCode is 403
          resolve
            result: false
            statusCode: 403
            body: body
      form = r.form()
      form.append "access_token","#{atom.config.get('atom-butterfly.puzzleAccessToken')}"
      form.append "name", info.packageName
      form.append "repository_url", repoUrl
      form.append "description", info.describe || info.packageName
      form.append "previews", info.previews if info.previews
      # form.append "tags", info.tags if info.tags
    .then (obj) ->
      # TODO 是否更新此package
      if obj.statusCode is 403
        console.log 'update this package...'
    .progress (notify) ->
      console.log notify.stdout if notify.stdout
      console.error notify.stderr if notify.stderr
    .catch (error) ->
      console.trace error.stack
      done(error)
      alert("#{error}")
    .finally ->
      console.log "publish package finally."
