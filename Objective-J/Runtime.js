/*
 * Runtime.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
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

var CLS_CLASS           = 0x1,
    CLS_META            = 0x2,
    CLS_INITIALIZED     = 0x4,
    CLS_INITIALIZING    = 0x8;

#define CHANGEINFO(aClass, aSetInfoMask, aClearInfoMask) aClass.info = (aClass.info | (aSetInfoMask)) & ~(aClearInfoMask)
#define GETINFO(aClass, anInfoMask) (aClass.info & (anInfoMask))
#define SETINFO(aClass, anInfoMask) CHANGEINFO(aClass, anInfoMask, 0)
#define CLEARINFO(aClass, anInfoMask) CHANGEINFO(aClass, 0, anInfoMask)
#define ISMETA(aClass) (GETINFO(aClass, CLS_META))
#define GETMETA(aClass) (ISMETA(aClass) ? aClass : aClass.isa)
#define ISINITIALIZED(aClass) GETINFO(GETMETA(aClass), CLS_INITIALIZED)

// MAXIMUM_RECURSION_CHECKS
// If defined, objj_msgSend will check for recursion deeper than MAXIMUM_RECURSION_DEPTH and
// throw an error if found. While crude, this can be helpful when your JavaScript debugger
// crashes on recursion errors (e.g. Safari) or ignores them (e.g. Chrome).

// #define MAXIMUM_RECURSION_CHECKS
#define MAXIMUM_RECURSION_DEPTH 80

GLOBAL(objj_ivar) = function(/*String*/ aName, /*String*/ aType)
{
    this.name = aName;
    this.type = aType;
}

GLOBAL(objj_method) = function(/*String*/ aName, /*IMP*/ anImplementation, /*String*/ types)
{
    this.name = aName;
    this.method_imp = anImplementation;
    this.types = types;
}

GLOBAL(objj_class) = function(displayName)
{
    this.isa            = NULL;

    this.version        = 0;

    this.super_class    = NULL;
    this.sub_classes    = [];

    this.name           = NULL;
    this.info           = 0;

    this.ivar_list      = [];
    this.ivar_store     = function() { };
    this.ivar_dtable    = this.ivar_store.prototype;

    this.method_list    = [];
    this.method_store   = function() { };
    this.method_dtable  = this.method_store.prototype;

#if DEBUG
    // Naming the allocator allows the WebKit heap snapshot tool to display object class names correctly
    // HACK: displayName property is not respected so we must eval a function to name it
    eval("this.allocator = function " + (displayName || "OBJJ_OBJECT").replace(/\W/g, "_") + "() { }");
#else
    this.allocator      = function() { };
#endif

    this._UID           = -1;
}

GLOBAL(objj_object) = function()
{
    this.isa    = NULL;
    this._UID   = -1;
}

// Working with Classes

GLOBAL(class_getName) = function(/*Class*/ aClass)
{
    if (aClass == Nil)
        return "";

    return aClass.name;
}

GLOBAL(class_isMetaClass) = function(/*Class*/ aClass)
{
    if (!aClass)
        return NO;

    return ISMETA(aClass);
}

GLOBAL(class_getSuperclass) = function(/*Class*/ aClass)
{
    if (aClass == Nil)
        return Nil;

    return aClass.super_class;
}

GLOBAL(class_setSuperclass) = function(/*Class*/ aClass, /*Class*/ aSuperClass)
{
    // Set up the actual class hierarchy.
    aClass.super_class = aSuperClass;
    aClass.isa.super_class = aSuperClass.isa;
}

GLOBAL(class_addIvar) = function(/*Class*/ aClass, /*String*/ aName, /*String*/ aType)
{
    var thePrototype = aClass.allocator.prototype;

    // FIXME: Use getInstanceVariable
    if (typeof thePrototype[aName] != "undefined")
        return NO;

    var ivar = new objj_ivar(aName, aType);

    aClass.ivar_list.push(ivar);
    aClass.ivar_dtable[aName] = ivar;

    thePrototype[aName] = NULL;

    return YES;
}

