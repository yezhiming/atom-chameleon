WizardView = require '../utils/wizard-view'

module.exports =
class CreateProjectWizardView extends WizardView

  @flow: [

    -> require './build-approach-view'

    (previous) ->
      console.log "#{previous.approach}, #{previous.approach == 'puzzle'}"
      if previous.approach == 'puzzle'
        require './build-with-puzzle-view'
      else
        require './build-with-local-view'
  ]
