path = require 'path'
fs = require 'fs-extra'
{$, $$, View, EditorView} = require 'atom'
remote = require 'remote'
dialog = remote.require 'dialog'
Q = require 'q'
{openFile} = require '../utils/dialog'

fsmkdirs = Q.denodeify fs.mkdirs

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

        @div class: "form-group", =>
          @label 'http port'
          @subview 'httpPort', new EditorView(mini: true)

        @div class: 'form-group', =>
          @div =>
            @span 'Proxy Config'
            @span click:'addProxy', class: 'glyphicon glyphicon-plus'
          @div class: 'proxy-list'

        # @div class: "checkbox", =>
        #   @label =>
        #     @input type: "checkbox", id: 'usingPushState'
        #     @text('Using pushState')

        @button 'Run', click: 'onClickRun', class: "btn btn-primary btn-lg btn-block"

  initialize: (serializeState) ->

    @selectedRootPath.text '.'

    if atom.project.path

      fs.exists path.resolve(atom.project.path, 'index.html'), (exists1)=>
        fs.exists path.resolve(atom.project.path, 'main', 'index.html'), (exists2)=>
          @selectedIndexFile.text 'index.html' if exists1
          @selectedIndexFile.text 'main/index.html' if exists2

    @httpPort.setText "3000"

    # @find('.glyphicon-minus').on 'click', (e) ->
    #   console.log "remove"
    #   item = $(e.target).closest('.proxy-item')
    #   item.remove()
    #   e.preventDefault()

  addProxy: ->
    item = $$ ->
      @div class: 'proxy-item row', =>
        @div class: 'col-xs-4', =>
          @subview 'c', new EditorView(mini: true)
        @div class: 'col-xs-7', =>
          @subview 'd', new EditorView(mini: true)
        @div class: 'col-xs-1', =>
          @span class: 'glyphicon glyphicon-minus'
    @find('.proxy-list').append $(item)

  removeProxy: ->
    console.log "remove"

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

  onClickRun: ->
    rootPath = path.resolve(atom.project.path, @selectedRootPath.text())
    destPath = path.resolve(atom.project.path, @selectedIndexFile.text())
    httpPort = parseInt @httpPort.getText()
    pushState = @find('#usingPushState').is(":checked")

    #TODO: validation

    @trigger 'createServer', [rootPath, destPath, httpPort, pushState]

    @destroy()

  attach: ->
    atom.workspaceView.append(this)

  destroy: ->
    @remove()

  toggle: ->
    if @hasParent() then @detach() else @attach()
