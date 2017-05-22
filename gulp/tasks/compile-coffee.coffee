# including plugins
gulp    = require 'gulp'
coffee  = require 'gulp-coffee'
{ tests = [] }  = require '../../manifest.json'

# task 'compile-coffee'
gulp.task 'compile_coffee', ->
  gulp.src './lib/**/*.coffee'
  .pipe coffee()
  .pipe gulp.dest './dist'
  .on 'end', ->
    # gulp.src './lib/migrations/*.coffee'
    # .pipe coffee()
    # .pipe gulp.dest './dist/migrations'
    # .on 'end', ->
    gulp.src './test/**/*.coffee'
    .pipe coffee()
    .pipe gulp.dest './dist/test'
    .on 'end', ->
      gulp.src './index.coffee'
      .pipe coffee()
      .pipe gulp.dest './'
