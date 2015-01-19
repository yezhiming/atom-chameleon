{View} = require 'atom'

#
# using webview tag:
# https://github.com/atom/atom-shell/blob/master/docs/api/web-view-tag.md
#
module.exports =
class EmulatorView extends View
  @content: ->
    @div class: 'butterfly emulator-view', 'data-show-on-left-side': atom.config.get('tree-view.showOnRightSide'), =>
      @div class: 'nav', =>
        @span click: 'onClickRefresh', class: 'glyphicon glyphicon-refresh'
        @div click: 'onClickAddressBar', outlet: 'url', class:'address'
        @span click: 'destroy', class: 'glyphicon glyphicon-remove'

      @div class: 'device', =>
        @tag 'webview', outlet: 'webview', class: 'device-content'

      # @div class: 'control', =>
      #   @form class: 'form-inline', role: 'form', =>
      #
      #     @div class: 'block', =>
      #       @button 'Open with Chrome', class: 'btn btn-primary inline-block-tight', click: 'onClickChrome'
      #       @button 'Open with iOS Emulator', class: 'btn btn-primary inline-block-tight', click: 'onClickIOSSimulator'
      #       @button 'Debug', class: 'btn btn-primary inline-block-tight', click: 'onClickDebug'

  initialize: (serializeState) ->
    #observe tree-view side toggle event
    @subscribe atom.config.observe 'tree-view.showOnRightSide', callNow: false, (newValue) =>
      @detach()
      @attach()
      @element.dataset.showOnLeftSide = newValue

    @url.text('http://localhost:3000')

  attach: ->
    if atom.config.get('tree-view.showOnRightSide')
      atom.workspaceView.appendToLeft(this)
    else
      atom.workspaceView.appendToRight(this)

    @setTargetUrl()

  destroy: ->
    @detach()

  toggle: ->
    if @hasParent() then @detach() else @attach()

  getTargetUrl: ->
    @url.text()

  setTargetUrl: (url)->
    @find('webview').attr('src', url)

  onClickAddressBar: ->
    #TODO: launch mini editor

  onClickRefresh: ->
    console.log "refresh"
    @setTargetUrl(@url.text())
    try
      @webview[0].reload()
    catch
      console.log "webview is not open"

  onClickDebug: ->
    webview = document.querySelector('webview')
    webview.openDevTools() unless webview.isDevToolsOpened()

  onClickChrome: ->
    {exec} = require 'child_process'
    exec("open -a Google\\ Chrome #{@getTargetUrl()}")

  onClickIOSSimulator: ->
    {exec} = require 'child_process'
    exec("open -a 'iOS Simulator' --args -u #{@getTargetUrl()}");

  #   #参考链接：http://apple.stackexchange.com/questions/117064/how-to-launch-browser-in-ios-simulator-from-command-line
  #
  #   #基础路径
  #   ios_sim_platform = '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform'
  #   #iOS模拟器（Mac应用）
  #   ios_sim_app = "#{ios_sim_platform}/Developer/Applications/iPhone\\ Simulator.app/Contents/MacOS/iPhone\\ Simulator"
  #   #要打开的地址
  #   url = 'http://localhost:3000'
  #   #组装命令
  #   command = "#{ios_sim_app} -u #{url}"
  #   #执行
  #   exec(command);
