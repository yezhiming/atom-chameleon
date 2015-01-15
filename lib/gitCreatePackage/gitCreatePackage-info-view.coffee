{$, $$, View, EditorView} = require 'atom'
_s = require 'underscore.string'
_ = require 'underscore'
path = require 'path'


request = require 'request'
Q = require 'q'

module.exports =
class V extends View
  @content: ->
    @div id: 'gitCreatePackage-info-view', =>
      @h1 'Create a git package:'

      @div class: "form-group", =>
        @div class:"optional-radio", =>
          @input name: "gitSelect", type: "radio", id: 'publicPackageRadio', checked: "checked", outlet: "publicPackageRadio", click: "radioSelectPublicFun"
          @label "You will open your source to everyone.", class: 'radioLabel'

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
    @judgeTheName(wizard)

  judgeTheName: (wizard)->
    server = atom.config.get('atom-butterfly.puzzleServerAddress')
    access_token = atom.config.get 'atom-butterfly.puzzleAccessToken'

    url = "#{server}/api/packages/findOne/#{@packageName.getText()}?access_token=#{access_token}"
    Q.Promise (resolve, reject, notify) =>
      request url, (error, response, body) ->
        return reject error if error
        if response.statusCode is 200
          try
            bodyJson =  $.parseJSON(body)
          catch
            bodyJson = {}

          if bodyJson.code is 404 # 没有package
            resolve true
          else
            resolve false
        else
          reject $.parseJSON(response.body).message

    .then (packageHave) =>
      # console.log packageHave
      unless @privateSelect.isHidden()
        selectGit = @selectPublicGit.val()
      else
        selectGit = @selectPublicGit.val()

      wizard.mergeOptions {
        repo: selectGit
        packageName: @packageName.getText()
        describe: @describe.getText()
      }
      if packageHave
        wizard.nextStep()
      else
        alert "Sorry,please change you Package Name!"

    .catch (err) ->
      console.trace err.stack
      alert "#{err}"
