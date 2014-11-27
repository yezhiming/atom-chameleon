{EventEmitter} = require 'events'
fs = require 'fs-plus'

request = require 'request'
Q = require 'q'

download = (fileURL, targetFile) ->

  progress = new EventEmitter()

  console.log "download to: #{targetFile}"
  fileStream = fs.createWriteStream(targetFile)
  fileStream.on 'open', -> console.log "download file open: #{fs.existsSync(targetFile)}"
  fileStream.on 'finish', -> progress.emit 'finish'

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
          progress.emit 'progress', received * 100 / totalLength
        else
          progress.emit 'indeterminate', received
    .on 'error', (err) ->
      progress.emit 'error', err
    .pipe(fileStream)

  return progress

downloadPromise = (fileURL, targetFile) ->

  return Q.Promise (resolve, reject, notify) ->

    console.log "download to: #{targetFile}"
    fileStream = fs.createWriteStream(targetFile)
    fileStream.on 'open', ->
      console.log "file stream open: #{fs.existsSync(targetFile)}"
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

module.exports.download = download
module.exports.downloadPromise = downloadPromise
