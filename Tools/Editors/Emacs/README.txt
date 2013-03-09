Description
===========
A simple Emacs mode for editing Objective-J (Cappuccino) files.

Author
======
Geoffrey Grosenbach, PeepCode Screencasts 
http://peepcode.com

Features
========
* Syntax highlighting thanks to objc-c-mode.el.
* Some adherence to Objective-J coding style guidelines (indentation).
* Automatic loading of objj-mode when .j files are opened.

Installation
============
Add objc-c-mode.el and objj-mode.el to your load path and require 
objj-mode.

  (add-to-list 'load-path "/path/to/cappuccino/Tools/Editors/Emacs/")
  (require 'objj-mode)

Other
=====
If you use yasnippet (http://code.google.com/p/yasnippet/), you can define 
tab-triggered snippet templates specifically for Objective-J.

Put your snippets in the "snippets/text-mode/objj-mode" directory where
you keep your other yasnippets.

