{ScrollView} = require 'atom'

module.exports =
class EmulatorView extends ScrollView
  @content: ->
    @div class: 'emulator-view', 'data-show-on-left-side': atom.config.get('tree-view.showOnRightSide'), =>
      @div class: 'device', =>
        @iframe class: 'content'
      @div class: 'control', =>
        @input outlet: 'url'
        @button 'Open', class: 'btn btn-primary', click: 'onClickOpen'

  initialize: (serializeState) ->
    #换另外一边时用到 添加一个观察者
    @subscribe atom.config.observe 'tree-view.showOnRightSide', callNow: false, (newValue) =>
      @onSideToggled(newValue)

    @url.val('http://localhost:3000')

  attach: ->
    if atom.config.get('tree-view.showOnRightSide')
      atom.workspaceView.appendToLeft(this)
    else
      atom.workspaceView.appendToRight(this)

  toggle: ->
    if @hasParent() then @detach() else @attach()

  #换边时响应函数
  onSideToggled: (newValue) ->
    @detach()
    @attach()
    @element.dataset.showOnLeftSide = newValue

  setTargetUrl: (url = 'http://localhost:3000')->
    @find('iframe').attr('src', url)

  onClickOpen: ->
    @setTargetUrl(@url.val())
