{$, $$, View, EditorView} = require 'atom'
_s = require 'underscore.string'

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
        @label 'Account:'
        @subview 'account', new EditorView(mini: true)
      @div class: "form-group", =>
        @label 'Password:'
        @subview 'password', new EditorView(mini: true)

      
      @div class: "form-group", =>
        @label 'Package Name:'
        @subview 'packageName', new EditorView(mini: true)

      @div class: "form-group", =>
        @label 'Describe:'
        @subview 'describe', new EditorView(mini: true, placeholderText: '可选' )
    

  initialize: (wizardView) ->
    @passwordEditorView @password
    

  destroy: ->
    @remove()

  onNext: (wizard) ->
    wizard.mergeOptions {
      repo: @selectGit.val()
      account: @account.getText()
      password: @password.originalText
      packageName: @packageName.getText()
      describe: @describe.getText()
    }
    wizard.nextStep()

  passwordEditorView: (editorView)->
    editorView.originalText = ''
    editorView.hiddenInput.on 'keypress', (e) =>
      editor = editorView.getEditor()
      selection = editor.getSelectedBufferRange()
      cursor = editor.getCursorBufferPosition()
      if !selection.isEmpty()
        editorView.originalText = _s.splice(editorView.originalText, selection.start.column, selection.end.column - selection.start.column, String.fromCharCode(e.which))
      else
        editorView.originalText = _s.splice(editorView.originalText, cursor.column, 0, String.fromCharCode(e.which))
      editorView.insertText '*'
      false
  
    editorView.hiddenInput.on 'keydown', (e) =>
      if e.which == 8
        editor = editorView.getEditor()
        selection = editor.getSelectedBufferRange()
        cursor = editor.getCursorBufferPosition()
        if !selection.isEmpty()
          editorView.originalText = _s.splice(editorView.originalText, selection.start.column, selection.end.column - selection.start.column)
        else
          editorView.originalText = _s.splice(editorView.originalText, cursor.column - 1, 1)
        editorView.backspace
        false
      true
  
