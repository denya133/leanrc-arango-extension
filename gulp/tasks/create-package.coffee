# This file is part of leanrc-arango-extension.
#
# leanrc-arango-extension is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# leanrc-arango-extension is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with leanrc-arango-extension.  If not, see <https://www.gnu.org/licenses/>.

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
