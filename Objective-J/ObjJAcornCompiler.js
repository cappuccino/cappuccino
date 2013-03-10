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
    if (prev && (!stopAtMethod || !this.methodtype))
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

var currentCompilerFlags = "";

var reservedIdentifiers = exports.acorn.makePredicate("self _cmd undefined localStorage arguments");

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
    for (var i = 0; i < node.body.length; ++i) {
      c(node.body[i], st, "Statement");
    }
    CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.end));
    // Check maybe warnings
    var maybeWarnings = st.maybeWarnings();
    if (maybeWarnings) for (var i = 0; i < maybeWarnings.length; i++) {
        var maybeWarning = maybeWarnings[i];
        if (!st.getLvar(maybeWarning.identifier) && typeof global[maybeWarning.identifier] === "undefined" && typeof window[maybeWarning.identifier] === "undefined" && !st.compiler.getClassDef(maybeWarning.identifier)) {
            st.compiler.addWarning(maybeWarning.message);
        }
    }
},
Function: function(node, scope, c) {
  var inner = new Scope(scope);
  for (var i = 0; i < node.params.length; ++i)
    inner.vars[node.params[i].name] = {type: "argument", node: node.params[i]};
  if (node.id) {
    var decl = node.type == "FunctionDeclaration";
    (decl ? scope : inner).vars[node.id.name] =
      {type: decl ? "function" : "function name", node: node.id};
    CONCAT(scope.compiler.jsBuffer,scope.compiler.source.substring(scope.compiler.lastPos, node.start));
    CONCAT(scope.compiler.jsBuffer, node.id.name);
    CONCAT(scope.compiler.jsBuffer, " = function");
    scope.compiler.lastPos = node.id.end;
  }
  c(node.body, inner, "ScopeBody");
  inner.copyAddedSelfToIvarsToParent();
},
TryStatement: function(node, scope, c) {
  c(node.block, scope, "Statement");
  for (var i = 0; i < node.handlers.length; ++i) {
    var handler = node.handlers[i], inner = new Scope(scope);
    inner.vars[handler.param.name] = {type: "catch clause", node: handler.param};
    c(handler.body, inner, "ScopeBody");
    inner.copyAddedSelfToIvarsToParent();
  }
  if (node.finalizer) c(node.finalizer, scope, "Statement");
},
VariableDeclaration: function(node, scope, c) {
  for (var i = 0; i < node.declarations.length; ++i) {
    var decl = node.declarations[i],
        identifier = decl.id.name;
    scope.vars[identifier] = {type: "var", node: decl.id};
    if (decl.init) c(decl.init, scope, "Expression");
    if (scope.addedSelfToIvars) {
      var addedSelfToIvar = scope.addedSelfToIvars[identifier];
      if (addedSelfToIvar) {
        var buffer = scope.compiler.jsBuffer.atoms;
        for (var i = 0; i < addedSelfToIvar.length; i++) {
          var dict = addedSelfToIvar[i];
          buffer[dict.index] = "";
          scope.compiler.addWarning(createMessage("Local declaration of '" + identifier + "' hides instance variable", dict.node, scope.compiler.source));
        }
        scope.addedSelfToIvars[identifier] = [];
      }
    }
  }
},
AssignmentExpression: function(node, st, c) {
    if (node.left.type === "Dereference") {
        checkCanDereference(st, node.left);

        // @deref(x) = z    -> x(z) etc
        CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));

        // Output the dereference function, "(...)(z)"
        CONCAT(st.compiler.jsBuffer, "(");
        // What's being dereferenced could itself be an expression, such as when dereferencing a deref.
        st.compiler.lastPos = node.left.expr.start;
        c(node.left.expr, st, "Expression");
        CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.left.expr.end));
        CONCAT(st.compiler.jsBuffer, ")(");

        // Now "(x)(...)". We have to manually expand +=, -=, *= etc.
        if (node.operator !== "=") {
            // Output the whole .left, not just .left.expr.
            st.compiler.lastPos = node.left.start;
            c(node.left, st, "Expression");
            CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.left.end));
            CONCAT(st.compiler.jsBuffer, " " + node.operator.substring(0, 1) + " ");
        }

        st.compiler.lastPos = node.right.start;
        c(node.right, st, "Expression");
        CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.right.end));
        CONCAT(st.compiler.jsBuffer, ")");

        st.compiler.lastPos = node.end;

        return;
    }

    var saveAssignment = st.assignment;
    st.assignment = true;
    c(node.left, st, "Expression");
    st.assignment = saveAssignment;
    c(node.right, st, "Expression");
    if (st.isRootScope() && node.left.type === "Identifier" && !st.getLvar(node.left.name))
        st.vars[node.left.name] = {type: "global", node: node.left};
},
UpdateExpression: function(node, st, c) {
    if (node.argument.type === "Dereference") {
        checkCanDereference(st, node.argument);

        // @deref(x)++ and ++@deref(x) require special handling.
        CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));

        // Output the dereference function, "(...)(z)"
        CONCAT(st.compiler.jsBuffer, (node.prefix ? "" : "(") + "(");

        // The thing being dereferenced.
        st.compiler.lastPos = node.argument.expr.start;
        c(node.argument.expr, st, "Expression");
        CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.argument.expr.end));
        CONCAT(st.compiler.jsBuffer, ")(");

        st.compiler.lastPos = node.argument.start;
        c(node.argument, st, "Expression");
        CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.argument.end));
        CONCAT(st.compiler.jsBuffer, " " + node.operator.substring(0, 1) + " 1)" + (node.prefix ? "" : node.operator == '++' ? " - 1)" : " + 1)"));

        st.compiler.lastPos = node.end;
        return;
    }

    c(node.argument, st, "Expression");
},
MemberExpression: function(node, st, c) {
    c(node.object, st, "Expression");
    st.secondMemberExpression = !node.computed;
    c(node.property, st, "Expression");
    st.secondMemberExpression = false;
},
ImportStatement: function(node, st, c) {
    var buffer = st.compiler.jsBuffer;

    if (!buffer) return;
    CONCAT(buffer,st.compiler.source.substring(st.compiler.lastPos, node.start));
    CONCAT(buffer, "objj_executeFile(\"");
    CONCAT(buffer, node.filename.value);
    CONCAT(buffer, node.localfilepath ? "\", YES);" : "\", NO);");
    st.compiler.lastPos = node.end;
},
ClassDeclarationStatement: function(node, st, c) {
    var classDef,
        saveJSBuffer = st.compiler.jsBuffer,
        className = node.classname.name,
        classScope = new Scope(st);

    st.compiler.imBuffer = new StringBuffer();
    st.compiler.cmBuffer = new StringBuffer();
    st.compiler.classBodyBuffer = new StringBuffer();      // TODO: Check if this is needed

    CONCAT(saveJSBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));

    // First we declare the class
    if (node.superclassname)
    {
        classDef = st.compiler.getClassDef(className);
        if (classDef && classDef.ivars)     // Must have ivars dictionary to be a real declaration. Without it is a "@class" declaration
            throw st.compiler.error_message("Duplicate class " + className, node.classname);
        if (!st.compiler.getClassDef(node.superclassname.name))
        {
            var errorMessage = "Can't find superclass " + node.superclassname.name;
            for (var i = ObjJAcornCompiler.importStack.length; --i >= 0;)
                errorMessage += "\n" + Array((ObjJAcornCompiler.importStack.length - i) * 2 + 1).join(" ") + "Imported by: " + ObjJAcornCompiler.importStack[i];
            throw st.compiler.error_message(errorMessage, node.superclassname);
        }

        classDef = {"className": className, "superClassName": node.superclassname.name, "ivars": Object.create(null), "methods": Object.create(null)};

        CONCAT(saveJSBuffer, "{var the_class = objj_allocateClassPair(" + node.superclassname.name + ", \"" + className + "\"),\nmeta_class = the_class.isa;");
    }
    else if (node.categoryname)
    {
        classDef = st.compiler.getClassDef(className);
        if (!classDef)
            throw st.compiler.error_message("Class " + className + " not found ", node.classname);

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
    st.compiler.currentSuperClass = "objj_getClass(\"" + className + "\").super_class";
    st.compiler.currentSuperMetaClass = "objj_getMetaClass(\"" + className + "\").super_class";

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

        if (st.compiler.flags & ObjJAcornCompiler.Flags.IncludeTypeSignatures)
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
        CONCAT(getterSetterBuffer, st.compiler.source.substring(node.start, node.endOfIvars));
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
        var imBuffer = ObjJAcornCompiler.compileToIMBuffer(b, "Accessors", st.compiler.flags, st.compiler.classDefs);

        // Add the accessors methods first to instance method buffer.
        // This will allow manually added set and get methods to override the compiler generated
        CONCAT(st.compiler.imBuffer, imBuffer);
    }

    // We will store the classDef first after accessors are done so we don't get a duplicate class error
    st.compiler.classDefs[className] = classDef;

    if (node.body.length > 0)
    {
        st.compiler.lastPos = node.body[0].start;

        // And last add methods and other statements
        for (var i = 0; i < node.body.length; ++i) {
            var body = node.body[i];
            c(body, classScope, "Statement");
        }
        CONCAT(saveJSBuffer, st.compiler.source.substring(st.compiler.lastPos, body.end));
    }

    // We must make a new class object for our class definition if it's not a category
    if (!node.categoryname) {
        CONCAT(saveJSBuffer, "objj_registerClassPair(the_class);\n");
    }

    // Add instance methods
    if (IS_NOT_EMPTY(st.compiler.imBuffer))
    {
        CONCAT(saveJSBuffer, "class_addMethods(the_class, [");
        saveJSBuffer.atoms.push.apply(saveJSBuffer.atoms, st.compiler.imBuffer.atoms); // FIXME: Move this append to StringBuffer
        CONCAT(saveJSBuffer, "]);\n");
    }

    // Add class methods
    if (IS_NOT_EMPTY(st.compiler.cmBuffer))
    {
        CONCAT(saveJSBuffer, "class_addMethods(meta_class, [");
        saveJSBuffer.atoms.push.apply(saveJSBuffer.atoms, st.compiler.cmBuffer.atoms); // FIXME: Move this append to StringBuffer
        CONCAT(saveJSBuffer, "]);\n");
    }

    CONCAT(saveJSBuffer, "}");

    st.compiler.jsBuffer = saveJSBuffer;

    // Skip the "@end"
    st.compiler.lastPos = node.end;
},
MethodDeclarationStatement: function(node, st, c) {
    var saveJSBuffer = st.compiler.jsBuffer,
        methodScope = new Scope(st),
        selectors = node.selectors,
        arguments = node.arguments,
        types = [node.returntype ? node.returntype.name : "id"],
        selector = selectors[0].name;    // There is always at least one selector

    CONCAT(saveJSBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));

    st.compiler.jsBuffer = node.methodtype === '-' ? st.compiler.imBuffer : st.compiler.cmBuffer;

    // Put together the selector. Maybe this should be done in the parser...
    for (var i = 0; i < arguments.length; i++) {
        if (i === 0)
            selector += ":";
        else
            selector += (selectors[i] ? selectors[i].name : "") + ":";
    }

    if (IS_NOT_EMPTY(st.compiler.jsBuffer))           // Add comma separator if this is not first method in this buffer
        CONCAT(st.compiler.jsBuffer, ", ");
    CONCAT(st.compiler.jsBuffer, "new objj_method(sel_getUid(\"");
    CONCAT(st.compiler.jsBuffer, selector);
    CONCAT(st.compiler.jsBuffer, "\"), function");

