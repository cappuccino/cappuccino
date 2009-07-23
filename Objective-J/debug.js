// formatting helpers

function objj_debug_object_format(aReceiver)
{
    return (aReceiver && aReceiver.isa) ? sprintf("<%s %#08x>", GETMETA(aReceiver).name, aReceiver.__address) : String(aReceiver);
}

function objj_debug_message_format(aReceiver, aSelector)
{
    return sprintf("[%s %s]", objj_debug_object_format(aReceiver), aSelector);
}


// save the original msgSend implementations so we can restore them later
var objj_msgSend_original = objj_msgSend,
    objj_msgSendSuper_original = objj_msgSendSuper;


// decorator management functions

// reset to default objj_msgSend* implementations
function objj_msgSend_reset()
{
    objj_msgSend = objj_msgSend_original;
    objj_msgSendSuper = objj_msgSendSuper_original;
}

// decorate both objj_msgSend and objj_msgSendSuper
function objj_msgSend_decorate()
{
    for (var i = 0; i < arguments.length; i++)
    {
        objj_msgSend = arguments[i](objj_msgSend);
        objj_msgSendSuper = arguments[i](objj_msgSendSuper);
    }
}

// reset then decorate both objj_msgSend and objj_msgSendSuper
function objj_msgSend_set_decorators()
{
    objj_msgSend_reset();
    objj_msgSend_decorate.apply(null, arguments);
}


// backtrace decorator

var objj_backtrace = [];
function objj_backtrace_decorator(msgSend)
{
    return function(aReceiverOrSuper, aSelector)
    {
        var aReceiver = aReceiverOrSuper && (aReceiverOrSuper.receiver || aReceiverOrSuper);
        
        // push the receiver and selector onto the backtrace stack
        objj_backtrace.push({ receiver: aReceiver, selector : aSelector });
        try
        {
            return msgSend.apply(null, arguments);
        }
        catch (anException)
        {
            // print the exception and backtrace
            objj_fprintf(warning_stream, "Exception " + anException + " in " + objj_debug_message_format(aReceiver, aSelector));
            for (var i = 0; i < objj_backtrace.length; i++)
                objj_fprintf(warning_stream, objj_debug_message_format(objj_backtrace[i].receiver, objj_backtrace[i].selector));
        }
        finally
        {
            // make sure to always pop
            objj_backtrace.pop();
        }
    }
}

// type checking decorator

var objj_typechecks_reported = {};
function objj_typecheck_decorator(msgSend)
{
    return function(aReceiverOrSuper, aSelector)
    {
        var aReceiver = aReceiverOrSuper && (aReceiverOrSuper.receiver || aReceiverOrSuper);
        
        if (!aReceiver)
            return msgSend.apply(null, arguments);

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
                    objj_typechecks_reported[key] = true;
                    objj_fprintf(warning_stream, "Type check failed on argument " + (i-2) + " of " + objj_debug_message_format(aReceiver, aSelector) + ": " + e);
                }
            }
        }
        
        var result = msgSend.apply(null, arguments);

        try
        {
            objj_debug_typecheck(types[0], result);
        }
        catch (e)
        {
            var key = [GETMETA(aReceiver).name, aSelector, "ret", e].join(";");
            if (!objj_typechecks_reported[key]) {
                objj_typechecks_reported[key] = true;
                objj_fprintf(warning_stream, "Type check failed on return val of " + objj_debug_message_format(aReceiver, aSelector) + ": " + e);
            }
        }

        return result;
    }
}

// type checking logic:
function objj_debug_typecheck(expectedType, object)
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
        else if (object.isa)
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
    if (object === null)
        actualType = "null";
    else if (object === undefined)
        actualType = "void";
    else if (object.isa)
        actualType = GETMETA(object).name;
    else
        actualType = typeof object;
        
    throw ("expected=" + expectedType + ", actual=" + actualType);
}

// profile decorator
/*
function objj_debug_profile(msgSend)
{
    return function(aReceiverOrSuper, aSelector)
    {
        var aReceiver = aReceiverOrSuper && (aReceiverOrSuper.receiver || aReceiverOrSuper);
        
        // profiling book keeping 
        var profileRecord = {
            parent      : objj_debug_profile,
            receiver    : aReceiver && GETMETA(aReceiver).name,
            selector    : aSelector,
            calls       : []
        }
        objj_debug_profile.calls.push(profileRecord);
        objj_debug_profile = profileRecord;
        profileRecord.start = new Date();

        try
        {
            return msgSend.apply(null, arguments);
        }
        finally
        {
            profileRecord.end = new Date();
            objj_debug_profile = profileRecord.parent;
        }
    }
}

// FIXME: This could be much better.
var objj_debug_backtrace;
    
function objj_backtrace_set_enabled(enabled)
{
    if (enabled)
    {
        objj_debug_backtrace = [];
        objj_msgSend = objj_msgSend_Backtrace;
        objj_msgSendSuper = objj_msgSendSuper_Backtrace;
    }
    else
    {
        objj_msgSend = objj_msgSend_Standard;
        objj_msgSendSuper = objj_msgSendSuper_Standard;
    }
}

function objj_debug_print_backtrace()
{
    alert(objj_debug_backtrace_string());
}

function objj_debug_backtrace_string()
{
    return objj_debug_backtrace ? objj_debug_backtrace.join("\n") : "";
}

var objj_debug_profile = null,
    objj_currently_profiling = false,
    objj_profile_cleanup;

function objj_profile(title)
{
    if (objj_currently_profiling)
        return;
    
    var objj_msgSend_profile_saved = objj_msgSend,
        objj_msgSendSuper_profile_saved = objj_msgSendSuper;
    
    objj_msgSend = objj_msgSend_Profile;
    objj_msgSendSuper = objj_msgSendSuper_Profile;
    
    var root = { calls: [] };
    objj_debug_profile = root;
    
    var context = {
        start : new Date(),
        title : title,
        profile : root
    };

    objj_profile_cleanup = function() {
        objj_msgSend = objj_msgSend_profile_saved;
        objj_msgSendSuper = objj_msgSendSuper_profile_saved;
        context.end = new Date();
        return context;
    }
    
    objj_currently_profiling = true;
}

function objj_profileEnd()
{
    if (!objj_currently_profiling)
        return;
    
    objj_debug_profile = null;
    objj_currently_profiling = false;
    
    return objj_profile_cleanup();
}
*/

objj_msgSend_set_decorators(objj_typecheck_decorator, objj_backtrace_decorator);
