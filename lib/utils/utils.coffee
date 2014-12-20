path = require 'path'
_ = require 'underscore'

module.exports =
  getResourcePath: ->
    packagePath = atom.packages.getActivePackage('atom-butterfly').path
    path.resolve.apply _, _.union([packagePath], arguments)
