[![Build Status](https://travis-ci.org/cappuccino/cappuccino.svg?branch=master)](https://travis-ci.org/cappuccino/cappuccino) [![Join the chat at https://gitter.im/cappuccino/cappuccino](https://badges.gitter.im/cappuccino/cappuccino.svg)](https://gitter.im/cappuccino/cappuccino?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Welcome to Cappuccino!
======================

Introduction
------------
Cappuccino is an open source framework that makes it easy to build
desktop-caliber applications that run in a web browser.

Cappuccino is built on top of standard web technologies like JavaScript, and
it implements most of the familiar APIs from GNUstep and Apple's Cocoa
frameworks. When you program in Cappuccino, you don't need to concern yourself
with the complexities of traditional web technologies like HTML, CSS, or even
the DOM. The unpleasantries of building complex cross browser applications are
abstracted away for you.

For more information, see <http://cappuccino-project.org>. Follow [@cappuccino](https://twitter.com/cappuccino) on Twitter for updates on the project.

System Requirements
-------------------
To run Cappuccino applications, all you need is a HTML5 compliant web browser.

To develop Cappuccino applications, all you need is a simple text editor and the starter package.

However, Cappuccino's build system and the Xcode integration bring the eases of Cocoa development to web development. 

To build Cappuccino itself, please read below. More information is available
here: [Getting and Building the Source](http://wiki.github.com/cappuccino/cappuccino/getting-and-building-the-source>).

If you're using Windows, you'll also need [Cygwin](http://www.cygwin.com/).

Finally, if you want to easily stay up to date with the latest developments
and contribute your work back to the Cappuccino community, you'll want to
[install Git](http://git-scm.com/).

Getting Started
---------------
To get started, download and install the current release version of Cappuccino:

    $ curl https://raw.githubusercontent.com/cappuccino/cappuccino/v0.9.10/bootstrap.sh >/tmp/cappuccino_bootstrap.sh && bash /tmp/cappuccino_bootstrap.sh

If you'd just like to get started using Cappuccino for your web apps, you are done.

The rest of these instructions are for building a development copy of Cappuccino.
To build Cappuccino from source, check out the most recent stable version from GitHub:

    $ git clone git://github.com/cappuccino/cappuccino.git (git)

or download the zipball of the most recent source code:

  <http://github.com/cappuccino/cappuccino/zipball/master> (zip)

Then, simply type `jake` from within the root of the Cappuccino directory. If you
get an error like `jake: command not found`, you forgot to run the bootstrap script
as described above.

Jake will build a "release" copy of the frameworks. Typing `jake debug` will
build a debug version.

`jake install` will build Cappuccino and associated tools and install them for general use.

Editors
-------
The Cappuccino TextMate Bundle: <http://github.com/malkomalko/Cappuccino.tmbundle>.

The Cappuccino Xcode Plugin: <http://github.com/rbartolome/xcode-cappuccino>.

Getting Help
------------
If you need help with Cappuccino, you can get help from the following sources:

  - [FAQ](http://cappuccino-project.org/support/faq.html)
  - [Documentation](http://cappuccino-project.org/learn/)
  - [Wiki](http://github.com/cappuccino/cappuccino/wikis)
  - Mailing Lists:
    - [Objective-J](http://groups.google.com/group/objectivej)
    - [Objective-J Developers](http://groups.google.com/group/objectivej-dev)
  - [Gitter] (https://gitter.im/cappuccino/cappuccino)

If you discover any bugs, please file a ticket at:

  <http://github.com/cappuccino/cappuccino/issues>

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
