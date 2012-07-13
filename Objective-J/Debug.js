/*
 * Debug.js
 * Objective-J
 *
 * Created by Thomas Robinson.
 * Copyright 2008-2010, 280 North, Inc.
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

#ifdef BROWSER
CPLogRegister(CPLogDefault);
#endif

// formatting helpers

function objj_debug_object_format(aReceiver)
{
    return (aReceiver && aReceiver.isa) ? exports.sprintf("<%s %#08x>", GETMETA(aReceiver).name, aReceiver._UID) : String(aReceiver);
}

function objj_debug_message_format(aReceiver, aSelector)
{
    return exports.sprintf("[%s %s]", objj_debug_object_format(aReceiver), aSelector);
}


// save the original msgSend implementations so we can restore them later
var objj_msgSend_original = objj_msgSend,
    objj_msgSendSuper_original = objj_msgSendSuper;

// decorator management functions

// reset to default objj_msgSend* implementations
GLOBAL(objj_msgSend_reset) = function()
{
    objj_msgSend = objj_msgSend_original;
    objj_msgSendSuper = objj_msgSendSuper_original;
}

// decorate both objj_msgSend and objj_msgSendSuper
GLOBAL(objj_msgSend_decorate) = function()
{
    var index = 0,
        count = arguments.length;

    for (; index < count; ++index)
    {
        objj_msgSend = arguments[index](objj_msgSend);
        objj_msgSendSuper = arguments[index](objj_msgSendSuper);
    }
}

// reset then decorate both objj_msgSend and objj_msgSendSuper
GLOBAL(objj_msgSend_set_decorators) = function()
{
    objj_msgSend_reset();
    objj_msgSend_decorate.apply(NULL, arguments);
}


// backtrace decorator

var objj_backtrace = [];

GLOBAL(objj_backtrace_print) = function(/*Callable*/ aStream)
{
    var index = 0,
        count = objj_backtrace.length;

    for (; index < count; ++index)
    {
        var frame = objj_backtrace[index];

        aStream(objj_debug_message_format(frame.receiver, frame.selector));
    }
}

GLOBAL(objj_backtrace_decorator) = function(msgSend)
{
    return function(aReceiverOrSuper, aSelector)
    {
        var aReceiver = aReceiverOrSuper && (aReceiverOrSuper.receiver || aReceiverOrSuper);

        // push the receiver and selector onto the backtrace stack
        objj_backtrace.push({ receiver: aReceiver, selector : aSelector });
        try
        {
            return msgSend.apply(NULL, arguments);
        }
        catch (anException)
        {
            if (objj_backtrace.length)
            {
                // print the exception and backtrace
                CPLog.warn("Exception " + anException + " in " + objj_debug_message_format(aReceiver, aSelector));
                objj_backtrace_print(CPLog.warn);
                objj_backtrace = [];
            }
            // re-throw the exception
            throw anException;
        }
        finally
        {
            // make sure to always pop
            objj_backtrace.pop();
        }
    };
}

GLOBAL(objj_supress_exceptions_decorator) = function(msgSend)
{
    return function(aReceiverOrSuper, aSelector)
    {
        var aReceiver = aReceiverOrSuper && (aReceiverOrSuper.receiver || aReceiverOrSuper);

        try
        {
            return msgSend.apply(NULL, arguments);
        }
        catch (anException)
        {
            // print the exception and backtrace
            CPLog.warn("Exception " + anException + " in " + objj_debug_message_format(aReceiver, aSelector));
        }
    };
}

// type checking decorator

var objj_typechecks_reported = {},
    objj_typecheck_prints_backtrace = NO;

GLOBAL(objj_typecheck_decorator) = function(msgSend)
{
    return function(aReceiverOrSuper, aSelector)
    {
        var aReceiver = aReceiverOrSuper && (aReceiverOrSuper.receiver || aReceiverOrSuper);

        if (!aReceiver)
            return msgSend.apply(NULL, arguments);

        var types = aReceiver.isa.method_dtable[aSelector].types;
        for (var i = 2; i < arguments.length; i++)
        {
            try
            {
                objj_debug_typecheck(types[i-1], arguments[i]);
            }
            catch (e)
            {
                var key = [GETMETA(aReceiver).name, aSelector, i, e].join(";");
                if (!objj_typechecks_reported[key]) {
                    objj_typechecks_reported[key] = YES;
                    CPLog.warn("Type check failed on argument " + (i-2) + " of " + objj_debug_message_format(aReceiver, aSelector) + ": " + e);
                    if (objj_typecheck_prints_backtrace)
                        objj_backtrace_print(CPLog.warn);
                }
            }
        }

        var result = msgSend.apply(NULL, arguments);

        try
        {
            objj_debug_typecheck(types[0], result);
        }
        catch (e)
        {
            var key = [GETMETA(aReceiver).name, aSelector, "ret", e].join(";");
            if (!objj_typechecks_reported[key]) {
                objj_typechecks_reported[key] = YES;
                CPLog.warn("Type check failed on return val of " + objj_debug_message_format(aReceiver, aSelector) + ": " + e);
                if (objj_typecheck_prints_backtrace)
                    objj_backtrace_print(CPLog.warn);
            }
        }

        return result;
    };
}

// type checking logic:
GLOBAL(objj_debug_typecheck) = function(expectedType, object)
{
    var objjClass;

    if (!expectedType)
    {
        return;
    }
    else if (expectedType === "id")
    {
        if (object !== undefined)
            return;
    }
    else if (expectedType === "void")
    {
        if (object === undefined)
            return;
    }
    else if (objjClass = objj_getClass(expectedType))
    {
        if (object === nil)
        {
            return;
        }
        else if (object !== undefined && object.isa)
        {
            var theClass = object.isa;

            for (; theClass; theClass = theClass.super_class)
                if (theClass === objjClass)
                    return;
        }
    }
    else
    {
        return;
    }

    var actualType;
    if (object === NULL)
        actualType = "null";
    else if (object === undefined)
        actualType = "void";
    else if (object.isa)
        actualType = GETMETA(object).name;
    else
        actualType = typeof object;

    throw ("expected=" + expectedType + ", actual=" + actualType);
}
