fs = require 'fs'
Q = require 'q'
request = require 'request'

module.exports = (fileURL, targetFile) ->

  Q.Promise (resolve, reject, notify) ->

    console.log "download #{fileURL} to: #{targetFile}"
    fileStream = fs.createWriteStream(targetFile)
    #TODO: remove this event listening
    fileStream.on 'open', ->
      console.log "file stream open, success: #{fs.existsSync(targetFile)}"
    fileStream.on 'finish', ->
      console.log "file stream finish."
      resolve()

    request
      .get(fileURL)
      .on 'response', (response) ->
        totalLength = response.headers['content-length']
        console.log "can not get content-length" unless totalLength

        received = 0
        response.on 'data', (data) ->
          received += data.length
          #emit progress event
          if totalLength
            notify 'progress': received * 100 / totalLength
          else
            notify 'indeterminate': received
      .on 'error', (err) ->
        reject(err)
      .pipe(fileStream)
