" Vim syntax file
" Language:	Objective-J
" Maintainer:	Shawn MacIntyre <sdm@openradical.com>
" Updaters:	
" URL:		
" Changes:	(sm) merged javascript syntax Claudio Fleiner and Scott Shattuck and objc syntax by Kazunobu Kuriyama and Anthony Hodsdon 
" Last Change:	2008 Sep 8

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
" tuning parameters:
" unlet objj_fold

if !exists("main_syntax")
  if version < 600
    syntax clear
  elseif exists("b:current_syntax")
    finish
  endif
  let main_syntax = 'objj'
endif

" Drop fold if it set but vim doesn't support it.
if version < 600 && exists("objj_fold")
  unlet objj_fold
endif

syn case ignore

" objj keywords, types, type qualifiers etc.
syn keyword objjStatement	self super _cmd
syn keyword objjType		id Class SEL IMP BOOL
"syn keyword objjTypeModifier	bycopy in out inout oneway
syn keyword objjConstant	nil Nil

" Match the objj #import directive (like C's #include)
syn region objjImported display contained start=+"+  skip=+\\\\\|\\"+  end=+"+
syn match  objjImported display contained "<[_0-9a-zA-Z.\/]*>"
syn match  objjImport display "^\s*\(%:\|#\)\s*import\>\s*["<]" contains=objjImported

" Match the important objj directives
syn match  objjScopeDecl    "@public\|@private\|@protected"
syn match  objjDirective    "@interface\|@implementation"
syn match  objjDirective    "@class\|@end\|@defs"
syn match  objjDirective    "@encode\|@protocol\|@selector"
syn match  objjDirective    "@try\|@catch\|@finally\|@throw\|@synchronized"

" Match the ObjC method types
"
" NOTE: here I match only the indicators, this looks
" much nicer and reduces cluttering color highlightings.
" However, if you prefer full method declaration matching
" append .* at the end of the next two patterns!
"
syn match objjInstMethod    "^\s*-\s*"
syn match objjFactMethod    "^\s*+\s*"

" To distinguish from a header inclusion from a protocol list.
"syn match objjProtocol display "<[_a-zA-Z][_a-zA-Z0-9]*>" contains=objjType,cType,Type


" To distinguish labels from the keyword for a method's parameter.
syn region objjKeyForMethodParam display
    \ start="^\s*[_a-zA-Z][_a-zA-Z0-9]*\s*:\s*("
    \ end=")\s*[_a-zA-Z][_a-zA-Z0-9]*"
    \ contains=objjType,Type

" Objective-C Constant Strings
syn match objjSpecial display "%@" contained
syn region objjString start=+\(@"\|"\)+ skip=+\\\\\|\\"+ end=+"+ contains=cFormat,cSpecial,objcSpecial

" Objective-C Message Expressions
syn region objjMessage display start="\[" end="\]" contains=objjMessage,objjStatement,objjType,objjTypeModifier,objjString,objjConstant,objjDirective

syn cluster cParenGroup add=objjMessage
syn cluster cPreProcGroup add=objjMessage


syn keyword objjCommentTodo    TODO FIXME XXX TBD contained
syn match   objjLineComment    "\/\/.*" contains=objjCommentTodo
syn match   objjCommentSkip    "^[ \t]*\*\($\|[ \t]\+\)"
syn region  objjComment	       start="/\*"  end="\*/" contains=objjCommentTodo
syn match   objjSpecial	       "\\\d\d\d\|\\."
syn region  objjStringD	       start=+"+  skip=+\\\\\|\\"+  end=+"\|$+  contains=objjSpecial,@htmlPreproc
syn region  objjStringS	       start=+'+  skip=+\\\\\|\\'+  end=+'\|$+  contains=objjSpecial,@htmlPreproc

