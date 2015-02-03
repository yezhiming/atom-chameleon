Q = require 'q'
 # check network
 # @param  {[type]} netType     需要监测的网络类型。注：只检测http 和 https 类型
 # @param  {[type]} netAddress  需要检测网络的全地址。eg：https://github.com/ 或者：http://www.baidu.com
module.exports = (netType, netAddress)->
  Q.Promise (resolve, reject, notify) ->

    if netType is "http"
      http = require "http"
      http.get netAddress,(res) ->
        if 200 is res.statusCode
          resolve()
      .on "error", (e) ->
        reject "Please check your network."

    else if netType is "https"
      https = require 'https'
      https.get netAddress, (res) ->
        if 200 is res.statusCode
          resolve()
      .on 'error', (e) ->
        reject "Please check your network."

    else
      reject "this network type:#{netType} does not exist."