GLOBAL(class_addIvars) = function(/*Class*/ aClass, /*Array*/ivars)
{
    var index = 0,
        count = ivars.length,
        thePrototype = aClass.allocator.prototype;

    for (; index < count; ++index)
    {
        var ivar = ivars[index],
            name = ivar.name;

        // FIXME: Use getInstanceVariable
        if (typeof thePrototype[name] === "undefined")
        {
            aClass.ivar_list.push(ivar);
            aClass.ivar_dtable[name] = ivar;

            thePrototype[name] = NULL;
        }
    }
}

GLOBAL(class_copyIvarList) = function(/*Class*/ aClass)
{
    return aClass.ivar_list.slice(0);
}

//#define class_copyIvarList(aClass) (aClass.ivar_list.slice(0))

#define METHOD_DISPLAY_NAME(aClass, aMethod) (ISMETA(aClass) ? '+' : '-') + " [" + class_getName(aClass) + ' ' + method_getName(aMethod) + ']'

GLOBAL(class_addMethod) = function(/*Class*/ aClass, /*SEL*/ aName, /*IMP*/ anImplementation, /*Array<String>*/ types)
{
    // FIXME: return NO if it exists?
    var method = new objj_method(aName, anImplementation, types);

    aClass.method_list.push(method);
    aClass.method_dtable[aName] = method;

#if DEBUG
    // Give this function a "pretty" name for the console.
    method.method_imp.displayName = METHOD_DISPLAY_NAME(aClass, method);
#endif

    // FIXME: Should this be done here?
    // If this is a root class...
    if (!ISMETA(aClass) && GETMETA(aClass).isa === GETMETA(aClass))
        class_addMethod(GETMETA(aClass), aName, anImplementation, types);

    return YES;
}

GLOBAL(class_addMethods) = function(/*Class*/ aClass, /*Array*/ methods)
{
    var index = 0,
        count = methods.length,

        method_list = aClass.method_list,
        method_dtable = aClass.method_dtable;

    for (; index < count; ++index)
    {
        var method = methods[index];

        // FIXME: Don't do it if it exists?
        method_list.push(method);
        method_dtable[method.name] = method;

#if DEBUG
        // Give this function a "pretty" name for the console.
        method.method_imp.displayName = METHOD_DISPLAY_NAME(aClass, method);
#endif
    }

    // If this is a root class...
    if (!ISMETA(aClass) && GETMETA(aClass).isa === GETMETA(aClass))
        class_addMethods(GETMETA(aClass), methods);
}

GLOBAL(class_getInstanceMethod) = function(/*Class*/ aClass, /*SEL*/ aSelector)
{
    if (!aClass || !aSelector)
        return NULL;

    var method = aClass.method_dtable[aSelector];

    return method ? method : NULL;
}

GLOBAL(class_getInstanceVariable) = function(/*Class*/ aClass, /*String*/ aName)
{
    if (!aClass || !aName)
        return NULL;

    // FIXME: this doesn't appropriately deal with Object's properties.
    var variable = aClass.ivar_dtable[aName];

    return variable;
}

GLOBAL(class_getClassMethod) = function(/*Class*/ aClass, /*SEL*/ aSelector)
{
    if (!aClass || !aSelector)
        return NULL;

    var method = GETMETA(aClass).method_dtable[aSelector];

    return method ? method : NULL;
}

GLOBAL(class_respondsToSelector) = function(/*Class*/ aClass, /*SEL*/ aSelector)
{
    return class_getClassMethod(aClass, aSelector) != NULL;
}

GLOBAL(class_copyMethodList) = function(/*Class*/ aClass)
{
    return aClass.method_list.slice(0);
}

GLOBAL(class_getVersion) = function(/*Class*/ aClass)
{
    return aClass.version;
}

GLOBAL(class_setVersion) = function(/*Class*/ aClass, /*Integer*/ aVersion)
{
    aClass.version = parseInt(aVersion, 10);
}

