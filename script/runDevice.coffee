{exec} = require 'child_process'

module.exports = (pathAPP,cb)->

  commands = "ios-deploy --bundle #{pathAPP}"
  exec commands, (error, stdout, stderr) ->
    console.log('stdout: ' + stdout);
    console.log('stderr: ' + stderr);
    if error
      console.log('exec error: ' + error);

  

  
  
