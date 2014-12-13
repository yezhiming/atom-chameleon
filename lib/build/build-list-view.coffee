{$, View, SelectListView, $$} = require 'atom'
request = require 'request'
Q = require 'q'

class BuildTaskListView extends SelectListView

  initialize: ->
    super
    @filterEditorView.off 'blur'

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
    @server = atom.config.get('atom-butterfly.puzzleServerAddress')
    @serverSecured = atom.config.get('atom-butterfly.puzzleServerAddressSecured')
    @access_token = atom.config.get('atom-butterfly.puzzleAccessToken')

  attach: ->
    atom.workspaceView.append(this)
    @refreshTaskList()

  destroy: ->
    @detach()

  refreshTaskList: ->
    Q.nfcall request.get, "#{@server}/api/tasks?access_token=#{@access_token}"
    .then (result) ->
      JSON.parse result[1]
    .then (result) =>
      @listView.setItems(result)
    .catch (err) ->
      alert('fetch build tasks fail.' + err)
      trace err.stack
