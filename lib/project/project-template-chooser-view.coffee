{$, View} = require 'atom'
_ = require 'underscore'
ChooserView = require '../utils/chooser-view'

class TemplateTreeView extends View
  @content: ->
    @ul class: 'list-tree', =>
      @li class: 'list-nested-item', =>
        @div class: 'list-item', =>
          @span class: 'icon icon-file-directory', 'HTML5 Application'
        @ul class: 'list-tree', =>
          @li class: 'list-item', =>
            @span class: 'icon icon-file-text', 'aaa'

templates = [
  {id: 'simple', name: 'Starter', glyphicon: 'glyphicon-bold', description: 'A Simple Project, with Butterfly.js framework, and Bootstrap, Ratchet framework, if selected.'}
  {id: 'modular', name: 'Modular', glyphicon: 'glyphicon-align-center', description: 'A Project with modular feature enabled, along with Butterfly.js framework, and a base main module'}
  {id: 'empty', name: 'Empty', glyphicon: 'glyphicon-align-center', description: 'An empty project'}
]

module.exports =
class TemplateChooserView extends View
  @content: ->
    @div =>
      @subview 'chooser', new ChooserView(title: 'Choose a template for your new project:', items: templates)

  attachTo: (parentView) ->
    parentView.append(this)
    @chooser.selectFirstItemView()

  destroy: ->
    @detach()

  onNext: (wizard) ->
    wizard.mergeOptions {'template': @chooser.getSelectedItem().id}
    wizard.nextStep()
