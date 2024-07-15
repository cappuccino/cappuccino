[![build](https://github.com/cappuccino/cappuccino/actions/workflows/BuildAndTest.yml/badge.svg)](https://github.com/cappuccino/cappuccino/actions/workflows/BuildAndTest.yml)
[![Join the chat at https://gitter.im/cappuccino/cappuccino](https://badges.gitter.im/cappuccino/cappuccino.svg)](
  https://gitter.im/cappuccino/cappuccino?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Welcome to Cappuccino!
======================

Cappuccino, a web application framework in Objective-J, a superset of JavaScript, enhances web development by implementing the NeXTSTEP/Apple Cocoa APIs for web browsers. This integration supports the creation of sophisticated, desktop-class applications without imposing arbitrary complexity limits. Leveraging Cocoa’s well-established architecture, Cappuccino facilitates scalable and reliable application development. Applications can be served from any web server and deployed to any modern web browser without dependencies, offering a streamlined solution for developers.

Introduction
------------
Cappuccino is an open-source framework in continuous development since 2008 and released under the LGPL2 license. It implements as much of the proven NeXTStep/Apple Cocoa API as practicable in the modern web browser environment. Resulting applications are served as HTML, JavaScript, and CSS, allowing deployment from any web host.

Benefits of Cocoa over raw HTML/Javascript/CSS:
* Cocoa's rich range of interface controls are abstracted to HTML, CSS, and JavaScript. These go beyond the functionality provided by current browser standards, and only require minimal HTML5 support.
* These design patterns and APIs provide a solid foundation for application development. The APIs have been proven over forty years and provide browser-independent functionality which is a superset of current browser capabilities. 
* Custom interface controls can reliably build on basic Cocoa controls if extended or new functionality is required.
* Robust event-handling mechanisms, a superset of those provided by current browsers, ensure responsive and interactive applications.
* Internationalization and localization technologies simplify global deployment.
* Consistent and predictable behavior across different platforms enhances reliability and user experience.
* Objective-J's [message-passing architecture](https://en.wikipedia.org/wiki/Message_passing), which the Cocoa APIs leverage, promote loose coupling of an app's component functionality — making large scale development more managable.
* Comprehensive documentation for Objective-J is supplemented by over two decades of resources for Objective-C and Cocoa. Additionally, a large public catalog of Objective-C Cocoa applications offers valuable guidance for development. Translation of such sample code to Objective-J is often trivial.
* Toolchain stability - use of proven APIs means an absense of the churn which is all too common in the current generic browser-app ecosystem.

Check out a [live demo of the standard interface controls provided by Cappuccino](https://cappuccino-testbook.5apps.com/#ThemeKitchenSink)

Check out some [tutorials](https://cappuccino-cookbook.5apps.com)

For more information, see the
  - [Official website](http://cappuccino-project.org)
  - [Github Wiki](https://github.com/cappuccino/cappuccino/wiki)
  - [FAQ](http://cappuccino-project.org/support/faq.html)
  - [Documentation](http://cappuccino-project.org/learn/)
  - [Mailing list](http://groups.google.com/group/objectivej)
  - [Gitter](https://gitter.im/cappuccino/cappuccino)

Bugs can be reported by [creating a Github issue](http://github.com/cappuccino/cappuccino/issues).

System Requirements
-------------------
An HTML5 web browser is the only requirement for running Cappuccino applications.
They are served as standard HTML, Javascript, CSS and images from any web server.

Any programmer's editor can be used for coding.

macOS users can use Xcode - which leverages the visual development tools from Apple for creation of complex applications with minimal coding.


Notes on the transition of Cappuccino from the Narwhal Javascript engine to NodeJS
------------------ 

Cappuccino compiles source code files written in Objective-J or Javascript to pure HTML/Javascript/CSS.
A desktop Javascript engine with extensions for accessing local resources is required for the compilation phase.
Historically, this engine was [Narwhal](https://narwhaljs.org/).
Over the several calendar years, a transition to NodeJS has occured.
The results of this are available as a Release Candidate.
While a formal production release is scheduled for early-autumn 2024, it should be considered production-ready as-is. Multiple production deployments over the last twelve months have confirmed this.
In addition to the NodeJS-based toolchain, the next formal release will include multiple maintenance improvements and enhancements to the API.

To try the Cappuccino using the Node.js version, do the following:

1. Install Node.js and npm from the [Node.js website](https://nodejs.org/en/).
  
2. Run `npm set prefix ~/.npm`. This will set the default install location for npm to `~/.npm`. The reasoning behind 
this is outlined in the section about permission issues below.

3. Add this line to your `.zshrc` or equivalent config file.
    ```bash
    export PATH="~/.npm/bin:$PATH"
    ```

4. Restart your shell.

5. Run `npm install -g @objj/cappuccino`.

6. Done! See below for basic usage.

### Permisson issues

By default npm uses `/usr/local/lib/node_modules` as the install location for globally installed packages. This causes
problems since users typically lack write permissions there. It is therefore recommended to either use a version
manager, or change npm's default install location manually (which is what we did above). For more details on how to do
this, see [this article](https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally).

### Basic usage

On successful installation, follow these steps to create a basic and fully-functional Cappuccino application:

1. `capp gen HelloWorld`
2. `cd HelloWorld`
3. `python3 -m http.server`
4. Go to `localhost:8000` in your web browser.

### Building Cappuccino from source

If you want to build Cappuccino from source you should clone the GitHub repository at 
https://github.com/cappuccino/cappuccino/ and checkout the `node` branch. Then you can use the command
`jake install` to install Cappuccino and its tools locally. 

To build from source, do:

1. `git clone https://github.com/cappuccino/cappuccino.git`
   
2. `cd cappuccino`
   
3. `git checkout node`

4. `npm install`

5. Make any desired changes to the codebase.
   
6. Make sure the environment variable `CAPP_BUILD` is set. This is done by adding the line
    ```bash
    export CAPP_BUILD="/path/to/cappuccino/build/directory"
    ```
    to your `.zshrc` or equivalent config file and of course changing the path to where you want to build Cappuccino.
7.  Run `jake install` to build and install Cappuccino.

Beware that building and installing Cappuccino from source will overwrite the binaries installed from npm. To undo this,
simply run `npm install -g @objj/cappuccino` again.

Getting Started
---------------
To write you first application, [download the starter package](http://cappuccino.dev/#download).

To try our new Node (alpha) version of the Cappuccino framework, [check the Node installation instructions](https://github.com/cappuccino/cappuccino/wiki/node)

To contribute to Cappuccino, please read here: [Getting and Building the Source](
  https://github.com/cappuccino/cappuccino/wiki/Getting-and-building-the-source).

License
-------
This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option)
any later version.

This library is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
details.

You should have received a copy of the GNU Lesser General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 51
Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
