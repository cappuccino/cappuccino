/*
 * ObjJCompiler.js
 * Objective-J
 *
 * Created by Martin Carlberg.
 * Copyright 2012, Martin Carlberg.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

//function FileDependency(/*CFURL*/ aURL, /*BOOL*/ isLocal)
/*{
    this._URL = aURL;
    this._isLocal = isLocal;
}*/

//var FileDependency = {};   // Dummy declaration !!!!!!!      REMOVE!!!!!!!!
var ObjJCompiler = { },
    currentCompilerFlags = "";

//(function(global, exports, module)
//{

/*    function IS_NOT_EMPTY(buffer) {return buffer.atoms.length !== 0;}
    
    function CONCAT(buffer, atom)
    {
        if (buffer)
            buffer.atoms[buffer.atoms.length] = atom;
    }
*/
/*function StringBuffer()
{
    this.atoms = [];
}

StringBuffer.prototype.toString = function()
{
    return this.atoms.join("");
}*/

//exports.compile = function(/*String*/ aString, /*CFURL*/ aURL, /*unsigned*/ flags)
/*{
    return new ObjJCompiler(aString, aURL, flags);
}*/

exports.compileToExecutable = function(/*String*/ aString, /*CFURL*/ aURL, /*unsigned*/ flags)
{
    return new ObjJCompiler(aString, aURL, flags, 2).executable();
}

exports.compileToIMBuffer = function(/*String*/ aString, /*CFURL*/ aURL, /*unsigned*/ flags)
{
    return new ObjJCompiler(aString, aURL, flags, 2).IMBuffer();
}

exports.compileFileDependencies = function(/*String*/ aString, /*CFURL*/ aURL, /*unsigned*/ flags)
{
    return new ObjJCompiler(aString, aURL, flags, 1).executable();
}

/*exports.eval = function(aString)
{
    return eval(exports.compile(aString).JSBuffer());
}*/

var ObjJCompiler = function(/*String*/ aString, /*CFURL*/ aURL, /*unsigned*/ flags, /*unsigned*/ pass)
{
    aString = aString.replace(/^#[^\n]+\n/, "\n");
    this._URL = new CFURL(aURL);
	this._pass = pass;
	// If this is pass one we should not save anything in javascript buffer
	if (pass === 1)
		this._jsBuffer = null;
	else
		this._jsBuffer = new StringBuffer();
    this._imBuffer = null;
    this._cmBuffer = null;
    var start = new Date().getTime();
	//console.time("Parse - " + aURL);
    this._tokens = exports.Parser.parse(aString);
	var end = new Date().getTime();
	var time = (end - start) / 1000;
	//print("Parse: " + aURL + " in " + time + " seconds");
	//console.timeEnd("Parse - " + aURL);
    this._dependencies = [];
    this._flags = flags | ObjJCompiler.Flags.IncludeDebugSymbols;
    this._classDefs = {};
    var start = new Date().getTime();
//	console.time("Compile" + pass + " - " + aURL);
	try {
    this.nodeDocument(this._tokens);
    }
    catch (e) {
    	print("Error: " + e + ", file content: " + aString);
    	throw e;
    }
	var end = new Date().getTime();
	var time = (end - start) / 1000;
	//print("Compile pass 1: " + aURL + " in " + time + " seconds");
//	console.timeEnd("Compile" + pass + " - " + aURL);
//	console.log("JS: " + this._jsBuffer);
}

ObjJCompiler.prototype.compilePass2 = function()
{
	this._pass = 2;
	this._jsBuffer = new StringBuffer();
	//print("Start Compile2: " + this._URL);
    var start = new Date().getTime();
//	console.time("Compile" + this._pass + " - " + this._URL);
    this.nodeDocument(this._tokens);
	var end = new Date().getTime();
	var time = (end - start) / 1000;
	//print("Compile pass 2: " + this._URL + " in " + time + " seconds");
//	console.timeEnd("Compile" + this._pass + " - " + this._URL);
	return this._jsBuffer.toString();
}

exports.ObjJCompiler = ObjJCompiler;

exports.setCurrentCompilerFlags = function(/*String*/ compilerFlags)
{
    currentCompilerFlags = compilerFlags;
}

exports.currentCompilerFlags = function(/*String*/ compilerFlags)
{
    return currentCompilerFlags;
}

ObjJCompiler.Flags = { };

ObjJCompiler.Flags.IncludeDebugSymbols = 1 << 0;
ObjJCompiler.Flags.IncludeTypeSignatures = 1 << 1;

ObjJCompiler.AstNodeDocument = "#document";
ObjJCompiler.AstNodeStart = "start";
ObjJCompiler.AstNodeFunctionBody = "FunctionBody";
ObjJCompiler.AstNodeSourceElements = "SourceElements";
ObjJCompiler.AstNodeSourceElement = "SourceElement";
ObjJCompiler.AstNodeFunctionDeclaration = "FunctionDeclaration";
ObjJCompiler.AstNodeFunctionExpression = "FunctionExpression";
ObjJCompiler.AstNodeFormalParameterList = "FormalParameterList";
ObjJCompiler.AstNodeStatementList = "StatementList";
ObjJCompiler.AstNodeStatement = "Statement";
ObjJCompiler.AstNodeBlock = "Block";
ObjJCompiler.AstNodeVariableStatement = "VariableStatement";
ObjJCompiler.AstNodeEmptyStatement = "EmptyStatement";
ObjJCompiler.AstNodeExpressionStatement = "ExpressionStatement";
ObjJCompiler.AstNodeIfStatement = "IfStatement";
ObjJCompiler.AstNodeIterationStatement = "IterationStatement";
ObjJCompiler.AstNodeContinueStatement = "ContinueStatement";
ObjJCompiler.AstNodeBreakStatement = "BreakStatement";
ObjJCompiler.AstNodeReturnStatement = "ReturnStatement";
ObjJCompiler.AstNodeWithStatement = "WithStatement";
ObjJCompiler.AstNodeLabelledStatement = "LabelledStatement";
ObjJCompiler.AstNodeSwitchStatement = "SwitchStatement";
ObjJCompiler.AstNodeThrowStatement = "ThrowStatement";
ObjJCompiler.AstNodeTryStatement = "TryStatement";
ObjJCompiler.AstNodeDebuggerStatement = "DebuggerStatement";
ObjJCompiler.AstNodeImportStatement = "ImportStatement";
ObjJCompiler.AstNodeVariableDeclaration = "VariableDeclaration";
ObjJCompiler.AstNodeVariableDeclarationNoIn = "VariableDeclarationNoIn";
ObjJCompiler.AstNodeVariableDeclarationListNoIn = "VariableDeclarationListNoIn";
ObjJCompiler.AstNodeDoWhileStatement = "DoWhileStatement";
ObjJCompiler.AstNodeWhileStatement = "WhileStatement";
ObjJCompiler.AstNodeForStatement = "ForStatement";
ObjJCompiler.AstNodeForFirstExpression = "ForFirstExpression";
ObjJCompiler.AstNodeForInStatement = "ForInStatement";
ObjJCompiler.AstNodeForInFirstExpression = "ForInFirstExpression";
ObjJCompiler.AstNodeEachStatement = "EachStatement";
ObjJCompiler.AstNodeCaseBlock = "CaseBlock";
ObjJCompiler.AstNodeCaseClauses = "CaseClauses";
ObjJCompiler.AstNodeCaseClause = "CaseClause";
ObjJCompiler.AstNodeDefaultClause = "DefaultClause";
ObjJCompiler.AstNodeCatch = "Catch";
ObjJCompiler.AstNodeFinally = "Finally";
ObjJCompiler.AstNodeLocalFilePath = "LocalFilePath";
ObjJCompiler.AstNodeStandardFilePath = "StandardFilePath";
ObjJCompiler.AstNodeClassDeclarationStatement = "ClassDeclarationStatement";
ObjJCompiler.AstNodeSuperclassDeclaration = "SuperclassDeclaration";
ObjJCompiler.AstNodeCategoryDeclaration = "CategoryDeclaration";
ObjJCompiler.AstNodeCompoundIvarDeclaration = "CompoundIvarDeclaration";
ObjJCompiler.AstNodeIvarType = "IvarType";
ObjJCompiler.AstNodeIvarTypeElement = "IvarTypeElement";
ObjJCompiler.AstNodeIvarDeclaration = "IvarDeclaration";
ObjJCompiler.AstNodeAccessors = "Accessors";
ObjJCompiler.AstNodeAccessorsConfiguration = "AccessorsConfiguration";
ObjJCompiler.AstNodeIvarPropertyName = "IvarPropertyName";
ObjJCompiler.AstNodeIvarGetterName = "IvarGetterName";
ObjJCompiler.AstNodeIvarSetterName = "IvarSetterName";
ObjJCompiler.AstNodeClassBody = "ClassBody";
ObjJCompiler.AstNodeClassElements = "ClassElements";
ObjJCompiler.AstNodeClassElement = "ClassElement";
ObjJCompiler.AstNodeClassMethodDeclaration = "ClassMethodDeclaration";
ObjJCompiler.AstNodeInstanceMethodDeclaration = "InstanceMethodDeclaration";
ObjJCompiler.AstNodeMethodSelector = "MethodSelector";
ObjJCompiler.AstNodeUnarySelector = "UnarySelector";
ObjJCompiler.AstNodeKeywordSelector = "KeywordSelector";
ObjJCompiler.AstNodeKeywordDeclarator = "KeywordDeclarator";
ObjJCompiler.AstNodeSelector = "Selector";
ObjJCompiler.AstNodeMethodType = "MethodType";
ObjJCompiler.AstNodeACTION = "ACTION";
ObjJCompiler.AstNodeExpression = "Expression";
ObjJCompiler.AstNodeExpressionNoIn = "ExpressionNoIn";
ObjJCompiler.AstNodeAssignmentExpression = "AssignmentExpression";
ObjJCompiler.AstNodeAssignmentExpressionNoIn = "AssignmentExpressionNoIn";
ObjJCompiler.AstNodeAssignmentOperator = "AssignmentOperator";
ObjJCompiler.AstNodeConditionalExpression = "ConditionalExpression";
ObjJCompiler.AstNodeConditionalExpressionNoIn = "ConditionalExpressionNoIn";
ObjJCompiler.AstNodeLogicalOrExpression = "LogicalOrExpression";
ObjJCompiler.AstNodeLogicalOrExpressionNoIn = "LogicalOrExpressionNoIn";
ObjJCompiler.AstNodeLogicalAndExpression = "LogicalAndExpression";
ObjJCompiler.AstNodeLogicalAndExpressionNoIn = "LogicalAndExpressionNoIn";
ObjJCompiler.AstNodeBitwiseOrExpression = "BitwiseOrExpression";
ObjJCompiler.AstNodeBitwiseOrExpressionNoIn = "BitwiseOrExpressionNoIn";
ObjJCompiler.AstNodeBitwiseXOrExpression = "BitwiseXOrExpression";
ObjJCompiler.AstNodeBitwiseXOrExpressionNoIn = "BitwiseXOrExpressionNoIn";
ObjJCompiler.AstNodeBitwiseAndExpression = "BitwiseAndExpression";
ObjJCompiler.AstNodeBitwiseAndExpressionNoIn = "BitwiseAndExpressionNoIn";
ObjJCompiler.AstNodeEqualityExpression = "EqualityExpression";
ObjJCompiler.AstNodeEqualityExpressionNoIn = "EqualityExpressionNoIn";
ObjJCompiler.AstNodeEqualityOperator = "EqualityOperator";
ObjJCompiler.AstNodeRelationalExpression = "RelationalExpression";
ObjJCompiler.AstNodeRelationalOperator = "RelationalOperator";
ObjJCompiler.AstNodeRelationalExpressionNoIn = "RelationalExpressionNoIn";
ObjJCompiler.AstNodeRelationalOperatorNoIn = "RelationalOperatorNoIn";
ObjJCompiler.AstNodeShiftExpression = "ShiftExpression";
ObjJCompiler.AstNodeShiftOperator = "ShiftOperator";
ObjJCompiler.AstNodeAdditiveExpression = "AdditiveExpression";
ObjJCompiler.AstNodeAdditiveOperator = "AdditiveOperator";
ObjJCompiler.AstNodeMultiplicativeExpression = "MultiplicativeExpression";
ObjJCompiler.AstNodeMultiplicativeOperator = "MultiplicativeOperator";
ObjJCompiler.AstNodeUnaryExpression = "UnaryExpression";
ObjJCompiler.AstNodePostfixExpression = "PostfixExpression";
ObjJCompiler.AstNodeLeftHandSideExpression = "LeftHandSideExpression";
ObjJCompiler.AstNodeNewExpression = "NewExpression";
ObjJCompiler.AstNodeCallExpression = "CallExpression";
ObjJCompiler.AstNodeMemberExpression = "MemberExpression";
ObjJCompiler.AstNodeBracketedAccessor = "BracketedAccessor";
ObjJCompiler.AstNodeDotAccessor = "DotAccessor";
ObjJCompiler.AstNodeArguments = "Arguments";
ObjJCompiler.AstNodeArgumentList = "ArgumentList";
ObjJCompiler.AstNodePrimaryExpression = "PrimaryExpression";
ObjJCompiler.AstNodeMessageExpression = "MessageExpression";
ObjJCompiler.AstNodeSUPER = "SUPER";
ObjJCompiler.AstNodeSelectorCall = "SelectorCall";
ObjJCompiler.AstNodeKeywordSelectorCall = "KeywordSelectorCall";
ObjJCompiler.AstNodeKeywordCall = "KeywordCall";
ObjJCompiler.AstNodeArrayLiteral = "ArrayLiteral";
ObjJCompiler.AstNodeElementList = "ElementList";
ObjJCompiler.AstNodeObjectLiteral = "ObjectLiteral";
ObjJCompiler.AstNodePropertyNameAndValueList = "PropertyNameAndValueList";
ObjJCompiler.AstNodePropertyAssignment = "PropertyAssignment";
ObjJCompiler.AstNodePropertyGetter = "PropertyGetter";
ObjJCompiler.AstNodePropertySetter = "PropertySetter";
ObjJCompiler.AstNodePropertyName = "PropertyName";
ObjJCompiler.AstNodePropertySetParameterList = "PropertySetParameterList";
ObjJCompiler.AstNodeLiteral = "Literal";
ObjJCompiler.AstNodeNullLiteral = "NullLiteral";
ObjJCompiler.AstNodeBooleanLiteral = "BooleanLiteral";
ObjJCompiler.AstNodeNumericLiteral = "NumericLiteral";
ObjJCompiler.AstNodeDecimalLiteral = "DecimalLiteral";
ObjJCompiler.AstNodeDecimalIntegerLiteral = "DecimalIntegerLiteral";
ObjJCompiler.AstNodeDecimalDigit = "DecimalDigit";
ObjJCompiler.AstNodeExponentPart = "ExponentPart";
ObjJCompiler.AstNodeSignedInteger = "SignedInteger";
ObjJCompiler.AstNodeHexIntegerLiteral = "HexIntegerLiteral";
ObjJCompiler.AstNodeHexDigit = "HexDigit";
ObjJCompiler.AstNodeStringLiteral = "StringLiteral";
ObjJCompiler.AstNodeDoubleStringCharacter = "DoubleStringCharacter";
ObjJCompiler.AstNodeSingleStringCharacter = "SingleStringCharacter";
ObjJCompiler.AstNodeLineContinuation = "LineContinuation";
ObjJCompiler.AstNodeEscapeSequence = "EscapeSequence";
ObjJCompiler.AstNodeCharacterEscapeSequence = "CharacterEscapeSequence";
ObjJCompiler.AstNodeSingleEscapeCharacter = "SingleEscapeCharacter";
ObjJCompiler.AstNodeNonEscapeCharacter = "NonEscapeCharacter";
ObjJCompiler.AstNodeEscapeCharacter = "EscapeCharacter";
ObjJCompiler.AstNodeHexEscapeSequence = "HexEscapeSequence";
ObjJCompiler.AstNodeUnicodeEscapeSequence = "UnicodeEscapeSequence";
ObjJCompiler.AstNodeRegularExpressionLiteral = "RegularExpressionLiteral";
ObjJCompiler.AstNodeRegularExpressionBody = "RegularExpressionBody";
ObjJCompiler.AstNodeRegularExpressionFirstChar = "RegularExpressionFirstChar";
ObjJCompiler.AstNodeRegularExpressionChar = "RegularExpressionChar";
ObjJCompiler.AstNodeRegularExpressionBackslashSequence = "RegularExpressionBackslashSequence";
ObjJCompiler.AstNodeRegularExpressionNonTerminator = "RegularExpressionNonTerminator";
ObjJCompiler.AstNodeRegularExpressionClass = "RegularExpressionClass";
ObjJCompiler.AstNodeRegularExpressionClassChar = "RegularExpressionClassChar";
ObjJCompiler.AstNodeRegularExpressionFlags = "RegularExpressionFlags";
ObjJCompiler.AstNodeSelectorLiteral = "SelectorLiteral";
ObjJCompiler.AstNodeSelectorLiteralContents = "SelectorLiteralContents";
ObjJCompiler.AstNodeUnderline = "_";
ObjJCompiler.AstNodeUnderlineNoLineBreak = "__";
ObjJCompiler.AstNodeWhiteSpace = "WhiteSpace";
ObjJCompiler.AstNodeLineTerminator = "LineTerminator";
ObjJCompiler.AstNodeLineTerminatorSequence = "LineTerminatorSequence";
ObjJCompiler.AstNodeComment = "Comment";
ObjJCompiler.AstNodeMultiLineComment = "MultiLineComment";
ObjJCompiler.AstNodeSingleLineMultiLineComment = "SingleLineMultiLineComment";
ObjJCompiler.AstNodeSingleLineComment = "SingleLineComment";
ObjJCompiler.AstNodeSingleLineCommentChar = "SingleLineCommentChar";
ObjJCompiler.AstNodeEOS = "EOS";
ObjJCompiler.AstNodeSemicolonInsertionEOS = "SemicolonInsertionEOS";
ObjJCompiler.AstNodeEOF = "EOF";
ObjJCompiler.AstNodeReservedWord = "ReservedWord";
ObjJCompiler.AstNodeKeyword = "Keyword";
ObjJCompiler.AstNodeFutureReservedWord = "FutureReservedWord";
ObjJCompiler.AstNodeIdentifier = "Identifier";
ObjJCompiler.AstNodeBadIdentifier = "BadIdentifier";
ObjJCompiler.AstNodeReservedWordIdentifier = "ReservedWordIdentifier";
ObjJCompiler.AstNodeDigitIdentifier = "DigitIdentifier";
ObjJCompiler.AstNodeIdentifierName = "IdentifierName";
ObjJCompiler.AstNodeIdentifierStart = "IdentifierStart";
ObjJCompiler.AstNodeIdentifierPart = "IdentifierPart";
ObjJCompiler.AstNodeUnicodeLetter = "UnicodeLetter";
ObjJCompiler.AstNodeUnicodeCombiningMark = "UnicodeCombiningMark";
ObjJCompiler.AstNodeUnicodeDigit = "UnicodeDigit";
ObjJCompiler.AstNodeUnicodeConnectorPunctuation = "UnicodeConnectorPunctuation";
ObjJCompiler.AstNodeZWNJ = "ZWNJ";
ObjJCompiler.AstNodeZWJ = "ZWJ";
ObjJCompiler.AstNodeFALSE = "FALSE";
ObjJCompiler.AstNodeTRUE = "TRUE";
ObjJCompiler.AstNodeNULL = "NULL";
ObjJCompiler.AstNodeBREAK = "BREAK";
ObjJCompiler.AstNodeCONTINUE = "CONTINUE";
ObjJCompiler.AstNodeDEBUGGER = "DEBUGGER";
ObjJCompiler.AstNodeIN = "IN";
ObjJCompiler.AstNodeINSTANCEOF = "INSTANCEOF";
ObjJCompiler.AstNodeDELETE = "DELETE";
ObjJCompiler.AstNodeFUNCTION = "FUNCTION";
ObjJCompiler.AstNodeNEW = "NEW";
ObjJCompiler.AstNodeTHIS = "THIS";
ObjJCompiler.AstNodeTYPEOF = "TYPEOF";
ObjJCompiler.AstNodeVOID = "VOID";
ObjJCompiler.AstNodeIF = "IF";
ObjJCompiler.AstNodeELSE = "ELSE";
ObjJCompiler.AstNodeDO = "DO";
ObjJCompiler.AstNodeWHILE = "WHILE";
ObjJCompiler.AstNodeFOR = "FOR";
ObjJCompiler.AstNodeVAR = "VAR";
ObjJCompiler.AstNodeRETURN = "RETURN";
ObjJCompiler.AstNodeCASE = "CASE";
ObjJCompiler.AstNodeDEFAULT = "DEFAULT";
ObjJCompiler.AstNodeSWITCH = "SWITCH";
ObjJCompiler.AstNodeTHROW = "THROW";
ObjJCompiler.AstNodeCATCH = "CATCH";
ObjJCompiler.AstNodeFINALLY = "FINALLY";
ObjJCompiler.AstNodeTRY = "TRY";
ObjJCompiler.AstNodeWITH = "WITH";

ObjJCompiler.prototype.assertNode = function(/*SyntaxNode*/ astNode, /*String*/ astNodeName)
{
	if (!astNode || astNode.name !== astNodeName)
    {
//        debugger;
		throw new SyntaxError(this.error_message("Expected node " + astNodeName + " but got " + (astNode ? astNode.name : astNode), astNode));
    }
}

ObjJCompiler.prototype.nodeDocument = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeDocument);
	this.nodeStart(astNode.children[0]);
}

