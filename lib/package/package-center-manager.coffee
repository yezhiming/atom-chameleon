fs = require 'fs'
path = require 'path'
Q = require 'q'

module.exports =
class PackageManager

  activate: ->
    # @toggle()
    atom.workspaceView.command "atom-butterfly:installChameleonPackage", => @createCenter()
    
  createCenter: ->
    selectPath = atom.packages.getActivePackage('tree-view').mainModule.treeView.selectedPath
    
    if require('fs').statSync(selectPath).isFile()
      selectPath = selectPath.split path.sep
      selectPath.pop()
      selectPath = selectPath.toString()
      selectPath = selectPath.replace /,/g, path.sep
      
    PackageCenter = require './package-center'
    packageCenter = new PackageCenter path: selectPath
    packageCenter.toggle()