syn match   objjSpecialCharacter "'\\.'"
syn match   objjNumber	       "-\=\<\d\+L\=\>\|0[xX][0-9a-fA-F]\+\>"
syn region  objjRegexpString     start=+/[^/*]+me=e-1 skip=+\\\\\|\\/+ end=+/[gi]\{0,2\}\s*$+ end=+/[gi]\{0,2\}\s*[;.,)\]}]+me=e-1 contains=@htmlPreproc oneline

syn keyword objjConditional	if else switch
syn keyword objjRepeat		while for do in
syn keyword objjBranch		break continue
syn keyword objjOperator	new delete instanceof typeof
syn keyword objjType		Array Boolean Date Function Number Object String RegExp
syn keyword objjStatement	return with
syn keyword objjBoolean		true false
syn keyword objjNull		null undefined
syn keyword objjIdentifier	arguments this var
syn keyword objjLabel		case default
syn keyword objjException	try catch finally throw
syn keyword objjMessage		alert confirm prompt status
syn keyword objjGlobal		self window top parent
syn keyword objjMember		document event location 
syn keyword objjDeprecated	escape unescape
syn keyword objjReserved	abstract boolean byte char class const debugger double enum export extends final float goto implements import int interface long native package private protected public short static super synchronized throws transient volatile 

if exists("objj_fold")
    syn match	objjFunction      "\<function\>"
    syn region	objjFunctionFold	start="\<function\>.*[^};]$" end="^\z1}.*$" transparent fold keepend

    syn sync match objjSync	grouphere objjFunctionFold "\<function\>"
    syn sync match objjSync	grouphere NONE "^}"

    setlocal foldmethod=syntax
    setlocal foldtext=getline(v:foldstart)
else
    syn keyword	objjFunction      function
    syn match	objjBraces	   "[{}\[\]]"
    syn match	objjParens	   "[()]"
endif

syn sync fromstart
syn sync maxlines=100

if main_syntax == "objj"
  syn sync ccomment objjComment
endif

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_objj_syn_inits")
  if version < 508
    let did_objj_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
  HiLink objjComment		Comment
  HiLink objjLineComment	Comment
  HiLink objjCommentTodo	Todo
  HiLink objjSpecial		Special
  HiLink objjStringS		String
  HiLink objjStringD		String
  HiLink objjCharacter		Character
  HiLink objjSpecialCharacter	objjSpecial
  HiLink objjNumber		objjValue
  HiLink objjConditional	Conditional
  HiLink objjRepeat		Repeat
  HiLink objjBranch		Conditional
  HiLink objjOperator		Operator
  HiLink objjType		Type
  HiLink objjStatement		Statement
  HiLink objjFunction		Function
  HiLink objjBraces		Function
  HiLink objjError		Error
  HiLink javaScrParenError	objjError
  HiLink objjNull		Keyword
  HiLink objjBoolean		Boolean
  HiLink objjRegexpString	String

  HiLink objjIdentifier		Identifier
  HiLink objjLabel		Label
  HiLink objjException		Exception
  HiLink objjMessage		Keyword
  HiLink objjGlobal		Keyword
  HiLink objjMember		Keyword
  HiLink objjDeprecated		Exception 
  HiLink objjReserved		Keyword
  HiLink objjDebug		Debug
  HiLink objjConstant		Label

  HiLink objjImport		Include
  HiLink objjImported		String
  HiLink objjTypeModifier	objjType
  HiLink objjType		Type
  HiLink objjScopeDecl		Statement
  HiLink objjInstMethod		Function
  HiLink objjFactMethod		Function
  HiLink objjStatement		Statement
  HiLink objjDirective		Statement
  HiLink objjKeyForMethodParam	None
  HiLink objjString		String
  HiLink objjSpecial		Special
  HiLink objjProtocol		None
  HiLink objjConstant		Constant

  delcommand HiLink
endif

let b:current_syntax = "objj"
if main_syntax == 'objj'
  unlet main_syntax
endif

" vim: ts=8