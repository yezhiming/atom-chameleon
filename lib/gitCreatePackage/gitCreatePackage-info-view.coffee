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
        @div class:"optional-radio", =>
          @input name: "gitSelect", type: "radio", id: 'publicPackageRadio', checked: "checked", outlet: "publicPackageRadio", click: "radioSelectPublicFun"
          @label "You will open your source to everyone!", class: 'radioLabel'
        
        @div outlet: 'publicSelect', =>
          @select class:'gitCreatePackageSelect', outlet: 'selectPublicGit', =>
            @option "github"

      @div class: "form-group", =>
        @div class:"optional-radio", =>
          @input name: "gitSelect", type: "radio", id: 'privatePackageRadio', outlet: "privatePackageRadio", click: "radioSelectPrivateFun"
          @label 'You only open your source to your company.', class: 'radioLabel'

        @div outlet: 'privateSelect', =>
          @select class:'gitCreatePackageSelect', outlet: 'selectPrivateGit', =>
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
    
  attached: ->
    @privateSelect.hide()

  radioSelectPublicFun: ->
    if @publicSelect.isHidden()
      @publicSelect.show()
      @privateSelect.hide()
      
  radioSelectPrivateFun: ->
    if @privateSelect.isHidden()
      @privateSelect.show()
      @publicSelect.hide()

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
    unless @privateSelect.isHidden()
      selectGit = @selectPublicGit.val()
    else
      selectGit = @selectPublicGit.val()
    
    wizard.mergeOptions {
      repo: selectGit
      packageName: @packageName.getText()
      describe: @describe.getText()
    }
    wizard.nextStep()
