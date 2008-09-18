/*
 * preprocess.js
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

OBJJParseException          = "OBJJParseException";
OBJJClassNotFoundException  = "OBJJClassNotFoundException";

var TOKEN_NEW               = "new",
    TOKEN_SUPER             = "super",
    TOKEN_CLASS             = "class",
    TOKEN_IMPORT            = "import",
    TOKEN_FUNCTION          = "function",
    TOKEN_SELECTOR          = "selector",
    TOKEN_IMPLEMENTATION    = "implementation",
                            
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
    

// FIXME: This could break with static preinterpretation.
var SUPER_CLASSES           = new objj_dictionary(),
    CURRENT_SUPER_CLASS     = NULL,
    CURRENT_CLASS_NAME      = NULL;

var OBJJ_CURRENT_BUNDLE     = NULL;

// FIXME: Used fixed regex
var objj_lexer = function(aString, aSourceFile)
{
    this._index = 0;
    this._tokens = (aString + '\n').match(/\/\/.*(\r|\n)?|\/\*(?:.|\n|\r)*?\*\/|\w+\b|[+-]?\d+(([.]\d+)*([eE][+-]?\d+))?|"[^"\\]*(\\.[^"\\]*)*"|'[^'\\]*(\\.[^'\\]*)*'|\s+|./g);
    
    this.file = aSourceFile;
    
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

var objj_preprocess_method = function(tokens, count, array_name)
{
    var token,
        selector = "",
        parameters = new Array();
    
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

    var i= 0,
        length = parameters.length,
        selectorDisplayName = "$"+CURRENT_CLASS_NAME+"__"+selector.replace(/:/g, "_"),
        preprocessed = array_name + "["+count+"] = new objj_method(sel_registerName(\""+selector+"\"), function "+selectorDisplayName+"(self, _cmd";
    
    for(; i < length; ++i)
        preprocessed += ", " + parameters[i];
    
#if FIREBUG
    // FireBug auto expands and doesn't allow you to resize, so truncate it.
    var truncatedSelector = "["+CURRENT_CLASS_NAME+" "+(selector.length > 60 ? selector.substring(0, 60) + "..." : selector)+"]";
    return preprocessed + ")\n{ \"__FIREBUG_FNAME__"+truncatedSelector+"\".length;\n with(self)\n{" + objj_preprocess_tokens(tokens, TOKEN_CLOSE_BRACE, TOKEN_OPEN_BRACE) + "}\n});\n";
#else
    return preprocessed + ")\n{ with(self)\n{" + objj_preprocess_tokens(tokens, TOKEN_CLOSE_BRACE, TOKEN_OPEN_BRACE) + "}\n});\n";
#endif
}

var objj_preprocess_implementation= function(tokens)
{
    var token = "",
        category = NO,
        preprocessed = "",
        class_name = tokens.skip_whitespace(),
        superclass_name = "Nil",
        class_method_count = 0,
        instance_method_count = 0;
    
    if (!(/^\w/).test(class_name))
        objj_exception_throw(new objj_exception(OBJJParseException, "*** Expected class name, found \"" + class_name + "\"."));
    
    CURRENT_SUPER_CLASS = NULL;
    CURRENT_CLASS_NAME = class_name;
    
    // NOTE: This behavior is currently turned off.
    // addWorkingClass(class_name);
    
    // If we reach an open parenthesis, we are declaring a category.
    if((token = tokens.skip_whitespace()) == TOKEN_OPEN_PARENTHESIS)
    {
        token = tokens.skip_whitespace();
        
        if(tokens.skip_whitespace() != TOKEN_CLOSE_PARENTHESIS)
            objj_exception_throw(new objj_exception(OBJJParseException, "*** Improper Category Definition for class \""+class_name+"\"."));
        
        preprocessed += "{\nvar the_class = objj_getClass(\"" + class_name + "\")\n";
        preprocessed += "if(!the_class) objj_exception_throw(new objj_exception(OBJJClassNotFoundException, \"*** Could not find definition for class \\\"" + class_name + "\\\"\"));\n";
        preprocessed += "var meta_class = the_class.isa;";
        
        var superclass_name = dictionary_getValue(SUPER_CLASSES, class_name);
        
        // FIXME: We should have a better solution for this case, although it's actually not much slower than the real case.
        if (!superclass_name)
            CURRENT_SUPER_CLASS = "objj_getClass(\"" + class_name + "\").super_class";
        else
            CURRENT_SUPER_CLASS = "objj_getClass(\"" + superclass_name + "\")"; 
    }
    else
    {
        // If we reach a colon (':'), then a superclass is being declared.
        if(token == TOKEN_COLON)
        {
            token = tokens.skip_whitespace();
            if (!(/^\w/).test(token))
                objj_exception_throw(new objj_exception(OBJJParseException, "*** Expected class name, found \"" + token + "\"."));
            
            superclass_name = token;
            CURRENT_SUPER_CLASS = "objj_getClass(\"" + superclass_name + "\")";
            
            dictionary_setValue(SUPER_CLASSES, class_name, superclass_name);

            token = tokens.skip_whitespace();
        }
        
        preprocessed += "{var the_class = objj_allocateClassPair(" + superclass_name + ", \"" + class_name + "\"),\nmeta_class = the_class.isa;";
        
        // If we are at an opening curly brace ('{'), then we have an ivar declaration.
        if (token == TOKEN_OPEN_BRACE)
        {
            var ivar = true,
                ivar_count = 0;
                
            while((token = tokens.skip_whitespace()) && token != TOKEN_CLOSE_BRACE)
            {
                if (token != TOKEN_SEMICOLON && (ivar = !ivar))
                {
                    if (ivar_count++ == 0)
                        preprocessed += "class_addIvars(the_class, [";
                    else
                        preprocessed += ", ";
                    
                    preprocessed += "new objj_ivar(\"" + token + "\")";
                }
            }

            if (ivar_count)
                preprocessed += "]);\n";
            
            if (!token)
                objj_exception_throw(new objj_exception(OBJJParseException, "*** Expected '}'"));
        }
        else tokens.previous();
        
        // We must make a new class object for our class definition.
        preprocessed += "objj_registerClassPair(the_class);\n";

        // Add this class to the current bundle.
        preprocessed += "objj_addClassForBundle(the_class, objj_getBundleWithPath(OBJJ_CURRENT_BUNDLE.path));\n";
    }
    
    while((token = tokens.skip_whitespace()))
    {
        if(token == TOKEN_PLUS) preprocessed += (class_method_count ? "" : "var class_methods = [];\n") + objj_preprocess_method(tokens, class_method_count++, "class_methods");
        else if(token == TOKEN_MINUS) preprocessed += (instance_method_count ? "" : "var instance_methods = [];\n") + objj_preprocess_method(tokens, instance_method_count++, "instance_methods"); 
        // Check if we've reached @end...
        else if(token == TOKEN_PREPROCESSOR)
        {
            // The only preprocessor directive we should ever encounter at this point is @end.
            if((token = tokens.next()) == "end")
                break;
            else
                objj_exception_throw(new objj_exception(OBJJParseException, "*** Expected \"@end\", found \"@" + token + "\"."));
        }
    }
    
    // Do the instance methods first because they could override the class methods if not.
    if (instance_method_count) preprocessed += "class_addMethods(the_class, instance_methods);\n";
    if (class_method_count) preprocessed += "class_addMethods(meta_class, class_methods);\n";
    
    return preprocessed + '}';
}

var objj_preprocess_directive = function(tokens)
{
    // Grab the next token, preprocessor directives follow '@' immediately.
    token = tokens.next();
            
    // To provide compatibility with Objective-C files, we convert NSString literals into 
    // toll-freed JavaScript/CPString strings.
    if(token.charAt(0) == TOKEN_DOUBLE_QUOTE) return token;
    // Currently we simply swallow forward declarations and only provide them to allow 
    // compatibility with Objective-C files.
    else if(token == TOKEN_CLASS) { tokens.skip_whitespace(); return ""; }
    // @implementation Class implementations
    else if(token == TOKEN_IMPLEMENTATION) return objj_preprocess_implementation(tokens);
    // @selector
    else if(token == TOKEN_SELECTOR)
    {
        // Swallow open parenthesis.
        if (tokens.skip_whitespace() != TOKEN_OPEN_PARENTHESIS)
            objj_exception_throw(new objj_exception(OBJJParseException, "*** Expected ')'"));
        return "sel_registerName(\"" + objj_preprocess_tokens(tokens, TOKEN_CLOSE_PARENTHESIS) +"\")";
    }
    
    return "";
}

var objj_preprocess_brackets = function(tokens)
{
    // We maintain two parallel interpretations through the process,
    // One which assumes the brackets form a literal array, and
    // another that builds the possible message dispatch composed of
    // a receiver, a selector, and a number of marg_list.
    var literal = '[',
        receiver = "",
        selector = "",
        marg_list = new Array(),
        preprocessed = "objj_msgSend";
    
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
                preprocessed = "objj_msgSendSuper";
                token = "{ receiver:self, super_class:" + CURRENT_SUPER_CLASS + " }";
            }
            else
                objj_exception_throw(new objj_exception(OBJJParseException, "*** Can't use 'super' in this context."));
        }
        else if (token == TOKEN_OPEN_BRACE) ++braces;
        else if (token == TOKEN_CLOSE_BRACE) --braces;
        // Tertiary expressions have the potential to confuse the preprocessor, 
        // so keep track of them to avoid misidentifying a colon (':') for an 
        // argument.
        else if(token == TOKEN_QUESTION_MARK) ++tertiary;
        // Keep track of expressions within parenthesis.
        else if(token == TOKEN_OPEN_PARENTHESIS) ++parenthesis;
        else if(token == TOKEN_CLOSE_PARENTHESIS) --parenthesis;
        // If we reach a nested bracket, preprocess it first and interpret 
        // the result as the current token.
        else if(token == TOKEN_OPEN_BRACKET) token = objj_preprocess_brackets(tokens);
        else if(token == TOKEN_PREPROCESSOR) token = objj_preprocess_directive(tokens);
        
        // Preprocess tokens only if we're not within parenthesis or in a 
        // tertiary statement.
        if(preprocess)
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
                                
                previous = token;
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
            literal += "new ";
        else
            literal += token;
    }

    // If we have a selector, then add the remaining string to the argument.
    if (selector.length) marg_list[marg_list.length - 1] += previous;
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
    else return literal + ']';
    
    // NOTE: For now, turn this behavior off.
    // Classes act much like keywords since they are not directly manipulatable.
    // We thus check whether it exists in our class hash or working hash, and if 
    // instead use a reference to it if it does.
    // if (tokens.containsClass(receiver) || objj_getClass(receiver)) receiver = "objj_getClass(\"" + receiver + "\")";

    // The first two arguments are always the receiver and the selector.
    preprocessed += '(' + receiver + ", \"" + sel_registerName(selector) + "\"";
    
    // Populate the remaining parameters with the provided arguments.
    var i = 0,
        length = marg_list.length;
    
    for(; i < length; ++i)
        preprocessed += ", " + marg_list[i];
    
    // Return the fully preprocessed message dispatch.
    return preprocessed + ')';
}

function objj_preprocess_tokens(tokens, terminator, instigator, segment)
{//if (window.p) alert("objj_preprocess_tokens");
    var count = 0,
        token = "",
        fragments = [],
        preprocessed = "";

    while((token = tokens.next()) && ((token != terminator) || count))
    {
        if (instigator)
        { 
            if (token == instigator) ++count;
            else if (token == terminator) --count;    
        }
        
        // We convert import statements into objj_request_import function calls, converting
        // the the file paths to use the proper search arguments.
        if(token == TOKEN_IMPORT)
        {
            if ((/[^\s]/).test(preprocessed))
                fragments.push(fragment_create_code(preprocessed, OBJJ_CURRENT_BUNDLE, tokens.file));

            preprocessed = "";
            
            var path = "",
                token = tokens.skip_whitespace(),
                isLocal = token != TOKEN_LESS_THAN;

            if(token == TOKEN_LESS_THAN)
            {
                while((token= tokens.next()) && token != TOKEN_GREATER_THAN) path+= token;
                if(!token) objj_throw("Parser Error - Unterminated import statement.");
            }
            else if(token.charAt(0) == TOKEN_DOUBLE_QUOTE) path= token.substr(1, token.length-2);
            else
                objj_exception_throw(new objj_exception(OBJJParseException, "*** Expecting '<' or '\"', found \"" + token + "\"."));
            
            fragments.push(fragment_create_file(path, NULL, isLocal, YES, tokens.file));
        }
        // Safari can't handle function declarations of the form function [name]([arguments]) { } 
        // in evals.  It requires them to be in the form [name] = function([arguments]) { }.  So we 
        // need to find these and fix them.
        else if(token == TOKEN_FUNCTION)
        {//if (window.p) alert("function");
            var accumulator= "";
        
            // Following the function identifier we can either have an open parenthesis or an identifier:
            while((token = tokens.next()) && token != TOKEN_OPEN_PARENTHESIS && !(/^\w/).test(token))
                accumulator += token;
            
            // If the next token is an open parenthesis, we have a standard function and we don't have to 
            // change it:
            if(token == TOKEN_OPEN_PARENTHESIS)
                preprocessed+= "function"+accumulator+'(';
            // If it's not a parenthesis, we know we have a non-supported function declaration, so fix it:
            else
            {
                preprocessed += token + "= function";
            
#if FIREBUG
                var functionName = token;

                // Skip everything until the next close parenthesis.
                while((token = tokens.next()) && token != TOKEN_CLOSE_PARENTHESIS)
                    preprocessed += token;
                    
                // Don't forget the last token!
                preprocessed += token;
                
                // Skip everything until the next open curly brace. 
                while((token = tokens.next()) && token != TOKEN_OPEN_BRACE)
                    preprocessed += token;
                
                // Place the open curly brace as well, and the function name
                preprocessed += token + "\n \"__FIREBUG_FNAME__" + functionName + "\".length;\n";
#endif
            }
        }
        // If we reach an @ symbol, we are at a preprocessor directive.
        else if(token == TOKEN_PREPROCESSOR)
            preprocessed+= objj_preprocess_directive(tokens);
        // If we reach a bracket, we will either be preprocessing a message send, a literal 
        // array, or an array index.
        else if(token == TOKEN_OPEN_BRACKET)
            preprocessed += objj_preprocess_brackets(tokens);
        // If not simply append the token.
        else
            preprocessed += token;
    }
    
    if (preprocessed.length && (/[^\s]/).test(preprocessed))
        fragments.push(fragment_create_code(preprocessed, OBJJ_CURRENT_BUNDLE, tokens.file));

    if (!segment)
        return fragments.length ? fragments[0].info : "";

    return fragments;
}

function objj_preprocess(aString, aBundle, aSourceFile) 
{    
    try
    {
        OBJJ_CURRENT_BUNDLE = aBundle;
    
        return objj_preprocess_tokens(new objj_lexer(aString, aSourceFile), nil, nil, YES);
    }
    catch (anException)
    {
        objj_exception_report(anException, aSourceFile);
    }
    
    return [];
}
