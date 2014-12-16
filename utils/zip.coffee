spawn = require('child_process').spawn
Q = require 'q'

{exec} = require 'child_process'

module.exports = (pathDir,source,decs,cb)->
  
  Q.Promise (resolve, reject, notify) ->
  
  # exec
    commands = "zip -r #{decs} #{source}"

    options =
      cwd:"#{pathDir}"
      maxBuffer:1024*1024*10
    foreverossZip = exec commands, options, (error,stdout,stderr)=>
      if error isnt null
        reject(error)
      zip_path = "#{pathDir}/#{decs}"
      resolve(zip_path)

    foreverossZip.stdout.on 'data', (data) ->
      console.log data
    foreverossZip.stderr.on 'data', (data) ->
      console.log data
  
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