GLOBAL(class_replaceMethod) = function(/*Class*/ aClass, /*SEL*/ aSelector, /*IMP*/ aMethodImplementation)
{
    if (!aClass || !aSelector)
        return NULL;

    var method = aClass.method_dtable[aSelector],
        method_imp = NULL;

    if (method)
        method_imp = method.method_imp;

    method.method_imp = aMethodImplementation;

    return method_imp;
}

var _class_initialize = function(/*Class*/ aClass)
{
    var meta = GETMETA(aClass);

    if (GETINFO(aClass, CLS_META))
        aClass = objj_getClass(aClass.name);

    if (aClass.super_class && !ISINITIALIZED(aClass.super_class))
        _class_initialize(aClass.super_class);

    if (!GETINFO(meta, CLS_INITIALIZED) && !GETINFO(meta, CLS_INITIALIZING))
    {
        SETINFO(meta, CLS_INITIALIZING);

        objj_msgSend(aClass, "initialize");

        CHANGEINFO(meta, CLS_INITIALIZED, CLS_INITIALIZING);
    }
}

var _objj_forward = function(self, _cmd)
{
    var isa = self.isa,
        implementation = isa.method_dtable[SEL_forwardingTargetForSelector_];

    if (implementation)
    {
        var target = implementation.method_imp.call(this, self, SEL_forwardingTargetForSelector_, _cmd);

        if (target && target !== self)
        {
            arguments[0] = target;

            return objj_msgSend.apply(this, arguments);
        }
    }

    implementation = isa.method_dtable[SEL_methodSignatureForSelector_];

    if (implementation)
    {
        var forwardInvocationImplementation = isa.method_dtable[SEL_forwardInvocation_];

        if (forwardInvocationImplementation)
        {
            var signature = implementation.method_imp.call(this, self, SEL_methodSignatureForSelector_, _cmd);

            if (signature)
            {
                var invocationClass = objj_lookUpClass("CPInvocation");

                if (invocationClass)
                {
                    var invocation = objj_msgSend(invocationClass, SEL_invocationWithMethodSignature_, signature),
                        index = 0,
                        count = arguments.length;

                    for (; index < count; ++index)
                        objj_msgSend(invocation, SEL_setArgument_atIndex_, arguments[index], index);

                    forwardInvocationImplementation.method_imp.call(this, self, SEL_forwardInvocation_, invocation);

                    return objj_msgSend(invocation, SEL_returnValue);
                }
            }
        }
    }

    implementation = isa.method_dtable[SEL_doesNotRecognizeSelector_];

    if (implementation)
        return implementation.method_imp.call(this, self, SEL_doesNotRecognizeSelector_, _cmd);

    throw class_getName(isa) + " does not implement doesNotRecognizeSelector:. Did you forget a superclass for " + class_getName(isa) + "?";
};

// I think this forward:: may need to be a common method, instead of defined in CPObject.
#define CLASS_GET_METHOD_IMPLEMENTATION(aMethodImplementation, aClass, aSelector)\
    if (!ISINITIALIZED(aClass))\
        _class_initialize(aClass);\
    \
    var method = aClass.method_dtable[aSelector];\
    \
    aMethodImplementation = method ? method.method_imp : _objj_forward;

GLOBAL(class_getMethodImplementation) = function(/*Class*/ aClass, /*SEL*/ aSelector)
{
    CLASS_GET_METHOD_IMPLEMENTATION(var implementation, aClass, aSelector);

    return implementation;
}

// Adding Classes
var REGISTERED_CLASSES  = { };

