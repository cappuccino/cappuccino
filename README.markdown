[![build](https://github.com/cappuccino/cappuccino/actions/workflows/BuildAndTest.yml/badge.svg)](https://github.com/cappuccino/cappuccino/actions/workflows/BuildAndTest.yml)
[![Join the chat at https://gitter.im/cappuccino/cappuccino](https://badges.gitter.im/cappuccino/cappuccino.svg)](https://gitter.im/cappuccino/cappuccino?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Cappuccino: Build Desktop-Class Web Applications

Cappuccino is an open-source framework that supports building powerful, desktop-class applications running in any modern web browser. Instead of direct manipulation of HTML, CSS, and the DOM, applications are built using Objective-J, a superset of JavaScript modeled on Objective-C.

Cappuccino faithfully implements the proven design patterns of NeXTSTEP/Apple's Cocoa frameworks, enabling the creation of incredibly complex and reliable applications with a fraction of the code.

> **✨ Project Status: Active Development & Node.js Transition**
> Cappuccino has been under continuous development since 2008 and is actively maintained. A major transition to a modern, **Node.js-based toolchain** has recently been finalized. The current release is a production-ready Release Candidate, with a formal release scheduled for 2025. It is stable, fast, and ready for new projects.

---

## Why Use Cappuccino?

Cappuccino is not intended for building simple websites. It is for building **applications**—especially complex, data-rich, line-of-business tools where productivity and user experience are paramount.

*   **💻 True Desktop Behavior, Out-of-the-Box:** Applications built with Cappuccino behave like native desktop software by default. This includes a rich palette of UI controls, **full keyboard navigation and focus management**, and **multi-level undo/redo support** — all implemented without requiring a single extra line of code. See a [Demo application](https://ansb.uniklinik-freiburg.de/UIBuilder/index.html) and the [Kitchen Sink](https://cappuccino-testbook.5apps.com/#ThemeKitchenSink).
*   **🚀 Incredible Productivity:** Less code is needed. High-level abstractions and a powerful object-oriented model mean development is focused on application logic, not browser quirks.
*   **🏛️ Stable & Mature:** Built on decades of proven API design from Cocoa®, Cappuccino provides a stable foundation, free from the churn common in the JavaScript ecosystem.
*   **🧱 True Object-Oriented Architecture:** Objective-J's message-passing architecture promotes loose coupling and clean design, making large-scale applications easier to build and maintain.
*   **🌐 Platform Independent:** Development can be done on macOS, Windows, or Linux. Deployment can target any modern web browser.

## 🚀 Quick Start

A new Cappuccino application can be running in five minutes.

### 1. Prerequisites
[Node.js](https://nodejs.org/en/download/) (LTS versions are recommended) and `npm` are required.

### 2. Configure npm (Recommended First-Time Setup)
To avoid potential permission issues with global packages, setting a local directory for npm is the recommended approach.

```bash
# Tell npm where to install global packages
npm set prefix ~/.npm

# Add this directory to the shell's path in .zshrc, .bash_profile, etc.
export PATH="~/.npm/bin:$PATH"
```
The shell must be restarted or the profile sourced (`source ~/.zshrc`) for the changes to take effect. For more details, see the [npm documentation](https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally).

### 3. Install Cappuccino
```bash
npm install -g @objj/cappuccino
```

### 4. Create and Run the First App
```bash
# 1. A new project is generated
capp gen HelloWorld

# 2. Move into the new directory
cd HelloWorld

# 3. A local web server is started (Python 3 example)
python3 -m http.server 8000

# 4. The new app can be opened in any modern browser
# http://localhost:8000
```
A fully-functional Cappuccino application has now been created.

---

## What is Objective-J?

Objective-J is a strict superset of JavaScript, which means **all JavaScript code is valid Objective-J code**. It adds the powerful object-oriented features of Smalltalk and Objective-C, like explicit message-passing and class-based inheritance.

The syntax might look different, but it is designed for clarity and power.

*   **Objective-C:**
    ```objc
    NSString *greeting = [NSString stringWithFormat:@"Hello, %@!", name];
    ```
*   **Objective-J:**
    ```objj
    var greeting = [CPString stringWithFormat:@"Hello, %@!", name];
    ```

Pure JavaScript and Objective-J can be mixed and matched, even in the same file. The Objective-J code is transpiled into highly-optimized JavaScript for deployment, but can also be run directly in the browser during development.

## Find Out More

*   **Official Website:** [cappuccino.dev](http://cappuccino.dev)
*   **Documentation & Tutorials:** [cappuccino.dev/learn/](http://cappuccino.dev/learn/),  [cappuccino cookbook](https://cappuccino-cookbook.5apps.com)
*   **Gitter Community Chat:** [gitter.im/cappuccino/cappuccino](https://gitter.im/cappuccino/cappuccino)
*   **GitHub Wiki:** [github.com/cappuccino/cappuccino/wiki](https://github.com/cappuccino/cappuccino/wiki)
*   **FAQ:** [cappuccino.dev/support/faq.html](http://cappuccino.dev/support/faq.html)
*   **Report a Bug:** [Create a GitHub Issue](http://github.com/cappuccino/cappuccino/issues)

---

## Frequently Asked Questions (FAQ)

**Q: What are the advantages over React or Vue?**  
**A:** React and Vue are excellent libraries for building web UIs. Cappuccino is a comprehensive **framework** for building entire **applications**. It provides a fully integrated stack—including a mature UI library, event handling, and data management—designed for large-scale development.

Beyond this, Cappuccino provides a more integrated and powerful data-binding layer inspired directly by Cocoa, which dramatically reduces boilerplate code for complex UIs:

*   **Sophisticated Data Bindings:** Going beyond simple state-to-view mapping, Cappuccino's binding technology, based on Key-Value Coding (KVC), allows data models to be declaratively linked directly to UI components.
*   **Powerful Controller Layer:** Dedicated controller objects (like `CPArrayController`) are used to mediate between data and views. These controllers automatically handle sorting, filtering, and selection state, completely decoupling the UI from the business logic.
*   **Advanced Filtering with Predicates:** A table displaying thousands of items can be filtered simply by setting a predicate (a declarative filter rule, e.g., `lastName BEGINSWITH 'S'`) on its controller. The UI updates instantly. This eliminates tons of manual state management and filtering logic code.
*   **Automatic Value Transformation:** Data can be easily formatted for display (e.g., dates, currency, booleans to "Yes/No") directly within the binding itself using value transformers, keeping model data pure and view logic minimal.

**Q: Can Cappuccino be used on Windows/Linux?**  
**A:** Yes. The development tools run on Node.js and are platform-independent. Applications can be developed on any OS and deployed on any web server.

**Q: Is Xcode required?**  
**A:** No. Any code editor can be used. Xcode offers optional visual development tools for macOS users, but it is not a requirement.

**Q: Hasn't Apple moved on from Objective-C, making these APIs obsolete?**  
**A:** While Swift is Apple's newer language, Objective-C and AppKit remain foundational, actively supported technologies used in many of Apple's flagship applications. Cappuccino leverages the stability and power of this time-tested API design, which is independent of Apple's future product roadmap.

**Q: How can custom HTML, CSS, or JavaScript libraries be integrated?**  
**A:** Cappuccino abstracts away the DOM, but other web technologies can still be integrated. The `CPWebView` control allows arbitrary HTML/CSS/JS content to be embedded. Since Objective-J is a superset of JavaScript, JS libraries can be used and JS functions can be called directly from Objective-J code.

**Q: Does the LGPL license permit closed-source commercial applications?**  
**A:** Yes. The LGPLv2 license allows proprietary, closed-source applications to be built and distributed using Cappuccino. Sharing of source code is only required for any modifications made **to the Cappuccino framework itself**. The application code remains proprietary.

---

## Building from Source

To contribute to Cappuccino or to use the absolute latest, un-released changes, the project can be built from source.

1.  `git clone https://github.com/cappuccino/cappuccino.git`
2.  `cd cappuccino`
3.  `npm install` (This bootstraps the build process using the latest release)
4.  `jake build`
5.  `jake dist` (This will install the locally-built toolchain, potentially overwriting your npm version)

To switch back to the official release, `npm install -g @objj/cappuccino` can be run again.

---

## License

Cappuccino is released under the **GNU Lesser General Public License (LGPL) version 2.1 (or later)**.

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

*Cocoa® is a registered trademark of Apple Inc.*
