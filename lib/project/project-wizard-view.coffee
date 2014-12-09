WizardView = require '../utils/wizard-view'

module.exports =
class ProjectWizardView extends WizardView

  @flow: [
    -> require './project-template-chooser-view'
    -> require './project-info-view'
  ]

  initialize: ->
    super