GLOBAL(objj_allocateClassPair) = function(/*Class*/ superclass, /*String*/ aName)
{
    var classObject = new objj_class(aName),
        metaClassObject = new objj_class(aName),
        rootClassObject = classObject;

    // If we don't have a superclass, we are the root class.
    if (superclass)
    {
        rootClassObject = superclass;

        while (rootClassObject.superclass)
            rootClassObject = rootClassObject.superclass;

        // Give our current allocator all the instance variables of our super class' allocator.
        classObject.allocator.prototype = new superclass.allocator;

        // "Inherit" parent properties.
        classObject.ivar_dtable = classObject.ivar_store.prototype = new superclass.ivar_store;
        classObject.method_dtable = classObject.method_store.prototype = new superclass.method_store;

        metaClassObject.method_dtable = metaClassObject.method_store.prototype = new superclass.isa.method_store;

        // Set up the actual class hierarchy.
        classObject.super_class = superclass;
        metaClassObject.super_class = superclass.isa;
    }
    else
        classObject.allocator.prototype = new objj_object();

    classObject.isa = metaClassObject;
    classObject.name = aName;
    classObject.info = CLS_CLASS;
    classObject._UID = objj_generateObjectUID();

    metaClassObject.isa = rootClassObject.isa;
    metaClassObject.name = aName;
    metaClassObject.info = CLS_META;
    metaClassObject._UID = objj_generateObjectUID();

    return classObject;
}

var CONTEXT_BUNDLE = nil;

GLOBAL(objj_registerClassPair) = function(/*Class*/ aClass)
{
    global[aClass.name] = aClass;
    REGISTERED_CLASSES[aClass.name] = aClass;

    addClassToBundle(aClass, CONTEXT_BUNDLE);
}

GLOBAL(objj_resetRegisterClasses) = function()
{
    for (var key in REGISTERED_CLASSES)
        delete global[key];

    REGISTERED_CLASSES = {};

    resetBundle();
}

// Instantiating Classes

GLOBAL(class_createInstance) = function(/*Class*/ aClass)
{
    if (!aClass)
        throw new Error("*** Attempting to create object with Nil class.");

    var object = new aClass.allocator();

    object.isa = aClass;
    object._UID = objj_generateObjectUID();

    return object;
}

// Opera 9.5.1 has a bug where prototypes "inheret" members from instances when "with" is used.
// Given that the Opera team is so fond of bug-testing instead of version-testing, we'll go
// ahead and do that.

var prototype_bug = function() { }

prototype_bug.prototype.member = false;

with (new prototype_bug())
    member = true;

// If the bug exists, go down the slow path.
if (new prototype_bug().member)
{

var fast_class_createInstance = class_createInstance;

class_createInstance = function(/*Class*/ aClass)
{
    var object = fast_class_createInstance(aClass);

    if (object)
    {
        var theClass = object.isa,
            actualClass = theClass;

        while (theClass)
        {
            var ivars = theClass.ivar_list,
                count = ivars.length;

            while (count--)
                object[ivars[count].name] = NULL;

            theClass = theClass.super_class;
        }

        object.isa = actualClass;
    }

    return object;
}

}

// Working with Instances

GLOBAL(object_getClassName) = function(/*id*/ anObject)
{
    if (!anObject)
        return "";

    var theClass = anObject.isa;

    return theClass ? class_getName(theClass) : "";
}

//objc_getClassList
GLOBAL(objj_lookUpClass) = function(/*String*/ aName)
{
    var theClass = REGISTERED_CLASSES[aName];

    return theClass ? theClass : Nil;
}

GLOBAL(objj_getClass) = function(/*String*/ aName)
{
    var theClass = REGISTERED_CLASSES[aName];

    /*if (!theClass)
    {
        for (var key in REGISTERED_CLASSES)
        {
            print("regClass: " + key + ", regClass.isa: " + REGISTERED_CLASSES[key].isa);
        }
        print("");
    }*/

    if (!theClass)
    {
        // class handler callback???
    }

    return theClass ? theClass : Nil;
}

//objc_getRequiredClass
GLOBAL(objj_getMetaClass) = function(/*String*/ aName)
{
    var theClass = objj_getClass(aName);

    return GETMETA(theClass);
}

// Working with Instance Variables

GLOBAL(ivar_getName) = function(anIvar)
{
    return anIvar.name;
}

GLOBAL(ivar_getTypeEncoding) = function(anIvar)
{
    return anIvar.type;
}

