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
* Cross-platform development – any programmer's text editor or IDE is sufficient. The compiler and other parts of the toolchain required to prepare applications for deployment are hosted by Node.js.
* Cocoa's rich range of interface controls are abstracted to HTML, CSS, and JavaScript. These go well beyond the functionality provided by current browser standards, and only require minimal HTML5 support.
* These design patterns and APIs provide a solid foundation for application development. The APIs have been proven over forty years and provide browser-independent functionality which is a superset of current browser capabilities. 
* Custom interface controls can reliably build on basic Cocoa controls if extended or new functionality is required.
* Robust event-handling mechanisms, a superset of those provided by current browsers, ensure responsive and interactive applications.
* Internationalization and localization technologies simplify global deployment.
* Consistent and predictable behavior across different platforms enhances reliability and user experience.
* Objective-J's [message-passing architecture](https://en.wikipedia.org/wiki/Message_passing), which the Cocoa APIs leverage, promote loose coupling of an app's component functionality — making large scale development more managable.
* Comprehensive documentation for Objective-J is supplemented by over two decades of resources for Objective-C and Cocoa. Additionally, a large public catalog of Objective-C Cocoa applications offers valuable guidance for development. Translation of such sample code to Objective-J is often trivial.
* Toolchain stability – use of time-tested APIs means an absense of the churn which is all too common in the current generic browser-app ecosystem.
* The first web browser and server were written in 1990 by a single person using the APIs which Apple later re-branded and extended as Cocoa. Beyond being a testament to their productivity, it doesn't seem out of place to write application software using the same APIs.

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

System Requirements
-------------------


**Q: I have my own HTML, JavaScript, and CSS I'd like to use in a larger app. I don't see any JavaScript, HTML, or CSS in the sample code available. How do I modify the DOM?**  
**A:** Cappuccino abstracts much of the DOM to align with Cocoa's model.  Existing Cocoa controls can be extended or new ones built from scratch to meet specific requirements. The Cocoa APIs follow a classic object-oriented programming model – most necessary functionality will be inherited from the Cappuccino base class one is starting with. The [CPWebView](https://www.cappuccino.dev/learn/documentation/interface_c_p_web_view.html) control can also be used to embed either HTML/Javascript/CSS fragments or entire web pages.

**Q: What are the advantages of Cappuccino over libraries and frameworks like React and Vue?**  
**A:** Cappuccino offers several advantages:



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
