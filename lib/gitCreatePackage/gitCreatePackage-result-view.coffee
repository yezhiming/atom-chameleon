{View, EditorView} = require 'atom'

module.exports =
class V extends View

  @content: ->
    @div class: "resultView overlay butterfly from-top", =>
      @div class: 'content', =>
        @h1 outlet: "title"

        @label "HTTPS", class: "labelTitle", outlet: "labelTitle"
        @label "clone URL", class: "labelDeputyTitle", outlet: "labelDeputyTitle"
        @div class: 'form-group', =>
          @div class: 'editorViewResultView', =>
            @subview "filePath", new EditorView
              mini: true
              placeholderText: "Absolute path to file."
          @button class: "btn btnResultView", click: "copyUrlFun", outlet: "copyUrl", =>
            @span class: "glyphicon glyphicon-list-alt"
    
        @div class: 'form-group', =>
          @label "You can clone with"
          @a "HTTPS", style: "padding-left:5px", click: "httpsFun"
          @label ",", style: "padding-left:1px"
          @a "SSH", style: "padding-left:5px", click: "sshFun"
          @label ", or", style: "padding-left:1px"
          @a "Subversion", style: "padding-left:5px", click: "subversionFun"

      @div class: 'actions', =>
        @div class: 'pull-right block', =>
          @button 'Close', click: 'certainFun', outlet: 'certain', class: 'inline-block-tight btn btn-primary'
        
  initialize: ->
    @obj = {}
    
    @selectWhich = "https"

    # disposable = atom.tooltips.add(@copyUrl, {title: 'This is a tooltip'})
      
  setValues: (obj) ->
    @obj = obj

    @title.html("#{obj.package.name} Create success")

    @filePath.setText obj.package.https
    @labelTitle.html "HTTPS"
    @labelDeputyTitle.html "clone URL"

  copyUrlFun: ->
    if @selectWhich is "https"
      atom.clipboard.write @obj.package.https
    else if @selectWhich is "ssh"
      atom.clipboard.write @obj.package.repository_url
    else
      atom.clipboard.write @obj.package.subversion
    
  certainFun: ->
    @remove()

  httpsFun: ->
    @filePath.setText @obj.package.https
    @labelTitle.html "HTTPS"
    @labelDeputyTitle.html "clone URL"
    
    @selectWhich = "https"

  sshFun: ->
    @filePath.setText @obj.package.repository_url
    @labelTitle.html "SSH"
    @labelDeputyTitle.html "clone URL"

    @selectWhich = "ssh"

  subversionFun: ->
    @filePath.setText @obj.package.subversion
    @labelTitle.html "Subversion"
    @labelDeputyTitle.html "checkout URL"

    @selectWhich = "subversion"
