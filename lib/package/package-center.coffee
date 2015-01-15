{View, EditorView} = require 'atom'
_ = require 'underscore'
request = require 'request'
Q = require 'q'
{openDirectory} = require '../utils/dialog'
git = require '../project/scaffolder'
path = require 'path'
#包列表项视图
class PackageListCell extends View
  @content: ->
    @div class: 'row', =>
      @div class: 'available-package-view col-lg-8', =>
        @div class: 'stats pull-right', =>
          @span class: 'stats-item', =>
            @span class: 'icon icon-star'
            @span outlet: 'rating', class: 'value'
        @div class: 'body', =>
          @h4 class: 'card-name', =>
            @a outlet: 'title'
          @span class: 'package-description', outlet: 'description'
        @div class: 'meta', =>
          @div class: 'meta-user', =>
            @span 'Author'
            @a class: 'author', outlet: 'author'
          @div class: 'meta-controls', =>
            @div class: 'btn-group', =>
              @button outlet: 'installButton', click: 'onInstallButtonClick', type: 'button', class: 'btn btn-info icon icon-cloud-download install-button', 'Install'

  initialize: (params) ->
    @data = params.info
    @title.text @data.name or 'no package name'
    @title.attr 'href', @data.home_url
    @author.text @data.author or 'no package author'
    @description.text @data.description or 'no package description'
    @rating.text @data.rating
    @callback = params.callback

  onInstallButtonClick: ->
    @callback this, @data.repo if @callback
  #标识正在下载
  setInstalling: (install) ->
    @installButton.attr('class', 'btn btn-info icon icon-cloud-download install-button ' + if install then 'is-installing disabled')


PuzzleServer = atom.config.get 'atom-butterfly.puzzleServerAddress'
PuzzleAccessToken = atom.config.get 'atom-butterfly.puzzleAccessToken'

module.exports =
  class Center extends View
    @content: ->
      @div class: 'settings-view package-center pane-item', =>
        @div class: 'panels', =>
          @div class: 'space-pen-div', =>
            @div class: 'section packages' , =>
              @div class: 'section-container', =>
                @h1 class: 'section-heading icon icon-cloud-download', 'Install Packages'
                @div class: 'control-group', =>
                @div class: 'text native-key-bindings', tabindex: '-1', =>
                  @span class: "icon icon-question"
                  @span 'The Chameleon package are installed to your selected path'
                  # @div class: 'controls', =>
                  #   @label class: 'congtrol-label', =>
                  #     @div class: 'setting-title', 'Install Path'
                  #     @div class: 'setting-description'
                  @div class: 'controls', =>
                    @div class: 'editor-container', =>
                      @subview 'installPathEditor', new EditorView mini:true, placeholderText: 'Package Install Path'
                @div class: 'search-container clearfix', =>
                  @div class: 'editor-container', =>
                    @subview 'editor', new EditorView(mini: true, placeholderText: 'Search Packages')
                  @div class: 'btn-group', =>
                    @button click: 'onSearchEnter', class: 'btn btn-default selected', 'Search'
                @div outlet:'searchTip', class: 'alert alert-info search-message icon icon-search', style: 'display:none;'
                @div class: 'container package-container', outlet: 'packageList'
            @div class: 'section packages' , =>
              @div class: 'section-container', =>
                @h1 class: 'section-heading icon icon-star', 'Featured Packages'


    initialize: (options = {})->
      @editor.on 'core:confirm', => @onSearchEnter()
      @editor.on 'keyup', => @onSearchEnter()
      @installPathEditor.on 'click', => @choosePath()
      @installPathEditor.setText options.path if options.path

    attach: ->
      aPane = atom.workspaceView.getActivePane()
      item = aPane.addItem this
      aPane.activateItem item
    #响应搜索输入栏回车事件
    onSearchEnter: (event)->
      packageName = @editor.getText()
      @searchPackage packageName, (packages, keyword)=> @onSearchDone(packages, keyword)

    #根据关键字搜索包
    searchPackage: (keyword, done)->

      return done @serverPackages, keyword if @serverPackages

      return if @isFetching
      @isFetching = yes
      @fetchAllPackageFormServer().then (result)=>
        console.log "fetch all packages info finished,total:#{result.length}"
        @isFetching = no
        @serverPackages = result
        done @serverPackages, keyword

    #从服务器拉取所有安装包信息
    fetchAllPackageFormServer:() ->
        Q.promise (resolve, reject, notify) =>
          r = request.get "#{PuzzleServer}/api/packages?access_token=#{PuzzleAccessToken}&sequence=1", (err, res, body) =>
            reject err if err
            data = JSON.parse(body)
            resolve data.packages

    #搜索完成时回调
    onSearchDone: (packages, keyword)->

      filter = _.filter packages, (pack)->
        -1 != pack.name.toLowerCase().indexOf keyword


      if !filter or filter.length is 0
        @searchTip.text "No package result for #{keyword}"
        @searchTip.css 'display', 'block'
      else
        @searchTip.css 'display', 'none'
        filter = filter.slice 0, 10

      console.log "search finished,total:#{filter.length}"

      @packageList.html ""
      return if !keyword

      _.each filter, (pack, index)=>
        cell = new PackageListCell(
          info: pack
          callback: (view, repo)=>
            iPath = @installPathEditor.getText()
            return @choosePath() if !iPath
            view.setInstalling yes
            @installPackage iPath, pack.name, repo, ->
              view.setInstalling no
          )

        @packageList.append cell

    choosePath: ()->
      installPathEditor = @installPathEditor;
      openDirectory().then (destPath) =>
        installPathEditor.setText destPath[0]

    installPackage: (path, name, repo, callback)->
      console.log "Start pull package,Path:#{path}, PackageName:#{name}, gitRepo:#{repo}"
      git({
        path: path
        name: name
        repo: repo
        }).then (destPath)->
          console.log 'package pull finished'
          callback(destPath) if callback


    getTitle: ->
      'Package Center'

    destroy: ->
      @detach()

    toggle: ->
      if @hasParent() then @detach() else @attach()