//    this.currentSelector = selector;

    if (st.compiler.flags & ObjJAcornCompiler.Flags.IncludeDebugSymbols)
    {
        CONCAT(st.compiler.jsBuffer, " $" + st.currentClassName() + "__" + selector.replace(/:/g, "_"));
    }

    CONCAT(st.compiler.jsBuffer, "(self, _cmd");

    methodScope.methodType = node.methodtype;
    if (arguments) for (var i = 0; i < arguments.length; i++)
    {
        var argument = arguments[i],
            argumentName = argument.identifier.name;

        CONCAT(st.compiler.jsBuffer, ", ");
        CONCAT(st.compiler.jsBuffer, argumentName);
        types.push(argument.type ? argument.type.name : null);
        methodScope.vars[argumentName] = {type: "method argument", node: argument};
    }

    CONCAT(st.compiler.jsBuffer, ")");

    st.compiler.lastPos = node.startOfBody;
    c(node.body, methodScope, "Statement");
    CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.body.end));

    CONCAT(st.compiler.jsBuffer, "\n");
    if (st.compiler.flags & ObjJAcornCompiler.Flags.IncludeDebugSymbols)
        CONCAT(st.compiler.jsBuffer, ","+JSON.stringify(types));
    CONCAT(st.compiler.jsBuffer, ")");
    st.compiler.jsBuffer = saveJSBuffer;
    st.compiler.lastPos = node.end;
},
MessageSendExpression: function(node, st, c) {
    CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));
    st.compiler.lastPos = node.object ? node.object.start : node.arguments.length ? node.arguments[0].start : node.end;
    if (node.superObject)
    {
        CONCAT(st.compiler.jsBuffer, "objj_msgSendSuper(");
        CONCAT(st.compiler.jsBuffer, "{ receiver:self, super_class:" + (st.currentMethodType() === "+" ? st.compiler.currentSuperMetaClass : st.compiler.currentSuperClass ) + " }");
    }
    else
    {
        CONCAT(st.compiler.jsBuffer, "objj_msgSend(");
        c(node.object, st, "Expression");
        CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.object.end));
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

    CONCAT(st.compiler.jsBuffer, ", \"");
    CONCAT(st.compiler.jsBuffer, selector); // FIXME: sel_getUid(selector + "") ? This FIXME is from the old preprocessor compiler
    CONCAT(st.compiler.jsBuffer, "\"");

    if (node.arguments) for (var i = 0; i < node.arguments.length; i++)
    {
        var argument = node.arguments[i];

        CONCAT(st.compiler.jsBuffer, ", ");
        st.compiler.lastPos = argument.start;
        c(argument, st, "Expression");
        CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, argument.end));
        st.compiler.lastPos = argument.end;
    }

    // TODO: Move this 'if' with body up inside the node.argument 'if'
    if (node.parameters) for (var i = 0; i < node.parameters.length; ++i)
    {
        var parameter = node.parameters[i];

        CONCAT(st.compiler.jsBuffer, ", ");
        st.compiler.lastPos = parameter.start;
        c(parameter, st, "Expression");
        CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, parameter.end));
        st.compiler.lastPos = parameter.end;
    }

    CONCAT(st.compiler.jsBuffer, ")");
    st.compiler.lastPos = node.end;
},
Identifier: function(node, st, c) {
    if (st.currentMethodType() === "-" && !st.secondMemberExpression)
    {
        var identifier = node.name,
            lvar = st.getLvar(identifier, true), // Stop looking at method
            ivar = st.compiler.getIvarForClass(identifier, st);

        if (ivar)
        {
            if (lvar)
                st.compiler.addWarning(createMessage("Local declaration of '" + identifier + "' hides instance variable", node, st.compiler.source));
            else
            {
                var nodeStart = node.start,
                    compiler = st.compiler;

                do {    // The Spider Monkey AST tree includes any parentheses in start and end properties so we have to make sure we skip those
                    CONCAT(compiler.jsBuffer, compiler.source.substring(compiler.lastPos, nodeStart));
                    compiler.lastPos = nodeStart;
                } while (compiler.source.substr(nodeStart++, 1) === "(")
                // Save the index in where the "self." string is stored and the node.
                // These will be used if we find a variable declaration that is hoisting this identifier.
                ((st.addedSelfToIvars || (st.addedSelfToIvars = Object.create(null)))[identifier] || (st.addedSelfToIvars[identifier] = [])).push({node: node, index: compiler.jsBuffer.atoms.length});
                CONCAT(compiler.jsBuffer, "self.");
            }
        } else {
            if (!reservedIdentifiers(identifier) && !st.getLvar(identifier) && typeof global[identifier] === "undefined" && typeof window[identifier] === "undefined" && !st.compiler.getClassDef(identifier)) {
                var message;
                if (st.assignment) {
                    message = createMessage("Creating global variable inside function or method '" + identifier + "'", node, st.compiler.source);
                    st.vars[identifier] = {type: "global", node: node};
                } else
                    message = createMessage("Using unknown class or uninitialized global variable '" + identifier + "'", node, st.compiler.source);

                st.addMaybeWarning({identifier: identifier, message: message});
            }
        }
    }
},
ArrayLiteral: function(node, st, c) {
    CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));
    st.compiler.lastPos = node.start;

    if (!node.elements.length) {
        CONCAT(st.compiler.jsBuffer, "objj_msgSend(objj_msgSend(CPArray, \"alloc\"), \"init\")");
    } else {
        CONCAT(st.compiler.jsBuffer, "objj_msgSend(objj_msgSend(CPArray, \"alloc\"), \"initWithObjects:count:\", [");
        for (var i = 0; i < node.elements.length; i++) {
            var elt = node.elements[i];

            if (i)
                CONCAT(st.compiler.jsBuffer, ", ");

            st.compiler.lastPos = elt.start;
            c(elt, st, "Expression");
            CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, elt.end));
        }
        CONCAT(st.compiler.jsBuffer, "], " + node.elements.length + ")");
    }

    st.compiler.lastPos = node.end;
},
DictionaryLiteral: function(node, st, c) {
    CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));
    st.compiler.lastPos = node.start;

    if (!node.keys.length) {
        CONCAT(st.compiler.jsBuffer, "objj_msgSend(objj_msgSend(CPDictionary, \"alloc\"), \"init\")");
    } else {
        CONCAT(st.compiler.jsBuffer, "objj_msgSend(objj_msgSend(CPDictionary, \"alloc\"), \"initWithObjectsAndKeys:\"");
        for (var i = 0; i < node.keys.length; i++) {
            var key = node.keys[i],
                value = node.values[i];

            CONCAT(st.compiler.jsBuffer, ", ");

            st.compiler.lastPos = value.start;
            c(value, st, "Expression");
            CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, value.end));

            CONCAT(st.compiler.jsBuffer, ", ");

            st.compiler.lastPos = key.start;
            c(key, st, "Expression");
            CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, key.end));
        }
        CONCAT(st.compiler.jsBuffer, ")");
    }

    st.compiler.lastPos = node.end;
},
SelectorLiteralExpression: function(node, st, c) {
    CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));
    CONCAT(st.compiler.jsBuffer, "sel_getUid(\"");
    CONCAT(st.compiler.jsBuffer, node.selector);
    CONCAT(st.compiler.jsBuffer, "\")");
    st.compiler.lastPos = node.end;
},
Reference: function(node, st, c) {
    CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));
    CONCAT(st.compiler.jsBuffer, "function(__input) { if (arguments.length) return ");
    CONCAT(st.compiler.jsBuffer, node.element.name);
    CONCAT(st.compiler.jsBuffer, " = __input; return ");
    CONCAT(st.compiler.jsBuffer, node.element.name);
    CONCAT(st.compiler.jsBuffer, "; }");
    st.compiler.lastPos = node.end;
},
Dereference: function(node, st, c) {
    checkCanDereference(st, node.expr);

    // @deref(y) -> y()
    // @deref(@deref(y)) -> y()()
    CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));
    st.compiler.lastPos = node.expr.start;
    c(node.expr, st, "Expression");
    CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.expr.end));
    CONCAT(st.compiler.jsBuffer, "()");
    st.compiler.lastPos = node.end;

},
Literal: function(node, st, c) {
    if (node.raw && node.raw.charAt(0) === "@")
    {
        CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));
        st.compiler.lastPos = node.start + 1;
    }
},
ObjectExpression: function(node, st, c) {
    for (var i = 0; i < node.properties.length; ++i)
    {
        var prop = node.properties[i];
        if (prop.key.raw && prop.key.raw.charAt(0) === "@")
        {
            CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, prop.key.start));
            st.compiler.lastPos = prop.key.start + 1;
        }
        c(prop.value, st, "Expression");
    }
},
PreprocessStatement: function(node, st, c) {
    CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));
    st.compiler.lastPos = node.start;
    CONCAT(st.compiler.jsBuffer, "//");
},
ClassStatement: function(node, st, c) {
    CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));
    st.compiler.lastPos = node.start;
    CONCAT(st.compiler.jsBuffer, "//");
    var className = node.id.name;
    if (!st.compiler.getClassDef(className)) {
        classDef = {"className": className};
        st.compiler.classDefs[className] = classDef;
    }
    st.vars[node.id.name] = {type: "class", node: node.id};
},
GlobalStatement: function(node, st, c) {
    CONCAT(st.compiler.jsBuffer, st.compiler.source.substring(st.compiler.lastPos, node.start));
    st.compiler.lastPos = node.start;
    CONCAT(st.compiler.jsBuffer, "//");
    st.rootScope().vars[node.id.name] = {type: "global", node: node.id};
}
});
