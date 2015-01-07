module.exports =
class GitCreatePackageManager

  activate: ->
    atom.workspaceView.command "atom-butterfly:gitCreatePackage", => @gitCreatePackage()
    console.log "GitCreatePackageManager activate"


  gitCreatePackage: ->
    GitCreatePackageWizardView = require './gitCreatePackage-wizard-view'
    gitCreatePackageWizardView = new GitCreatePackageWizardView().attach()
    
    gitCreatePackageWizardView.finishPromise()
    .then (options) ->
      console.log options
    
    .catch (error) ->
      console.trace error.stack
      alert("#{error}")
    .finally ->
      console.log "finally"
