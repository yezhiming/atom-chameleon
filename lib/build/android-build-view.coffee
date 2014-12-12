{$, View, EditorView} = require 'atom'
{openFile} = require '../utils/dialog'
path = require 'path'
_ = require 'underscore'

module.exports =
class V extends View
  @content: ->
    @div id: 'android-build-view', =>
      @h2 'Build android App:'

      @div class: 'row', =>
        @div class: 'col-xs-3', =>
          @img class: 'icon', click: 'onClickIcon', outlet: 'icon'
          @subview 'title', new EditorView(mini: true, placeholderText: 'Title'), class: 'title'
          @subview 'version', new EditorView(mini: true, placeholderText: 'Version'), class: 'version'
          @subview 'build', new EditorView(mini: true, placeholderText: 'Build'), class: 'build'

        @div class: 'col-xs-9', =>

          @div class: 'form-group', =>
            @label 'keystore:'
            @subview 'keystore', new EditorView(mini: true, placeholderText: 'click here to select keystore file')
          @div class: 'form-group', =>
            @label 'alias:'
            @subview 'alias', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'keypass:'
            @subview 'keypass', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'aliaspass:'
            @subview 'aliaspass', new EditorView(mini: true)
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
      {view: @keystore, suffix: 'keystore'}
      # {view: @p12, suffix: 'p12'}
      {view: @src, suffix: 'html', relative: true}
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
          if each.relative?
            each.view.setText path.relative(atom.project.path, destPath[0])
          else
            each.view.setText destPath[0]

    @title.setText _.last(atom.project.path.split(path.sep))
    @version.setText "1.0.0"
    @build.setText "1"

    path = atom.project.getPath()+"/resource/android"
    @icon.attr('src',"#{path}/test.png")
    @keystore.setText "#{path}/test_1.keystore"
    @alias.setText "test_1"
    @keypass.setText "test123"
    @aliaspass.setText "test123"
    @url.setText "http://localhost:800/androiddown/android.zip"
    @scheme.setText "bundle"
    @src.setText "exhibition/index.html"

  onClickIcon: ->
    openFile
      title: 'Select Icon Image'
      filters: [{name: "png image", extensions: ['png']}]
    .then (destPath) =>
      @icon.attr('src', destPath[0]) if destPath.length > 0

  getResult: ->
    icon:@icon[0].src.replace "file://", ""
    title: @title.getText()
    version: @version.getText()
    build:@build.getText()
    keystore: @keystore.getText()
    alias: @alias.getText()
    keypass:@keypass.getText()
    aliaspass:@aliaspass.getText()
    scheme: @scheme.getText()
    content_src: @src.getText()
    app_url: @url.getText()
