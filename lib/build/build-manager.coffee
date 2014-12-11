module.exports =
class BuildManager

  activate: ->
    console.log "build manager launch..."
    atom.workspaceView.command "atom-chameleon:publish-application", => @cmdPublishApplication()

  cmdPublishApplication: ->

    PublishAppView = require './publish-wizard-view'
    buildWizard = new PublishAppView().attach()

    buildWizard.finishPromise()
    .then (result)->
      buildWizard.destroy()
      console.log "#{JSON.stringify result}"
