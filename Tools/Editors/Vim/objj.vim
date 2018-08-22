" Vim syntax file
" Language:             Objective-J
" Maintainer:           Shawn MacIntyre <sdm@openradical.com>
" First Author:         Shawn MacIntyre <sdm@openradical.com>
" Updaters:             Kevin Xu <kevin.xu.1982.02.06@gmail.com>
" Changes:              (sm) merged JavaScript syntax by
"                          Claudio Fleiner & Scott Shattuck and
"                          Objective-C syntax by
"                          Valentino Kyriakides, Anthony Hodsdon & Kazunobu Kuriyama
"                       (sm) modified 'objc.vim' to our 'objj.vim'
"                          which reads 'javascript.vim' in the beginning.
" Last Change:          2014 Sep 29

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" Read the JavaScript syntax to start with
if version < 600
  source <sfile>:p:h/javascript.vim
else
  runtime! syntax/javascript.vim
  unlet b:current_syntax
endif

" Modify some syntax from 'javascript.vim'.
syn clear javaScriptParens
syn clear javaScriptBraces

" TODO: The '{}' & '[]' representing the JavaScript 'object' & 'array'
" should be highlighted.

" Read the C syntax to start with
if version < 600
  source <sfile>:p:h/c.vim
else
  runtime! syntax/c.vim
  unlet b:current_syntax
endif

" FIXME: The highlighting the common special-notice 'TBD'
" for comments in JavaScript
" is broken by c.vim.

" Objective-J extentions follow below
"
" NOTE: Objective-J is abbreviated to ObjJ/objj
" and uses *.j as file extensions!


" ObjJ keywords, types, type qualifiers etc.
syn keyword objjStatement	self super _cmd
syn keyword objjStatement	property getter setter readwrite readonly copy
syn keyword objjType		id Class SEL IMP BOOL
syn keyword objjTypeModifier	bycopy in out inout oneway
syn keyword objjConstant	nil Nil NULL NO YES

" Match the ObjJ @import directive
syn match  objjDirective    "@import"

" Match the ObjJ #import directive (like C's #include)
syn region objjImported display contained start=+"+  skip=+\\\\\|\\"+  end=+"+
syn match  objjImported display contained "<[-_0-9a-zA-Z.\/]*>"
syn match  objjImport display "^\s*\(%:\|#\|@\)\s*import\>\s*["<]" contains=objjImported

" Match the important ObjJ directives
syn match  objjDirective    "@typedef"
syn match  objjDirective    "@interface\|@implementation\|@protocol\|@end"
syn match  objjScopeDecl    "@public\|@protected\|@private\|@package"
syn match  objjScopeDecl    "@required\|@optional"
syn match  objjDirective    "@property\|@synthesize\|@dynamic"
syn match  objjDirective    "@outlet\|@accessors"
syn match  objjDirective    "@action\|@selector"
syn match  objjDirective    "@defs"
syn match  objjDirective    "@global\|@class"
syn match  objjDirective    "@encode"
syn match  objjDirective    "@ref\|@deref"
syn match  objjDirective    "@try\|@catch\|@finally\|@throw\|@synchronized"

" Match the ObjJ method types
"
" NOTE: here I match only the indicators, this looks
" much nicer and reduces cluttering color highlightings.
" However, if you prefer full method declaration matching
" append .* at the end of the next two patterns!
"
syn match objjInstMethod    "^\s*-\s*"
syn match objjFactMethod    "^\s*+\s*"

" To distinguish from a header inclusion from a protocol list.
syn match objjProtocol display "<[_a-zA-Z][_a-zA-Z0-9]*>" contains=objjType,cType,Type


" To distinguish labels from the keyword for a method's parameter.
syn region objjKeyForMethodParam display
    \ start="^\s*[_a-zA-Z][_a-zA-Z0-9]*\s*:\s*("
    \ end=")\s*[_a-zA-Z][_a-zA-Z0-9]*"
    \ contains=objjType,objjTypeModifier,cType,cStructure,cStorageClass,Type

" Objective-J Constant Strings
syn match objjSpecial display "%@" contained
syn region objjString start=+\(@"\|"\)+ skip=+\\\\\|\\"+ end=+"+ contains=cFormat,cSpecial,objjSpecial

" Objective-J Message Expressions
syn region objjMessage display start="\[" end="\]" contains=objjMessage,objjStatement,objjType,objjTypeModifier,objjString,objjConstant,objjDirective,cType,cStructure,cStorageClass,cString,cCharacter,cSpecialCharacter,cNumbers,cConstant,cOperator,cComment,cCommentL,Type

syn cluster cParenGroup add=objjMessage
syn cluster cPreProcGroup add=objjMessage

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_objj_syntax_inits")
  if version < 508
    let did_objj_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink objjImport		Include
  HiLink objjImported		cString
  HiLink objjTypeModifier	objjType
  HiLink objjType		Type
  HiLink objjScopeDecl		Statement
  HiLink objjInstMethod		Function
  HiLink objjFactMethod		Function
  HiLink objjStatement		Statement
  HiLink objjDirective		Statement
  HiLink objjKeyForMethodParam	None
  HiLink objjString		cString
  HiLink objjSpecial		Special
  HiLink objjProtocol		None
  HiLink objjConstant		cConstant

  delcommand HiLink
endif

let b:current_syntax = "objj"

" vim: ts=8
