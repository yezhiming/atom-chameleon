{WorkspaceView} = require 'atom'
fs = require 'fs'

{downloadPromise} = require '../lib/utils/download'

describe "utils.download", ->
  packagePath = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('atom-butterfly')

    waitsForPromise ->
      activationPromise

  it "can download", ->

    packagePath = atom.packages.getActivePackage('atom-butterfly').path
    console.log "packagePath: #{packagePath}"
    expect(packagePath).not.toBe(null)

    butterflyURL = "https://github.com/yezhiming/butterfly/archive/master.zip"

    targetZipFile = "#{packagePath}/spec/download.zip"

    # waitsForPromise ->
    downloadPromise butterflyURL, targetZipFile
    .then ->
      console.log "done"
    , (err)->
      console.log "err"
    , (progress)->
      console.log "progress"


    # exists = fs.existsSync(targetZipFile)

    # expect(exists).toBe true
