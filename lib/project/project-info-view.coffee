{View, EditorView} = require 'atom'
{checkProjectName} = require '../utils/utils'

module.exports =
class ProjectInfoView extends View
  @content: ->
    @div =>
      @h1 'Choose options for your new project:'
      @div class: "form-group", =>
        @label 'Project Name:'
        @subview 'editor', new EditorView(mini: true)
        @div style: "background-color: #f7ea57;", outlet: "warnPackageText", =>
          @label style: "font-weight: bolder; color: black;padding-left: 5px;padding-top: 5px;",outlet: "warnPackageTextLabel"



  initialize: (wizardView) ->
    @checkNameEditorView @editor
    @warnPackageText.hide()

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
      name: @editor.originalText
    }
    wizard.nextStep()

  checkNameEditorView: (editorView)->
    editorView.originalText = ''
    editorView.hiddenInput.on 'focusout', (e) =>
      @checkName editorView

  checkName: (editorView)->
    str = editorView.getText()
    strcheck = checkProjectName str
    editorView.originalText = strcheck
    @warnPackageTextLabel.html("Will be created as #{strcheck}")

    if strcheck is str
      @warnPackageText.hide()
    else
      @warnPackageText.show()
