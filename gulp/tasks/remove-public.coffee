gulp        = require 'gulp'
fs          = require 'fs-extra'

gulp.task 'remove_public', (cb) ->
  fs.remove './public', cb
