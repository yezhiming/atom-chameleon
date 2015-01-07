{View, EditorView} = require 'atom'

module.exports =
class ProjectInfoView extends View
  @content: ->
    @div =>
      @h1 'Choose options for your new project:'
      @div class: "form-group", =>
        @label 'Project Name:'
        @subview 'editor', new EditorView(mini: true)

      @div class: "checkbox", =>
        @label =>
          @input type: "checkbox", id: 'withRatchet'
          @text('With Ratchet')

      @div class: "checkbox", =>
        @label =>
          @input type: "checkbox", id: 'withBootstrap'
          @text('With Bootstrap')


  initialize: (wizardView) ->
    @editor.getEditor().onDidChange =>
      unless @editor.getText() is ""
        wizardView.enableNext()
      else
        wizardView.disableNext()
      
    

  attachTo: (parentView)->
    parentView.append(this)
    @editor.focus()

  destroy: ->
    @detach()

  onNext: (wizard) ->
    wizard.mergeOptions {
      name: @editor.getText()
      bootstrap: @find('#withBootstrap').is(":checked")
      ratchet: @find('#withRatchet').is(":checked")
    }
    wizard.nextStep()
