require 'shelljs/global'
Q = require 'q'

module.exports = (path, url, options, describe)->

  Q.Promise (resolve, reject, notify) =>
    if not which 'git'
      return reject 'Sorry, this script requires git'

    unless path?
      return reject "请输入path地址"

    unless url?
      return reject "请输入URL地址"

    if describe is ""
      describe = "init"
    console.log "describe:#{describe}"

    cd "#{path}"
    return resolve()
  .then =>
    Q.Promise (resolve, reject, notify) =>
      console.log "options1"
      console.log options
      console.log "pwd:#{pwd()}"
      console.log "git init"
      exec 'git init', options, (code, output) ->
        console.log('Exit code:', code);
        console.log('Program output:', output);
        if code !=0
          reject("Error: Git init failed:#{output}")
        else
          resolve()
  .then =>
    Q.Promise (resolve, reject, notify) =>
      console.log "options2"
      console.log options
      console.log "pwd:#{pwd()}"
      console.log "git add ."
      exec 'git add .', options, (code, output) ->
        console.log('Exit code:', code);
        console.log('Program output:', output);
        if code !=0
          reject("Error: Git add . failed:#{output}")
        else
          resolve()
  .then =>
    Q.Promise (resolve, reject, notify) =>
      console.log "options3"
      console.log options
      console.log "pwd:#{pwd()}"
      console.log 'git commit -m "'+ describe+'"'
      exec 'git commit -m "'+ describe+'"', options, (code, output) ->
        console.log('Exit code:', code);
        console.log('Program output:', output);
        if code !=0
          reject('git commit -m "'+ describe+'"'+"failed: #{output}")
        else
          resolve()
  .then =>
    Q.Promise (resolve, reject, notify) =>
      console.log "options4"
      console.log options
      console.log "pwd:#{pwd()}"
      console.log 'git remote add origin ' + url
      exec 'git remote add origin ' + url, options, (code, output) ->
        console.log('Exit code:', code);
        console.log('Program output:', output);
        if code != 0
          reject("Error: git remote add origin #{url} failed: #{output}")
        else
          resolve()
  # .then =>
  #   Q.Promise (resolve, reject, notify) =>
  #     console.log "options5"
  #     console.log options
  #     console.log "pwd:#{pwd()}"
  #     console.log 'git pull origin master'
  #     exec 'git pull origin master', options, (code, output) ->
  #       console.log('Exit code:', code);
  #       console.log('Program output:', output);
  #       if code !=0
  #         reject("Error: git pull origin master failed: #{output}")
  #       else
  #         resolve()
  .then =>
    Q.Promise (resolve, reject, notify) =>
      console.log "options5"
      console.log options
      console.log "pwd:#{pwd()}"
      console.log 'git push -u origin master'
      exec 'git push -u origin master', options, (code, output) ->
        console.log('Exit code:', code);
        console.log('Program output:', output);
        if code != 0
          reject("Error: git push -u origin master failed: #{output}")
        else
          resolve()
