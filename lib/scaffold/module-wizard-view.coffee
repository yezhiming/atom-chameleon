{View,EditorView} = require 'atom'


module.exports =
class CreateModuleWizardView extends View
  @content: ->
    @div class: 'butterfly overlay from-top', =>
      @div class: 'form-group', =>
        @label 'module name'
        @subview 'moduleName', new EditorView(mini: true)
      @button 'Create', click: 'onClickCreate', class: "btn btn-primary col-md-6"
      @button 'Cancel', click: 'onClickCancel', class: "btn btn-error selected inline-block-tight col-md-6"


  attach: ->
    atom.workspaceView.append(this)
    return this

  destroy: ->
    @detach()

  onClickCreate: ->
    @destroy()

  onClickCancel: ->
    @destory()
