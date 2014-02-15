/*
 * ObjJAcornCompiler.js
 * Objective-J
 *
 * Created by Martin Carlberg.
 * Copyright 2013, Martin Carlberg.
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

var Scope = function(prev, base)
{
    this.vars = Object.create(null);
    if (base) for (var key in base) this[key] = base[key];
    this.prev = prev;
    if (prev) this.compiler = prev.compiler;
}

Scope.prototype.compiler = function()
{
    return this.compiler;
}

Scope.prototype.rootScope = function()
{
    return this.prev ? this.prev.rootScope() : this;
}

Scope.prototype.isRootScope = function()
{
    return !this.prev;
}

Scope.prototype.currentClassName = function()
{
    return this.classDef ? this.classDef.name : this.prev ? this.prev.currentClassName() : null;
}

Scope.prototype.currentProtocolName = function()
{
    return this.protocolDef ? this.protocolDef.name : this.prev ? this.prev.currentProtocolName() : null;
}

Scope.prototype.getIvarForCurrentClass = function(/* String */ ivarName)
{
    if (this.ivars)
    {
        var ivar = this.ivars[ivarName];
        if (ivar)
            return ivar;
    }

    var prev = this.prev;

    // Stop at the class declaration
    if (prev && !this.classDef)
        return prev.getIvarForCurrentClass(ivarName);

    return null;
}

Scope.prototype.getLvar = function(/* String */ lvarName, /* BOOL */ stopAtMethod)
{
    if (this.vars)
    {
        var lvar = this.vars[lvarName];
        if (lvar)
            return lvar;
    }

    var prev = this.prev;

    // Stop at the method declaration
    if (prev && (!stopAtMethod || !this.methodType))
        return prev.getLvar(lvarName, stopAtMethod);

    return null;
}

Scope.prototype.currentMethodType = function()
{
    return this.methodType ? this.methodType : this.prev ? this.prev.currentMethodType() : null;
}

Scope.prototype.copyAddedSelfToIvarsToParent = function()
{
  if (this.prev && this.addedSelfToIvars) for (var key in this.addedSelfToIvars)
  {
    var addedSelfToIvar = this.addedSelfToIvars[key],
        scopeAddedSelfToIvar = (this.prev.addedSelfToIvars || (this.prev.addedSelfToIvars = Object.create(null)))[key] || (this.prev.addedSelfToIvars[key] = []);

    scopeAddedSelfToIvar.push.apply(scopeAddedSelfToIvar, addedSelfToIvar);   // Append at end in parent scope
  }
}

Scope.prototype.addMaybeWarning = function(warning)
{
    var rootScope = this.rootScope();

    (rootScope._maybeWarnings || (rootScope._maybeWarnings = [])).push(warning);
}

Scope.prototype.maybeWarnings = function()
{
    return this.rootScope()._maybeWarnings;
}

var GlobalVariableMaybeWarning = function(/* String */ aMessage, /* SpiderMonkey AST node */ node, /* String */ code)
{
    this.message = createMessage(aMessage, node, code);
    this.node = node;
}

GlobalVariableMaybeWarning.prototype.checkIfWarning = function(/* Scope */ st)
{
    var identifier = this.node.name;
    return !st.getLvar(identifier) && typeof global[identifier] === "undefined" && typeof window[identifier] === "undefined" && !st.compiler.getClassDef(identifier);
}

function StringBuffer()
{
    this.atoms = [];
}

StringBuffer.prototype.toString = function()
{
    return this.atoms.join("");
}

StringBuffer.prototype.concat = function(aString)
{
    this.atoms.push(aString);
}

StringBuffer.prototype.isEmpty = function()
{
    return this.atoms.length !== 0;
}

// Both the ClassDef and ProtocolDef conforms to a 'protocol' (That we can't declare in Javascript).
// Both Objects have the attribute 'protocols': Array of ProtocolDef that they conform to
// Both also have the functions: addInstanceMethod, addClassMethod, getInstanceMethod and getClassMethod
// classDef = {"className": aClassName, "superClass": superClass , "ivars": myIvars, "instanceMethods": instanceMethodDefs, "classMethods": classMethodDefs, "protocols": myProtocols};
var ClassDef = function(isImplementationDeclaration, name, superClass, ivars, instanceMethods, classMethods, protocols)
{
    this.name = name;
    if (superClass)
        this.superClass = superClass;
    if (ivars)
        this.ivars = ivars;
    if (isImplementationDeclaration) {
        this.instanceMethods = instanceMethods || Object.create(null);
        this.classMethods = classMethods || Object.create(null);
    }
    if (protocols)
        this.protocols = protocols;
}

ClassDef.prototype.addInstanceMethod = function(methodDef) {
    this.instanceMethods[methodDef.name] = methodDef;
}

ClassDef.prototype.addClassMethod = function(methodDef) {
    this.classMethods[methodDef.name] = methodDef;
}

ClassDef.prototype.listOfNotImplementedMethodsForProtocols = function(protocolDefs) {
    var resultList = [],
        instanceMethods = this.getInstanceMethods(),
        classMethods = this.getClassMethods();

    for (var i = 0, size = protocolDefs.length; i < size; i++)
    {
        var protocolDef = protocolDefs[i],
            protocolInstanceMethods = protocolDef.requiredInstanceMethods,
            protocolClassMethods = protocolDef.requiredClassMethods,
            inheritFromProtocols = protocolDef.protocols;

        if (protocolInstanceMethods)
            for (var methodName in protocolInstanceMethods) {
                var methodDef = protocolInstanceMethods[methodName];

                if (!instanceMethods[methodName])
                    resultList.push({"methodDef": methodDef, "protocolDef": protocolDef});
            }

        if (protocolClassMethods)
            for (var methodName in protocolClassMethods) {
                var methodDef = protocolClassMethods[methodName];

                if (!classMethods[methodName])
                    resultList.push({"methodDef": methodDef, "protocolDef": protocolDef});
            }

        if (inheritFromProtocols)
            resultList = resultList.concat(this.listOfNotImplementedMethodsForProtocols(inheritFromProtocols));
    }

    return resultList;
}

ClassDef.prototype.getInstanceMethod = function(name) {
    var instanceMethods = this.instanceMethods;

    if (instanceMethods) {
        var method = instanceMethods[name];

        if (method)
            return method;
    }

    var superClass = this.superClass;

    if (superClass)
        return superClass.getInstanceMethod(name);

    return null;
}

ClassDef.prototype.getClassMethod = function(name) {
    var classMethods = this.classMethods;
    if (classMethods) {
        var method = classMethods[name];

        if (method)
            return method;
    }

    var superClass = this.superClass;

    if (superClass)
        return superClass.getClassMethod(name);

    return null;
}

// Return a new Array with all instance methods
ClassDef.prototype.getInstanceMethods = function() {
    var instanceMethods = this.instanceMethods;
    if (instanceMethods) {
        var superClass = this.superClass,
            returnObject = Object.create(null);
        if (superClass) {
            var superClassMethods = superClass.getInstanceMethods();
            for (var methodName in superClassMethods)
                returnObject[methodName] = superClassMethods[methodName];
        }

        for (var methodName in instanceMethods)
            returnObject[methodName] = instanceMethods[methodName];

        return returnObject;
    }

    return [];
}

// Return a new Array with all class methods
ClassDef.prototype.getClassMethods = function() {
    var classMethods = this.classMethods;
    if (classMethods) {
        var superClass = this.superClass,
            returnObject = Object.create(null);
        if (superClass) {
            var superClassMethods = superClass.getClassMethods();
            for (var methodName in superClassMethods)
                returnObject[methodName] = superClassMethods[methodName];
        }

        for (var methodName in classMethods)
            returnObject[methodName] = classMethods[methodName];

        return returnObject;
    }

    return [];
}

//  protocolDef = {"name": aProtocolName, "protocols": inheritFromProtocols, "requiredInstanceMethods": requiredInstanceMethodDefs, "requiredClassMethods": requiredClassMethodDefs};
var ProtocolDef = function(name, protocols, requiredInstanceMethodDefs, requiredClassMethodDefs)
{
    this.name = name;
    this.protocols = protocols;
    if (requiredInstanceMethodDefs)
        this.requiredInstanceMethods = requiredInstanceMethodDefs;
    if (requiredClassMethodDefs)
        this.requiredClassMethods = requiredClassMethodDefs;
}

ProtocolDef.prototype.addInstanceMethod = function(methodDef) {
    (this.requiredInstanceMethods || (this.requiredInstanceMethods = Object.create(null)))[methodDef.name] = methodDef;
}

ProtocolDef.prototype.addClassMethod = function(methodDef) {
    (this.requiredClassMethods || (this.requiredClassMethods = Object.create(null)))[methodDef.name] = methodDef;
}

ProtocolDef.prototype.getInstanceMethod = function(name) {
    var instanceMethods = this.requiredInstanceMethods;

    if (instanceMethods) {
        var method = instanceMethods[name];

        if (method)
            return method;
    }

    var protocols = this.protocols;

    for (var i = 0, size = protocols.length; i < size; i++) {
        var protocol = protocols[i],
            method = protocol.getInstanceMethod(name);

        if (method)
            return method;
    }

    return null;
}

ProtocolDef.prototype.getClassMethod = function(name) {
    var classMethods = this.requiredClassMethods;

    if (classMethods) {
        var method = classMethods[name];

        if (method)
            return method;
    }

    var protocols = this.protocols;

    for (var i = 0, size = protocols.length; i < size; i++) {
        var protocol = protocols[i],
            method = protocol.getInstanceMethod(name);

        if (method)
            return method;
    }

    return null;
}

