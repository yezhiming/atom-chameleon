ProgressView = require './utils/progress-view'
_ = require 'underscore'
{openDirectory} = require('./utils/dialog')
{generateKeyPair} = require './utils/gitApi'
UUID = require 'uuid'
fs = require 'fs'
# for debug properse only, it will add many ms to startup time.
Q = require 'q'
Q.longStackSupport = true


module.exports =

  configDefaults:
    chameleonServerAddress: 'http://bsl.foreveross.com'
    chameleonTanant: 'cube'
    chameleonUsername: 'cube'
    puzzleServerAddress: 'http://bsl.foreveross.com/puzzle' # http://localhost:8000/puzzle
    puzzleServerAddressSecured: 'https://bsl.foreveross.com/puzzle' # https://localhost:8443/puzzle
    puzzleAccessToken: ''
    gitCloneEnvironmentPath: ''

  activate: (state) ->

    localStorage.removeItem 'github' # 重启就要github认证，不然会报错，暂时这样
    localStorage.removeItem 'gogs' # 重启就要gogs认证，不然会报错，暂时这样
    # git ssh 策略：ide每次检测不存在就默认生成keypair
    # home = process.env.USERPROFILE || process.env.HOME || process.env.HOMEPATH
    # exist1 = fs.existsSync "#{home}/.ssh/id_dsa"
    # exist2 = fs.existsSync "#{home}/.ssh/id_dsa.pub"
    # if (!localStorage.getItem 'installedSshKey') or (!exist1) or (!exist2)
    #   options =
    #     maxBuffer: 1024*1024*10
    #   options.env = path: atom.config.get('atom-chameleon.gitCloneEnvironmentPath') if atom.config.get('atom-chameleon.gitCloneEnvironmentPath') # 一般mac不需要配置
    #   # 生成默认的公、密钥到userhome/.ssh
    #   generateKeyPair
    #     home: home
    #     options
      #     if process.platform is 'win32' and (!process.env.Path.contains "#{atom.config.get('atom-chameleon.gitCloneEnvironmentPath')}")
      #       # TODO 这里要重启windows，atom才能读取到系统变量 真是蛋碎 T^T
      #       command = "setx PATH \"%PATH%#{path.delimiter}#{atom.config.get('atom-chameleon.gitCloneEnvironmentPath')}\""
      #     else if process.platform != 'win32' and (!process.env.PATH.contains "#{atom.config.get('atom-chameleon.gitCloneEnvironmentPath')}")
      #       command = "cat /etc/profile && echo \\nexport PATH=$PATH#{path.delimiter}#{atom.config.get('atom-chameleon.gitCloneEnvironmentPath')} >> /etc/profile && source /etc/profile"
      #     cp = exec command, (error, stdout, stderr) ->
      #         if error
      #           reject(error)
      #         else
      #           console.log stdout.toString()
      #           console.log stderr.toString()
      #           resolve()
      # .then ->
      #   generateKeyPair(home)

    # create access_token if necessary
    token = atom.config.get('atom-chameleon.puzzleAccessToken')
    atom.config.set('atom-chameleon.puzzleAccessToken', UUID.v4()) unless token

    @projectManager = new (require './project/project-manager')()
    @projectManager.activate()

    @packageManager = new (require './package/package-manager')()
    @packageManager.activate()

    @fileManager = new (require './file/file-manager')()
    @fileManager.activate()

    @buildManager = new (require './build/build-manager')()
    @buildManager.activate()

    @emulatorManager = new (require './emulator/emulator-manager')()
    @emulatorManager.activate()

    @gitCreatePackageManager = new (require './gitCreatePackage/gitCreatePackage-manager')()
    @gitCreatePackageManager.activate()

    @packageCenterManager = new (require './package/package-center-manager')
    @packageCenterManager.activate()

    atom.workspaceView.command "atom-chameleon:debug", => @cmdDebug()
    atom.workspaceView.command "atom-chameleon:debug-emulator", => @cmdDebugEmulator()

    #New
    atom.workspaceView.command "atom-chameleon:create-project", => @cmdCreateProject()
    atom.workspaceView.command "atom-chameleon:create-file", => @cmdCreateFile()

  deactivate: ->
    @projectManager.deactivate?()
    @packageManager.deactivate?()
    @fileManager.deactivate?()
    @buildManager.deactivate?()
    @emulatorManager.deactivate?()
    @gitCreatePackageManager.deactivate?()

  cmdDebugEmulator: ->
    try
      webview = document.querySelector('webview')
      # console.log "webview.isDevToolsOpened(): #{webview.isDevToolsOpened()}"
      if webview.isDevToolsOpened()
        webview.closeDevTools()
      else
        webview.openDevTools()
    catch
      console.log "webview not open"
      alert "Please open the Emulator."


  cmdDebug: ->
    # BowerView = require './scaffold/bower-view'
    # new BowerView().attach()
    # webview = document.querySelector('webview')
    # webview.openDevTools() unless webview.isDevToolsOpened()

    bsv = new (require './build/build-state-view')()
    bsv.attach()

  cmdCreateFile: ->
    alert "This feature is in development."

  cmdCreateProject: ->

    ProjectWizardView = require './project/project-wizard-view'
    projectWizardView = new ProjectWizardView()
    pv = new ProgressView("Create Project...")

    # 检测是否存在网络
    (require "../utils/checkNetwork")("http", "http://www.baidu.com")
    .then =>
      Q.Promise (resolve, reject, notify) =>
        projectWizardView.attach()
        isOpenDialog = false
        projectWizardView.on 'finish', (result) ->
          if isOpenDialog
            return
          isOpenDialog = true
          # composite promise combine result with previous result
          openDirectory(title: 'Select Path')
          .then (destPath) ->
            resolve _.extend(result, path: destPath[0])
          .finally ->
            isOpenDialog = false

    # do UI stuffs
    .then (options)->
      projectWizardView.destroy()
      pv.attach()
      Q(options)

    # create project with options
    .then (options) ->
      switch options.template
        when 'simple' then options.repo = "https://github.com/yezhiming/butterfly-starter.git"
        when 'modular' then options.repo = "https://git.oschina.net/cwlay/ModuleManager.git"
        else options.repo = "https://git.oschina.net/cwlay/ModuleManager.git"

      # promise of project creation
      (require "./project/scaffolder")(options)

    # open new project
    .then (projectPath)->
      atom.open {pathsToOpen: [projectPath]}
      
      if atom.packages.getActivePackage('tree-view').mainModule.treeView
        if atom.packages.getActivePackage('tree-view').mainModule.treeView.isHidden()
          atom.workspaceView.trigger "tree-view:toggle"

    .progress (progress)->
      pv.setTitle(progress.message) if progress.message
      pv.setProgress(progress.progress) if progress.progress
      console.log progress.out if progress.out
    .catch (error) ->
      console.trace error.stack
      alert("#{error}")
    .finally ->
      pv.destroy()
