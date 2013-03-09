;;; objj-mode.el --- Major mode for editing Objective-J (Cappuccino) files
;;; Written by Geoffrey Grosenbach http://peepcode.com

;;; Builds on the excellent objc-mode from http://www.foldr.org/~michaelw/objective-c/objc-c-mode.el

;;; To install, save this somewhere and add the following to your .emacs file:
;;;
;;; (add-to-list 'load-path "/path/to/cappuccino/Tools/Editors/Emacs/")
;;; (require 'objj-mode)
;;;
;;; Features:
;;; * Syntax highlighting
;;; * Indentation (minimal adherence to Obj-J coding style guidelines)

(require 'objc-c-mode)

(define-derived-mode objj-mode objc-mode
  "Objective-J"
  "Major mode for editing Objective-J files."
  (setq c-basic-offset 4)             ;; 4 spaces for tab
  (setq indent-tabs-mode nil)         ;; Spaces, not tabs
  (c-set-offset 'substatement-open 0) ;; Curly brace on next line
  )

;; TODO: Define more syntax settings to comply with http://cappuccino.org/contribute/coding-style.php

(add-to-list 'auto-mode-alist '("\\.j$" . objj-mode))

(provide 'objj-mode)

