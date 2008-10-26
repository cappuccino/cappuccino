/*
 * preprocessor.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

function objj_preprocess(/*String*/ aString, /*objj_bundle*/ aBundle, /*objj_file*/ aSourceFile) 
{    
    try
    {
        OBJJ_CURRENT_BUNDLE = aBundle;
    
        return new objj_preprocessor(aString, aSourceFile).fragments();
    }
    catch (anException)
    {
        objj_exception_report(anException, aSourceFile);
    }
    
    return [];
}

OBJJParseException          = "OBJJParseException";
OBJJClassNotFoundException  = "OBJJClassNotFoundException";

var TOKEN_ACCESSORS         = "accessors",
    TOKEN_CLASS             = "class",
    TOKEN_END               = "end",
    TOKEN_FUNCTION          = "function",
    TOKEN_IMPLEMENTATION    = "implementation",
    TOKEN_IMPORT            = "import",
    TOKEN_NEW               = "new",
    TOKEN_SELECTOR          = "selector",
    TOKEN_SUPER             = "super",
                            
    TOKEN_EQUAL             = '=',
    TOKEN_PLUS              = '+',
    TOKEN_MINUS             = '-',
    TOKEN_COLON             = ':',
    TOKEN_COMMA             = ',',
    TOKEN_PERIOD            = '.',
    TOKEN_ASTERISK          = '*',
    TOKEN_SEMICOLON         = ';',
    TOKEN_LESS_THAN         = '<',
    TOKEN_OPEN_BRACE        = '{',
    TOKEN_CLOSE_BRACE       = '}',
    TOKEN_GREATER_THAN      = '>',
    TOKEN_OPEN_BRACKET      = '[',
    TOKEN_DOUBLE_QUOTE      = '"',
    TOKEN_PREPROCESSOR      = '@',
    TOKEN_CLOSE_BRACKET     = ']',
    TOKEN_QUESTION_MARK     = '?',
    TOKEN_OPEN_PARENTHESIS  = '(',
    TOKEN_CLOSE_PARENTHESIS = ')';
    
#define IS_WORD(token) /^\w+$/.test(token)

#define IS_NOT_EMPTY(buffer) buffer.atoms.length !== 0
#define CONCAT(buffer, atom) buffer.atoms[buffer.atoms.length] = atom

var SUPER_CLASSES           = new objj_dictionary();

var OBJJ_CURRENT_BUNDLE     = NULL;

// FIXME: Used fixed regex
var objj_lexer = function(aString)
{
    this._index = 0;
    this._tokens = (aString + '\n').match(/\/\/.*(\r|\n)?|\/\*(?:.|\n|\r)*?\*\/|\w+\b|[+-]?\d+(([.]\d+)*([eE][+-]?\d+))?|"([^"\\]|\\[\s\S])*"|'[^'\\]*(\\.[^'\\]*)*'|\s+|./g);
    
    return this;
}

objj_lexer.prototype.next = function()
{
    return this._tokens[this._index++];
}

objj_lexer.prototype.previous = function()
{
    return this._tokens[--this._index];
}

objj_lexer.prototype.last = function()
{
    if (this._index > 1)
        return this._tokens[this._index - 2];
    
    return NULL;
}

objj_lexer.prototype.skip_whitespace= function()
{   
    var token;
    while((token = this.next()) && (!(/\S/).test(token) || token.substr(0,2) == "//" || token.substr(0,2) == "/*")) ;

    return token;
}

var objj_stringBuffer = function()
{
    this.atoms = [];
}

objj_stringBuffer.prototype.toString = function()
{
    return this.atoms.join("");
}

objj_stringBuffer.prototype.clear = function()
{
    this.atoms = [];
}

objj_stringBuffer.prototype.isEmpty = function()
{
    return (this.atoms.length === 0);
}

var objj_preprocessor = function(aString, aSourceFile)
{
    this._currentClass = "";
    this._currentSuperClass = "";
    
    this._file = aSourceFile;
    this._fragments = [];
    this._preprocessed = new objj_stringBuffer();
    this._tokens = new objj_lexer(aString);
    
    this.preprocess(this._tokens, this._preprocessed);
    this.fragment();
}

