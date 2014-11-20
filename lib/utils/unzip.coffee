path = require 'path'
fs = require 'fs-plus'
mkdirp = require 'mkdirp'
AdmZip = require 'adm-zip'
SequenceTaskQueue = require './sequence-task-queue'

module.exports =
  #using adm-zip module
  unzip: (zipFile, destPath)->

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

    return queue
