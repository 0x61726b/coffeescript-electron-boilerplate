gulp = require 'gulp'
utils = require './Utility'

gulp.task('release', ['build'], () ->
  r = require('./Win32Release')

  r()
  )