ObjJCompiler.prototype.nodeStart = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeStart);
	var children = astNode.children;

	this.nodeUnderline(children[0], false);
	var lastUnderlineIndex = 1;
	if (children.length === 3)
	{
		this.nodeSourceElements(children[1]);
		lastUnderlineIndex++;
	}
	this.nodeUnderline(children[lastUnderlineIndex], false)
}

ObjJCompiler.prototype.nodeFunctionBody = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeFunctionBody);
	var children = astNode.children;

	this.nodeUnderline(children[0], false);
	var lastUnderlineIndex = 1;
	if (children.length === 3)
	{
		this.nodeSourceElements(children[1]);
		lastUnderlineIndex++;
	}
	this.nodeUnderline(children[lastUnderlineIndex], false)
}

ObjJCompiler.prototype.nodeSourceElements = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSourceElements);
	var children = astNode.children;

	this.nodeSourceElement(children[0]);

	for (var i = 1; i + 1 < children.length; i += 2)
	{
		this.nodeUnderline(children[i], false);
		this.nodeSourceElement(children[i + 1]);
	}
}

ObjJCompiler.prototype.nodeSourceElement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSourceElement);
	var child = astNode.children[0];

	if (child && child.name === ObjJCompiler.AstNodeStatement)
		this.nodeStatement(child);
	else if (child && child.name === ObjJCompiler.AstNodeFunctionDeclaration)
		if (this._pass === 2)	// Skip this if it is the first pass
			this.nodeFunctionDeclaration(child);
	else
		throw new SyntaxError(this.error_message("Expected node " + ObjJCompiler.AstNodeStatement + " or " + ObjJCompiler.AstNodeFunctionDeclaration + " but got " + child, child));
}

ObjJCompiler.prototype.nodeFunctionDeclaration = function(/*SyntaxNode*/ astNode)
{
    // Safari can't handle function declarations of the form function [name]([arguments]) { }
    // in evals.  It requires them to be in the form [name] = function([arguments]) { }.  So we
    // need format them like that.
	this.assertNode(astNode, ObjJCompiler.AstNodeFunctionDeclaration);
	var children = astNode.children,
        child = children[6],
        offset = 0,
		saveJSBuffer = this._jsBuffer;

	this._jsBuffer = null;
	this.nodeFUNCTION(children[0]);
	this.nodeUnderline(children[1], true);
	var identifier = this.nodeIdentifier(children[2]);
	this.nodeUnderline(children[3], false);
	if (saveJSBuffer)
	{
		CONCAT(saveJSBuffer, identifier);
		CONCAT(saveJSBuffer, " = function");
	}
	this._jsBuffer = saveJSBuffer;
	this.nodeOpenParenthesis(children[4]);
	this.nodeUnderline(children[5], false);

	if (child && child.name ===ObjJCompiler.AstNodeFormalParameterList)
	{
		this.nodeFormalParameterList(children[6]);
		offset++;
	}
	this.nodeUnderline(children[6 + offset], false);
	this.nodeCloseParenthesis(children[7 + offset]);
	this.nodeUnderline(children[8 + offset], false);
	this.nodeOpenBrace(children[9 + offset]);
	this.nodeUnderline(children[10 + offset], false);
	this.nodeFunctionBody(children[11 + offset]);
	this.nodeUnderline(children[12 + offset], false);
	this.nodeCloseBrace(children[13 + offset]);
}

ObjJCompiler.prototype.nodeFunctionExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeFunctionExpression);
	var children = astNode.children,
        child = children[2],
        offset = 0;

	this.nodeFUNCTION(children[0]);
	this.nodeUnderline(children[1], true);
    if (child && child.name === ObjJCompiler.AstNodeIdentifier)
    {
        this.nodeIdentifier(child);
        offset++;
    }
	this.nodeUnderline(children[2 + offset], false);
	this.nodeWORD(children[3 + offset]);
	this.nodeUnderline(children[4 + offset], false);

    child = children[5 + offset];

	if (child && child.name ===ObjJCompiler.AstNodeFormalParameterList)
	{
		this.nodeFormalParameterList(child);
		offset++;
	}
	this.nodeUnderline(children[5 + offset], false);
	this.nodeWORD(children[6 + offset]);
	this.nodeUnderline(children[7 + offset], false);
	this.nodeOpenBrace(children[8 + offset]);
	this.nodeUnderline(children[9 + offset], false);
	this.nodeFunctionBody(children[10 + offset]);
	this.nodeUnderline(children[11 + offset], false);
	this.nodeCloseBrace(children[12 + offset]);
}

ObjJCompiler.prototype.nodeFormalParameterList = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeFormalParameterList);
	var children = astNode.children;

	this.nodeIdentifier(children[0]);
	for (var i = 1; i + 3 < children.length; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeWORD(children[i + 1]);
		this.nodeUnderline(children[i + 2], false);
		this.nodeIdentifier(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeStatementList = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeStatementList);
	var children = astNode.children;

	this.nodeStatement(children[0]);

	for (var i = 1; i + 1 < children.length; i += 2)
	{
		this.nodeUnderline(children[i], false);
		this.nodeStatement(children[i + 1]);
	}
}

ObjJCompiler.prototype.nodeStatement = function(/*SyntaxNode*/ astNode)
{
	var child = astNode.children[0],
        name = child ? child.name : null;

    switch(name)
    {
        case ObjJCompiler.AstNodeBlock:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeBlock(child);
			break;
        case ObjJCompiler.AstNodeVariableStatement:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeVariableStatement(child);
			break;
        case ObjJCompiler.AstNodeEmptyStatement:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeEmptyStatement(child);
			break;
        case ObjJCompiler.AstNodeExpressionStatement:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeExpressionStatement(child);
			break;
        case ObjJCompiler.AstNodeIfStatement:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeIfStatement(child);
			break;
        case ObjJCompiler.AstNodeIterationStatement:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeIterationStatement(child);
			break;
        case ObjJCompiler.AstNodeContinueStatement:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeContinueStatement(child);
			break;
        case ObjJCompiler.AstNodeBreakStatement:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeBreakStatement(child);
			break;
        case ObjJCompiler.AstNodeReturnStatement:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeReturnStatement(child);
			break;
        case ObjJCompiler.AstNodeWithStatement:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeWithStatement(child);
			break;
        case ObjJCompiler.AstNodeLabelledStatement:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeLabelledStatement(child);
			break;
        case ObjJCompiler.AstNodeSwitchStatement:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeSwitchStatement(child);
			break;
        case ObjJCompiler.AstNodeThrowStatement:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeThrowStatement(child);
			break;
        case ObjJCompiler.AstNodeTryStatement:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeTryStatement(child);
			break;
        case ObjJCompiler.AstNodeDebuggerStatement:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeDebuggerStatement(child);
			break;
        case ObjJCompiler.AstNodeFunctionDeclaration:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeFunctionDeclaration(child);
			break;
        case ObjJCompiler.AstNodeFunctionExpression:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeFunctionExpression(child);
			break;
        case ObjJCompiler.AstNodeImportStatement:
			this.nodeImportStatement(child);
			break;
        case ObjJCompiler.AstNodeClassDeclarationStatement:
			if (this._pass === 2)	// Skip this if it is the first pass
				this.nodeClassDeclationStatement(child);
			break;
        default:
			throw new SyntaxError(this.error_message("Expected node " + ObjJCompiler.AstNodeStatement + " but got " + child, child));
    }
}

ObjJCompiler.prototype.nodeBlock = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeBlock);
	var children = astNode.children;

	this.nodeOpenBrace(children[0]);
	this.nodeUnderline(children[1], false);
	var offset = 0;
	if (children.length === 5)
	{
		this.nodeStatementList(children[2]);
		offset++;
	}
	this.nodeUnderline(children[2 + offset], false);
	this.nodeCloseBrace(children[3 + offset]);
	// TODO: Handle BadBlock with missing close brace
}

ObjJCompiler.prototype.nodeVariableStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeVariableStatement);
	var children = astNode.children;

	this.nodeVAR(children[0]);
	this.nodeUnderline(children[1], true);
	this.nodeVariableDeclaration(children[2]);

	for (var i = 3; i + 3 < children.length; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeCOMMA(children[i + 1]);
		this.nodeUnderline(children[i + 2], false);
		this.nodeVariableDeclaration(children[i + 3]);
	}
	this.nodeEOS(children[i]);
}

