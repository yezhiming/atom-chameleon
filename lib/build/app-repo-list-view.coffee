{$, View, SelectListView, $$} = require 'atom'
request = require 'request'
Q = require 'q'
_ = require 'underscore'

class AppRepoListView extends SelectListView

  initialize: ->
    super
    @filterEditorView.off 'blur'
    @off 'core:cancel'

  getFilterKey: -> 'name'

  # Here you specify the view for an item
  viewForItem: (item) ->
    $$ ->
      @li =>
        @p item.name
        @p item.url
        @p item.description

  confirmed: (item) ->
    @trigger 'confirmed', item

repos = [
  {
    name: 'Chameleon iOS'
    url: 'https://git.oschina.net/chameleon/chameleon-ios/repository/archive?ref=master'
    description: 'Standard Chameleon Application'
    platform: 'ios'
  }
  {
    name: 'Chameleon iOS with All Plugins'
    url: 'https://git.oschina.net/chameleon/chameleon-ios/repository/archive?ref=master'
    description: 'Chameleon Application All'
    platform: 'ios'
  }
  {
    name: 'Chameleon iOS Test'
    url: 'http://localhost:800/iosdown/ios.zip'
    description: 'Chameleon iOS for testing'
    platform: 'ios'
  }
  {
    name: 'Chameleon Android'
    url: 'https://git.oschina.net/chameleon/chameleon-android-v3/repository/archive?ref=master'
    description: 'Standard Chameleon Application'
    platform: 'android'
  }
]

module.exports =
class V extends View
  @content: ->
    @div class: 'butterfly overlay from-top', =>
      @h1 'Select Application Reponsitory:'
      @subview 'listView', new AppRepoListView()

      @div class: 'actions', =>
        @div class: 'pull-left', =>
          @button 'Cancel', click: 'destroy', class: 'inline-block-tight btn'
        @div class: 'pull-right', =>
          @button 'Add', click: 'onClickAdd', class: 'inline-block-tight btn'

  initialize: ->
    @server = atom.config.get('atom-butterfly.puzzleServerAddress')
    @serverSecured = atom.config.get('atom-butterfly.puzzleServerAddressSecured')
    @access_token = atom.config.get('atom-butterfly.puzzleAccessToken')

    @listView.on 'confirmed', (event, item) =>
      @trigger 'confirmed', item
      @destroy()

  attach: ->
    atom.workspaceView.append(this)
    return this

  destroy: ->
    @remove()

  filterPlatform: (platform) ->
    filtered = _.filter repos, (repo)-> repo.platform == platform
    @listView.setItems(filtered)
