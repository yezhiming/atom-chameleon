path = require 'path'
fs = require 'fs-plus'
{View, EditorView} = require 'atom'
remote = require 'remote'
dialog = remote.require 'dialog'

module.exports =
class V extends View
  @content: ->
    @div =>
      @div class: "form-group", =>
        @label 'Identifier'
        @subview 'identifier', new EditorView(mini: true)

      @div class: "form-group", =>
        @label 'Name'
        @subview 'name', new EditorView(mini: true)

      @div class: "form-group", =>
        @label 'Version'
        @subview 'version', new EditorView(mini: true)

      @div class: "checkbox", =>
        @label =>
          @input type: "checkbox", id: 'invisible'
          @text('Invisible')

      @div class: "form-group", =>
        @label 'Select Icon'
        @div class: "input-group", =>
          @div outlet: 'selectedRootPath', class: 'form-control'
          @span class: 'input-group-btn', =>
            @button 'Select', class: 'btn btn-default reset-to-bootstrap-default', type: 'button', click: 'onSelectRootPath'

  initialize: (serializeState) ->

  onSelectRootPath: ->

    dialog.showOpenDialog {
      title: 'Select Root Path'
      defaultPath: atom.project.path
      properties: ['openDirectory']
    }, (destPath) =>

      if destPath
        relativePath = path.relative(atom.project.path, destPath[0]) || '.'
        @selectedRootPath.text relativePath if destPath

  onClickRun: ->
    rootPath = path.resolve(atom.project.path, @selectedRootPath.text())
    destPath = path.resolve(atom.project.path, @selectedIndexFile.text())
    httpPort = parseInt @httpPort.getText()
    pushState = @find('#usingPushState').is(":checked")
    apiScript = if @customAPIFile.text() then path.resolve(atom.project.path, @customAPIFile.text()) else null

  destroy: ->
    @remove()
