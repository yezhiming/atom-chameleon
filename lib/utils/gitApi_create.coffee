require 'shelljs/global'
# 修改shelljs内部的common.config，只是为了兼容window platform，不然windows会报BDADF, bad descriptor
{config} = require 'shelljs'
config.silent = true;

Q = require 'q'
{EOL} = require 'os'

module.exports = (path, url, options, describe, home, username) ->
  console.log "path: #{path}, url: #{url}, home: #{home}, username: #{username}"
  console.log options

  Q.Promise (resolve, reject, notify) =>
    if not which 'git'
      return reject new Error 'Sorry, this script requires git'

    unless path?
      return reject new Error "请输入path地址"

    unless url?
      return reject new Error "请输入URL地址"

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
        if code != 0
          e = new Error "Error: Git init failed:#{output}"
          e.code = code
          reject e
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
        if code != 0
          e = new Error "Error: Git add . failed:#{output}"
          e.code = code
          reject e
        else
          resolve()
  .then =>
    Q.Promise (resolve, reject, notify) =>
      console.log "options3"
      console.log options
      console.log "pwd:#{pwd()}"
      console.log 'git commit -m "'+ describe+'"'
      exec 'git commit -m "' + describe + '"', options, (code, output) ->
        console.log('Exit code:', code);
        console.log('Program output:', output);
        if code != 0
          e = new Error 'git commit -m "' + describe + '"' + "failed: #{output}"
          e.code = code
          reject e
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
          e = new Error "Error: git remote add origin #{url} failed: #{output}"
          e.code = code
          reject e
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
      # ssh-add 清除客户端公钥缓存
      exec "eval \"$(ssh-agent -s)\" && ssh-add #{home}/.ssh/id_rsa_#{username} && git push -u origin master#{EOL}#{EOL}#{EOL}#{EOL}", options, (code, output) ->
        console.log('Exit code:', code);
        console.log('Program output:', output);
        if code != 0
          e = new Error "Error: git push -u origin master failed: #{output}"
          e.code = code
          reject e
        else
          resolve()
