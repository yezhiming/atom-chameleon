{WorkspaceView} = require 'atom'
AtomButterfly = require '../lib/atom-chameleon'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "AtomButterfly", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('atom-chameleon')

  describe "when the atom-chameleon:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.atom-chameleon')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch atom.workspaceView.element, 'atom-chameleon:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.atom-chameleon')).toExist()
        atom.commands.dispatch atom.workspaceView.element, 'atom-chameleon:toggle'
        expect(atom.workspaceView.find('.atom-chameleon')).not.toExist()
