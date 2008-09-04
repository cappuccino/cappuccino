/*
 * runtime.js
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

function objj_ivar(/*String*/ aName, /*String*/ aType)
{
    this.name = aName;
    this.type = aType;
}

function objj_method(/*String*/ aName, /*IMP*/ anImplementation, /*String*/ types)
{
    this.name = aName;
    this.method_imp = anImplementation;
    this.types = types;
}

function objj_class()
{
    this.isa            = NULL;
    
    this.super_class    = NULL;
    this.sub_classes    = [];
    
    this.name           = NULL;
    this.info           = 0;
    this.ivars          = [];
    
    this.method_list    = [];
    this.method_hash    = {};
    
    this.method_store   = function() { };
    this.method_dtable  = this.method_store.prototype;
    
    this.allocator      = function() { };
    this.__address      = -1;
}

function objj_object()
{
    this.isa        = NULL;
    this.__address  = -1;
}

// Addressing Objects

var OBJECT_COUNT   = 0;

function _objj_generateObjectHash()
{
    return OBJECT_COUNT++;
}

#define _objj_generateObjectHash() (OBJECT_COUNT++)

// Working with Classes

function class_getName(/*Class*/ aClass)
{
    if (aClass == Nil)
        return "";
    
    return aClass.name;
}

function class_isMetaClass(/*Class*/ aClass)
{
    if (!aClass)
        return NO;
    
    return ISMETA(aClass);
}

function class_getSuperclass(/*Class*/ aClass)
{
    if (aClass == Nil)
        return Nil;
    
    return aClass.super_class;
}

function class_setSuperclass(/*Class*/ aClass, /*Class*/ aSuperClass)
{
    // FIXME: implement.
}

function class_isMetaClass(/*Class*/ aClass)
{
    return ISMETA(aClass);
}

function class_addIvar(/*Class*/ aClass, /*String*/ aName, /*String*/ aType)
{
    var thePrototype = aClass.allocator.prototype;
    
    if (typeof thePrototype[aName] != "undefined")
        return NO;
    
    aClass.ivars.push(new objj_ivar(aName, aType)); 
    thePrototype[aName] = NULL;
    
    return YES;
}

function class_addIvars(/*Class*/ aClass, /*Array*/ivars)
{
    var index = 0,
        count = ivars.length,
        thePrototype = aClass.allocator.prototype;
        
    for (; index < count; ++index)
    {
        var ivar = ivars[index],
            name = ivar.name;

        if (typeof thePrototype[name] == "undefined")
        {
            aClass.ivars.push(ivar); 
            thePrototype[name] = NULL;
        }
    }
}

function class_copyIvarList(/*Class*/ aClass)
{
    return aClass.ivars.slice(0);
}

//#define class_copyIvarList(aClass) (aClass.ivars.slice(0))

function class_addMethod(/*Class*/ aClass, /*SEL*/ aName, /*IMP*/ anImplementation, /*String*/types)
{
    if (aClass.method_hash[aName])
        return NO;
    
    var method = new objj_method(aName, anImplementation, aType);
    
    aClass.method_list.push(method); 
    aClass.method_dtable[aName] = method;
    
    // FIXME: Should this be done here?
    // If this is a root class...
    if (!ISMETA(aClass) && GETMETA(aClass).isa == GETMETA(aClass))
        class_addMethods(GETMETA(aClass), methods);
    
    return YES;
}

function class_addMethods(/*Class*/ aClass, /*Array*/ methods)
{
    var index = 0,
        count = methods.length,
        
        method_list = aClass.method_list,
        method_dtable = aClass.method_dtable;
    
    for (; index < count; ++index)
    {
        var method = methods[index];
        
        if (aClass.method_hash[method.name])
            continue;
        
        method_list.push(method); 
        method_dtable[method.name] = method;
    }

    // If this is a root class...
    if (!ISMETA(aClass) && GETMETA(aClass).isa == GETMETA(aClass))
        class_addMethods(GETMETA(aClass), methods);
}

