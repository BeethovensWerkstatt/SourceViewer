/*
 *
 * Copyright (c) 2014 eXist Solutions
 * Licensed under the MIT license.
 */

'use strict';

/* jshint indent: 2 */

module.exports = function (grunt) {

    require('load-grunt-tasks')(grunt, {scope: 'devDependencies'});

    // Actually load this plugin's task(s).
    // Not necessary since load-grunt-tasks automatically adds them.      
    /*
    grunt.loadNpmTasks('grunt-contrib-concat');
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-zip');
    grunt.loadNpmTasks('grunt-text-replace');
    grunt.loadNpmTasks('grunt-contrib-compass');
    grunt.loadNpmTasks('grunt-contrib-cssmin');
    */
    
    // Project configuration.
    grunt.initConfig({
        xar: grunt.file.readJSON('package.json'),
        config: grunt.file.readJSON('config.json'),
        
        jshint: {
            all: [
                'gruntfile.js'
            ],
            options: {
                jshintrc: '.jshintrc'
            }
        },

        // Before generating any new files, remove any previously-created files.
        clean: {
            pre: ['build', 'dist'],
            post: ['resources/js/app.min.js']
        },

        /*
         replaces tokens in expath-pkg.tmpl and creates expath-pkg.xml with substituted values
         */
        replace: {
            expath: {
                src: ['expath-pkg.tmpl'],
                dest:"expath-pkg.xml",
                replacements: [
                    {
                        from: '@APPVERSION@',
                        to: '<%= xar.version %>'
                    },
                    {
                        from: '@APPNAME@',
                        to: '<%= xar.name %>'
                    },
                    {
                        from: '@APPDESCRIPTION@',
                        to: '<%= xar.description %>'
                    },
                    {
                        from: '@APPURL@',
                        to: '<%= xar.url %>'
                    }
                ]
            } ,
            repo: {
                src: ['repo.tmpl'],
                dest:"repo.xml",
                replacements: [
                    {
                        from: '@APPNAME@',
                        to: '<%= xar.name %>'
                    },
                    {
                        from: '@APPAUTHOR@',
                        to: '<%= xar.author %>'
                    },
                    {
                        from: '@APPLICENSE@',
                        to: '<%= xar.license %>'
                    },
                    {
                        from: '@APPDESCRIPTION@',
                        to: '<%= xar.description %>'
                    }
                ]
            }
        },

        /*
        Copy copies all relevant files for building a distribution in 'dist' directory
        */
        // CSS and JS resources are copied as they get processed by their respective optimization tasks later in the chain.
        // png images will not be copied as they will get optimized by imagemin
        copy: {
            dist: {
                files: [
                    {expand: true,
                        cwd: './',
                        src: ['controller.xconf','modules/**','resources/img/**', '*.xql', '*.xml', '*.txt', '*.ico', '*.html','*.xhtml'],
                        dest: 'dist/'},
                    {expand: true,
                        cwd: './',
                        flatten: true,
                        src: ['bower_components/font-awesome/fonts/**'],
                        dest: 'dist/resources/fonts/',
                        filter: 'isFile'
                    },
                    {expand: true,
                        cwd: './',
                        flatten: true,
                        src: ['resources/fonts/bravura-1.02/**'],
                        dest: 'dist/resources/fonts/bravura-1.02',
                        filter: 'isFile'
                    },
                    {expand: true,
                        cwd: './',
                        flatten: true,
                        src: ['resources/fonts/colaborate/**'],
                        dest: 'dist/resources/fonts/colaborate',
                        filter: 'isFile'
                    },
                    {expand: true,
                        cwd: './',
                        flatten: true,
                        src: ['resources/images/**'],
                        dest: 'dist/resources/images',
                        filter: 'isFile'
                    },
                    {expand: true,
                        cwd: './',
                        flatten: true,
                        src: ['resources/xql/**'],
                        dest: 'dist/resources/xql',
                        filter: 'isFile'
                    },
                    {expand: true,
                        cwd: './',
                        flatten: true,
                        src: ['resources/i18n/**'],
                        dest: 'dist/resources/i18n',
                        filter: 'isFile'
                    },
                    {expand: true,
                        cwd: './',
                        flatten: true,
                        src: ['resources/xslt/**'],
                        dest: 'dist/resources/xslt',
                        filter: 'isFile'
                    },
                    {expand: true,
                        cwd: './bower_components/ace-builds/src-min/',
                        flatten: false,
                        src: ['**/*'],
                        dest: 'dist/resources/js/ace',
                        filter: 'isFile'
                    },
                    {expand: true,
                        cwd: './',
                        flatten: true,
                        src: ['resources/css/filters.svg'],
                        dest: 'dist/resources/css/',
                        filter: 'isFile'
                    },
                    {expand: true,
                        cwd: './',
                        flatten: true,
                        src: ['bower_components/dataModel/rng/bw_data.model_2014.rng'],
                        dest: 'dist/contents/schemata/rng/',
                        filter: 'isFile'
                    },
                    {expand: true,
                        cwd: './',
                        flatten: false,
                        src: ['contents/**/*','!contents/readme.md'],
                        dest: 'dist/',
                        filter: 'isFile'
                    }
                ]
            }
        },
        
        /*
         minifies the file 'resources/js/app.js'. Creates a minified version 'app.min.js'. Using a fixed and unconfigurable
         name makes substitution in html page easier - see build comments at the end of html files.
         */
        uglify: {
            dist: {
                files: {
                    'resources/js/app.min.js': [     
                        'resources/js/leaflet.js', //we need to use this version of leaflet (0.8-dev) until 0.8 is stable and our library can be made compatible 
                        'bower_components/facsimileViewer/leaflet.facsimileViewer.js',
                        'resources/js/app.js'
                    ]
                }
            }
        },
        
        /*
         * compiles all files from resources/scss to dist/resources/css. 
         * in resources/scss, only main.scss is expected to be found. If other files
         * are needed, they should be named with a leading underscore ("_imports.scss")
         * and imported with sass
         */
        compass: {
            dist: {
                options: {
                    sassDir: 'resources/scss',
                    cssDir: 'dist/resources/css'
                }
            }
        },
        
        /*
         * cssmin takes all files that have been processed by compass and merges them with
         * other (legacy) css resources from resources/css. 
         */
        cssmin: {
            combine: {
                options: {
                    keepSpecialComments: 0
                },
                files: {
                    'dist/resources/css/sourceViewer.min.css': ['bower_components/font-awesome/css/font-awesome.min.css',
                                            'resources/css/bravura.css',
                                            'resources/css/colaborate.css',
                                            'resources/css/leaflet.css',
                                            'dist/resources/css/main.css']
                }
            }
        },

        /*
         concatenates all minified JavaScript files into one. Destination file will be app.min.js
         the only exception is ace.js, which seems to reference a whole bunch of other js files, 
         and is thus handled separately by the copy task.
         */
        concat: {
            options: {
                // define a string to put between each file in the concatenated output
                stripBanners: true
            },
            dist: {
                // the files to concatenate - use explicit filenames here to ensure proper order
                // puts app.js at the end.
                src: [
                    'bower_components/jquery/dist/jquery.min.js',
                    'bower_components/verovio/index.js',
                    'resources/js/app.min.js'],
                // the location of the resulting JS file
                dest: 'dist/resources/js/app.min.js'
            }
        },
               
        /*
        This task will replace CSS and JS imports in the main html file to point to the optimized versions instead
        of linking into 'components'
        */
        processhtml: {
            dist: {
                options: {
                    data: {
                        minifiedCss: '<link href="resources/css/sourceViewer.min.css" type="text/css" rel="stylesheet"/>'
                    }
                },
                files: {
                    'dist/index.html': ['./index.html']
                }
            }
        },
        
        existUpload: {
            
                js: {
                    cwd: './dist/',
                    src: ['resources/js/*'],
                    dest:'resources/js/',
                    filter: 'isFile'
                },
                css: {
                    cwd: './dist/',
                    src: ['resources/css/*'],
                    dest:'resources/css/'
                },
                xslt: {
                    cwd: './dist/',
                    src: ['resources/xslt/*'],
                    dest:'resources/xslt/'
                },
                xql: {
                    cwd: './dist/',
                    src: ['resources/xql/*'],
                    dest:'resources/xql/'
                },
                images: {
                    cwd: './dist/',
                    src: ['resources/images/*'],
                    dest:'resources/images/'
                },
                fonts: {
                    cwd: './dist/',
                    src: ['resources/fonts/**/*'],
                    dest:'resources/fonts/',
                    filter: 'isFile'
                }
            
        },
        
        webdav_sync: {
            resources: {
                options: {
                    local_path: './dist/resources/css/**/*',
                    remote_path: 'http://<%= config.eXist_auth %>@<%= config.eXist_host %>:<%= config.eXist_port %>/exist/webdav/db/apps/SourceViewer/resources/'
                }
            }
        },
        
        /*webdav_sync: {
            default: {
                options: {
                    local_path: 'test/assets/upload',
                    remote_path: 'http://user:password@localhost:9001/path/to'
                }
            }
        },*/
        
        /*
         this task builds the actual .xar apps for deployment into eXistdb. zip:xar will create an unoptimized version while
         zip:production will use the optimized app found in the 'dist' directory.

         Note: here component files are cherry-picked - including the whole distribution is certainly more generic but bloats the resulting .xar too much
         */
        zip: {
            /*xar: {
                src: [
                    'collection.xconf',
                    '*.xml',
                    '*.xql',
                    '*.html',
                    '*.xhtml',
                    'data/**',
                    'modules/**',
                    'resources/**',
                    'templates/**',
                    'components/animate.css/*',
                    'components/bootstrap/dist/**',
                    'components/font-awesome/css/**',
                    'components/font-awesome/fonts/**',
                    'components/jquery/dist/**',
                    'components/snap.svg/dist/**'
                ],
                dest: 'build/<%=xar.name%>-<%=xar.version%>.zip'
            },*/
            production: {
                cwd: 'dist/',
                src: ['dist/**'],
                dest: 'build/<%=xar.name%>-<%=xar.version%>.min.xar'
            }
        },

        /*
         watches gruntfile itself and checks for problems
         */
        watch: {
            files: ['gruntfile.js'],
            tasks: ['jshint']
        }



    });

    /*
     */
    grunt.registerTask('default', [
        'clean:pre',
        'replace',
        'copy',
        'uglify',
        'compass',
        'cssmin',
        'concat',
        'processhtml',
        'clean:post'
    ]);
    
    grunt.registerTask('dist', [
        'clean:pre',
        'replace',
        'copy',
        'uglify',
        'compass',
        'cssmin',
        'concat',
        'processhtml',
        'zip:production',
        'clean:post'
    ]);
    
    grunt.registerTask('updateJS', [
        'clean:pre',
        'replace',
        'copy',
        'uglify',
        'concat',
        'processhtml',
        'existUpload:js',
        'clean:post'
    ]);
    
    grunt.registerTask('updateCSS', [
        'clean:pre',
        'replace',
        'copy',
        'compass',
        'cssmin',
        'processhtml',
        'existUpload:css'
    ]);
    
    grunt.registerTask('updateXQL', [
        'clean:pre',
        'replace',
        'copy',
        'existUpload:xql'
    ]);
    
    grunt.registerTask('updateXSLT', [
        'clean:pre',
        'replace',
        'copy',
        'existUpload:xslt'
    ]);
    
    
    grunt.registerTask('existCheck','connects to a local exist database',function(){
        
        var Connection = require('./bower_components/existdb-node/index.js');
                
        var options = {
            host: grunt.file.readJSON('config.json').eXist_host,
            port: grunt.file.readJSON('config.json').eXist_port,
            rest: grunt.file.readJSON('config.json').eXist_rest,
            auth: grunt.file.readJSON('config.json').eXist_auth
        };
        
        var connection = new Connection(options);
        var done = this.async();
        
        connection.get('/db/apps/SourceViewer',function(res){
            
            //necessary for retrieving files 
            /*var data = [];
            res.on("data", function(chunk) {
                data.push(chunk);
            });
            res.on("end", function() {
                grunt.log.writeln(data.join(""));
                done();
            });*/
            
            res.on("end", function() {
                grunt.log.writeln('The eXist-db at http://'+options.host+':'+options.port+' is available');
                grunt.log.writeln('It seems like a SourceViewer app is installed.');
                done();
            });
            
            res.on("error", function(err) {
                grunt.log.writeln('error: ' +err);
                if(err == 'Error: 404')
                    grunt.log.writeln('The eXist-db at http://'+options.host+':'+options.port+' is inaccessible or no SourceViewer app is installed.');
                done(false);
            });
            
        });
        
    });
    
    grunt.registerMultiTask('existUpload','loads compiled resources to the local exist instance',function(){
        
        var config = grunt.file.readJSON('config.json');
        var options = {
            host: config.eXist_host,
            port: config.eXist_port,
            rest: config.eXist_rest,
            auth: config.eXist_auth
        };
        
        var Connection = require('./bower_components/existdb-node/index.js');
        var connection = new Connection(options);
        
        
        
        var files = this.files;
        
        var me = this;
        
        files.forEach(function(file) {
            
            
            grunt.log.writeln('starting over');
            
            var contents = file.src.filter(function(filepath) {
            // Remove nonexistent files (it's up to you to filter or warn here).
            
            var done = me.async();
            
            grunt.log.writeln('filepath:' + filepath);
            
            var path = file.cwd + filepath;
            
            if (!grunt.file.exists(file.cwd + filepath)) {
              grunt.log.warn('Source file "' + file.cwd + filepath + '" not found.');
              return false;
            } else {
              
              var indexLast = filepath.lastIndexOf('/');
              var targetPath = filepath.substring(0,filepath.lastIndexOf('/')) + '/';
              
              grunt.log.writeln('uploading ' + file.cwd + filepath + ' to ' + '/db/apps/SourceViewer/' + targetPath);
              
              connection.store(file.cwd + filepath, '/db/apps/SourceViewer/' + targetPath, function(err) {
                grunt.log.writeln(arguments);
                
                /*if (err) {
                    grunt.log.writeln("uploaded " + file.cwd + filepath + ' to ' + file.dest);
                    grunt.log.writeln("Error: " + err);
                    //done(false);
                } else {
                    grunt.log.writeln("uploaded " + file.cwd + filepath + ' to ' + file.dest);
                    //done();
                }*/
            });
            
            grunt.log.writeln(file);
            
            setTimeout(function() {
                grunt.log.writeln('waiting');
                done();
            },500);
            
            }
          });
          
        });
        
        
        
        /*setTimeout(function() {
            grunt.log.writeln('done');
                done();
            },5000);*/
        
        
    });


};
