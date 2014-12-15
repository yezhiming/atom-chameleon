_ = require 'underscore'
{View} = require 'atom'
{EventEmitter} = require 'events'

Q = require 'q'

# Extending classes must implement a `@flow` method.
# class MyWizardView extends WizardView
#   @flow: ->
#     [View1, View2]
# ```
module.exports =
class WizardView extends View
  @content: ->
    @div class: 'butterfly overlay from-top', =>

      # content view of each step, insert here
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

    # mixin
    _.extend this, EventEmitter.prototype

    @order = 0 #current flow order
    @result = {} #result collector

  _refresh: (previous_result)->
    # disable 'Previous' Button on the first flow
    @previous.prop 'disabled', @order == 0
    # disable 'Next' Button on the last flow + 1
    @next.prop 'disabled', @order == @constructor.flow.length

    @_destroyCurrentStep()

    nextFlow = @constructor.flow[@order]
    View = nextFlow(previous_result)

    @currentView = new View(this)
    if @currentView.attachTo then @currentView.attachTo(@contentView) else @contentView.append(@currentView)

  _destroyCurrentStep: ->
    #invoke destroy if provided, invoke remove othervise
    @currentView.destroy?() or @currentView.remove?() if @currentView

  onClickPrevious: ->
    @order--
    @_refresh()

  onClickNext: ->
    #collect result into @result object
    _.extend @result, @currentView.getResult() if @currentView.getResult

    if @order < @constructor.flow.length - 1
      @order++
      @_refresh(@currentView.getResult())
    else
      @emit 'finish', @result

  attach: ->
    atom.workspaceView.append(this)
    @_refresh()
    return this

  destroy: ->

    @_destroyCurrentStep()

    @remove()

  enableNext: ->
    @next.prop 'disabled', false

  disableNext: ->
    @next.prop 'disabled', true

  finishPromise: ->
    Q.Promise (resolve, reject, notify) =>
      @on 'finish', (result) -> resolve(result)