function class_getInstanceMethod(/*Class*/ aClass, /*SEL*/ aSelector)
{
    if (!aClass || !aSelector)
        return NULL;
    
    var method = aClass.method_dtable[aSelector];
    
    return method ? method : NULL;
}

function class_getClassMethod(/*Class*/ aClass, /*SEL*/ aSelector)
{
    if (!aClass || !aSelector)
        return NULL;

    var method = GETMETA(aClass).method_dtable[aSelector];
    
    return method ? method : NULL;
}

function class_copyMethodList(/*Class*/ aClass)
{
    return aClass.method_list.slice(0);
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

var _objj_forward = new objj_method("forward", function(self, _cmd)
{
    return objj_msgSend(self, "forward::", _cmd, arguments);
});

// I think this forward:: may need to be a common method, instead of defined in CPObject.
#define CLASS_GET_METHOD_IMPLEMENTATION(aMethodImplementation, aClass, aSelector)\
    if (!ISINITIALIZED(aClass))\
        _class_initialize(aClass);\
    \
    var method = aClass.method_dtable[aSelector];\
    \
    if (!method)\
        method = _objj_forward;\
    \
    aMethodImplementation = method.method_imp;

function class_getMethodImplementation(/*Class*/ aClass, /*SEL*/ aSelector)
{
    CLASS_GET_METHOD_IMPLEMENTATION(var implementation, aClass, aSelector);
    
    return implementation;
}

// Adding Classes

var GLOBAL_NAMESPACE    = this,
    REGISTERED_CLASSES  = {};

function objj_allocateClassPair(/*Class*/ superclass, /*String*/ aName)
{
    var classObject = new objj_class(),
        metaClassObject = new objj_class(),
        rootClassObject = classObject;
    
    // If we don't have a superclass, we are the root class.
    if (superclass)
    {
        rootClassObject = superclass;
        
        while (rootClassObject.superclass)
            rootClassObject = rootClassObject.superclass;
        
        // Give our current allocator all the instance variables of our super class' allocator.
        classObject.allocator.prototype = new superclass.allocator;
        
        // "Inheret" parent methods.
        classObject.method_store.prototype = new superclass.method_store;
        classObject.method_dtable = classObject.method_store.prototype;
        
        metaClassObject.method_store.prototype = new superclass.isa.method_store;
        metaClassObject.method_dtable = metaClassObject.method_store.prototype;
        
        // Set up the actual class hierarchy.
        classObject.super_class = superclass;
        metaClassObject.super_class = superclass.isa;
    }
    else
        classObject.allocator.prototype = new objj_object();
    
    classObject.isa = metaClassObject;
    classObject.name = aName;
    classObject.info = CLS_CLASS;
    classObject.__address = _objj_generateObjectHash();
    
    metaClassObject.isa = rootClassObject.isa;
    metaClassObject.name = aName;
    metaClassObject.info = CLS_META;
    metaClassObject.__address = _objj_generateObjectHash();
    
    return classObject;
}

function objj_registerClassPair(/*Class*/ aClass)
{
    GLOBAL_NAMESPACE[aClass.name] = aClass;
    REGISTERED_CLASSES[aClass.name] = aClass;
}

// Instantiating Classes

function class_createInstance(/*Class*/ aClass)
{
    if (!aClass)
        objj_exception_throw(new objj_exception(OBJJNilClassException, "*** Attempting to create object with Nil class."));

    var object = new aClass.allocator;

    object.__address = _objj_generateObjectHash();
    object.isa = aClass;

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
            var ivars = theClass.ivars;
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

function object_getClassName(/*id*/ anObject)
{
    if (!anObject)
        return "";

    var theClass = anObject.isa;

    return theClass ? class_getName(theClass) : "";
}

//objc_getClassList  
function objj_lookUpClass(/*String*/ aName)
{
    var theClass = REGISTERED_CLASSES[aName];
    
    return theClass ? theClass : Nil;
}

function objj_getClass(/*String*/ aName)
{
    var theClass = REGISTERED_CLASSES[aName];
    
    if (!theClass)
    {
        // class handler callback???
    }
    
    return theClass ? theClass : Nil;
}

//objc_getRequiredClass  
function objj_getMetaClass(/*String*/ aName)
{
    var theClass = objj_getClass(aName);
    
    return GETMETA(theClass);
}

// Working with Instance Variables

function ivar_getName(anIvar)
{
    return anIvar.name;
}

function ivar_getTypeEncoding(anIvar)
{
    return anIvar.type;
}

// Sending Messages

function objj_msgSend(/*id*/ aReceiver, /*SEL*/ aSelector)
{
    if (aReceiver == nil)
        return nil;

#if DEBUG
    objj_debug_backtrace.push("[" + GETMETA(aReceiver).name + " " + aSelector + "]");
    
    try
    {
        var result = class_getMethodImplementation(aReceiver.isa, aSelector).apply(aReceiver, arguments);
    }
    catch (anException)
    {
        CPLog.error("Exception " + anException + " in [" + GETMETA(aReceiver).name + " " + aSelector + "]");
        objj_debug_print_backtrace();
    }
    
    objj_debug_backtrace.pop();
    
    return result;
#else
    CLASS_GET_METHOD_IMPLEMENTATION(var implementation, aReceiver.isa, aSelector);
    
    return implementation.apply(aReceiver, arguments);
#endif
}

function objj_msgSendSuper(/*id*/ aSuper, /*SEL*/ aSelector)
{
#if DEBUG
    objj_debug_backtrace.push("[" + GETMETA(aSuper.receiver).name + " " + aSelector + "]");
#endif
    var super_class = aSuper.super_class;
    
    arguments[0] = aSuper.receiver;
    
#if !DEBUG
    CLASS_GET_METHOD_IMPLEMENTATION(var implementation, super_class, aSelector);
    
    return implementation.apply(aSuper.receiver, arguments);
#else
    try
    {
        var result = class_getMethodImplementation(super_class, aSelector).apply(aSuper.receiver, arguments);
    }
    catch (anException)
    {
        CPLog.error("Exception " + anException + " in [" + GETMETA(aSuper.receiver).name + " " + aSelector + "]");
        objj_debug_print_backtrace();
    }
    
    objj_debug_backtrace.pop();
    
    return result;
#endif
}

#if DEBUG
// FIXME: This could be much better.
var objj_debug_backtrace = [];

function objj_debug_print_backtrace()
{
    CPLog.trace(objj_debug_backtrace_string());
}

function objj_debug_backtrace_string()
{
    var i = objj_debug_backtrace.length,
        backtrace = "";
        
    while (i--)
        backtrace += objj_debug_backtrace[i] + "\n";
        
    return backtrace;
}
#endif

// Working with Methods

function method_getName(/*Method*/ aMethod)
{
    return aMethod.name;
}

function method_getImplementation(/*Method*/ aMethod)
{
    return aMethod.method_imp;
}

function method_setImplementation(/*Method*/ aMethod, /*IMP*/ anImplementation)
{
    var oldImplementation = aMethod.method_imp;
    
    aMethod.method_imp = anImplementation;
    
    return oldImplementation;
}

function method_exchangeImplementations(/*Method*/ lhs, /*Method*/ rhs)
{
    var lhs_imp = method_getImplementation(lhs),
        rhs_imp = method_getImplementation(rhs);

    method_setImplementation(lhs, rhs_imp);
    method_setImplementation(rhs, lhs_imp);
}

// Working with Selectors

function sel_getName(aSelector)
{
    return aSelector ? aSelector : "<null selector>";
}

function sel_getUid(/*String*/ aName)
{
    return aName;
}

function sel_isEqual(/*SEL*/ lhs, /*SEL*/ rhs)
{
    return lhs == rhs;
}

function sel_registerName(aName)
{
    return aName;
}
