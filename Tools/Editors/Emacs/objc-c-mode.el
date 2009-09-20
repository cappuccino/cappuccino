;;; objc-c-mode.el --- improvements for the XEmacs Objective-C mode

;; Author:	Michael Weber <michaelw@foldr.org>
;; Version:	20020527
;; Keywords:	Objective-C, ObjC
;; Depends:	cc-mode, font-lock
;; Tested with: XEmacs 21.4 (patch 6) "Common Lisp" [Lucid]

;;; Documentation:
;;; ==============
;;; To use this style for your Objective-C buffers, just add
;;; 	(require 'objc-c-mode)
;;;
;;; to your XEmacs dot-file.  It creates a new style `objc',
;;; which is set as default for all objc-mode buffers.
;;;
;;; To further customize, try this:

;;; (defconst my-c-style
;;;   '("objc"
;;;     (c-indent-comments-syntactically-p       . t)
;;;     (c-comment-only-line-offset              . 0)
;;;     ;;; whatever else here...
;;;
;;;     (c-cleanup-list         . (brace-else-brace
;;;                                brace-elseif-brace
;;;                                empty-defun-braces
;;;                                defun-close-semi
;;;                                compact-empty-funcall
;;;                                )))
;;;   "My C Programming style")
;;;
;;; (defun my-c-mode-common-hook ()
;;;   (c-add-style "PERSONAL" my-c-style t)
;;;   (setq comment-column 40
;;;         tab-width 4
;;;         c-basic-offset tab-width)
;;;
;;;   (c-toggle-auto-state 1))
;;;   
;;; ;; activate customizations for all cc-mode derived modes
;;; (add-hook 'c-mode-common-hook 'my-c-mode-common-hook)

;;; If you want to specifically change the "objc" style,
;;; probably use something like: 

;;; (defconst my-objc-style 
;;;   '(("objc"
;;;      (...)
;;;      "My ObjC style")))
;;; (defun my-objc-mode-hook ()
;;;   (c-add-style "objc" my-objc-style))
;;; (add-hook 'objc-mode-hook 'my-objc-mode-hook)


;;; Code:
;;; =====

(require 'cc-mode)

;;; Default values.  Do not change them here, instead change them like
;;; any other style variable in your customized style.
;;; NOTE: These numbers are ignored anyway, below they are set based on
;;;       `c-basic-offset' which is usually what one wants anyway...
(defcustom-c-stylevar objc-method-arg-min-delta-to-bracket 2
  "*Minimun number of chars to the opening bracket.

Consider this ObjC snippet:

	[foo blahBlah: fred
	|<-x->|barBaz: barney

If `x' is less than this number then `c-lineup-ObjC-method-call-colons'
will defer the indentation decision to the next function.  By default
this is `c-lineup-ObjC-method-call', which would align it like:

	[foo blahBlahBlah: fred
	     thisIsTooDamnLong: barney

This behaviour can be overridden by customizing the indentation of
`objc-method-call-cont' in the \"objc\" style."
  :group 'c)

(defcustom-c-stylevar objc-method-arg-unfinished-offset 4
  "*Offset relative to bracket if first selector is on a new line.

    [aaaaaaaaa
    |<-x->|bbbbbbb:  cccccc
             ddddd: eeee];"
  :group 'c)

(defcustom-c-stylevar objc-method-parameter-offset 4
  "*Offset for selector parameter on a new line (relative to first selector.

    [aaaaaaa bbbbbbbbbb:
	     |<-x->|cccccccc
                    ddd: eeee
                   ffff: ggg];"
  :group 'c)

;; These are the real defaults (set here, because otherwise the
;; indentation whines about them not being defined... *shrug*
(setq c-style-variables (append 
			 '(objc-method-arg-min-delta-to-bracket
			   objc-method-arg-unfinished-offset
			   objc-method-parameter-offset)
			 c-style-variables)

      c-offsets-alist (append
		       '((objc-method-arg-min-delta-to-bracket	. *)
			 (objc-method-arg-unfinished-offset	. +)
			 (objc-method-parameter-offset		. +))
		       c-offsets-alist))


(defun c-lineup-ObjC-method-call-colons (langelem)
  "Line up the colons of selector args with the first selector.

If no decision can be made return NIL, so that other lineup methods can be 
tried.  This is typically chained with `c-lineup-ObjC-method-call'."

  (save-excursion
    (catch 'no-idea
      (let* ((method-arg-len (progn
			       (back-to-indentation)
			       (if (search-forward ":" (c-point 'eol) 'move)
				   (- (point) (c-point 'boi))
				 ; no complete argument to indent yet
				 (throw 'no-idea nil))))

	     (extra (save-excursion	
                      ; indent parameter to argument if needed
		      (back-to-indentation)
		      (c-backward-syntactic-ws (cdr langelem))
		      (if (eq ?: (char-before))
			  (c-get-offset '(objc-method-parameter-offset . nil))
			0)))

	     (open-bracket-col (c-langelem-col langelem))

	     (arg-ralign-colon-ofs (progn
			(forward-char) ; skip over '['
			; skip over object/class name
			; and first argument
			(c-forward-sexp 2)
			(if (search-forward ":" (c-point 'eol) 'move)
			    (- (current-column) open-bracket-col
			       method-arg-len extra)
			  ; previous arg has no param
  			  (c-get-offset '(objc-method-arg-unfinished-offset . nil))))))

	(if (>= arg-ralign-colon-ofs
		(c-get-offset '(objc-method-arg-min-delta-to-bracket . nil)))
	    (+ arg-ralign-colon-ofs extra)
	  (throw 'no-idea nil)
	  )))))


;;; create and add style
(c-add-style "objc"
	     '("gnu"
	       (c-offsets-alist	. ((objc-method-call-cont .
					 (c-lineup-ObjC-method-call-colons
					  c-lineup-ObjC-method-call
					  +))
				   ))
	       ))

(setq c-default-style (cons '(objc-mode . "objc")
			    c-default-style))


;;
;; Now for the font-locking part... :)
;;
(require 'font-lock)

(put 'objc-mode 'font-lock-defaults 
     '((objc-font-lock-keywords
        objc-font-lock-keywords-1 
	objc-font-lock-keywords-2
	objc-font-lock-keywords-3)
       ;; TODO: ?_ is not a good idea in ObjC specifiers...
       nil nil ((?_ . "w")) beginning-of-defun))

(let* ((ctoken          "\\(?:\\sw\\|\\s_\\|[:~*&]\\)+")
       (objc-keywords	"YES\\|NO\\|[Nn]il\\|self\\|super")
       (objc-type-types	"id\\|Class\\|SEL\\|IMP\\|BOOL")
       (addon-objc-font-lock-keywords-1
	  (list ;; nothing to do here...
	   ))
       (addon-objc-font-lock-keywords-2
  	  (append addon-objc-font-lock-keywords-1
	     (list
	      ;; first part of selector (in a declaration)
	      (list (concat "^[+-][ \t]*"
			    "\\((" ctoken "[ \t]*[*]*)\\)?[ \t]*"
			    "\\(\\sw+\\)"
			    )
		    '(2 font-lock-function-name-face))
	      ;; part of a selector
	      '("\\sw*:" 0 font-lock-function-name-face t)
	      ;; Fontify all type specifiers.
	      (cons (concat "\\<\\(" objc-type-types "\\)\\>") 
		    'font-lock-type-face)
	      ;; Fontify all builtin keywords
	      (cons (concat "\\<\\(" objc-keywords "\\)\\>") 
		    'font-lock-keyword-face)
	      ;; Fontify specific keywords
	      (cons (concat "^" (regexp-opt (list
				  "@implementation" "@interface"
				  "@protocol" "@end" "@public"
				  "@private" "@protected"
				  ) t))
		    'font-lock-keyword-face)

	      (list (concat "\\("
			    (regexp-opt (list
				"@class" "@defs" "@encode" "@selector"
				"@protocol"
				))
			    "\\)[ \t]*(")
		    1 'font-lock-keyword-face)

	      '("^#[ \t]*import[ \t]+\\(<[^>\"\n]+>\\)" 
		    1 font-lock-string-face)
	      )
	     ))
	(addon-objc-font-lock-keywords-3
  	  (append addon-objc-font-lock-keywords-2
	     (list
	      ;; get argument-less selectors' highlighting right
	      ;; [[foo _bar_] _baz_] -> bar, baz are highlighted
	      (cons (concat "\\(\\sw+\\)" "[ \t]*" "[]]")
		    '(1 (let ((non-ws-before-match (char-before 
				  (save-excursion
				    (goto-char (match-beginning 1))
				    ;; expensive!
				    (c-backward-syntactic-ws (c-point 'bol))
				    ))))
			  (unless (or (eq ?:  non-ws-before-match)
				      (eq ?\[ non-ws-before-match))
			    'font-lock-function-name-face))))

	      (cons (concat "\\<\\(" objc-type-types "\\)\\>"
			    "\\([ \t*&]+\\sw+\\>\\)*")
		    ;; taken verbatim from font-lock.el
		    '(font-lock-match-c++-style-declaration-item-and-skip-to-next
		      (goto-char (or (match-beginning 8) (match-end 1)))
		      (goto-char (match-end 1))
		      (1 (if (match-beginning 4)
			     font-lock-function-name-face
			   font-lock-variable-name-face))))
	      (cons (concat "\\<"
			    (regexp-opt (list
				 "NS_DURING" "NS_HANDLER" "NS_ENDHANDLER"
				 "RECREATE_AUTORELEASE_POOL"
				 "CREATE_AUTORELEASE_POOL"
				 "ASSIGNCOPY" "ASSIGN" "RETAIN"
				 "DESTROY" "AUTORELEASE" "RELEASE"
				 ) t)
			    "\\>")
		    'font-lock-preprocessor-face)
	      )))
	)

  (setq objc-font-lock-keywords-1 (append c-font-lock-keywords-1 
					  addon-objc-font-lock-keywords-1)

	objc-font-lock-keywords-2 (append c-font-lock-keywords-2
					  addon-objc-font-lock-keywords-2)
 
	objc-font-lock-keywords-3 (append c-font-lock-keywords-3
					  addon-objc-font-lock-keywords-3)
	))


(defvar objc-font-lock-keywords objc-font-lock-keywords-1
  "Default expressions to highlight in ObjC mode.")


(provide 'objc-c-mode)

;;; objc-c-mode.el ends here
