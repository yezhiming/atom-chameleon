WizardView = require '../utils/wizard-view'

#
# 1. 构建方式
# 2. ios or android
# 3. 输入构建信息
# 4. 确定弹出构建状态页
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
