{$, View, SelectListView, $$} = require 'atom'
Q = require 'q'
puzzleClient = require '../utils/puzzle-client'

class BuildTaskListView extends SelectListView

  initialize: ->
    super
    @filterEditorView.off 'blur'
    @off 'core:cancel'

  getFilterKey: -> 'id'

  # Here you specify the view for an item
  viewForItem: (item) ->
    $$ ->
      @li =>
        @p item.id
        @p item.state
        @p new Date(parseInt(item.created_at)).toString()

  confirmed: (item) ->
    buildStateView = new (require './build-state-view')()
    buildStateView.attach()
    buildStateView.listViewInput()
    buildStateView.setTask(item)

module.exports =
class V extends View
  @content: ->
    @div class: 'butterfly overlay from-top', =>
      @h1 'Build List'
      @subview 'listView', new BuildTaskListView()

      @div class: 'actions', =>
        @div class: 'pull-left', =>
          @button 'Cancel', click: 'destroy', class: 'inline-block-tight btn'
        @div class: 'pull-right', =>
          @button 'Refresh', click: 'refreshTaskList', class: 'inline-block-tight btn'

  initialize: ->

  attach: ->
    atom.workspaceView.append(this)
    @refreshTaskList()

  destroy: ->
    @detach()

  refreshTaskList: ->
    puzzleClient.getTasks()
    .then (result) =>
      @listView.setItems(result)
    .catch (err) ->
      alert('fetch build tasks fail.' + err)
      trace err.stack
