path = require 'path'
_ = require 'underscore'

module.exports =
  getResourcePath: ->
    packagePath = atom.packages.getActivePackage('atom-chameleon').path
    path.resolve.apply _, _.union([packagePath], arguments)

  # 将传递过来的 str 进行判断是否符合文件命名，如果不符合，将不符合的字符改为"-", 并进行去重
  checkProjectName: (str)->
    regEx = /[\`\~\!\@\#\$\%\^\&\*\(\)\+\=\|\{\}\'\:\;\,\·\\\[\]\<\>\/\?\~\！\@\#\￥\%\…\…\&\*\（\）\—\—\+\|\{\}\【\】\‘\；\：\”\“\’\。\，\、\？]/g
    strcheck = str.replace(/[^\x00-\xff]/g,"-")
    strcheck = strcheck.replace(regEx,"-")
    strcheck = strcheck.replace(/-+/g, '-')
    # 特殊处理
    strcheck = '...' if strcheck is '.' or strcheck is '..'
    return strcheck
