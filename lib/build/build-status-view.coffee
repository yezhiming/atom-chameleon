#
# 显示任务状态，点击构建时弹出，作为一个tab
#
{$, View} = require 'atom'

module.exports =
class V extends View
  @content: ->
    @div class: 'build-status-view', =>
      
