{$, View} = require 'atom'

ChooserView = require '../utils/chooser-view'

items = [
  {id: 'ios', name: 'iOS', description: 'iOS Application'}
  {id: 'android', name: 'Android', description: 'Android Application'}
  {id: 'windows', name: 'Windows Mobile', description: 'Windows Application'}
]

module.exports =
class V extends View
  @content: ->
    @div =>
      @subview 'cv', new ChooserView(title: 'Choose a Platform:', items: items)

  attachTo: (parentView) ->
    parentView.append(this)
    @chooser.selectFirstItemView()

  getResult: ->
    platform: @cv.getSelectedItem().id
