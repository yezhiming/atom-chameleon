ProgressView = require './utils/progress-view'
_ = require 'underscore'
{openDirectory} = require('./utils/dialog')
UUID = require 'uuid'

# for debug properse only, it will add many ms to startup time.
Q = require 'q'
Q.longStackSupport = true

module.exports =

  configDefaults:
    chameleonServerAddress: 'http://localhost'
    tanant: ''
    username: ''
    puzzleServerAddress: 'http://localhost:8080'
    puzzleServerAddressSecured: 'https://localhost:8443'
    puzzleAccessToken: ''

  activate: (state) ->
    # create access_token if necessary
    token = atom.config.get('atom-butterfly.puzzleAccessToken')
    atom.config.set('atom-butterfly.puzzleAccessToken', UUID.v4()) unless token

    @packageManager = new (require './package/package-manager')()
    @packageManager.activate()

    @buildManager = new (require './build/build-manager')()
    @buildManager.activate()

    atom.workspaceView.command "atom-butterfly:debug", => @cmdDebug()

    #New
    atom.workspaceView.command "atom-butterfly:create-project", => @cmdCreateProject()
    atom.workspaceView.command "atom-butterfly:create-file", => @cmdCreateFile()

    #Product
    atom.workspaceView.command "atom-butterfly:install", => @cmdInstall()
    atom.workspaceView.command "atom-butterfly:run-on-server", => @cmdRunOnServer()
    atom.workspaceView.command "atom-butterfly:emulator", => @cmdLaunchEmulator()

  deactivate: ->
    @packageManager.deactivate?()
    @buildManager.deactivate?()

    @runOnServerView?.destroy()
    @serverStatusView?.destroy()

    @debugServer?.stop()

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
      {createProjectPromise} = require './project/scaffold'
      createProjectPromise(options)

    # open new project
    .then (projectPath)->
      atom.open {pathsToOpen: [projectPath]}

    .progress (progress)->
      pv.setTitle(progress.message) if progress.message
      pv.setProgress(progress.progress) if progress.progress
    .catch (error) ->
      console.trace error.stack
      alert('error occur!')
    .finally ->
      pv.destroy()

  cmdInstall: ->

    pv = new ProgressView("Install Butterfly.js...")
    pv.attach()

    Scaffolder = require './project/scaffold'
    Scaffolder.installFrameworkPromise()
    .progress (progress)->
      pv.setTitle(progress.message) if progress.message
      pv.setProgress(progress.progress) if progress.progress
    .then ->
      pv.destroy()

  cmdRunOnServer: ->

    @_setupDebugServer()

    RunOnServerView = require './run-on-server-view'
    @runOnServerView = new RunOnServerView()
    @runOnServerView.attach()
    @runOnServerView.on 'createServer', (event, rootPath, destPath, httpPort, pushState, api)=>
      @debugServer.start {
        rootPath: rootPath
        defaultPage: destPath
        httpPort: httpPort
        pushState: pushState
        api: api
      }

  _setupDebugServer: ->

    unless @serverStatusView and @debugServer

      ServerStatusView = require './server-status-view'
      @serverStatusView = new ServerStatusView()
      @serverStatusView.on 'stopServer', => @debugServer.stop()

      DebugServer = require './debug-server'
      @debugServer = new DebugServer()
      @debugServer.on 'start', => @serverStatusView.attach()
      @debugServer.on 'stop', => @serverStatusView.detach()

  cmdLaunchEmulator: ->

    unless @emulatorView?
      EmulatorView = require './emulator/emulator-view'
      @emulatorView = new EmulatorView()

    @emulatorView.toggle()
