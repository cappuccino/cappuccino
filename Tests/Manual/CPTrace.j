/*
 * CPTrace.j
 *
 * Created by cacaodev
 * Copyright 2012 <cacaodev@gmail.com>
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

var patchedClassesAndSelectors = [],
    globalStack = [],
    globalLevel = 0;

var Tracer = function()
{
    this.td = 0;
    this.tc = 0;
    this.displayFunction = nil;
};

Tracer.prototype.log = function()
{
    var c = globalStack.length;

    for (var i = 0; i < c; i++)
    {
        var trace = globalStack.shift();
        this.displayFunction(trace.receiver, trace.selector, trace.args, trace.duration, this.td, this.tc, trace.level);
    }
};

var defaultDisplay  = function(receiver, selector, args, duration, total_duration, total_count, level)
{
    var message = objj_message(receiver, selector, args),
        // WARNING: average duration only supported for root calls.
        avg_message = (level == 0) ? (" , avg = " + (ROUND(100 * total_duration / total_count) / 100) + " ms") : "";

    console.log(indent(level) + message + " in " + duration + " ms" + avg_message);
};

var indent = function(n)
{
    var str = "";
    while (n--)
        str += "  ";

    return str;
};

var objj_message = function(receiver, selector, args)
{
    var c = args.length,
        sel = selector.split(":"),
        rdesc = receiver ? [receiver description] : "<null>";

    while (c--)
        sel.splice(c + 1, 0, ":" + [args[c] description] + " ");

    var joined = sel.join("");

    if (args.length)
        joined = joined.substring(0, joined.length - 1);

    return ("[" + rdesc + " " + joined + "]");
};

function CPTrace(aClassName, aSelector, displayFunction)
{
    var aclass = CPClassFromString(aClassName);

    if (aclass)
       _CPTraceClass(aclass, aSelector, displayFunction);
    else if (typeof(objj_getClassList) != 'undefined')
    {
        var classes = [],
            patchednum = 0,
            numclasses = objj_getClassList(classes, 400),
            regex = new RegExp(aClassName);

        while (numclasses--)
        {
            var cls = classes[numclasses];
            if (regex.test(cls))
            {
                console.log("Patching " + cls + " -" + aSelector);
                _CPTraceClass(cls, aSelector, displayFunction);
                patchednum++;
            }
        }

        if (patchednum == 0)
            console.log("Could not find any class matching '" + aClassName + "'");
        else
            console.log("Patched " + patchednum + " classes matching " + aClassName);
    }
    else
        [CPException raise:CPInvalidArgumentException reason:("Unknown class name '" + aClassName + "'")];
}

var _CPTraceClass = function(aClass, aSelector, displayFunction)
{
    if (![aClass instancesRespondToSelector:aSelector])
        [CPException raise:CPInvalidArgumentException reason:(aClass + " does not respond to '" + aSelector + "'")];

    var superclass = aClass;
    while (![superclass instancesImplementsSelector:aSelector] && superclass != [CPObject class])
        superclass = [superclass superclass];

    var patchUniqueString = (superclass + "_" + aSelector);
    if ([patchedClassesAndSelectors containsObject:patchUniqueString])
    {
        if (superclass == aClass)
            console.log(superclass + " -" + aSelector + " is already patched. Ignoring.");
        else
            console.log("-" + aSelector + " is implemented in a superclass of " + aClass + " (" + superclass + ") where it's already patched. Ignoring.");

        return;
    }

    var patched_sel = CPSelectorFromString("patched_" + CPStringFromSelector(aSelector)),
        tracer = new Tracer();

    tracer.displayFunction = displayFunction ? displayFunction : defaultDisplay;

    class_addMethod(aClass, patched_sel, function()
    {
        var orig_arguments = arguments,
            receiver = orig_arguments[0],
            selector = orig_arguments[1],
            args = [];

        for (var i = 2; i < orig_arguments.length; i++)
            args.push(orig_arguments[i]);

        orig_arguments[1] = patched_sel;

        var trace = {receiver:receiver, selector:selector, args:args, start:(new Date()), level:globalLevel};
        globalStack.push(trace);
        globalLevel++;

        objj_msgSend.apply(objj_msgSend, orig_arguments);

        var duration = (trace.duration = new Date() - trace.start);
        globalLevel--;
        if (globalLevel == 0)
        {
            if (duration > 0)
                tracer.tc++;
            tracer.td += trace.duration;
            tracer.log();
        }

    }, "");

    Swizzle(aClass, aSelector, patched_sel);
    [patchedClassesAndSelectors addObject:patchUniqueString];
};

function CPTraceStop(aClass, aSelector)
{
    var patchUniqueString = (aClass + "_" + aSelector);
    if (![patchedClassesAndSelectors containsObject:patchUniqueString])
        return;

    var patched_sel = CPSelectorFromString("patched_" + CPStringFromSelector(aSelector));
    Swizzle(CPClassFromString(aClass), patched_sel, aSelector);
    [patchedClassesAndSelectors removeObject:patchUniqueString];
}

var Swizzle = function(aClass, orig_sel, new_sel)
{
    var origMethod = class_getInstanceMethod(aClass, orig_sel),
        newMethod = class_getInstanceMethod(aClass, new_sel);

// This check should be in class_addMethod : Don't add and return NO and if method already exists.
    if (getMethodNoSuper(aClass, orig_sel) == NULL)
    {
        class_addMethod(aClass, orig_sel, method_getImplementation(newMethod), "");
        class_replaceMethod(aClass, new_sel, method_getImplementation(origMethod), "");
    }
    else
        method_exchangeImplementations(origMethod, newMethod);

/*
    if (class_addMethod(aClass, orig_sel, method_getImplementation(newMethod), ""))
        class_replaceMethod(aClass, new_sel, method_getImplementation(origMethod), "");
    else
        method_exchangeImplementations(origMethod, newMethod);
*/
};


var getMethodNoSuper = function(cls, sel)
{
    var method_list = cls.method_list,
        count = method_list.length;

    while (count--)
    {
        var mthd = method_list[count];
        if (mthd.name == sel)
            return mthd;
    }

    return NULL;
}

/*
    Utility for moving average
*/
var moving_averager = function(period)
{
    var nums = [];

    return function(num)
    {
        nums.push(num);

        if (nums.length > period)
            nums.splice(0,1);  // remove the first element of the array

        var sum = 0,
            count = nums.length;

        for (var i = 0; i < count; i++)
            sum += nums[i];

        var n = period;

        if (count < period)
            n = count;

        return(sum / n);
    }
};

@implementation CPObject (instancesImplementsSelector)

- (BOOL)instancesImplementsSelector:(SEL)aSelector
{
    var methods = class_copyMethodList(self),
        count = methods.length;

    while (count--)
        if (method_getName(methods[count]) === aSelector)
            return YES;

    return NO;
}

@end