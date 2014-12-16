Q = require 'q'
request = require 'request'

request_get = Q.denodeify request.get
request_delete = Q.denodeify request.delete

class PuzzleClient

  initialize: ->
    PACKAGE = 'atom-butterfly'
    # http url
    @server = atom.config.get("#{PACKAGE}.puzzleServerAddress")
    # https url
    @serverSecured = atom.config.get("#{PACKAGE}.puzzleServerAddressSecured")

    @access_token = atom.config.get("#{PACKAGE}.puzzleAccessToken")

  getTask: (task_id) ->
    request_get
      url: "#{@server}/api/tasks/#{task_id}"
      rejectUnauthorized: false
    .then (result) -> JSON.parse result[1]

  deleteTask: (task_id) ->
    request_delete
      url: "#{@server}/api/tasks/#{task_id}"
      rejectUnauthorized: false
    .then (result) -> JSON.parse result[1]

module.exports = new PuzzleClient()