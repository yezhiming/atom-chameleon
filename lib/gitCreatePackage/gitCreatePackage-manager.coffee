path = require 'path'
fs = require 'fs-extra'
os = require 'os'
uuid = require 'uuid'

_ = require 'underscore'

Q = require 'q'

module.exports =
class GitCreatePackageManager

  activate: ->
    atom.workspaceView.command "atom-butterfly:gitCreatePackage", => @gitCreatePackage()
    console.log "GitCreatePackageManager activate"


  gitCreatePackage: ->
    GitCreatePackageWizardView = require './gitCreatePackage-wizard-view'
    gitCreatePackageWizardView = new GitCreatePackageWizardView().attach()
    
    gitCreatePackageWizardView.finishPromise()
    .then (options) ->
      selectPath = atom.packages.getActivePackage('tree-view').mainModule.treeView.selectedPath
      if require('fs').statSync(selectPath).isFile()
        tmpfile = path.resolve os.tmpdir(), uuid.v1()
      else
        tmpfile = os.tmpdir()
      
      tmpDir = path.resolve tmpfile, path.basename(selectPath)
      if fs.existsSync tmpDir
        fs.removeSync tmpDir
      fs.copySync selectPath, tmpDir

      _.extend(options, gitPath: tmpDir)
    .then (options)->
      Q.Promise (resolve, reject, notify) ->
        console.log options
        resolve()
      
    .catch (error) ->
      console.trace error.stack
      alert("#{error}")
    .finally ->
      console.log "finally"
