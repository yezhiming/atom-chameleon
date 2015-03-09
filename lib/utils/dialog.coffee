_ = require 'underscore'
Q = require 'q'
dialog = require('remote').require 'dialog'

openDialog = (options) ->

  Q.Promise (resolve, reject, notify) ->
    dialog.showOpenDialog options, (destPath) ->
      if destPath then resolve(destPath) else reject()

openDirectory = (options) ->

  options = _.extend({
    defaultPath: atom.project.rootDirectories[0].path
    properties: ['openDirectory']
    }, options)

  openDialog(options)

openFile = (options) ->

  options = _.extend({
    defaultPath: atom.project.rootDirectories[0].path
    properties: ['openFile']
    }, options)

  openDialog(options)

module.exports.openDialog = openDialog
module.exports.openDirectory = openDirectory
module.exports.openFile = openFile
