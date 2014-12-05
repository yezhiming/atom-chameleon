WizardView = require '../utils/wizard-view'

SelectProjectTemplateView = require './select-project-template-view'
InputProjectInfoView = require './input-project-info-view'

module.exports =
class CreateProjectWizardView extends WizardView

  @flow: [
    -> SelectProjectTemplateView
    -> InputProjectInfoView
  ]
