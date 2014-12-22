{$, $$, View, EditorView} = require 'atom'
{openFile} = require '../utils/dialog'
path = require 'path'
_ = require 'underscore'
AppRepoListView = require './app-repo-list-view'
{getResourcePath} = require '../utils/utils'

KEYS = ['title', 'version', 'build', 'bundleIdentifier', 'mobileprovision'
'p12', 'p12_password', 'scheme', 'content_src', 'repository_url','pushp12','pushp12password']

module.exports =
class V extends View
  @content: ->
    @div id: 'ios-build-view', =>
      @h1 'Build iOS App:'

      @div class: 'row', =>
        @div class: 'col-xs-3', =>
          @img class: 'icon', click: 'onClickIcon', outlet: 'icon'
          @div class: 'form-group', =>
            @label 'Title:'
            @subview 'title', new EditorView(mini: true, placeholderText: 'Title'), class: 'title'
          @div class: 'form-group', =>
            @label 'Version:'
            @subview 'version', new EditorView(mini: true, placeholderText: 'Version'), class: 'version'
          @div class: 'form-group', =>
            @label 'Build:'
            @subview 'build', new EditorView(mini: true, placeholderText: 'Build'), class: 'build'

        @div class: 'col-xs-9', =>

          @div class: 'form-group', =>
            @label 'Bundle Identifier:'
            @subview 'bundleIdentifier', new EditorView(mini: true)

          @div class: 'form-group', =>
            @label 'Application URL:'
            @subview 'repository_url', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'Scheme:'
            @subview 'scheme', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'Content Src:'
            @subview 'content_src', new EditorView(mini: true, placeholderText: 'click here to content-src')

          # use my cert
          @div class: 'optional-checkbox', =>
            @input type: 'checkbox', outlet: 'useMyCert', click: 'toggleUseMyCert'
            @span 'Use my mobileprovision:'

          @div outlet: 'cert', =>
            @div class: 'form-group', =>
              @label 'Mobileprovision:'
              @subview 'mobileprovision', new EditorView(mini: true, placeholderText: 'click here to select mobileprovision file')
            @div class: 'form-group', =>
              @label 'p12:'
              @subview 'p12', new EditorView(mini: true, placeholderText: 'click here to select p12 file')
            @div class: 'form-group', =>
              @label 'p12 password:'
              @subview 'p12_password', new EditorView(mini: true)

          # use push
          @div class: 'optional-checkbox', =>
            @input type: 'checkbox', outlet: 'usePushCert', click: 'togglePushServersCert'
            @span 'Use Push Services:'

          @div outlet:"pushcer",=>
            @div class: 'form-group', =>
              @label 'Push Services p12 path:'
              @subview 'pushp12', new EditorView(mini: true, placeholderText: 'click here to Push Services p12 path')
            @div class: 'form-group', =>
              @label 'Push Services p12 password:'
              @subview 'pushp12password', new EditorView(mini: true)

  initialize: ->
    # 选择文件
    [
      {view: @mobileprovision, suffix: 'mobileprovision'}
      {view: @p12, suffix: 'p12'}
      {view: @content_src, suffix: 'html', relative: true}
      {view:@pushp12,suffix:'p12'}
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

    # 选择原生代码仓库
    @repository_url.on 'click', =>
      new AppRepoListView()
      .on 'confirmed', (event, repo) => @repository_url.setText repo.url
      .attach()
      .filterPlatform('ios')

    # set defaults
    @title.setText _.last(atom.project.path.split("/")) if atom.project.path
    @version.setText "1.0.0"
    @build.setText "1"
    @icon.attr 'src', getResourcePath('images', 'icon.png')

    # restore last options
    # console.log "window: #{window.localStroage}"
    # json = window.localStroage.getItem "ios-build-view"
    # if json
    #   json = JSON.parse json
    #   KEYS.each (key) =>
    #     this[key].setText json[key]
    #   @icon.prop 'src', json['icon']

  attached: ->
    console.log 'attached'
    @cert.toggle()
    @pushcer.toggle()

  destroy: ->

    # save last options
    # localStroage.setItem "ios-build-view", JSON.stringify(@serialize())

    console.log  "ios-build-view destroy."
    @remove()

  toggleUseMyCert: ->
    @cert.toggle()

  togglePushServersCert: ->
    @pushcer.toggle()

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
    , {icon: @icon[0].src.replace "file://", ""}

    unless @useMyCert.prop('checked')
      result = _.omit result, ['mobileprovision', 'p12', 'p12_password']

    unless @usePushCert.prop('checked')
      result = _.omit result, ['pushp12', 'pushp12password']

    return result

  onNext: (wizard) ->
    wizard.mergeOptions @serialize()
    wizard.nextStep()
