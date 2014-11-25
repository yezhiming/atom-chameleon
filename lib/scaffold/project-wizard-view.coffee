WizardView = require './wizard-view'

SelectProjectTypeView = require './select-project-type-view'
InputProjectInfoView = require './input-project-info-view'

module.exports =
class CreateProjectWizardView extends WizardView

  @flow: [
    SelectProjectTypeView
    InputProjectInfoView
  ]
