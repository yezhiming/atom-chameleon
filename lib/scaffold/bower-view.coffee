{$, View, SelectListView} = require 'atom'
bower = require 'bower'
_ = require 'underscore'

class ComponentSelectListView extends SelectListView

  inputThrottle: 1000

  initialize: () ->
    super
    @filterEditorView.off 'blur'

  confirmed: (item) ->

  #override this to stop populateList() from searching
  getFilterQuery: -> ""

  #and copy one for our own use
  _getFilterQuery: ->
    @filterEditorView.getEditor().getText()

  schedulePopulateList: ->

    @search_id = _.uniqueId('bower_search_')

    clearTimeout(@scheduleTimeout)
    populateCallback = (uid)=>
      filterQuery = @_getFilterQuery()
      @setLoading("searching #{filterQuery}...")
      bower.commands.search(filterQuery).on 'end', (results) =>
        @setItems results
        if @isOnDom() and uid == @search_id
          @populateList()
        else
          console.log "drop result"
        @setLoading()

    @scheduleTimeout = setTimeout =>
      populateCallback(@search_id)
    ,  @inputThrottle

  # Here you specify the view for an item
  viewForItem: (item) ->
    "<li> <div>#{item.name}</div> <div>#{item.url}</div> </li>"

class SelectedComponentListView extends SelectListView

  viewForItem: (item) ->
    "<li> #{item.name} #{item.url} </li>"

module.exports =
class BowerView extends View
  @content: ->
    @div class: 'butterfly overlay from-top width-700', =>
      @div class: 'col-xs-5', =>
        @h1 'Select Bower Components'
        @subview 'selectListView', new ComponentSelectListView()
      @div class: 'col-xs-2', =>
        @button click: 'onClickSelect', '->', class: 'btn btn-lg btn-primary'
        @button click: 'onClickDeselect', '<-', class: 'btn btn-lg btn-primary'
      @div class: 'col-xs-5', =>
        @h1 'Selected Components'
        @subview 'selectedListView', new SelectedComponentListView()

      @span click: 'destroy', class: 'glyphicon glyphicon-remove close-view'

  initialize: ->
    @selectedItems = []
    @selectedListView.setItems(@selectedItems)

  attach: ->
    atom.workspaceView.append(this)

  destroy: ->
    @detach()

  toggle: ->
    if @hasParent() then @detach() else @attach()

  onClickSelect: ->
    item = @selectListView.getSelectedItem()
    @selectedItems.push(item)
    @selectedListView.setItems(@selectedItems)

  onClickDeselect: ->
