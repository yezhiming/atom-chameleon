{$, View, EditorView} = require 'atom'

module.exports =
class V extends View
  @content: ->
    @div =>
      @h2 'Build iOS App:'
      @div class: "form-group", =>
        @label 'Project Name:'
        @subview 'editor', new EditorView(mini: true)

      @div class: 'form-group', =>
        @label 'Mobileprovision:'
        @subview 'editor', new EditorView(mini: true)

      @div class: 'form-group', =>
        @label 'p12:'
        @subview 'editor', new EditorView(mini: true)

      @div class: 'form-group', =>
        @label 'p12 password:'
        @subview 'editor', new EditorView(mini: true)

      @div class: 'form-group', =>
        @label 'Application URL:'
        @subview 'editor', new EditorView(mini: true)

      @div class: 'form-group', =>
        @label 'Scheme:'
        @subview 'editor', new EditorView(mini: true)
