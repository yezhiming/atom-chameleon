{$, View, EditorView} = require 'atom'
{openFile} = require '../utils/dialog'
path = require 'path'
_ = require 'underscore'
AppRepoListView = require './app-repo-list-view'

KEYS = ['title', 'version', 'build', 'bundleIdentifier', 'mobileprovision'
'p12', 'p12_password', 'scheme', 'content_src', 'repository_url']

module.exports =
class V extends View
  @content: ->
    @div id: 'ios-build-view', =>
      @h2 'Build iOS App:'

      @div class: 'row', =>
        @div class: 'col-xs-3', =>
          @img class: 'icon', click: 'onClickIcon', outlet: 'icon'
          @subview 'title', new EditorView(mini: true, placeholderText: 'Title'), class: 'title'
          @subview 'version', new EditorView(mini: true, placeholderText: 'Version'), class: 'version'
          @subview 'build', new EditorView(mini: true, placeholderText: 'Build'), class: 'build'

        @div class: 'col-xs-9', =>

          @div class: 'form-group', =>
            @label 'Mobileprovision:'
            @subview 'mobileprovision', new EditorView(mini: true, placeholderText: 'click here to select mobileprovision file')
          @div class: 'form-group', =>
            @label 'p12:'
            @subview 'p12', new EditorView(mini: true, placeholderText: 'click here to select p12 file')
          @div class: 'form-group', =>
            @label 'p12 password:'
            @subview 'p12_password', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'Application URL:'
            @subview 'repository_url', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'Scheme:'
            @subview 'scheme', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'Bundle Identifier:'
            @subview 'bundleIdentifier', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'Content Src:'
            @subview 'content_src', new EditorView(mini: true, placeholderText: 'click here to content-src')

  initialize: ->
    [
      {view: @mobileprovision, suffix: 'mobileprovision'}
      {view: @p12, suffix: 'p12'}
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

    @repository_url.on 'click', =>
      new AppRepoListView()
      .on 'confirmed', (event, repo) => @repository_url.setText repo.url
      .attach()
      .filterPlatform('ios')

    # set defaults
    @title.setText _.last(atom.project.path.split("/")) if atom.project.path
    @version.setText "1.0.0"
    @build.setText "1"

    # restore last options
    # console.log "window: #{window.localStroage}"
    # json = window.localStroage.getItem "ios-build-view"
    # if json
    #   json = JSON.parse json
    #   KEYS.each (key) =>
    #     this[key].setText json[key]
    #   @icon.prop 'src', json['icon']

  destroy: ->

    # save last options
    # localStroage.setItem "ios-build-view", JSON.stringify(@serialize())

    console.log  "ios-build-view destroy."
    @remove()

  onClickIcon: ->
    openFile
      title: 'Select Icon Image'
      filters: [{name: "png image", extensions: ['png']}]
    .then (destPath) =>
      @icon.attr('src', destPath[0]) if destPath.length > 0

  serialize: ->
    KEYS.reduce (all, key) =>
      all[key] = this[key].getText()
      return all
    , {icon: @icon[0].src.replace "file://", ""}

  getResult: ->
    @serialize()
