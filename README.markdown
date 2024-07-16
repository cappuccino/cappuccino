[![build](https://github.com/cappuccino/cappuccino/actions/workflows/BuildAndTest.yml/badge.svg)](https://github.com/cappuccino/cappuccino/actions/workflows/BuildAndTest.yml)
[![Join the chat at https://gitter.im/cappuccino/cappuccino](https://badges.gitter.im/cappuccino/cappuccino.svg)](
  https://gitter.im/cappuccino/cappuccino?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Welcome to Cappuccino!
======================

Cappuccino, a web application framework in Objective-J, a superset of JavaScript, enhances web development by implementing the NeXTSTEP/Apple Cocoa APIs for web browsers. This integration supports the creation of sophisticated, desktop-class applications without imposing arbitrary complexity limits. Leveraging Cocoa’s well-established architecture, Cappuccino facilitates scalable and reliable application development. Applications can be served from any web server and deployed to any modern web browser without dependencies, offering a streamlined solution for developers.

Introduction
------------
Cappuccino is an open-source framework in continuous development since 2008 and released under the LGPL2 license. It implements as much of the proven NeXTStep/Apple Cocoa API as practicable in the modern web browser environment. Resulting applications are served as HTML, JavaScript, and CSS, allowing deployment from any web host.

Benefits of Cappuccino's Cocoa implementation:
* Cross-platform development - any programmer's text editor or IDE is sufficient. The compiler and other parts of the toolchain required to prepare applications for deployment are hosted by Node.js.
* Cocoa's rich range of interface controls are abstracted to HTML, CSS, and JavaScript. These go well beyond the functionality provided by current browser standards, and only require minimal HTML5 support.
* These design patterns and APIs provide a solid foundation for application development. The APIs have been proven over forty years and provide browser-independent functionality which is a superset of current browser capabilities. 
* Custom interface controls can reliably build on basic Cocoa controls if extended or new functionality is required.
* Robust event-handling mechanisms, a superset of those provided by current browsers, ensure responsive and interactive applications.
* Internationalization and localization technologies simplify global deployment.
* Consistent and predictable behavior across different platforms enhances reliability and user experience.
* Objective-J's [message-passing architecture](https://en.wikipedia.org/wiki/Message_passing), which the Cocoa APIs leverage, promote loose coupling of an app's component functionality — making large scale development more managable.
* Comprehensive documentation for Objective-J is supplemented by over two decades of resources for Objective-C and Cocoa. Additionally, a large public catalog of Objective-C Cocoa applications offers valuable guidance for development. Translation of such sample code to Objective-J is often trivial.
* Toolchain stability - use of time-tested APIs means an absense of the churn which is all too common in the current generic browser-app ecosystem.
* The first web browser and server were written in 1990 by a single person using the APIs which Apple later re-branded and extended as Cocoa. Beyond being a testament to their productivity, it doesn't seem out of place to write application software using the same APIs.

Check out a [live demo of the standard interface controls provided by Cappuccino](https://cappuccino-testbook.5apps.com/#ThemeKitchenSink)

Check out some [tutorials](https://cappuccino-cookbook.5apps.com)

For more information, see the
  - [Official website](http://cappuccino.dev)
  - [Gitter](https://gitter.im/cappuccino/cappuccino)
  - [Github Wiki](https://github.com/cappuccino/cappuccino/wiki)
  - [FAQ](http://cappuccino.dev/support/faq.html)
  - [Documentation](http://cappuccino.dev/learn/)
  - [Mailing list (inactive - for historical purposes only)](http://groups.google.com/group/objectivej)

Bugs and enhancement requrests can be reported by [creating a Github issue](http://github.com/cappuccino/cappuccino/issues).

System Requirements
-------------------
A minimally HTML5-compliant web browser is the only requirement for running Cappuccino applications.
They are served as standard HTML, Javascript, CSS and images from any web server.

Any programmer's editor can be used for coding.

macOS users can use Xcode – which leverages the visual development tools from Apple for creation of complex applications with minimal coding.

Notes on the transition of Cappuccino from the Narwhal Javascript engine to Node.js
------------------ 

Cappuccino compiles source code files written in Objective-J or Javascript to pure HTML/Javascript/CSS.
A desktop Javascript engine with CommonJS for accessing local resources is required for the compilation phase.
Historically, this engine was [Narwhal](https://narwhaljs.org/).
A transition to [Node.js](https://nodejs.org) is being finalized.
The results of this transition are available as a Release Candidate.
While a formal production release is scheduled for early-autumn 2024, it should be considered production-ready as-is. Multiple production deployments over the last twelve months have confirmed this.
In addition to the Node.js-based toolchain, the next formal release will include multiple maintenance improvements and enhancements to the API.

To try Cappuccino using the Node.js version, do the following:

1. Install Node.js and npm from the [Node.js website](https://nodejs.org/download/) or the OS-specific package manager of your choice. Long-term Support (LTS) versions are supported although others will probably work as intended.
  
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
manager, or change npm's default install location manually (which is what we did above with the `npm set prefix…` command). For more details see [this article](https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally).

### Basic usage

On successful installation, follow these steps to create a basic and fully-functional Cappuccino application:

1. `capp gen HelloWorld`
2. `cd HelloWorld`
3. `python3 -m http.server` (any local http server can be used)
4. Go to `localhost:8000` in your web browser.

### Building Cappuccino from source

To build Cappuccino from source  clone the GitHub repository at 
https://github.com/cappuccino/cappuccino/ and checkout the `main` branch. Use the command
`jake install` to install the Cappuccino frameworks and toolchain locally. 

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

FAQs
----
**Q: Can I use Cappuccino on Windows/Linux?**  
**A:** Yes, Cappuccino can be used on Windows or Linux. While Cappuccino technology is inspired by Apple's Cocoa framework, it is designed to be platform-independent. As long as you have a modern web browser and a compatible development environment (An LTS version of node and an http server), you can develop and deploy Cappuccino applications on other operating systems without any issues.

**Q: Has Apple not moved away from Objective-C and Cocoa, making this a dead end?**  
**A:** While Apple has introduced Swift as a modern language and shifted focus to frameworks like SwiftUI, Objective-C and Cocoa remain widely used and supported. Cappuccino leverages the mature and proven Cocoa architecture, which continues to be relevant for many applications. Additionally, Cappuccino’s design abstracts these technologies to the web, ensuring that developers can create robust web applications regardless of Apple’s evolving ecosystem.

**Q: What is with the funny syntax of Objective-J and its brackets? I've never seen a language like this - how can anyone be productive with something so strange?**   
**A:** Objective-J’s syntax, with its brackets, is inspired by Objective-C, which has been used for decades in developing macOS and iOS applications. While it may seem unusual initially, it provides a powerful way to structure code and manage objects. Developers familiar with Objective-C will find it intuitive, and those new to it can leverage extensive documentation and community resources. The initial learning curve is offset by the productivity gains in building complex, maintainable web applications.

**Q: I have my own HTML, JavaScript, and CSS I'd like to use in a larger app. I don't see any JavaScript, HTML, or CSS in the sample code available. How do I modify the DOM?**  
**A:** Cappuccino abstracts much of the DOM to align with Cocoa's model.  Existing Cocoa controls can be extended or new ones built from scratch to meet specific requirements. The Cocoa APIs follow a classic object-oriented programming model – most necessary functionality will be inherited from the Cappuccino base class one is starting with. The [CPWebView](https://www.cappuccino.dev/learn/documentation/interface_c_p_web_view.html) control can also be used to embed either HTML/Javascript/CSS fragments or entire web pages.

**Q: What are the advantages of Cappuccino over libraries and frameworks like React and Vue?**  
**A:** Cappuccino offers several advantages:

* Cocoa Architecture: Leverages the mature and robust Cocoa APIs, providing a solid foundation for complex applications.
* Object-Oriented Approach: Uses Objective-J, which extends JavaScript with powerful object-oriented capabilities.
* Desktop-Class Applications: Designed for creating rich, desktop-like applications that run in web browsers.
* Unified Framework: Integrates UI components, event handling, and data management in a cohesive package.
* Legacy and Stability: Continuous development since 2008 (1986, if going back to the inception of Objective-C and Cocoa) ensures stability and reliability.

**Q: I've heard claims about Objective-C and Cocoa providing increased productivity – how true is this?**.  
**A:** Objective-C and Cocoa are designed for efficiency and ease of use. Their mature, well-documented APIs and comprehensive frameworks enable rapid development of robust applications. The object-oriented nature of Objective-C promotes code reuse and modularity, while Cocoa’s design patterns streamline common tasks. Developers often find that these features collectively lead to increased productivity, especially for complex, desktop-class applications.


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
