Q = require 'q'
gulpUtil = require('gulp-util');
childProcess = require('child_process');
jetpack = require('fs-jetpack');
asar = require('asar');
utils = require('./Utility');

projectDir = null;
tmpDir = null;
releasesDir = null;
readyAppDir = null;
manifest = null;

Init = () ->
    projectDir = jetpack;
    tmpDir = projectDir.dir('./tmp', { empty: true });
    releasesDir = projectDir.dir('./releases');
    manifest = projectDir.read('app/package.json', 'json');
    readyAppDir = tmpDir.cwd(manifest.name);

    Q()


CopyRuntime = () ->
  projectDir.copyAsync('node_modules/electron-prebuilt/dist', readyAppDir.path(), { overwrite: true })

CleanupRuntime = () ->
  readyAppDir.removeAsync('resources/default_app')

PackageBuiltApp = () ->
  deferred = Q.defer()

  asar.createPackage( projectDir.path('build'),readyAppDir.path('resources/app.asar'),() ->
    deferred.resolve() )

  deferred.promise

Finalize = () ->
  deferred = Q.defer()

  projectDir.copy('resources/windows/icon.ico',readyAppDir.path('icon.ico'))

  rcedit = require 'rcedit'

  rcedit(readyAppDir.path('electron.exe'),
  {
      'icon': projectDir.path('resources/windows/icon.ico'),
      'version-string':{
            'ProductName': manifest.productName,
            'FileDescription': manifest.description,
            'ProductVersion': manifest.version,
            'CompanyName': manifest.author, # it might be better to add another field to package.json for this
            'LegalCopyright': manifest.copyright,
            'OriginalFilename': manifest.productName + '.exe'
      }
  }, (err) ->
    if err == null
      deferred.resolve()
      )

  deferred.promise;

RenameApp = () ->
  readyAppDir.renameAsync('electron.exe',manifest.productName + '.exe')


CreateInstaller = () ->
  deferred = Q.defer()

  finalPackageName = manifest.name + '_' + manifest.version + '.exe';
  installScript = projectDir.read('resources/windows/installer.nsi');

  installScript = utils.replace(installScript,
  {
        name: manifest.name,
        productName: manifest.productName,
        author: manifest.author,
        version: manifest.version,
        src: readyAppDir.path(),
        dest: releasesDir.path(finalPackageName),
        icon: readyAppDir.path('icon.ico'),
        setupIcon: projectDir.path('resources/windows/setup-icon.ico'),
        banner: projectDir.path('resources/windows/setup-banner.bmp'),
  })

  tmpDir.write('installer.nsi',installScript)

  gulpUtil.log('Building...')

  releasesDir.remove(finalPackageName);

  nsis = childProcess.spawn('makensis', [
    tmpDir.path('installer.nsi')
    ], {
      stdio: 'inherit'
    })

  nsis.on 'error', (err) ->
    if err.message == 'spawn makensis ENOENT'
      throw "Can't find NSIS."
    else
      throw err;

  nsis.on 'close', () ->
    gulpUtil.log('Installer is ready.',releasesDir.path(finalPackageName))
    deferred.resolve()

  deferred.promise;

CleanClutter = () ->
  tmpDir.removeAsync('.')

module.exports = () ->
  Init().then( () ->
    CopyRuntime().then( () ->
      CleanupRuntime().then( () ->
        PackageBuiltApp().then( () ->
          Finalize().then( () ->
            RenameApp().then( () ->
              CreateInstaller().then( () ->
                CleanClutter())))))))
