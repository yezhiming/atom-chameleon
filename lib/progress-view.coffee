{$, EditorView, View} = require 'atom'

module.exports =
class ProgressView extends View
  @content: ->
    @div class: 'overlay from-top', =>
      @div class: 'block', style: 'text-align:center', =>
        @h2 outlet: 'title', class: 'block'
        @progress outlet: 'progress', class: '', style: 'width: 90%'

  attach: ->
    atom.workspaceView.append(this)

  destroy: ->
    console.log 'loading view destroy.'
    @detach()

  setIndeterminate: ->
    @progress.removeAttr("max").removeAttr("value")

  setProgress: (value)->
    @progress.attr('max', 100).attr('value', value)

  setTitle: (title)->
    @title.text(title)
