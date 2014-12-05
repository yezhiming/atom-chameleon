path = require 'path'
fs = require 'fs-plus'
_ = require 'underscore'
{View} = require 'atom'
{EventEmitter} = require 'events'

# Extending classes must implement a `@flow` method.
# class MyWizardView extends WizardView
#   @flow: ->
#     [View1, View2]
# ```
module.exports =
class WizardView extends View
  @content: ->
    @div class: 'butterfly overlay from-top', =>

      @div outlet: 'contentView', class: 'content'

      @div class: 'actions', =>
        @div class: 'pull-left', =>
          @button 'Cancel', click: 'destroy', class: 'inline-block-tight btn'

        @div class: 'pull-right block', =>
          @button 'Previous', click: 'onClickPrevious', outlet: 'previous', class: 'inline-block-tight btn'
          @button 'Next', click: 'onClickNext', outlet: 'next', class: 'inline-block-tight btn btn-primary'

  #@flow is an action sequence, an array of functions
  initialize: ->
    throw new Error('@flow must be specified.') unless @constructor.flow

    #multi inheritance...
    _.extend this, EventEmitter.prototype

    @order = 0 #current flow order
    @result = {} #result collector

  _refresh: (previous_result)->
    # disable 'Previous' Button on the first flow
    @previous.prop 'disabled', @order == 0
    # disable 'Next' Button on the last flow + 1
    @next.prop 'disabled', @order == @constructor.flow.length

    @currentView.destroy() if @currentView

    nextFlow = @constructor.flow[@order]
    View = nextFlow(previous_result)

    @currentView = new View(this)
    if @currentView.attachTo? @currentView.attachTo(@contentView) else @contentView.append(@currentView)

  onClickPrevious: ->
    @order--
    @_refresh()

  onClickNext: ->
    #collect result into @result object
    _.extend @result, @currentView.getResult()

    if @order < @constructor.flow.length - 1
      @order++
      @_refresh()
    else
      @emit 'finish', @result

  attach: ->
    atom.workspaceView.append(this)
    @_refresh()
    return this

  destroy: ->
    @detach()
