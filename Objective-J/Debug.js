// formatting helpers

function objj_debug_object_format(aReceiver)
{
    return (aReceiver && aReceiver.isa) ? sprintf("<%s %#08x>", GETMETA(aReceiver).name, aReceiver._UID) : String(aReceiver);
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
    objj_msgSend_decorate.apply(NULL, arguments);
}


// backtrace decorator

var objj_backtrace = [];

function objj_backtrace_print(stream) {
    for (var i = 0; i < objj_backtrace.length; i++)
        objj_fprintf(stream, objj_debug_message_format(objj_backtrace[i].receiver, objj_backtrace[i].selector));
}

function objj_backtrace_decorator(msgSend)
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
            // print the exception and backtrace
            objj_fprintf(warning_stream, "Exception " + anException + " in " + objj_debug_message_format(aReceiver, aSelector));
            objj_backtrace_print(warning_stream);
        }
        finally
        {
            // make sure to always pop
            objj_backtrace.pop();
        }
    }
}

// type checking decorator

var objj_typechecks_reported = {},
    objj_typecheck_prints_backtrace = NO;

function objj_typecheck_decorator(msgSend)
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
                    objj_fprintf(warning_stream, "Type check failed on argument " + (i-2) + " of " + objj_debug_message_format(aReceiver, aSelector) + ": " + e);
                    if (objj_typecheck_prints_backtrace)
                        objj_backtrace_print(warning_stream);
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
                objj_fprintf(warning_stream, "Type check failed on return val of " + objj_debug_message_format(aReceiver, aSelector) + ": " + e);
                if (objj_typecheck_prints_backtrace)
                    objj_backtrace_print(warning_stream);
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
        else if (object && object.isa)
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
