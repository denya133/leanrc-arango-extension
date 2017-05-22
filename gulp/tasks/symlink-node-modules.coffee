require 'supererror'
gulp              = require 'gulp'
symlink           = require 'gulp-symlink'
{ join }          = require 'path'
{ foxxmcDependencies }  = require '../../package.json'

ROOT = join __dirname, '../..'


gulp.task 'symlink_node_modules', ->
  foxxmcDependencies.map (name)->
    gulp.src "node_modules/#{name}", cwd: join ROOT
      .pipe symlink "./dist/node_modules/#{name}"
