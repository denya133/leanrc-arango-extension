# including plugins
gulp          = require 'gulp'
runSequence   = require 'run-sequence'

# task 'watch'
gulp.task 'watch', (cb)->
  runSequence ['remove_dist', 'remove_public']
  , 'compile_documentation', 'compile_coffee'
  , 'copy_javascript', 'symlink_node_modules', ->
    gulp.watch [
      './api/**/*.coffee'
      './api/**/*.js'
      './migrations/*.coffee'
      './index.coffee'
    ], ['compile_coffee', 'copy_javascript']
    .on 'end', cb
