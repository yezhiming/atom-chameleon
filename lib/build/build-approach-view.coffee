{$, View} = require 'atom'

class GridView extends View
  @content: ->
    @ul class: 'grid-view col-2', =>
      @li
        'data-name': 'puzzle'
        'data-description': 'Using Puzzle Building Cloud'
      , =>
        @span class: 'glyphicon glyphicon-bold'
        @span class: 'name', 'Puzzle Cloud'

      @li
        'data-name': 'local'
        'data-description': 'Using local build system'
      , =>
        @span class: 'glyphicon glyphicon-align-center'
        @span class: 'name', 'Local'

  initialize: ->
    @on 'mousedown', 'li', (e) =>
      @selectItemView($(e.target).closest('li'))
      e.preventDefault()

    @selectItemView(@find('li:first'))

  selectItemView: (view) ->
    return unless view.length
    @find('.selected').removeClass('selected')
    view.addClass('selected')
    @trigger 'selected', view.data('description')

  getSelectedItem: ->
    @find('li.selected').data('name')

module.exports =
class SelectTemplateView extends View
  @content: ->
    @div id: 'project-template-chooser', =>
      @h2 'Select building approach:'
      @div =>
        @subview 'gridView', new GridView()
      @div '', class: 'description'

  initialize: ->
    @gridView.on 'selected', (event, description)=>
      @find('.description').text(description)

  attachTo: (parentView)->
    parentView.append(this)

  destroy: ->
    @detach()

  getResult: ->
    'approach' : @gridView.getSelectedItem()
