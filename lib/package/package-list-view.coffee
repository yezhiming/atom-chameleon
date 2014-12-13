{View} = require "atom"
_ = require "underscore"
AdmZip = require 'adm-zip'
path = require 'path'
fs = require 'fs'
request = require 'request'
async = require 'async'
Q = require 'q'

readdir = Q.denodeify fs.readdir
stat = Q.denodeify fs.stat
readFile = Q.denodeify fs.readFile

exists = (path) ->
  Q.Promise (resolve, reject, notify) ->
    fs.exists path, (exists) -> resolve(exists)

isButterflyPackage = (p) ->
  json_path = path.resolve(p, 'package.json')
  exists(json_path).then (e) ->
    if e
      readFile json_path
      .then (content) ->  _.has JSON.parse(content), 'identifier'
    else
      false

module.exports =
  class PackageListView extends View

    @content: ->
      @div class: 'overlay from-top select-list', =>
        @ol outlet: 'list', class: 'list-group package-list'
        @button 'Cancel', click: 'destroy', class: "btn btn-lg"

    attach: ->
      request = request.defaults({jar: true})
      @loginServer 'cube', 'cube', 'cube', (data)->
        console.log data

      root = atom.project.path

      readdir(root)
      # filter butterfly packages
      .then (files) ->

        promises = _.map files, (file) ->
          isButterflyPackage path.resolve(root, file)

        Q.spread promises, ->
          mappings = _.object(files, arguments)
          packages = _.pick mappings, (is_butterfly_package, file) -> is_butterfly_package
          _.keys(packages)

      # <file-name, json>
      .then (files) ->
        # promises that read package.json and parse it into object
        promises = _.map files, (file) ->
          readFile path.resolve(root, file, 'package.json')
          .then (content) -> JSON.parse(content)

        Q.spread promises, ->
          map = _.object(files, arguments)
      # format translate
      .then (map) ->
        _.chain(map).pairs()
        .reduce (array, pair) ->
          array.push path: pair[0], package: pair[1]
          return array
        , []
        .value()
      # show up
      .then (map) =>
        @showPackageList map
      .catch (err) ->
        console.log err.message
        console.trace err.stack

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

    destroy: ->
      @detach()
