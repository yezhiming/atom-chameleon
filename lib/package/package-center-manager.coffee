fs = require 'fs-extra'
path = require 'path'
Q = require 'q'

module.exports =
class PackageManager

  activate: ->
    # @toggle()
    atom.workspaceView.command "atom-butterfly:installChameleonPackage", => @createCenter()
    
  createCenter: ->
    selectPath = atom.packages.getActivePackage('tree-view').mainModule.treeView.selectedPath
    
    PackageCenter = require './package-center'
    packageCenter = new PackageCenter path: selectPath
    packageCenter.toggle()
