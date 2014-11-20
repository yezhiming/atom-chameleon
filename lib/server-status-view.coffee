{View} = require 'atom'
remote = require 'remote'
dialog = remote.require 'dialog'

module.exports =

class ServerStatusView extends View

  @content: ->
    @div click: 'onClick', id: 'chameleon-server-status', class: 'inline-block', =>
      @span 'HTTP Server'
      @span class: 'glyphicon glyphicon-refresh running', outlet: 'status'

  initialize: ->

  attach: ->
    atom.workspaceView.statusBar.appendLeft(this)

  destroy: ->
    console.log 'server status view destroy.'
    @detach()

  onClick: ->
    dialog.showMessageBox {
      title: 'HTTP Server'
      message: 'ready to stop http server, are you sure?'
      buttons: ['confirm', 'cancel']
    }, (response)=>

      if response == 0
        console.log "ready to close server..."
        @trigger 'stopServer'
      else
        console.log "user cancel."
