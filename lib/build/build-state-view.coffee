#
# 显示任务状态，点击构建时弹出，作为一个tab
#
{$, View, SelectListView, $$} = require 'atom'
qrcode = require '../qrcode'
request = require 'request'
io = require 'socket.io-client'
Q = require 'q'

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
        @div class: 'pull-right', =>
          @button 'Refresh', click: 'refreshTaskState', class: 'inline-block-tight btn'

  initialize: ->
    @server = atom.config.get('atom-butterfly.puzzleServerAddress')
    @serverSecured = atom.config.get('atom-butterfly.puzzleServerAddressSecured')
    @access_token = atom.config.get('atom-butterfly.puzzleAccessToken')

    @find('#toggle-out').on 'click', => @find('#out').toggle()

  attach: ->
    atom.workspaceView.append(this)

    @socket = io(@server)

    @socket.on 'connect', =>
      console.log "socket connected."
      @socket.emit 'bind', @access_token

    @socket.on 'disconnect', ->
      console.log "socket disconnected."

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
    @detach()

  setTask: (@task) ->
    @find('.task-id').text @task.id
    @find('.task-uuid').text @task.data.uuid
    @find('.task-state').text @task.state

    @showState(@task)

  showState: (task) ->
    @loading.show()

    console.log task.state
    @loading.hide() if task.state == 'failed'
    switch task.state
      when 'complete'
        @loading.hide()
        @updateQRCode(task.data.platform)
      when 'failed'
        @loading.hide()
        @find('.glyphicon-remove').removeClass('hidden')

  refreshTaskState: ->

    Q.nfcall request.get,
      url: "#{@server}/api/tasks/#{@task.id}"
      rejectUnauthorized: false
    .then (result) -> JSON.parse result[1]
    .then (task) => @setTask(task)
    .catch (err) -> alert "error: #{err}"

  updateQRCode: (platform) ->
    console.log "update qrcode for platform: #{platform}"
    qr = qrcode(4, 'M')
    if platform == 'ios'
      qr.addData("#{@serverSecured}/archives/#{@task.id}/install/ios")
    else if platform == 'android'
      qr.addData("#{@serverSecured}/archives/#{@task.id}.apk")
    else
      throw new Error('qrcode: unkown platform.')
    qr.make()
    imgTag = qr.createImgTag(8)
    @find('#qrcode').empty().append(imgTag)
