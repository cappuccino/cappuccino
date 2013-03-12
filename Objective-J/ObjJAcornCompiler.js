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
    return this.classDef ? this.classDef.className : this.prev ? this.prev.currentClassName() : null;
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

// This is for IE8 support. It doesn't have the Object.create function
if (typeof Object.create !== 'function')
{
   Object.create = function (o)
   {
       function F() {}
       F.prototype = o;
       return new F();
   };
}

var currentCompilerFlags = "";

var reservedIdentifiers = exports.acorn.makePredicate("self _cmd undefined localStorage arguments");

var wordPrefixOperators = exports.acorn.makePredicate("delete in instanceof new typeof void");

var ObjJAcornCompiler = function(/*String*/ aString, /*CFURL*/ aURL, /*unsigned*/ flags, /*unsigned*/ pass, /* Dictionary */ classDefs)
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
    this.lastPos = 0;
    compile(this.tokens, new Scope(null ,{ compiler: this }), pass === 2 ? pass2 : pass1);
}

exports.ObjJAcornCompiler = ObjJAcornCompiler;

exports.ObjJAcornCompiler.compileToExecutable = function(/*String*/ aString, /*CFURL*/ aURL, /*unsigned*/ flags)
{
    ObjJAcornCompiler.currentCompileFile = aURL;
    return new ObjJAcornCompiler(aString, aURL, flags, 2).executable();
}

exports.ObjJAcornCompiler.compileToIMBuffer = function(/*String*/ aString, /*CFURL*/ aURL, /*unsigned*/ flags, classDefs)
{
    return new ObjJAcornCompiler(aString, aURL, flags, 2, classDefs).IMBuffer();
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
    print("source: " + this.URL + "\n" + this.source + "\nCompiled into:\n" + this.jsBuffer.toString());

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

ObjJAcornCompiler.Flags.IncludeDebugSymbols = 1 << 0;
ObjJAcornCompiler.Flags.IncludeTypeSignatures = 1 << 1;

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
        c = this.getClassDef(c.superClassName);
    }
}

