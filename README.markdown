[![build](https://github.com/cappuccino/cappuccino/actions/workflows/BuildAndTest.yml/badge.svg)](https://github.com/cappuccino/cappuccino/actions/workflows/BuildAndTest.yml)
[![Join the chat at https://gitter.im/cappuccino/cappuccino](https://badges.gitter.im/cappuccino/cappuccino.svg)](https://gitter.im/cappuccino/cappuccino?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Cappuccino: Build Desktop-Class Web Applications

Cappuccino is an open-source framework that lets you build powerful, desktop-class applications that run in a web browser. Instead of wrestling with HTML, CSS, and the DOM, you can build your app using Objective-J, a superset of JavaScript modeled on Objective-C.

Cappuccino faithfully implements the proven design patterns of NeXTSTEP/Apple's Cocoa frameworks, allowing you to build incredibly complex and reliable applications with a fraction of the code.

> **✨ Project Status: Active Development & Node.js Transition**
> Cappuccino has been under continuous development since 2008 and is actively maintained. We have recently finalized a major transition to a modern, **Node.js-based toolchain**. The current release is a production-ready Release Candidate, with a formal release scheduled for 2025. It's stable, fast, and ready for your next project.

---

## Why Use Cappuccino?

Cappuccino is not for building simple websites. It's for building **applications**—especially complex, data-rich, line-of-business tools where productivity and user experience are paramount.

*   **💻 True Desktop Behavior, Out-of-the-Box:** Applications built with Cappuccino behave like native desktop software by default. This includes a rich palette of UI controls, **full keyboard navigation and focus management**, and **multi-level undo/redo support** — all without writing a single extra line of code. [See the Kitchen Sink demo](https://cappuccino-testbook.5apps.com/#ThemeKitchenSink).
*   **🚀 Incredible Productivity:** Write less code. High-level abstractions and a powerful object-oriented model mean you focus on your app's logic, not the browser's quirks.
*   **🏛️ Stable & Mature:** Built on decades of proven API design from Cocoa®, Cappuccino provides a stable foundation, free from the churn common in the JavaScript ecosystem.
*   **🧱 True Object-Oriented Architecture:** Objective-J's message-passing architecture promotes loose coupling and clean design, making large-scale applications easier to build and maintain.
*   **🌐 Platform Independent:** Develop on macOS, Windows, or Linux. Deploy to any modern web browser.

## 🚀 Quick Start

Get a new Cappuccino application running in five minutes.

### 1. Prerequisites
You'll need [Node.js](https://nodejs.org/en/download/) (LTS versions are recommended) and `npm`.

### 2. Configure npm (Recommended First-Time Setup)
To avoid potential permission issues with global packages, it's best to set a local directory for npm.

```bash
# Tell npm where to install global packages
npm set prefix ~/.npm

# Add this directory to your path in .zshrc, .bash_profile, etc.
export PATH="~/.npm/bin:$PATH"
```
Restart your shell or source your profile (`source ~/.zshrc`) for the changes to take effect. For more details, see the [npm documentation](https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally).

### 3. Install Cappuccino
```bash
npm install -g @objj/cappuccino
```

### 4. Create and Run Your First App
```bash
# 1. Generate a new project
capp gen HelloWorld

# 2. Move into the new directory
cd HelloWorld

# 3. Start a local web server (Python 3 example)
python3 -m http.server 8000

# 4. Open your new app in any modern browser!
# http://localhost:8000
```
That's it! You now have a fully-functional Cappuccino application.

---

## What is Objective-J?

Objective-J is a strict superset of JavaScript, which means **all JavaScript code is valid Objective-J code**. It adds the powerful object-oriented features of Smalltalk and Objective-C, like explicit message-passing and class-based inheritance.

The syntax might look different, but it's designed for clarity and power.

*   **Objective-C:**
    ```objc
    NSString *greeting = [NSString stringWithFormat:@"Hello, %@!", name];
    ```
*   **Objective-J:**
    ```objj
    var greeting = [CPString stringWithFormat:@"Hello, %@!", name];
    ```

You can mix and match pure JavaScript and Objective-J, even in the same file. Your Objective-J code is transpiled into highly-optimized JavaScript for deployment, but can also be run directly in the browser during development.

## Find Out More

*   **Official Website:** [cappuccino.dev](http://cappuccino.dev)
*   **Documentation & Tutorials:** [cappuccino.dev/learn/](http://cappuccino.dev/learn/),  [cappuccino cookbook](https://cappuccino-cookbook.5apps.com)

*   **Gitter Community Chat:** [gitter.im/cappuccino/cappuccino](https://gitter.im/cappuccino/cappuccino)
*   **GitHub Wiki:** [github.com/cappuccino/cappuccino/wiki](https://github.com/cappuccino/cappuccino/wiki)
*   **FAQ:** [cappuccino.dev/support/faq.html](http://cappuccino.dev/support/faq.html)
*   **Report a Bug:** [Create a GitHub Issue](http://github.com/cappuccino/cappuccino/issues)

---

## Frequently Asked Questions (FAQ)

**Q: Can I use Cappuccino on Windows/Linux?**  
**A:** Yes. The development tools run on Node.js and are platform-independent. Applications can be developed on any OS and deployed on any web server.

**Q: Do I have to use Xcode?**  
**A:** No. You can use any code editor. Xcode offers optional visual development tools for macOS users, but it is not required.

**Q: Hasn't Apple moved on from Objective-C, making these APIs obsolete?**  
**A:** While Swift is Apple's newer language, Objective-C and AppKit remain foundational, actively supported technologies used in many of Apple's flagship applications. Cappuccino leverages the stability and power of this time-tested API design, which is independent of Apple's future product roadmap.

**Q: How do I integrate my own HTML, CSS, or JavaScript libraries?**  
**A:** Cappuccino abstracts away the DOM, but you can still integrate other web technologies. The `CPWebView` control allows you to embed arbitrary HTML/CSS/JS content. Since Objective-J is a superset of JavaScript, you can use JS libraries and call JS functions directly from your Objective-J code.

**Q: What are the advantages over React or Vue?**  
**A:** React and Vue are excellent libraries for building web UIs. Cappuccino is a comprehensive **framework** for building entire **applications**. It provides a fully integrated stack—including a mature UI library, event handling, and data management—designed for large-scale development.

Beyond this, Cappuccino provides a more integrated and powerful data-binding layer inspired directly by Cocoa, which dramatically reduces boilerplate code for complex UIs:

*   **Sophisticated Data Bindings:** Go beyond simple state-to-view mapping. Cappuccino's binding technology, based on Key-Value Coding (KVC), allows you to declaratively link your data models directly to your UI components.
*   **Powerful Controller Layer:** Use dedicated controller objects (like `CPArrayController`) to mediate between your data and your views. These controllers automatically handle sorting, filtering, and selection state, completely decoupling your UI from your business logic.
*   **Advanced Filtering with Predicates:** You can filter a table of thousands of items simply by setting a predicate (a declarative filter rule, e.g., `lastName BEGINSWITH 'S'`) on its controller. The UI updates instantly. This eliminates tons of manual state management and filtering logic code.
*   **Automatic Value Transformation:** Easily format data for display (e.g., dates, currency, booleans to "Yes/No") directly within the binding itself using value transformers, keeping your model data pure and your view logic minimal.

**Q: Does the LGPL license permit closed-source commercial applications?**  
**A:** Yes. The LGPLv2 license allows you to build and distribute proprietary, closed-source applications using Cappuccino. You are only required to share the source code of any modifications you make **to the Cappuccino framework itself**. Your own application code remains your own.

---

## Building from Source

If you want to contribute to Cappuccino or use the absolute latest, un-released changes, you can build it from source.

1.  `git clone https://github.com/cappuccino/cappuccino.git`
2.  `cd cappuccino`
3.  `npm install` (This bootstraps the build process using the latest release)
4.  `jake build`
5.  `jake dist` (This will install the locally-built toolchain, potentially overwriting your npm version)

To switch back to the official release, simply run `npm install -g @objj/cappuccino` again.

---

## License

Cappuccino is released under the **GNU Lesser General Public License (LGPL) version 2.1**.

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

*Cocoa® is a registered trademark of Apple Inc.*
