{$, View} = require 'atom'
_ = require 'underscore'

module.exports =
class Chooser extends View
  @content: (options)->
    @div id: 'chooser-view', =>
      @h2 options.title or ''
      @div =>
        #grid view
        @ul class: 'grid-view', =>
          for item in options.items
            @li 'data-id': item.id, =>
              @span class: 'glyphicon ' + item.glyphicon or ''
              @span class: 'name', item.name
      @div outlet: 'description', class: 'description'

  initialize: (options) ->
    @items = options.items

    @on 'mousedown', 'li', (e) =>
      li = $(e.target).closest('li')
      e.preventDefault()
      @selectItemView(li)

  remove: ->
    super
    @off 'mousedown'

  selectItemView: (view) ->
    return unless view.length
    @find('.grid-view .selected').removeClass('selected')
    view.addClass('selected')

  selectFirstItemView: ->
    @selectItemView @find('.grid-view li:first')

  getSelectedItem: ->
    selected = @find('.grid-view li.selected')
    tpl = _.find @items, (t)-> t.id == selected.data('id')
