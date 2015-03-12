{$, View, EditorView} = require 'atom'
{openFile} = require '../utils/dialog'
path = require 'path'
_ = require 'underscore'
AppRepoListView = require './app-repo-list-view'

{getResourcePath} = require '../utils/utils'

url = require 'url'

KEYS = ['title', 'version', 'build', 'keystore', 'alias'
'keypass', 'aliaspass', 'repository_url', 'scheme', 'content_src']

module.exports =
class V extends View
  @content: ->
    @div id: 'android-build-view', =>
      @h2 'Build android App:'

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
            @label 'Application URL:'
            @subview 'repository_url', new EditorView(mini: true,placeholderText:'Click to choose your Application URL')
          @div class: 'form-group', =>
            @label 'Build type:'
            @subview 'scheme', new EditorView(mini: true,placeholderText:'Please input bundle or sandbox')
          @div class: 'form-group', =>
            @label 'Content Src:'
            @subview 'content_src', new EditorView(mini: true, placeholderText: 'Click here to select your content-src')


          @div class: 'optional-checkbox', =>
            @input type: 'checkbox', outlet: 'useMyCert', click: 'toggleUseMyCert'
            @span 'Use my keystore:'

          @div outlet: 'cert', =>
            @div class: 'form-group', =>
              @label 'keystore:'
              @subview 'keystore', new EditorView(mini: true, placeholderText: 'Click here to select keystore file')
            @div class: 'form-group', =>
              @label 'alias:'
              @subview 'alias', new EditorView(mini: true,placeholderText:'Please input alias')
            @div class: 'form-group', =>
              @label 'keypass:'
              @subview 'keypass', new EditorView(mini: true,placeholderText:'Please input keypass')
            @div class: 'form-group', =>
              @label 'aliaspass:'
              @subview 'aliaspass', new EditorView(mini: true,placeholderText:'Please input aliaspass')



  initialize: ->
    [
      {view: @keystore, suffix: 'keystore'}
      {view: @content_src, suffix: 'html', relative: true}
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
            each.view.setText path.relative(atom.project.rootDirectories[0].path, destPath[0])
          else
            each.view.setText destPath[0]

    @repository_url.on 'click', =>
      new AppRepoListView()
      .on 'confirmed', (event, repo) => @repository_url.setText repo.url
      .attach()
      .filterPlatform('android')

    @title.setText _.last(atom.project.rootDirectories[0].path.split(path.sep)) if atom.project.rootDirectories[0].path
    @version.setText "1.0.0"
    @build.setText "1"
    @icon.attr 'src', getResourcePath('images', 'icon.png')

    @repository_url.setText 'https://git.oschina.net/chameleon/chameleon-android-v3.git'
    @scheme.setText 'bundle'
    @content_src.setText 'main/index.html'

  attached: ->
    console.log 'attached'
    @cert.toggle()

  toggleUseMyCert: ->
    @cert.toggle()

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

    unless @useMyCert.prop('checked')
      result = _.omit result, ['keystore', 'alias', 'keypass','aliaspass']

    return result

  iconSrcPath:->
    if process.platform is "win32"
      {icon: url.parse(this.icon[0].src).path.replace("/","")}
    else
      {icon: url.parse(this.icon[0].src).path}

  onNext: (wizard) ->
    wizard.mergeOptions @serialize()
    wizard.nextStep()
