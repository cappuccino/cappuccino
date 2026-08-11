[![build](https://github.com/cappuccino/cappuccino/actions/workflows/BuildAndTest.yml/badge.svg)](https://github.com/cappuccino/cappuccino/actions/workflows/BuildAndTest.yml)
[![Join the chat at https://gitter.im/cappuccino/cappuccino](https://badges.gitter.im/cappuccino/cappuccino.svg)](https://gitter.im/cappuccino/cappuccino?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Cappuccino: Build Desktop-Class Web Applications

> **✨ Project Status: v1.5.0 Baseline & Upcoming v2.0.0 Toolchain**
>
> Cappuccino has been under continuous development since 2008 and is actively maintained. The v1.5.0 release establishes a baseline as we move to the new resolution-independent Aristo3 theme and Go-based toolchain.

> For users seeking a complication-free alternative who wish to avoid the Aristo3 work entirely, the legacy-1.4.0 branch provides an unambiguous freeze point. Please note, however, that this legacy branch is not guaranteed to receive any future bug fixes or improvements.

> Active development is now focused on the upcoming v2.0.0 release, which will transition the full toolchain to Golang and the platform-native binaries it produces, leaving Node.js and npm behind.

> **🚨 Aristo3 Theme: Community Testing Required**
>
> Aristo3 represents a non-trivial refactoring of AppKit UI classes. While unit tests pass, it must be tested against real-world applications before being merged into `main`. Community members testing against their own applications will accelerate the process. We are not concerned with minor visual breakages or cosmetic regressions at this stage; **the primary concern is structural failures.**
>
> The fully merged state has been pushed to the `aristo3` branch on the canonical repo.
>
> **How to help:**
> 1. Check out the `aristo3` branch: `git fetch origin && git checkout aristo3`
> 2. Build the frameworks and run your existing applications against this branch.
> 3. Open your browser's developer console and watch for:
>    - Uncaught `CPException`s or JavaScript errors.
>    - Infinite layout loops (browser freezing/tab crashing).
>    - Broken responder chains or keyboard event handling.
>    - KVO/Binding failures or `valueForThemeAttribute:` resolving to `nil` unexpectedly.
>    - View hierarchy corruption (subviews disappearing or failing to clip).
>
> Please leave a 👍 on the [Aristo3 Pull Request](https://github.com/cappuccino/cappuccino/pull/3038) if your apps run without structural failures. If you encounter exceptions or crashes, please leave a comment with the stack trace. **A solid response of thumbs up is required before `main` can be merged. Our intention is to leave no community member behind.**


## Why Use Cappuccino?

Cappuccino is for building **applications** in the browser — especially complex, data-rich, line-of-business tools where productivity and user experience are paramount. Instead of direct manipulation of HTML, CSS, and the DOM, applications are built using Objective-J, a superset of JavaScript modeled on Objective-C. This gives you a lot of benefits:

*   **💻 True Desktop Behavior, Out-of-the-Box:** Applications built with Cappuccino behave like native desktop software by default. This includes a rich palette of UI controls, **full keyboard navigation and focus management**, and **multi-level undo/redo support** — as you can see in this [Showcase application](https://ansb.uniklinik-freiburg.de/ThemeKitchenSinkA3). Also take a look at the [Cookbook tutorial](https://cappuccino-cookbook.5apps.com/).
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
*   **Documentation & Tutorials:** [cappuccino.dev/learn/](http://cappuccino.dev/learn/), [Browser online documentation](https://daboe01.github.io/CappDoc/), [cappuccino cookbook](https://cappuccino-cookbook.5apps.com)
*   **Gitter Community Chat:** [gitter.im/cappuccino/cappuccino](https://gitter.im/cappuccino/cappuccino)
*   **GitHub Wiki:** [github.com/cappuccino/cappuccino/wiki](https://github.com/cappuccino/cappuccino/wiki)
*   **FAQ:** [cappuccino.dev/support/faq.html](http://cappuccino.dev/support/faq.html)
*   **Report a Bug:** [Create a GitHub Issue](http://github.com/cappuccino/cappuccino/issues)

---

## Frequently Asked Questions (FAQ)

**Q: What are the advantages over React or Vue?**
**A:** React and Vue are excellent libraries for building web UIs. Cappuccino is a comprehensive **framework** for building entire **applications**. It provides a fully integrated stack—including a mature UI library, event handling, and data management—designed for large-scale development.

Beyond this, Cappuccino provides a more integrated and powerful data-binding layer inspired directly by Cocoa, which dramatically reduces boilerplate code for complex UIs as you can see in this [example code](https://github.com/daboe01/UIBuilder/tree/master/public/Frontend) that uses these features:

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
