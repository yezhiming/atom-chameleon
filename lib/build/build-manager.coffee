fs = require 'fs'
request = require 'request'
Q = require 'q'
_ = require 'underscore'

uuid = require 'uuid'

os = require 'os'

fsIsDirectorySync = (path) ->
  try
    stat = fs.statSync(path)
    stat.isDirectory()
  catch
    false

module.exports =
class BuildManager

  activate: ->
    atom.workspaceView.command "atom-chameleon:publish-application", => @cmdPublishApplication()
    @server = atom.config.get('atom-chameleon.puzzleServerAddress')

    atom.workspaceView.command "atom-chameleon:build-list", => @cmdBuildList()

  deactivate: ->

  cmdBuildList: ->
    # 检测是否存在网络
    (require "../../utils/checkNetwork")("http", "http://www.baidu.com")
    .then =>
      new (require './build-list-view')().attach()
    .catch (error) ->
      alert("#{error}")

  cmdPublishApplication: ->

    PublishAppView = require './publish-wizard-view'
    buildWizard = new PublishAppView()
    buildStateView = new (require './build-state-view')()

    # 这样就可以可以不仅在windows还是mac都可以获取到.atom路径
    decs = "#{os.tmpdir()}/atom-chameleon"
    zipFile = "#{uuid.v1()}.zip"
    unless fsIsDirectorySync(decs)
      console.log "新建文件夹：#{decs}"
      fs.mkdirSync decs
    removeZipPath = "#{decs}/#{zipFile}"

    # 检测是否存在网络
    (require "../../utils/checkNetwork")("http", "http://www.baidu.com")
    .then =>
      buildWizard.attach()
      buildWizard.finishPromise()
    .then (result) ->
      console.log "开始压缩..."
      buildWizard.destroy()
      buildStateView.attach()

      require('../../utils/zip')(atom.project.rootDirectories[0].path,removeZipPath).then (zip_path) ->_.extend(result, asset: zip_path)
    .then (result) ->
      console.log "结束压缩..."

      Q.Promise (resolve, reject, notify) ->
        buildStateView.socket.on "resSocketId", (sid) ->
          console.log "resSocketId:#{sid}"
          resolve(_.extend(result, socketId: sid))
        buildStateView.socket.emit "reqSocketId"
    .then (result) =>
      @sendBuildRequest(result)
    .then (result) ->
      buildStateView.buttonAbled()
      console.log "删除文件：#{removeZipPath}"
      if fs.existsSync removeZipPath
        fs.unlinkSync(removeZipPath)
      JSON.parse result
    .then (task) ->
      buildStateView.setTask(task)
    .catch (err) ->
      buildStateView.destroy()
      console.trace err.stack
      alert "err occur! #{err}"

  sendBuildRequest: (options) ->
    console.log "options:"
    console.log options
    if options.platform == "android"

      Q.Promise (resolve, reject, notify) =>
        r = request.post {url:"#{@server}/api/tasks",timeout: 1000*60*10}, (err, httpResponse, body)=>
          if err then reject(err) else resolve(body)

        form = r.form()
        form.append "access_token","#{atom.config.get('atom-chameleon.puzzleAccessToken')}"
        form.append "builder","cordova-android"
        form.append "platform","android"
        form.append "asset",fs.createReadStream(options.asset)
        form.append "socketId","#{options.socketId}"

        # 若不填写，使用默认图标
        unless options.icon is ""
          form.append "icon",fs.createReadStream(options.icon)

        # 以下只要一个信息不填写，那么就使用默认的证书发布安卓应用
        # unless ((options.keystore is "") && (options.keypass is "") && (options.alias is "") && (options.aliaspass is ""))
        if (options.keystore && options.keypass && options.alias && options.aliaspass)
          form.append "keystore",fs.createReadStream (options.keystore)
          form.append "keypass","#{options.keypass}"
          form.append "alias","#{options.alias}"
          form.append "aliaspass","#{options.aliaspass}"

        # 如果不填写，就使用默认库
        unless ((options.repository_url is "") && (options.scheme is ""))
          form.append "repository_url","#{options.repository_url}"
          form.append "buildtype","#{options.scheme}"

        # 不填写，使用默认启动页面
        unless (options.content_src is "")
          form.append "content_src","#{options.content_src}"

        form.append "version","#{options.version}"
        form.append "build","#{options.build}"
        form.append "title","#{options.title}"
        

    else if options.platform == "ios"
      Q.Promise (resolve, reject, notify) =>
        r = request.post {url:"#{@server}/api/tasks",timeout: 1000*60*10}, (err, httpResponse, body)->
          if err then reject(err) else resolve(body)

        form = r.form()
        form.append "access_token","#{atom.config.get('atom-chameleon.puzzleAccessToken')}"
        form.append "builder","cordova-ios"
        form.append "platform","ios"

        # 以下三个参数需要同时不为空，否则不发送到服务器  如果不填写，那么使用服务器的默认证书
        # unless ((options.mobileprovision is "") && (options.p12 is "") && (options.p12_password is ""))
        if options.mobileprovision && options.p12 && options.p12_password
          form.append "mobileprovision", fs.createReadStream(options.mobileprovision)
          form.append "p12",fs.createReadStream(options.p12)
          form.append "p12_password","#{options.p12_password}"

        form.append "bundleIdentifier","#{options.bundleIdentifier}"

        # 若不填写，使用默认图标
        unless options.icon is ""
          form.append "icon",fs.createReadStream(options.icon)

        # # 下面是库连接，只要一下一个值为空，就是使用默认的github地址进行下载
        unless ((options.repository_url is "") || (options.scheme is ""))
          form.append "scheme","#{options.scheme}"
          form.append "repository_url","#{options.repository_url}"

        unless (options.content_src is "")
          form.append "content_src","#{options.content_src}"

        # 是否使用push servers
        # unless ((options.pushp12 is "") && (options.pushp12password is ""))
        if options.pushp12 && options.pushp12password
          form.append "pushp12",fs.createReadStream(options.pushp12)
          form.append "pushp12password",options.pushp12password

        form.append "title","#{options.title}"
        form.append "version","#{options.version}"
        form.append "build","#{options.build}"

        form.append "asset",fs.createReadStream(options.asset)
        form.append "socketId","#{options.socketId}"
  
    else if options.platform == "ios-fastbuild"

      Q.Promise (resolve, reject, notify) =>
        r = request.post {url:"#{@server}/api/tasks",timeout: 1000*60*10}, (err, httpResponse, body)->
          if err then reject(err) else resolve(body)

        form = r.form()
        form.append "access_token","#{atom.config.get('atom-chameleon.puzzleAccessToken')}"
        form.append "builder","cordova-ios-fastBuild"
        form.append "platform","ios-fastbuild"
        
        form.append "bundleIdentifier","#{options.bundleIdentifier}"

        form.append "icon",fs.createReadStream(options.icon)

        form.append "scheme","#{options.scheme}"

        unless (options.content_src is "")
          form.append "content_src","#{options.content_src}"

        form.append "title","#{options.title}"
        form.append "version","#{options.version}"
        form.append "build","#{options.build}"

        form.append "asset",fs.createReadStream(options.asset)
        form.append "socketId","#{options.socketId}"

    else if options.platform == "android-fastbuild"
      Q.Promise (resolve, reject, notify) =>
        r = request.post {url:"#{@server}/api/tasks",timeout: 1000*60*10}, (err, httpResponse, body)=>
          if err then reject(err) else resolve(body)

        form = r.form()
        form.append "access_token","#{atom.config.get('atom-chameleon.puzzleAccessToken')}"
        form.append "builder","cordova-android-fastbuild"
        form.append "platform","android-fastbuild"
        form.append "asset",fs.createReadStream(options.asset)
        form.append "socketId","#{options.socketId}"

        form.append "scheme","#{options.scheme}"
        form.append "icon",fs.createReadStream(options.icon)
        form.append "content_src","#{options.content_src}"
        form.append "version","#{options.version}"
        form.append "build","#{options.build}"
        form.append "title","#{options.title}"
