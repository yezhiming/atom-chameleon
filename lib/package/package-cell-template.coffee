{View} = require 'atom'
{EventEmitter} = require 'events'
_ = require 'underscore'

module.exports =
  class PackageCell extends View

    @state: 'normal'

    @content: ->
      @li class: 'two-line package-list-item', =>
        @div class: 'package-icon', =>
          @img src: 'atom://atom-chameleon/images/icon.png'
        @div class: 'info', =>
          @div outlet: 'baseInfo', =>
            @div outlet: 'name'
            @span outlet: 'identifier', class: 'identifier'
            @span outlet: 'version', class: 'version'
            @div outlet: 'description', class: 'description'
          # @div outlet: 'state', class: 'block', style: 'display:none;' ,=>
          #   @progress class: 'inline-block'
          #   @span class: 'inline-block', 'Uploading...'

        @button outlet: 'uploadButton', click: 'onPublishClick', class: 'btn btn-success inline-block-tight btn-publish', 'Publish'

    initialize: (@module)->

      _.extend this, EventEmitter.prototype

      info = @module.package
      @name.text info.name
      @identifier.text(info.identifier)
      @version.text(info.version)
      @description.text(info.description)

    onPublishClick: ->
      return if @state is 'upload'
      @emit 'upload', this, @module

    getModule:->
      return @module

    changeState: (state) ->
      if state is 'upload'
        @uploadButton.text "Uploading"
        @state = 'upload'
      if state is 'normal'
        @uploadButton.text "Publish"
        @state = 'normal'
      # if state == 'upload'
      #   @baseInfo.css 'display', 'none'
      #   @state.css 'display', 'block'
      # else
      #   @baseInfo.css 'display', 'block'
      #   @state.css 'display', 'none'
