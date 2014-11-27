{View} = require 'atom'

module.exports =
class CreateProjectView extends View
  @content: ->
    @div =>
      @h1 'Choose options for your new project:'
      @div class: "form-group", =>
        @label 'Project Name:'
        @input outlet: 'projectName', class: 'form-control'

      @div class: "checkbox", =>
        @label =>
          @input type: "checkbox", id: 'withRatchet'
          @text('With Ratchet')

      @div class: "checkbox", =>
        @label =>
          @input type: "checkbox", id: 'withBootstrap'
          @text('With Bootstrap')

  attachTo: (parentView)->
    parentView.append(this)

  destroy: ->
    @detach()

  getResult: ->
    name: @projectName.val()
    bootstrap: @find('#withBootstrap').is(":checked")
    ratchet: @find('#withRatchet').is(":checked")
