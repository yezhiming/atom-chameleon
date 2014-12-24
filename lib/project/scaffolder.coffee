#
# 如果使用shell，则需要每个操作系统各写脚本
# 使用coffee来做跨平台脚本
# 用同步API简化代码，用子进程方式执行
#
path = require 'path'
fs = require 'fs-extra'
Q = require 'q'
{exec} = require 'child_process'
{getResourcePath} = require '../utils/utils'

remove = Q.denodeify fs.remove
fscopy = Q.denodeify fs.copy

execute = (command) ->

  Q.Promise (resolve, reject, notify) ->
    options = null
    if atom.config.get('atom-butterfly.gitCloneEnvironmentPath')
      options =
        env: path:atom.config.get('atom-butterfly.gitCloneEnvironmentPath')

    cp = exec command, options, (error) ->
      if error then reject(error) else resolve()


    cp.stdout.on 'data', (data) -> notify out: data.toString()
    cp.stderr.on 'data', (data) -> notify out: data.toString()

#
# options:
# path: project store path
# name: project name
# ratchet:
# bootstrap:
#
module.exports = (options) ->

  destPath = path.resolve options.path, options.name
  scaffoldPath = getResourcePath 'scaffold'

  execute "git clone #{options.repo} #{destPath}"
  .then -> remove "#{destPath}/.git"
  .then -> fscopy "#{scaffoldPath}/ratchet", "#{destPath}/ratchet" if options.ratchet
  .then -> fscopy "#{scaffoldPath}/bootstrap", "#{destPath}/bootstrap" if options.bootstrap
  # .then -> #TODO: do replacement
  .then -> destPath
