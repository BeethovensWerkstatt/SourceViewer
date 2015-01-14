# SourceViewer App
This is a web application to render genetic processes in musical sources encoded with the format of the Music Encoding Initiative ([MEI]). In addition to standard MEI 2013, it makes use of the [data model] for encoding genetic processes provided in a separate git repository.
The application is build to be served from the XML database [eXist] (versions 2.1 and 2.2 work fine). 

This application is work in progress, and will change as required by the [Beethovens Werkstatt] project. A [sample installation] shows the application in action. 

The following first steps relate to **version 0.3.1** of the tool. 

## Installation

In order to use SourceViewer, you need [node.js]. Please refer to their homepage for OS-specific installers.

All commands have to be executed in the root directory of your project.

#### 1. install nodeJS
Refer to their homepage for a OS-specific installer for your system.

#### 2. initialize dependencies
All dependencies are managed by [grunt] and [bower]. In the root directory of your workspace, run the following command:

`npm install` 

This will download and setup the development listed in your *package.json* file. As a result you'll get a folder 'node_modules' being created. 
** Note: ** watch your console for errors during `npm install` to ensure you get a working installation. Sometimes administrator rights are needed for a correct install. 
This is the case on Mac OSX, for instance. On such systems, you need to add `sudo ` before all npm-based commands like so:

`sudo npm install`

##### Grunt-cli
If you've never used Grunt before, you have to install the command-line interface for Grunt (Grunt-cli).

`npm install grunt-cli -g`

##### Compass
SourceViewer is based on [Sass], which is is compiled to CSS. For this compilation, a version of [compass] needs to be available 
on your machine. Go to their website for an OS-specific installer. 


#### 3. initialize Bower
Bower manages the higher-level dependencies. If you haven't installed bower on your computer yet, run

`npm install -g bower`

When Bower is installed, run the following command in the main directory:

`bower install`

This will download the dependencies listed in bower.json to a folder 'bower_components'. 

#### 4. adjust configuration
in the root directory of the app, there is a file *config.tmpl*, which contains information how to access the [eXist] instance for this SourceViewer. The values in here are default values and should ***not*** be changed under any circumstances. Instead, you have create a copy of that file named *config.json* with

`cp config.tmpl config.json`

and adjust the values in the new file. *config.json* is ignored by git to avoid security issues. 


## Grunt command reference

Call the following commands in the root directory of your application for common tasks:

Task | Description
-------- | ----------------
`grunt` | default Grunt task will compile everything to the `dist` directory
`grunt dist`| in addition to the tasks performed by `grunt`, a .xar file is created with correct version number in the `build` directory
`grunt updateJS` | this task will only compile all javascript resources and upload it to the [eXist] instance as described in *config.json*
`grunt updateCSS` | this task will only compile SASS resources and upload it as CSS to the [eXist] instance as described in *config.json*
`grunt updateXQL` | this task will update all xQueries in the [eXist] instance, using the login information from *config.json*
`grunt updateXSLT` | this task will update all XSL stylesheets in the [eXist] instance, using the login information from *config.json*



## Provision of Content
All contents for this tool have to be inserted in the *contents* directory. More detailed information about the data setup is contained in the 
*contents/readme.md* file.

#### Change name, version and description of the app
Variables for the build process can be defined in `package.json`. 

## License
SourceViewer is available under the GNU Affero General Public License (AGPL) v3. 


[mei]:http://www.music-encoding.org/
[eXist]:http://eXist-db.org
[data model]:https://github.com/BeethovensWerkstatt/Data-Model
[Beethovens Werkstatt]:http://beethovens-werkstatt.de
[sample installation]:http://beethovens-werkstatt.de/demo/index.html
[node.js]:http://nodejs.org
[grunt]:http://gruntjs.com
[bower]:http://bower.io
[Sass]:http://sass-lang.com
[compass]:http://compass-style.org
[their website]:http://compass-style.org/install