ObjJCompiler.prototype.nodeVariableDeclaration = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeVariableDeclaration);
	var children = astNode.children,
		identifier = this.nodeIdentifier(children[0]);

	if (children.length === 5)
	{
		this.nodeUnderline(children[1], false);
		this.nodeEQUALS(children[2]);
		this.nodeUnderline(children[3], false);
		this.nodeAssignmentExpression(children[4]);
	}

	this.createLocalVariable({"identifier": identifier});
}

ObjJCompiler.prototype.nodeVariableDeclarationNoIn = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeVariableDeclarationNoIn);
	var children = astNode.children,
		identifier = this.nodeIdentifier(children[0]);

	if (children.length === 5)
	{
		this.nodeUnderline(children[1], false);
		this.nodeEQUALS(children[2]);
		this.nodeUnderline(children[3], false);
		this.nodeAssignmentExpressionNoIn(children[4]);
	}

	this.createLocalVariable({"identifier": identifier});
}

ObjJCompiler.prototype.nodeVariableDeclarationListNoIn = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeVariableDeclarationListNoIn);
	var children = astNode.children;

	this.nodeVariableDeclarationNoIn(children[0]);

	for (var i = 1; i + 3 < children.length; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeCOMMA(children[i + 1]);
		this.nodeUnderline(children[i + 2], false);
		this.nodeVariableDeclarationNoIn(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeEmptyStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeEmptyStatement);

	this.nodeWORD(astNode.children[0]);	// ";"
}

ObjJCompiler.prototype.nodeExpressionStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeExpressionStatement);
	var children = astNode.children;

	this.nodeExpression(children[0]);
	this.nodeEOS(children[1]);
}

ObjJCompiler.prototype.nodeIfStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeIfStatement);
	var children = astNode.children;

	this.nodeIF(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeOpenParenthesis(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeExpression(children[4]);
	this.nodeUnderline(children[5], false);
	this.nodeCloseParenthesis(children[6]);
	this.nodeUnderline(children[7], false);
	this.nodeStatement(children[8]);

	if (children.length === 13)
	{
		this.nodeUnderline(children[9], false);
		this.nodeELSE(children[10], false);
		this.nodeUnderline(children[11], true);
		this.nodeStatement(children[12]);
	}
}

ObjJCompiler.prototype.nodeIterationStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeIterationStatement);
	var child = astNode.children[0],
        name = child ? child.name : null;

    switch(name)
    {
        case ObjJCompiler.AstNodeDoWhileStatement:
			this.nodeDoWhileStatement(child);
			break;
        case ObjJCompiler.AstNodeWhileStatement:
			this.nodeWhileStatement(child);
			break;
        case ObjJCompiler.AstNodeForStatement:
			this.nodeForStatement(child);
			break;
        case ObjJCompiler.AstNodeForInStatement:
			this.nodeForInStatement(child);
			break;
        case ObjJCompiler.AstNodeEachStatement:
			this.nodeEachStatement(child);
			break;
        default:
			throw new SyntaxError(this.error_message("Expected node " + ObjJCompiler.AstNodeIterationStatement + " but got " + child, child));
    }
}

ObjJCompiler.prototype.nodeDoWhileStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeDoWhileStatement);
	var children = astNode.children;

	this.nodeDO(children[0]);
	this.nodeUnderline(children[1], true);
	this.nodeStatement(children[2]);
	this.nodeUnderline(children[3], true);
	this.nodeWHILE(children[4]);
	this.nodeUnderline(children[5], false);
	this.nodeOpenParenthesis(children[6]);
	this.nodeUnderline(children[7], false);
	this.nodeExpression(children[8]);
	this.nodeUnderline(children[9], false);
	this.nodeCloseParenthesis(children[10]);
	this.nodeEOS(children[11]);
}

ObjJCompiler.prototype.nodeWhileStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeWhileStatement);
	var children = astNode.children;

	this.nodeWHILE(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeOpenParenthesis(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeExpression(children[4]);
	this.nodeUnderline(children[5], false);
	this.nodeCloseParenthesis(children[6]);
	this.nodeUnderline(children[7], false);
	this.nodeStatement(children[8]);
}

ObjJCompiler.prototype.nodeForStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeForStatement);
	var children = astNode.children,
        child = children[4];

	this.nodeFOR(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeOpenParenthesis(children[2]);
	this.nodeUnderline(children[3], false);
	var offset = 0;
	if (!child || child.name !== ObjJCompiler.AstNodeUnderline)
	{
		this.nodeForFirstExpression(children[4]);
		offset++;
	}
	this.nodeUnderline(children[4 + offset], false);
	this.nodeWORD(children[5 + offset]);	// ";"
	this.nodeUnderline(children[6 + offset], false);
    child = children[7 + offset];
	if (!child || child.name !== ObjJCompiler.AstNodeUnderline)
	{
		this.nodeExpression(child);
		offset++;
	}
	this.nodeUnderline(children[7 + offset], false);
	this.nodeWORD(children[8 + offset]);	// ";"
	this.nodeUnderline(children[9 + offset], false);
    child = children[10 + offset];
	if (!child || child.name !== ObjJCompiler.AstNodeUnderline)
	{
		this.nodeExpression(children[10 + offset]);
		offset++;
	}
	this.nodeUnderline(children[10 + offset], false);
	this.nodeCloseParenthesis(children[11 + offset]);
	this.nodeUnderline(children[12 + offset], false);
	this.nodeStatement(children[13 + offset]);
}

ObjJCompiler.prototype.nodeForFirstExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeForFirstExpression);
	var children = astNode.children,
        child = children[0];

	if (child && child.name === ObjJCompiler.AstNodeVAR)
	{
		this.nodeVAR(child);
		this.nodeUnderline(children[1], true);
		this.nodeVariableDeclarationListNoIn(children[2]);
	}
	else
		this.nodeExpressionNoIn(children[0]);
}

ObjJCompiler.prototype.nodeForInStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeForInStatement);
	var children = astNode.children;

	this.nodeFOR(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeOpenParenthesis(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeForInFirstExpression(children[4]);
	this.nodeUnderline(children[5], true);
	this.nodeIN(children[6]);
	this.nodeUnderline(children[7], true);
	this.nodeExpression(children[8]);	// ";"
	this.nodeUnderline(children[9], false);
	this.nodeCloseParenthesis(children[10]);
	this.nodeUnderline(children[11], false);
	this.nodeStatement(children[12]);
}

ObjJCompiler.prototype.nodeForInFirstExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeForInFirstExpression);
	var children = astNode.children,
        child = children[0];

	if (child && child.name === ObjJCompiler.AstNodeVAR)
	{
		this.nodeVAR(child);
		this.nodeUnderline(children[1], true);
		this.nodeVariableDeclarationNoIn(children[2]);
	}
	else
		this.nodeLeftHandSideExpression(child);
}

ObjJCompiler.prototype.nodeEachStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeEachStatement);
	var children = astNode.children;

	this.nodeEACH(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeOpenParenthesis(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeForInFirstExpression(children[4]);
	this.nodeUnderline(children[5], true);
	this.nodeIN(children[6]);
	this.nodeUnderline(children[7], true);
	this.nodeExpression(children[8]);	// ";"
	this.nodeUnderline(children[9], false);
	this.nodeCloseParenthesis(children[10]);
	this.nodeUnderline(children[11], false);
	this.nodeStatement(children[12]);
}

ObjJCompiler.prototype.nodeContinueStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeContinueStatement);
	var children = astNode.children,
        child = children[2];

	this.nodeCONTINUE(children[0]);
	this.nodeUnderlineNoLineBreak(children[1], false);
	if (child && child.name === ObjJCompiler.AstNodeIdentifier)
	{
		this.nodeIdentifier(child);
		this.nodeEOS(children[3]);
	}
	else
		this.nodeSemicolonInsertionEOS(children[2]);
}

ObjJCompiler.prototype.nodeBreakStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeBreakStatement);
	var children = astNode.children,
        child = children[2];

	this.nodeBREAK(children[0]);
	this.nodeUnderlineNoLineBreak(children[1], false);
	if (child && child.name === ObjJCompiler.AstNodeIdentifier)
	{
		this.nodeIdentifier(child);
		this.nodeEOS(children[3]);
	}
	else
		this.nodeSemicolonInsertionEOS(children[2]);
}

ObjJCompiler.prototype.nodeReturnStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeReturnStatement);
	var children = astNode.children,
        child = children[2];

	this.nodeRETURN(children[0]);
	this.nodeUnderlineNoLineBreak(children[1], false);
	if (child && child.name === ObjJCompiler.AstNodeExpression)
	{
		this.nodeExpression(child);
		this.nodeEOS(children[3]);
	}
	else
		this.nodeSemicolonInsertionEOS(child);
}

ObjJCompiler.prototype.nodeWithStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeWithStatement);
	var children = astNode.children;

	this.nodeWITH(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeOpenParenthesis(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeExpression(children[4]);
	this.nodeUnderline(children[5], true);
	this.nodeCloseParenthesis(children[6]);
	this.nodeUnderline(children[7], false);
	this.nodeStatement(children[8]);
}

ObjJCompiler.prototype.nodeSwitchStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSwitchStatement);
	var children = astNode.children;

	this.nodeSWITCH(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeOpenParenthesis(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeExpression(children[4]);
	this.nodeUnderline(children[5], true);
	this.nodeCloseParenthesis(children[6]);
	this.nodeUnderline(children[7], false);
	this.nodeCaseBlock(children[8]);
}

ObjJCompiler.prototype.nodeCaseBlock = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeCaseBlock);
	var children = astNode.children,
        child = children[2];

	this.nodeOpenBrace(children[0]);
	this.nodeUnderline(children[1], false);
	var offset = 0;
	if (child && child.name === ObjJCompiler.AstNodeCaseClauses)
	{
		this.nodeCaseClauses(child);
		offset++;
	}
	this.nodeUnderline(children[2 + offset], false);
    child = children[3 + offset];
	if (child && child.name === ObjJCompiler.AstNodeDefaultClause)
	{
		this.nodeDefaultClause(child);
		offset++;
	}
	this.nodeUnderline(children[3 + offset], false);
    child = children[4 + offset];
	if (child && child.name === ObjJCompiler.AstNodeCaseClauses)
	{
		this.nodeCaseClauses(child);
		offset++;
	}
	this.nodeUnderline(children[4 + offset], false);
	this.nodeCloseBrace(children[5 + offset]);
}

ObjJCompiler.prototype.nodeCaseClauses = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeCaseClauses);
	var children = astNode.children;

	this.nodeCaseClause(children[0]);

	for (var i = 1; i + 1 < children.length; i += 2)
	{
		this.nodeUnderline(children[i], false);
		this.nodeCaseClause(children[i + 1]);
	}
}

ObjJCompiler.prototype.nodeCaseClause = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeCaseClause);
	var children = astNode.children,
        child = children[5];

	this.nodeCASE(children[0]);
	this.nodeUnderline(children[1], true);
	this.nodeExpression(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeCOLON(children[4]);
	if (child && child.name === ObjJCompiler.AstNodeUnderline)
	{
		this.nodeUnderline(child, false);
		this.nodeStatementList(children[6]);
	}
}

ObjJCompiler.prototype.nodeDefaultClause = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeDefaultClause);
	var children = astNode.children,
        child = children[3];

	this.nodeDEFAULT(children[0]);
	this.nodeUnderline(children[1], true);
	this.nodeCOLON(children[2]);
	if (child && child.name === ObjJCompiler.AstNodeUnderline)
	{
		this.nodeUnderline(child, false);
		this.nodeStatementList(children[4]);
	}
}

ObjJCompiler.prototype.nodeLabelledStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeLabelledStatement);
	var children = astNode.children;

	this.nodeIdentifier(children[0]);
	this.nodeUnderline(children[1], true);
	this.nodeCOLON(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeStatementList(children[4]);
}

ObjJCompiler.prototype.nodeThrowStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeThrowStatement);
	var children = astNode.children,
        child = children[2];

	this.nodeTHROW(children[0]);
	this.nodeUnderlineNoLineBreak(children[1], false);
	if (child && child.name === ObjJCompiler.AstNodeExpression)
	{
		this.nodeExpression(child);
		this.nodeEOS(children[3]);
	}
	else
		this.nodeSemicolonInsertionEOS(children[2]);
}

ObjJCompiler.prototype.nodeTryStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeTryStatement);
	var children = astNode.children,
        child = children[4];

	this.nodeTRY(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeBlock(children[2]);
	this.nodeUnderline(children[3], false);
	if (child && child.name === ObjJCompiler.AstNodeCatch)
	{
		this.nodeCatch(child);
        child = children[5];
		if (child && child.name === ObjJCompiler.AstNodeFinally)
		{
			this.nodeFinally(child);
		}
	}
	else
		this.nodeFinally(child);
}

ObjJCompiler.prototype.nodeCatch = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeCatch);
	var children = astNode.children;

	this.nodeCATCH(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeOpenParenthesis(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeIdentifier(children[4]);
	this.nodeUnderline(children[5], false);
	this.nodeCloseParenthesis(children[6]);
	this.nodeUnderline(children[7], false);
	this.nodeBlock(children[8]);
}

ObjJCompiler.prototype.nodeFinally = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeFinally);
	var children = astNode.children;

	this.nodeFINALLY(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeBlock(children[2]);
}

ObjJCompiler.prototype.nodeDebuggerStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeDebuggerStatement);
	var children = astNode.children;

	this.nodeDEBUGGER(children[0]);
	this.nodeEOS(children[1]);
}

ObjJCompiler.prototype.nodeImportStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeImportStatement);
	var children = astNode.children,
        child = children[2],
        isQuoted = null,
        urlString = null,
        saveJSBuffer = this._jsBuffer;

    this._jsBuffer = null;
	this.nodeIMPORT(children[0]);
	this.nodeUnderline(children[1], false);
	if (child && child.name === ObjJCompiler.AstNodeLocalFilePath)
    {
		urlString = this.nodeLocalFilePath(child);
        isQuoted = true;
    }
	else
    {
		urlString = this.nodeStandardFilePath(children[2]);
        isQuoted = false;
    }
	this.nodeEOS(children[3]);

	if (saveJSBuffer)
	{
    	CONCAT(saveJSBuffer, "objj_executeFile(\"");
    	CONCAT(saveJSBuffer, urlString);
    	CONCAT(saveJSBuffer, isQuoted ? "\", YES);" : "\", NO);");
	}
    
    this._dependencies.push(new FileDependency(new CFURL(urlString), isQuoted));
    this._jsBuffer = saveJSBuffer;
}

ObjJCompiler.prototype.nodeLocalFilePath = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeLocalFilePath);

	return this.nodeStringLiteral(astNode.children[0]);
}