// methodDef = {"types": types, "name": selector}
var MethodDef = function(name, types)
{
    this.name = name;
    this.types = types;
}

var currentCompilerFlags = "";

var reservedIdentifiers = exports.acorn.makePredicate("self _cmd undefined localStorage arguments");

var wordPrefixOperators = exports.acorn.makePredicate("delete in instanceof new typeof void");

var isLogicalBinary = exports.acorn.makePredicate("LogicalExpression BinaryExpression");
var isInInstanceof = exports.acorn.makePredicate("in instanceof");

var ObjJAcornCompiler = function(/*String*/ aString, /*CFURL*/ aURL, /*unsigned*/ flags, /*unsigned*/ pass, /* Dictionary */ classDefs, /* Dictionary */ protocolDefs)
{
    this.source = aString;
    this.URL = new CFURL(aURL);
    this.pass = pass;
    this.jsBuffer = new StringBuffer();
    this.imBuffer = null;
    this.cmBuffer = null;
    this.warnings = [];

    try {
        this.tokens = exports.acorn.parse(aString);
    }
    catch (e) {
        if (e.lineStart)
        {
            var message = this.prettifyMessage(e, "ERROR");
#ifdef BROWSER
            console.log(message);
#else
            print(message);
#endif
        }
        throw e;
    }

    this.dependencies = [];
    this.flags = flags | ObjJAcornCompiler.Flags.IncludeDebugSymbols;
    this.classDefs = classDefs ? classDefs : Object.create(null);
    this.protocolDefs = protocolDefs ? protocolDefs : Object.create(null);
    this.lastPos = 0;
    if (currentCompilerFlags & ObjJAcornCompiler.Flags.Generate)
        this.generate = true;
    this.generate = true;

    compile(this.tokens, new Scope(null ,{ compiler: this }), pass === 2 ? pass2 : pass1);
}

exports.ObjJAcornCompiler = ObjJAcornCompiler;

exports.ObjJAcornCompiler.compileToExecutable = function(/*String*/ aString, /*CFURL*/ aURL, /*unsigned*/ flags)
{
    ObjJAcornCompiler.currentCompileFile = aURL;
    return new ObjJAcornCompiler(aString, aURL, flags, 2).executable();
}

exports.ObjJAcornCompiler.compileToIMBuffer = function(/*String*/ aString, /*CFURL*/ aURL, /*unsigned*/ flags, classDefs, protocolDefs)
{
    return new ObjJAcornCompiler(aString, aURL, flags, 2, classDefs, protocolDefs).IMBuffer();
}

exports.ObjJAcornCompiler.compileFileDependencies = function(/*String*/ aString, /*CFURL*/ aURL, /*unsigned*/ flags)
{
    ObjJAcornCompiler.currentCompileFile = aURL;
    return new ObjJAcornCompiler(aString, aURL, flags, 1).executable();
}

ObjJAcornCompiler.prototype.compilePass2 = function()
{
    ObjJAcornCompiler.currentCompileFile = this.URL;
    this.pass = 2;
    this.jsBuffer = new StringBuffer();
    this.warnings = [];
    //print(this.URL + ": Compiling");
    compile(this.tokens, new Scope(null ,{ compiler: this }), pass2);
    for (var i = 0; i < this.warnings.length; i++)
    {
       var message = this.prettifyMessage(this.warnings[i], "WARNING");
#ifdef BROWSER
        console.log(message);
#else
        print(message);
#endif
    }

    //print(this.URL + ": " + this.jsBuffer.toString());
    return this.jsBuffer.toString();
}

var currentCompilerFlags = "";

exports.setCurrentCompilerFlags = function(/*String*/ compilerFlags)
{
    currentCompilerFlags = compilerFlags;
}

exports.currentCompilerFlags = function(/*String*/ compilerFlags)
{
    return currentCompilerFlags;
}

ObjJAcornCompiler.Flags = { };

ObjJAcornCompiler.Flags.IncludeDebugSymbols   = 1 << 0;
ObjJAcornCompiler.Flags.IncludeTypeSignatures = 1 << 1;
ObjJAcornCompiler.Flags.Generate              = 1 << 2;

ObjJAcornCompiler.prototype.addWarning = function(/* Warning */ aWarning)
{
    this.warnings.push(aWarning);
}

ObjJAcornCompiler.prototype.getIvarForClass = function(/* String */ ivarName, /* Scope */ scope)
{
    var ivar = scope.getIvarForCurrentClass(ivarName);

    if (ivar)
        return ivar;

    var c = this.getClassDef(scope.currentClassName());

    while (c)
    {
        var ivars = c.ivars;
        if (ivars)
        {
            var ivarDef = ivars[ivarName];
            if (ivarDef)
                return ivarDef;
        }
        c = c.superClass;
    }
}

ObjJAcornCompiler.prototype.getClassDef = function(/* String */ aClassName)
{
    if (!aClassName)
        return null;

    var c = this.classDefs[aClassName];

    if (c)
        return c;

    if (typeof objj_getClass === 'function')
    {
        var aClass = objj_getClass(aClassName);
        if (aClass)
        {
            var ivars = class_copyIvarList(aClass),
                ivarSize = ivars.length,
                myIvars = Object.create(null),
                protocols = class_copyProtocolList(aClass),
                protocolSize = protocols.length,
                myProtocols = Object.create(null),
                instanceMethodDefs = ObjJAcornCompiler.methodDefsFromMethodList(class_copyMethodList(aClass)),
                classMethodDefs = ObjJAcornCompiler.methodDefsFromMethodList(class_copyMethodList(aClass.isa)),
                superClass = class_getSuperclass(aClass);

            for (var i = 0; i < ivarSize; i++)
            {
                var ivar = ivars[i];

                myIvars[ivar.name] = {"type": ivar.type, "name": ivar.name};
            }

            for (var i = 0; i < protocolSize; i++)
            {
                var protocol = protocols[i],
                    protocolName = protocol_getName(protocol),
                    protocolDef = this.getProtocolDef(protocolName);

                myProtocols[protocolName] = protocolDef;
            }

            c = new ClassDef(true, aClassName, superClass ? this.getClassDef(superClass.name) : null, myIvars, instanceMethodDefs, classMethodDefs, myProtocols);
            this.classDefs[aClassName] = c;
            return c;
        }
    }

    return null;
}

ObjJAcornCompiler.prototype.getProtocolDef = function(/* String */ aProtocolName)
{
    if (!aProtocolName)
        return null;

    var p = this.protocolDefs[aProtocolName];

    if (p)
        return p;

    if (typeof objj_getProtocol === 'function')
    {
        var aProtocol = objj_getProtocol(aProtocolName);
        if (aProtocol)
        {
            var protocolName = protocol_getName(aProtocol),
                requiredInstanceMethods = protocol_copyMethodDescriptionList(aProtocol, true, true),
                requiredInstanceMethodDefs = ObjJAcornCompiler.methodDefsFromMethodList(requiredInstanceMethods),
                requiredClassMethods = protocol_copyMethodDescriptionList(aProtocol, true, false),
                requiredClassMethodDefs = ObjJAcornCompiler.methodDefsFromMethodList(requiredClassMethods),
                protocols = aProtocol.protocols,
                inheritFromProtocols = [];

            if (protocols)
                for (var i = 0, size = protocols.length; i < size; i++)
                    inheritFromProtocols.push(compiler.getProtocolDef(protocols[i].name));

            p = new ProtocolDef(protocolName, inheritFromProtocols, requiredInstanceMethodDefs, requiredClassMethodDefs);

            this.protocolDefs[aProtocolName] = p;
            return p;
        }
    }

    return null;
//  protocolDef = {"name": protocolName, "protocols": Object.create(null), "required": Object.create(null), "optional": Object.create(null)};
}

ObjJAcornCompiler.methodDefsFromMethodList = function(/* Array */ methodList)
{
    var methodSize = methodList.length,
        myMethods = Object.create(null);

    for (var i = 0; i < methodSize; i++)
    {
        var method = methodList[i],
            methodName = method_getName(method);

        myMethods[methodName] = new MethodDef(methodName, method.types);
    }

    return myMethods;
}

ObjJAcornCompiler.prototype.executable = function()
{
    if (!this._executable)
        this._executable = new Executable(this.jsBuffer ? this.jsBuffer.toString() : null, this.dependencies, this.URL, null, this);
    return this._executable;
}

ObjJAcornCompiler.prototype.IMBuffer = function()
{
    return this.imBuffer;
}

ObjJAcornCompiler.prototype.JSBuffer = function()
{
    return this.jsBuffer;
}

ObjJAcornCompiler.prototype.prettifyMessage = function(/* Message */ aMessage, /* String */ messageType)
{
    var line = this.source.substring(aMessage.lineStart, aMessage.lineEnd),
        message = "\n" + line;

    message += (new Array(aMessage.column + 1)).join(" ");
    message += (new Array(Math.min(1, line.length) + 1)).join("^") + "\n";
    message += messageType + " line " + aMessage.line + " in " + this.URL + ": " + aMessage.message;

    return message;
}

ObjJAcornCompiler.prototype.error_message = function(errorMessage, node)
{
    var pos = exports.acorn.getLineInfo(this.source, node.start),
        syntaxError = {message: errorMessage, line: pos.line, column: pos.column, lineStart: pos.lineStart, lineEnd: pos.lineEnd};

    return new SyntaxError(this.prettifyMessage(syntaxError, "ERROR"));
}

