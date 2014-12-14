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
    comeontom = spawn("zip",args)
    
    comeontom.on 'close',(status)->
      # if status is 0
      #   console.log "zip success"
      # else
      #   console.log "zip failed"
      zip_path = "#{pathDir}/#{decs}"
      # cb(status,zip_path)

      if status is 0
        resolve(zip_path)
      else
        reject(status)
