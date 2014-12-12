#
# 显示任务状态，点击构建时弹出，作为一个tab
#
{$, View} = require 'atom'
qrcode = require '../qrcode'
request = require 'request'
io = require 'socket.io-client'
Q = require 'q'

module.exports =
class BuildStatusView extends View
  @content: ->
    @div class: 'build-status-view butterfly overlay from-top', =>
      @h1 'Build Status'
      @div class: "form-group", =>
        @label 'ID:'
        @span class: 'task-id'
      @div class: "form-group", =>
        @label 'UUID:'
        @span class: 'task-uuid'
      @div class: "form-group", =>
        @label 'State:'
        @span class: 'task-state'

      @div id: 'qrcode', =>
        @span class: 'loading loading-spinner-large inline-block'

      @div class: 'actions', =>
        @div class: 'pull-left', =>
          @button 'Cancel', click: 'destroy', class: 'inline-block-tight btn'
        @div class: 'pull-right', =>
          @button 'Refresh', click: 'onClickRefresh', class: 'inline-block-tight btn'

  initialize: ->
    @server = atom.config.get('atom-butterfly.puzzleServerAddress')
    @serverSecured = atom.config.get('atom-butterfly.puzzleServerAddressSecured')

  attach: ->
    atom.workspaceView.append(this)

  destroy: ->
    @detach()

  setTaskId: (@id) ->
    @onClickRefresh()

    socket = io(@server)

    socket.on 'connect', ->
      console.log "bind socket"
      socket.emit 'bind', atom.config.get('atom-butterfly.puzzleAPIToken')

    socket.on 'error', (err) ->
      console.log "socket error: #{err}"

    socket.on 'timeout', ->
      console.log "socket timeout"

    socket.on 'state', (state) =>
      console.log "update state via socket"
      @find('.task-state').text state
      @updateQRCode() if state == 'complete'

  onClickRefresh: ->
    Q.nfcall request.get,
      url: "#{@server}/api/tasks/#{@id}"
      rejectUnauthorized: false
    .then (result) =>
      body = JSON.parse result[1]
      @find('.task-id').text body.id
      @find('.task-uuid').text body.data.uuid
      @find('.task-state').text body.state

      @updateQRCode(body.data.platform) if body.state == 'complete'
      @showError() if body.state == 'failed'

  showError: ->


  updateQRCode: (platform) ->
    qr = qrcode(4, 'M')
    # if platform == 'ios'
    qr.addData("#{@serverSecured}/archives/#{@id}/install/ios")
    # else if platform == 'android'
      # qr.addData("#{@serverSecured}/archives/#{@id}.apk")
    # else
    #   throw new Error('qrcode: unkown platform.')
    qr.make()
    imgTag = qr.createImgTag(8)
    @find('#qrcode').empty().append(imgTag)
