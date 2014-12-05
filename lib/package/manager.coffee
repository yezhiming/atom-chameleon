fs = require 'fs-plus'
path = require 'path'
Q = require 'q'

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
    @packageWizardView = new (require('./package-wizard-view'))() unless @packageWizardView?
    @packageWizardView.attach()
    @packageWizardView.on 'finish', (options) =>
      @packageWizardView.destroy()

      package_path = path.resolve atom.project.path, options.name
      Q.nfcall fs.mkdir, package_path
      .then -> Q.nfcall(fs.copy, options.icon_path, "#{package_path}/icon.png") if options.icon_path
      .then ->
        Q.promise (resolve, reject, notify)->
          ws = fs.createWriteStream "#{package_path}/package.json"
          ws.write """
          {
            "name": "#{options.title}",
            "identifier": "#{options.identifier}",
            "version": "#{options.version}",
            "description": "#{options.description}"
          }
          """, (err)->
            if err then resolve() else reject(err)
      .catch (err)->
        alert(JSON.stringfiy err)

  listPackage: ->
    @packageListView = new (require('./package-list-view'))() unless @packageListView?
    @packageListView.attach()
