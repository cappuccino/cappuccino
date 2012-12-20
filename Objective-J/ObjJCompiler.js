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

var ObjJCompiler = { },
    currentCompilerFlags = "";

exports.compileToExecutable = function(/*String*/ aString, /*CFURL*/ aURL, /*unsigned*/ flags)
{
    ObjJCompiler.currentCompileFile = aURL;
    return new ObjJCompiler(aString, aURL, flags, 2).executable();
}

exports.compileToIMBuffer = function(/*String*/ aString, /*CFURL*/ aURL, /*unsigned*/ flags)
{
    return new ObjJCompiler(aString, aURL, flags, 2).IMBuffer();
}

exports.compileFileDependencies = function(/*String*/ aString, /*CFURL*/ aURL, /*unsigned*/ flags)
{
    ObjJCompiler.currentCompileFile = aURL;
    return new ObjJCompiler(aString, aURL, flags, 1).executable();
}

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

    //var start = new Date().getTime();
#ifdef BROWSER
	console.time("Parse - " + aURL);
#endif
    this._tokens = exports.Parser.parse(aString);
	//var end = new Date().getTime();
	//var time = (end - start) / 1000;
	//print("Parse: " + aURL + " in " + time + " seconds");
#ifdef BROWSER
	console.timeEnd("Parse - " + aURL);
#endif
    this._dependencies = [];
    this._flags = flags | ObjJCompiler.Flags.IncludeDebugSymbols;
    this._classDefs = {};
    //var start = new Date().getTime();
#ifdef BROWSER
	console.time("Compile pass " + pass + " - " + aURL);
#endif
	try {
    this.nodeDocument(this._tokens);
    }
    catch (e) {
    	print("Error: " + e + ", file content: " + aString);
    	throw e;
    }
	//var end = new Date().getTime();
	//var time = (end - start) / 1000;
	//print("Compile pass 1: " + aURL + " in " + time + " seconds");
#ifdef BROWSER
	console.timeEnd("Compile pass " + pass + " - " + aURL);
#endif
//	console.log("JS: " + this._jsBuffer);
}

ObjJCompiler.prototype.compilePass2 = function()
{
    ObjJCompiler.currentCompileFile = this._URL;
	this._pass = 2;
	this._jsBuffer = new StringBuffer();
	//print("Start Compile2: " + this._URL);
    //var start = new Date().getTime();
#ifdef BROWSER
    console.time("Compile pass 2" + this._pass + " - " + this._URL);
#endif
    this.nodeDocument(this._tokens);
	//var end = new Date().getTime();
	//var time = (end - start) / 1000;
	//print("Compile pass 2: " + this._URL + " in " + time + " seconds");
#ifdef BROWSER
    console.timeEnd("Compile" + this._pass + " - " + this._URL);
#endif
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

#if DEBUG
ObjJCompiler.prototype.assertNode = function(/*SyntaxNode*/ astNode, /*String*/ astNodeName)
{
	if (!astNode || astNode.name !== astNodeName)
    {
//        debugger;
		throw new SyntaxError(this.error_message("Expected node " + astNodeName + " but got " + (astNode ? astNode.name : astNode), astNode));
    }
}
#endif

ObjJCompiler.prototype.nodeDocument = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeDocument);
#endif
	this.nodeStart(astNode.children[0]);
}

ObjJCompiler.prototype.nodeStart = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeStart);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeFunctionBody);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSourceElements);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSourceElement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeFunctionDeclaration);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeFunctionExpression);
#endif
	var children = astNode.children,
        child = children[2],
        offset = 0,
        saveJSBuffer = this._jsBuffer;

    this._jsBuffer = null;
	this.nodeFUNCTION(children[0]);
	this.nodeUnderline(children[1], true);
    var identifier = null;
    if (child && child.name === ObjJCompiler.AstNodeIdentifier)
    {
        identifier = this.nodeIdentifier(child);
        offset++;
    }
	this.nodeUnderline(children[2 + offset], false);
    if (saveJSBuffer)
        if (identifier)
        {
            CONCAT(saveJSBuffer, identifier);
            CONCAT(saveJSBuffer, " = function");
        }
        else
        {
            CONCAT(saveJSBuffer, "function");
        }
    this._jsBuffer = saveJSBuffer;
	this.nodeOpenParenthesis(children[3 + offset]);
	this.nodeUnderline(children[4 + offset], false);

    child = children[5 + offset];

	if (child && child.name ===ObjJCompiler.AstNodeFormalParameterList)
	{
		this.nodeFormalParameterList(child);
		offset++;
	}
	this.nodeUnderline(children[5 + offset], false);
	this.nodeCloseParenthesis(children[6 + offset]);
	this.nodeUnderline(children[7 + offset], false);
	this.nodeOpenBrace(children[8 + offset]);
	this.nodeUnderline(children[9 + offset], false);
	this.nodeFunctionBody(children[10 + offset]);
	this.nodeUnderline(children[11 + offset], false);
	this.nodeCloseBrace(children[12 + offset]);
}

