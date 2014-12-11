WizardView = require '../utils/wizard-view'

#
# 1. ios or android
# 2. 输入构建信息
# 3. 确定弹出构建状态页
#
module.exports =
class CreateProjectWizardView extends WizardView

  @flow: [

    -> require './platform-chooser-view'

    (previous) ->
      if previous.platform == 'ios'
        require './ios-build-view'
      else if previous.platform == 'android'
        require './android-build-view'
      else
        null
  ]
