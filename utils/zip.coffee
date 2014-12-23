spawn = require('child_process').spawn
Q = require 'q'
fs = require 'fs'
fsplus = require 'fs-plus'

uuid = require 'uuid'

{exec} = require 'child_process'

module.exports = (pathDir,cb)->

  Q.Promise (resolve, reject, notify) ->

    decs = fsplus.absolute "~/.atom/atom-butterfly"

    zipFile = "#{uuid.v1()}.zip"
    
    unless fsplus.isDirectorySync(decs)
      console.log "新建文件夹：#{decs}"
      fs.mkdirSync decs

    zipFile = "#{decs}/#{zipFile}"

  # exec
    commands = "zip -r #{zipFile} ./"

    options =
      cwd:"#{pathDir}"
      maxBuffer:1024*1024*10
    foreverossZip = exec commands, options, (error,stdout,stderr)=>
      if error isnt null
        reject(error)
      # zip_path = "#{pathDir}/#{decs}"
      resolve(zipFile)

  # spawn
    # args = ["-r",decs,source];
    # foreverossZip = spawn("zip", args,{cwd:"#{pathDir}"})
    #
    # foreverossZip.stdout.on('data',(data)->
    #   console.log "stdout:"+data
    # )
    #
    # foreverossZip.stderr.on('data',(data)->
    #   # errorcb && errorcb(data)
    #   console.log data
    # )
    #
    # foreverossZip.on 'close',(status)->
    #   zip_path = "#{pathDir}/#{decs}"
    #
    #   if status is 0
    #     resolve(zip_path)
    #   else
    #     reject(status)
