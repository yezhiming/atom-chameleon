{$, View, EditorView} = require 'atom'
{openFile} = require('../utils/dialog')

module.exports =
class V extends View
  @content: ->
    @div id: 'ios-build-view', =>
      @h2 'Build iOS App:'

      @div class: 'row', =>
        @div class: 'col-xs-3', =>
          @img class: 'icon', click: 'onClickIcon', outlet: 'icon'
          @subview 'title', new EditorView(mini: true, placeholderText: 'Title'), class: 'title'

        @div class: 'col-xs-9', =>

          @div class: 'form-group', =>
            @label 'Mobileprovision:'
            @subview 'mobileprovision', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'p12:'
            @subview 'p12', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'p12 password:'
            @subview 'editor', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'Application URL:'
            @subview 'editor', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'Scheme:'
            @subview 'editor', new EditorView(mini: true)
          @div class: 'form-group', =>
            @label 'Content Src:'
            @subview 'src', new EditorView(mini: true)

  initialize: ->
    [
      {view: @mobileprovision, suffix: 'mobileprovision'}
      {view: @p12, suffix: 'p12'}
      {view: @src, suffix: 'html'}
    ]
    .forEach (each) ->
      #disable input
      # each.view.setInputEnabled false
      #select file
      each.view.on 'click', ->
        openFile({
          title: "Select .#{each.suffix} File"
          filters: [{name: ".#{each.suffix} file", extensions: [each.suffix]}]
        })
        .then (destPath) ->
          console.log "!!! #{each.view.setText}"
          each.view.setText(destPath)

  onClickIcon: ->
    openFile({
      title: 'Select Icon Image'
      filters: [{name: "png image", extensions: ['png']}]
    })
    .then (destPath) =>
      @icon.attr('src', destPath) if destPath
