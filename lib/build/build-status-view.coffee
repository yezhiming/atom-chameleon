#
# 显示任务状态，点击构建时弹出，作为一个tab
#
{$, View, SelectListView, $$} = require 'atom'
qrcode = require '../qrcode'
request = require 'request'
io = require 'socket.io-client'
Q = require 'q'

class BuildTaskListView extends SelectListView

  initialize: () ->
    super
    @filterEditorView.off 'blur'

  # Here you specify the view for an item
  viewForItem: (item) ->
    $$ ->
      @li =>
        @p item.id
        @p item.state

  confirmed: (item) ->
    console.log item

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

      @div class: 'actions', =>
        @div class: 'pull-left', =>
          @button 'Cancel', click: 'destroy', class: 'inline-block-tight btn'
        @div class: 'pull-right', =>
          @button 'Refresh', click: 'refreshTaskState', class: 'inline-block-tight btn'

  initialize: ->
    @server = atom.config.get('atom-butterfly.puzzleServerAddress')
    @serverSecured = atom.config.get('atom-butterfly.puzzleServerAddressSecured')
    @access_token = atom.config.get('atom-butterfly.puzzleAccessToken')

  attach: ->
    atom.workspaceView.append(this)

    @socket = socket = io(@server)

    socket.on 'connect', ->
      console.log "bind socket"
      socket.emit 'bind', @access_token

    socket.on 'error', (err) ->
      console.log "socket error: #{err}"

    socket.on 'timeout', ->
      console.log "socket timeout"

    socket.on 'update', (job) =>
      console.log "task updated"
      @find('.task-state').text job.state
      @updateQRCode(job.data.platform) if job.state == 'complete'

  destroy: ->
    @socket?.disconnect()
    @detach()

  updateTaskList: ->
    Q.nfcall request.get, "#{@server}/api/tasks?access_token=#{@access_token}"
    .then (result) ->
      JSON.parse result[1]
    .then (result) =>
      console.log result
      @taskList.setItems(result)
    .catch (err) ->
      alert('fetch build tasks fail.' + err)
      trace err.stack

  setTaskId: (@id) ->
    @refreshTaskState()

  refreshTaskState: ->
    # show loading
    @loading.show()

    Q.nfcall request.get,
      url: "#{@server}/api/tasks/#{@id}"
      rejectUnauthorized: false
    .then (result) ->
      JSON.parse result[1]
    .then (task) =>
      @find('.task-id').text task.id
      @find('.task-uuid').text task.data.uuid
      @find('.task-state').text task.state

      # hide loading
      @loading.hide()

      switch task.state
        when 'complete' then @updateQRCode(body.data.platform)
        when 'failed' then @showFailed()
    .catch (err) ->
      alert "error: #{err}"

  showFailed: ->
    @find('.glyphicon-remove').removeClass('hidden')

  updateQRCode: (platform) ->
    console.log "update qrcode for platform: #{platform}"
    qr = qrcode(4, 'M')
    if platform == 'ios'
      qr.addData("#{@serverSecured}/archives/#{@id}/install/ios")
    else if platform == 'android'
      qr.addData("#{@serverSecured}/archives/#{@id}.apk")
    else
      throw new Error('qrcode: unkown platform.')
    qr.make()
    imgTag = qr.createImgTag(8)
    @find('#qrcode').empty().append(imgTag)
