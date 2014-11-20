{EventEmitter} = require 'events'

module.exports =
class SequenceTaskQueue extends EventEmitter

  constructor: ->
    @tasks = []

  add: (task)->
    @tasks.push task

  execute: ()->
    #mark total when execute
    @total = @tasks.length unless @total

    if @tasks.length > 0
      @emit 'progress', (@total - tasks.length) * 100 / @total
      task = @tasks.shift()
      task => @execute(finish)
    else
      @emit 'finish'