ObjJCompiler.prototype.nodeStandardFilePath = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeStandardFilePath);
	var children = astNode.children,
		size = children.length,
        string = "";

	this.nodeLESSTHEN(children[0]);
	this.nodeUnderline(children[1], false);
	for (var i = 2; i < size - 2; i++)
	{
		string += this.nodeWORD(children[i]);
	}
	this.nodeUnderline(children[size - 2], false);
	this.nodeGREATERTHEN(children[size - 1]);

    return string;
}

ObjJCompiler.prototype.nodeClassDeclationStatement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeClassDeclarationStatement);
	var children = astNode.children,
        child = children[4],
		offset = 0,
        saveJSBuffer = this._jsBuffer,          // Save the javascript buffer
        saveObjJBuffer = this._objJBuffer,      // Save the objJ buffer
        classBodyBuffer = new StringBuffer();   // Create a buffer for javascript statements and functions inside the class declaration

    // Make sure nothing is copied to the javascript buffer
    this._jsBuffer = null;
    // Crate an objJ buffer if we need to create accessors
    this._objJBuffer = new StringBuffer();

	this.nodeIMPLEMENTATION(children[0]);
	this.nodeUnderline(children[1], true);

	var className = this.nodeIdentifier(children[2]),
		superClassName = null,
		classDef = null,
		isCategoryDeclaration = false;

	this.nodeUnderline(children[3], false);

	if (child && child.name === ObjJCompiler.AstNodeSuperclassDeclaration)
	{
		superClassName = this.nodeSuperclassDeclaration(child);
		offset++;

		if (this.getClassDef(className))
			throw new SyntaxError(this.error_message("Duplicate class " + className, children[2]));
		if (!this.getClassDef(superClassName))
				throw new SyntaxError(this.error_message("Can't find superclass " + superClassName, child));

		classDef = {"className": className, "superClassName": superClassName, "ivars": {}, "methods": {}};

		this._classDefs[className] = classDef;

		if (saveJSBuffer)
        	CONCAT(saveJSBuffer, "{var the_class = objj_allocateClassPair(" + superClassName + ", \"" + className + "\"),\nmeta_class = the_class.isa;");
	}
	else if (child && child.name === ObjJCompiler.AstNodeCategoryDeclaration)
	{
		isCategoryDeclaration = true;
		this.nodeCategoryDeclaration(child);
		offset++;

		classDef = this.getClassDef(className);
		if (!classDef)
			throw new SyntaxError(this.error_message("Class " + className + " not found ", children[2]));

		if (saveJSBuffer)
		{
        	CONCAT(saveJSBuffer, "{\nvar the_class = objj_getClass(\"" + className + "\")\n");
        	CONCAT(saveJSBuffer, "if(!the_class) throw new SyntaxError(\"*** Could not find definition for class \\\"" + className + "\\\"\");\n");
        	CONCAT(saveJSBuffer, "var meta_class = the_class.isa;");
		}
	}
	else
	{
		classDef = {"className": className, "superClassName": null, "ivars": {}, "methods": {}};

		this._classDefs[className] = classDef;

		if (saveJSBuffer)
        	CONCAT(saveJSBuffer, "{var the_class = objj_allocateClassPair(Nil, \"" + className + "\"),\nmeta_class = the_class.isa;");
	}

    this._currentSuperClass = "objj_getClass(\"" + className + "\").super_class";
    this._currentSuperMetaClass = "objj_getMetaClass(\"" + className + "\").super_class";

	this.nodeUnderline(children[4 + offset], false);
	this._imBuffer = new StringBuffer();
	this._cmBuffer = new StringBuffer();
	this._classBodyBuffer = new StringBuffer();
    child = children[5 + offset];
    
	if (!child || child.name !== ObjJCompiler.AstNodeUnderline)
	{
		this.nodeOpenBrace(child);
        offset++;
		var firstIvarDeclaration = true,
			ivars = classDef.ivars,
            hasAccessors = false;

        child = children[6 + offset];

		while (child && child.name === ObjJCompiler.AstNodeCompoundIvarDeclaration)
		{
			this.nodeUnderline(children[5 + offset++], false);

			var ivarDeclaration = this.nodeCompoundIvarDeclaration(child, ivars),   // This will save the declaration in ivars and return the declaration.
				type = ivarDeclaration.type;

			for (var name in ivarDeclaration.ivars)
			{
				if (firstIvarDeclaration)
				{
					firstIvarDeclaration = false;
					if (saveJSBuffer)
	            		CONCAT(saveJSBuffer, "class_addIvars(the_class, [");
				}
				else
					if (saveJSBuffer)
	            		CONCAT(saveJSBuffer, ", ");

				if (saveJSBuffer)
	            	if (this._flags & ObjJCompiler.Flags.IncludeTypeSignatures)
	                	CONCAT(saveJSBuffer, "new objj_ivar(\"" + name + "\", \"" + type + "\")");
	            	else
	                	CONCAT(saveJSBuffer, "new objj_ivar(\"" + name + "\")");

                if (!hasAccessors && ivarDeclaration.ivars[name].accessors)
                    hasAccessors = true;
			}

            child = children[6 + ++offset];
		}
		if (!firstIvarDeclaration)
			if (saveJSBuffer)
				CONCAT(saveJSBuffer, "]);\n");

		this.nodeUnderline(children[5 + offset++], false);
		this.nodeCloseBrace(children[5 + offset++]);

        if (hasAccessors)
        {
            var getterSetterBuffer = new StringBuffer();

            // Add the class declaration to compile accessors correctly
            CONCAT(getterSetterBuffer, this._objJBuffer);
            CONCAT(getterSetterBuffer, "\n");

            for (var name in ivars)
            {
                var ivarDecl = ivars[name],
                    type = ivarDecl.type,
                    accessors = ivarDecl.accessors;

                if (!accessors)
                    continue;

                var property = accessors["property"] || name,
                    getterName = accessors["getter"] || property,
                getterCode = "- (" + (type ? type : "id") + ")" + getterName + "\n{\nreturn " + name + ";\n}\n";

                CONCAT(getterSetterBuffer, getterCode);

                if (accessors["readonly"])
                    continue;

                var setterName = accessors["setter"];

                if (!setterName)
                {
                    var start = property.charAt(0) == '_' ? 1 : 0;
                    setterName = (start ? "_" : "") + "set" + property.substr(start, 1).toUpperCase() + property.substring(start + 1) + ":";
                }

                var setterCode = "- (void)" + setterName + "(" + (type ? type : "id") +  ")newValue\n{\n";

                if (accessors["copy"])
                    setterCode += "if (" + name + " !== newValue)\n" + name + " = [newValue copy];\n}\n";
                else
                    setterCode += name + " = newValue;\n}\n";

                CONCAT(getterSetterBuffer, setterCode);
            }

            CONCAT(getterSetterBuffer, "\n@end");
            // Remove all @accessors or we will get a recursive loop in infinity
            var b = getterSetterBuffer.toString().replace(/@accessors(\(.*\))?/g, "");
            var imBuffer = exports.compileToIMBuffer(b, "getter", this._flags);

            CONCAT(this._imBuffer, imBuffer);
        }
	}
	this.nodeUnderline(children[5 + offset], false);
	this._currentClassDef = classDef;

	this._jsBuffer = classBodyBuffer;
	this.nodeClassBody(children[6 + offset]);	
	this._currentClassDef = null;
	this._jsBuffer = null;
    
	this.nodeUnderline(children[7 + offset], false);
	this.nodeEND(children[8 + offset]);
	this.nodeEOS(children[9 + offset]);

	if (saveJSBuffer)
	{
	    // We must make a new class object for our class definition.
		if (!isCategoryDeclaration) {
            CONCAT(saveJSBuffer, "objj_registerClassPair(the_class);\n");
        }

    	if (IS_NOT_EMPTY(this._imBuffer))
    	{
        	CONCAT(saveJSBuffer, "class_addMethods(the_class, [");
        	CONCAT(saveJSBuffer, this._imBuffer);
        	CONCAT(saveJSBuffer, "]);\n");
    	}

    	if (IS_NOT_EMPTY(this._cmBuffer))
    	{
        	CONCAT(saveJSBuffer, "class_addMethods(meta_class, [");
        	CONCAT(saveJSBuffer, this._cmBuffer);
        	CONCAT(saveJSBuffer, "]);\n");
    	}

    	CONCAT(saveJSBuffer, "}");

	// FIXME: Maybe we should add this before we add the class implementation?
	//		  We might have variable/function declarations etc that is needed before class declaration?
	//		  Maybe not? Needs some investigation....
    	CONCAT(saveJSBuffer, this._classBodyBuffer);
	}
    // Restore javascript buffer
	this._jsBuffer = saveJSBuffer;
    // Restore objJ buffer
    if (saveObjJBuffer)
        CONCAT(saveObjJBuffer, this._objJBuffer);
	this._objJBuffer = saveObjJBuffer;
}

ObjJCompiler.prototype.nodeSuperclassDeclaration = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSuperclassDeclaration);
	var children = astNode.children;

	this.nodeCOLON(children[0]);
	this.nodeUnderline(children[1], false);
	return this.nodeIdentifier(children[2]);
}

ObjJCompiler.prototype.nodeCategoryDeclaration = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeCategoryDeclaration);
	var children = astNode.children;

	this.nodeOpenParenthesis(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeIdentifier(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeCloseParenthesis(children[4]);
}

ObjJCompiler.prototype.nodeCompoundIvarDeclaration = function(/*SyntaxNode*/ astNode, classDefIvars)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeCompoundIvarDeclaration);
	var children = astNode.children,
		type = this.nodeIvarType(children[0]);

	this.nodeUnderline(children[1], true);
	var ivar = this.nodeIvarDeclaration(children[2]),
        ivars = {};

    ivars[ivar.identifier] = ivar;
    classDefIvars[ivar.identifier] = {"type": type, "name": ivar.identifier, "accessors": ivar.accessors};
	for (var i = 3; i + 3 < children.length; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeWORD(children[i + 1]);	// ","
		this.nodeUnderline(children[i + 2], false);
		ivar = this.nodeIvarDeclaration(children[i + 3]);
		if (classDefIvars[ivar.identifier])	// FIXME: Must look at classes not in this file
			throw new SyntaxError(this.error_message("Duplicate member " + ivar.identifier, children[i + 3]));
		ivars[ivar.identifier] = ivar;
		classDefIvars[ivar.identifier] = {"type": type, "name": ivar.identifier, "accessors": ivar.accessors};
	}
	this.nodeEOS(children[i]);
	return {"type": type, "ivars": ivars};
}

// This grammar is not correct. You should not be able to have multiple IvarTypeElement.
// Maybe should be one type element and one extra @outlet? Or something......
// IvarType =
//    IvarTypeElement (_ IvarTypeElement)*

ObjJCompiler.prototype.nodeIvarType = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeIvarType);
	var children = astNode.children,
		type = "";

	var newType = this.nodeIvarTypeElement(children[0]);
	// Maybe we should return the outlet information and save it along the ivars for the class....
	if (newType !== "@outlet")
		type = newType;

	for (var i = 1; i + 1 < children.length; i += 2)
	{
		this.nodeUnderline(children[i], false);
		newType = this.nodeIvarTypeElement(children[i + 1]);
		// Maybe we should return the outlet information and save it along the ivars for the class....
		if (newType !== "@outlet")
			type += " " + newType;
	}

    return type;
}

ObjJCompiler.prototype.nodeIvarTypeElement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeIvarTypeElement);
	var children = astNode.children,
        child = children[0];

	if (child && child.name === ObjJCompiler.AstNodeIdentifierName)
		return this.nodeIdentifierName(child);
	else
		return this.nodeOUTLET(child);
}

ObjJCompiler.prototype.nodeIvarDeclaration = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeIvarDeclaration);
	var children = astNode.children,
        child = children[2],
        ivar = {};

	ivar.identifier = this.nodeIdentifier(children[0]);
	this.nodeUnderline(children[1], false);

	if (child && child.name === ObjJCompiler.AstNodeAccessors)
		ivar.accessors = this.nodeAccessors(child);
	return ivar;
}

ObjJCompiler.prototype.nodeAccessors = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeAccessors);
	var children = astNode.children,
		size = children.length,
		accessors = {};

	this.nodeACCESSORS(children[0]);
	if (size > 1)
	{
		this.nodeOpenParenthesis(children[1]);
		var offset = 0,
            child = children[2];
		if (child && child.name === ObjJCompiler.AstNodeAccessorsConfiguration)
		{
			accessors = this.nodeAccessorsConfiguration(child);
            child = children[2 + ++offset]
			while (child && child.name === ObjJCompiler.AstNodeUnderline)
			{
				this.nodeUnderline(children[2 + offset++], false);
				this.nodeWORD(children[2 + offset++]);	// ","
				this.nodeUnderline(children[2 + offset++], false);
				var moreAccessors = this.nodeAccessorsConfiguration(children[2 + offset++]);
				for (var attrname in moreAccessors)			// Clang takes the last if many exists so just Merge in moreAccessors
					accessors[attrname] = moreAccessors[attrname];
                child = children[2 + offset];
			}
		}
		this.nodeCloseParenthesis(child);
	}
	return accessors;
}

ObjJCompiler.prototype.nodeAccessorsConfiguration = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeAccessorsConfiguration);
	var child = astNode.children[0],
        name = child ? child.name : null;

    switch(name)
    {
        case ObjJCompiler.AstNodeIvarPropertyName:
			return {"property": this.nodeIvarPropertyName(child)};
        case ObjJCompiler.AstNodeIvarGetterName:
			return {"getter": this.nodeIvarGetterName(child)};
        case ObjJCompiler.AstNodeIvarSetterName:
			return {"setter": this.nodeIvarSetterName(child)};
        default:
            // Here we accept anything the parser accepts: "readonly", "copy" or "readwrite"
			this.nodeWORD(child);
            var r = {};
            r[child] = true;
			return r;
    }
}

ObjJCompiler.prototype.nodeIvarPropertyName = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeIvarPropertyName);
	var children = astNode.children;

	this.nodePROPERTY(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeEQUALS(children[2]);
	this.nodeUnderline(children[3], false);
	return this.nodeIdentifier(children[4]);
}

ObjJCompiler.prototype.nodeIvarGetterName = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeIvarGetterName);
	var children = astNode.children;

	this.nodeGETTER(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeEQUALS(children[2]);
	this.nodeUnderline(children[3], false);
	return this.nodeIdentifier(children[4]);
}

ObjJCompiler.prototype.nodeIvarSetterName = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeIvarSetterName);
	var children = astNode.children;

	this.nodeSETTER(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeEQUALS(children[2]);
	this.nodeUnderline(children[3], false);
	var setterName = this.nodeIdentifier(children[4]);

	// I think the grammar is wrong here! You should always include the colon.
	// IvarSetterName =
	//   "setter" _ "=" _ Identifier (_ ":")?
	
	if (children.length > 6)
	{
		this.nodeUnderline(children[5], false);
		setterName += this.nodeCOLON(children[6]);
	}
	else
	{
		setterName += ":";
	}

	return setterName;
}

