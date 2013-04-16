/*
 * CPObject.j
 * Foundation
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

/*!
    @class CPObject
    @ingroup foundation
    @brief The root class from which most classes are subclassed.

    CPObject is the root class for most Cappuccino classes. Like in Objective-C,
    you have to declare parent class explicitly in Objective-J, so your custom
    classes should almost always subclass CPObject or one of its children.

    CPObject provides facilities for class allocation and initialization,
    querying runtime about parent classes and available selectors, using KVC
    (key-value coding).

    When you subclass CPObject, most of the time you override one selector - init.
    It is called for default initialization of custom object. You must call
    parent class init in your overridden code:
    <pre>- (id)init
{
    self = [super init];
    if (self) {
        ... provide default initialization code for your object ...
    }
    return self;
}</pre>

    One more useful thing to override is description(). This selector
    is used to provide developer-readable information about object. description
    selector is often used with CPLog debugging:
    <pre>- (CPString)description
{
    return [CPString stringWithFormat:@"<SomeClass %d>", someValue];
}</pre>
    To get description value you can use %@ specifier everywhere where format
    specifiers are allowed:
    <pre>var inst = [[SomeClass alloc] initWithSomeValue:10];
CPLog(@"Got some class: %@", inst);
    would output:
    \c Got \c some \c class: \c <SomeClass \c 10>

    @todo document KVC usage.
*/

@class CPString
@class CPException

@global CPInvalidArgumentException

@implementation CPObject
{
    Class   isa;
}

+ (void)load
{
}

+ (void)initialize
{
//    CPLog("calling initialize "+self.name);
}

/*!
    Allocates a new instance of the receiver, and sends it an \c -init
    @return the new object
*/
+ (id)new
{
    return [[self alloc] init];
}

/*!
    Allocates a new instance of the receiving class
*/
+ (id)alloc
{
//    CPLog("calling alloc on " + self.name + ".");
    return class_createInstance(self);
}

+ (id)allocWithCoder:(CPCoder)aCoder
{
    return [self alloc];
}

/*!
    Initializes the receiver
    @return the initialized receiver
*/
- (id)init
{
    return self;
}

/*!
    Makes a deep copy of the receiver. The copy should be functionally equivalent to the receiver.
    @return the copy of the receiver
*/
- (id)copy
{
    return self;
}

/*!
    Creates a deep mutable copy of the receiver.
    @return the mutable copy of the receiver
*/
- (id)mutableCopy
{
    return [self copy];
}

/*!
    Not necessary to call in Objective-J. Only exists for code compatibility.
*/
- (void)dealloc
{
}

// Identifying classes
/*!
    Returns the Class object for this class definition.
*/
+ (Class)class
{
    return self;
}

/*!
    Returns the receiver's Class
*/
- (Class)class
{
    return isa;
}

/*!
    Returns the class object super class
*/
+ (Class)superclass
{
    return self.super_class;
}

/*!
    Returns \c YES if the receiving class is a subclass of \c aClass.
    @param aClass the class to test inheritance from
*/
+ (BOOL)isSubclassOfClass:(Class)aClass
{
    var theClass = self;

    for (; theClass; theClass = theClass.super_class)
        if (theClass === aClass)
            return YES;

    return NO;
}

/*!
    Returns \c YES if the receiver is a \c aClass type, or a subtype of it.
    @param aClass the class to test as the receiver's class or super class.
*/
- (BOOL)isKindOfClass:(Class)aClass
{
    return [isa isSubclassOfClass:aClass];
}

+ (BOOL)isKindOfClass:(Class)aClass
{
    return [self isSubclassOfClass:aClass];
}

/*!
    Returns \c YES if the receiver is of the \c aClass class type.
    @param aClass the class to test the receiver
*/
- (BOOL)isMemberOfClass:(Class)aClass
{
    return self.isa === aClass;
}

+ (BOOL)isMemberOfClass:(Class)aClass
{
    return self === aClass;
}

/*!
    Determines whether the receiver's root object is a proxy.
    @return \c YES if the root object is a proxy
*/
- (BOOL)isProxy
{
    return NO;
}

// Testing class functionality
/*!
    Test whether instances of this class respond to the provided selector.
    @param aSelector the selector for which to test the class
    @return \c YES if instances of the class respond to the selector
*/
+ (BOOL)instancesRespondToSelector:(SEL)aSelector
{
    return !!class_getInstanceMethod(self, aSelector);
}