ObjJAcornCompiler.prototype.getClassDef = function(/* String */ aClassName)
{
    if (!aClassName) return null;

	var	c = this.classDefs[aClassName];

	if (c) return c;

	if (objj_getClass)
	{
		var aClass = objj_getClass(aClassName);
		if (aClass)
		{
			var ivars = class_copyIvarList(aClass),
				ivarSize = ivars.length,
				myIvars = Object.create(null),
				superClass = aClass.super_class;

			for (var i = 0; i < ivarSize; i++)
			{
				var ivar = ivars[i];

			    myIvars[ivar.name] = {"type": ivar.type, "name": ivar.name};
			}
			c = {"className": aClassName, "ivars": myIvars};

			if (superClass)
				c.superClassName = superClass.name;
			this.classDefs[aClassName] = c;
			return c;
		}
	}

	return null;
//	classDef = {"className": className, "superClassName": superClassName, "ivars": Object.create(null), "methods": Object.create(null)};
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
        visitor[override || node.type](node, st, c);
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

var pass1 = exports.acorn.walk.make({
ImportStatement: function(node, st, c) {
    var urlString = node.filename.value;

    st.compiler.dependencies.push(new FileDependency(new CFURL(urlString), node.localfilepath));
}
});

var pass2 = exports.acorn.walk.make({
Program: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    for (var i = 0; i < node.body.length; ++i) {
      c(node.body[i], st, "Statement");
    }
    if (!generate) CONCAT(compiler.jsBuffer,compiler.source.substring(st.compiler.lastPos, node.end));

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
        generate = compiler.generate;
    if (generate) CONCAT(compiler.jsBuffer, "{\n");
    for (var i = 0; i < node.body.length; ++i) {
      c(node.body[i], st, "Statement");
    }
    if (generate) CONCAT(compiler.jsBuffer, "}\n");
},
ExpressionStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    c(node.expression, st, "Expression");
    if (generate) CONCAT(compiler.jsBuffer, ";\n");
},
IfStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) CONCAT(compiler.jsBuffer, "if (");
    c(node.test, st, "Expression");
    if (generate) CONCAT(compiler.jsBuffer, ") ");
    c(node.consequent, st, "Statement");
    if (node.alternate) {
      if (generate) CONCAT(compiler.jsBuffer, "else ");
      c(node.alternate, st, "Statement");
    }
},
LabeledStatement: function(node, st, c) {
    var compiler = st.compiler;
    if (compiler.generate) {
      CONCAT(compiler.jsBuffer, node.label.name);
      CONCAT(compiler.jsBuffer, ": ");
    }
    c(node.body, st, "Statement");
},
BreakStatement: function(node, st, c) {
    var compiler = st.compiler;
    if (compiler.generate) {
      if (node.label) {
        CONCAT(compiler.jsBuffer, "break ");
        CONCAT(compiler.jsBuffer, node.label.name);
        CONCAT(compiler.jsBuffer, ";\n");
      } else
        CONCAT(compiler.jsBuffer, "break;\n");
    }
},
ContinueStatement: function(node, st, c) {
    var compiler = st.compiler;
    if (compiler.generate) {
      if (node.label) {
        CONCAT(compiler.jsBuffer, "continue ");
        CONCAT(compiler.jsBuffer, node.label.name);
        CONCAT(compiler.jsBuffer, ";\n");
      } else
        CONCAT(compiler.jsBuffer, "continue;\n");
    }
},
WithStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) CONCAT(compiler.jsBuffer, "with(");
    c(node.object, st, "Expression");
    if (generate) CONCAT(compiler.jsBuffer, ") ");
    c(node.body, st, "Statement");
},
SwitchStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) CONCAT(compiler.jsBuffer, "switch(");
    c(node.discriminant, st, "Expression");
    if (generate) CONCAT(compiler.jsBuffer, ") {\n");
    for (var i = 0; i < node.cases.length; ++i) {
      var cs = node.cases[i];
      if (cs.test) {
        if (generate) CONCAT(compiler.jsBuffer, "case ");
        c(cs.test, st, "Expression");
        if (generate) CONCAT(compiler.jsBuffer, ":\n");
      } else
        if (generate) CONCAT(compiler.jsBuffer, "default: ");
      for (var j = 0; j < cs.consequent.length; ++j)
        c(cs.consequent[j], st, "Statement");
    }
    if (generate) CONCAT(compiler.jsBuffer, "}\n");
},
ReturnStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) CONCAT(compiler.jsBuffer, "return");
    if (node.argument) {
      if (generate) CONCAT(compiler.jsBuffer, " ");
      c(node.argument, st, "Expression");
    }
    if (generate) CONCAT(compiler.jsBuffer, ";\n");
},
ThrowStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) CONCAT(compiler.jsBuffer, "throw ");
    c(node.argument, st, "Expression");
    if (generate) CONCAT(compiler.jsBuffer, ";\n");
},
TryStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) CONCAT(compiler.jsBuffer, "try");
      c(node.block, st, "Statement");
    for (var i = 0; i < node.handlers.length; ++i) {
      var handler = node.handlers[i], inner = new Scope(st),
          param = handler.param,
          name = param.name;
      inner.vars[name] = {type: "catch clause", node: param};
      if (generate) CONCAT(compiler.jsBuffer, "catch(");
      if (generate) CONCAT(compiler.jsBuffer, name);
      if (generate) CONCAT(compiler.jsBuffer, ")");
      c(handler.body, inner, "ScopeBody");
      inner.copyAddedSelfToIvarsToParent();
    }
    if (node.finalizer) c(node.finalizer, st, "Statement");
},
WhileStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) CONCAT(compiler.jsBuffer, "while(");
    c(node.test, st, "Expression");
    if (generate) CONCAT(compiler.jsBuffer, ")");
    c(node.body, st, "Statement");
},
DoWhileStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) CONCAT(compiler.jsBuffer, "do");
    c(node.body, st, "Statement");
    if (generate) CONCAT(compiler.jsBuffer, "while(");
    c(node.test, st, "Expression");
    if (generate) CONCAT(compiler.jsBuffer, ");\n");
},
ForStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) CONCAT(compiler.jsBuffer, "for(");
    if (node.init) c(node.init, st, "ForInit");
    if (generate) CONCAT(compiler.jsBuffer, "; ");
    if (node.test) c(node.test, st, "Expression");
    if (generate) CONCAT(compiler.jsBuffer, "; ");
    if (node.update) c(node.update, st, "Expression");
    if (generate) CONCAT(compiler.jsBuffer, ")");
    c(node.body, st, "Statement");
},
ForInStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) CONCAT(compiler.jsBuffer, "for(");
    c(node.left, st, "ForInit");
    if (generate) CONCAT(compiler.jsBuffer, " in ");
    c(node.right, st, "Expression");
    if (generate) CONCAT(compiler.jsBuffer, ")");
    c(node.body, st, "Statement");
},
DebuggerStatement: function(node, st, c) {
    var compiler = st.compiler;
    if (compiler.generate) CONCAT(compiler.jsBuffer, "debugger;\n");
},
// FIXME: Missing stuff
Function: function(node, st, c) {
  var compiler = st.compiler,
      generate = compiler.generate;
  var inner = new Scope(st);
  if (node.id) {
    var decl = node.type == "FunctionDeclaration";
    (decl ? st : inner).vars[node.id.name] =
      {type: decl ? "function" : "function name", node: node.id};
    if (generate) {
      CONCAT(compiler.jsBuffer, node.id.name);
      CONCAT(compiler.jsBuffer, " = function(");
      for (var i = 0; i < node.params.length; ++i) {
        var paramNode = node.params[i],
            name = paramNode.name;
        if (i)
          CONCAT(compiler.jsBuffer, ", ");
        inner.vars[name] = {type: "argument", node: paramNode};
        CONCAT(compiler.jsBuffer, name);
      }
      CONCAT(compiler.jsBuffer, ")");
    } else {
        CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.start));
        CONCAT(compiler.jsBuffer, node.id.name);
        CONCAT(compiler.jsBuffer, " = function");
        compiler.lastPos = node.id.end;
    }
  }
  c(node.body, inner, "ScopeBody");
  inner.copyAddedSelfToIvarsToParent();
},
VariableDeclaration: function(node, st, c) {
  var compiler = st.compiler,
      generate = compiler.generate;
  if (generate) CONCAT(compiler.jsBuffer, "var ");
  for (var i = 0; i < node.declarations.length; ++i) {
    var decl = node.declarations[i],
        identifier = decl.id.name;
    if (i !== 0)
      if (generate) CONCAT(compiler.jsBuffer, ", ");
    st.vars[identifier] = {type: "var", node: decl.id};
    if (generate) CONCAT(compiler.jsBuffer, identifier);
    if (decl.init) {
      if (generate) CONCAT(compiler.jsBuffer, " = ");
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
          st.compiler.addWarning(createMessage("Local declaration of '" + identifier + "' hides instance variable", dict.node, st.compiler.source));
        }
        st.addedSelfToIvars[identifier] = [];
      }
    }
  }
},
ThisExpression: function(node, st, c) {
    var compiler = st.compiler;
    if (compiler.generate) CONCAT(compiler.jsBuffer, "this");
},
ArrayExpression: function(node, st, c) {
  var compiler = st.compiler,
      generate = compiler.generate;
  if (generate) CONCAT(compiler.jsBuffer, "[");
    for (var i = 0; i < node.elements.length; ++i) {
      var elt = node.elements[i];
      if (i !== 0)
          if (generate) CONCAT(compiler.jsBuffer, ", ");

      if (elt) c(elt, st, "Expression");
    }
  if (generate) CONCAT(compiler.jsBuffer, "]");
},
ObjectExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) CONCAT(compiler.jsBuffer, "{");
    for (var i = 0; i < node.properties.length; ++i)
    {
        var prop = node.properties[i];
        if (generate) {
          if (i !== 0) CONCAT(compiler.jsBuffer, ", ");
          CONCAT(compiler.jsBuffer, prop.key.name);
          CONCAT(compiler.jsBuffer, ": ");
        } else if (prop.key.raw && prop.key.raw.charAt(0) === "@") {
          CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, prop.key.start));
          compiler.lastPos = prop.key.start + 1;
        }

        c(prop.value, st, "Expression");
    }
    if (generate) CONCAT(compiler.jsBuffer, "}");
},
SequenceExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    for (var i = 0; i < node.expressions.length; ++i) {
      if (generate && i !== 0)
        CONCAT(compiler.jsBuffer, ", ");
      c(node.expressions[i], st, "Expression");
    }
},
UnaryExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (node.prefix) {
      if (generate) {
        CONCAT(compiler.jsBuffer, node.operator);
        if (wordPrefixOperators())
          CONCAT(compiler.jsBuffer, " ");
      }
      c(node.argument, st, "Expression");
    } else {
      c(node.argument, st, "Expression");
      if (generate) CONCAT(compiler.jsBuffer, node.operator);
    }
},
UpdateExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (node.argument.type === "Dereference") {
        checkCanDereference(st, node.argument);

        // @deref(x)++ and ++@deref(x) require special handling.
        if (!generate) CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.start));

        // Output the dereference function, "(...)(z)"
        CONCAT(compiler.jsBuffer, (node.prefix ? "" : "(") + "(");

        // The thing being dereferenced.
        if (!generate) compiler.lastPos = node.argument.expr.start;
        c(node.argument.expr, st, "Expression");
        if (!generate) CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.argument.expr.end));
        CONCAT(compiler.jsBuffer, ")(");

        if (!generate) compiler.lastPos = node.argument.start;
        c(node.argument, st, "Expression");
        if (!generate) CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.argument.end));
        CONCAT(compiler.jsBuffer, " " + node.operator.substring(0, 1) + " 1)" + (node.prefix ? "" : node.operator == '++' ? " - 1)" : " + 1)"));

        if (!generate) compiler.lastPos = node.end;
        return;
    }

    if (node.prefix) {
      if (generate) {
        CONCAT(compiler.jsBuffer, node.operator);
        if (wordPrefixOperators())
          CONCAT(compiler.jsBuffer, " ");
      }
      c(node.argument, st, "Expression");
    } else {
      c(node.argument, st, "Expression");
      if (generate) CONCAT(compiler.jsBuffer, node.operator);
    }
},
BinaryExpression: function(node, st, c) {
    var compiler = st.compiler;
    c(node.left, st, "Expression");
    if (compiler.generate) CONCAT(compiler.jsBuffer, node.operator);
    c(node.right, st, "Expression");
},
AssignmentExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        saveAssignment = st.assignment;

    if (node.left.type === "Dereference") {
        checkCanDereference(st, node.left);

        // @deref(x) = z    -> x(z) etc
        if (!generate) CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.start));

        // Output the dereference function, "(...)(z)"
        CONCAT(compiler.jsBuffer, "(");
        // What's being dereferenced could itself be an expression, such as when dereferencing a deref.
        if (!generate) compiler.lastPos = node.left.expr.start;
        c(node.left.expr, st, "Expression");
        if (!generate) CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.left.expr.end));
        CONCAT(compiler.jsBuffer, ")(");

        // Now "(x)(...)". We have to manually expand +=, -=, *= etc.
        if (node.operator !== "=") {
            // Output the whole .left, not just .left.expr.
            if (!generate) compiler.lastPos = node.left.start;
            c(node.left, st, "Expression");
            if (!generate) CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.left.end));
            CONCAT(compiler.jsBuffer, " " + node.operator.substring(0, 1) + " ");
        }

        if (!generate) compiler.lastPos = node.right.start;
        c(node.right, st, "Expression");
        if (!generate) CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.right.end));
        CONCAT(st.compiler.jsBuffer, ")");

        if (!generate) compiler.lastPos = node.end;

        return;
    }

    var saveAssignment = st.assignment;
    st.assignment = true;
    c(node.left, st, "Expression");
    if (generate) CONCAT(compiler.jsBuffer, node.operator);
    st.assignment = saveAssignment;
    c(node.right, st, "Expression");
    if (st.isRootScope() && node.left.type === "Identifier" && !st.getLvar(node.left.name))
        st.vars[node.left.name] = {type: "global", node: node.left};
},
ConditionalExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    c(node.test, st, "Expression");
    if (generate) CONCAT(compiler.jsBuffer, " ? ");
    c(node.consequent, st, "Expression");
    if (generate) CONCAT(compiler.jsBuffer, " : ");
    c(node.alternate, st, "Expression");
},
NewExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) CONCAT(compiler.jsBuffer, "new ");
    c(node.callee, st, "Expression");
    if (generate) CONCAT(compiler.jsBuffer, "(");
    if (node.arguments) {
      var first = true;
      for (var i = 0; i < node.arguments.length; ++i) {
        if (generate) {
          if (first)
            first = false;
          else
            CONCAT(compiler.jsBuffer, ", ");
        }
        c(node.arguments[i], st, "Expression");
      }
    }
    if (generate) CONCAT(compiler.jsBuffer, ")");
},
CallExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    c(node.callee, st, "Expression");
    if (generate) CONCAT(compiler.jsBuffer, "(");
    if (node.arguments) {
      var first = true;
      for (var i = 0; i < node.arguments.length; ++i) {
        if (generate) {
          if (first)
            first = false;
          else
            CONCAT(compiler.jsBuffer, ", ");
        }
        c(node.arguments[i], st, "Expression");
      }
    }
    if (generate) CONCAT(compiler.jsBuffer, ")");
},
MemberExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        computed = node.computed;
    c(node.object, st, "Expression");
    if (generate) {
      if (computed)
        CONCAT(compiler.jsBuffer, "[");
      else
        CONCAT(compiler.jsBuffer, ".");
    }
    st.secondMemberExpression = !computed;
    c(node.property, st, "Expression");
    st.secondMemberExpression = false;
    if (generate && computed)
      CONCAT(compiler.jsBuffer, "]");
},
Identifier: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        identifier = node.name;
    if (st.currentMethodType() === "-" && !st.secondMemberExpression)
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
                    CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, nodeStart));
                    compiler.lastPos = nodeStart;
                } while (compiler.source.substr(nodeStart++, 1) === "(")
                // Save the index in where the "self." string is stored and the node.
                // These will be used if we find a variable declaration that is hoisting this identifier.
                ((st.addedSelfToIvars || (st.addedSelfToIvars = Object.create(null)))[identifier] || (st.addedSelfToIvars[identifier] = [])).push({node: node, index: compiler.jsBuffer.atoms.length});
                CONCAT(compiler.jsBuffer, "self.");
            }
        } else if (!reservedIdentifiers(identifier)) {  // Don't check for warnings if it is a reserved word like self, localStorage, _cmd, etc...
            var message,
                classOrGlobal = typeof global[identifier] !== "undefined" || typeof window[identifier] !== "undefined" || compiler.getClassDef(identifier),
                globalVar = st.getLvar(identifier);
            if (classOrGlobal && (!globalVar || globalVar.type !== "class")) { // It can't be declared with a @class statement.
                /* Turned off this warning as there are many many warnings when compiling the Cappuccino frameworks - Martin
                if (lvar) {
                    message = st.compiler.addWarning(createMessage("Local declaration of '" + identifier + "' hides global variable", node, st.compiler.source));
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
    if (generate) CONCAT(compiler.jsBuffer, identifier);
},
Literal: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (generate) {
      var isString = typeof node.value === "string";
      if (isString)
        CONCAT(st.compiler.jsBuffer, "\"");
      CONCAT(st.compiler.jsBuffer, node.value);
      if (isString)
        CONCAT(st.compiler.jsBuffer, "\"");
    } else if (node.raw && node.raw.charAt(0) === "@") {
        CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));
        st.compiler.lastPos = node.start + 1;
    }

},
ArrayLiteral: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (!generate) {
        CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.start));
        compiler.lastPos = node.start;
    }

    if (!node.elements.length) {
        CONCAT(compiler.jsBuffer, "objj_msgSend(objj_msgSend(CPArray, \"alloc\"), \"init\")");
    } else {
        CONCAT(compiler.jsBuffer, "objj_msgSend(objj_msgSend(CPArray, \"alloc\"), \"initWithObjects:count:\", [");
        for (var i = 0; i < node.elements.length; i++) {
            var elt = node.elements[i];

            if (i)
                CONCAT(compiler.jsBuffer, ", ");

            if (!generate) compiler.lastPos = elt.start;
            c(elt, st, "Expression");
            if (!generate) CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, elt.end));
        }
        CONCAT(compiler.jsBuffer, "], " + node.elements.length + ")");
    }

    if (!generate) compiler.lastPos = node.end;
},
DictionaryLiteral: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (!generate) {
        CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.start));
        compiler.lastPos = node.start;
    }

    if (!node.keys.length) {
        CONCAT(compiler.jsBuffer, "objj_msgSend(objj_msgSend(CPDictionary, \"alloc\"), \"init\")");
    } else {
        CONCAT(compiler.jsBuffer, "objj_msgSend(objj_msgSend(CPDictionary, \"alloc\"), \"initWithObjectsAndKeys:\"");
        for (var i = 0; i < node.keys.length; i++) {
            var key = node.keys[i],
                value = node.values[i];

            CONCAT(compiler.jsBuffer, ", ");

            if (!generate) compiler.lastPos = value.start;
            c(value, st, "Expression");
            if (!generate) CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, value.end));

            CONCAT(compiler.jsBuffer, ", ");

            if (!generate) compiler.lastPos = key.start;
            c(key, st, "Expression");
            if (!generate) CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, key.end));
        }
        CONCAT(compiler.jsBuffer, ")");
    }

    if (!generate) st.compiler.lastPos = node.end;
},
ImportStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        buffer = compiler.jsBuffer;

    if (!generate) CONCAT(buffer,compiler.source.substring(st.compiler.lastPos, node.start));
    CONCAT(buffer, "objj_executeFile(\"");
    CONCAT(buffer, node.filename.value);
    CONCAT(buffer, node.localfilepath ? "\", YES);" : "\", NO);");
    if (!generate) compiler.lastPos = node.end;
},
ClassDeclarationStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        classDef,
        saveJSBuffer = compiler.jsBuffer,
        className = node.classname.name,
        classScope = new Scope(st);

    compiler.imBuffer = new StringBuffer();
    compiler.cmBuffer = new StringBuffer();
    compiler.classBodyBuffer = new StringBuffer();      // TODO: Check if this is needed

    if (!generate) CONCAT(saveJSBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));

    // First we declare the class
    if (node.superclassname)
    {
        classDef = compiler.getClassDef(className);
        if (classDef && classDef.ivars)     // Must have ivars dictionary to be a real declaration. Without it is a "@class" declaration
            throw compiler.error_message("Duplicate class " + className, node.classname);
        if (!compiler.getClassDef(node.superclassname.name))
        {
            var errorMessage = "Can't find superclass " + node.superclassname.name;
            for (var i = ObjJAcornCompiler.importStack.length; --i >= 0;)
                errorMessage += "\n" + Array((ObjJAcornCompiler.importStack.length - i) * 2 + 1).join(" ") + "Imported by: " + ObjJAcornCompiler.importStack[i];
            throw compiler.error_message(errorMessage, node.superclassname);
        }

        classDef = {"className": className, "superClassName": node.superclassname.name, "ivars": Object.create(null), "methods": Object.create(null)};

        CONCAT(saveJSBuffer, "{var the_class = objj_allocateClassPair(" + node.superclassname.name + ", \"" + className + "\"),\nmeta_class = the_class.isa;");
    }
    else if (node.categoryname)
    {
        classDef = compiler.getClassDef(className);
        if (!classDef)
            throw compiler.error_message("Class " + className + " not found ", node.classname);

        CONCAT(saveJSBuffer, "{\nvar the_class = objj_getClass(\"" + className + "\")\n");
        CONCAT(saveJSBuffer, "if(!the_class) throw new SyntaxError(\"*** Could not find definition for class \\\"" + className + "\\\"\");\n");
        CONCAT(saveJSBuffer, "var meta_class = the_class.isa;");
    }
    else
    {
        classDef = {"className": className, "superClassName": null, "ivars": Object.create(null), "methods": Object.create(null)};

        CONCAT(saveJSBuffer, "{var the_class = objj_allocateClassPair(Nil, \"" + className + "\"),\nmeta_class = the_class.isa;");
    }

    classScope.classDef = classDef;
    compiler.currentSuperClass = "objj_getClass(\"" + className + "\").super_class";
    compiler.currentSuperMetaClass = "objj_getMetaClass(\"" + className + "\").super_class";

    var firstIvarDeclaration = true,
        hasAccessors = false;

    // Then we add all ivars
    if (node.ivardeclarations) for (var i = 0; i < node.ivardeclarations.length; ++i)
    {
        var ivarDecl = node.ivardeclarations[i],
            ivarType = ivarDecl.ivartype ? ivarDecl.ivartype.name : null,
            ivarName = ivarDecl.id.name,
            ivar = {"type": ivarType, "name": ivarName};

        if (firstIvarDeclaration)
        {
            firstIvarDeclaration = false;
            CONCAT(saveJSBuffer, "class_addIvars(the_class, [");
        }
        else
            CONCAT(saveJSBuffer, ", ");

        if (compiler.flags & ObjJAcornCompiler.Flags.IncludeTypeSignatures)
            CONCAT(saveJSBuffer, "new objj_ivar(\"" + ivarName + "\", \"" + ivarType + "\")");
        else
            CONCAT(saveJSBuffer, "new objj_ivar(\"" + ivarName + "\")");

        if (ivarDecl.outlet)
            ivar.outlet = true;
        classDef.ivars[ivarName] = ivar;
        if (!classScope.ivars)
            classScope.ivars = Object.create(null);
        classScope.ivars[ivarName] = {type: "ivar", name: ivarName, node: ivarDecl.id, ivar: ivar};

        if (!hasAccessors && ivarDecl.accessors)
            hasAccessors = true;
    }

    if (!firstIvarDeclaration)
        CONCAT(saveJSBuffer, "]);");

    // If we have accessors add get and set methods for them
    if (hasAccessors)
    {
        var getterSetterBuffer = new StringBuffer();

        // Add the class declaration to compile accessors correctly
        CONCAT(getterSetterBuffer, compiler.source.substring(node.start, node.endOfIvars));
        CONCAT(getterSetterBuffer, "\n");

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

            CONCAT(getterSetterBuffer, getterCode);

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

            CONCAT(getterSetterBuffer, setterCode);
        }

        CONCAT(getterSetterBuffer, "\n@end");

        // Remove all @accessors or we will get a recursive loop in infinity
        var b = getterSetterBuffer.toString().replace(/@accessors(\(.*\))?/g, "");
        var imBuffer = ObjJAcornCompiler.compileToIMBuffer(b, "Accessors", compiler.flags, st.compiler.classDefs);

        // Add the accessors methods first to instance method buffer.
        // This will allow manually added set and get methods to override the compiler generated
        CONCAT(compiler.imBuffer, imBuffer);
    }

    // We will store the classDef first after accessors are done so we don't get a duplicate class error
    compiler.classDefs[className] = classDef;

    if (node.body.length > 0)
    {
        if (!generate) compiler.lastPos = node.body[0].start;

        // And last add methods and other statements
        for (var i = 0; i < node.body.length; ++i) {
            var body = node.body[i];
            c(body, classScope, "Statement");
        }
        if (!generate) CONCAT(saveJSBuffer, compiler.source.substring(st.compiler.lastPos, body.end));
    }

    // We must make a new class object for our class definition if it's not a category
    if (!node.categoryname) {
        CONCAT(saveJSBuffer, "objj_registerClassPair(the_class);\n");
    }

    // Add instance methods
    if (IS_NOT_EMPTY(compiler.imBuffer))
    {
        CONCAT(saveJSBuffer, "class_addMethods(the_class, [");
        saveJSBuffer.atoms.push.apply(saveJSBuffer.atoms, compiler.imBuffer.atoms); // FIXME: Move this append to StringBuffer
        CONCAT(saveJSBuffer, "]);\n");
    }

    // Add class methods
    if (IS_NOT_EMPTY(st.compiler.cmBuffer))
    {
        CONCAT(saveJSBuffer, "class_addMethods(meta_class, [");
        saveJSBuffer.atoms.push.apply(saveJSBuffer.atoms, compiler.cmBuffer.atoms); // FIXME: Move this append to StringBuffer
        CONCAT(saveJSBuffer, "]);\n");
    }

    CONCAT(saveJSBuffer, "}");

    compiler.jsBuffer = saveJSBuffer;

    // Skip the "@end"
    if (!generate) compiler.lastPos = node.end;
},
MethodDeclarationStatement: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate,
        saveJSBuffer = compiler.jsBuffer,
        methodScope = new Scope(st),
        selectors = node.selectors,
        arguments = node.arguments,
        types = [node.returntype ? node.returntype.name : "id"],
        selector = selectors[0].name;    // There is always at least one selector

    if (!generate) CONCAT(saveJSBuffer, compiler.source.substring(compiler.lastPos, node.start));

    compiler.jsBuffer = node.methodtype === '-' ? compiler.imBuffer : compiler.cmBuffer;

    // Put together the selector. Maybe this should be done in the parser...
    for (var i = 0; i < arguments.length; i++) {
        if (i === 0)
            selector += ":";
        else
            selector += (selectors[i] ? selectors[i].name : "") + ":";
    }

    if (IS_NOT_EMPTY(compiler.jsBuffer))           // Add comma separator if this is not first method in this buffer
        CONCAT(compiler.jsBuffer, ", ");
    CONCAT(compiler.jsBuffer, "new objj_method(sel_getUid(\"");
    CONCAT(compiler.jsBuffer, selector);
    CONCAT(compiler.jsBuffer, "\"), function");

//    this.currentSelector = selector;

    if (compiler.flags & ObjJAcornCompiler.Flags.IncludeDebugSymbols)
    {
        CONCAT(compiler.jsBuffer, " $" + st.currentClassName() + "__" + selector.replace(/:/g, "_"));
    }

    CONCAT(st.compiler.jsBuffer, "(self, _cmd");

    methodScope.methodType = node.methodtype;
    if (arguments) for (var i = 0; i < arguments.length; i++)
    {
        var argument = arguments[i],
            argumentName = argument.identifier.name;

        CONCAT(compiler.jsBuffer, ", ");
        CONCAT(compiler.jsBuffer, argumentName);
        types.push(argument.type ? argument.type.name : null);
        methodScope.vars[argumentName] = {type: "method argument", node: argument};
    }

    CONCAT(st.compiler.jsBuffer, ")");

    if (!generate) compiler.lastPos = node.startOfBody;
    c(node.body, methodScope, "Statement");
    if (!generate) CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.body.end));

    CONCAT(compiler.jsBuffer, "\n");
    if (compiler.flags & ObjJAcornCompiler.Flags.IncludeDebugSymbols)
        CONCAT(compiler.jsBuffer, ","+JSON.stringify(types));
    CONCAT(compiler.jsBuffer, ")");
    compiler.jsBuffer = saveJSBuffer;
    if (!generate) compiler.lastPos = node.end;
},
MessageSendExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (!generate) {
        CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.start));
        compiler.lastPos = node.object ? node.object.start : node.arguments.length ? node.arguments[0].start : node.end;
    }
    if (node.superObject)
    {
        CONCAT(compiler.jsBuffer, "objj_msgSendSuper(");
        CONCAT(compiler.jsBuffer, "{ receiver:self, super_class:" + (st.currentMethodType() === "+" ? compiler.currentSuperMetaClass : compiler.currentSuperClass ) + " }");
    }
    else
    {
        CONCAT(compiler.jsBuffer, "objj_msgSend(");
        c(node.object, st, "Expression");
        if (!generate) CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.object.end));
    }

    var selectors = node.selectors,
        arguments = node.arguments,
        selector = selectors[0].name;    // There is always at least one selector

    // Put together the selector. Maybe this should be done in the parser...
    for (var i = 0; i < arguments.length; i++)
        if (i === 0)
            selector += ":";
        else
            selector += (selectors[i] ? selectors[i].name : "") + ":";

    CONCAT(compiler.jsBuffer, ", \"");
    CONCAT(compiler.jsBuffer, selector); // FIXME: sel_getUid(selector + "") ? This FIXME is from the old preprocessor compiler
    CONCAT(compiler.jsBuffer, "\"");

    if (node.arguments) for (var i = 0; i < node.arguments.length; i++)
    {
        var argument = node.arguments[i];

        CONCAT(compiler.jsBuffer, ", ");
        if (!generate)
            compiler.lastPos = argument.start;
        c(argument, st, "Expression");
        if (!generate) {
            CONCAT(compiler.jsBuffer, compiler.source.substring(st.compiler.lastPos, argument.end));
            compiler.lastPos = argument.end;
        }
    }

    // TODO: Move this 'if' with body up inside the node.argument 'if'
    if (node.parameters) for (var i = 0; i < node.parameters.length; ++i)
    {
        var parameter = node.parameters[i];

        CONCAT(compiler.jsBuffer, ", ");
        if (!generate)
            compiler.lastPos = parameter.start;
        c(parameter, st, "Expression");
        if (!generate) {
            CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, parameter.end));
            compiler.lastPos = parameter.end;
        }
    }

    CONCAT(compiler.jsBuffer, ")");
    if (!generate) compiler.lastPos = node.end;
},
SelectorLiteralExpression: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (!generate) CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.start));
    CONCAT(compiler.jsBuffer, "sel_getUid(\"");
    CONCAT(compiler.jsBuffer, node.selector);
    CONCAT(compiler.jsBuffer, "\")");
    if (!generate) compiler.lastPos = node.end;
},
Reference: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;
    if (!generate) CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.start));
    CONCAT(compiler.jsBuffer, "function(__input) { if (arguments.length) return ");
    CONCAT(compiler.jsBuffer, node.element.name);
    CONCAT(compiler.jsBuffer, " = __input; return ");
    CONCAT(compiler.jsBuffer, node.element.name);
    CONCAT(compiler.jsBuffer, "; }");
    if (!generate) compiler.lastPos = node.end;
},
Dereference: function(node, st, c) {
    var compiler = st.compiler,
        generate = compiler.generate;

    checkCanDereference(st, node.expr);

    // @deref(y) -> y()
    // @deref(@deref(y)) -> y()()
    if (!generate) {
        CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.start));
        compiler.lastPos = node.expr.start;
    }
    c(node.expr, st, "Expression");
    if (!generate) CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.expr.end));
    CONCAT(compiler.jsBuffer, "()");
    if (!generate) compiler.lastPos = node.end;
},
ClassStatement: function(node, st, c) {
    var compiler = st.compiler;
    if (!compiler.generate) {
        CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.start));
        compiler.lastPos = node.start;
        CONCAT(compiler.jsBuffer, "//");
    }
    var className = node.id.name;
    if (!compiler.getClassDef(className)) {
        classDef = {"className": className};
        compiler.classDefs[className] = classDef;
    }
    st.vars[node.id.name] = {type: "class", node: node.id};
},
GlobalStatement: function(node, st, c) {
    var compiler = st.compiler;
    if (!compiler.generate) {
        CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.start));
        compiler.lastPos = node.start;
        CONCAT(compiler.jsBuffer, "//");
    }
    st.rootScope().vars[node.id.name] = {type: "global", node: node.id};
},
PreprocessStatement: function(node, st, c) {
    var compiler = st.compiler;
    if (!compiler.generate) {
      CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, node.start));
      compiler.lastPos = node.start;
      CONCAT(compiler.jsBuffer, "//");
    }
}
});
