{$, $$, View, EditorView} = require 'atom'
{openFile} = require '../utils/dialog'
path = require 'path'
_ = require 'underscore'

url = require 'url'

AppRepoListView = require './app-repo-list-view'
{getResourcePath} = require '../utils/utils'

KEYS = ['title', 'version', 'build', 'bundleIdentifier', 'content_src']

module.exports =
class V extends View
  @content: ->
    @div id: 'ios-build-view', =>
      @h1 'Fast Build iOS App:'

      @div class: 'row', =>
        @div class: 'col-xs-3', =>
          @img class: 'icon', click: 'onClickIcon', outlet: 'icon'
          @div class: 'form-group', =>
            @label 'Title:'
            @subview 'title', new EditorView(mini: true, placeholderText: 'Title')
          @div class: 'form-group', =>
            @label 'Version:'
            @subview 'version', new EditorView(mini: true, placeholderText: 'Version')
          @div class: 'form-group', =>
            @label 'Build:'
            @subview 'build', new EditorView(mini: true, placeholderText: 'Build')
          

        @div class: 'col-xs-9', =>
        
          @div class: 'form-group', =>
            @label 'Bundle Identifier:'
            @subview 'bundleIdentifier', new EditorView(mini: true, placeholderText: 'Please input your Bundle Identifier')
          @div class: 'form-group', =>
            @label 'Scheme:'
            @select class:'form-control', outlet: 'scheme', =>
              @option "chameleon-bundled"
              @option "chameleon-sandbox"
          @div class: 'form-group', =>
            @label 'Content Src:'
            @subview 'content_src', new EditorView(mini: true, placeholderText: 'Click here to select your content-src')
        

  initialize: ->
    # 选择文件
    [
      {view: @content_src, suffix: 'html', relative: true}
    ]
    .forEach (each) ->
      #disable input
      each.view.setInputEnabled false
      #select file
      each.view.on 'click', ->
        console.log "window: #{window.localStroage}"
        openFile
          title: "Select .#{each.suffix} File"
          filters: [{name: ".#{each.suffix} file", extensions: [each.suffix]}]
        .then (destPath) ->
          if each.relative
            each.view.setText path.relative(atom.project.path, destPath[0])
          else
            each.view.setText destPath[0]

    # set defaults
    @title.setText _.last(atom.project.path.split(path.sep)) if atom.project.path
    @version.setText "1.0.0"
    @build.setText "1"
    @icon.attr 'src', getResourcePath('images', 'icon.png')

    @bundleIdentifier.setText 'com.foreveross.chameleon'
    @content_src.setText 'main/index.html'

  attached: ->
    console.log 'attached'

  destroy: ->
    console.log  "ios-build-view destroy."
    @remove()

  onClickIcon: ->
    openFile
      title: 'Select Icon Image'
      filters: [{name: "png image", extensions: ['png']}]
    .then (destPath) =>
      @icon.attr('src', destPath[0]) if destPath.length > 0

  serialize: ->
    result = KEYS.reduce (all, key) =>
      all[key] = this[key].getText()
      return all
    , @iconSrcPath()
    result = _.extend result, scheme: "#{@scheme.val()}"
    return result

  iconSrcPath:->
    if process.platform is "win32"
      {icon: url.parse(this.icon[0].src).path.replace("/","")}
    else
      {icon: url.parse(this.icon[0].src).path}

  onNext: (wizard) ->
    wizard.mergeOptions @serialize()
    wizard.nextStep()
