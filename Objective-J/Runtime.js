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

GLOBAL(objj_ivar) = function(/*String*/ aName, /*String*/ aType)
{
    this.name = aName;
    this.type = aType;
}

DISPLAY_NAME(objj_ivar);

GLOBAL(objj_method) = function(/*String*/ aName, /*IMP*/ anImplementation, /*String*/ types)
{
    this.name = aName;
    this.method_imp = anImplementation;
    this.types = types;
}

DISPLAY_NAME(objj_method);

GLOBAL(objj_class) = function()
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
    this._UID           = -1;
}

DISPLAY_NAME(objj_class);

GLOBAL(objj_object) = function()
{
    this.isa    = NULL;
    this._UID   = -1;
}

DISPLAY_NAME(objj_object);

// Working with Classes

GLOBAL(class_getName) = function(/*Class*/ aClass)
{
    if (aClass == Nil)
        return "";
    
    return aClass.name;
}

DISPLAY_NAME(class_getName);

GLOBAL(class_isMetaClass) = function(/*Class*/ aClass)
{
    if (!aClass)
        return NO;
    
    return ISMETA(aClass);
}

DISPLAY_NAME(class_isMetaClass);

GLOBAL(class_getSuperclass) = function(/*Class*/ aClass)
{
    if (aClass == Nil)
        return Nil;
    
    return aClass.super_class;
}

DISPLAY_NAME(class_getSuperclass)

GLOBAL(class_setSuperclass) = function(/*Class*/ aClass, /*Class*/ aSuperClass)
{
    // Set up the actual class hierarchy.
    aClass.super_class = aSuperClass;
    aClass.isa.super_class = aSuperClass.isa;
}

DISPLAY_NAME(class_setSuperclass);

GLOBAL(class_addIvar) = function(/*Class*/ aClass, /*String*/ aName, /*String*/ aType)
{
    var thePrototype = aClass.allocator.prototype;
    
    if (typeof thePrototype[aName] != "undefined")
        return NO;
    
    aClass.ivars.push(new objj_ivar(aName, aType)); 
    thePrototype[aName] = NULL;
    
    return YES;
}

DISPLAY_NAME(class_addIvar);

GLOBAL(class_addIvars) = function(/*Class*/ aClass, /*Array*/ivars)
{
    var index = 0,
        count = ivars.length,
        thePrototype = aClass.allocator.prototype;
        
    for (; index < count; ++index)
    {
        var ivar = ivars[index],
            name = ivar.name;

        if (typeof thePrototype[name] === "undefined")
        {
            aClass.ivars.push(ivar); 
            thePrototype[name] = NULL;
        }
    }
}

DISPLAY_NAME(class_addIvars);

GLOBAL(class_copyIvarList) = function(/*Class*/ aClass)
{
    return aClass.ivars.slice(0);
}

DISPLAY_NAME(class_copyIvarList);

//#define class_copyIvarList(aClass) (aClass.ivars.slice(0))

#define METHOD_DISPLAY_NAME(aClass, aMethod) (ISMETA(aClass) ? '+' : '-') + " [" + class_getName(aClass) + ' ' + method_getName(aMethod) + ']'

GLOBAL(class_addMethod) = function(/*Class*/ aClass, /*SEL*/ aName, /*IMP*/ anImplementation, /*Array<String>*/ types)
{
    if (aClass.method_hash[aName])
        return NO;
    
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

DISPLAY_NAME(class_addMethod);

GLOBAL(class_addMethods) = function(/*Class*/ aClass, /*Array*/ methods)
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

#if DEBUG
        // Give this function a "pretty" name for the console.
        method.method_imp.displayName = METHOD_DISPLAY_NAME(aClass, method);
#endif
    }

    // If this is a root class...
    if (!ISMETA(aClass) && GETMETA(aClass).isa === GETMETA(aClass))
        class_addMethods(GETMETA(aClass), methods);
}

DISPLAY_NAME(class_addMethods);

GLOBAL(class_getInstanceMethod) = function(/*Class*/ aClass, /*SEL*/ aSelector)
{
    if (!aClass || !aSelector)
        return NULL;
    
    var method = aClass.method_dtable[aSelector];
    
    return method ? method : NULL;
}

DISPLAY_NAME(class_getInstanceMethod);

GLOBAL(class_getClassMethod) = function(/*Class*/ aClass, /*SEL*/ aSelector)
{
    if (!aClass || !aSelector)
        return NULL;

    var method = GETMETA(aClass).method_dtable[aSelector];
    
    return method ? method : NULL;
}

DISPLAY_NAME(class_getClassMethod);

GLOBAL(class_copyMethodList) = function(/*Class*/ aClass)
{
    return aClass.method_list.slice(0);
}

DISPLAY_NAME(class_copyMethodList);

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

DISPLAY_NAME(class_replaceMethod);

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

GLOBAL(class_getMethodImplementation) = function(/*Class*/ aClass, /*SEL*/ aSelector)
{
    CLASS_GET_METHOD_IMPLEMENTATION(var implementation, aClass, aSelector);
    
    return implementation;
}

DISPLAY_NAME(class_getMethodImplementation);

