{$, View, EditorView} = require 'atom'
{openFile} = require '../utils/dialog'
path = require 'path'
_ = require 'underscore'

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
            @subview 'password', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'Application URL:'
            @subview 'url', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'Scheme:'
            @subview 'scheme', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'Content Src:'
            @subview 'src', new EditorView(mini: true, placeholderText: 'click here to content-src')

  initialize: ->
    [
      {view: @mobileprovision, suffix: 'mobileprovision'}
      {view: @p12, suffix: 'p12'}
      {view: @src, suffix: 'html'}
    ]
    .forEach (each) ->
      #disable input
      each.view.setInputEnabled false
      #select file
      each.view.on 'click', ->
        openFile
          title: "Select .#{each.suffix} File"
          filters: [{name: ".#{each.suffix} file", extensions: [each.suffix]}]
        .then (destPath) ->
          each.view.setText destPath[0]

    @title.setText _.last(atom.project.path.split(path.sep))
    @version.setText "1.0.0"
    @build.setText "1"

  onClickIcon: ->
    openFile
      title: 'Select Icon Image'
      filters: [{name: "png image", extensions: ['png']}]
    .then (destPath) =>
      @icon.attr('src', destPath[0]) if destPath.length > 0

  getResult: ->
    title: @title.getText()
    version: @version.getText()
    build: @build.getText()
    Mobileprovision: @mobileprovision.getText()
    p12: @p12.getText()
    p12_password: @password.getText()
    scheme: @scheme.getText()
    content_src: @src.getText()
    app_url: @url.getText()
