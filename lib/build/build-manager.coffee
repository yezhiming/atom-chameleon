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

    .then (response, body) ->
      buildStatusView = new (require './build-status-view')
      buildStatusView.attach()
    .catch (err) ->
      console.trace err.stack
      alert 'err occur!'

  sendBuildRequest: (options) ->
    Q.nfcall request.post, 'http://localhost:3000/api/tasks',
      form:
        builder: 'cordova-ios'
        mobileprovision: fs.createReadStream options.Mobileprovision
        p12: fs.createReadStream options.p12
        p12_password: options.p12_password
        scheme: options.scheme
        download_url: options.app_url
        icon:options.icon
        title: options.title
        version: options.version
        build: options.build
        content_src: options.content_src
