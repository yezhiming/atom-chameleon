spawn = require('child_process').spawn
Q = require 'q'

module.exports = (pathDir,source,decs,cb)->
  
  Q.Promise (resolve, reject, notify) ->
    # zip -r cfads.zip chameleon.app
    console.log('Starting directory: ' + process.cwd());
    # try
    process.chdir("#{pathDir}")
    console.log('New directory: ' + process.cwd());
  
  
    args = ["-r",decs,source];
    comeontom = spawn("zip", args, maxBuffer: 1024*1024*10)

    comeontom.stdout.on('data',(data)->
      console.log "stdout:"+data
    )
    
    comeontom.stderr.on('data',(data)->
      # errorcb && errorcb(data)
      console.log data
    )
    
    comeontom.on 'close',(status)->
      zip_path = "#{pathDir}/#{decs}"

      if status is 0
        resolve(zip_path)
      else
        reject(status)
