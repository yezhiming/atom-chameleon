{$, $$, View, EditorView} = require 'atom'
_s = require 'underscore.string'
_ = require 'underscore'
path = require 'path'

module.exports =
class V extends View
  @content: ->
    @div id: 'gitCreatePackage-info-view', =>
      @h1 'Create a git package:'
  
      @div class: "form-group", =>
        @label 'Select:'
        @select class:'gitCreatePackageSelect', outlet: 'selectGit', =>
          @option "github"
          @option "gogs"
      
      @div class: "form-group", =>
        @label 'Package Name:'
        @subview 'packageName', new EditorView(mini: true)

      @div class: "form-group", =>
        @label 'Describe:'
        @subview 'describe', new EditorView(mini: true, placeholderText: 'optional' )
    

  initialize: (wizardView) ->
    @editorOnDidChange @packageName, wizardView

    selectPath = atom.packages.getActivePackage('tree-view').mainModule.treeView.selectedPath
    @packageName.setText _.last(selectPath.split(path.sep))

  # 验证editor是否填写了内容
  editorOnDidChange:(editor, wizardView) ->
    editor.getEditor().onDidChange =>
      @editorVerify wizardView

  editorVerify: (wizardView)->
    unless  (@packageName.getText() is "")
      wizardView.enableNext()
    else
      wizardView.disableNext()
    

  destroy: ->
    @remove()

  onNext: (wizard) ->
    wizard.mergeOptions {
      repo: @selectGit.val()
      packageName: @packageName.getText()
      describe: @describe.getText()
    }
    wizard.nextStep()
