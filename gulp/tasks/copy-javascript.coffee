require 'supererror'
gulp              = require 'gulp'
fs                = require 'fs-extra'
gcopy             = require 'gulp-copy'
{ join }          = require 'path'

ROOT = join __dirname, '../..'

isDirectoryExist = (dirName) -> (try fs.statSync(dirName)?.isDirectory()) ? no

copyFiles = (originDir, destinationDir, mask = '**/*.js') ->
  new Promise (resolve, reject)->
    opts = cwd: originDir
    fs.ensureDirSync destinationDir
    gulp.src mask, opts
      .pipe gcopy destinationDir
      .on 'error', reject
      .on 'end', resolve
    return

copyManifest = (originDir, destinationDir, mask = '**/manifest.json') ->
  new Promise (resolve, reject)->
    opts = cwd: originDir
    fs.ensureDirSync destinationDir
    gulp.src mask, opts
      .pipe gcopy destinationDir
      .on 'error', reject
      .on 'end', resolve
    return

gulp.task 'copy_javascript', ->
  rootAssets = join ROOT, 'api'
  publicDir = './dist'
  copyFiles rootAssets, publicDir
  .then -> copyManifest ROOT, publicDir