ObjJCompiler.prototype.nodeClassBody = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeClassBody);
	var child = astNode.children[0];

    if (child && child.name === ObjJCompiler.AstNodeClassElements)
		this.nodeClassElements(child);
}

ObjJCompiler.prototype.nodeClassElements = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeClassElements);
	var children = astNode.children;

	this.nodeClassElement(children[0]);

	for (var i = 1; i + 1 < children.length; i += 2)
	{
		this.nodeUnderline(children[i], false);
		this.nodeClassElement(children[i + 1]);
	}
}

ObjJCompiler.prototype.nodeClassElement = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeClassElement);
	var child = astNode.children[0],
        name = child ? child.name : null;

    switch(name)
    {
        case ObjJCompiler.AstNodeClassMethodDeclaration:
			this.nodeClassMethodDeclaration(child);
			break;
        case ObjJCompiler.AstNodeInstanceMethodDeclaration:
			this.nodeInstanceMethodDeclaration(child);
			break;
        case ObjJCompiler.AstNodeStatement:
			this._jsBuffer = this._classBodyBuffer;
			this.nodeStatement(child);
			this._jsBuffer = null;
			break;
	    case ObjJCompiler.AstNodeFunctionDeclaration:
			this._jsBuffer = this._classBodyBuffer;
			this.nodeFunctionDeclaration(child);
			this._jsBuffer = null;
			break;
        default:
			throw new SyntaxError(this.error_message("Expected node " + ObjJCompiler.AstNodeClassElement + " but got " + child, child));
			break;
    }
}

ObjJCompiler.prototype.nodeClassMethodDeclaration = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeClassMethodDeclaration);
	this.nodePLUS(astNode.children[0]);
    this._classMethod = true;
	this.genericMethodDeclaration(astNode, this._cmBuffer);
}

ObjJCompiler.prototype.nodeInstanceMethodDeclaration = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeInstanceMethodDeclaration);
	this.nodeMINUS(astNode.children[0]);
    this._classMethod = false;
	this.genericMethodDeclaration(astNode, this._imBuffer);
}

ObjJCompiler.prototype.genericMethodDeclaration = function(/*SyntaxNode*/ astNode, /*StringBuffer*/ buffer)
{
	var children = astNode.children,
        child = children[2],
		offset = 0,
		returnTypes = [null],
		classDef = this._currentClassDef,
		currentClassMethods = classDef ? classDef.methods : null;

	if (child && child.name === ObjJCompiler.AstNodeMethodType)
	{
		this.nodeUnderline(children[1 + offset++], false);
		returnTypes = this.nodeMethodType(children[1 + offset++]);
	}
	this.nodeUnderline(children[1 + offset], false);
	var methodSelector = this.nodeMethodSelector(children[2 + offset]),
		selector = methodSelector.selector,
		types = [returnTypes[0]];		// First type is return type? We might handle only one type? The grammar MethodType can be many types

    if (IS_NOT_EMPTY(buffer))           // Add comma separator if this is not first method in this buffer
        CONCAT(buffer, ", ");
    CONCAT(buffer, "new objj_method(sel_getUid(\"");
    CONCAT(buffer, selector);
    CONCAT(buffer, "\"), function");

//    this._currentSelector = selector;

    if (this._flags & ObjJCompiler.Flags.IncludeDebugSymbols)
	{
        CONCAT(buffer, " $" + this._currentClassDef.className + "__" + selector.replace(/:/g, "_"));
	}

    CONCAT(buffer, "(self, _cmd");

	for (var identifier in methodSelector.parameters)
	{
		var parameter = methodSelector.parameters[identifier];

        CONCAT(buffer, ", ");
        CONCAT(buffer, parameter.identifier);
		types.push(parameter.type);
	}

	if (currentClassMethods)
	{
		var currentMethodSelector = currentClassMethods[methodSelector.selector];
		if (currentMethodSelector)
		{
			// Method already declared. May be a warning?
		}
		currentClassMethods[methodSelector.selector] = methodSelector;
		this._currentMethod = methodSelector;
	}

    CONCAT(buffer, ")\n{\n");

	this.nodeUnderline(children[3 + offset], false);

    child = children[4 + offset];
	if (child && child.name !== ObjJCompiler.AstNodeUnderline)
	{
		this.nodeSEMICOLON(children[4 + offset++]);
	}
	this.nodeUnderline(children[4 + offset], false);
	this.nodeOpenBrace(children[5 + offset]);
	this.nodeUnderline(children[6 + offset], false);
	this._jsBuffer = buffer;	// Now write the FunctionBody to buffer
	this.nodeFunctionBody(children[7 + offset]);
	this._jsBuffer = null;			// Turn back off again so nothing is written
	this.nodeUnderline(children[8 + offset], false);
	this.nodeCloseBrace(children[9 + offset]);
    CONCAT(buffer, "}\n");
    if (this._flags & ObjJCompiler.Flags.IncludeDebugSymbols) //flags.IncludeTypeSignatures)
        CONCAT(buffer, ","+JSON.stringify(types));
    CONCAT(buffer, ")");

	this._currentMethod = null;
}

ObjJCompiler.prototype.nodeMethodSelector = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeMethodSelector);
	var children = astNode.children,
        child = children[0],
		size = children.length;

	if (child && child.name === ObjJCompiler.AstNodeKeywordSelector)
	{
		var keywordSelector = this.nodeKeywordSelector(child);
		if (size > 1)
		{
			this.nodeUnderline(children[1], false);
			this.nodeCOMMA(children[2]);
			this.nodeUnderline(children[3], false);
			// FIXME: Handle argument list. If we need to?
			this.nodeWORD(children[4]);	// ...
		}
		return keywordSelector;
	}
	else
		return {"selector": this.nodeUnarySelector(child)};
}

ObjJCompiler.prototype.nodeUnarySelector = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeUnarySelector);
	return this.nodeSelector(astNode.children[0]);
}

ObjJCompiler.prototype.nodeKeywordSelector = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeKeywordSelector);
	var children = astNode.children,
		keywordDecl = this.nodeKeywordDeclarator(children[0]),
        typeAndIndentifier = {"type": keywordDecl.methodType, "identifier": keywordDecl.identifier},
        keywordSelector = {"selector": keywordDecl.selector, "parameters":{}};

    keywordSelector.parameters[keywordDecl.identifier] = typeAndIndentifier;

	for (var i = 1; i + 1 < children.length; i += 2)
	{
		this.nodeUnderline(children[i], false);
		var nextKeywordDecl = this.nodeKeywordDeclarator(children[i + 1]);

		keywordSelector.selector += nextKeywordDecl.selector;
		keywordSelector.parameters[nextKeywordDecl.identifier] = {"type": nextKeywordDecl.methodType, "identifier": nextKeywordDecl.identifier};
	}
	return keywordSelector;
}

ObjJCompiler.prototype.nodeKeywordDeclarator = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeKeywordDeclarator);
	var children = astNode.children,
        child = children[0],
		offset = 0,
		selector = "",
		methodType = null;

	if (child && child.name === ObjJCompiler.AstNodeSelector)
	{
		selector = this.nodeSelector(children[0 + offset++]);
		this.nodeUnderline(children[0 + offset++], false);
	}

	this.nodeCOLON(children[0 + offset]);
	selector += ":";
    child = children[2 + offset];

	if (child && child.name === ObjJCompiler.AstNodeMethodType)
	{
		this.nodeUnderline(children[1 + offset++], false);
		// TODO: Parser allows multiple MethodType. Need to find out what to do if we get more then one
		methodType = this.nodeMethodType(children[1 + offset++])[0];
	}

	this.nodeUnderline(children[1 + offset], false);
	var identifier = this.nodeIdentifier(children[2 + offset]);

	return {"selector": selector, "methodType": methodType, "identifier": identifier};
}

ObjJCompiler.prototype.nodeSelector = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSelector);
	return this.nodeIdentifierName(astNode.children[0]);
}

ObjJCompiler.prototype.nodeMethodType = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeMethodType);
	var children = astNode.children,
        child = children[2],
		size = children.length,
		methodTypes = [],
        offset = 3;

	this.nodeOpenParenthesis(children[0]);
	this.nodeUnderline(children[1], false);

	if (child && child.name === ObjJCompiler.AstNodeACTION)
		methodTypes.push(this.nodeACTION(child));
	else
    {
		methodTypes.push(this.nodeIdentifierName(child));
        if (children[4] === "<")
        {
            this.nodeUnderline(children[3], false);
            this.nodeWORD(children[4]);     // "<"
            this.nodeUnderline(children[5], false);
            this.nodeIdentifierName(children[6]);
            this.nodeUnderline(children[7], false);
            this.nodeWORD(children[8]);      // ">"
            offset += 6;
        }
    }

	for (var i = offset; i + 1 < size - 2; i += 2)
	{
		this.nodeUnderline(children[i], true);
        child = children[i + 1];
		if (child && child.name === ObjJCompiler.AstNodeACTION)
			methodTypes.push(this.nodeACTION(child));
		else
        {
			methodTypes.push(this.nodeIdentifierName(child));
            if (i + 7 < size && children[i + 3] === "<")
            {
                this.nodeUnderline(children[i++ + 2], false);
                this.nodeWORD(children[i++ + 2]);      // "<"
                this.nodeUnderline(children[i++ + 2], false);
                this.nodeIdentifierName(children[i++ + 2]);
                this.nodeUnderline(children[i++ + 2], false);
                this.nodeWORD(children[i++ + 2]);       // ">"
            }
        }
	}

	this.nodeUnderline(children[size - 2], false);
	this.nodeCloseParenthesis(children[size - 1]);
	return methodTypes;
}

ObjJCompiler.prototype.nodeACTION = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeACTION);
	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeExpression);
	var children = astNode.children,
		size = children.length;

	this.nodeAssignmentExpression(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeWORD(children[i + 1]);	// ","
		this.nodeUnderline(children[i + 2], false);
		this.nodeAssignmentExpression(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeExpressionNoIn = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeExpressionNoIn);
	var children = astNode.children,
		size = children.length;

	this.nodeAssignmentExpressionNoIn(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeWORD(children[i + 1]);	// ","
		this.nodeUnderline(children[i + 2], false);
		this.nodeAssignmentExpressionNoIn(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeAssignmentExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeAssignmentExpression);
	var children = astNode.children,
        child = children[0];

	if (child && child.name === ObjJCompiler.AstNodeLeftHandSideExpression)
	{
		this.nodeLeftHandSideExpression(child);
		this.nodeUnderline(children[1], false);
		this.nodeAssignmentOperator(children[2]);
		this.nodeUnderline(children[3], false);
		this.nodeAssignmentExpression(children[4]);
	}
	else
		this.nodeConditionalExpression(child);
}

ObjJCompiler.prototype.nodeAssignmentExpressionNoIn = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeAssignmentExpressionNoIn);
	var children = astNode.children,
        child = children[0];

	if (child && child.name === ObjJCompiler.AstNodeLeftHandSideExpression)
	{
		this.nodeLeftHandSideExpression(child);
		this.nodeUnderline(children[1], false);
		this.nodeAssignmentOperator(children[2]);
		this.nodeUnderline(children[3], false);
		this.nodeAssignmentExpressionNoIn(children[4]);
	}
	else
		this.nodeConditionalExpressionNoIn(child);
}

ObjJCompiler.prototype.nodeAssignmentOperator = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeAssignmentOperator);
	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeConditionalExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeConditionalExpression);
	var children = astNode.children,
        child = children[1];

	this.nodeLogicalOrExpression(children[0]);
	if (child && child.name === ObjJCompiler.AstNodeUnderline)
    {
		this.nodeUnderline(child, false);
		this.nodeWORD(children[2]);				// "?"
		this.nodeUnderline(children[3], false);
		this.nodeAssignmentExpression(children[4]);
		this.nodeUnderline(children[5], false);
		this.nodeWORD(children[6]);				// ":"
		this.nodeUnderline(children[7], false);
		this.nodeAssignmentExpression(children[8]);
	}
}

ObjJCompiler.prototype.nodeConditionalExpressionNoIn = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeConditionalExpressionNoIn);
	var children = astNode.children,
        child = children[1];

	this.nodeLogicalOrExpressionNoIn(children[0]);
	if (child && child.name === ObjJCompiler.AstNodeUnderline)
    {
		this.nodeUnderline(child, false);
		this.nodeWORD(children[2]);				// "?"
		this.nodeUnderline(children[3], false);
		this.nodeAssignmentExpressionNoIn(children[4]);
		this.nodeUnderline(children[5], false);
		this.nodeWORD(children[6]);				// ":"
		this.nodeUnderline(children[7], false);
		this.nodeAssignmentExpressionNoIn(children[8]);
	}
}