/*!
    Tests whether the receiver responds to the provided selector.
    @param aSelector the selector for which to test the receiver
    @return \c YES if the receiver responds to the selector
*/
- (BOOL)respondsToSelector:(SEL)aSelector
{
    // isa is isa.isa in class case.
    return !!class_getInstanceMethod(isa, aSelector);
}

/*!
    Tests whether the receiver implements to the provided selector regardless of inheritance.
    @param aSelector the selector for which to test the receiver
    @return \c YES if the receiver implements the selector
*/
- (BOOL)implementsSelector:(SEL)aSelector
{
    var methods = class_copyMethodList(isa),
        count = methods.length;

    while (count--)
        if (method_getName(methods[count]) === aSelector)
            return YES;

    return NO;
}

// Obtaining method information

/*!
    Returns the implementation of the receiver's method for the provided selector.
    @param aSelector the selector for the method to return
    @return the method implementation ( a function )
*/
- (IMP)methodForSelector:(SEL)aSelector
{
    return class_getMethodImplementation(isa, aSelector);
}

/*!
    Returns the implementation of the receiving class' method for the provided selector.
    @param aSelector the selector for the class method to return
    @return the method implementation ( a function )
*/
+ (IMP)instanceMethodForSelector:(SEL)aSelector
{
    return class_getMethodImplementation(self, aSelector);
}

/*!
    Returns the method signature for the provided selector.
    @param aSelector the selector for which to find the method signature
    @return the selector's method signature
*/
- (CPMethodSignature)methodSignatureForSelector:(SEL)aSelector
{
    // FIXME: We need to implement method signatures.
    return nil;
}

// Describing objects
/*!
    Returns a human readable string describing the receiver
*/
- (CPString)description
{
    return "<" + class_getName(isa) + " 0x" + [CPString stringWithHash:[self UID]] + ">";
}

+ (CPString)description
{
    return class_getName(self.isa);
}

// Sending Messages
/*!
    Sends the specified message to the receiver.
    @param aSelector the message to send
    @return the return value of the message
*/
- (id)performSelector:(SEL)aSelector
{
    return objj_msgSend(self, aSelector);
}

/*!
    Sends the specified message to the receiver, with one argument.
    @param aSelector the message to send
    @param anObject the message argument
    @return the return value of the message
*/
- (id)performSelector:(SEL)aSelector withObject:(id)anObject
{
    return objj_msgSend(self, aSelector, anObject);
}

/*!
    Sends the specified message to the receiver, with two arguments.
    @param aSelector the message to send
    @param anObject the first message argument
    @param anotherObject the second message argument
    @return the return value of the message
*/
- (id)performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject
{
    return objj_msgSend(self, aSelector, anObject, anotherObject);
}

/*!
    Sends the specified message to the reciever, with any number of arguments.
    @param aSelector the message to send
    @param anObject... comma seperated objects to pass to the selector
    @return the return value of the message
*/
- (id)performSelector:(SEL)aSelector withObjects:(id)anObject, ...
{
    var params = [self, aSelector].concat(Array.prototype.slice.apply(arguments, [3]));
    return objj_msgSend.apply(this, params);
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return nil;
}

// Forwarding Messages
/*!
    Subclasses can override this method to forward message to
    other objects. Overwriting this method in conjunction with
    \c -methodSignatureForSelector: allows the receiver to
    forward messages for which it does not respond, to another object that does.
*/
- (void)forwardInvocation:(CPInvocation)anInvocation
{
    [self doesNotRecognizeSelector:[anInvocation selector]];
}

// Error Handling
/*!
    Called by the Objective-J runtime when an object can't respond to
    a message. It's not recommended to call this method directly, unless
    you need your class to not support a method that it has inherited from a super class.
*/
- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    [CPException raise:CPInvalidArgumentException reason:
        (class_isMetaClass(isa) ? "+" : "-") + " [" + [self className] + " " + aSelector + "] unrecognized selector sent to " +
        (class_isMetaClass(isa) ? "class " + class_getName(isa) : "instance 0x" + [CPString stringWithHash:[self UID]])];
}

// Archiving
/*!
    Subclasses override this method to possibly substitute
    the unarchived object with another. This would be
    useful if your program utilizes a
    <a href="http://en.wikipedia.org/wiki/Flyweight_pattern">flyweight pattern</a>.
    The method is called by CPCoder.
    @param aCoder the coder that contained the receiver's data
*/
- (id)awakeAfterUsingCoder:(CPCoder)aCoder
{
    return self;
}

/*!
    Can be overridden by subclasses to substitute a different class to represent the receiver for keyed archiving.
    @return the class to use. A \c nil means to ignore the method result.
*/
- (Class)classForKeyedArchiver
{
    return [self classForCoder];
}

