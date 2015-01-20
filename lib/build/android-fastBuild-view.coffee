{$, View, EditorView} = require 'atom'
{openFile} = require '../utils/dialog'
path = require 'path'
_ = require 'underscore'
AppRepoListView = require './app-repo-list-view'

{getResourcePath} = require '../utils/utils'

url = require 'url'

KEYS = ['title', 'version', 'build', 'content_src']

module.exports =
class V extends View
  @content: ->
    @div id: 'android-build-view', =>
      @h2 'Fast Build android App:'

      @div class: 'row', =>
        @div class: 'col-xs-3', =>
          @img class: 'icon', outlet: 'icon'
    
        @div class: 'col-xs-9', =>

          @div class: 'form-group', =>
            @label 'Title:'
            @subview 'title', new EditorView(mini: true, placeholderText: 'Title'), class: 'title'
          @div class: 'form-group', =>
            @label 'Version:'
            @subview 'version', new EditorView(mini: true, placeholderText: 'Version'), class: 'version'
          @div class: 'form-group', =>
            @label 'Build:'
            @subview 'build', new EditorView(mini: true, placeholderText: 'Build'), class: 'build'

          @div class: 'form-group', =>
            @label 'Scheme:'
            @select class:'form-control', outlet: 'scheme', =>
              @option "chameleon-bundled"
              @option "chameleon-sandbox"

          # @div class: 'form-group', =>
          #   @label 'Content Src:'
          #   @subview 'content_src', new EditorView(mini: true, placeholderText: 'click here to content-src')

  initialize: ->
    @title.setText _.last(atom.project.path.split(path.sep)) if atom.project.path
    @version.setText "1.0.0"
    @build.setText "1"
    @icon.attr 'src', getResourcePath('images', 'icon.png')

    @readOnlyEditorView @title
    @readOnlyEditorView @version
    @readOnlyEditorView @build
  
  serialize: ->
    # result = KEYS.reduce (all, key) =>
    #   all[key] = this[key].getText()
    #   return all
    # , @iconSrcPath()
    # result = _.extend result, scheme: "#{@scheme.val()}"
    result = scheme: "#{@scheme.val()}"
    return result


  iconSrcPath:->
    if process.platform is "win32"
      {icon: url.parse(this.icon[0].src).path.replace("/","")}
    else
      {icon: url.parse(this.icon[0].src).path}

  onNext: (wizard) ->
    wizard.mergeOptions @serialize()
    wizard.nextStep()

  readOnlyEditorView: (editorView)->
    editorView.setInputEnabled false
    editorView.hiddenInput.on 'keydown', (e) =>
      if e.which == 8
        return false
        
