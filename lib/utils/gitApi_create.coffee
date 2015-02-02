require 'shelljs/global'
# 修改shelljs内部的common.config，只是为了兼容window platform，不然windows会报BDADF, bad descriptor
{config} = require 'shelljs'
config.silent = true;

Q = require 'q'
{EOL, platform} = require 'os'

module.exports = (path, url, options, describe, home, username) ->
  console.log "path: #{path}, url: #{url}, home: #{home}, username: #{username}"
  console.log options

  Q.Promise (resolve, reject, notify) =>
    env["path"] = options.env.path if options.env # 非永久设置环境变量
    if not which 'git'
      return reject new Error 'Sorry, please set git env on chameleon-atom settings'

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
  #
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
      # ssh-add 清除客户端公钥缓存
      console.log "options5"
      console.log "pwd:#{pwd()}"
      console.log 'git push -u origin master'
      # 判断平台有效性windowk跨越度很大，fuck window
      if platform() is 'win32'
        exec 'ssh-agent -s', options, (code, output) ->
          console.log('Program output:', output);
          try
            arr = output.toString().split "\n" # 3
            arr0 = arr[0].split(';')[0].split('=')
            arr1 = arr[1].split(';')[0].split('=')
            # 设置临时环境变量
            env[arr0[0]] = arr0[1]
            env[arr1[0]] = arr1[1]
          catch error
            error.code = 500
            reject error
          exec "ssh-add #{home}/.ssh/id_rsa_#{username} && git push -u origin master#{EOL}#{EOL}#{EOL}#{EOL}", options, (code, output) ->
            console.log('Exit code:', code);
            console.log('Program output:', output);
            if code != 0
              e = new Error "Error: git push -u origin master failed: #{output}"
              e.code = code
              reject e
            else
              resolve()
      else
        exec "eval \"$(ssh-agent -s)\" && ssh-add #{home}/.ssh/id_rsa_#{username} && git push -u origin master#{EOL}#{EOL}#{EOL}#{EOL}", options, (code, output) ->
          console.log('Exit code:', code);
          console.log('Program output:', output);
          if code != 0
            e = new Error "Error: git push -u origin master failed: #{output}"
            e.code = code
            reject e
          else
            resolve()
