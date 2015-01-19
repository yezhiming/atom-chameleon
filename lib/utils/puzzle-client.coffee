Q = require 'q'
request = require 'request'

request_get = Q.denodeify request.get
request_delete = Q.denodeify request.del

class PuzzleClient

  constructor: ->
    PACKAGE = 'atom-chameleon'
    # http url
    @server = atom.config.get("#{PACKAGE}.puzzleServerAddress")
    # https url
    @serverSecured = atom.config.get("#{PACKAGE}.puzzleServerAddressSecured")

    @access_token = atom.config.get("#{PACKAGE}.puzzleAccessToken")

  getTasks: ->
    request_get
      url: "#{@server}/api/tasks?access_token=#{@access_token}"
      rejectUnauthorized: false
    .then (result) ->
      JSON.parse result[1]

  getTask: (task_id) ->
    request_get
      url: "#{@server}/api/tasks/#{task_id}?access_token=#{@access_token}"
      rejectUnauthorized: false
    .then (result) -> JSON.parse result[1]

  deleteTask: (task_id) ->
    console.log "#{@server}/api/tasks/#{task_id}?access_token=#{@access_token}"
    request_delete
      url: "#{@server}/api/tasks/#{task_id}?access_token=#{@access_token}"
      rejectUnauthorized: false
    .then (result) -> JSON.parse result[1]

module.exports = new PuzzleClient()
