path = require 'path'
fs = require 'fs'
{View, EditorView} = require 'atom'
remote = require 'remote'
dialog = remote.require 'dialog'

module.exports =
class RunOnServerView extends View
  @content: ->
    @div class: 'butterfly overlay from-top', =>
      @div =>
        @h1 'Run on Server'
        @span click: 'destroy', class: 'glyphicon glyphicon-remove close-view'

        @div class: "form-group", =>
          @label 'Select Root Path'
          @div class: "input-group", =>
            @div outlet: 'selectedRootPath', class: 'form-control'
            @span class: 'input-group-btn', =>
              @button 'Select', class: 'btn btn-default reset-to-bootstrap-default', type: 'button', click: 'onSelectRootPath'

        @div class: "form-group", =>
          @label 'Select Index Page'
          @div class: "input-group", =>
            @div outlet: 'selectedIndexFile', class: 'form-control'
            @span class: 'input-group-btn', =>
              @button 'Select', class: 'btn btn-default reset-to-bootstrap-default', type: 'button', click: 'onSelectIndex'

        #TODO: proxy api
        @div class: "form-group", =>
          @label 'Select Custom API'
          @div class: "input-group", =>
            @div outlet: 'customAPIFile', class: 'form-control'
            @span class: 'input-group-btn', =>
              @button 'Select', class: 'btn btn-default reset-to-bootstrap-default', type: 'button', click: 'onSelectAPI'

        @div class: "form-group", =>
          @label 'http port'
          @subview 'httpPort', new EditorView(mini: true)

        @div class: "checkbox", =>
          @label =>
            @input type: "checkbox", id: 'usingPushState'
            @text('Using pushState')

        @button 'Run', click: 'onClickRun', class: "btn btn-primary btn-lg btn-block"

  initialize: (serializeState) ->

    @selectedRootPath.text '.'

    fs.exists path.resolve(atom.project.path, 'index.html'), (exists)=>
      @selectedIndexFile.text 'index.html' if exists

    @httpPort.setText "3000"

  onSelectRootPath: ->

    dialog.showOpenDialog {
      title: 'Select Root Path'
      defaultPath: atom.project.path
      properties: ['openDirectory']
    }, (destPath) =>

      if destPath
        relativePath = path.relative(atom.project.path, destPath[0]) || '.'
        @selectedRootPath.text relativePath if destPath

  onSelectIndex: ->

    dialog.showOpenDialog {
      title: 'Select Index File'
      defaultPath: atom.project.path
      filters: [{name: "html", extensions: ['html', 'htm']}]
      properties: ['openFile']
    }, (destPath) =>

      #note: use val method for input tag
      @selectedIndexFile.text path.relative(atom.project.path, destPath[0]) if destPath

  onSelectAPI: ->

    dialog.showOpenDialog {
      title: 'Custom API Script'
      defaultPath: atom.project.path
      filters: [{name: "js_coffee", extensions: ['js', 'coffee']}]
      properties: ['openFile']
    }, (destPath) =>

      @customAPIFile.text path.relative(atom.project.path, destPath[0]) if destPath

  onClickRun: ->
    rootPath = path.resolve(atom.project.path, @selectedRootPath.text())
    destPath = path.resolve(atom.project.path, @selectedIndexFile.text())
    httpPort = parseInt @httpPort.getText()
    pushState = @find('#usingPushState').is(":checked")
    apiScript = if @customAPIFile.text() then path.resolve(atom.project.path, @customAPIFile.text()) else null

    #TODO: validation

    @trigger 'createServer', [rootPath, destPath, httpPort, pushState, apiScript]

    @destroy()

  attach: ->
    atom.workspaceView.append(this)

  destroy: ->
    @remove()

  toggle: ->
    if @hasParent() then @detach() else @attach()
