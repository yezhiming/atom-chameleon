{View} = require "atom"
_ = require "underscore"
AdmZip = require 'adm-zip'
path = require 'path'
fs = require 'fs'
request = require 'request'

module.exports =
  class PackageListView extends View

    @content: ->
      @div class: 'overlay from-top select-list', =>
        @ol outlet: 'list', class: 'list-group package-list'
        @button 'Cancel', click: 'onClickCancel', class: "btn btn-lg"

    attach: ->
      request = request.defaults({jar: true})
      @loginServer 'cube', 'cube', 'cube', (data)->
        console.log data

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
          cell.on 'upload', (cell, module)=>
            @upload(cell, module)
          @list.append cell

      atom.workspaceView.append this

    upload: (cell, module)->
      cell.changeState 'upload'
      setTimeout =>
        modulePath = path.dirname module.path
        zip = new AdmZip()
        zip.addLocalFolder path.join(modulePath, '/')
        # zip.writeZip path.join modulePath, 'update.zip'
        # return
        buf = zip.toBuffer()
        @uploadAttachment buf, (data)=>
          console.log data
          if data.result is 'success' and data.id
            id = data.id
            @validateAttachment id, (data)=>
              console.log data
              if data.result is 'success'
                params = _.extend data,
                  widget_id: '548698920cf2da4e8927bab5'
                  boundle: id
                @newModule params, (data)=>
                  console.log data
                  cell.changeState 'normal' if data.result is 'success'
                , (err)->
                  console.log err

            , (err)->
              console.log err

        , (err)->
          console.log err
      , 500

    #模块上传流程
    #1.上传模块压缩包到变色龙后台
    #2.通过返回的id校验模块的合法性
    #3.新增模块

    uploadAttachment: (file, success, error) ->
      r = request.post 'http://bsl.foreveross.com/bsl-web/mam/attachment/upload', (err, res, body)=>
          return error err if err
          success JSON.parse(body) if success

      form = r.form();
      form.append "file", file,
        filename: 'upload.zip'
        contentType: 'application/zip'

    validateAttachment: (id, success, error) ->
      r = request.get "http://bsl.foreveross.com/bsl-web/mam/attachment/readfile/#{id}", (err, res, body)=>
        return error err if err
        success JSON.parse(body) if success

    newModule: (data, success, error) ->
      r = request.post "http://bsl.foreveross.com/bsl-web/mam/widgetVersion/add", (err, res, body)=>
        return error err if err
        success JSON.parse(body) if success

      form = r.form()
      form.append 'name', data.name
      form.append 'identify', data.identifier
      form.append 'boundle', data.boundle
      form.append 'build', data.build
      form.append 'version', data.version
      form.append 'release_not', data.releaseNote
      form.append 'widget_id', data.widget_id

    loginServer: (acc, username, password, success, error) ->
      r = request.post 'http://bsl.foreveross.com/bsl-web/system/account/login', (err, res, body)=>
        return error err if err
        success JSON.parse(body) if success
      form = r.form()
      form.append 'accUsername', acc
      form.append 'username', username
      form.append 'password', password

    onClickCancel: ->
      @destroy()

    destroy: ->
      @detach()
