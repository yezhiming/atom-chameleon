#
# 显示任务状态，点击构建时弹出，作为一个tab
#
{$, View, SelectListView, $$} = require 'atom'
qrcode = require '../utils/qrcode'
request = require 'request'
io = require 'socket.io-client'
Q = require 'q'

puzzleClient = require '../utils/puzzle-client'
ConsoleView = require '../utils/console-view'

{allowUnsafeNewFunction} = require('loophole')
Download = allowUnsafeNewFunction -> require 'download'

Device = require '../../script/runDevice'

module.exports =
class BuildStatusView extends View
  @content: ->
    @div class: 'build-state-view butterfly overlay from-top', =>
      @h1 'Build Status'
      @div style: 'text-align: center', =>
        @span outlet: 'loading', class: 'loading loading-spinner-large inline-block'

      @div =>
        @div class: "form-group", =>
          @label 'ID:'
          @span class: 'task-id'
        @div class: "form-group", =>
          @label 'UUID:'
          @span class: 'task-uuid'
        @div class: "form-group", =>
          @label 'State:'
          @span class: 'task-state'
          @span class: 'glyphicon glyphicon-remove text-error hidden'

        @div id: 'qrcode'

        @subview 'console', new ConsoleView()

      @div class: 'actions', =>
        @div class: 'pull-left',outlet:"closebutton", =>
          @button 'Close', click: 'destroy', class: 'inline-block-tight btn'

        @div class: 'pull-right', =>
          @button 'Cancel', click: 'cancel',outlet:'cancelbutton', class: 'inline-block-tight btn'
          @button 'Refresh', click: 'refreshTaskState',outlet:'refreshbutton', class: 'inline-block-tight btn'

  initialize: ->
    @cancelbutton.disable()
    @refreshbutton.disable()

  attach: ->
    atom.workspaceView.append(this)

    @console.toggleLogger()

    console.log "try to connect."

    # puzzleClient.server: http://bsl.foreveross.com/puzzle/socketio 服务器默认的path为/
    hostName = puzzleClient.server.substr 0, puzzleClient.server.lastIndexOf('/')
    console.log 'hostName: %s', hostName

    @socket = io "http://115.28.1.109:8000/socketio",
      reconnection: true
      reconnectionDelay: 50
      reconnectionDelayMax: 12000
      timeout: 3000

    @socket.on 'connect', =>
      console.log "socket connected. #{puzzleClient.access_token}"
      @socket.emit 'bind', puzzleClient.access_token

    @socket.on 'disconnect', ->
      console.log "socket disconnected."

    @socket.on 'reconnect', (n)->
      console.log "socket reconnect. #{n} counts"

    @socket.on 'error', (err) ->
      console.log "socket error: #{err}"

    @socket.on 'timeout', ->
      console.log "socket timeout"

    @socket.on 'update', (job) =>
      console.log "task #{job.id} updated"
      @setTask(job)
      # if job.id == @task.id
      #   console.log "task #{job.id} updated"
      #   @task = job
      #   @find('.task-state').text job.state
      #   @showState(job)

    @socket.on 'stdout', (out) => @console.append(out.content)

    @socket.on 'stderr', (out) => @console.append(out.content, 'text-error')

  destroy: ->
    @remove()

  setTask: (@task) ->
    @find('.task-id').text @task.id
    @find('.task-uuid').text @task.data.uuid
    @find('.task-state').text @task.state

    @showState(@task)

  showState: (task) ->
    @loading.show()

    switch task.state
      when 'complete'
        @loading.hide()
        @updateQRCode(task.data.platform)
        @cancelbutton.disable()
        @refreshbutton.disable()
      when 'failed'
        @loading.hide()
        @find('.glyphicon-remove').removeClass('hidden')
        @cancelbutton.disable()
        @refreshbutton.disable()


  refreshTaskState: ->

    puzzleClient.getTask @task.id
    .then (task) => @setTask(task)
    .catch (err) -> alert "error: #{err}"

  updateQRCode: (platform) ->
    console.log "update qrcode for platform: #{platform}"
    qr = qrcode(4, 'M')
    if platform == 'ios'
      # @devicebtn.show()
      qr.addData("#{puzzleClient.serverSecured}/archives/#{@task.id}/install/ios")
    else if platform == 'android'
      qr.addData("#{puzzleClient.serverSecured}/archives/#{@task.id}.apk")
    else
      throw new Error('qrcode: unkown platform.')
    qr.make()
    imgTag = qr.createImgTag(4)
    @find('#qrcode').empty().append(imgTag)

  DeviceFun:->
    # https://172.16.1.95:8443/archives/device/4/ios
    downLoadPath = "#{puzzleClient.server}/archives/device/#{@task.id}/ios"
    # downLoadPath = "http://172.16.1.95:8080/archives/device/5/ios"
    destPath = "#{atom.project.path}/#{@task.id}/comeontom.app"
    # destPath = "#{atom.project.path}/5/comeontom.app"
    console.log "downLoadPath#{downLoadPath}"
    download = new Download({ extract: true, strip: 1, mode: '777' })
    .get(downLoadPath)
    .dest(destPath)

    download.run (err, files, stream)->
      if err
        throw err
      Device(destPath,(status)->
        console.log "status:#{status}"
      )

  cancel:->
    selectConfirm=confirm("请确认是否中止编译？");
    if selectConfirm
      if @task and @task.state != 'complete'
        @loading.hide()
        @find('.glyphicon-remove').removeClass('hidden')
        @find('.task-state').text "failed"
        @cancelbutton.disable()
        @refreshbutton.disable()
        puzzleClient.deleteTask @task.id
        .then ->
          console.log "task #{@task.id} deleted."
        .catch ->
          console.error "failed to delete task #{@task.id}"

  buttonAbled: ->
    @refreshbutton.attr("disabled",false)
    @cancelbutton.attr("disabled",false)
