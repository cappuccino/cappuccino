# Manual Integration Tests

This directory contains the manual integration test suite for Cappuccino.
Each subdirectory represents a distinct test application.
## Integration Test Definition
Unlike automated, isolated unit tests located in Tests/AppKit, Tests/Foundation, and Tests/Objective-J, the tests in this directory validate the framework as a complete, running application.
A test consists of a minimal Cappuccino application (AppController.j, main.j, Info.plist, index.html) executing in a real browser, exercising the compiled runtime, rendering pipeline, and target classes together.
These tests require manual verification. There are no automated assertions; a human reviewer must open the application, interact with it, and visually verify its behavior.
This suite is designed for human review of specific features, not yet unattended CI.
## Execution
Open /index.html (release) or /index-debug.html (debug, unminified) directly in a web browser.
No intermediate build step is required to load the framework and application sources, provided the /Frameworks directory exists.
To provision the Frameworks directory for every application in the suite, execute `jake configure` within Tests/Manual once initially, and after any framework modifications. The available tasks are:
- `configure:` (Default): Depends on refresh-dist. Builds a shared, merged .Frameworks cache once, then provisions every test application with a single symlink pointing to it.
- `refresh-dist`: Rebuilds the dist packages at the repository root (../../dist).
- `clean`: Removes the Frameworks symlink from each application directory without affecting actual directories. Skips any unmanaged, non-symlink directories.
- `clobber`: Executes clean, then removes the shared .Frameworks cache.

Many applications contain legacy Jakefiles predating the current Node-hosted toolchain.
These use incompatible idioms, will not execute correctly via per-application jake build or jake run commands, and are not required to open the tests directly in a browser. Migration of these Jakefiles is pending.

## Framework Provisioning
The HTML entry points load Frameworks/Objective-J/Objective-J.js (or the debug equivalent) via a literal relative path.
Without this directory present, the application will not load.
### Shared Cache Architecture
Cappuccino's framework build is distributed across two packages (dist/cappuccino, dist/objective-j) and two target levels (release, debug). Every application requires the same merged subset of eight items.
Utilizing a shared cache (.Frameworks) with per-application symlinks provides three structural advantages over copying or linking individual framework components directly into dist:
- **Centralized Configuration**: Modifying the required framework set requires only a single edit, which immediately updates all applications. Direct linking requires restating the set for every application.
- **Atomic Cleanup**: The clean operation targets a single symlink per application. Managing a per-application directory requires sweeping the directory and distinguishing managed components from unmanaged files.
- **Scalability**: The operational cost scales with the application count, rather than the product of application count and member count. Direct linking repeats eight operations per application on every configure execution, whereas the shared cache performs the operations once globally. This ensures configure remains fast enough to run reflexively during iterative development.

### Portability
The Frameworks symlink is ephemeral, ignored by git, and valid exclusively within the Tests/Manual tree.
To relocate a test, regenerate the Frameworks directory at the destination using `capp gen --frameworks appName` (or `--frameworks --symlink appName`), utilizing the binary located at dist/cappuccino/bin/capp.