ObjJCompiler.prototype.nodeFormalParameterList = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeFormalParameterList);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeStatementList);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeBlock);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeVariableStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeVariableDeclaration);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeVariableDeclarationNoIn);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeVariableDeclarationListNoIn);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeEmptyStatement);
#endif

	this.nodeWORD(astNode.children[0]);	// ";"
}

ObjJCompiler.prototype.nodeExpressionStatement = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeExpressionStatement);
#endif
	var children = astNode.children;

	this.nodeExpression(children[0]);
	this.nodeEOS(children[1]);
}

ObjJCompiler.prototype.nodeIfStatement = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeIfStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeIterationStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeDoWhileStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeWhileStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeForStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeForFirstExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeForInStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeForInFirstExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeEachStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeContinueStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeBreakStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeReturnStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeWithStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSwitchStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeCaseBlock);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeCaseClauses);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeCaseClause);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeDefaultClause);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeLabelledStatement);
#endif
	var children = astNode.children;

	this.nodeIdentifier(children[0]);
	this.nodeUnderline(children[1], true);
	this.nodeCOLON(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeStatementList(children[4]);
}

ObjJCompiler.prototype.nodeThrowStatement = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeThrowStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeTryStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeCatch);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeFinally);
#endif
	var children = astNode.children;

	this.nodeFINALLY(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeBlock(children[2]);
}

ObjJCompiler.prototype.nodeDebuggerStatement = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeDebuggerStatement);
#endif
	var children = astNode.children;

	this.nodeDEBUGGER(children[0]);
	this.nodeEOS(children[1]);
}

ObjJCompiler.prototype.nodeImportStatement = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeImportStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeLocalFilePath);
#endif

	return this.nodeStringLiteral(astNode.children[0]);
}

ObjJCompiler.prototype.nodeStandardFilePath = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeStandardFilePath);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeClassDeclarationStatement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSuperclassDeclaration);
#endif
	var children = astNode.children;

	this.nodeCOLON(children[0]);
	this.nodeUnderline(children[1], false);
	return this.nodeIdentifier(children[2]);
}

ObjJCompiler.prototype.nodeCategoryDeclaration = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeCategoryDeclaration);
#endif
	var children = astNode.children;

	this.nodeOpenParenthesis(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeIdentifier(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeCloseParenthesis(children[4]);
}

ObjJCompiler.prototype.nodeCompoundIvarDeclaration = function(/*SyntaxNode*/ astNode, classDefIvars)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeCompoundIvarDeclaration);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeIvarType);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeIvarTypeElement);
#endif
	var children = astNode.children,
        child = children[0];

	if (child && child.name === ObjJCompiler.AstNodeIdentifierName)
		return this.nodeIdentifierName(child);
	else
		return this.nodeOUTLET(child);
}

ObjJCompiler.prototype.nodeIvarDeclaration = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeIvarDeclaration);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeAccessors);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeAccessorsConfiguration);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeIvarPropertyName);
#endif
	var children = astNode.children;

	this.nodePROPERTY(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeEQUALS(children[2]);
	this.nodeUnderline(children[3], false);
	return this.nodeIdentifier(children[4]);
}

ObjJCompiler.prototype.nodeIvarGetterName = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeIvarGetterName);
#endif
	var children = astNode.children;

	this.nodeGETTER(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeEQUALS(children[2]);
	this.nodeUnderline(children[3], false);
	return this.nodeIdentifier(children[4]);
}

ObjJCompiler.prototype.nodeIvarSetterName = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeIvarSetterName);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeClassBody);
#endif
	var child = astNode.children[0];

    if (child && child.name === ObjJCompiler.AstNodeClassElements)
		this.nodeClassElements(child);
}

ObjJCompiler.prototype.nodeClassElements = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeClassElements);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeClassElement);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeClassMethodDeclaration);
#endif
	this.nodePLUS(astNode.children[0]);
    this._classMethod = true;
	this.genericMethodDeclaration(astNode, this._cmBuffer);
}

ObjJCompiler.prototype.nodeInstanceMethodDeclaration = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeInstanceMethodDeclaration);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeMethodSelector);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeUnarySelector);
#endif
	return this.nodeSelector(astNode.children[0]);
}

ObjJCompiler.prototype.nodeKeywordSelector = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeKeywordSelector);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeKeywordDeclarator);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSelector);
#endif
	return this.nodeIdentifierName(astNode.children[0]);
}

