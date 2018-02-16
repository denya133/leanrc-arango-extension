# including plugins
gulp    = require 'gulp'
fs      = require 'fs-extra'
coffee  = require 'gulp-coffee'
{ tests = [] }  = require '../../manifest.json'

compileFiles = (originDir, destinationDir, mask = '**/*.coffee') ->
  new Promise (resolve, reject) ->
    opts = cwd: originDir
    fs.ensureDirSync destinationDir
    gulp.src mask, opts
      .pipe coffee()
      .pipe gulp.dest destinationDir
      .on 'error', reject
      .on 'end', resolve
    return

# task 'compile-coffee'
gulp.task 'compile_coffee', ->
  Promise.resolve()
    .then -> compileFiles './lib', './dist'
    .then -> compileFiles './test/integrational', './dist/app'
    # .then -> compileFiles './lib/migrations', './dist/migrations'
    .then -> compileFiles './test/lib', './dist/test/lib'
    .then -> compileFiles './test/scripts', './dist/scripts'
