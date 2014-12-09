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
    @ul class: 'grid-view', =>
      @li 'data-name': 'simple', class: 'selected', =>
        @span class: 'glyphicon glyphicon-bold'
        @span class: 'name', 'Simple'
      @li 'data-name': 'modular', =>
        @span class: 'glyphicon glyphicon-align-center'
        @span class: 'name', 'Modular'
      @li 'data-name': 'empty', =>
        @span class: 'glyphicon glyphicon-align-center'
        @span class: 'name', 'Empty'

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
    @div id: 'project-template-chooser', =>
      @h2 'Choose a template for your new project:'
      @div =>
        @subview 'gridView', new GridView()
      @div 'Web Framework from best practice, MVC based on Backbone.js, structure code using Require.js', class: 'description'

  attachTo: (parentView)->
    parentView.append(this)

  destroy: ->
    @detach()

  getResult: ->
    'template': @gridView.getSelectedItem()
