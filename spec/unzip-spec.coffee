{WorkspaceView} = require 'atom'
unzip = require '../lib/utils/unzip'
path = require 'path'
fs = require 'fs-plus'
rimraf = require 'rimraf'

describe "utils.unzip", ->
  testZipPackagePath = null
  targetFolderPath = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('atom-butterfly')

    waitsForPromise ->
      activationPromise.then ->
        packagePath = atom.packages.getActivePackage('atom-butterfly').path
        expect(packagePath).not.toBe(null)

        testZipPackagePath = "#{packagePath}/sandbox/archive.zip"
        targetFolderPath = "#{packagePath}/sandbox"

  afterEach ->
    console.log "after: remove #{targetFolderPath}/butterfly"
    rimraf.sync "#{targetFolderPath}/butterfly"

  # it "can decompress", ->
  #
  #   rimraf.sync targetFolderPath
  #
  #   waitsForPromise ->
  #     unzip.decompressPromise(testZipPackagePath, targetFolderPath)

  it "can unzip", ->

    waitsForPromise ->
      unzip.unzipPromise(testZipPackagePath, targetFolderPath)
