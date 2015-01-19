fs = require 'fs-extra'
path = require 'path'
Q = require 'q'

module.exports =
class PackageManager

  activate: ->
    atom.workspaceView.command "atom-chameleon:create-package", => @cmdCreatePackage()
    atom.workspaceView.command "atom-chameleon:list-package", => @cmdPublishPackage()
    atom.workspaceView.command "atom-chameleon:publish-package", => @cmdPublishPackage()

  deactivate: ->
    @packageListView?.destroy?()
    @packageListView?.destroy?()

  cmdCreatePackage: ->
    @packageWizardView = new (require('./package-wizard-view'))() #unless @packageWizardView?
    @packageWizardView.attach()
    @packageWizardView.on 'finish', (options) =>
      @packageWizardView.destroy()

      package_path = path.resolve atom.project.path, options.name
      Q.nfcall fs.mkdirs, package_path
      .then -> Q.nfcall(fs.copy, options.icon_path, "#{package_path}/icon.png") if options.icon_path
      .then ->
        Q.promise (resolve, reject, notify)->
          ws = fs.createWriteStream "#{package_path}/package.json"
          ws.write """
          {
            "name": "#{options.title}",
            "identifier": "#{options.identifier}",
            "version": "#{options.version}",
            "description": "#{options.description}",
            "build": "1",
            "dependencies": "{}",
            "releaseNote": "#{options.title}",
            "hidden": false
          }
          """, (err)->
            if err then resolve() else reject(err)
      .catch (err)->
        alert(JSON.stringfiy err)

  cmdPublishPackage: ->
    @packageListView = new (require './package-list-view')() unless @packageListView?
    @packageListView.attach()
