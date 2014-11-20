{EventEmitter} = require 'events'

path = require 'path'
fs = require 'fs-plus'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'

Downloader = require './utils/download'
Unzip = require './utils/unzip'

butterflyURL = "https://github.com/yezhiming/butterfly/archive/master.zip"

module.exports =
  createProject: (destPath)->

    events = new EventEmitter()

    mkdirp destPath, =>
      @installFramework destPath
      .on 'message', (message) -> events.emit 'message', message
      .on 'progress', (progress) -> events.emit 'progress', progress
      .on 'finish', ->
        #TODO: create main package(module)
        events.emit 'finish'

    return events

  installFramework: (installToPath = atom.project.path)->

    events = new EventEmitter()

    targetFolder = path.resolve(installToPath, 'butterfly')
    targetZipFile = path.resolve(installToPath, 'butterfly.zip')

    rimraf targetZipFile, =>

      events.emit 'message', "Download butterfly.js..."
      Downloader.download(butterflyURL, targetZipFile)
      .on 'progress', (progress) ->
        events.emit 'progress', progress
      .on 'indeterminate', (received) ->
        events.emit 'message', "Download butterfly.js...(#{received / 1000}k)"
      .on 'finish', ->
        rimraf targetFolder, ->

          events.emit 'message', "Unzip..."
          Unzip.unzip(targetZipFile, installToPath).on 'finish', ->

            fs.unlink targetZipFile, ->
              events.emit 'message', "Finish."
              events.emit 'finish'

    return events
