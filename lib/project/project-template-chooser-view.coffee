{$, View} = require 'atom'
_ = require 'underscore'

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
  @content: (items) ->
    @ul class: 'grid-view', =>
      for item in items
        @li 'data-name': item.id, =>
          @span class: 'glyphicon ' + item.glyphicon or ''
          @span class: 'name', item.name

  initialize: ->
    @on 'mousedown', 'li', (e) =>
      li = $(e.target).closest('li')
      @selectItemView(li)
      e.preventDefault()

  selectItemView: (view) ->
    return unless view.length
    @find('.selected').removeClass('selected')
    view.addClass('selected')

    @trigger 'selected', view.data('name')

  getSelectedItem: ->
    @find('li.selected').data('name')

templates = [
  {id: 'simple', name: 'Simple', glyphicon: 'glyphicon-bold', description: 'A Simple Project, with Butterfly.js framework, and Bootstrap, Ratchet framework, if selected.'}
  {id: 'modular', name: 'Modular', glyphicon: 'glyphicon-align-center', description: 'A Project with modular feature enabled, along with Butterfly.js framework, and a base main module'}
  {id: 'empty', name: 'Empty', glyphicon: 'glyphicon-align-center', description: 'An empty project'}
]

module.exports =
class TemplateChooserView extends View
  @content: ->
    @div id: 'project-template-chooser', =>
      @h2 'Choose a template for your new project:'
      @div =>
        @subview 'gridView', new GridView(templates)
      @div outlet: 'description', class: 'description'

  attachTo: (parentView) ->
    @gridView.on 'selected', (event, id) =>
      tpl = _.find(templates, (t)-> t.id == id)
      @description.text(tpl.description)

    @gridView.selectItemView @gridView.find('li:first')

    parentView.append(this)

  destroy: ->
    @gridView.off 'selected'
    @detach()

  getResult: ->
    'template': @gridView.getSelectedItem()