ObjJCompiler.prototype.nodeLogicalOrExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeLogicalOrExpression);
	var children = astNode.children,
		size = children.length;

	this.nodeLogicalAndExpression(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeWORD(children[i + 1]);	// "||"
		this.nodeUnderline(children[i + 2], false);
		this.nodeLogicalAndExpression(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeLogicalOrExpressionNoIn = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeLogicalOrExpressionNoIn);
	var children = astNode.children,
		size = children.length;

	this.nodeLogicalAndExpressionNoIn(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeWORD(children[i + 1]);	// "||"
		this.nodeUnderline(children[i + 2], false);
		this.nodeLogicalAndExpressionNoIn(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeLogicalAndExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeLogicalAndExpression);
	var children = astNode.children,
		size = children.length;

	this.nodeBitwiseOrExpression(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeWORD(children[i + 1]);	// "&&"
		this.nodeUnderline(children[i + 2], false);
		this.nodeBitwiseOrExpression(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeLogicalAndExpressionNoIn = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeLogicalAndExpressionNoIn);
	var children = astNode.children,
		size = children.length;

	this.nodeBitwiseOrExpressionNoIn(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeWORD(children[i + 1]);	// "&&"
		this.nodeUnderline(children[i + 2], false);
		this.nodeBitwiseOrExpressionNoIn(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeBitwiseOrExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeBitwiseOrExpression);
	var children = astNode.children,
		size = children.length;

	this.nodeBitwiseXOrExpression(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeWORD(children[i + 1]);	// "|"
		this.nodeUnderline(children[i + 2], false);
		this.nodeBitwiseXOrExpression(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeBitwiseOrExpressionNoIn = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeBitwiseOrExpressionNoIn);
	var children = astNode.children,
		size = children.length;

	this.nodeBitwiseXOrExpressionNoIn(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeWORD(children[i + 1]);	// "|"
		this.nodeUnderline(children[i + 2], false);
		this.nodeBitwiseXOrExpressionNoIn(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeBitwiseXOrExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeBitwiseXOrExpression);
	var children = astNode.children,
		size = children.length;

	this.nodeBitwiseAndExpression(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeWORD(children[i + 1]);	// "^"
		this.nodeUnderline(children[i + 2], false);
		this.nodeBitwiseAndExpression(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeBitwiseXOrExpressionNoIn = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeBitwiseXOrExpressionNoIn);
	var children = astNode.children,
		size = children.length;

	this.nodeBitwiseAndExpressionNoIn(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeWORD(children[i + 1]);	// "^"
		this.nodeUnderline(children[i + 2], false);
		this.nodeBitwiseAndExpressionNoIn(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeBitwiseAndExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeBitwiseAndExpression);
	var children = astNode.children,
		size = children.length;

	this.nodeEqualityExpression(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeWORD(children[i + 1]);	// "&"
		this.nodeUnderline(children[i + 2], false);
		this.nodeEqualityExpression(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeBitwiseAndExpressionNoIn = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeBitwiseAndExpressionNoIn);
	var children = astNode.children,
		size = children.length;

	this.nodeEqualityExpressionNoIn(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeWORD(children[i + 1]);	// "&"
		this.nodeUnderline(children[i + 2], false);
		this.nodeEqualityExpressionNoIn(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeEqualityExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeEqualityExpression);
	var children = astNode.children,
		size = children.length;

	this.nodeRelationalExpression(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeEqualityOperator(children[i + 1]);
		this.nodeUnderline(children[i + 2], false);
		this.nodeRelationalExpression(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeEqualityExpressionNoIn = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeEqualityExpressionNoIn);
	var children = astNode.children,
		size = children.length;

	this.nodeRelationalExpressionNoIn(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeEqualityOperator(children[i + 1]);
		this.nodeUnderline(children[i + 2], false);
		this.nodeRelationalExpressionNoIn(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeEqualityOperator = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeEqualityOperator);
	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeRelationalExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeRelationalExpression);
	var children = astNode.children,
		size = children.length;

	this.nodeShiftExpression(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeRelationalOperator(children[i + 1]);
		this.nodeUnderline(children[i + 2], false);
		this.nodeShiftExpression(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeRelationalOperator = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeRelationalOperator);
	var child = astNode.children[0],
        name = child ? child.name : null;

	switch(name)
	{
		case ObjJCompiler.AstNodeIN:
			this.nodeIN(child);
			break;
		case ObjJCompiler.AstNodeINSTANCEOF:
			this.nodeINSTANCEOF(child);
			break;
		default:
			this.nodeWORD(child);
	}
}

ObjJCompiler.prototype.nodeRelationalExpressionNoIn = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeRelationalExpressionNoIn);
	var children = astNode.children,
		size = children.length;

	this.nodeShiftExpression(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeRelationalOperatorNoIn(children[i + 1]);
		this.nodeUnderline(children[i + 2], false);
		this.nodeShiftExpression(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeRelationalOperatorNoIn = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeRelationalOperatorNoIn);
	var child = astNode.children[0],
        name = child ? child.name : null;

	switch(name)
	{
		case ObjJCompiler.AstNodeINSTANCEOF:
			this.nodeINSTANCEOF(child);
			break;
		default:
			this.nodeWORD(child);
	}
}

ObjJCompiler.prototype.nodeShiftExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeShiftExpression);
	var children = astNode.children,
		size = children.length;

	this.nodeAdditiveExpression(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeShiftOperator(children[i + 1]);
		this.nodeUnderline(children[i + 2], false);
		this.nodeAdditiveExpression(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeShiftOperator = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeShiftOperator);
	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeAdditiveExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeAdditiveExpression);
	var children = astNode.children,
		size = children.length;

	this.nodeMultiplicativeExpression(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeAdditiveOperator(children[i + 1]);
		this.nodeUnderline(children[i + 2], false);
		this.nodeMultiplicativeExpression(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeAdditiveOperator = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeAdditiveOperator);
	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeMultiplicativeExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeMultiplicativeExpression);
	var children = astNode.children,
		size = children.length;

	this.nodeUnaryExpression(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeMultiplicativeOperator(children[i + 1]);
		this.nodeUnderline(children[i + 2], false);
		this.nodeUnaryExpression(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodeMultiplicativeOperator = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeMultiplicativeOperator);
	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeUnaryExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeUnaryExpression);
	var children = astNode.children,
        child = astNode.children[0],
        name = child ? child.name : null;

	switch(name)
	{
		case ObjJCompiler.AstNodePostfixExpression:
			this.nodePostfixExpression(child);
			break;
		case ObjJCompiler.AstNodeDELETE:
			this.nodeDELETE(child);
			this.nodeUnderline(children[1], true);
			this.nodeUnaryExpression(children[2]);
			break;
		case ObjJCompiler.AstNodeVOID:
			this.nodeVOID(child);
			this.nodeUnderline(children[1], true);
			this.nodeUnaryExpression(children[2]);
			break;
		case ObjJCompiler.AstNodeTYPEOF:
			this.nodeTYPEOF(child);
			this.nodeUnderline(children[1], true);
			this.nodeUnaryExpression(children[2]);
			break;
		default:
			this.nodeWORD(child);
			this.nodeUnderline(children[1], false);
			this.nodeUnaryExpression(children[2]);
	}
}

ObjJCompiler.prototype.nodePostfixExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodePostfixExpression);
	var children = astNode.children;

	this.nodeLeftHandSideExpression(children[0]);

	if (children.length > 1)
	{
		this.nodeUnderlineNoLineBreak(children[1], false);
		this.nodeWORD(children[2]);		// "++" or "--"
	}
}

ObjJCompiler.prototype.nodeLeftHandSideExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeLeftHandSideExpression);
	var child = astNode.children[0];

	if (child && child.name === ObjJCompiler.AstNodeCallExpression)
		this.nodeCallExpression(child)
	else
		this.nodeNewExpression(child);
}

ObjJCompiler.prototype.nodeNewExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeNewExpression);
	var children = astNode.children,
		child = children[0];

	if (child && child.name === ObjJCompiler.AstNodeMemberExpression)
		this.nodeMemberExpression(child)
	else
	{
		this.nodeNEW(child);
		this.nodeUnderline(children[1], true);
		this.nodeNewExpression(children[2]);
	}
}

ObjJCompiler.prototype.nodeCallExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeCallExpression);
	var children = astNode.children,
		size = children.length;

	this.nodeMemberExpression(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeArguments(children[2]);

	for (var i = 3; i + 1 < size; i += 2)
	{
		this.nodeUnderline(children[i], false);
		var child = children[i + 1],
            name = child ? child.name : null;

		switch(name)
		{
			case ObjJCompiler.AstNodeArguments:
				this.nodeArguments(child);
				break;
			case ObjJCompiler.AstNodeBracketedAccessor:
				this.nodeBracketedAccessor(child);
				break;
			case ObjJCompiler.AstNodeDotAccessor:
				this.nodeDotAccessor(child);
				break;
			default:
				throw new SyntaxError(this.error_message("Expected node " + ObjJCompiler.AstNodeArguments + ", " + ObjJCompiler.AstNodeBracketedAccessor + " or " + ObjJCompiler.AstNodeDotAccessor + " but got " + child, child));
		}
	}
}

ObjJCompiler.prototype.nodeMemberExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeMemberExpression);
	var children = astNode.children,
		size = children.length,
		child = children[0],
        name = child ? child.name : null,
		offset = 1;

		switch(name)
		{
			case ObjJCompiler.AstNodePrimaryExpression:
				this.nodePrimaryExpression(child);
				break;
			case ObjJCompiler.AstNodeFunctionExpression:
				this.nodeFunctionExpression(child);
				break;
			case ObjJCompiler.AstNodeMessageExpression:
				this.nodeMessageExpression(child);
				break;
			default:
				this.nodeNEW(child);
				this.nodeUnderline(children[offset++], true);
				this.nodeMemberExpression(children[offset++]);
				this.nodeUnderline(children[offset++], false);
				this.nodeArguments(children[offset++]);
		}

	for (var i = offset; i + 1 < size; i += 2)
	{
		this.nodeUnderline(children[i], false);
		var child = children[i + 1],
            name = child ? child.name : null;

		switch(name)
		{
			case ObjJCompiler.AstNodeBracketedAccessor:
				this.nodeBracketedAccessor(child);
				break;
			case ObjJCompiler.AstNodeDotAccessor:
				this.nodeDotAccessor(child);
				break;
			default:
				throw new SyntaxError(this.error_message("Expected node " + ObjJCompiler.AstNodeBracketedAccessor + " or " + ObjJCompiler.AstNodeDotAccessor + " but got " + child, child));
		}
	}
}

ObjJCompiler.prototype.nodeBracketedAccessor = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeBracketedAccessor);
	var children = astNode.children;

	this.nodeOpenBracket(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeExpression(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeCloseBracket(children[4]);
}

ObjJCompiler.prototype.nodeDotAccessor = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeDotAccessor);
	var children = astNode.children;

	this.nodeDOT(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeIdentifierName(children[2]);
}

ObjJCompiler.prototype.nodeArguments = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeArguments);
	var children = astNode.children,
        child  = children[2],
		offset = 0;

	this.nodeOpenParenthesis(children[0]);
	this.nodeUnderline(children[1], false);
	if (child && child.name === ObjJCompiler.AstNodeArgumentList)
    {
		this.nodeArgumentList(child);
        offset++;
    }
	this.nodeUnderline(children[2 + offset], false);
	this.nodeCloseParenthesis(children[3 + offset]);
}

ObjJCompiler.prototype.nodeArgumentList = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeArgumentList);
	var children = astNode.children,
		size = children.length;

	this.nodeAssignmentExpression(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeCOMMA(children[i + 1]);
		this.nodeUnderline(children[i + 2], false);
		this.nodeAssignmentExpression(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodePrimaryExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodePrimaryExpression);
	var children = astNode.children,
		child = children[0],
        name = child ? child.name : null;

	switch(name)
	{
		case ObjJCompiler.AstNodeTHIS:
			this.nodeTHIS(child);
			break;
		case ObjJCompiler.AstNodeIdentifier:
			var saveJSBuffer = this._jsBuffer;

            this._jsBuffer = null;
            var identifier = this.nodeIdentifier(child);
            this._jsBuffer = saveJSBuffer;

			if (saveJSBuffer)
			{
				var lvar = this.getLvarForCurrentMethod(identifier),
					ivar = this.getIvarForCurrentClass(identifier);

            	if (ivar)
					if (lvar)
						0 == 0; // Warning: Local declaration of 'identifier' hides instance variable
					else
                		CONCAT(saveJSBuffer, "self.");

            	CONCAT(saveJSBuffer, identifier);
			}
			break;
		case ObjJCompiler.AstNodeLiteral:
			this.nodeLiteral(child);
			break;
		case ObjJCompiler.AstNodeArrayLiteral:
			this.nodeArrayLiteral(child);
			break;
		case ObjJCompiler.AstNodeObjectLiteral:
			this.nodeObjectLiteral(child);
			break;
		default:
			this.nodeOpenParenthesis(child);
			this.nodeUnderline(children[1], false);
			this.nodeExpression(children[2]);
			this.nodeUnderline(children[3], false);
			this.nodeCloseParenthesis(children[4]);
	}
}

ObjJCompiler.prototype.nodeMessageExpression = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeMessageExpression);
	var children = astNode.children,
		child = children[2],
        saveJSBuffer = this._jsBuffer;

    this._jsBuffer = null;
	this.nodeOpenBracket(children[0]);
	this.nodeUnderline(children[1], false);
	if (child && child.name === ObjJCompiler.AstNodeExpression)
    {
        var buffer = new StringBuffer();

        this._jsBuffer = buffer;
		this.nodeExpression(child);
        this._jsBuffer = null;
		if (saveJSBuffer)
		{
        	CONCAT(saveJSBuffer, "objj_msgSend(");
        	CONCAT(saveJSBuffer, buffer);
		}
    }
	else
    {
		this.nodeSUPER(child);
		if (saveJSBuffer)
		{
        	CONCAT(saveJSBuffer, "objj_msgSendSuper(");
        	CONCAT(saveJSBuffer, "{ receiver:self, super_class:" + (this._classMethod ? this._currentSuperMetaClass : this._currentSuperClass ) + " }");
		}
    }

	this.nodeUnderline(children[3], false);
	var selector = this.nodeSelectorCall(children[4]);

	if (saveJSBuffer)
	{
    	CONCAT(saveJSBuffer, ", \"");
    	CONCAT(saveJSBuffer, selector.selector); // FIXME: sel_getUid(selector.selector + "") ?
    	CONCAT(saveJSBuffer, "\"");

    	if (selector.expressions)
        	for (var i = 0; i < selector.expressions.length; i++)
            	CONCAT(saveJSBuffer, ", " + selector.expressions[i]);

    	CONCAT(saveJSBuffer, ")");
	}

	this.nodeUnderline(children[5], false);
	this.nodeCloseBracket(children[6]);

    this._jsBuffer = saveJSBuffer;
}

ObjJCompiler.prototype.nodeSelectorCall = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSelectorCall);
	var children = astNode.children,
		size = children.length,
		child = children[0],
        selector = {};

	if (child && child.name === ObjJCompiler.AstNodeUnarySelector)
		selector.selector = this.nodeUnarySelector(child);
	else
	{
		selector = this.nodeKeywordSelectorCall(child);

		for (var i = 1; i + 3 < size; i += 4)
		{
			this.nodeUnderline(children[i], false);
			this.nodeCOMMA(children[i + 1]);
			this.nodeUnderline(children[i + 2], false);
            var buffer = new StringBuffer();
            this._jsBuffer = buffer;
			this.nodeExpression(children[i + 3]);
            selector.parameters.push(buffer.toString());
            this._jsBuffer = null;
		}
	}
    return selector;
}

ObjJCompiler.prototype.nodeKeywordSelectorCall = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeKeywordSelectorCall);
	var children = astNode.children,
		size = children.length;

	var keywordCall = this.nodeKeywordCall(children[0]),
        selector = keywordCall.selector,
        expressions = [keywordCall.expression];

	for (var i = 1; i + 1 < size; i += 2)
	{
		this.nodeUnderline(children[i], false);
		keywordCall = this.nodeKeywordCall(children[i + 1]);
        selector += keywordCall.selector;
        expressions.push(keywordCall.expression);
	}
    return {"selector": selector, "expressions": expressions};
}

ObjJCompiler.prototype.nodeKeywordCall = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeKeywordCall);
	var children = astNode.children,
        child = children[0],
		offset = 0,
        selector = "",
        buffer = new StringBuffer();

	if (child && child.name === ObjJCompiler.AstNodeSelector)
		selector += this.nodeSelector(children[offset++]);
	
	this.nodeUnderline(children[offset++], false);
	this.nodeCOLON(children[offset++]);
    selector += ":";
	this.nodeUnderline(children[offset++], false);
    this._jsBuffer = buffer;
	this.nodeExpression(children[offset]);
    this._jsBuffer = null;

    return {"selector": selector, "expression": buffer.toString()};
}

