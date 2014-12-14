{View} = require "atom"
_ = require "underscore"
AdmZip = require 'adm-zip'
path = require 'path'
fs = require 'fs'
request = require 'request'
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

request_get = (options) ->
  args = arguments
  Q.Promise (resolve, reject, notify) ->
    request.get options, (err, response, body) ->
      if "#{response.statusCode}".startsWith('2') and not err
        resolve(JSON.parse body)
      else
        reject(err)

request_post = (options) ->
  args = arguments
  Q.Promise (resolve, reject, notify) ->
    console.log "!#{args}"
    request.post options, (err, response, body) ->
      if "#{response.statusCode}".startsWith('2') and not err
        resolve(JSON.parse body)
      else
        reject(err)

C_Server = atom.config.get 'atom-butterfly.chameleonServerAddress'

module.exports =
class PackageListView extends View

  @content: ->
    @div class: 'overlay from-top select-list', =>
      @ol outlet: 'list', class: 'list-group package-list'
      @button 'Cancel', click: 'destroy', class: "btn btn-lg"

  attach: ->
    request = request.defaults({jar: true})

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
        array.push path: path.resolve(root, pair[0]), package: pair[1]
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

    @login 'cube', 'cube', 'cube'
    .then (result) =>
      throw new Error('login fail') unless result.result is 'true'
      console.log "upload"
      zip = new AdmZip()
      zip.addLocalFolder module.path
      @uploadAttach zip.toBuffer()
    .then (result) =>
      console.log "validate"
      throw new Error('upload fail') unless result.result is 'success'
      @validateAttach result.id
    .then (result) =>
      console.log "new module"
      throw new Error('validate fail') unless result.result is 'success'
      @createModule _.extend result, {widget_id: '548698920cf2da4e8927bab5', boundle: id}
    .then (result) ->
      cell.changeState 'normal' if result.result is 'success'
    .catch (err) ->
      console.trace err.stack

  #模块上传流程
  #1.上传模块压缩包到变色龙后台
  #2.通过返回的id校验模块的合法性
  #3.新增模块
  validateAttachment: (id, success, error) ->
    r = request.get "#{C_Server}/bsl-web/mam/attachment/readfile/#{id}", (err, res, body)=>
      return error err if err
      success JSON.parse(body) if success

  newModule: (data, success, error) ->
    r = request.post "#{C_Server}/bsl-web/mam/widgetVersion/add", (err, res, body)=>
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

  login: (tanant, username, password) ->
    console.log "login"
    request_post
      url: "#{C_Server}/bsl-web/system/account/login"
      form:
        accUsername: tanant
        username: username
        password: password

  validateAttach: (id) ->
    request_get "#{C_Server}/bsl-web/mam/attachment/readfile/#{id}"

  uploadAttach: (buf) ->
    # request_post url: "#{C_Server}/bsl-web/mam/attachment/upload",
    #   form:
    #     file: buf
    #     filename: 'upload.zip'
    #     contentType: 'application/zip'

    Q.Promise (resolve, reject, notify) ->
      r = request.post "#{C_Server}/bsl-web/mam/attachment/upload", (err, res, body)=>
          if err
            reject(err)
          else
            resolve JSON.parse(body)

      form = r.form()
      form.append "file", buf,
        filename: 'upload.zip'
        contentType: 'application/zip'

  destroy: ->
    @detach()
