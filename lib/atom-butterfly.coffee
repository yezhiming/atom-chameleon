ProgressView = require './utils/progress-view'
_ = require 'underscore'
{openDirectory} = require('./utils/dialog')
{generateKeyPair} = require './utils/gitApi'
path = require 'path'
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
    puzzleServerAddress: 'http://localhost:8080'
    puzzleServerAddressSecured: 'https://localhost:8443'
    puzzleAccessToken: ''
    gitCloneEnvironmentPath: ''

  activate: (state) ->
    # git ssh 策略：ide每次检测不存在就默认生成keypair
    home = process.env.USERPROFILE || process.env.HOME || process.env.HOMEPATH
    exist1 = fs.existsSync "#{home}/.ssh/id_dsa"
    exist2 = fs.existsSync "#{home}/.ssh/id_dsa.pub"
    if (!localStorage.getItem 'installedSshKey') or (!exist1) or (!exist2)
      # 生成默认的公、密钥到userhome/.ssh
      if atom.config.get('atom-butterfly.gitCloneEnvironmentPath')
        # 自动添加环境变量
        envPath = process.env.PATH || process.env.Path
        envPath += "#{path.delimiter}#{atom.config.get('atom-butterfly.gitCloneEnvironmentPath')}"
      generateKeyPair(home)

    # create access_token if necessary
    token = atom.config.get('atom-butterfly.puzzleAccessToken')
    atom.config.set('atom-butterfly.puzzleAccessToken', UUID.v4()) unless token

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

    atom.workspaceView.command "atom-butterfly:debug", => @cmdDebug()
    atom.workspaceView.command "atom-butterfly:debug-emulator", => @cmdDebugEmulator()

    #New
    atom.workspaceView.command "atom-butterfly:create-project", => @cmdCreateProject()
    atom.workspaceView.command "atom-butterfly:create-file", => @cmdCreateFile()

  deactivate: ->
    @projectManager.deactivate?()
    @packageManager.deactivate?()
    @fileManager.deactivate?()
    @buildManager.deactivate?()
    @emulatorManager.deactivate?()
    @gitCreatePackageManager.deactivate?()

  cmdDebugEmulator: ->
    document.querySelector('webview').openDevTools()

  cmdDebug: ->
    # BowerView = require './scaffold/bower-view'
    # new BowerView().attach()
    # webview = document.querySelector('webview')
    # webview.openDevTools() unless webview.isDevToolsOpened()

    bsv = new (require './build/build-state-view')()
    bsv.attach()

  cmdCreateProject: ->

    ProjectWizardView = require './project/project-wizard-view'
    projectWizardView = new ProjectWizardView().attach()
    pv = new ProgressView("Create Project...")

    projectWizardView.finishPromise()
    # select dest path
    .then (options) ->
      # composite promise combine result with previous result
      openDirectory(title: 'Select Path')
      .then (destPath) -> Q(_.extend(options, path: destPath[0]))

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

    .progress (progress)->
      pv.setTitle(progress.message) if progress.message
      pv.setProgress(progress.progress) if progress.progress
      console.log progress.out if progress.out
    .catch (error) ->
      console.trace error.stack
      alert("#{error}")
    .finally ->
      pv.destroy()
