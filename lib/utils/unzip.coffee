path = require 'path'
fs = require 'fs-plus'
mkdirp = require 'mkdirp'
AdmZip = require 'adm-zip'
DecompressZip = require 'decompress-zip'
Q = require 'q'

module.exports =

  #TODO: not work with strip=1
  decompressPromise: (zipFile, destPath)->

    return Q.Promise (resolve, reject, notify) ->
      unzipper = new DecompressZip(zipFile)
      unzipper.on 'error', (err)->
        reject(err)
      unzipper.on 'extract', ->
        resolve()
      unzipper.extract path: destPath, strip: 1

  unzipPromise: (zipFile, destPath)->
    #get zip entries
    entries = new AdmZip(zipFile).getEntries()
    #get the root (the first one)
    rootPath = entries.shift().entryName

    return entries.reduce (soFar, zipEntry) ->

      pathWithoutRoot = zipEntry.entryName.substr(rootPath.length)
      finalPath = path.resolve(destPath, 'butterfly', pathWithoutRoot)

      nextPromise = ->
        if zipEntry.isDirectory
          Q.nfcall mkdirp finalPath
        else
          Q.Promise (resolve, reject, notify) ->
            zipEntry.getDataAsync (data)->
              fs.writeFile finalPath, data, ->
                resolve()

      soFar.then(nextPromise())

    , Q()

  #using adm-zip module
  unzip: (zipFile, destPath)->

    SequenceTaskQueue = require './sequence-task-queue'

    queue = new SequenceTaskQueue()
    #get zip entries
    entries = new AdmZip(zipFile).getEntries()
    #get the root (the first one)
    rootPath = entries.shift().entryName

    entries.forEach (zipEntry)->
      pathWithoutRoot = zipEntry.entryName.substr(rootPath.length)
      finalPath = path.resolve(destPath, 'butterfly', pathWithoutRoot)

      if zipEntry.isDirectory
        queue.add (next)->
          mkdirp finalPath, ->
            next()
      else
        queue.add (next)->
          zipEntry.getDataAsync (data)->
            fs.writeFile finalPath, data, ->
              next()

    console.log "#{queue.tasks.length} entries in zip file."

    return queue.execute()
