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
