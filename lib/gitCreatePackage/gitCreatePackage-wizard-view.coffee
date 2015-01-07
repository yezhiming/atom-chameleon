WizardView = require '../utils/wizard-view'

module.exports =
class V extends WizardView

  @flow: [
    -> require './gitCreatePackage-info-view'
  ]