objj_preprocessor.prototype.fragments = function()
{
    return this._fragments;
}

objj_preprocessor.prototype.accessors = function(tokens)
{
    var token = tokens.skip_whitespace(),
        attributes = {};

    if (token != TOKEN_OPEN_PARENTHESIS)
    {
        tokens.previous();
        
        return attributes;
    }

    while ((token = tokens.skip_whitespace()) != TOKEN_CLOSE_PARENTHESIS)
    {
        var name = token,
            value = true;

        if (!IS_WORD(name))
            objj_exception_throw(new objj_exception(OBJJParseException, "*** @property attribute name not valid."));

        if ((token = tokens.skip_whitespace()) == TOKEN_EQUAL)
        {
            value = tokens.skip_whitespace();
            
            if (!IS_WORD(value))
                objj_exception_throw(new objj_exception(OBJJParseException, "*** @property attribute value not valid."));

            if (name == "setter")
            {
                if ((token = tokens.next()) != TOKEN_COLON)
                    objj_exception_throw(new objj_exception(OBJJParseException, "*** @property setter attribute requires argument with \":\" at end of selector name."));
                
                value += ":";
            }

            token = tokens.skip_whitespace();
        }

        attributes[name] = value;

        if (token == TOKEN_CLOSE_PARENTHESIS)
            break;
        
        if (token != TOKEN_COMMA)
            objj_exception_throw(new objj_exception(OBJJParseException, "*** Expected ',' or ')' in @property attribute list."));
    }
    
    return attributes;
}

