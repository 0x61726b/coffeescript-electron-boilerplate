pathUtil = require 'path'
Q = require 'q'
gulp = require 'gulp'
rollup = require 'rollup'
less = require 'gulp-less'
jetpack = require 'fs-jetpack'

projectDir = jetpack;
srcDir = projectDir.cwd('./app');
destDir = projectDir.cwd('./build');

utils = require './Utility'

paths =
  copyFromAppDir:
    [
        './node_modules/**',
        './vendor/**',
        './**/*.html',
        './**/*.+(jpg|png|svg)'
    ]
 # -------------------------------------
 # Tasks
 # -------------------------------------

#Clean
gulp.task 'clean', () ->
  destDir.dirAsync('.', { empty:true })
#Copy
CopyTask = () ->
  projectDir.copyAsync('app',destDir.path(), { overwrite:true,matching: paths.copyFromAppDir})


gulp.task('copy',['clean'],CopyTask)
gulp.task('copy-watch',CopyTask)

#Bundle
Bundle = (src,dest) ->
  deferred = Q.defer()

  rollup.rollup( { entry:src})
        .then( (bundle) ->
          jsFile = pathUtil.basename(dest)
          result = bundle.generate( { format:'cjs',sourceMap:true,sourceMapFile: jsFile})
          isolatedCode = '(function() {' + result.code+'\n}());';

          Q.all( [
              destDir.writeAsync(dest, isolatedCode + '\n//# sourceMappingURL=' + jsFile + '.map'),
              destDir.writeAsync(dest + '.map', result.map.toString()),
            ])
        ).then( () -> deferred.resolve() )
         .catch( (err) -> console.error('Build: Error during rollup',err.stack));

         deferred.promise;

BundleApplication = () ->

BundleTask = () ->
  BundleApplication()
gulp.task('bundle',['clean'],BundleTask)
gulp.task('bundle-watch',BundleTask)

#less
LessTask = () ->
  gulp.src('app/stylesheets/main.less')
      .pipe(less())
      .pipe(gulp.dest(destDir.path('stylesheets')))

gulp.task('less',['clean'],LessTask)
gulp.task('less-watch',LessTask)


#Watch
gulp.task 'watch', () ->
    gulp.watch('app/**/*.js', ['bundle-watch']);
    gulp.watch(paths.copyFromAppDir, { cwd: 'app' }, ['copy-watch']);
    gulp.watch('app/**/*.less', ['less-watch']);

#Coffee
gulp.task 'compile', () ->
  coffee = require 'gulp-coffee'

  gulp.src( './app/scripts/*.coffee')
      .pipe(coffee())
      .pipe(gulp.dest(destDir.path()))


#Finalize
gulp.task 'finalize', ['clean'], () ->
  manifest = srcDir.read('package.json','json');

  if utils.GetEnvironment() == 'development'
    manifest.name += '-dev'
    manifest.productName += ' Dev'

  destDir.write('package.json',manifest)

gulp.task('build',['bundle','compile','less','copy','finalize'])
