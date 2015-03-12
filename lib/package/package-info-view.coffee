path = require 'path'
fs = require 'fs'
{View, EditorView} = require 'atom'
remote = require 'remote'
dialog = remote.require 'dialog'

module.exports =
class V extends View
  @content: ->
    @div id: 'package-info-view', =>
      @h1 'Create Package:'
      @div class: 'text-error'
      @div class: 'row', =>
        # icon
        @div class: 'col-xs-3', =>
          @img class: 'icon', click: 'onClickIcon', outlet: 'icon'
          @div class: "form-group", =>
            @label 'Title'
            @subview 'title', new EditorView(mini: true, placeholderText: 'Title'), class: 'title'
        # info
        @div class: 'col-xs-9', =>
          @div class: "form-group", =>
            @label 'Name'
            @subview 'name', new EditorView(mini: true)

          @div class: "form-group", =>
            @label 'Identifier'
            @subview 'identifier', new EditorView(mini: true)

          @div class: "form-group", =>
            @label 'Description'
            @subview 'description', new EditorView(mini: true)

          @div class: "form-group", =>
            @label 'Version'
            @subview 'version', new EditorView(mini: true)

          @div class: "checkbox", =>
            @label =>
              @input outlet: 'invisible', type: "checkbox"
              @text('Invisible')

  initialize: (wizardView) ->
    @version.setText("1.0.0")

    wizardView.disableNext()

    # observe identifier change
    @name.getEditor().onDidChange =>
      return unless @name.getText()? # reject null only
      # check for available
      fs.exists path.resolve(atom.project.rootDirectories[0].path, @name.getText()), (exists)=>
        if exists
          wizardView.disableNext()
        else
          wizardView.enableNext()
    @isOpenDialog = false

  onClickIcon: ->
    if @isOpenDialog
      return
    @isOpenDialog = true
    dialog.showOpenDialog {
      title: 'Select Icon Image'
      defaultPath: atom.project.rootDirectories[0].path
      filters: [{name: "png image", extensions: ['png', 'jpg']}]
      properties: ['openFile']
    }, (destPath) =>
      @isOpenDialog = false
      @icon.attr('src', destPath) if destPath

  destroy: ->
    @remove()

  onNext: (wizard) ->
    wizard.mergeOptions {
      name: @name.getText()
      title: @title.getText()
      identifier: @identifier.getText()
      version: @version.getText()
      description: @description.getText() or ""
      invisible: @invisible.prop('checked')
      icon_path: @icon.attr('src')
    }
    wizard.nextStep()