objj_preprocessor.prototype.brackets = function(tokens, /*objj_stringBuffer*/ aStringBuffer)
{
    var buffer = aStringBuffer ? aStringBuffer : new objj_stringBuffer();
    
    // We maintain two parallel interpretations through the process,
    // One which assumes the brackets form a literal array, and
    // another that builds the possible message dispatch composed of
    // a receiver, a selector, and a number of marg_list.
    var literal = new objj_stringBuffer(),
        msgSend = "objj_msgSend",
        receiver = "",
        selector = "",
        marg_list = [];
    
    CONCAT(literal, '[');
    
    // We keep track of the current iterative token, the previous 
    // expression, tertiary operations, and parenthesis.
    var token = "",
        array = false,
        previous = "",
        
        braces = 0,
        tertiary = 0,
        parenthesis = 0;
    
    while((token = tokens.skip_whitespace()) && token != TOKEN_CLOSE_BRACKET)
    {
        // We should attempt to preprocess our message code only if we are 
        // not within parenthesis or a tertiary statement.
        var preprocess = !braces && !tertiary && !parenthesis && !array;
        
        // We handle the special case where the receiver is super.  In this case, 
        // use an objj_super object and use objj_msgSendSuper instead of objj_msgSend.
        if (token == TOKEN_SUPER)
        {
            if (!receiver.length)
            {
                msgSend = "objj_msgSendSuper";
                token = "{ receiver:self, super_class:" + this._currentSuperClass + " }";
            }
            else
                objj_exception_throw(new objj_exception(OBJJParseException, "*** Can't use 'super' in this context."));
        }
        
        else if (token == TOKEN_OPEN_BRACE)
            ++braces;
        
        else if (token == TOKEN_CLOSE_BRACE)
            --braces;
        
        // Tertiary expressions have the potential to confuse the preprocessor, 
        // so keep track of them to avoid misidentifying a colon (':') for an 
        // argument.
        else if(token == TOKEN_QUESTION_MARK)
            ++tertiary;
        
        // Keep track of expressions within parenthesis.
        else if(token == TOKEN_OPEN_PARENTHESIS)
            ++parenthesis;
        
        else if(token == TOKEN_CLOSE_PARENTHESIS)
            --parenthesis;
        
        // If we reach a nested bracket, preprocess it first and interpret 
        // the result as the current token.
        else if(token == TOKEN_OPEN_BRACKET)
            token = this.brackets(tokens);
        
        else if(token == TOKEN_PREPROCESSOR)
            token = this.directive(tokens);
        
        // Preprocess tokens only if we're not within parenthesis or in a 
        // tertiary statement.
        if (preprocess)
        {
            // If we ever reach a comma that is not in a sub expression, 
            // and we haven't yet begun to construct a selector, then 
            // we can be sure that this is not a message dispatch, and 
            // we should simply return so that the lexer can continue 
            // to preprocess normally.
            if(token == TOKEN_COMMA && !selector.length)
                array = true;//return literal + token;
            // A colon (':') alerts us that we've reached the end of a label.
            if(token == TOKEN_COLON)
            {
                // If the previous token was actually white space, so this 
                // is an empty label.
                var last = tokens.last();
                
                if (last && (!(/\S/).test(last) || last.substr(0, 2) == "//" || last.substr(0, 2) == "/*"))
                {
                    selector += ':';
                    marg_list[marg_list.length - 1] += previous;
                    marg_list[marg_list.length] = previous = "";
                }
                
                // If not the previous token was was part of the label and 
                // thus should be appended to the selector.
                else
                {
                    selector += previous + ":";
                    marg_list[marg_list.length] = previous = "";
                }
            }
            else
            {            
                // Generally we are unconcerned with whitespace, however the new 
                // operator requires it.
                if (previous == TOKEN_NEW)
                    previous = "new ";
                
                // If we've already begun building our selector, then the token 
                // should be applied to the current argument.
                if (selector.length)
                    marg_list[marg_list.length - 1] += previous;
                
                // If not, then it belongs to the receiver.
                else        
                    receiver += previous;
                                
                previous = token.toString();
            }
        }
        // If not, add it to previous to be interpreted as one block.
        else
        {
            // We know this colon (':') to match a previous tertiary expression.
            // FIXME PARSER_BUG: This does not properly account for interspersed { } and ?:
            // https://trac.280north.com/ticket/15
            if(token == TOKEN_COLON && !braces)
                --tertiary;
            
            previous += token;
        }
        
        // The literal interpretation is always handled in the same 
        // manner, simply aggregate the tokens, unless we have a new token,
        // in which case we need to add back the whitespace we removed.
        if (token == TOKEN_NEW)
            CONCAT(literal, "new ");
        else
            CONCAT(literal, token);
    }

    // If we have a selector, then add the remaining string to the argument.
    if (selector.length)
        marg_list[marg_list.length - 1] += previous;
    
    // If not, check whether the final character of our proposed receiver
    // is an operator or the new keyword.  Also check that the previous 
    // expression does not begin with a parenthesis, since this means it 
    // definitely can't be a selector.
    // FIXME: There is probably a more concise and efficient way to represent
    // these regular expressions.
    // FIXME: Should the second expression be the same as the first.  For example,
    // array[i%] becomes arrayobjj_msgSend(i,"%") if not.  This is an error either 
    // way though.  https://trac.280north.com/ticket/6
    else if(!array && receiver.length && !((/[\:\+\-\*\/\=\<\>\&\|\!\.\%]/).test(receiver.charAt(receiver.length - 1))) && 
            receiver != TOKEN_NEW && !(/[\+\-\*\/\=\<\>\&\|\!\.\[\^\(]/).test(previous.charAt(0)))
        selector = previous;
    
    // If we did not build a selector through the parsing process, then we 
    // are either a single entry literal array, or an array index, and so 
    // we should simply return our literal string.
    else
    {
        CONCAT(buffer, literal);
        CONCAT(buffer, ']');

        // Return no matter what!
        if (!aStringBuffer)
            return buffer;
        else
            return;
    }
    
    // NOTE: For now, turn this behavior off.
    // Classes act much like keywords since they are not directly manipulatable.
    // We thus check whether it exists in our class hash or working hash, and if 
    // instead use a reference to it if it does.
    // if (tokens.containsClass(receiver) || objj_getClass(receiver)) receiver = "objj_getClass(\"" + receiver + "\")";

    // The first two arguments are always the receiver and the selector.
    CONCAT(buffer, msgSend);
    CONCAT(buffer, '(' + receiver + ", \"" + sel_getUid(selector) + "\"");
    
    // Populate the remaining parameters with the provided arguments.
    var index = 0,
        count = marg_list.length;
    
    for(; index < count; ++index)
        CONCAT(buffer, ", " + marg_list[index]);
    
    // Return the fully preprocessed message dispatch.
    CONCAT(buffer, ')');
    
    if (!aStringBuffer)
        return buffer;
}


objj_preprocessor.prototype.directive = function(tokens, aStringBuffer, allowedDirectivesFlags)
{
    // Grab the next token, preprocessor directives follow '@' immediately.
    var buffer = aStringBuffer ? aStringBuffer : new objj_stringBuffer(),
        token = tokens.next();
            
    // To provide compatibility with Objective-C files, we convert NSString literals into 
    // toll-freed JavaScript/CPString strings.
    if (token.charAt(0) == TOKEN_DOUBLE_QUOTE)
        CONCAT(buffer, token);
    
    // Currently we simply swallow forward declarations and only provide them to allow 
    // compatibility with Objective-C files.
    else if (token == TOKEN_CLASS)
    {
        tokens.skip_whitespace();
        
        return;
    }
    
    // @implementation Class implementations
    else if (token == TOKEN_IMPLEMENTATION)
        this.implementation(tokens, buffer);

    // @import
    else if (token == TOKEN_IMPORT)
        this._import(tokens);

    // @selector
    else if (token == TOKEN_SELECTOR)
        this.selector(tokens, buffer);
    
    else if (token == TOKEN_ACCESSORS)
        return this.accessors(tokens);
    
    if (!aStringBuffer)
        return buffer;
}

objj_preprocessor.prototype.fragment = function()
{
    var preprocessed = this._preprocessed.toString();
    
    // But make sure it's not just all whitespace!
    if ((/[^\s]/).test(preprocessed))
        this._fragments.push(fragment_create_code(preprocessed, OBJJ_CURRENT_BUNDLE, this._file));
    
    this._preprocessed.clear();
}

objj_preprocessor.prototype.implementation = function(tokens, /*objj_stringBuffer*/ aStringBuffer)
{
    var buffer = aStringBuffer,
        token = "",
        category = NO,
        class_name = tokens.skip_whitespace(),
        superclass_name = "Nil",
        
        instance_methods = new objj_stringBuffer(),
        class_methods = new objj_stringBuffer();
    
    if (!(/^\w/).test(class_name))
        objj_exception_throw(new objj_exception(OBJJParseException, "*** Expected class name, found \"" + class_name + "\"."));
    
    this._currentSuperClass = NULL;
    this._currentClass = class_name;
    
    // If we reach an open parenthesis, we are declaring a category.
    if((token = tokens.skip_whitespace()) == TOKEN_OPEN_PARENTHESIS)
    {
        token = tokens.skip_whitespace();
        
        if (token == TOKEN_CLOSE_PARENTHESIS)
            objj_exception_throw(new objj_exception(OBJJParseException, "*** Can't Have Empty Category Name for class \"" + class_name + "\"."));
        
        if (tokens.skip_whitespace() != TOKEN_CLOSE_PARENTHESIS)
            objj_exception_throw(new objj_exception(OBJJParseException, "*** Improper Category Definition for class \"" + class_name + "\"."));
        
        CONCAT(buffer, "{\nvar the_class = objj_getClass(\"" + class_name + "\")\n");
        CONCAT(buffer, "if(!the_class) objj_exception_throw(new objj_exception(OBJJClassNotFoundException, \"*** Could not find definition for class \\\"" + class_name + "\\\"\"));\n");
        CONCAT(buffer, "var meta_class = the_class.isa;");
        
        var superclass_name = dictionary_getValue(SUPER_CLASSES, class_name);
        
        // FIXME: We should have a better solution for this case, although it's actually not much slower than the real case.
        if (!superclass_name)
            this._currentSuperClass = "objj_getClass(\"" + class_name + "\").super_class";
        else
            this._currentSuperClass = "objj_getClass(\"" + superclass_name + "\")";
    }
    else
    {
        // If we reach a colon (':'), then a superclass is being declared.
        if(token == TOKEN_COLON)
        {
            token = tokens.skip_whitespace();
            
            if (!(/^[a-zA-Z_$](\w|$)*$/).test(token))
                objj_exception_throw(new objj_exception(OBJJParseException, "*** Expected class name, found \"" + token + "\"."));
            
            superclass_name = token;
            this._currentSuperClass = "objj_getClass(\"" + superclass_name + "\")";
            
            dictionary_setValue(SUPER_CLASSES, class_name, superclass_name);

            token = tokens.skip_whitespace();
        }
        
        CONCAT(buffer, "{var the_class = objj_allocateClassPair(" + superclass_name + ", \"" + class_name + "\"),\nmeta_class = the_class.isa;");
        
        // If we are at an opening curly brace ('{'), then we have an ivar declaration.
        if (token == TOKEN_OPEN_BRACE)
        {
            var ivar_count = 0,
                declaration = [],
                
                attributes,
                accessors = {};
            
            while((token = tokens.skip_whitespace()) && token != TOKEN_CLOSE_BRACE)
            {
                if (token == TOKEN_PREPROCESSOR)
                    attributes = this.directive(tokens);
                
                else if (token == TOKEN_SEMICOLON)
                {
                    if (ivar_count++ == 0)
                        CONCAT(buffer, "class_addIvars(the_class, [");
                    else
                        CONCAT(buffer, ", ");
                    
                    var name = declaration[declaration.length - 1];
                    
                    CONCAT(buffer, "new objj_ivar(\"" + name + "\")");
                    
                    declaration = [];
                    
                    if (attributes)
                    {
                        accessors[name] = attributes;
                        attributes = NULL;
                    }
                }
                else
                    declaration.push(token);
            }
            
            // If we have objects in our declaration, the user forgot a ';'.
            if (declaration.length)
                objj_exception_throw(new objj_exception(OBJJParseException, "*** Expected ';' in ivar declaration, found '}'."));

            if (ivar_count)
                CONCAT(buffer, "]);\n");
            
            if (!token)
                objj_exception_throw(new objj_exception(OBJJParseException, "*** Expected '}'"));
            
            for (ivar_name in accessors)
            {
                var accessor = accessors[name],
                    property = accessor["property"] || name,
                    getterName = accessor["getter"] || property,
                    getterCode = "(id)" + getterName + "\n{\nreturn " + name + ";\n}";

                if (IS_NOT_EMPTY(instance_methods))
                    CONCAT(instance_methods, ",\n");
                
                CONCAT(instance_methods, this.method(new objj_lexer(getterCode)));
                
                // setter
                if (accessor["readonly"])
                    continue;
                
                var setterName = accessor["setter"];
                
                if (!setterName)
                {
                    var start = property.charAt(0) == '_' ? 1 : 0;
                    
                    setterName = "set" + property.substr(start, 1).toUpperCase() + property.substring(start + 1) + ":";
                }
                
                var setterCode = "(void)" + setterName + "(id)newValue\n{\n";
                
                if (accessor["copy"])
                    setterCode += "if (" + name + " !== newValue)\n" + name + " = [newValue copy];\n}";
                else
                    setterCode += name + " = newValue;\n}";
                
                if (IS_NOT_EMPTY(instance_methods))
                    CONCAT(instance_methods, ",\n");
                
                CONCAT(instance_methods, this.method(new objj_lexer(setterCode)));
            }
        }
        else
            tokens.previous();
        
        // We must make a new class object for our class definition.
        CONCAT(buffer, "objj_registerClassPair(the_class);\n");

        // Add this class to the current bundle.
        CONCAT(buffer, "objj_addClassForBundle(the_class, objj_getBundleWithPath(OBJJ_CURRENT_BUNDLE.path));\n");
    }
    
    while ((token = tokens.skip_whitespace()))
    {
        if (token == TOKEN_PLUS)
        {
            if (IS_NOT_EMPTY(class_methods))
                CONCAT(class_methods, ", ");
            
            CONCAT(class_methods, this.method(tokens));
        }
        
        else if (token == TOKEN_MINUS)
        {
            if (IS_NOT_EMPTY(instance_methods))
                CONCAT(instance_methods, ", ");
            
            CONCAT(instance_methods, this.method(tokens));
        }
        
        // Check if we've reached @end...
        else if (token == TOKEN_PREPROCESSOR)
        {
            // The only preprocessor directive we should ever encounter at this point is @end.
            if ((token = tokens.next()) == TOKEN_END)
                break;
            
            else
                objj_exception_throw(new objj_exception(OBJJParseException, "*** Expected \"@end\", found \"@" + token + "\"."));
        }
    }
    
    if (IS_NOT_EMPTY(instance_methods))
    {
        CONCAT(buffer, "class_addMethods(the_class, [");
        CONCAT(buffer, instance_methods);
        CONCAT(buffer, "]);\n");
    }
    
    if (IS_NOT_EMPTY(class_methods))
    {
        CONCAT(buffer, "class_addMethods(meta_class, [");
        CONCAT(buffer, class_methods);
        CONCAT(buffer, "]);\n");
    }
    
    CONCAT(buffer, '}');
}

objj_preprocessor.prototype._import = function(tokens)
{
    // The introduction of an import statement forces the creation of a code fragment.
    this.fragment();
    
    var path = "",
        token = tokens.skip_whitespace(),
        isLocal = (token != TOKEN_LESS_THAN);

    if (token == TOKEN_LESS_THAN)
    {
        while((token = tokens.next()) && token != TOKEN_GREATER_THAN)
            path += token;
        
        if(!token)
            objj_exception_throw(new objj_exception(OBJJParseException, "*** Unterminated import statement."));
    }
    
    else if (token.charAt(0) == TOKEN_DOUBLE_QUOTE)
        path = token.substr(1, token.length - 2);
    
    else
        objj_exception_throw(new objj_exception(OBJJParseException, "*** Expecting '<' or '\"', found \"" + token + "\"."));
    
    this._fragments.push(fragment_create_file(path, NULL, isLocal, this._file));
}

objj_preprocessor.prototype.method = function(tokens)
{
    var buffer = new objj_stringBuffer(),
        token,
        selector = "",
        parameters = [];
    
    while((token = tokens.skip_whitespace()) && token != TOKEN_OPEN_BRACE)
    {
        if (token == TOKEN_COLON)
        {
            // Colons are part of the selector name
            selector += token;
            
            token = tokens.skip_whitespace();
            
            if (token == TOKEN_OPEN_PARENTHESIS)
            {
                // Swallow parameter/return type.  Perhaps later we can use this for debugging?
                while((token = tokens.skip_whitespace()) && token != TOKEN_CLOSE_PARENTHESIS) ;
    
                token = tokens.skip_whitespace();
            }
            
            // Since this follows a colon, this must be the parameter name.
            parameters[parameters.length] = token;
        }
        
        else if (token == TOKEN_OPEN_PARENTHESIS)
            // Since :( is handled above, this must be the return type, just swallow it.
            while((token = tokens.skip_whitespace()) && token != TOKEN_CLOSE_PARENTHESIS) ;
        
        // Argument list ", ..."
        else if (token == TOKEN_COMMA)
        {
            // At this point, "..." MUST follow.
            if ((token = tokens.skip_whitespace()) != TOKEN_PERIOD || tokens.next() != TOKEN_PERIOD || tokens.next() != TOKEN_PERIOD)
                objj_exception_throw(new objj_exception(OBJJParseException, "*** Argument list expected after ','."));
            
            // FIXME: Shouldn't allow any more after this.
        }
        
        // Build selector name.
        else
            selector += token;
    }

    var index = 0,
        count = parameters.length;
    
    CONCAT(buffer, "new objj_method(sel_getUid(\"");
    CONCAT(buffer, selector);
    CONCAT(buffer, "\"), function ");
    CONCAT(buffer, "$" + this._currentClass + "__" + selector.replace(/:/g, "_"));
    CONCAT(buffer, "(self, _cmd");
    
    for(; index < count; ++index)
    {
        CONCAT(buffer, ", ");
        CONCAT(buffer, parameters[index]);
    }

    CONCAT(buffer, ")\n{ with(self)\n{");
    CONCAT(buffer, this.preprocess(tokens, NULL, TOKEN_CLOSE_BRACE, TOKEN_OPEN_BRACE));
    CONCAT(buffer, "}\n})");

    return buffer;
}

objj_preprocessor.prototype.preprocess = function(tokens, /*objj_stringBuffer*/ aStringBuffer, terminator, instigator)
{
    var buffer = aStringBuffer ? aStringBuffer : new objj_stringBuffer(),
        count = 0,
        token = "";

    while((token = tokens.next()) && ((token != terminator) || count))
    {
        if (instigator)
        { 
            if (token == instigator)
                ++count;
            
            else if (token == terminator) 
                --count;    
        }
        
        // We convert import statements into objj_request_import function calls, converting
        // the the file paths to use the proper search arguments.
        if(token == TOKEN_IMPORT)
        {
            objj_fprintf(warning_stream, "import keyword is deprecated, use @import instead.");
            
            this._import(tokens);
        }
        // Safari can't handle function declarations of the form function [name]([arguments]) { } 
        // in evals.  It requires them to be in the form [name] = function([arguments]) { }.  So we 
        // need to find these and fix them.
        else if(token == TOKEN_FUNCTION)
        {//if (window.p) alert("function");
            var accumulator = "";
        
            // Following the function identifier we can either have an open parenthesis or an identifier:
            while((token = tokens.next()) && token != TOKEN_OPEN_PARENTHESIS && !(/^\w/).test(token))
                accumulator += token;
            
            // If the next token is an open parenthesis, we have a standard function and we don't have to 
            // change it:
            if(token == TOKEN_OPEN_PARENTHESIS)
                CONCAT(buffer, "function" + accumulator + '(');
            
            // If it's not a parenthesis, we know we have a non-supported function declaration, so fix it:
            else
            {
                CONCAT(buffer, token + "= function");
            
#if FIREBUG
                var functionName = token;

                // Skip everything until the next close parenthesis.
                while((token = tokens.next()) && token != TOKEN_CLOSE_PARENTHESIS)
                    CONCAT(buffer, token);
                    
                // Don't forget the last token!
                CONCAT(buffer, token);
                
                // Skip everything until the next open curly brace. 
                while((token = tokens.next()) && token != TOKEN_OPEN_BRACE)
                    CONCAT(bfufer, token);
                
                // Place the open curly brace as well, and the function name
                CONCAT(buffer, token + "\n \"__FIREBUG_FNAME__" + functionName + "\".length;\n");
#endif
            }
        }
        
        // If we reach an @ symbol, we are at a preprocessor directive.
        else if (token == TOKEN_PREPROCESSOR)
            this.directive(tokens, buffer);
        
        // If we reach a bracket, we will either be preprocessing a message send, a literal 
        // array, or an array index.
        else if (token == TOKEN_OPEN_BRACKET)
            this.brackets(tokens, buffer);
        
        // If not simply append the token.
        else
            CONCAT(buffer, token);
    }
    
    if (!aStringBuffer)
        return buffer;
}

objj_preprocessor.prototype.selector = function(tokens, aStringBuffer)
{
    var buffer = aStringBuffer ? aStringBuffer : new objj_stringBuffer();
    
    CONCAT(buffer, "sel_getUid(\"");
    
    // Swallow open parenthesis.
    if (tokens.skip_whitespace() != TOKEN_OPEN_PARENTHESIS)
        objj_exception_throw(new objj_exception(OBJJParseException, "*** Expected ')'"));
    
    // Eat leading whitespace
    var selector = tokens.skip_whitespace();
    
    if (selector == TOKEN_CLOSE_PARENTHESIS)
        objj_exception_throw(new objj_exception(OBJJParseException, "*** Unexpected ')', can't have empty @selector()"));
    
    CONCAT(aStringBuffer, selector);
    
    var token,
        starting = true;
    
    while ((token = tokens.next()) && token != TOKEN_CLOSE_PARENTHESIS)
    {
        if (starting && /^\d+$/.test(token) || !(/^(\w|$|\:)/.test(token)))
        {
            // Only allow tail whitespace
            if (!(/\S/).test(token))
                if (tokens.skip_whitespace() == TOKEN_CLOSE_PARENTHESIS)
                    break;
                else
                    objj_exception_throw(new objj_exception(OBJJParseException, "*** Unexpected whitespace in @selector()."));
            else
                objj_exception_throw(new objj_exception(OBJJParseException, "*** Illegal character '" + token + "' in @selector()."));
        }
        
        CONCAT(buffer, token);
        starting = (token == TOKEN_COLON);
    }
    
    CONCAT(buffer, "\")");

    if (!aStringBuffer)
        return buffer;
}
