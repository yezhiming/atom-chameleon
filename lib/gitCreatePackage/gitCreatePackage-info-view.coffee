{$, $$, View, EditorView} = require 'atom'
_s = require 'underscore.string'
_ = require 'underscore'
path = require 'path'

LoginView = require './gitCreatePackage-login-view'

request = require 'request'
Q = require 'q'

module.exports =
class V extends View
  @content: ->
    @div id: 'gitCreatePackage-info-view', class: 'gitCreatePackage-info-view', =>
      @h1 'Create a package:'

      @div class: "form-group", =>
        @div class:"optional-radio", =>
          @input name: "gitSelect", type: "radio", id: 'publicPackageRadio', checked: "checked", outlet: "publicPackageRadio", click: "radioSelectPublicFun"
          @label "Anyone can see this repository. You choose who can commit.", class: 'radioLabel'

        @div outlet: 'publicSelect', =>
          @select class:'form-control', outlet: 'selectPublicGit', =>
            @option "github"

      @div class: "form-group", =>
        @div class:"optional-radio", =>
          @input name: "gitSelect", type: "radio", id: 'privatePackageRadio', outlet: "privatePackageRadio", click: "radioSelectPrivateFun"
          @label 'Your team can see this repository. You choose who can commit.', class: 'radioLabel'

        @div outlet: 'privateSelect', =>
          @select class:'form-control', outlet: 'selectPrivateGit', =>
            @option "gogs"

      @div outlet: "userAccount", =>
        @div class: 'form-group', =>
          @label "Account:"
          @div class: 'accountSetting', =>
            @label class: 'account', outlet: 'account'
            @div class: 'glyphicon glyphicon-log-out accountIcon', click: "logOutFun"

      @div class: "form-group", =>
        @label 'Package Name:'
        @subview 'packageName', new EditorView(mini: true)
        @div style: "background-color: #f7ea57;", outlet: "warnPackageText", =>
          @label style: "font-weight: bolder; color: black;",outlet: "warnPackageTextLabel"

      @div class: "form-group", =>
        @label 'Describe:'
        @subview 'describe', new EditorView( placeholderText: 'optional' )


  initialize: (wizardView) ->
    
    @loginView = new LoginView()
    atom.workspaceView.append @loginView
    @loginView.hide()

    @editorOnDidChange @packageName, wizardView

    @describe.attr("style","height:200px")


    selectPath = atom.packages.getActivePackage('tree-view').mainModule.treeView.selectedPath
    @packageName.setText _.last(selectPath.split(path.sep))
  
    @selectPublicGit.change =>
      @userAccountAttached()

    @selectPrivateGit.change =>
      @userAccountAttached()

    @checkNameEditorView @packageName
    @warnPackageText.hide()
    
    
  attached: ->
    @privateSelect.hide()
    @userAccountAttached()

    @packageName.focus()
    
  userAccountAttached: ->
    unless @privateSelect.isHidden()
      @selectGit = @selectPrivateGit.val()
    else
      @selectGit = @selectPublicGit.val()
    
    loginInfo = localStorage.getItem @selectGit
    loginInfo = JSON.parse(loginInfo)
    
    if loginInfo is null
      @userAccount.hide()
    else
      @userAccount.show()
      @account.html loginInfo.username
      
  logOutFun: ->
    localStorage.removeItem @selectGit
    @userAccountAttached()

  radioSelectPublicFun: ->
    if @publicSelect.isHidden()
      @publicSelect.show()
      @privateSelect.hide()
      @userAccountAttached()

  radioSelectPrivateFun: ->
    if @privateSelect.isHidden()
      @privateSelect.show()
      @publicSelect.hide()
      @userAccountAttached()

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
    unless @loginView.isHidden()
      @loginView.hide()
    @remove()

  onNext: (wizard) ->
    @judgeTheName(wizard)

  judgeTheName: (wizard)->
    server = atom.config.get('atom-chameleon.puzzleServerAddress')
    access_token = atom.config.get 'atom-chameleon.puzzleAccessToken'

    unless @loginView.isHidden()
      return
    
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
      Q.Promise (resolve, reject, notify) =>
        # console.log packageHave
        options =
          repo: @selectGit
          packageName: @packageName.originalText
          describe: @describe.getText()

        unless packageHave
          @packageName.focus()
          reject "Sorry,please change you Package Name!"
        else
          # 保存用户认证，但不保存用户密码
          unless @userAccount.isHidden()
            loginInfo = localStorage.getItem @selectGit
            loginInfo = JSON.parse(loginInfo)
            account = loginInfo.username
            _.extend(options, account: account)
            resolve(options)
          else
            @loginView.mergeOptions options
            @loginView.show()
            @loginView.editorVerify()
            @loginView.account.focus()
            @loginView.on 'certain', (result) => resolve(result)
            @loginView.on 'destroy', => @packageName.focus()

    .then (options) =>
      @loginView.destroy()
      wizard.mergeOptions options
      wizard.nextStep()
    .catch (err) ->
      console.trace err.stack
      alert "#{err}"


  checkNameEditorView: (editorView)->
    editorView.originalText = ''
    editorView.hiddenInput.on 'focusout', (e) =>
      @checkName editorView


  checkName: (editorView)->
    str = editorView.getText()
    regEx = /[\`\~\!\@\#\$\%\^\&\*\(\)\+\=\|\{\}\'\:\;\,\\\[\]\<\>\/\?\~\！\@\#\￥\%\…\…\&\*\（\）\—\—\+\|\{\}\【\】\‘\；\：\”\“\’\。\，\、\？]/g
    strcheck = str.replace(/[^\x00-\xff]/g,"-")
    strcheck = strcheck.replace(regEx,"-")
    strcheck = strcheck.replace(/-+/g, '-')

    editorView.originalText = strcheck
    @warnPackageTextLabel.html("Will be created as #{strcheck}")

    if strcheck is str
      @warnPackageText.hide()
    else
      @warnPackageText.show()
  
    
    
