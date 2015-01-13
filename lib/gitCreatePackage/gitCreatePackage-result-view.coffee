{View, EditorView} = require 'atom'

module.exports =
class V extends View

  @content: ->
    @div class: "resultView overlay butterfly from-top", =>
      @div class: 'content', =>
        @h1 outlet: "title"

        @label "click this url to open on brower:"
        @div class: "form-group", =>
          @a outlet:'urlPath', class: 'resultViewUrlPath'

      @div class: 'actions', =>

        @div class: 'pull-right block', =>
          @button 'Copy Url', click: 'copyUrlFun', class: 'inline-block-tight btn btn-primary'
          @button 'Close', click: 'certainFun', outlet: 'certain', class: 'inline-block-tight btn'
        
  setValues: (obj) ->
    @title.html("#{obj.package.name}创建成功")
    @urlPath.html("#{obj.package.repository_url}")
    @urlPath.attr "href", obj.package.repository_url

  copyUrlFun: ->
    atom.clipboard.write @urlPath.html()
    @certainFun()
    
  certainFun: ->
    @remove()
