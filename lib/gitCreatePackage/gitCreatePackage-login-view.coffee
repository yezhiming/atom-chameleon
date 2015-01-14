{$, $$, View, EditorView} = require 'atom'
_s = require 'underscore.string'
_ = require 'underscore'
Q = require 'q'
{EventEmitter} = require 'events'

module.exports =
class V extends View
  @content:->
    @div class: 'loginView overlay butterfly from-top', =>
      @div class: 'content', =>
        @h1 'Verify Account:'

        @div class: "form-group", =>
          @label 'Account:'
          @subview 'account', new EditorView(mini: true)
        @div class: "form-group", =>
          @label 'Password:'
          @subview 'password', new EditorView(mini: true)

      @div class: 'actions', =>
        @div class: 'pull-left', =>
          @button 'Cancel', click: 'destroy', class: 'inline-block-tight btn'

        @div class: 'pull-right block', =>
          @button 'Certain', click: 'certainFun', outlet: 'certain', class: 'inline-block-tight btn btn-primary'

  initialize: ->
    @passwordEditorView @password
    @editorOnDidChange @account
    @editorOnDidChange @password

    @options = {}

    _.extend this, EventEmitter.prototype

  mergeOptions:(options) ->
    _.extend @options, options

  # 验证editor是否填写了内容
  editorOnDidChange:(editor) ->
    editor.getEditor().onDidChange =>
      @editorVerify()

  editorVerify: ->
    unless  (@account.getText() is "") or
            (@password.getText() is "")
      @enableCertain()
    else
      @disableCertain()

  enableCertain: ->
    @certain.prop 'disabled', false

  disableCertain: ->
    @certain.prop 'disabled', true

  certainFun: ->
    console.log "CertainFun"
    @options.account = @account.getText()
    @options.password = @password.originalText
    @emit 'certain', @options

  destroy: ->
    @remove()

  finishPromise: ->
    Q.Promise (resolve, reject, notify) =>
      @on 'certain', (result) -> resolve(result)
      # 保存用户认证，但不保存用户密码
      github = JSON.parse localStorage.getItem 'github'
      if @options.repo is 'github' and github and github.safe
        resolve(@options)

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
          return true
        editorView.backspace
        return false

      if e.which == 229
        alert "Password is not Chinese!"
        editorView.text ""
        return false
      return true
