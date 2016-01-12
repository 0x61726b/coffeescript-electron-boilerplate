require './script/build'
require './script/Release'

gulp = require 'gulp'

gulp.task 'run', () ->
  start = require './script/Start'

  start()
