fs = require 'fs'
fse = require 'fs-extra'
path = require 'path'
request = require 'request'
Decompress = require 'decompress'

module.exports = (router, buildPath) ->

  router.use '/fs/:command', (req, res, next) ->
    cmd = req.param('command')
    console.log "commad= #{cmd}"
    rePath = req.query.path
    req.rpath = path.join buildPath, rePath if rePath

    if cmd is 'download'
      next()
    else if cmd is 'stat' or cmd is 'readFile'
      unless rePath
        res.status(400).send "please add querystring 'path'"
      else
        next()
    else
      console.log "cmd: #{cmd}"
      # 代理其余的函数
      fs[cmd] req.rpath, -> res.status(200).json(arguments)

  # /fs/stat?path=/a/b/c
  router.get '/fs/stat', (req, res, next) ->
    fs.stat req.rpath, (err, stats) ->
      res.status(200).json
        err: err
        stats: stats
        isDirectory: stats.isDirectory?()


  router.get '/fs/readFile', (req, res, next) ->
    fs.readFile req.rpath, encoding: 'utf-8', (err, data) ->
      res.status(200).json
        err: err
        data: data

  # http://115.28.1.119:18860/mam/api/mam/cilent/files/bundle?appKey=xxx
  # /fs/download?path=/xxx/xxx&bundle=xxx&appkey=xxx&identifier=/abc/zz
  router.get '/fs/download/:bundle', (req, res, next) ->
    console.log "/fs/download"
    bundle = req.param('bundle')
    appkey = req.param('appkey')
    identifier = req.query.identifier

    url = "http://115.28.1.119:18860/mam/api/mam/clients/files/#{bundle}?appKey=#{appkey}"

    savePath = path.join buildPath, identifier
    zipPath = "#{savePath}.zip"

    channel = request(url).pipe(fs.createWriteStream(zipPath))
    channel.on "finish", ->
      console.log "finish"
      decompress = new Decompress(mode: "755").src(zipPath).dest(savePath).use(Decompress.zip(strip: 0))
      decompress.run (err) ->
        next err  if err
        console.log "Archive extracted successfully!"
        res.status(200).end "ok"
        # 删除zip
        fs.unlink zipPath, (err) ->
          console.log if err then err else '删除成功'


  # as same as rm -rf /folder
  router.get '/fs/rmdir', (req, res, next) ->

    fse.remove req.rpath, (err) ->
      if err
        res.status(500).json
          err: err
          result: false
      else
        res.status(200).json
          err: null
          result: true