// Sending Messages

#ifdef MAXIMUM_RECURSION_CHECKS
var __objj_msgSend__StackDepth = 0;
#endif

GLOBAL(objj_msgSend) = function(/*id*/ aReceiver, /*SEL*/ aSelector)
{
    if (aReceiver == nil)
        return nil;

    var isa = aReceiver.isa;

    CLASS_GET_METHOD_IMPLEMENTATION(var implementation, isa, aSelector);

#ifdef MAXIMUM_RECURSION_CHECKS
    if (__objj_msgSend__StackDepth++ > MAXIMUM_RECURSION_DEPTH)
        throw new Error("Maximum call stack depth exceeded.");

    try {
#endif

    switch(arguments.length)
    {
        case 2: return implementation(aReceiver, aSelector);
        case 3: return implementation(aReceiver, aSelector, arguments[2]);
        case 4: return implementation(aReceiver, aSelector, arguments[2], arguments[3]);
    }

    return implementation.apply(aReceiver, arguments);

#ifdef MAXIMUM_RECURSION_CHECKS
    } finally {
        __objj_msgSend__StackDepth--;
    }
#endif
}

GLOBAL(objj_msgSendSuper) = function(/*id*/ aSuper, /*SEL*/ aSelector)
{
    var super_class = aSuper.super_class;

    arguments[0] = aSuper.receiver;

    CLASS_GET_METHOD_IMPLEMENTATION(var implementation, super_class, aSelector);

    return implementation.apply(aSuper.receiver, arguments);
}

// Working with Methods

GLOBAL(method_getName) = function(/*Method*/ aMethod)
{
    return aMethod.name;
}

GLOBAL(method_getImplementation) = function(/*Method*/ aMethod)
{
    return aMethod.method_imp;
}

GLOBAL(method_setImplementation) = function(/*Method*/ aMethod, /*IMP*/ anImplementation)
{
    var oldImplementation = aMethod.method_imp;

    aMethod.method_imp = anImplementation;

    return oldImplementation;
}

GLOBAL(method_exchangeImplementations) = function(/*Method*/ lhs, /*Method*/ rhs)
{
    var lhs_imp = method_getImplementation(lhs),
        rhs_imp = method_getImplementation(rhs);

    method_setImplementation(lhs, rhs_imp);
    method_setImplementation(rhs, lhs_imp);
}

// Working with Selectors

GLOBAL(sel_getName) = function(aSelector)
{
    return aSelector ? aSelector : "<null selector>";
}

GLOBAL(sel_getUid) = function(/*String*/ aName)
{
    return aName;
}

GLOBAL(sel_isEqual) = function(/*SEL*/ lhs, /*SEL*/ rhs)
{
    return lhs === rhs;
}

GLOBAL(sel_registerName) = function(/*String*/ aName)
{
    return aName;
}

objj_class.prototype.toString = objj_object.prototype.toString = function()
{
    var isa = this.isa;

    if (class_getInstanceMethod(isa, SEL_description))
        return objj_msgSend(this, SEL_description);

    if (class_isMetaClass(isa))
        return this.name;

    return "[" + isa.name + " Object](-description not implemented)";
}

var SEL_description                     = sel_getUid("description"),
    SEL_forwardingTargetForSelector_    = sel_getUid("forwardingTargetForSelector:"),
    SEL_methodSignatureForSelector_     = sel_getUid("methodSignatureForSelector:"),
    SEL_forwardInvocation_              = sel_getUid("forwardInvocation:"),
    SEL_doesNotRecognizeSelector_       = sel_getUid("doesNotRecognizeSelector:"),
    SEL_invocationWithMethodSignature_  = sel_getUid("invocationWithMethodSignature:"),
    SEL_setTarget_                      = sel_getUid("setTarget:"),
    SEL_setSelector_                    = sel_getUid("setSelector:"),
    SEL_setArgument_atIndex_            = sel_getUid("setArgument:atIndex:"),
    SEL_returnValue                     = sel_getUid("returnValue");
