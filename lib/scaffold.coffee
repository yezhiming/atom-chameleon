path = require 'path'
fs = require 'fs-plus'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'

module.exports =
  createProject: (destPath, onFinish)->
    mkdirp destPath, =>
      @installFramework destPath, ->
        onFinish()

  installFramework: (installToPath = atom.project.path, onFinish)->

    targetFolder = path.resolve(installToPath, 'butterfly')
    targetZipFile = path.resolve(installToPath, 'butterfly.zip')

    rimraf targetZipFile, =>

      @download butterflyURL, targetZipFile, (progress)->
        pv.setProgress(progress)
      , =>
        rimraf targetFolder, =>

          pv.setTitle("Unzip...")
          @unzip targetZipFile, installToPath, =>

            fs.unlink targetZipFile, ->
              pv.destroy()
              onFinish()
