 # -------------------------------------
 # Helper functions
 # -------------------------------------
argv = require('yargs').argv
os = require('os')

module.exports.WhereAreWe = () ->
  platform = 'unsupported'
  if os.platform() == 'darwin'
    platform = 'osx'
  if os.platform() == 'linux'
    platform = 'linux'
  if os.platform() == 'win32'
    platform = 'win32'

module.exports.GetEnvironment = () ->
  argv.env || 'development'

module.exports.replace = (str,patterns) ->
  Object.keys(patterns).forEach( (pattern) ->
    matcher = new RegExp('{{' + pattern + '}}','g')
    str = str.replace(matcher,patterns[pattern]))

  str;