ObjJAcornCompiler.prototype.pushImport = function(url)
{
    if (!ObjJAcornCompiler.importStack) ObjJAcornCompiler.importStack = [];  // This is used to keep track of imports. Each time the compiler imports a file the url is pushed here.

    ObjJAcornCompiler.importStack.push(url);
}

ObjJAcornCompiler.prototype.popImport = function()
{
    ObjJAcornCompiler.importStack.pop();
}

function createMessage(/* String */ aMessage, /* SpiderMonkey AST node */ node, /* String */ code)
{
    var message = exports.acorn.getLineInfo(code, node.start);

    message.message = aMessage;

    return message;
}

function compile(node, state, visitor) {
    function c(node, st, override) {
        //print("c: " + (override ? override + ", " : "") + node.type + ", " + exports.acorn.getLineInfo(st.compiler.source, node.start).line);
        visitor[override || node.type](node, st, c);
        //print("cc: " + (override ? override + ", " : "") + node.type + ", " + exports.acorn.getLineInfo(st.compiler.source, node.end).line);
    }
    c(node, state);
};

function isIdempotentExpression(node) {
    switch (node.type) {
        case "Literal":
        case "Identifier":
            return true;

        case "ArrayExpression":
            for (var i = 0; i < node.elements.length; ++i) {
                if (!isIdempotentExpression(node.elements[i]))
                    return false;
            }

            return true;

        case "DictionaryLiteral":
            for (var i = 0; i < node.keys.length; ++i) {
                if (!isIdempotentExpression(node.keys[i]))
                    return false;
                if (!isIdempotentExpression(node.values[i]))
                    return false;
            }

            return true;

        case "ObjectExpression":
            for (var i = 0; i < node.properties.length; ++i)
                if (!isIdempotentExpression(node.properties[i].value))
                    return false;

            return true;

        case "FunctionExpression":
            for (var i = 0; i < node.params.length; ++i)
                if (!isIdempotentExpression(node.params[i]))
                    return false;

            return true;

        case "SequenceExpression":
            for (var i = 0; i < node.expressions.length; ++i)
                if (!isIdempotentExpression(node.expressions[i]))
                    return false;

            return true;

        case "UnaryExpression":
            return isIdempotentExpression(node.argument);

        case "BinaryExpression":
            return isIdempotentExpression(node.left) && isIdempotentExpression(node.right);

        case "ConditionalExpression":
            return isIdempotentExpression(node.test) && isIdempotentExpression(node.consequent) && isIdempotentExpression(node.alternate);

        case "MemberExpression":
            return isIdempotentExpression(node.object) && (!node.computed || isIdempotentExpression(node.property));

        case "Dereference":
            return isIdempotentExpression(node.expr);

        case "Reference":
            return isIdempotentExpression(node.element);

        default:
            return false;
    }
}

// We do not allow dereferencing of expressions with side effects because we might need to evaluate the expression twice in certain uses of deref, which is not obvious when you look at the deref operator in plain code.
function checkCanDereference(st, node) {
    if (!isIdempotentExpression(node))
        throw st.compiler.error_message("Dereference of expression with side effects", node);
}

// Surround expression with parentheses
function surroundExpression(c) {
    return function(node, st, override) {
      st.compiler.jsBuffer.concat("(");
      c(node, st, override);
      st.compiler.jsBuffer.concat(")");
    }
}

var operatorPrecedence = {
    // MemberExpression
    // These two are never used as they are a MemberExpression with the attribute 'computed' which tells what operator it uses.
    //".": 0, "[]": 0,
    // NewExpression
    // This is never used.
    //"new": 1,
    // All these are UnaryExpression or UpdateExpression and never used.
    //"!": 2, "~": 2, "-": 2, "+": 2, "++": 2, "--": 2, "typeof": 2, "void": 2, "delete": 2,
    // BinaryExpression
    "*": 3, "/": 3, "%": 3,
    "+": 4, "-": 4,
    "<<": 5, ">>": 5, ">>>": 5,
    "<": 6, "<=": 6, ">": 6, ">=": 6, "in": 6, "instanceof": 6,
    "==": 7, "!=": 7, "===": 7, "!==": 7,
    "&": 8,
    "^": 9,
    "|": 10,
    // LogicalExpression
    "&&": 11,
    "||": 12
    // ConditionalExpression
    // AssignmentExpression
}

var expressionTypePrecedence = {
    MemberExpression: 0,
    CallExpression: 1,
    NewExpression: 2,
    FunctionExpression: 3,
    UnaryExpression: 4, UpdateExpression: 4,
    BinaryExpression: 5,
    LogicalExpression: 6,
    ConditionalExpression: 7,
    AssignmentExpression: 8
}

// Returns true if subNode has higher precedence the the root node.
// If the subNode is the right (as in left/right) subNode
function nodePrecedence(node, subNode, right) {
    var nodeType = node.type,
        nodePrecedence = expressionTypePrecedence[nodeType] || -1,
        subNodePrecedence = expressionTypePrecedence[subNode.type] || -1,
        nodeOperatorPrecedence,
        subNodeOperatorPrecedence;
    return nodePrecedence < subNodePrecedence || (nodePrecedence === subNodePrecedence && isLogicalBinary(nodeType) && ((nodeOperatorPrecedence = operatorPrecedence[node.operator]) < (subNodeOperatorPrecedence = operatorPrecedence[subNode.operator]) || (right && nodeOperatorPrecedence === subNodeOperatorPrecedence)));
}

var pass1 = exports.acorn.walk.make({
ImportStatement: function(node, st, c) {
    var urlString = node.filename.value;

    st.compiler.dependencies.push(new FileDependency(new CFURL(urlString), node.localfilepath));
}
});

var indentationSpaces = 4;
var indentStep = Array(indentationSpaces + 1).join(" ");
var indentation = "";

