{$, View, $$} = require 'atom'

module.exports =
class ConsoleView extends View
  @content: ->
    @div =>
      @div click: 'onToggle', id: 'console-toggle', =>
        @span class: 'glyphicon glyphicon-chevron-down'
        @span 'show output:'
      @div id: 'out', outlet: 'out', style: 'height: 300px; overflow: scroll; color: white;', =>

  initialize: ->
    @onToggle()

  append: (content, style = '')->
    @out.append("<pre class='#{style}'>#{content}</pre>")
    @out[0].scrollTop = @out[0].scrollHeight

  onToggle: ->
    @find('#out').toggle()
