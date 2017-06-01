gulp        = require 'gulp'
fs          = require 'fs-extra'

gulp.task 'remove_dist', (cb) ->
  fs.remove './dist', cb
