#
# 显示任务状态，点击构建时弹出，作为一个tab
#
{$, View, SelectListView, $$} = require 'atom'
qrcode = require '../utils/qrcode'
request = require 'request'
io = require 'socket.io-client'
Q = require 'q'

puzzleClient = require '../utils/puzzle-client'

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

        @div =>
          @div id: 'toggle-out', =>
            @span class: 'glyphicon glyphicon-chevron-down'
            @span 'show output:'
          @div id: 'out', style: 'height: 300px; overflow: scroll; color: white;', =>

      @div class: 'actions', =>
        @div class: 'pull-left', =>
          @button 'Cancel', click: 'destroy', class: 'inline-block-tight btn'
        @div class: 'pull-right',outlet:"devicebtn",style:"display:none", =>
          @button 'Device', click: 'DeviceFun', class: 'inline-block-tight btn'
        @div class: 'pull-right', =>
          @button 'Refresh', click: 'refreshTaskState', class: 'inline-block-tight btn'

  initialize: ->

    @find('#toggle-out').on 'click', => @find('#out').toggle()
    # @devicebtn.show()

  attach: ->
    atom.workspaceView.append(this)

    console.log "try to connect."

    @socket = io puzzleClient.server,
      reconnection: true
      reconnectionDelay: 50
      reconnectionDelayMax: 12000

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
      console.log "task updated"
      @find('.task-state').text job.state
      @updateQRCode(job.data.platform) if job.state == 'complete'

    @socket.on 'stdout', (out) =>
      out_element = @find('#out')
      out_element.append("<pre>#{out}</pre>")
      out_element.scrollTop = out_element.scrollHeight

    @socket.on 'stderr', (out) =>
      out_element = @find('#out')
      out_element.append("<pre class='text-warning'>#{out}</pre>")
      out_element.scrollTop = out_element.scrollHeight

  destroy: ->
    @socket?.disconnect()
    if @task and @task.state != 'complete'
      puzzleClient.deleteTask @task.id
      .then ->
        console.log "task #{@task.id} deleted."
      .catch ->
        console.error "failed to delete task #{@task.id}"

    @detach()

  setTask: (@task) ->
    @find('.task-id').text @task.id
    @find('.task-uuid').text @task.data.uuid
    @find('.task-state').text @task.state

    @showState(@task)

  showState: (task) ->
    @loading.show()

    @loading.hide() if task.state == 'failed'
    switch task.state
      when 'complete'
        @loading.hide()
        @updateQRCode(task.data.platform)
      when 'failed'
        @loading.hide()
        @find('.glyphicon-remove').removeClass('hidden')

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
