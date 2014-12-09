path = require 'path'
fs = require 'fs-extra'
{allowUnsafeNewFunction} = require('loophole')
Decompress = allowUnsafeNewFunction -> require 'decompress'
Q = require 'q'

module.exports = (zipFile, destPath)->

  Q.Promise (resolve, reject, notify) ->

    console.log "unzip #{zipFile} to #{destPath}"

    decompress = new Decompress({ mode: '777' })
    .src(zipFile)
    .dest(destPath)
    .use(Decompress.zip({ strip: 1 }))

    decompress.run (err)->
      if err
        reject(err)
      else
        resolve()
