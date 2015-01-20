{$, View} = require 'atom'

ChooserView = require '../utils/chooser-view'

items = [
  {
    id:     'ios'
    name:   'iOS'
    image:  'atom://atom-chameleon/images/apple.png'
    description: 'iOS Application'
  }
  {
    id:     'android'
    name:   'Android'
    image:  'atom://atom-chameleon/images/android.png'
    description: 'Android Application'
  }
  {
    id:     'ios-fastbuild'
    name:   'iOS Fast Build'
    image:  'atom://atom-chameleon/images/apple.png'
    description: 'iOS Application fast build'
  }
  {
    id:     'android-fastbuild'
    name:   'Android Fast Build'
    image:  'atom://atom-chameleon/images/android.png'
    description: 'Android Application fast build'
  }
]

module.exports =
class V extends View
  @content: ->
    @div =>
      @subview 'chooser', new ChooserView(title: 'Choose a Platform:', items: items)

  attachTo: (parentView) ->
    parentView.append(this)
    @chooser.selectFirstItemView()

  onNext: (wizard) ->
    wizard.mergeOptions {platform: @chooser.getSelectedItem().id}
    wizard.nextStep()