ObjJCompiler.prototype.nodeMethodType = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeMethodType);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeACTION);
#endif
	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeExpression = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeExpressionNoIn);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeAssignmentExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeAssignmentExpressionNoIn);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeAssignmentOperator);
#endif
	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeConditionalExpression = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeConditionalExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeConditionalExpressionNoIn);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeLogicalOrExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeLogicalOrExpressionNoIn);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeLogicalAndExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeLogicalAndExpressionNoIn);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeBitwiseOrExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeBitwiseOrExpressionNoIn);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeBitwiseXOrExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeBitwiseXOrExpressionNoIn);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeBitwiseAndExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeBitwiseAndExpressionNoIn);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeEqualityExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeEqualityExpressionNoIn);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeEqualityOperator);
#endif
	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeRelationalExpression = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeRelationalExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeRelationalOperator);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeRelationalExpressionNoIn);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeRelationalOperatorNoIn);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeShiftExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeShiftOperator);
#endif
	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeAdditiveExpression = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeAdditiveExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeAdditiveOperator);
#endif
	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeMultiplicativeExpression = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeMultiplicativeExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeMultiplicativeOperator);
#endif
	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeUnaryExpression = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeUnaryExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodePostfixExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeLeftHandSideExpression);
#endif
	var child = astNode.children[0];

	if (child && child.name === ObjJCompiler.AstNodeCallExpression)
		this.nodeCallExpression(child)
	else
		this.nodeNewExpression(child);
}

ObjJCompiler.prototype.nodeNewExpression = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeNewExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeCallExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeMemberExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeBracketedAccessor);
#endif
	var children = astNode.children;

	this.nodeOpenBracket(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeExpression(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeCloseBracket(children[4]);
}

ObjJCompiler.prototype.nodeDotAccessor = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeDotAccessor);
#endif
	var children = astNode.children;

	this.nodeDOT(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeIdentifierName(children[2]);
}

ObjJCompiler.prototype.nodeArguments = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeArguments);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeArgumentList);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodePrimaryExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeMessageExpression);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSelectorCall);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeKeywordSelectorCall);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeKeywordCall);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeArrayLiteral);
#endif
	var children = astNode.children;

	this.nodeOpenBracket(children[0]);
	this.nodeUnderline(children[1], false);
	this.nodeElementList(children[2]);
	this.nodeUnderline(children[3], false);
	this.nodeCloseBracket(children[4]);
}

ObjJCompiler.prototype.nodeElementList = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeElementList);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeObjectLiteral);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodePropertyNameAndValueList);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodePropertyAssignment);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodePropertyGetter);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodePropertyGetter);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodePropertyName);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodePropertySetParameterList);
#endif

	this.nodeIdentifier(astNode.children[0]);
}

ObjJCompiler.prototype.nodeLiteral = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeLiteral);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSelectorLiteral);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSelectorLiteralContents);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeNullLiteral);
#endif

	this.nodeNULL(astNode.children[0]);
}

ObjJCompiler.prototype.nodeBooleanLiteral = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeBooleanLiteral);
#endif
	var child = astNode.children[0];

	if (child && child.name === ObjJCompiler.AstNodeTRUE)
		this.nodeTRUE(child);
	else
		this.nodeFALSE(child);
}

ObjJCompiler.prototype.nodeNumericLiteral = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeNumericLiteral);
#endif
	var child = astNode.children[0];

	if (child && child.name === ObjJCompiler.AstNodeHexIntegerLiteral)
		this.nodeHexIntegerLiteral(child);
	else
		this.nodeDecimalLiteral(child);
}

ObjJCompiler.prototype.nodeDecimalLiteral = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeDecimalLiteral);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeDecimalIntegerLiteral);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeDecimalDigit);
#endif

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeExponentPart = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeExponentPart);
#endif
	var children = astNode.children;

	return this.nodeWORD(children[0]) + this.nodeSignedInteger(children[1]);
}

ObjJCompiler.prototype.nodeSignedInteger = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSignedInteger);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeHexIntegerLiteral);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeHexDigit);
#endif

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeStringLiteral = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeStringLiteral);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeDoubleStringCharacter);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSingleStringCharacter);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeLineContinuation);
#endif
	var children = astNode.children;

	return this.nodeWORD(children[0]) + nodeLineTerminatorSequence(children[1]);
}

ObjJCompiler.prototype.nodeEscapeSequence = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeEscapeSequence);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeCharacterEscapeSequence);
#endif
	var child = astNode.children[0];

    if (child && child.name === ObjJCompiler.AstNodeSingleEscapeCharacter)
		return this.nodeSingleEscapeCharacter(child);
	else
		return this.nodeNonEscapeCharacter(child);
}

