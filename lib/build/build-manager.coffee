fs = require 'fs'
request = require 'request'
Q = require 'q'

module.exports =
class BuildManager

  activate: ->
    console.log "build manager launch..."
    atom.workspaceView.command "atom-chameleon:publish-application", => @cmdPublishApplication()

  deactivate: ->

  cmdPublishApplication: ->

    PublishAppView = require './publish-wizard-view'
    buildWizard = new PublishAppView().attach()

    buildWizard.finishPromise()
    .then (result) =>
      console.log "#{JSON.stringify result}"
      buildWizard.destroy()
      @sendBuildRequest(result)

    .then (result) ->
      result = JSON.parse result[1]
      buildStatusView = new (require './build-status-view')(result.id)
      buildStatusView.attach()
    .catch (err) ->
      console.trace err.stack
      alert "err occur! #{err}"

  sendBuildRequest: (options) ->
    if options.platform == "android"
      Q.nfcall request.post, 'http://localhost:3000/api/tasks',
        form:
          builder: 'cordova-android'
          download_url: options.app_url
          buildtype: options.scheme
          keystore: fs.createReadStream options.keystore
          alias: options.alias
          keypass: options.keypass
          aliaspass: options.aliaspass
          version: options.version
          build: options.build
          title: options.title
          content_src: options.content_src
          icon: fs.createReadStream options.icon
    else
      Q.nfcall request.post, 'http://localhost:3000/api/tasks',
        form:
          builder: 'cordova-ios'
          mobileprovision: fs.createReadStream options.Mobileprovision
          p12: fs.createReadStream options.p12
          p12_password: options.p12_password
          scheme: options.scheme
          download_url: options.app_url
          icon: fs.createReadStream options.icon
          title: options.title
          version: options.version
          build: options.build
          content_src: options.content_src
          bundleIdentifier:options.BundleIdentifier
