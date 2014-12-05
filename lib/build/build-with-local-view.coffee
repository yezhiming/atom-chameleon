{$, View} = require 'atom'

module.exports =
class V extends View
  @content: ->
    @div 'local'

  destroy: ->
    @remove()
