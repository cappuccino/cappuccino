[![build](https://github.com/cappuccino/cappuccino/actions/workflows/BuildAndTest.yml/badge.svg)](https://github.com/cappuccino/cappuccino/actions/workflows/BuildAndTest.yml)
[![Join the chat at https://gitter.im/cappuccino/cappuccino](https://badges.gitter.im/cappuccino/cappuccino.svg)](
  https://gitter.im/cappuccino/cappuccino?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

#Welcome to Cappuccino!

Cappuccino, a web application framework in Objective-J (*a superset of JavaScript which is transpiled for deployment*), enhances app development by implementing the NeXTSTEP/Apple Cocoa APIs for browsers. Leveraging Cocoa’s well-established architecture, Cappuccino facilitates scalable application development for those usage cases requiring developer productivity, reliability and sophisticated interaction support. Resulting applications are served from any web server and deployed to any modern web browser - without plugins or extensions of any kind.

##Introduction

Cappuccino is an open-source framework developed continuously since 2008 and released under the LGPL version 2. It implements as much of the proven NeXTStep/Apple Cocoa API as practical in the modern web browser environment.    

### Benefits of Cappuccino for Application Development:
   
- Cross-platform development – any programmer's text editor or IDE is sufficient. The compiler and other parts of the toolchain used to prepare applications for deployment are hosted by Node.js.
* Cocoa's rich range of interface controls are abstracted to HTML, CSS, and JavaScript. These go well beyond the functionality provided by current browser standards, and only require minimal HTML5 support.
* These design patterns and APIs provide a solid foundation for application development. The APIs have been proven over forty years and provide browser-independent functionality which is a superset of current browser capabilities. 
* Custom interface controls can reliably build on basic Cocoa controls - when extended or new functionality is required.
* Robust event-handling mechanisms, a superset of those provided by current browsers, ensure responsive and interactive applications.
* Internationalization and localization technologies simplify global deployment.
* Consistent and predictable behavior across different platforms enhances reliability and user experience.
* Objective-J's [message-passing architecture](https://en.wikipedia.org/wiki/Message_passing), which the Cocoa APIs leverage, promote loose coupling of an app's component functionality — making large scale development more managable.
* Comprehensive documentation for Objective-J is supplemented by over two decades of resources for Objective-C and Cocoa. Additionally, a large public catalog of Objective-C Cocoa applications offers valuable guidance for development. Translation of such sample code to Objective-J is often trivial.
* Toolchain stability – use of time-tested APIs means an absense of the churn which is all too common in the current generic browser-app ecosystem.

Check out a [live demo of the standard interface controls provided by Cappuccino](https://cappuccino-testbook.5apps.com/#ThemeKitchenSink)

Check out some [tutorials](https://cappuccino-cookbook.5apps.com)

For more information, see the
  - [Official website](http://cappuccino.dev)
  - [Gitter](https://gitter.im/cappuccino/cappuccino)
  - [Github Wiki](https://github.com/cappuccino/cappuccino/wiki)
  - [FAQ](http://cappuccino.dev/support/faq.html)
  - [Documentation](http://cappuccino.dev/learn/)
  - [Mailing list (inactive – for historical purposes only)](http://groups.google.com/group/objectivej)

Bugs and enhancement requrests can be reported by [creating a Github issue](http://github.com/cappuccino/cappuccino/issues).

##System Requirements

* A minimally HTML5-compliant web browser is the only requirement for running Cappuccino applications.
They are served as standard HTML, Javascript, CSS and images from any web server.
* Any programmer's editor can be used for coding.
* macOS users can use Xcode - which leverages the visual development tools from Apple for creation of complex applications with minimal coding.

##Installation instructions 
To try Cappuccino:  

1. Install Node.js and npm from the [Node.js website](https://nodejs.org/download/) or the OS-specific package manager of your choice. Long-term Support (LTS) versions are tested although others will probably work as intended.
  
2. Run `npm set prefix ~/.npm`. This will set the default install location for npm to `~/.npm`. The reasoning behind 
this is outlined in the section about permission issues below.

3. Add this line to your `.zshrc` or equivalent config file.
    ```bash
    export PATH="~/.npm/bin:$PATH"
    ```

4. Restart your shell.

5. Run `npm install -g @objj/cappuccino`.

6. Done! See below for basic usage.  

### Basic usage

On successful installation, follow these steps to create a basic and fully-functional Cappuccino application:

1. `capp gen HelloWorld`
2. `cd HelloWorld`
3. `python3 -m http.server` (any local http server can be used)
4.  Load [localhost:8000](http://localhost:8000) in any browser

### Technical notes

Cappuccino compiles source code files written in Objective-J to pure Javascript but can also run Objective-J directly in the browser. Pure Javascript code can be intermixed with Objective-J, just as Objective-C allows pure C code. This is because each language is a strict superset of its base language.

For app compilation and running other toolchain components in preparation for deployment to production, a desktop Javascript engine supporting CommonJS for accessing local resources is required.
Historically, this engine was [Narwhal](https://narwhaljs.org/).
A transition to [Node.js](https://nodejs.org) is being finalized.  

The results of this transition are available as a **Release Candidate**.
While an official production release is scheduled for early-autumn 2024, it should be considered production-ready as-is. Multiple production deployments over the last twelve months have confirmed this.
In addition to the Node.js-based toolchain, the next formal release will include both maintenance improvements and enhancements to the API.

### Permisson issues

By default npm uses `/usr/local/lib/node_modules` as the install location for globally installed packages. This causes
problems since users typically lack write permissions there. It is therefore recommended to either use a version
manager, or change npm's default install location manually (which is what we did above with the `npm set prefix…` command). For more details see [this article](https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally).  

### Building Cappuccino from source

To build Cappuccino from source (for the latest version, including un-released changes) clone the GitHub repository at 
https://github.com/cappuccino/cappuccino/ and checkout the `main` branch. Use the command
`jake install` to install the Cappuccino frameworks and toolchain locally. 

To build from source, do:

1. `git clone https://github.com/cappuccino/cappuccino.git`
   
2. `cd cappuccino`
   
3. `npm install`. Cappuccino source currently uses the release distribution from npm to bootstrap the toolchain.
   
4. Make sure the environment variable `CAPP_BUILD` is set. This is done by adding the line
    ```bash
    export CAPP_BUILD="/path/to/cappuccino/build/directory"
    ```
    to your `.zshrc` or equivalent config file and of course changing the path to where you want to build Cappuccino.

5.  Run `jake build` to build Cappuccino.  

6.  Run `jake dist` to install the toolchain, as just compiled from source. This step may require elevated permissions.

Beware that building and installing Cappuccino from source will overwrite the binaries installed from npm. To undo this,
simply run `npm install -g @objj/cappuccino` again.

##FAQs

**Q: What is meant by desktop-class apps?**  
**A:** Desktop-class apps refer to web applications that offer the same level of functionality, complexity, and user experience as traditional desktop applications. These apps leverage advanced user interface components, rich graphics, and responsive interactions. Cappuccino is ideally suited for developing line-of-business applications, which are essential tools used within a company for its operations. Such applications often require robust data handling, complex workflows, and a high degree of reliability. Cappuccino’s comprehensive framework, modeled after the Cocoa APIs, ensures that web applications can match the capabilities and performance of native desktop software.

**Q: I don't see any support for touch-screen devices like tablets and phones. Is this supported?**  
**A:** Cappuccino applications can be adapted to support touch-screen devices, including tablets and phones. The framework primarily targets large, information-dense displays typical of desktop environments. Achieving a seamless experience across desktops, tablets, and phones requires additional effort, such as incorporating touch event handling and responsive design. However, with the right adjustments, Cappuccino applications can deliver a consistent user experience on a variety of devices.  

For those looking to extend Cappuccino for touch applications, one option worth exploring is the open source Objective-C framework ["Chameleon"](https://github.com/BigZaphod/Chameleon). This predates Apple's Catalyst efforts and ports many UIKit classes to AppKit, allowing for a seamless integration of touch features. See below for porting Objective-C code to Objective-J, something which is mostly a search-and-replace operation.

**Q: How easy is it to port Objective-C code to Objective-J?**  
**A:** Porting Objective-C code to Objective-J is mostly a search-and-replace operation, primarily focusing on adapting pointer syntax and class names to fit the Objective-J framework.  

Here is a summary of the process:  

1. **Replace class prefixes**: Objective-C classes using the 'NS' prefix need to be replaced with 'CP'. Objective-C(J) does not support formal namespaces - class prefixes are used to overcome this ('NS' for Apple/NeXTSTEP, 'CP' for Cappuccino). Third-party code may use something else - or none at all. For example:  

    `NSString` becomes `CPString`, `NSArray` becomes `CPArray`, and `NSDictionary` becomes `CPDictionary`

2. **Remove pointer references:** Objective-C uses pointers, indicated by the * symbol, which are not used in Objective-J. See example below.

3. **Adapt memory management:** Objective-C's manual memory management and automatic reference counting (ARC) do not apply to Objective-J. Thus, methods like retain, release, and autorelease are removed. Objective-J relies on JavaScript's garbage collection - interaction with it is not supported by any browser.

4. **Modify code with no direct equivalent in Objective-J:** The most common is the C language `enum` construct. Javascript and Objective-J provide no direct equivalent - replace with Javascript objects or functions. 

    **A simple example:**  
    *Objective-C:*     
```NSString *greeting = [NSString stringWithFormat:@"Hello, %@!", name];
[greeting release];```. 
 
    *Objective-J:*  
```let greeting = [CPString stringWithFormat:@"Hello, %@!", name];```   

    Note: While most of ES2022 is supported, Javascript template literals are not (yet).
Simple concatenation could have been used in the Objective-J example, but conversion would have been less straightforward. `async/await` is supported.

**Q: Can I use Cappuccino on Windows/Linux?**  
**A:** Yes - while Cappuccino technology is inspired by Apple's Cocoa framework, it is inherently platform-independent. As long as you have a modern web browser and a compatible development environment (An LTS version of Node.js, a text editor, and an http server), Cappuccino applications can be developed on and deployed from other operating systems without any issues.

**Q: Hasn't Apple moved away from Objective-C and Cocoa, making them obsolete?**  
**A:** While Apple has indeed introduced Swift as a modern programming language and shifted its focus to frameworks like SwiftUI, Objective-C and Cocoa are still widely used and supported. Apple's most sophisticated user applications are written either entirely or substantially in Objective-C and will continue to be for the foreseeable future.

**Q: What is with the funny syntax of Objective-J and its brackets? I've never seen a language like this – how can anyone be productive with something so strange?**   
**A:** Objective-J’s syntax, with its brackets, is inspired by Objective-C, which has been used for decades in developing macOS and iOS applications. While it may seem unusual initially, it provides a powerful way to structure code and manage objects. Developers familiar with Objective-C will find it intuitive, and those new to it can leverage extensive documentation and community resources. The initial learning curve is offset by the productivity gains in building complex, maintainable web applications.

**Q: I have my own HTML, JavaScript, and CSS which I would like to use in a larger app. I don't see any JavaScript, HTML, or CSS in the availablesample code. How do I do this?**  
**A:** Cappuccino abstracts much of the DOM to align with Cocoa's model.  Existing Cocoa controls can be extended or new ones built from scratch to meet specific requirements. The Cocoa APIs follow a classic object-oriented programming model – most necessary functionality will be inherited from the Cappuccino base class one is starting with. The [CPWebView](https://www.cappuccino.dev/learn/documentation/interface_c_p_web_view.html) control can also be used to embed either HTML/Javascript/CSS fragments or entire web pages. Javascript can be intermixed with Objective-J code.

**Q: What are the advantages of Cappuccino over libraries and frameworks like React and Vue?**  
**A:** Cappuccino offers several advantages:

* Cocoa Architecture: Leverages the mature and robust Cocoa APIs, providing a solid foundation for complex applications.
* Object-Oriented Approach: Uses Objective-J, which extends JavaScript with powerful object-oriented capabilities.
* Desktop-Class Usability: Complex controls, coherent keyboard navigation and undo/redo out of the box.
* Unified Framework: Integrates UI components, event handling, and data management in a cohesive package.
* Legacy and Stability: Continuous development since 2008 ensures stability and reliability.

**Q: I've heard claims about Objective-C and Cocoa providing increased productivity – how true is this?**.  
**A:** Objective-C and Cocoa are designed for efficiency and ease of use. Their mature, well-documented APIs and comprehensive frameworks enable rapid development of robust applications. The object-oriented nature of Objective-C promotes code reuse and modularity, while Cocoa’s design patterns streamline common tasks. The rich and extendable palette of user interface controls, while being loosely coupled, are designed to visually and programmatically work well together. Developers often find that these features collectively lead to an order of magnitude increased productivity, especially for complex, desktop-class applications.

**Q: Does the license permit non-opensource development?**  
**A:** Yes, Cappuccino is released under the Lesser General Public License (LGPL) version 2. This allows developers to use, modify, and distribute Cappuccino for both open-source and closed-source applications. Commercial and proprietary software  can be developed with Cappuccino without the obligation to release source code, provided the terms of the LGPL are adhered to. This means any modifications to the Cappuccino framework itself must be made available under the same LGPL license, but your own application code remains proprietary.  

##License

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
