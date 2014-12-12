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

  initialize: (@id) ->

  updateQRCode: ->
    qr = qrcode(4, 'M')
    qr.addData("http://localhost:3000/archives/#{@id}")
    qr.make()
    imgTag = qr.createImgTag(8)
    @find('#qrcode').empty().append(imgTag)

  attach: ->
    atom.workspaceView.append(this)

    @onClickRefresh()

  destroy: ->
    @detach()

  onClickRefresh: ->
    Q.nfcall request, "http://localhost:3000/api/tasks/#{@id}"
    .then (result) =>
      body = JSON.parse result[1]
      @find('.task-id').text body.id
      @find('.task-uuid').text body.data.uuid
      @find('.task-state').text body.state

      @updateQRCode() if body.state == 'complete'
