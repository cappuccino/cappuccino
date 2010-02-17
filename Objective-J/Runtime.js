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
    // Set up the actual class hierarchy.
    aClass.super_class = aSuperClass;
    aClass.isa.super_class = aSuperClass.isa;
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

        if (typeof thePrototype[name] === "undefined")
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

#define METHOD_DISPLAY_NAME(aClass, aMethod) (ISMETA(aClass) ? '+' : '-') + " [" + class_getName(aClass) + ' ' + method_getName(aMethod) + ']'

function class_addMethod(/*Class*/ aClass, /*SEL*/ aName, /*IMP*/ anImplementation, /*Array<String>*/ types)
{
    if (aClass.method_hash[aName])
        return NO;
    
    var method = new objj_method(aName, anImplementation, types);
    
    aClass.method_list.push(method); 
    aClass.method_dtable[aName] = method;

    // Give this function a "pretty" name for the console.
    method.method_imp.displayName = METHOD_DISPLAY_NAME(aClass, method);

    // FIXME: Should this be done here?
    // If this is a root class...
    if (!ISMETA(aClass) && GETMETA(aClass).isa === GETMETA(aClass))
        class_addMethod(GETMETA(aClass), aName, anImplementation, types);

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

        // Give this function a "pretty" name for the console.
        method.method_imp.displayName = METHOD_DISPLAY_NAME(aClass, method);
    }

    // If this is a root class...
    if (!ISMETA(aClass) && GETMETA(aClass).isa === GETMETA(aClass))
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

function class_replaceMethod(/*Class*/ aClass, /*SEL*/ aSelector, /*IMP*/ aMethodImplementation)
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

// Private: Don't exports.
function _class_initialize(/*Class*/ aClass)
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
var GLOBAL_NAMESPACE    = GLOBAL_NAMESPACE || global,
    REGISTERED_CLASSES  = { };

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
    classObject.__address = generateObjectUID();
    
    metaClassObject.isa = rootClassObject.isa;
    metaClassObject.name = aName;
    metaClassObject.info = CLS_META;
    metaClassObject.__address = generateObjectUID();
    
    return classObject;
}

var CONTEXT_BUNDLE = nil;

function objj_registerClassPair(/*Class*/ aClass)
{
    GLOBAL_NAMESPACE[aClass.name] = aClass;
    REGISTERED_CLASSES[aClass.name] = aClass;

    addClassToBundle(aClass, CONTEXT_BUNDLE);
}

// Instantiating Classes

function class_createInstance(/*Class*/ aClass)
{
    if (!aClass)
        objj_exception_throw(new objj_exception(OBJJNilClassException, "*** Attempting to create object with Nil class."));

    var object = new aClass.allocator;

    object.__address = generateObjectUID();
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
        
    CLASS_GET_METHOD_IMPLEMENTATION(var implementation, aReceiver.isa, aSelector);

    switch(arguments.length)
    {
        case 2: return implementation(aReceiver, aSelector);
        case 3: return implementation(aReceiver, aSelector, arguments[2]);
        case 4: return implementation(aReceiver, aSelector, arguments[2], arguments[3]);
    }

    return implementation.apply(aReceiver, arguments);
}

function objj_msgSendSuper(/*id*/ aSuper, /*SEL*/ aSelector)
{
    var super_class = aSuper.super_class;

    arguments[0] = aSuper.receiver;

    CLASS_GET_METHOD_IMPLEMENTATION(var implementation, super_class, aSelector);

    return implementation.apply(aSuper.receiver, arguments);
}

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
    return lhs === rhs;
}

function sel_registerName(aName)
{
    return aName;
}

var fastEnumerationSelector = sel_getUid("countByEnumeratingWithState:objects:count:");

function objj_fastEnumerator(/*Object*/ anObject, /*Integer*/ anAssigneeCount)
{
    // If this object doesn't respond to countByEnumeratingWithState:objects:count:
    // (which is obviously the case for non-Objective-J objects), then just iterate
    // this one object.
    if (anObject && (!anObject.isa || !class_getInstanceMethod(anObject.isa, fastEnumerationSelector)))
        this._target = [anObject];

    // Else, use it's implementation.
    else
        this._target = anObject;

    this._state = { state:0, assigneeCount:anAssigneeCount };
    this._index = 0;

    // Nothing to iterate in this case.
    if (!anObject)
    {
        this.i = 0;
        this.l = 0;
    }
    else
        this.e();
}

