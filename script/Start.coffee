Q = require 'q'
electron = require 'electron-prebuilt'
pathUtil = require 'path'
childProcess = require 'child_process'
kill = require 'tree-kill'
utils = require './Utility'
watch = null
gulp = require 'gulp'


gulpPath = pathUtil.resolve('./node_modules/.bin/gulp')

if process.platform == 'win32'
  gulpPath += '.cmd'

RunBuild = () ->
  deferred = Q.defer()

  build = childProcess.spawn(gulpPath, ['build','--env=' + utils.GetEnvironment(),'--color'],{ stdio: 'inherit'})

  build.on 'close', () ->
    deferred.resolve()

  deferred.promise;

RunGulpWatch = () ->
  watch = childProcess.spawn(gulpPath, [
    'watch',
    '--env=' + utils.GetEnvironment(),
    '--color'
    ],
    {
      stdio: 'inherit'
    })

RunApp = () ->
  app = childProcess.spawn( electron, ['./build'],
  {
    stdio: 'inherit'
  });

  app.on 'close', () ->
    kill( watch.pid, 'SIGKILL', () ->
      process.exit()
      )

module.exports = () ->
  RunBuild().then( () ->
    RunGulpWatch()
    RunApp()
    )
