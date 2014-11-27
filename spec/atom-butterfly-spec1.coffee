{WorkspaceView} = require 'atom'
AtomButterfly = require '../lib/atom-butterfly'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "AtomButterfly", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('atom-butterfly')

  describe "when the atom-butterfly:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.atom-butterfly')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch atom.workspaceView.element, 'atom-butterfly:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.atom-butterfly')).toExist()
        atom.commands.dispatch atom.workspaceView.element, 'atom-butterfly:toggle'
        expect(atom.workspaceView.find('.atom-butterfly')).not.toExist()
