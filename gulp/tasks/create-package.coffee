# including plugins
gulp              = require 'gulp'
zip               = require 'gulp-zip'
{ join }          = require 'path'
{ leanrcDependencies }  = require '../../package.json'

ROOT = join __dirname, '../..'

# task 'create_package'
gulp.task 'create_package', ()->
  gulp.src leanrcDependencies.map((name)->
    "node_modules/#{name}/**/*"
  ), base: './', cwd: join ROOT
  .pipe gulp.dest './dist'
  .on 'end', ->
    gulp.src [
      'dist/**/*'
      'public/**/*'
      'migrations/*'
      'LICENSE'
      'index.js'
      'manifest.json'
      'README.md'
    ], base: './', cwd: join ROOT # path to your file
    .pipe zip 'package.zip'
    .pipe gulp.dest './'# including plugins
