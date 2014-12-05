module.exports =
class PackageManager

  activate: ->
    console.log "package manager launch..."
    atom.workspaceView.command "atom-butterfly:create-package", => @cmdCreatePackage()
    atom.workspaceView.command "atom-butterfly:list-package", => @listPackage()
    atom.workspaceView.command "atom-chameleon:publish-package", => @cmdPublishPackage()

  destroy: ->
    @packageListView?.destroy?()
    @packageListView?.destroy?()

  cmdCreatePackage: ->
    unless @packageWizardView?
      PWV = require('./package-wizard-view')
      @packageWizardView = new PWV()
    @packageWizardView.attach()

  listPackage: ->
    unless @packageListView?
      PLV = require('./package-list-view')
      @packageListView = new PLV()
    @packageListView.attach()