objj_fastEnumerator.prototype.e = function()
{
    var object = this._target;

    // Nothing to iterate, don't iterate
    if (!object)
        return NO;

    var state = this._state,
        index = state.assigneeCount;

    while (index--)
        state["items" + index] = nil;

    this.i = 0;

    // We optimize the array case.
    if (CPArray && object.isa === CPArray)
    {
        if (this.l)
            return NO;

        this.o0 = object;
        this.l = object.length;
    }

    else
    {
        // Clear out all the old state.
        state.items = nil;
        state.itemsPtr = nil;

        this.o0 = [];
        this.l = objj_msgSend(object, fastEnumerationSelector, state, this.o0, 16);

        // We're flexible on this.
        this.o0 = state.items || state.itemsPtr || state.items0 || this.o0;

        // We allow the user to not explictly return anything in countByEnumeratingWithState:objects:count:
        if (this.l === undefined)
            this.l = this.o0.length;
    }

    var assigneeCount = state.assigneeCount;

    index = assigneeCount - 1;

    // Handle all items from [1 .. assigneeCount - 1]
    while (index-- > 1)
        this["o" + index] = state["items" + index] || [];

    var lastAssigneeIndex = assigneeCount - 1;

    // Autogenerate the indexes if this was left blank.
    if (lastAssigneeIndex > 0)

        if (state["items" + lastAssigneeIndex])
            this["o" + lastAssigneeIndex] = state["items" + lastAssigneeIndex];

        else
        {
            var count = this.l,
                indexIndex = 0,
                indexes = new Array(count)

            for (; indexIndex < count; ++indexIndex, ++this._index)
                indexes[indexIndex] = this._index;

            this["o" + lastAssigneeIndex] = indexes;
        }

    // If this is the last iteration, set target to nil so that we don't call the
    // fast enumeration method again.
    return this.l > 0;
}

// Exports and Globals

exports.objj_ivar = objj_ivar;
exports.objj_method = objj_method;

exports.objj_class = objj_class;
exports.objj_object = objj_object;

exports.class_getName = class_getName;
exports.class_getSuperclass = class_getSuperclass;
exports.class_setSuperclass = class_setSuperclass;
exports.class_isMetaClass = class_isMetaClass;

exports.class_addIvar = class_addIvar;
exports.class_addIvars = class_addIvars;
exports.class_copyIvarList = class_copyIvarList;

exports.class_addMethod = class_addMethod;
exports.class_addMethods = class_addMethods;
exports.class_getInstanceMethod = class_getInstanceMethod;

exports.class_getClassMethod = class_getClassMethod;
exports.class_copyMethodList = class_copyMethodList;

exports.class_replaceMethod = class_replaceMethod;
exports.class_getMethodImplementation = class_getMethodImplementation;

exports.objj_allocateClassPair = objj_allocateClassPair;
exports.objj_registerClassPair = objj_registerClassPair;
exports.class_createInstance = class_createInstance;

exports.object_getClassName = object_getClassName;
exports.objj_lookUpClass = objj_lookUpClass;
exports.objj_getClass = objj_getClass;
exports.objj_getMetaClass = objj_getMetaClass;

exports.ivar_getName = ivar_getName;
exports.ivar_getTypeEncoding = ivar_getTypeEncoding;

exports.objj_msgSend = objj_msgSend;
exports.objj_msgSendSuper = objj_msgSendSuper;

exports.method_getName = method_getName;
exports.method_getImplementation = method_getImplementation;
exports.method_setImplementation = method_setImplementation;
exports.method_exchangeImplementations = method_exchangeImplementations;

exports.sel_getName = sel_getName;
exports.sel_getUid = sel_getUid;
exports.sel_isEqual = sel_isEqual;
exports.sel_registerName = sel_registerName;

exports.objj_fastEnumerator = objj_fastEnumerator;

exports.objj_generateObjectUID = generateObjectUID;
exports._objj_generateObjectHash = generateObjectUID;