ObjJCompiler.prototype.nodeArrayLiteral = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeArrayLiteral);
	var children = astNode.children;

	this.nodeOpenBracket(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeElementList(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeCloseBracket(children[4]);
}

ObjJCompiler.prototype.nodeElementList = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeElementList);
	var children = astNode.children,
		offset = 0;

	while (children[offset] === ",")
	{
		this.nodeCOMMA(children[offset++]);
		this.nodeUnderline(children[offset++], false);
	}

    var child = children[offset];
    
	while (child && child.name === ObjJCompiler.AstNodeUnderline)
	{
		this.nodeUnderline(child, false);
        child = children[++offset];
		if (child && child.name === ObjJCompiler.AstNodeAssignmentExpression)
			this.nodeAssignmentExpression(child);
		else if (child === ",")
			this.nodeCOMMA(child);

        child = children[++offset];
	}
}

ObjJCompiler.prototype.nodeObjectLiteral = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeObjectLiteral);
	var children = astNode.children,
        child = children[2],
		offset = 2;

	this.nodeOpenBrace(children[0]);
	this.nodeUnderline(children[1], false);
	if (child && child.name === ObjJCompiler.AstNodePropertyNameAndValueList)
	{
		this.nodePropertyNameAndValueList(children[offset++]);
		this.nodeUnderline(children[offset++], false);
		if (children[offset] === ",")
			this.nodeCOMMA(children[offset++]);
	}
	this.nodeUnderline(children[offset++], false);
	this.nodeCloseBrace(children[offset]);
}

ObjJCompiler.prototype.nodePropertyNameAndValueList = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodePropertyNameAndValueList);
	var children = astNode.children,
		size = children.length;

	this.nodePropertyAssignment(children[0]);

	for (var i = 1; i + 3 < size; i += 4)
	{
		this.nodeUnderline(children[i], false);
		this.nodeCOMMA(children[i + 1]);
		this.nodeUnderline(children[i + 2], false);
		this.nodePropertyAssignment(children[i + 3]);
	}
}

ObjJCompiler.prototype.nodePropertyAssignment = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodePropertyAssignment);
	var children = astNode.children,
		child = children[4],
        name = child ? child.name : null;

	this.nodePropertyName(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeCOLON(children[2]);
	this.nodeUnderline(children[3], false);

	switch(name)
	{
		case ObjJCompiler.AstNodeAssignmentExpression:
			this.nodeAssignmentExpression(child);
			break;
		case ObjJCompiler.AstNodePropertyGetter:
			this.nodePropertyGetter(child);
			break;
		case ObjJCompiler.AstNodePropertySetter:
			this.nodePropertySetter(child);
			break;
		default:
			throw new SyntaxError(this.error_message("Expected node " + ObjJCompiler.AstNodeAssignmentExpression + ", " + ObjJCompiler.AstNodePropertyGetter + " or " + ObjJCompiler.AstNodePropertySetter + " but got " + child, child));
	}
}

ObjJCompiler.prototype.nodePropertyGetter = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodePropertyGetter);
	var children = astNode.children,
		child = children[4];

	this.nodeGET(children[0]);
	this.nodeUnderline(children[1], true);
	this.nodePropertyName(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeOpenParenthesis(children[4]);
	this.nodeUnderline(children[5], false);
	this.nodeCloseParenthesis(children[6]);
	this.nodeUnderline(children[7], false);
	this.nodeOpenBrace(children[8]);
	this.nodeUnderline(children[9], false);
	this.nodeFunctionBody(children[10]);
	this.nodeUnderline(children[11], false);
	this.nodeCloseBrace(children[12]);
}

function PropertySetter(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodePropertyGetter);
	var children = astNode.children,
		child = children[4];

	this.nodeGET(children[0]);
	this.nodeUnderline(children[1], true);
	this.nodePropertyName(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeOpenParenthesis(children[4]);
	this.nodeUnderline(children[5], false);
	this.nodePropertySetParameterList(children[6]);
	this.nodeUnderline(children[7], false);
	this.nodeCloseParenthesis(children[8]);
	this.nodeUnderline(children[9], false);
	this.nodeOpenBrace(children[10]);
	this.nodeUnderline(children[11], false);
	this.nodeFunctionBody(children[12]);
	this.nodeUnderline(children[13], false);
	this.nodeCloseBrace(children[14]);
}

ObjJCompiler.prototype.nodePropertyName = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodePropertyName);
	var child = astNode.children[0],
        name = child ? child.name : null;

	switch(name)
	{
		case ObjJCompiler.AstNodeIdentifierName:
			this.nodeIdentifierName(child);
			break;
		case ObjJCompiler.AstNodeStringLiteral:
			this.nodeStringLiteral(child);
			break;
		case ObjJCompiler.AstNodeNumericLiteral:
			this.nodeNumericLiteral(child);
			break;
		default:
			throw new SyntaxError(this.error_message("Expected node " + ObjJCompiler.AstNodeIdentifierName + ", " + ObjJCompiler.AstNodeStringLiteral + " or " + ObjJCompiler.AstNodeNumericLiteral + " but got " + child, child));
	}
}

ObjJCompiler.prototype.nodePropertySetParameterList = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodePropertySetParameterList);

	this.nodeIdentifier(astNode.children[0]);
}

ObjJCompiler.prototype.nodeLiteral = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeLiteral);
	var child = astNode.children[0],
        name = child ? child.name : null;

    switch(name)
    {
        case ObjJCompiler.AstNodeNullLiteral:
			this.nodeNullLiteral(child);
			break;
        case ObjJCompiler.AstNodeBooleanLiteral:
			this.nodeBooleanLiteral(child);
			break;
        case ObjJCompiler.AstNodeNumericLiteral:
			this.nodeNumericLiteral(child);
			break;
        case ObjJCompiler.AstNodeStringLiteral:
			this.nodeStringLiteral(child);
			break;
        case ObjJCompiler.AstNodeRegularExpressionLiteral:
			this.nodeRegularExpressionLiteral(child);
			break;
	    case ObjJCompiler.AstNodeSelectorLiteral:
			this.nodeSelectorLiteral(child);
			break;
        default:
			throw new SyntaxError(this.error_message("Expected node " + ObjJCompiler.AstNodeLiteral + " but got " + child, child));
    }
}

ObjJCompiler.prototype.nodeSelectorLiteral = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSelectorLiteral);
	var children = astNode.children,
        saveJSBuffer = this._jsBuffer,
        selectorBuffer = new StringBuffer();

    this._jsBuffer = null;
	this.nodeSELECTOR(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeOpenParenthesis(children[2]);
	this.nodeUnderline(children[3], false);
	if (saveJSBuffer)
    	CONCAT(selectorBuffer, "sel_getUid(\"");
    this._jsBuffer = selectorBuffer;
	this.nodeSelectorLiteralContents(children[4]);
    CONCAT(selectorBuffer, "\")");
    this._jsBuffer = null;
	this.nodeUnderline(children[5], false);
	this.nodeCloseParenthesis(children[6]);
    this._jsBuffer = saveJSBuffer;
	if (saveJSBuffer)
    	CONCAT(saveJSBuffer, selectorBuffer);
}

ObjJCompiler.prototype.nodeSelectorLiteralContents = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSelectorLiteralContents);
	var children = astNode.children,
		child = children[0];

	if (child && child.name === ObjJCompiler.AstNodeIdentifier)
		this.nodeIdentifier(child);
	else
	{
		var size = children.length,
			offset = 0;

		while (offset < size)
		{
            child = children[offset];
			if (child && child.name === ObjJCompiler.AstNodeSelector)
				this.nodeSelector(children[offset++]);
			this.nodeUnderline(children[offset++], false);
			this.nodeCOLON(children[offset++]);
			this.nodeUnderline(children[offset++], false);
		}
	}
}

ObjJCompiler.prototype.nodeNullLiteral = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeNullLiteral);

	this.nodeNULL(astNode.children[0]);
}

ObjJCompiler.prototype.nodeBooleanLiteral = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeBooleanLiteral);
	var child = astNode.children[0];

	if (child && child.name === ObjJCompiler.AstNodeTRUE)
		this.nodeTRUE(child);
	else
		this.nodeFALSE(child);
}

ObjJCompiler.prototype.nodeNumericLiteral = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeNumericLiteral);
	var child = astNode.children[0];

	if (child && child.name === ObjJCompiler.AstNodeHexIntegerLiteral)
		this.nodeHexIntegerLiteral(child);
	else
		this.nodeDecimalLiteral(child);
}

ObjJCompiler.prototype.nodeDecimalLiteral = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeDecimalLiteral);
	var children = astNode.children,
		offset = 0,
		number = "",
        child = children[0];

	if (child && child.name === ObjJCompiler.AstNodeDecimalIntegerLiteral)
    {
		number += this.nodeDecimalIntegerLiteral(child);
        child = children[++offset];
    }

	if (child === ".")
	{
		number += this.nodeWORD(child); // "."
        child = children[++offset];
	}

	while (child && child.name === ObjJCompiler.AstNodeDecimalDigit)
	{
		number += this.nodeDecimalDigit(child);
        child = children[++offset]
	}

	if (child && child.name === ObjJCompiler.AstNodeExponentPart)
		number += this.nodeExponentPart(child);
}

ObjJCompiler.prototype.nodeDecimalIntegerLiteral = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeDecimalIntegerLiteral);
	var children = astNode.children,
		offset = 1,
		number = "";

	if (children[0] === "0")
		number = this.nodeWORD(children[0]);
	else
	{
		number = this.nodeWORD(children[0]);
	}

    var child = children[offset];

	while (child && child.name === ObjJCompiler.AstNodeDecimalDigit)
	{
		number += this.nodeDecimalDigit(child);
        child = children[++offset]
	}

	return number;
}

ObjJCompiler.prototype.nodeDecimalDigit = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeDecimalDigit);

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeExponentPart = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeExponentPart);
	var children = astNode.children;

	return this.nodeWORD(children[0]) + this.nodeSignedInteger(children[1]);
}

ObjJCompiler.prototype.nodeSignedInteger = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSignedInteger);
	var children = astNode.children,
		offset = 1,
		number = "",
        child = children[0];

	if (child === "+" || child === "-")
    {
		number = this.nodeWORD(child);
        child = children[offset++];
    }

	while (child && child.name === ObjJCompiler.AstNodeDecimalDigit)
	{
		number += this.nodeDecimalDigit(child);
        child = children[offset++];
	}

	return number;
}

ObjJCompiler.prototype.nodeHexIntegerLiteral = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeHexIntegerLiteral);
	var children = astNode.children,
		offset = 2,
		hex = this.nodeWORD(children[0]);

    hex += this.nodeWORD(children[1]);

    var child = children[offset];

	while (child && child.name === ObjJCompiler.AstNodeHexDigit)
	{
		hex += this.nodeHexDigit(child);
        child = children[++offset];
	}

	return hex;
}

ObjJCompiler.prototype.nodeHexDigit = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeHexDigit);

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeStringLiteral = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeStringLiteral);
	var children = astNode.children,
		offset = 0,
		string = "";

	if (children[0] === "@")
	{
		var saveJSBuffer = this._jsBuffer;

		this._jsBuffer = null;
		this.nodeWORD(children[offset++]);
		this._jsBuffer = saveJSBuffer;
		this.nodeUnderline(children[offset++], false);
	}

	var quoteCharacter = children[offset++],
		stringCharacterFunction = null;

    this.nodeWORD(quoteCharacter);

	if (quoteCharacter === '"')
		stringCharacterFunction = this.nodeDoubleStringCharacter;
	else
		stringCharacterFunction = this.nodeSingleStringCharacter;

	while (children[offset] !== quoteCharacter)
	{
		string += stringCharacterFunction.call(this, children[offset++]);
	}

    this.nodeWORD(children[offset]);

	return string;
}

ObjJCompiler.prototype.nodeDoubleStringCharacter = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeDoubleStringCharacter);
	var children = astNode.children,
		child = children[0];

	if (child === "\\")
		return this.nodeWORD(child) + this.nodeEscapeSequence(children[1]);
	else if (child && child.name === ObjJCompiler.AstNodeLineContinuation)
		return this.nodeLineContinuation(child);
	else
		return this.nodeWORD(child);
}

ObjJCompiler.prototype.nodeSingleStringCharacter = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSingleStringCharacter);
	var children = astNode.children,
		child = children[0];

	if (child === "\\")
		return this.nodeWORD(child) + this.nodeEscapeSequence(children[1]);
	else if (child && child.name === ObjJCompiler.AstNodeLineContinuation)
		return this.nodeLineContinuation(child);
	else
		return this.nodeWORD(child);
}

ObjJCompiler.prototype.nodeLineContinuation = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeLineContinuation);
	var children = astNode.children;

	return this.nodeWORD(children[0]) + nodeLineTerminatorSequence(children[1]);
}

ObjJCompiler.prototype.nodeEscapeSequence = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeEscapeSequence);
	var child = astNode.children[0],
        name = child ? child.name : null;

    switch(name)
    {
        case ObjJCompiler.AstNodeCharacterEscapeSequence:
			return this.nodeCharacterEscapeSequence(child);
        case ObjJCompiler.AstNodeHexEscapeSequence:
			return this.nodeHexEscapeSequence(child);
        case ObjJCompiler.AstNodeUnicodeEscapeSequence:
			return this.nodeUnicodeEscapeSequence(child);
        default:
			return this.nodeWORD(child);
    }
}

ObjJCompiler.prototype.nodeCharacterEscapeSequence = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeCharacterEscapeSequence);
	var child = astNode.children[0];

    if (child && child.name === ObjJCompiler.AstNodeSingleEscapeCharacter)
		return this.nodeSingleEscapeCharacter(child);
	else
		return this.nodeNonEscapeCharacter(child);
}

ObjJCompiler.prototype.nodeSingleEscapeCharacter = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSingleEscapeCharacter);

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeNonEscapeCharacter = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeNonEscapeCharacter);

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeHexEscapeSequence = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeHexEscapeSequence);
	var children = astNode.children;

	return children[0] + this.nodeHexDigit(children[1]) + nodeHexDigit(children[2]);
}

ObjJCompiler.prototype.nodeUnicodeEscapeSequence = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeUnicodeEscapeSequence);
	var children = astNode.children;

	return this.nodeWORD(children[0]) + this.nodeHexDigit(children[1]) + this.nodeHexDigit(children[2]) + this.nodeHexDigit(children[3]) + this.nodeHexDigit(children[4]);
}

ObjJCompiler.prototype.nodeRegularExpressionLiteral = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionLiteral);
	var children = astNode.children;

	return this.nodeWORD(children[0]) + this.nodeRegularExpressionBody(children[1]) + this.nodeWORD(children[2]) + this.nodeRegularExpressionFlags(children[3]);
}

ObjJCompiler.prototype.nodeRegularExpressionBody = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionBody);
	var children = astNode.children,
		regString = this.nodeRegularExpressionFirstChar(children[0]),
		offset = 1,
        child = children[offset];

	while (child && child.name === ObjJCompiler.AstNodeRegularExpressionChar)
	{
		regString += this.nodeRegularExpressionChar(child);
        child = children[++offset];
	}
	return regString;
}

