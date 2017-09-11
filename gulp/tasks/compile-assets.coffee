require 'supererror'
gulp              = require 'gulp'
fs                = require 'fs-extra'
gcopy             = require 'gulp-copy'
{ join }          = require 'path'

ROOT = join __dirname, '../..'

isDirectoryExist = (dirName) -> (try fs.statSync(dirName)?.isDirectory()) ? no

copyFiles = (originDir, destinationDir, mask = '**/*') ->
  new Promise (resolve, reject)->
    opts = cwd: originDir
    fs.ensureDirSync destinationDir
    gulp.src mask, opts
      .pipe gcopy destinationDir
      .on 'error', reject
      .on 'end', resolve
    return

gulp.task 'compile_assets', ->
  rootAssets = join ROOT, 'assets'
  publicDir = './public'
  copyFiles rootAssets, publicDir
