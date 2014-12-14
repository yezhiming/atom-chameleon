fs = require 'fs'
request = require 'request'
Q = require 'q'
_ = require 'underscore'

module.exports =
class BuildManager

  activate: ->
    atom.workspaceView.command "atom-chameleon:publish-application", => @cmdPublishApplication()
    @server = atom.config.get('atom-butterfly.puzzleServerAddress')

    atom.workspaceView.command "atom-chameleon:build-list", => @cmdBuildList()

  deactivate: ->

  cmdBuildList: ->
    new (require './build-list-view')().attach()

  cmdPublishApplication: ->

    PublishAppView = require './publish-wizard-view'
    buildWizard = new PublishAppView().attach()
    buildStateView = new (require './build-state-view')()

    buildWizard.finishPromise()
    .then (result) =>
      buildWizard.destroy()
      buildStateView.attach()

      require('../../utils/zip')(atom.project.path,"./","foreveross.zip").then (zip_path) ->_.extend(result, asset: zip_path)
    .then (result) =>
      @sendBuildRequest(result)
    .then (result) =>
      zip_path = "#{atom.project.path}/foreveross.zip"
      if fs.existsSync zip_path
        fs.unlinkSync(zip_path)
      JSON.parse result
    .then (task) ->
      buildStateView.setTask(task)
      

    .catch (err) ->
      buildStateView.destroy()
      console.trace err.stack
      alert "err occur! #{err}"

  sendBuildRequest: (options) ->
    console.log "options:#{options}"
    if options.platform == "android"
      
      Q.Promise (resolve, reject, notify) =>
        r = request.post "#{@server}/api/tasks",(err, httpResponse, body)=>
          if err then reject(err) else resolve(body)
        
        form = r.form()
        form.append "access_token","#{atom.config.get('atom-butterfly.puzzleAccessToken')}"
        form.append "builder","cordova-android"
        form.append "platform","android"
        form.append "repository_url","#{options.repository_url}"
        form.append "buildtype","#{options.scheme}"
        form.append "keystore",fs.createReadStream (options.keystore)
        form.append "alias","#{options.alias}"
        form.append "keypass","#{options.keypass}"
        form.append "aliaspass","#{options.aliaspass}"
        form.append "version","#{options.version}"
        form.append "build","#{options.build}"
        form.append "title","#{options.title}"
        form.append "content_src","#{options.content_src}"
        form.append "icon",fs.createReadStream(options.icon)
        form.append "asset",fs.createReadStream(options.asset)

    else
      Q.Promise (resolve, reject, notify) =>
        r = request.post "#{@server}/api/tasks",(err, httpResponse, body)=>
          if err then reject(err) else resolve(body)
        
        form = r.form()
        form.append "access_token","#{atom.config.get('atom-butterfly.puzzleAccessToken')}"
        form.append "builder","cordova-ios"
        form.append "platform","ios"
        form.append "mobileprovision",fs.createReadStream(options.Mobileprovision)
        form.append "p12",fs.createReadStream(options.p12)
        form.append "p12_password","#{options.p12_password}"
        form.append "scheme","#{options.scheme}"
        form.append "repository_url","#{options.repository_url}"
        form.append "icon",fs.createReadStream(options.icon)
        form.append "title","#{options.title}"
        form.append "version","#{options.version}"
        form.append "build","#{options.build}"
        form.append "content_src","#{options.content_src}"
        form.append "bundleIdentifier","#{options.BundleIdentifier}"
        form.append "asset",fs.createReadStream(options.asset)
