{$, View, $$} = require 'atom'

module.exports =
class ConsoleView extends View
  @content: ->
    @div =>
      @div click: 'onToggle', id: 'console-toggle', =>
        @span class: 'glyphicon glyphicon-chevron-down'
        @span 'show output:'
      @div id: 'out', style: 'height: 300px; overflow: scroll; color: white;', =>

  initialize: ->
    @onToggle()

  onToggle: ->
    @find('#out').toggle()

  stdout: (out) ->
    out_element = @find('#out')
    out_element.append("<pre>#{out}</pre>")
    out_element.scrollTop = out_element.scrollHeight

  append: (out) ->
    out_element = @find('#out')
    out_element.append("<pre class='text-error'>#{out}</pre>")
    out_element.scrollTop = out_element.scrollHeight
