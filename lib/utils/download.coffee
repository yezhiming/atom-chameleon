{EventEmitter} = require 'events'
fs = require 'fs-plus'

request = require 'request'

module.exports =

  download: (fileURL, targetFile) ->

    progress = new EventEmitter()

    file = fs.createWriteStream(targetFile)
    file.on 'finish', ->
      progress.emit 'finish'

    request
      .get(fileURL)
      .on 'response', (response) =>
        totalLength = response.headers['content-length']
        if totalLength
          received = 0
          response.on 'data', (data) =>
            received += data.length
            #emit progress event
            progress.emit 'progress', received * 100 / totalLength
        else
          console.log "can not get content-length"
      .pipe(file)

    return progress
