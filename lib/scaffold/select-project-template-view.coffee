{$, View} = require 'atom'

class TemplateTreeView extends View
  @content: ->
    @ul class: 'list-tree', =>
      @li class: 'list-nested-item', =>
        @div class: 'list-item', =>
          @span class: 'icon icon-file-directory', 'HTML5 Application'
        @ul class: 'list-tree', =>
          @li class: 'list-item', =>
            @span class: 'icon icon-file-text', 'aaa'

class GridView extends View
  @content: ->
    @ul class: 'template-list', =>
      @li 'data-name': 'butterfly', class: 'selected', =>
        @span class: 'glyphicon glyphicon-bold'
        @span class: 'name', 'Butterfly.js'
      @li 'data-name': 'butterfly', =>
        @span class: 'glyphicon glyphicon-align-center'
        @span class: 'name', 'Piece.js'
      @li 'data-name': 'butterfly', =>
        @span class: 'glyphicon glyphicon-align-center'
        @span class: 'name', 'Angular.js'

  initialize: ->
    @on 'mousedown', 'li', (e) =>
      @selectItemView($(e.target).closest('li'))
      e.preventDefault()

  selectItemView: (view) ->
    return unless view.length
    @find('.selected').removeClass('selected')
    view.addClass('selected')

  getSelectedItem: ->
    @find('li.selected').data('name')

module.exports =
class SelectTemplateView extends View
  @content: ->
    @div =>
      @h1 'Choose a template for your new project:'
      @div =>
        @subview 'gridView', new GridView()

  attachTo: (parentView)->
    parentView.append(this)

  destroy: ->
    @detach()

  getResult: ->
    'template': @gridView.getSelectedItem()