/*!
    Can be overridden by subclasses to substitute a different class to represent the receiver during coding.
    @return the class to use for coding
*/
- (Class)classForCoder
{
    return [self class];
}

/*!
    Can be overridden by subclasses to substitute another object during archiving.
    @param anArchiver that archiver
    @return the object to archive
*/
- (id)replacementObjectForArchiver:(CPArchiver)anArchiver
{
    return [self replacementObjectForCoder:anArchiver];
}

/*!
    Can be overridden by subclasses to substitute another object during keyed archiving.
    @param anArchive the keyed archiver
    @return the object to archive
*/
- (id)replacementObjectForKeyedArchiver:(CPKeyedArchiver)anArchiver
{
    return [self replacementObjectForCoder:anArchiver];
}

/*!
    Can be overridden by subclasses to substitute another object during coding.
    @param aCoder the coder
    @return the object to code
*/
- (id)replacementObjectForCoder:(CPCoder)aCoder
{
    return self;
}

/*!
    Sets the class version number.
    @param the new version number for the class
*/
+ (void)setVersion:(int)aVersion
{
    class_setVersion(self, aVersion);
}

/*!
    Returns the class version number.
*/
+ (int)version
{
    return class_getVersion(self);
}

// Scripting (?)
/*!
    Returns the class name
*/
- (CPString)className
{
    // FIXME: Why doesn't this work in KVO???
    // return class_getName([self class]);
    return isa.name;
}

// Extras
/*!
    Does nothing.
    @return the receiver
*/
- (id)autorelease
{
    return self;
}

/*!
    Returns a hash for the object
*/
- (unsigned)hash
{
    return [self UID];
}

- (CPString)UID
{
    if (typeof self._UID === "undefined")
        self._UID = objj_generateObjectUID();

    return self._UID + "";
}

/*!
    Determines if \c anObject is functionally equivalent to the receiver.
    @return \c YES if \c anObject is functionally equivalent to the receiver.
*/
- (BOOL)isEqual:(id)anObject
{
    return self === anObject || [self UID] === [anObject UID];
}

/*!
    Does nothing.
    @return the receiver
*/
- (id)retain
{
    return self;
}

/*!
    Does nothing.
*/
- (void)release
{
}

/*!
    Returns the receiver.
*/
- (id)self
{
    return self;
}

/*!
    Returns the receiver's super class.
*/
- (Class)superclass
{
    return isa.super_class;
}

@end

function CPDescriptionOfObject(anObject)
{
    if (anObject === nil)
        return "nil";

    if (anObject === undefined)
        return "undefined";

    if (anObject.isa)
    {
        if ([anObject isKindOfClass:CPString])
            return '@"' + [anObject description] + '"';

        return [anObject description];
    }

    if (typeof(anObject) !== "object")
        return String(anObject);

    var properties = [],
        desc;

    for (var property in anObject)
        if (anObject.hasOwnProperty(property))
            properties.push(property);

    properties.sort();

    if (properties.length === 2 && anObject.hasOwnProperty("width") && anObject.hasOwnProperty("height"))
        desc = [CPString stringWithFormat:@"CGSize: (%f, %f)", anObject.width, anObject.height];
    else if (properties.length === 2 && anObject.hasOwnProperty("x") && anObject.hasOwnProperty("y"))
        desc = [CPString stringWithFormat:@"CGPoint: (%f, %f)", anObject.x, anObject.y];
    else if (properties.length === 2 && anObject.hasOwnProperty("origin") && anObject.hasOwnProperty("size"))
        desc = [CPString stringWithFormat:@"CGRect: (%f, %f), (%f, %f)", anObject.origin.x, anObject.origin.y, anObject.size.width, anObject.size.height];
    else if (properties.length === 4 && anObject.hasOwnProperty("top") && anObject.hasOwnProperty("right") && anObject.hasOwnProperty("bottom") && anObject.hasOwnProperty("left"))
        desc = [CPString stringWithFormat:@"CGInset: { top:%f, right:%f, bottom:%f, left:%f }", anObject.top, anObject.right, anObject.bottom, anObject.left];
    else
    {
        desc = "{";

        for (var i = 0; i < properties.length; ++i)
        {
            if (i === 0)
                desc += "\n";

            desc += "    " + properties[i] + ": " + CPDescriptionOfObject(anObject[properties[i]]).split("\n").join("\n    ");

            if (i < properties.length - 1)
                desc += ",\n";
            else
                desc += "\n";
        }

        desc += "}";
    }

    return desc;
}
