###
require 'supererror'
gulp              = require 'gulp'
CodoCLI           = require 'codo/lib/command'


gulp.task 'compile_documentation', ->
  new CodoCLI().generate()
###
