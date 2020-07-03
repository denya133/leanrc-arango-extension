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
gulp    = require 'gulp'
fs      = require 'fs-extra'
coffee  = require 'gulp-coffee'
# { tests = [] }  = require '../../manifest.json'

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
