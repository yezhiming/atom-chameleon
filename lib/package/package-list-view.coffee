{View} = require "atom"
_ = require "underscore"
zip = require '../../utils/zip'
path = require 'path'
fs = require 'fs'
request = require 'request'
Q = require 'q'
# encrypt = require './sandbox/sandboxLite'

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
      @span class: "loading loading-spinner-small inline-block pull-right",outlet: 'loading'

  attach: ->
    request = request.defaults({jar: true})

    root = atom.project.path

    @loading.hide();

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
    .catch (err) =>
      console.log err.message
      console.trace err.stack

    return this

  showPackageList: (modules)->
    console.log 'showPackageList'
    @list.html ''
    PackageCell = require './package-cell-template'
    for module in modules
      _package = module.package
      if(_package && _package.build && _package.version)
        cell = new PackageCell(module)
        cell.on 'upload', (cell, module)=>
          @upload(cell, module)
        @list.append cell

    atom.workspaceView.append this

    #   @encrypt module.path, (path.join atom.project.path, 'encrypt', module.package.identifier)
    # .then (result) =>
  upload: (cell, module)->
    cell.changeState 'upload'
    @loading.show();
    @login 'cube', 'cube', 'cube'
    .then (result) =>
      throw new Error('login fail') unless result.result is 'true'
      console.log "upload"
      zip(module.path, module.path).then (zipPath) =>
        @uploadAttach zipPath + '.zip'
    .then (result) =>
      console.log "validate"
      throw new Error('upload fail') unless result.result is 'success'
      @validateAttach(result.id).then (nResult) -> _.extend(nResult, boundle: result.id)
    .then (result) =>
      console.log "fetchWidgetId"
      @fetchWidgetIdByIdentifier(module.package.identifier).then (nResult) ->
        _.extend(result, widget_id: nResult.id)
    .then (result) =>
      console.log "new module"
      throw new Error('validate fail') unless result.result is 'success'
      @newModule _.extend result, {widget_id: result.widget_id}
    .then (result) =>
      @loading.hide();
      cell.changeState 'normal' if result.result is 'success'
    .catch (err) =>
      @loading.hide();
      console.trace err.stack

  #模块上传流程
  #1.上传模块压缩包到变色龙后台
  #2.通过返回的id校验模块的合法性
  #3.新增模块
  validateAttachment: (id, success, error) ->
    r = request.get "#{C_Server}/bsl-web/mam/attachment/readfile/#{id}", (err, res, body)=>
      return error err if err
      success JSON.parse(body) if success

  fetchWidgetIdByIdentifier: (id, success, error) ->
    r = request_get "http://115.28.1.119:18860/mam/api/mam/widget/checkIdentity?identify=#{id}"

  newModule: (data, success, error) ->

    Q.Promise (resolve, reject, notify) ->

      r = request.post "#{C_Server}/bsl-web/mam/widgetVersion/add", (err, res, body)=>
        if err then reject(err) else resolve JSON.parse(body)

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

  uploadAttach: (zipPath) ->

    Q.Promise (resolve, reject, notify) ->
      r = request.post "#{C_Server}/bsl-web/mam/attachment/upload", (err, res, body)=>
          fs.unlink zipPath
          if err then reject(err) else resolve JSON.parse(body)

      form = r.form()
      form.append "file", fs.createReadStream(zipPath),
        filename: 'upload.zip'
        contentType: 'application/zip'

  encrypt: (sourceDir, targetDir) ->

    Q.Promise (resolve, reject, notify) ->
      encrypt sourceDir, targetDir, 'foreveross', (err)=>
        if err then reject(err) else resolve()

  destroy: ->
    @detach()