ObjJCompiler.prototype.nodeRegularExpressionFirstChar = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionFirstChar);
	var child = astNode.children[0],
        name = child ? child.name : null;

    switch(name)
    {
        case ObjJCompiler.AstNodeRegularExpressionNonTerminator:
			return this.nodeRegularExpressionNonTerminator(child);
        case ObjJCompiler.AstNodeRegularExpressionBackslashSequence:
			return this.nodeRegularExpressionBackslashSequence(child);
        case ObjJCompiler.AstNodeRegularExpressionClass:
			return this.nodeRegularExpressionClass(child);
        default:
			throw new SyntaxError(this.error_message("Expected node " + ObjJCompiler.AstNodeRegularExpressionNonTerminator + ", " + ObjJCompiler.AstNodeRegularExpressionBackslashSequence + " or " + ObjJCompiler.AstNodeRegularExpressionClass + " but got " + child, child));
    }
}

ObjJCompiler.prototype.nodeRegularExpressionChar = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionChar);
	var child = astNode.children[0],
        name = child ? child.name : null;

    switch(name)
    {
        case ObjJCompiler.AstNodeRegularExpressionNonTerminator:
			return this.nodeRegularExpressionNonTerminator(child);
        case ObjJCompiler.AstNodeRegularExpressionBackslashSequence:
			return this.nodeRegularExpressionBackslashSequence(child);
        case ObjJCompiler.AstNodeRegularExpressionClass:
			return this.nodeRegularExpressionClass(child);
        default:
			throw new SyntaxError(this.error_message("Expected node " + ObjJCompiler.AstNodeRegularExpressionNonTerminator + ", " + ObjJCompiler.AstNodeRegularExpressionBackslashSequence + " or " + ObjJCompiler.AstNodeRegularExpressionClass + " but got " + child, child));
    }
}

ObjJCompiler.prototype.nodeRegularExpressionBackslashSequence = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionBackslashSequence);
	var children = astNode.children;

	return this.nodeWORD(children[0]) + this.nodeRegularExpressionNonTerminator(children[1]);
}

ObjJCompiler.prototype.nodeRegularExpressionNonTerminator = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionNonTerminator);

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeRegularExpressionClass = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionClass);
	var children = astNode.children,
		offset = 1,
		regString = this.nodeWORD(children[0]),
        child = children[offset];

		while (child && child.name === ObjJCompiler.AstNodeRegularExpressionClassChar)
		{
			regString += this.nodeRegularExpressionClassChar(children[offset++]);
            child = children[offset];
		}

		return regString + this.nodeWORD(child);
}

ObjJCompiler.prototype.nodeRegularExpressionClassChar = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionClassChar);
	var child = astNode.children[0];

		if (child && child.name === ObjJCompiler.AstNodeRegularExpressionNonTerminator)
			return this.nodeRegularExpressionNonTerminator(child);
		else
			return this.nodeRegularExpressionBackslashSequence(child);
}

ObjJCompiler.prototype.nodeRegularExpressionFlags = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionFlags);
	var children = astNode.children,
		offset = 0,
        regString = "",
        child = children[offset];
    
    while (child && child.name === ObjJCompiler.AstNodeIdentifierPart)
		{
			regString += this.nodeIdentifierPart(child);
            child = children[++offset];
		}

    return regString;
}

ObjJCompiler.prototype.nodeUnderline = function(/*SyntaxNode*/ astNode, /*boolean*/ mustHaveOneSpace)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeUnderline);
	var children = astNode.children,
		size = children.length;
		string = "";

		for (var i = 0; i < size; i++)
		{
			var child = children[i],
                name = child ? child.name : null;

		    switch(name)
		    {
		        case ObjJCompiler.AstNodeWhiteSpace:
					string += this.nodeWhiteSpace(child);
					break;
		        case ObjJCompiler.AstNodeLineTerminator:
					string += this.nodeLineTerminator(child);
					break;
		        case ObjJCompiler.AstNodeComment:
					string += this.nodeComment(child);
					break
		        default:
					throw new SyntaxError(this.error_message("Expected node " + ObjJCompiler.AstNodeWhiteSpace + ", " + ObjJCompiler.AstNodeLineTerminator + " or " + ObjJCompiler.AstNodeComment + " but got " + child.name, child));
		    }
		}
		// FIXME: Do something smart with this.....
}

ObjJCompiler.prototype.nodeUnderlineNoLineBreak = function(/*SyntaxNode*/ astNode, /*boolean*/ mustHaveOneSpace)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeUnderlineNoLineBreak);
	var children = astNode.children,
		size = children.length;
		string = "";

		for (var i = 0; i < size; i++)
		{
			var child = children[i],
                name = child ? child.name : null;
            
		    switch(name)
		    {
		        case ObjJCompiler.AstNodeWhiteSpace:
					string += this.nodeWhiteSpace(child);
					break
		        case ObjJCompiler.AstNodeSingleLineMultiLineComment:
					string += this.nodeSingleLineMultiLineComment(child);
					break
		        case AstSingleLineComment:
					string += this.nodeSingleLineComment(child);
					break
		        default:
					throw new SyntaxError(this.error_message("Expected node " + ObjJCompiler.AstNodeWhiteSpace + ", " + ObjJCompiler.AstNodeSingleLineMultiLineComment + " or " + ObjJCompiler.AstSingleLineComment + " but got " + child.name, child));
		    }
		}
		// FIXME: Do something smart with this.....
}

ObjJCompiler.prototype.nodeWhiteSpace = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeWhiteSpace);

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeLineTerminator = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeLineTerminator);

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeLineTerminatorSequence = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeLineTerminatorSequence);

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeComment = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeComment);
	var child = astNode.children[0];

    if (child && child.name === ObjJCompiler.AstNodeMultiLineComment)
        return this.nodeMultiLineComment(child);
    else
        return this.nodeSingleLineComment(child);
}

ObjJCompiler.prototype.nodeMultiLineComment = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeMultiLineComment);
	var children = astNode.children,
		size = children.length;
		string = "";

    for (var i = 0; i < size; i++)
    {
        string += this.nodeWORD(children[i]);
    }

    return string;
}

ObjJCompiler.prototype.nodeSingleLineMultiLineComment = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSingleLineMultiLineComment);
	var children = astNode.children,
		size = children.length,
		string = "";

    for (var i = 0; i < size; i++)
    {
        string += this.nodeWORD(children[i]);
    }

    return string;
}

ObjJCompiler.prototype.nodeSingleLineComment = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSingleLineComment);
	var children = astNode.children,
		size = children.length,
		string = children[0];

    this.nodeWORD(string);
    for (var i = 1; i < size; i++)
    {
        string += this.nodeSingleLineCommentChar(children[i])
    }

    return string;
}

ObjJCompiler.prototype.nodeSingleLineCommentChar = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSingleLineCommentChar);

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeEOS = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeEOS);
	var children = astNode.children,
        child = children[0];

	if (child && child.name === ObjJCompiler.AstNodeUnderline)
	{
		this.nodeUnderline(child, false);
		this.nodeSEMICOLON(children[1]);
	}	
	else
	{
		this.nodeUnderlineNoLineBreak(child, false);
        child = children[1];

		if (child && child.name === ObjJCompiler.AstNodeLineTerminatorSequence)
			this.nodeLineTerminatorSequence(child);
		else if (child && child.name === ObjJCompiler.AstNodeEOF)
			this.nodeEOF(child);
	}
}

ObjJCompiler.prototype.nodeSemicolonInsertionEOS = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSemicolonInsertionEOS);
	var children = astNode.children,
        child = children[1];

	this.nodeUnderlineNoLineBreak(children[0], false)
	if (child && child.name === ObjJCompiler.AstNodeLineTerminatorSequence)
		this.nodeLineTerminatorSequence(child);
	else if (child && child.name === ObjJCompiler.AstNodeEOF)
		this.nodeEOF(child);
	else if (children.length > 1)
		this.nodeSEMICOLON(child);
}

ObjJCompiler.prototype.nodeEOF = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeEOF);
}

ObjJCompiler.prototype.nodeIdentifier = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeIdentifier);

	return this.nodeIdentifierName(astNode.children[0]);
}

ObjJCompiler.prototype.nodeIdentifierName = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeIdentifierName);
	var children = astNode.children,
		size = children.length,
		string = this.nodeIdentifierStart(children[0]);

    for (var i = 1; i < size; i++)
    {
        string += this.nodeIdentifierPart(children[i]);
    }

    return string;
}

ObjJCompiler.prototype.nodeIdentifierStart = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeIdentifierStart);
	var children = astNode.children,
		child = children[0];

	if (child && child.name === ObjJCompiler.AstNodeUnicodeLetter)
		return this.nodeUnicodeLetter(child);
	else if (child === "\\")
		return this.nodeWORD(child) + nodeUnicodeEscapeSequence(children[1]);
	else
		return this.nodeWORD(child);
}

ObjJCompiler.prototype.nodeIdentifierPart = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeIdentifierPart);
	var child = astNode.children[0],
        name = child ? child.name : null;

    switch(name)
    {
        case ObjJCompiler.AstNodeIdentifierStart:
			return this.nodeIdentifierStart(child);
        case ObjJCompiler.AstNodeUnicodeCombiningMark:
			return this.nodeUnicodeCombiningMark(child);
        case ObjJCompiler.AstNodeUnicodeDigit:
			return this.nodeUnicodeDigit(child);
        case ObjJCompiler.AstNodeUnicodeConnectorPunctuation:
			return this.nodeUnicodeConnectorPunctuation(child);
        case ObjJCompiler.AstNodeZWNJ:
			return this.nodeZWNJ(child);
	    case ObjJCompiler.AstNodeZWJ:
			return this.nodeZWJ(child);
        default:
			throw new SyntaxError(this.error_message("Expected children of " + ObjJCompiler.AstNodeIdentifierPart + " but got " + child, child));
    }
}

ObjJCompiler.prototype.nodeZWNJ = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeZWNJ);

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeZWJ = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeZWJ);

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeUnicodeLetter = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeUnicodeLetter);

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeUnicodeCombiningMark = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeUnicodeCombiningMark);

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeUnicodeDigit = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeUnicodeDigit);

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeUnicodeConnectorPunctuation = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeUnicodeConnectorPunctuation);

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeFALSE = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeFALSE);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeTRUE = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeTRUE);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeNULL = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeNULL);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeBREAK = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeBREAK);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeCONTINUE = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeCONTINUE);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeDEBUGGER = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeDEBUGGER);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeIN = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeIN);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeINSTANCEOF = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeINSTANCEOF);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeDELETE = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeDELETE);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeFUNCTION = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeFUNCTION);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeNEW = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeNEW);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeTHIS = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeTHIS);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeTYPEOF = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeTYPEOF);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeVOID = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeVOID);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeIF = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeIF);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeELSE = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeELSE);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeDO = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeDO);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeWHILE = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeWHILE);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeFOR = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeFOR);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeVAR = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeVAR);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeRETURN = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeRETURN);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeCASE = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeCASE);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeDEFAULT = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeDEFAULT);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeSWITCH = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSWITCH);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeTHROW = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeTHROW);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeCATCH = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeCATCH);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeFINALLY = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeFINALLY);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeTRY = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeTRY);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeWITH = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeWITH);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeSUPER = function(/*SyntaxNode*/ astNode)
{
	this.assertNode(astNode, ObjJCompiler.AstNodeSUPER);

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeCOMMA = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeCOLON = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeSEMICOLON = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeOpenParenthesis = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeCloseParenthesis = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeOpenBrace = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeCloseBrace = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeOpenBracket = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeCloseBracket = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeDOT = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeIMPLEMENTATION = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeEND = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeIMPORT = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeOUTLET = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeSELECTOR = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeACCESSORS = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodePROPERTY = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeGETTER = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeSETTER = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeLESSTHEN = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeGREATERTHEN = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeEQUALS = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodePLUS = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeMINUS = function(/*SyntaxNode*/ astNode)
{
	return this.nodeWORD(astNode);
}

ObjJCompiler.prototype.nodeWORD = function(/*SyntaxNode*/ astNode)
{
//    if (typeof astNode !== "string")
//        debugger;
	if (this._jsBuffer)
		CONCAT(this._jsBuffer, astNode);
	if (this._objJBuffer)
		CONCAT(this._objJBuffer, astNode);
	return astNode;
}

ObjJCompiler.prototype.getClassDef = function(/* String */ aClassName)
{
	var	c = this._classDefs[aClassName];

	if (c) return c;

	if (objj_getClass)
	{
		var aClass = objj_getClass(aClassName);
		if (aClass)
		{
			var ivars = class_copyIvarList(aClass),
				ivarSize = ivars.length,
				myIvars = {},
				superClass = aClass.super_class;

			for (var i = 0; i < ivarSize; i++)
			{
				var ivar = ivars[i];

			    myIvars[ivar.name] = {"type": ivar.type, "name": ivar.name};
			}
			c = {"className": aClassName, "ivars": myIvars};

			if (superClass)
				c.superClassName = superClass.name;
			this._classDefs[aClassName] = c;
			return c;
		}
	}

	return null;
//	classDef = {"className": className, "superClassName": superClassName, "ivars": {}, "methods": {}};
}

ObjJCompiler.prototype.getIvarForCurrentClass = function(/* String */ ivarName)
{
	var	c = this._currentClassDef;

	while (c)
	{
		var ivars = c.ivars;
		if (ivars)
		{
			var ivarDef = ivars[ivarName];
			if (ivarDef)
				return ivarDef;
		}
		c = this.getClassDef(c.superClassName);
	}

	return null;
}

ObjJCompiler.prototype.getLvarForCurrentMethod = function(/* String */ lvarName)
{
	var	currentMethod = this._currentMethod;

	if (currentMethod)
	{
		var ivars = currentMethod.lvars;
		if (ivars && ivars[lvarName])
		{
			return ivars[lvarName];
		}
		// TODO: check the parameters in the method declaration
	}

	return null;
}

ObjJCompiler.prototype.createLocalVariable = function(/*Variable*/ variable)
{
	var currentClassMethods = this._currentMethod;

	if (currentClassMethods)
	{
		var lvars = currentClassMethods.lvars;

		if (!lvars)
		{
			lvars = {};
			currentClassMethods.lvars = lvars;
		}

		if (lvars[variable.identifier])
		{
			// Local variable already declared! Maybe a warning?
		}

		lvars[variable.identifier] = variable;
	}
}

ObjJCompiler.prototype.executable = function()
{
    if (!this._executable)
        this._executable = new Executable(this._jsBuffer ? this._jsBuffer.toString() : null, this._dependencies, this._URL, null, this);
    return this._executable;
}

ObjJCompiler.prototype.IMBuffer = function()
{
    return this._imBuffer;
}

ObjJCompiler.prototype.JSBuffer = function()
{
    return this._jsBuffer;
}

ObjJCompiler.prototype.error_message = function(errorMessage, astNode)
{
    return errorMessage + " <Context File: "+ this._URL +
                                (this._currentClass ? " Class: "+this._currentClass : "") +
                                (this._currentSelector ? " Method: "+this._currentSelector : "") +">";
}
//})(window, ObjJCompiler, { exports: ObjJCompiler });
