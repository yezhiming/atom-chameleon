{View} = require "atom"
_ = require "underscore"
AdmZip = require 'adm-zip'
path = require 'path'
fs = require 'fs'

module.exports =
  class PackageListView extends View

    @content: ->
      @div class: 'overlay from-top select-list', =>
        @ol outlet: 'list', class: 'list-group package-list'
        @button 'Cancel', click: 'onClickCancel', class: "btn btn-lg"

    attach: ->
      packageFiles = []
      modules = []
      projectDir = atom.project.getDirectories()[0]
      subEntries = projectDir.getEntriesSync()
      _.each subEntries, (entity) =>
        if entity.isDirectory()
          packageFile = entity.getFile 'package.json'
          packageFiles.push packageFile if packageFile

      _.each packageFiles, (packageFile) =>
        packageContent = packageFile.read()
        packageContent.done (text) =>
          modules.push {
            path: packageFile.getPath()
            package: if text then JSON.parse text else null
          }
          @showPackageList modules if modules.length is packageFiles.length


      return this

    showPackageList: (modules)->
      console.log 'showPackageList'
      @list.html ''
      PackageCell = require './package-cell-template'
      for module in modules
        if(module.package)
          cell = new PackageCell(module)
          cell.on 'upload', @upload
          @list.append cell

      atom.workspaceView.append this

    upload: (cell, module)->
      cell.changeState 'upload'
      setTimeout ->
        modulePath = path.dirname module.path
        zip = new AdmZip()
        zip.addLocalFolder path.join modulePath, '/'
        buf = zip.toBuffer()
        # fs.writeFile (path.join modulePath, 'module.zip') ,buf , {}, (err)->
        #   console.log err if err
      , 500

    onClickCancel: ->
      @destroy()

    destroy: ->
      @detach()