ObjJCompiler.prototype.nodeSingleEscapeCharacter = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSingleEscapeCharacter);
#endif

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeNonEscapeCharacter = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeNonEscapeCharacter);
#endif

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeHexEscapeSequence = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeHexEscapeSequence);
#endif
	var children = astNode.children;

	return children[0] + this.nodeHexDigit(children[1]) + nodeHexDigit(children[2]);
}

ObjJCompiler.prototype.nodeUnicodeEscapeSequence = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeUnicodeEscapeSequence);
#endif
	var children = astNode.children;

	return this.nodeWORD(children[0]) + this.nodeHexDigit(children[1]) + this.nodeHexDigit(children[2]) + this.nodeHexDigit(children[3]) + this.nodeHexDigit(children[4]);
}

ObjJCompiler.prototype.nodeRegularExpressionLiteral = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionLiteral);
#endif
	var children = astNode.children;

	return this.nodeWORD(children[0]) + this.nodeRegularExpressionBody(children[1]) + this.nodeWORD(children[2]) + this.nodeRegularExpressionFlags(children[3]);
}

ObjJCompiler.prototype.nodeRegularExpressionBody = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionBody);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionFirstChar);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionChar);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionBackslashSequence);
#endif
	var children = astNode.children;

	return this.nodeWORD(children[0]) + this.nodeRegularExpressionNonTerminator(children[1]);
}

ObjJCompiler.prototype.nodeRegularExpressionNonTerminator = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionNonTerminator);
#endif

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeRegularExpressionClass = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionClass);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionClassChar);
#endif
	var child = astNode.children[0];

		if (child && child.name === ObjJCompiler.AstNodeRegularExpressionNonTerminator)
			return this.nodeRegularExpressionNonTerminator(child);
		else
			return this.nodeRegularExpressionBackslashSequence(child);
}

ObjJCompiler.prototype.nodeRegularExpressionFlags = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeRegularExpressionFlags);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeUnderline);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeUnderlineNoLineBreak);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeWhiteSpace);
#endif

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeLineTerminator = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeLineTerminator);
#endif

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeLineTerminatorSequence = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeLineTerminatorSequence);
#endif

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeComment = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeComment);
#endif
	var child = astNode.children[0];

    if (child && child.name === ObjJCompiler.AstNodeMultiLineComment)
        return this.nodeMultiLineComment(child);
    else
        return this.nodeSingleLineComment(child);
}

ObjJCompiler.prototype.nodeMultiLineComment = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeMultiLineComment);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSingleLineMultiLineComment);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSingleLineComment);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSingleLineCommentChar);
#endif

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeEOS = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeEOS);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSemicolonInsertionEOS);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeEOF);
#endif
}

ObjJCompiler.prototype.nodeIdentifier = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeIdentifier);
#endif

	return this.nodeIdentifierName(astNode.children[0]);
}

ObjJCompiler.prototype.nodeIdentifierName = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeIdentifierName);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeIdentifierStart);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeIdentifierPart);
#endif
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
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeZWNJ);
#endif

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeZWJ = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeZWJ);
#endif

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeUnicodeLetter = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeUnicodeLetter);
#endif

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeUnicodeCombiningMark = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeUnicodeCombiningMark);
#endif

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeUnicodeDigit = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeUnicodeDigit);
#endif

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeUnicodeConnectorPunctuation = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeUnicodeConnectorPunctuation);
#endif

	return this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeFALSE = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeFALSE);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeTRUE = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeTRUE);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeNULL = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeNULL);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeBREAK = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeBREAK);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeCONTINUE = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeCONTINUE);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeDEBUGGER = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeDEBUGGER);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeIN = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeIN);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeINSTANCEOF = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeINSTANCEOF);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeDELETE = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeDELETE);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeFUNCTION = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeFUNCTION);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeNEW = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeNEW);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeTHIS = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeTHIS);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeTYPEOF = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeTYPEOF);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeVOID = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeVOID);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeIF = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeIF);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeELSE = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeELSE);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeDO = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeDO);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeWHILE = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeWHILE);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeFOR = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeFOR);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeVAR = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeVAR);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeRETURN = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeRETURN);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeCASE = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeCASE);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeDEFAULT = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeDEFAULT);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeSWITCH = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSWITCH);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeTHROW = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeTHROW);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeCATCH = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeCATCH);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeFINALLY = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeFINALLY);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeTRY = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeTRY);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeWITH = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeWITH);
#endif

	this.nodeWORD(astNode.children[0]);
}

ObjJCompiler.prototype.nodeSUPER = function(/*SyntaxNode*/ astNode)
{
#if DEBUG
	this.assertNode(astNode, ObjJCompiler.AstNodeSUPER);
#endif

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
