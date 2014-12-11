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
            @li 'data-name': item.id, =>
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
    @find('.selected').removeClass('selected')
    view.addClass('selected')

  selectFirstItemView: ->
    @gridView.selectItemView @gridView.find('li:first')

  getSelectedItem: ->
    selected = @find('li.selected')
    item_id = selected.data('name')

    tpl = _.find(@items, (t)-> t.id == item_id)