var pass2 = exports.acorn.walk.make({
Program: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    indentation = "";
    for (var i = 0; i < node.body.length; ++i) {
      c(node.body[i], st, "Statement");
    }
    if (!generate) compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, node.end));

    // Check maybe warnings
    var maybeWarnings = st.maybeWarnings();
    if (maybeWarnings) for (var i = 0; i < maybeWarnings.length; i++) {
        var maybeWarning = maybeWarnings[i];
        if (maybeWarning.checkIfWarning(st)) {
            compiler.addWarning(maybeWarning.message);
        }
    }
},
BlockStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        buffer;
    if (generate) {
      st.indentBlockLevel = typeof st.indentBlockLevel === "undefined" ? 0 : st.indentBlockLevel + 1;
      buffer = compiler.jsBuffer;
      buffer.concat(indentation.substring(indentationSpaces));
      buffer.concat("{\n");
    }
    for (var i = 0; i < node.body.length; ++i) {
      c(node.body[i], st, "Statement");
    }
    if (generate) {
      buffer.concat(indentation.substring(indentationSpaces));
      buffer.concat("}");
      if (st.isDecl || st.indentBlockLevel > 0)
        buffer.concat("\n");
      st.indentBlockLevel--;
    }
},
ExpressionStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) compiler.jsBuffer.concat(indentation);
    c(node.expression, st, "Expression");
    if (generate) compiler.jsBuffer.concat(";\n");
},
IfStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        buffer;
    if (generate) {
      buffer = compiler.jsBuffer;
      if (!st.superNodeIsElse)
        buffer.concat(indentation);
      else
        delete st.superNodeIsElse;
      buffer.concat("if (");
    }
    c(node.test, st, "Expression");
    // We don't want EmptyStatements to generate an extra parenthesis except when it is in a while, for, ...
    if (generate) buffer.concat(node.consequent.type === "EmptyStatement" ? ");\n" : ")\n");
    indentation += indentStep;
    c(node.consequent, st, "Statement");
    indentation = indentation.substring(indentationSpaces);
    var alternate = node.alternate;
    if (alternate) {
      var alternateNotIf = alternate.type !== "IfStatement";
      if (generate) {
        var emptyStatement = alternate.type === "EmptyStatement";
        buffer.concat(indentation);
        // We don't want EmptyStatements to generate an extra parenthesis except when it is in a while, for, ...
        buffer.concat(alternateNotIf ? emptyStatement ? "else;\n" : "else\n" : "else ");
      }
      if (alternateNotIf)
        indentation += indentStep;
      else
        st.superNodeIsElse = true;

      c(alternate, st, "Statement");
      if (alternateNotIf) indentation = indentation.substring(indentationSpaces);
    }
},
LabeledStatement: function(node, st, c) {
    var compiler = st.compiler;
    if (compiler.generate) {
      var buffer = compiler.jsBuffer;
      buffer.concat(indentation);
      buffer.concat(node.label.name);
      buffer.concat(": ");
    }
    c(node.body, st, "Statement");
},
BreakStatement: function(node, st, c) {
    var compiler = st.compiler;
    if (compiler.generate) {
      compiler.jsBuffer.concat(indentation);
      if (node.label) {
        compiler.jsBuffer.concat("break ");
        compiler.jsBuffer.concat(node.label.name);
        compiler.jsBuffer.concat(";\n");
      } else
        compiler.jsBuffer.concat("break;\n");
    }
},
ContinueStatement: function(node, st, c) {
    var compiler = st.compiler;
    if (compiler.generate) {
      var buffer = compiler.jsBuffer;
      buffer.concat(indentation);
      if (node.label) {
        buffer.concat("continue ");
        buffer.concat(node.label.name);
        buffer.concat(";\n");
      } else
        buffer.concat("continue;\n");
    }
},
WithStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        buffer;
    if (generate) {
      buffer = compiler.jsBuffer;
      buffer.concat(indentation);
      buffer.concat("with(");
    }
    c(node.object, st, "Expression");
    if (generate) buffer.concat(")\n");
    indentation += indentStep;
    c(node.body, st, "Statement");
    indentation = indentation.substring(indentationSpaces);
},
SwitchStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        buffer;
    if (generate) {
      buffer = compiler.jsBuffer;
      buffer.concat(indentation);
      buffer.concat("switch(");
    }
    c(node.discriminant, st, "Expression");
    if (generate) buffer.concat(") {\n");
    for (var i = 0; i < node.cases.length; ++i) {
      var cs = node.cases[i];
      if (cs.test) {
        if (generate) {
          buffer.concat(indentation);
          buffer.concat("case ");
        }
        c(cs.test, st, "Expression");
        if (generate) buffer.concat(":\n");
      } else
        if (generate) buffer.concat("default:\n");
      indentation += indentStep;
      for (var j = 0; j < cs.consequent.length; ++j)
        c(cs.consequent[j], st, "Statement");
      indentation = indentation.substring(indentationSpaces);
    }
    if (generate) {
      buffer.concat(indentation);
      buffer.concat("}\n");
    }
},
ReturnStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        buffer;
    if (generate) {
      buffer = compiler.jsBuffer;
      buffer.concat(indentation);
      buffer.concat("return");
    }
    if (node.argument) {
      if (generate) buffer.concat(" ");
      c(node.argument, st, "Expression");
    }
    if (generate) buffer.concat(";\n");
},
ThrowStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        buffer;
    if (generate) {
      buffer = compiler.jsBuffer;
      buffer.concat(indentation);
      buffer.concat("throw ");
    }
    c(node.argument, st, "Expression");
    if (generate) buffer.concat(";\n");
},
TryStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        buffer;
    if (generate) {
      buffer = compiler.jsBuffer;
      buffer.concat(indentation);
      buffer.concat("try");
    }
    indentation += indentStep;
    c(node.block, st, "Statement");
    indentation = indentation.substring(indentationSpaces);
    for (var i = 0; i < node.handlers.length; ++i) {
      var handler = node.handlers[i], inner = new Scope(st),
          param = handler.param,
          name = param.name;
      inner.vars[name] = {type: "catch clause", node: param};
      if (generate) {
        buffer.concat(indentation);
        buffer.concat("catch(");
        buffer.concat(name);
        buffer.concat(") ");
      }
      indentation += indentStep;
      c(handler.body, inner, "ScopeBody");
      indentation = indentation.substring(indentationSpaces);
      inner.copyAddedSelfToIvarsToParent();
    }
    if (node.finalizer) {
      if (generate) {
        buffer.concat(indentation);
        buffer.concat("finally ");
      }
      indentation += indentStep;
      c(node.finalizer, st, "Statement");
      indentation = indentation.substring(indentationSpaces);
    }
},
WhileStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        body = node.body,
        buffer;
    if (generate) {
      buffer = compiler.jsBuffer;
      buffer.concat(indentation);
      buffer.concat("while (");
    }
    c(node.test, st, "Expression");
    if (generate) buffer.concat(body.type === "EmptyStatement" ? ");\n" : ")\n");
    indentation += indentStep;
    c(body, st, "Statement");
    indentation = indentation.substring(indentationSpaces);
},
DoWhileStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        buffer;
    if (generate) {
      buffer = compiler.jsBuffer;
      buffer.concat(indentation);
      buffer.concat("do\n");
    }
    indentation += indentStep;
    c(node.body, st, "Statement");
    indentation = indentation.substring(indentationSpaces);
    if (generate) {
      buffer.concat(indentation);
      buffer.concat("while (");
    }
    c(node.test, st, "Expression");
    if (generate) buffer.concat(");\n");
},
ForStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        body = node.body,
        buffer;
    if (generate) {
      buffer = compiler.jsBuffer;
      buffer.concat(indentation);
      buffer.concat("for (");
    }
    if (node.init) c(node.init, st, "ForInit");
    if (generate) buffer.concat("; ");
    if (node.test) c(node.test, st, "Expression");
    if (generate) buffer.concat("; ");
    if (node.update) c(node.update, st, "Expression");
    if (generate) buffer.concat(body.type === "EmptyStatement" ? ");\n" : ")\n");
    indentation += indentStep;
    c(body, st, "Statement");
    indentation = indentation.substring(indentationSpaces);
},
ForInStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        body = node.body,
        buffer;
    if (generate) {
      buffer = compiler.jsBuffer;
      buffer.concat(indentation);
      buffer.concat("for (");
    }
    c(node.left, st, "ForInit");
    if (generate) buffer.concat(" in ");
    c(node.right, st, "Expression");
    if (generate) buffer.concat(body.type === "EmptyStatement" ? ");\n" : ")\n");
    indentation += indentStep;
    c(body, st, "Statement");
    indentation = indentation.substring(indentationSpaces);
},
ForInit: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (node.type === "VariableDeclaration") {
        st.isFor = true;
        c(node, st);
        delete st.isFor;
    } else
      c(node, st, "Expression");
},
DebuggerStatement: function(node, st, c) {
    var compiler = st.compiler;
    if (compiler.generate) {
      var buffer = compiler.jsBuffer;
      buffer.concat(indentation);
      buffer.concat("debugger;\n");
    }
},
Function: function(node, st, c) {
  var compiler = st.compiler,
      generate = compiler.generate,
      buffer = compiler.jsBuffer;
      inner = new Scope(st),
      decl = node.type == "FunctionDeclaration";

      inner.isDecl = decl;
  for (var i = 0; i < node.params.length; ++i)
    inner.vars[node.params[i].name] = {type: "argument", node: node.params[i]};
  if (node.id) {
    (decl ? st : inner).vars[node.id.name] =
      {type: decl ? "function" : "function name", node: node.id};
    if (generate) {
      buffer.concat(node.id.name);
      buffer.concat(" = ");
    } else {
      buffer.concat(compiler.source.substring(compiler.lastPos, node.start));
      buffer.concat(node.id.name);
      buffer.concat(" = function");
      compiler.lastPos = node.id.end;
    }
  }
  if (generate) {
    buffer.concat("function(");
    for (var i = 0; i < node.params.length; ++i) {
      if (i)
        buffer.concat(", ");
      buffer.concat(node.params[i].name);
    }
    buffer.concat(")\n");
  }
  indentation += indentStep;
  c(node.body, inner, "ScopeBody");
  indentation = indentation.substring(indentationSpaces);
  inner.copyAddedSelfToIvarsToParent();
},
VariableDeclaration: function(node, st, c) {
  var compiler = st.compiler,
      generate = compiler.generate,
      buffer;
  if (generate) {
    buffer = compiler.jsBuffer;
    if (!st.isFor) buffer.concat(indentation);
    buffer.concat("var ");
  }
  for (var i = 0; i < node.declarations.length; ++i) {
    var decl = node.declarations[i],
        identifier = decl.id.name;
    if (i)
      if (generate) {
        if (st.isFor)
          buffer.concat(", ");
        else {
          buffer.concat(",\n");
          buffer.concat(indentation);
          buffer.concat("    ");
        }
      }
    st.vars[identifier] = {type: "var", node: decl.id};
    if (generate) buffer.concat(identifier);
    if (decl.init) {
      if (generate) buffer.concat(" = ");
      c(decl.init, st, "Expression");
    }
    // FIXME: Extract to function
    if (st.addedSelfToIvars) {
      var addedSelfToIvar = st.addedSelfToIvars[identifier];
      if (addedSelfToIvar) {
        var buffer = st.compiler.jsBuffer.atoms;
        for (var i = 0; i < addedSelfToIvar.length; i++) {
          var dict = addedSelfToIvar[i];
          buffer[dict.index] = "";
          compiler.addWarning(createMessage("Local declaration of '" + identifier + "' hides instance variable", dict.node, compiler.source));
        }
        st.addedSelfToIvars[identifier] = [];
      }
    }
  }
  if (generate && !st.isFor) compiler.jsBuffer.concat(";\n"); // Don't add ';' if this is a for statement but do it if this is a statement
},
ThisExpression: function(node, st, c) {
    var compiler = st.compiler;
    if (compiler.generate) compiler.jsBuffer.concat("this");
},
ArrayExpression: function(node, st, c) {
  var compiler = st.compiler,
      generate = compiler.generate;
  if (generate) compiler.jsBuffer.concat("[");
    for (var i = 0; i < node.elements.length; ++i) {
      var elt = node.elements[i];
      if (i !== 0)
          if (generate) compiler.jsBuffer.concat(", ");

      if (elt) c(elt, st, "Expression");
    }
  if (generate) compiler.jsBuffer.concat("]");
},
ObjectExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) compiler.jsBuffer.concat("{");
    for (var i = 0; i < node.properties.length; ++i)
    {
        var prop = node.properties[i];
        if (generate) {
          if (i)
            compiler.jsBuffer.concat(", ");
          st.isPropertyKey = true;
          c(prop.key, st, "Expression");
          delete st.isPropertyKey;
          compiler.jsBuffer.concat(": ");
        } else if (prop.key.raw && prop.key.raw.charAt(0) === "@") {
          compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, prop.key.start));
          compiler.lastPos = prop.key.start + 1;
        }

        c(prop.value, st, "Expression");
    }
    if (generate) compiler.jsBuffer.concat("}");
},
SequenceExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) compiler.jsBuffer.concat("(");
    for (var i = 0; i < node.expressions.length; ++i) {
      if (generate && i !== 0)
        compiler.jsBuffer.concat(", ");
      c(node.expressions[i], st, "Expression");
    }
    if (generate) compiler.jsBuffer.concat(")");
},
UnaryExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        argument = node.argument;
    if (generate) {
      if (node.prefix) {
        compiler.jsBuffer.concat(node.operator);
        if (wordPrefixOperators(node.operator))
          compiler.jsBuffer.concat(" ");
        (nodePrecedence(node, argument) ? surroundExpression(c) : c)(argument, st, "Expression");
      } else {
        (nodePrecedence(node, argument) ? surroundExpression(c) : c)(argument, st, "Expression");
        compiler.jsBuffer.concat(node.operator);
      }
    } else {
      c(argument, st, "Expression");
    }
},
UpdateExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (node.argument.type === "Dereference") {
        checkCanDereference(st, node.argument);

        // @deref(x)++ and ++@deref(x) require special handling.
        if (!generate) compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, node.start));

        // Output the dereference function, "(...)(z)"
        compiler.jsBuffer.concat((node.prefix ? "" : "(") + "(");

        // The thing being dereferenced.
        if (!generate) compiler.lastPos = node.argument.expr.start;
        c(node.argument.expr, st, "Expression");
        if (!generate) compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, node.argument.expr.end));
        compiler.jsBuffer.concat(")(");

        if (!generate) compiler.lastPos = node.argument.start;
        c(node.argument, st, "Expression");
        if (!generate) compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, node.argument.end));
        compiler.jsBuffer.concat(" " + node.operator.substring(0, 1) + " 1)" + (node.prefix ? "" : node.operator == '++' ? " - 1)" : " + 1)"));

        if (!generate) compiler.lastPos = node.end;
        return;
    }

    if (node.prefix) {
      if (generate) {
        compiler.jsBuffer.concat(node.operator);
        if (wordPrefixOperators(node.operator))
          compiler.jsBuffer.concat(" ");
      }
      (generate && nodePrecedence(node, node.argument) ? surroundExpression(c) : c)(node.argument, st, "Expression");
    } else {
      (generate && nodePrecedence(node, node.argument) ? surroundExpression(c) : c)(node.argument, st, "Expression");
      if (generate) compiler.jsBuffer.concat(node.operator);
    }
},
BinaryExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        operatorType = isInInstanceof(node.operator);
    (generate && nodePrecedence(node, node.left) ? surroundExpression(c) : c)(node.left, st, "Expression");
    if (generate) {
        var buffer = compiler.jsBuffer;
        buffer.concat(" ");
        buffer.concat(node.operator);
        buffer.concat(" ");
    }
    (generate && nodePrecedence(node, node.right, true) ? surroundExpression(c) : c)(node.right, st, "Expression");
},
LogicalExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    (generate && nodePrecedence(node, node.left) ? surroundExpression(c) : c)(node.left, st, "Expression");
    if (generate) {
        var buffer = compiler.jsBuffer;
        buffer.concat(" ");
        buffer.concat(node.operator);
        buffer.concat(" ");
    }
    (generate && nodePrecedence(node, node.right, true) ? surroundExpression(c) : c)(node.right, st, "Expression");
},
AssignmentExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        saveAssignment = st.assignment,
        buffer = compiler.jsBuffer;

    if (node.left.type === "Dereference") {
        checkCanDereference(st, node.left);

        // @deref(x) = z    -> x(z) etc
        if (!generate) buffer.concat(compiler.source.substring(compiler.lastPos, node.start));

        // Output the dereference function, "(...)(z)"
        buffer.concat("(");
        // What's being dereferenced could itself be an expression, such as when dereferencing a deref.
        if (!generate) compiler.lastPos = node.left.expr.start;
        c(node.left.expr, st, "Expression");
        if (!generate) buffer.concat(compiler.source.substring(compiler.lastPos, node.left.expr.end));
        buffer.concat(")(");

        // Now "(x)(...)". We have to manually expand +=, -=, *= etc.
        if (node.operator !== "=") {
            // Output the whole .left, not just .left.expr.
            if (!generate) compiler.lastPos = node.left.start;
            c(node.left, st, "Expression");
            if (!generate) buffer.concat(compiler.source.substring(compiler.lastPos, node.left.end));
            buffer.concat(" " + node.operator.substring(0, 1) + " ");
        }

        if (!generate) compiler.lastPos = node.right.start;
        c(node.right, st, "Expression");
        if (!generate) buffer.concat(compiler.source.substring(compiler.lastPos, node.right.end));
        buffer.concat(")");

        if (!generate) compiler.lastPos = node.end;

        return;
    }

    var saveAssignment = st.assignment;
    st.assignment = true;
    (generate && nodePrecedence(node, node.left) ? surroundExpression(c) : c)(node.left, st, "Expression");
    if (generate) {
        buffer.concat(" ");
        buffer.concat(node.operator);
        buffer.concat(" ");
    }
    st.assignment = saveAssignment;
    (generate && nodePrecedence(node, node.right, true) ? surroundExpression(c) : c)(node.right, st, "Expression");
    if (st.isRootScope() && node.left.type === "Identifier" && !st.getLvar(node.left.name))
        st.vars[node.left.name] = {type: "global", node: node.left};
},
ConditionalExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    (generate && nodePrecedence(node, node.test) ? surroundExpression(c) : c)(node.test, st, "Expression");
    if (generate)
      compiler.jsBuffer.concat(" ? ");
    c(node.consequent, st, "Expression");
    if (generate) compiler.jsBuffer.concat(" : ");
    c(node.alternate, st, "Expression");
},
NewExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) compiler.jsBuffer.concat("new ");
    (generate && nodePrecedence(node, node.callee) ? surroundExpression(c) : c)(node.callee, st, "Expression");
    if (generate) compiler.jsBuffer.concat("(");
    if (node.arguments) {
      for (var i = 0; i < node.arguments.length; ++i) {
        if (generate && i)
          compiler.jsBuffer.concat(", ");
        c(node.arguments[i], st, "Expression");
      }
    }
    if (generate) compiler.jsBuffer.concat(")");
},
CallExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    (generate && nodePrecedence(node, node.callee) ? surroundExpression(c) : c)(node.callee, st, "Expression");
    if (generate) compiler.jsBuffer.concat("(");
    if (node.arguments) {
      for (var i = 0; i < node.arguments.length; ++i) {
        if (generate && i)
          compiler.jsBuffer.concat(", ");
        c(node.arguments[i], st, "Expression");
      }
    }
    if (generate) compiler.jsBuffer.concat(")");
},
MemberExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        computed = node.computed;
    (generate && nodePrecedence(node, node.object) ? surroundExpression(c) : c)(node.object, st, "Expression");
    if (generate) {
      if (computed)
        compiler.jsBuffer.concat("[");
      else
        compiler.jsBuffer.concat(".");
    }
    st.secondMemberExpression = !computed;
    // No parentheses when it is computed, '[' amd ']' are the same thing.
    (generate && !computed && nodePrecedence(node, node.property) ? surroundExpression(c) : c)(node.property, st, "Expression");
    st.secondMemberExpression = false;
    if (generate && computed)
      compiler.jsBuffer.concat("]");
},
Identifier: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        identifier = node.name;
    if (st.currentMethodType() === "-" && !st.secondMemberExpression && !st.isPropertyKey)
    {
        var lvar = st.getLvar(identifier, true), // Only look inside method
            ivar = compiler.getIvarForClass(identifier, st);

        if (ivar)
        {
            if (lvar)
                compiler.addWarning(createMessage("Local declaration of '" + identifier + "' hides instance variable", node, compiler.source));
            else
            {
                var nodeStart = node.start;

                if (!generate) do {    // The Spider Monkey AST tree includes any parentheses in start and end properties so we have to make sure we skip those
                    compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, nodeStart));
                    compiler.lastPos = nodeStart;
                } while (compiler.source.substr(nodeStart++, 1) === "(")
                // Save the index in where the "self." string is stored and the node.
                // These will be used if we find a variable declaration that is hoisting this identifier.
                ((st.addedSelfToIvars || (st.addedSelfToIvars = Object.create(null)))[identifier] || (st.addedSelfToIvars[identifier] = [])).push({node: node, index: compiler.jsBuffer.atoms.length});
                compiler.jsBuffer.concat("self.");
            }
        } else if (!reservedIdentifiers(identifier)) {  // Don't check for warnings if it is a reserved word like self, localStorage, _cmd, etc...
            var message,
                classOrGlobal = typeof global[identifier] !== "undefined" || typeof window[identifier] !== "undefined" || compiler.getClassDef(identifier),
                globalVar = st.getLvar(identifier);
            if (classOrGlobal && (!globalVar || globalVar.type !== "class")) { // It can't be declared with a @class statement.
                /* Turned off this warning as there are many many warnings when compiling the Cappuccino frameworks - Martin
                if (lvar) {
                    message = compiler.addWarning(createMessage("Local declaration of '" + identifier + "' hides global variable", node, compiler.source));
                }*/
            } else if (!globalVar) {
                if (st.assignment) {
                    message = new GlobalVariableMaybeWarning("Creating global variable inside function or method '" + identifier + "'", node, compiler.source);
                    // Turn off these warnings for this identifier, we only want one.
                    st.vars[identifier] = {type: "remove global warning", node: node};
                } else {
                    message = new GlobalVariableMaybeWarning("Using unknown class or uninitialized global variable '" + identifier + "'", node, compiler.source);
                }
            }
            if (message)
                st.addMaybeWarning(message);
        }
    }
    if (generate) compiler.jsBuffer.concat(identifier);
},
Literal: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) {
      if (node.raw && node.raw.charAt(0) === "@")
        compiler.jsBuffer.concat(node.raw.substring(1));
      else
        compiler.jsBuffer.concat(node.raw);
    } else if (node.raw.charAt(0) === "@") {
        compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, node.start));
        compiler.lastPos = node.start + 1;
    }
},
ArrayLiteral: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (!generate) {
        compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, node.start));
        compiler.lastPos = node.start;
    }

    if (!generate) buffer.concat(" "); // Add an extra space if it looks something like this: "return(<expression>)". No space between return and expression.
    if (!node.elements.length) {
        compiler.jsBuffer.concat("objj_msgSend(objj_msgSend(CPArray, \"alloc\"), \"init\")");
    } else {
        compiler.jsBuffer.concat("objj_msgSend(objj_msgSend(CPArray, \"alloc\"), \"initWithObjects:count:\", [");
        for (var i = 0; i < node.elements.length; i++) {
            var elt = node.elements[i];

            if (i)
                compiler.jsBuffer.concat(", ");

            if (!generate) compiler.lastPos = elt.start;
            c(elt, st, "Expression");
            if (!generate) compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, elt.end));
        }
        compiler.jsBuffer.concat("], " + node.elements.length + ")");
    }

    if (!generate) compiler.lastPos = node.end;
},
DictionaryLiteral: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (!generate) {
        compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, node.start));
        compiler.lastPos = node.start;
    }

    if (!generate) buffer.concat(" "); // Add an extra space if it looks something like this: "return(<expression>)". No space between return and expression.
    if (!node.keys.length) {
        compiler.jsBuffer.concat("objj_msgSend(objj_msgSend(CPDictionary, \"alloc\"), \"init\")");
    } else {
        compiler.jsBuffer.concat("objj_msgSend(objj_msgSend(CPDictionary, \"alloc\"), \"initWithObjectsAndKeys:\"");
        for (var i = 0; i < node.keys.length; i++) {
            var key = node.keys[i],
                value = node.values[i];

            compiler.jsBuffer.concat(", ");

            if (!generate) compiler.lastPos = value.start;
            c(value, st, "Expression");
            if (!generate) compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, value.end));

            compiler.jsBuffer.concat(", ");

            if (!generate) compiler.lastPos = key.start;
            c(key, st, "Expression");
            if (!generate) compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, key.end));
        }
        compiler.jsBuffer.concat(")");
    }

    if (!generate) compiler.lastPos = node.end;
},
ImportStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        buffer = compiler.jsBuffer;

    if (!generate) buffer.concat(compiler.source.substring(compiler.lastPos, node.start));
    buffer.concat("objj_executeFile(\"");
    buffer.concat(node.filename.value);
    buffer.concat(node.localfilepath ? "\", YES);" : "\", NO);");
    if (!generate) compiler.lastPos = node.end;
},
ClassDeclarationStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        saveJSBuffer = compiler.jsBuffer,
        className = node.classname.name,
        classDef = compiler.getClassDef(className),
        classScope = new Scope(st),
        isInterfaceDeclaration = node.type === "InterfaceDeclarationStatement",
        protocols = node.protocols;

    compiler.imBuffer = new StringBuffer();
    compiler.cmBuffer = new StringBuffer();
    compiler.classBodyBuffer = new StringBuffer();      // TODO: Check if this is needed

    if (!generate) saveJSBuffer.concat(compiler.source.substring(compiler.lastPos, node.start));

    // First we declare the class
    if (node.superclassname)
    {
        // Must have methods dictionaries and ivars dictionary to be a real implementaion declaration.
        // Without it is a "@class" declaration (without both ivars dictionary and method dictionaries) or
        // "interface" declaration (without ivars dictionary)
        // TODO: Create a ClassDef object and add this logic to it
        if (classDef && classDef.ivars)
            // It has a real implementation declaration already
            throw compiler.error_message("Duplicate class " + className, node.classname);

        if (isInterfaceDeclaration && classDef && classDef.instanceMethods && classDef.classMethods)
            // It has a interface declaration already
            throw compiler.error_message("Duplicate interface definition for class " + className, node.classname);
        var superClassDef = compiler.getClassDef(node.superclassname.name);
        if (!superClassDef)
        {
            var errorMessage = "Can't find superclass " + node.superclassname.name;
            for (var i = ObjJAcornCompiler.importStack.length; --i >= 0;)
                errorMessage += "\n" + Array((ObjJAcornCompiler.importStack.length - i) * 2 + 1).join(" ") + "Imported by: " + ObjJAcornCompiler.importStack[i];
            throw compiler.error_message(errorMessage, node.superclassname);
        }

        classDef = new ClassDef(!isInterfaceDeclaration, className, superClassDef, Object.create(null));

        saveJSBuffer.concat("{var the_class = objj_allocateClassPair(" + node.superclassname.name + ", \"" + className + "\"),\nmeta_class = the_class.isa;");
    }
    else if (node.categoryname)
    {
        classDef = compiler.getClassDef(className);
        if (!classDef)
            throw compiler.error_message("Class " + className + " not found ", node.classname);

        saveJSBuffer.concat("{\nvar the_class = objj_getClass(\"" + className + "\")\n");
        saveJSBuffer.concat("if(!the_class) throw new SyntaxError(\"*** Could not find definition for class \\\"" + className + "\\\"\");\n");
        saveJSBuffer.concat("var meta_class = the_class.isa;");
    }
    else
    {
        classDef = new ClassDef(!isInterfaceDeclaration, className, null, Object.create(null));

        saveJSBuffer.concat("{var the_class = objj_allocateClassPair(Nil, \"" + className + "\"),\nmeta_class = the_class.isa;");
    }

    if (protocols)
        for (var i = 0, size = protocols.length; i < size; i++)
        {
            saveJSBuffer.concat("\nvar aProtocol = objj_getProtocol(\"" + protocols[i].name + "\");");
            saveJSBuffer.concat("\nif (!aProtocol) throw new SyntaxError(\"*** Could not find definition for protocol \\\"" + protocols[i].name + "\\\"\");");
            saveJSBuffer.concat("\nclass_addProtocol(the_class, aProtocol);");
        }
    /*
    if (isInterfaceDeclaration)
        classDef.interfaceDeclaration = true;
*/
    classScope.classDef = classDef;
    compiler.currentSuperClass = "objj_getClass(\"" + className + "\").super_class";
    compiler.currentSuperMetaClass = "objj_getMetaClass(\"" + className + "\").super_class";

    var firstIvarDeclaration = true,
        hasAccessors = false;

    // Then we add all ivars
    if (node.ivardeclarations)
        for (var i = 0; i < node.ivardeclarations.length; ++i)
        {
            var ivarDecl = node.ivardeclarations[i],
                ivarType = ivarDecl.ivartype ? ivarDecl.ivartype.name : null,
                ivarName = ivarDecl.id.name,
                ivars = classDef.ivars,
                ivar = {"type": ivarType, "name": ivarName},
                accessors = ivarDecl.accessors;

            if (ivars[ivarName])
                throw compiler.error_message("Instance variable '" + ivarName + "'is already declared for class " + className, ivarDecl.id);

            if (firstIvarDeclaration)
            {
                firstIvarDeclaration = false;
                saveJSBuffer.concat("class_addIvars(the_class, [");
            }
            else
                saveJSBuffer.concat(", ");

            if (compiler.flags & ObjJAcornCompiler.Flags.IncludeTypeSignatures)
                saveJSBuffer.concat("new objj_ivar(\"" + ivarName + "\", \"" + ivarType + "\")");
            else
                saveJSBuffer.concat("new objj_ivar(\"" + ivarName + "\")");

            if (ivarDecl.outlet)
                ivar.outlet = true;
            ivars[ivarName] = ivar;
            if (!classScope.ivars)
                classScope.ivars = Object.create(null);
            classScope.ivars[ivarName] = {type: "ivar", name: ivarName, node: ivarDecl.id, ivar: ivar};

            if (accessors)
            {
                // TODO: This next couple of lines for getting getterName and setterName are duplicated from below. Create functions for this.
                var property = (accessors.property && accessors.property.name) || ivarName,
                    getterName = (accessors.getter && accessors.getter.name) || property;

                classDef.addInstanceMethod(new MethodDef(getterName, [ivarType]));

                if (!accessors.readonly)
                {
                    var setterName = accessors.setter ? accessors.setter.name : null;

                    if (!setterName)
                    {
                        var start = property.charAt(0) == '_' ? 1 : 0;

                        setterName = (start ? "_" : "") + "set" + property.substr(start, 1).toUpperCase() + property.substring(start + 1) + ":";
                    }
                    classDef.addInstanceMethod(new MethodDef(setterName, ["void", ivarType]));
                }
                hasAccessors = true;
            }
        }

    if (!firstIvarDeclaration)
        saveJSBuffer.concat("]);");

    // If we have accessors add get and set methods for them
    if (!isInterfaceDeclaration && hasAccessors)
    {
        var getterSetterBuffer = new StringBuffer();

        // Add the class declaration to compile accessors correctly
        getterSetterBuffer.concat(compiler.source.substring(node.start, node.endOfIvars));
        getterSetterBuffer.concat("\n");

        for (var i = 0; i < node.ivardeclarations.length; ++i)
        {
            var ivarDecl = node.ivardeclarations[i],
                ivarType = ivarDecl.ivartype ? ivarDecl.ivartype.name : null,
                ivarName = ivarDecl.id.name,
                accessors = ivarDecl.accessors;

            if (!accessors)
                continue;

            var property = (accessors.property && accessors.property.name) || ivarName,
                getterName = (accessors.getter && accessors.getter.name) || property,
                getterCode = "- (" + (ivarType ? ivarType : "id") + ")" + getterName + "\n{\nreturn " + ivarName + ";\n}\n";

            getterSetterBuffer.concat(getterCode);

            if (accessors.readonly)
                continue;

            var setterName = accessors.setter ? accessors.setter.name : null;

            if (!setterName)
            {
                var start = property.charAt(0) == '_' ? 1 : 0;

                setterName = (start ? "_" : "") + "set" + property.substr(start, 1).toUpperCase() + property.substring(start + 1) + ":";
            }

            var setterCode = "- (void)" + setterName + "(" + (ivarType ? ivarType : "id") +  ")newValue\n{\n";

            if (accessors.copy)
                setterCode += "if (" + ivarName + " !== newValue)\n" + ivarName + " = [newValue copy];\n}\n";
            else
                setterCode += ivarName + " = newValue;\n}\n";

            getterSetterBuffer.concat(setterCode);
        }

        getterSetterBuffer.concat("\n@end");

        // Remove all @accessors or we will get a recursive loop in infinity
        var b = getterSetterBuffer.toString().replace(/@accessors(\(.*\))?/g, "");
        var imBuffer = ObjJAcornCompiler.compileToIMBuffer(b, "Accessors", compiler.flags, compiler.classDefs, compiler.protocolDefs);

        // Add the accessors methods first to instance method buffer.
        // This will allow manually added set and get methods to override the compiler generated
        compiler.imBuffer.concat(imBuffer);
    }

    // We will store the classDef first after accessors are done so we don't get a duplicate class error
    compiler.classDefs[className] = classDef;

    var bodies = node.body,
        bodyLength = bodies.length;

    if (bodyLength > 0)
    {
        if (!generate)
            compiler.lastPos = bodies[0].start;

        // And last add methods and other statements
        for (var i = 0; i < bodyLength; ++i) {
            var body = bodies[i];
            c(body, classScope, "Statement");
        }
        if (!generate)
            saveJSBuffer.concat(compiler.source.substring(compiler.lastPos, body.end));
    }
    // We must make a new class object for our class definition if it's not a category
    if (!isInterfaceDeclaration && !node.categoryname) {
        saveJSBuffer.concat("objj_registerClassPair(the_class);\n");
    }

    // Add instance methods
    if (compiler.imBuffer.isEmpty())
    {
        saveJSBuffer.concat("class_addMethods(the_class, [");
        saveJSBuffer.atoms.push.apply(saveJSBuffer.atoms, compiler.imBuffer.atoms); // FIXME: Move this append to StringBuffer
        saveJSBuffer.concat("]);\n");
    }

    // Add class methods
    if (compiler.cmBuffer.isEmpty())
    {
        saveJSBuffer.concat("class_addMethods(meta_class, [");
        saveJSBuffer.atoms.push.apply(saveJSBuffer.atoms, compiler.cmBuffer.atoms); // FIXME: Move this append to StringBuffer
        saveJSBuffer.concat("]);\n");
    }

    saveJSBuffer.concat("}");

    compiler.jsBuffer = saveJSBuffer;

    // Skip the "@end"
    if (!generate)
        compiler.lastPos = node.end;

    // If the class conforms to protocols check that all required methods are implemented
    if (protocols)
    {
        // Lookup the protocolDefs for the protocols
        var protocolDefs = [];

        for (var i = 0, size = protocols.length; i < size; i++)
            protocolDefs.push(compiler.getProtocolDef(protocols[i].name));

        var unimplementedMethods = classDef.listOfNotImplementedMethodsForProtocols(protocolDefs);

        if (unimplementedMethods && unimplementedMethods.length > 0)
            for (var i = 0, size = unimplementedMethods.length; i < size; i++) {
                var unimplementedMethod = unimplementedMethods[i],
                    methodDef = unimplementedMethod.methodDef,
                    protocolDef = unimplementedMethod.protocolDef;

                compiler.addWarning(createMessage("Method '" + methodDef.name + "' in protocol '" + protocolDef.name + "' is not implemented", node.classname, compiler.source));
            }
    }
},
ProtocolDeclarationStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        buffer = compiler.jsBuffer,
        protocolName = node.protocolname.name,
        protocolDef = compiler.getProtocolDef(protocolName),
        protocols = node.protocols,
        protocolScope = new Scope(st),
        inheritFromProtocols = [];

    if (protocolDef)
        throw compiler.error_message("Duplicate protocol " + protocolName, node.protocolname);

    compiler.imBuffer = new StringBuffer();
    compiler.cmBuffer = new StringBuffer();

    if (!generate)
        buffer.concat(compiler.source.substring(compiler.lastPos, node.start));

    buffer.concat("{var the_protocol = objj_allocateProtocol(\"" + protocolName + "\");");

    if (protocols)
        for (var i = 0, size = protocols.length; i < size; i++)
        {
            var protocol = protocols[i],
                inheritFromProtocolName = protocol.name;
                inheritProtocolDef = compiler.getProtocolDef(inheritFromProtocolName);

            if (!inheritProtocolDef)
                throw compiler.error_message("Can't find protocol " + inheritFromProtocolName, protocol);

            buffer.concat("\nvar aProtocol = objj_getProtocol(\"" + inheritFromProtocolName + "\");");
            buffer.concat("\nif (!aProtocol) throw new SyntaxError(\"*** Could not find definition for protocol \\\"" + protocolName + "\\\"\");");
            buffer.concat("\nprotocol_addProtocol(the_protocol, aProtocol);");
            inheritFromProtocols.push(inheritProtocolDef);
        }

    protocolDef = new ProtocolDef(protocolName, inheritFromProtocols);
    compiler.protocolDefs[protocolName] = protocolDef;
    protocolScope.protocolDef = protocolDef;

    var someRequired = node.required;

    if (someRequired) {
        var requiredLength = someRequired.length;

        if (requiredLength > 0)
        {
            // We only add the required methods
            for (var i = 0; i < requiredLength; ++i)
            {
                var required = someRequired[i];
                if (!generate)
                    compiler.lastPos = required.start;
                c(required, protocolScope, "Statement");
            }
            if (!generate)
                buffer.concat(compiler.source.substring(compiler.lastPos, required.end));
        }
    }

    buffer.concat("\nobjj_registerProtocol(the_protocol);\n");

    // Add instance methods
    if (compiler.imBuffer.isEmpty())
    {
        buffer.concat("protocol_addMethodDescriptions(the_protocol, [");
        buffer.atoms.push.apply(buffer.atoms, compiler.imBuffer.atoms); // FIXME: Move this append to StringBuffer
        buffer.concat("], true, true);\n");
    }

    // Add class methods
    if (compiler.cmBuffer.isEmpty())
    {
        buffer.concat("protocol_addMethodDescriptions(the_protocol, [");
        buffer.atoms.push.apply(buffer.atoms, compiler.cmBuffer.atoms); // FIXME: Move this append to StringBuffer
        buffer.concat("], true, false);\n");
    }

    buffer.concat("}");

    compiler.jsBuffer = buffer;

    // Skip the "@end"
    if (!generate)
        compiler.lastPos = node.end;
},
MethodDeclarationStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        saveJSBuffer = compiler.jsBuffer,
        methodScope = new Scope(st),
        isInstanceMethodType = node.methodtype === '-';
        selectors = node.selectors,
        nodeArguments = node.arguments,
        returnType = node.returntype,
        types = [returnType ? returnType.name : (node.action ? "void" : "id")],
        returnTypeProtocols = returnType ? returnType.protocols : null;
        selector = selectors[0].name;    // There is always at least one selector

    if (returnTypeProtocols)
        for (var i = 0, size = returnTypeProtocols.length; i < size; i++) {
            var returnTypeProtocol = returnTypeProtocols[i];
            if (!compiler.getProtocolDef(returnTypeProtocol.name)) {
                compiler.addWarning(createMessage("Cannot find protocol declaration for '" + returnTypeProtocol.name + "'", returnTypeProtocol, compiler.source));
            }
        }

    if (!generate)
        saveJSBuffer.concat(compiler.source.substring(compiler.lastPos, node.start));

    compiler.jsBuffer = isInstanceMethodType ? compiler.imBuffer : compiler.cmBuffer;

    // Put together the selector. Maybe this should be done in the parser...
    for (var i = 0; i < nodeArguments.length; i++) {
        var argument = nodeArguments[i],
            argumentType = argument.type,
            argumentTypeName = argumentType ? argumentType.name : "id",
            argumentProtocols = argumentType ? argumentType.protocols : null;

        types.push(argumentType ? argumentType.name : "id");

        if (argumentProtocols) for (var j = 0, size = argumentProtocols.length; j < size; j++)
        {
            var argumentProtocol = argumentProtocols[j];
            if (!compiler.getProtocolDef(argumentProtocol.name))
                compiler.addWarning(createMessage("Cannot find protocol declaration for '" + argumentProtocol.name + "'", argumentProtocol, compiler.source));
        }

        if (i === 0)
            selector += ":";
        else
            selector += (selectors[i] ? selectors[i].name : "") + ":";
    }

    if (compiler.jsBuffer.isEmpty())           // Add comma separator if this is not first method in this buffer
        compiler.jsBuffer.concat(", ");

    compiler.jsBuffer.concat("new objj_method(sel_getUid(\"");
    compiler.jsBuffer.concat(selector);
    compiler.jsBuffer.concat("\"), ");

    if (node.body)
    {
        compiler.jsBuffer.concat("function");

        if (compiler.flags & ObjJAcornCompiler.Flags.IncludeDebugSymbols)
        {
            compiler.jsBuffer.concat(" $" + st.currentClassName() + "__" + selector.replace(/:/g, "_"));
        }

        compiler.jsBuffer.concat("(self, _cmd");

        methodScope.methodType = node.methodtype;
        if (nodeArguments) for (var i = 0; i < nodeArguments.length; i++)
        {
            var argument = nodeArguments[i],
                argumentName = argument.identifier.name;

            compiler.jsBuffer.concat(", ");
            compiler.jsBuffer.concat(argumentName);
            methodScope.vars[argumentName] = {type: "method argument", node: argument};
        }

        compiler.jsBuffer.concat(")\n");

        if (!generate)
            compiler.lastPos = node.startOfBody;
        indentation += indentStep;
        c(node.body, methodScope, "Statement");
        indentation = indentation.substring(indentationSpaces);
        if (!generate)
            compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, node.body.end));

        compiler.jsBuffer.concat("\n");
    } else { // It is a interface or protocol declatartion and we don't have a method implementation
        compiler.jsBuffer.concat("Nil\n");
    }

    if (compiler.flags & ObjJAcornCompiler.Flags.IncludeDebugSymbols)
        compiler.jsBuffer.concat(","+JSON.stringify(types));

    compiler.jsBuffer.concat(")");
    compiler.jsBuffer = saveJSBuffer;

    if (!generate)
        compiler.lastPos = node.end;

    // Add the method to the class or protocol definition
    var def = st.classDef,
        alreadyDeclared;

    // But first, if it is a class definition check if it is declared in superclass or interface declaration
    if (def)
        alreadyDeclared = isInstanceMethodType ? def.getInstanceMethod(selector) : def.getClassMethod(selector);
    else
        def = st.protocolDef;

    if (!def)
        throw "InternalError: MethodDeclaration without ClassDeclaration or ProtocolDeclaration at line: " + exports.acorn.getLineInfo(compiler.source, node.start).line;

    // Create warnings if types does not corresponds to method declaration in superclass or interface declarations
    // If we don't find the method in superclass or interface declarations above or if it is a protocol
    // declaration, try to find it in any of the conforming protocols
    if (!alreadyDeclared) {
        var protocols = def.protocols;

        if (protocols)
            for (var i = 0, size = protocols.length; i < size; i++) {
                var protocol = protocols[i],
                    alreadyDeclared = isInstanceMethodType ? protocol.getInstanceMethod(selector) : protocol.getClassMethod(selector);

                if (alreadyDeclared)
                    break;
            }
    }

    if (alreadyDeclared) {
        var declaredTypes = alreadyDeclared.types;

        if (declaredTypes) {
            var typeSize = declaredTypes.length;
            if (typeSize > 0) {
                // First type is return type
                var declaredReturnType = declaredTypes[0];

                // Create warning if return types is not the same. It is ok if superclass has 'id' and subclass has a class type
                if (declaredReturnType !== types[0] && !(declaredReturnType === 'id' && returnType && returnType.typeisclass))
                    compiler.addWarning(createMessage("Conflicting return type in implementation of '" + selector + "': '" + declaredReturnType + "' vs '" + types[0] + "'", returnType || node.action || selectors[0], compiler.source));

                // Check the parameter types. The size of the two type arrays should be the same as they have the same selector.
                for (var i = 1; i < typeSize; i++) {
                    var parameterType = declaredTypes[i];

                    if (parameterType !== types[i] && !(parameterType === 'id' && nodeArguments[i - 1].type.typeisclass))
                        compiler.addWarning(createMessage("Conflicting parameter types in implementation of '" + selector + "': '" + parameterType + "' vs '" + types[i] + "'", nodeArguments[i - 1].type || nodeArguments[i - 1].identifier, compiler.source));
                }
            }
        }
    }

    // Now we add it
    var methodDef = new MethodDef(selector, types);

    if (isInstanceMethodType)
        def.addInstanceMethod(methodDef);
    else
        def.addClassMethod(methodDef);
},
MessageSendExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        buffer = compiler.jsBuffer;
    if (!generate) {
        buffer.concat(compiler.source.substring(compiler.lastPos, node.start));
        compiler.lastPos = node.object ? node.object.start : node.arguments.length ? node.arguments[0].start : node.end;
    }
    if (node.superObject)
    {
        if (!generate) buffer.concat(" "); // Add an extra space if it looks something like this: "return(<expression>)". No space between return and expression.
        buffer.concat("objj_msgSendSuper(");
        buffer.concat("{ receiver:self, super_class:" + (st.currentMethodType() === "+" ? compiler.currentSuperMetaClass : compiler.currentSuperClass ) + " }");
    }
    else
    {
        if (!generate) buffer.concat(" "); // Add an extra space if it looks something like this: "return(<expression>)". No space between return and expression.
        buffer.concat("objj_msgSend(");
        c(node.object, st, "Expression");
        if (!generate) buffer.concat(compiler.source.substring(compiler.lastPos, node.object.end));
    }

    var selectors = node.selectors,
        arguments = node.arguments,
        firstSelector = selectors[0],
        selector = firstSelector ? firstSelector.name : "";    // There is always at least one selector

    // Put together the selector. Maybe this should be done in the parser...
    for (var i = 0; i < arguments.length; i++)
        if (i === 0)
            selector += ":";
        else
            selector += (selectors[i] ? selectors[i].name : "") + ":";

    buffer.concat(", \"");
    buffer.concat(selector); // FIXME: sel_getUid(selector + "") ? This FIXME is from the old preprocessor compiler
    buffer.concat("\"");

    if (node.arguments) for (var i = 0; i < node.arguments.length; i++)
    {
        var argument = node.arguments[i];

        buffer.concat(", ");
        if (!generate)
            compiler.lastPos = argument.start;
        c(argument, st, "Expression");
        if (!generate) {
            buffer.concat(compiler.source.substring(compiler.lastPos, argument.end));
            compiler.lastPos = argument.end;
        }
    }

    // TODO: Move this 'if' with body up inside the node.argument 'if'
    if (node.parameters) for (var i = 0; i < node.parameters.length; ++i)
    {
        var parameter = node.parameters[i];

        buffer.concat(", ");
        if (!generate)
            compiler.lastPos = parameter.start;
        c(parameter, st, "Expression");
        if (!generate) {
            buffer.concat(compiler.source.substring(compiler.lastPos, parameter.end));
            compiler.lastPos = parameter.end;
        }
    }

    buffer.concat(")");
    if (!generate) compiler.lastPos = node.end;
},
SelectorLiteralExpression: function(node, st, c) {
    var compiler = st.compiler,
        buffer = compiler.jsBuffer,
        generate = compiler.generate;
    if (!generate) {
        buffer.concat(compiler.source.substring(compiler.lastPos, node.start));
        buffer.concat(" "); // Add an extra space if it looks something like this: "return(@selector(a:))". No space between return and expression.
    }
    buffer.concat("sel_getUid(\"");
    buffer.concat(node.selector);
    buffer.concat("\")");
    if (!generate) compiler.lastPos = node.end;
},
ProtocolLiteralExpression: function(node, st, c) {
    var compiler = st.compiler,
        buffer = compiler.jsBuffer,
        generate = compiler.generate;
    if (!generate) {
        buffer.concat(compiler.source.substring(compiler.lastPos, node.start));
        buffer.concat(" "); // Add an extra space if it looks something like this: "return(@protocol(a))". No space between return and expression.
    }
    buffer.concat("objj_getProtocol(\"");
    buffer.concat(node.id.name);
    buffer.concat("\")");
    if (!generate) compiler.lastPos = node.end;
},
Reference: function(node, st, c) {
    var compiler = st.compiler,
        buffer = compiler.jsBuffer,
        generate = compiler.generate;
    if (!generate) {
        buffer.concat(compiler.source.substring(compiler.lastPos, node.start));
        buffer.concat(" "); // Add an extra space if it looks something like this: "return(<expression>)". No space between return and expression.
    }
    buffer.concat("function(__input) { if (arguments.length) return ");
    buffer.concat(node.element.name);
    buffer.concat(" = __input; return ");
    buffer.concat(node.element.name);
    buffer.concat("; }");
    if (!generate) compiler.lastPos = node.end;
},
Dereference: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;

    checkCanDereference(st, node.expr);

    // @deref(y) -> y()
    // @deref(@deref(y)) -> y()()
    if (!generate) {
        compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, node.start));
        compiler.lastPos = node.expr.start;
    }
    c(node.expr, st, "Expression");
    if (!generate) compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, node.expr.end));
    compiler.jsBuffer.concat("()");
    if (!generate) compiler.lastPos = node.end;
},
ClassStatement: function(node, st, c) {
    var compiler = st.compiler;
    if (!compiler.generate) {
        compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, node.start));
        compiler.lastPos = node.start;
        compiler.jsBuffer.concat("//");
    }
    var className = node.id.name;
    if (!compiler.getClassDef(className)) {
        classDef = new ClassDef(false, className);
        compiler.classDefs[className] = classDef;
    }
    st.vars[node.id.name] = {type: "class", node: node.id};
},
GlobalStatement: function(node, st, c) {
    var compiler = st.compiler;
    if (!compiler.generate) {
        compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, node.start));
        compiler.lastPos = node.start;
        compiler.jsBuffer.concat("//");
    }
    st.rootScope().vars[node.id.name] = {type: "global", node: node.id};
},
PreprocessStatement: function(node, st, c) {
    var compiler = st.compiler;
    if (!compiler.generate) {
      compiler.jsBuffer.concat(compiler.source.substring(compiler.lastPos, node.start));
      compiler.lastPos = node.start;
      compiler.jsBuffer.concat("//");
    }
}
});
