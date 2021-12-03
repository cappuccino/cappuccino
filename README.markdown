[![build](https://github.com/cappuccino/cappuccino/actions/workflows/BuildAndTest.yml/badge.svg)](https://github.com/cappuccino/cappuccino/actions/workflows/BuildAndTest.yml)
[![Join the chat at https://gitter.im/cappuccino/cappuccino](https://badges.gitter.im/cappuccino/cappuccino.svg)](
  https://gitter.im/cappuccino/cappuccino?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Welcome to Cappuccino!
======================

Introduction
------------
Cappuccino is an open source framework that makes it easy to build
desktop-caliber applications that run in a web browser.

With Cappuccino, you don't concern yourself with HTML, CSS, or the DOM. You  write applications with the APIs from 
Apple's Cocoa frameworks and the Objective-J language.

Check out a [live demo of the widgets in Cappuccino](https://cappuccino-testbook.5apps.com/#ThemeKitchenSink)

Check out some [tutorials](https://cappuccino-cookbook.5apps.com)

For more information, see the
  - [Official website](http://cappuccino-project.org)
  - [Github Wiki](https://github.com/cappuccino/cappuccino/wiki)
  - [FAQ](http://cappuccino-project.org/support/faq.html)
  - [Documentation](http://cappuccino-project.org/learn/)
  - [Mailing list](http://groups.google.com/group/objectivej)
  - [Gitter](https://gitter.im/cappuccino/cappuccino)

Follow [@cappuccino](https://twitter.com/cappuccino) on Twitter for updates on the project.

If you discover any bugs, please [file a ticket](http://github.com/cappuccino/cappuccino/issues).

System Requirements
-------------------
To run Cappuccino applications, all you need is a HTML5 compliant web browser.

Our tight integration with Xcode on MacOS brings the full power of visual Cocoa development to the web.

However, you can also work on other platforms using only a simple text editor.

Node.js version alpha
------------------ 

There is currently an ongoing effort to switch JavaScript platform from [Narwhal](https://narwhaljs.org/) to Node.js.
To try the Node.js version, do the following:

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

If the install succeeded you will be able to do the following to create a simple Cappuccino application:

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
