#
# 如果使用shell，则需要每个操作系统各写脚本
# 使用coffee来做跨平台脚本
# 用同步API简化代码，用子进程方式执行
#
Q = require 'q'
{exec} = require 'child_process'

execute = (command) -> Q.nfcall exec, command

#
# options:
# path: project store path
# name: project name
# ratchet:
# bootstrap:
#
module.exports = (options) ->

  