// Adding Classes
var REGISTERED_CLASSES  = { };

GLOBAL(objj_allocateClassPair) = function(/*Class*/ superclass, /*String*/ aName)
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
    classObject._UID = objj_generateObjectUID();

    metaClassObject.isa = rootClassObject.isa;
    metaClassObject.name = aName;
    metaClassObject.info = CLS_META;
    metaClassObject._UID = objj_generateObjectUID();

    return classObject;
}

DISPLAY_NAME(objj_allocateClassPair);

var CONTEXT_BUNDLE = nil;

GLOBAL(objj_registerClassPair) = function(/*Class*/ aClass)
{
    global[aClass.name] = aClass;
    REGISTERED_CLASSES[aClass.name] = aClass;

    addClassToBundle(aClass, CONTEXT_BUNDLE);
}

DISPLAY_NAME(objj_registerClassPair);

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

DISPLAY_NAME(class_createInstance);

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

GLOBAL(object_getClassName) = function(/*id*/ anObject)
{
    if (!anObject)
        return "";

    var theClass = anObject.isa;

    return theClass ? class_getName(theClass) : "";
}

DISPLAY_NAME(object_getClassName);

//objc_getClassList  
GLOBAL(objj_lookUpClass) = function(/*String*/ aName)
{
    var theClass = REGISTERED_CLASSES[aName];
    
    return theClass ? theClass : Nil;
}

DISPLAY_NAME(objj_lookUpClass);

GLOBAL(objj_getClass) = function(/*String*/ aName)
{
    var theClass = REGISTERED_CLASSES[aName];
    
    if (!theClass)
    {
        // class handler callback???
    }
    
    return theClass ? theClass : Nil;
}

DISPLAY_NAME(objj_getClass);

//objc_getRequiredClass  
GLOBAL(objj_getMetaClass) = function(/*String*/ aName)
{
    var theClass = objj_getClass(aName);
    
    return GETMETA(theClass);
}

DISPLAY_NAME(objj_getMetaClass);

// Working with Instance Variables

GLOBAL(ivar_getName) = function(anIvar)
{
    return anIvar.name;
}

DISPLAY_NAME(ivar_getName);

GLOBAL(ivar_getTypeEncoding) = function(anIvar)
{
    return anIvar.type;
}

DISPLAY_NAME(ivar_getTypeEncoding);

// Sending Messages

GLOBAL(objj_msgSend) = function(/*id*/ aReceiver, /*SEL*/ aSelector)
{
    if (aReceiver == nil)
        return nil;

    var isa = aReceiver.isa;

    CLASS_GET_METHOD_IMPLEMENTATION(var implementation, isa, aSelector);

    switch(arguments.length)
    {
        case 2: return implementation(aReceiver, aSelector);
        case 3: return implementation(aReceiver, aSelector, arguments[2]);
        case 4: return implementation(aReceiver, aSelector, arguments[2], arguments[3]);
    }

    return implementation.apply(aReceiver, arguments);
}

DISPLAY_NAME(objj_msgSend);

GLOBAL(objj_msgSendSuper) = function(/*id*/ aSuper, /*SEL*/ aSelector)
{
    var super_class = aSuper.super_class;

    arguments[0] = aSuper.receiver;

    CLASS_GET_METHOD_IMPLEMENTATION(var implementation, super_class, aSelector);

    return implementation.apply(aSuper.receiver, arguments);
}

DISPLAY_NAME(objj_msgSendSuper);

// Working with Methods

GLOBAL(method_getName) = function(/*Method*/ aMethod)
{
    return aMethod.name;
}

DISPLAY_NAME(method_getName);

GLOBAL(method_getImplementation) = function(/*Method*/ aMethod)
{
    return aMethod.method_imp;
}

DISPLAY_NAME(method_getImplementation);

GLOBAL(method_setImplementation) = function(/*Method*/ aMethod, /*IMP*/ anImplementation)
{
    var oldImplementation = aMethod.method_imp;
    
    aMethod.method_imp = anImplementation;
    
    return oldImplementation;
}

DISPLAY_NAME(method_setImplementation);

GLOBAL(method_exchangeImplementations) = function(/*Method*/ lhs, /*Method*/ rhs)
{
    var lhs_imp = method_getImplementation(lhs),
        rhs_imp = method_getImplementation(rhs);

    method_setImplementation(lhs, rhs_imp);
    method_setImplementation(rhs, lhs_imp);
}

DISPLAY_NAME(method_exchangeImplementations);

// Working with Selectors

GLOBAL(sel_getName) = function(aSelector)
{
    return aSelector ? aSelector : "<null selector>";
}

DISPLAY_NAME(sel_getName);

GLOBAL(sel_getUid) = function(/*String*/ aName)
{
    return aName;
}

DISPLAY_NAME(sel_getUid);

GLOBAL(sel_isEqual) = function(/*SEL*/ lhs, /*SEL*/ rhs)
{
    return lhs === rhs;
}

DISPLAY_NAME(sel_isEqual);

GLOBAL(sel_registerName) = function(/*String*/ aName)
{
    return aName;
}

DISPLAY_NAME(sel_registerName);
