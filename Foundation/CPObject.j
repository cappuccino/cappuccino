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

+ (id)new
{
    return [[self alloc] init];
}

+ (id)alloc
{
//    CPLog("calling alloc on " + self.name + ".");
    return class_createInstance(self);
}

- (id)init
{
    return self;
}

- (id)copy
{
    return self;
}

- (id)mutableCopy
{
    return [self copy];
}

- (void)dealloc
{
}

// Identifying classes

+ (Class)class
{
    return self;
}

- (Class)class
{
    return isa;
}

+ (Class)superclass
{
    return super_class;
}

+ (BOOL)isSubclassOfClass:(Class)aClass
{
    var theClass = self;
    
    for(; theClass; theClass = theClass.super_class)
        if(theClass == aClass) return YES;
    
    return NO;
}

- (BOOL)isKindOfClass:(Class)aClass
{
    return [isa isSubclassOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass
{
    return self.isa == aClass;
}

- (BOOL)isProxy
{
    return NO;
}

// Testing class functionality

+ (BOOL)instancesRespondToSelector:(SEL)aSelector
{
    return class_getInstanceMethod(self, aSelector);
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return class_getInstanceMethod(isa, aSelector) != NULL;
}

// Obtaining method information

- (IMP)methodForSelector:(SEL)aSelector
{
    return class_getInstanceMethod(isa, aSelector);
}

+ (IMP)instanceMethodForSelector:(SEL)aSelector
{
    return class_getInstanceMethod(isa, aSelector);
}

- (CPMethodSignature)methodSignatureForSelector:(SEL)aSelector
{
    // FIXME: We need to implement method signatures.
    return nil;
}

// Describing objects

- (CPString)description
{
    return "<" + isa.name + " 0x" + [CPString stringWithHash:[self hash]] + ">";
}

// Sending Messages

- (id)performSelector:(SEL)aSelector
{
    return objj_msgSend(self, aSelector);
}

- (id)performSelector:(SEL)aSelector withObject:(id)anObject
{
    return objj_msgSend(self, aSelector, anObject);
}

- (id)performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject
{
    return objj_msgSend(self, aSelector, anObject, anotherObject);
}

// Forwarding Messages

- (void)forwardInvocation:(CPInvocation)anInvocation
{
    [self doesNotRecognizeSelector:[anInvocation selector]];
}

- (void)forward:(SEL)aSelector :(marg_list)args
{
    var signature = [self methodSignatureForSelector:_cmd];
    
    if (signature)
    {
        invocation = [CPInvocation invocationWithMethodSignature:signature];
        
        [invocation setTarget:self];
        [invocation setSelector:aSelector];
        
        var index = 2,
            count = args.length;
            
        for (; index < count; ++index)
            [invocation setArgument:args[index] atIndex:index];
        
        [self forwardInvocation:invocation];
        
        return [invocation returnValue];
    }
    
    [self doesNotRecognizeSelector:aSelector];
}

// Error Handling

- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    [CPException raise:CPInvalidArgumentException reason:
        (class_isMetaClass(isa) ? "+" : "-") + " [" + [self className] + " " + aSelector + "] unrecognized selector sent to " +
        (class_isMetaClass(isa) ? "class" : "instance") + " 0x" + [CPString stringWithHash:[self hash]]];
}

// Archiving

- (void)awakeAfterUsingCoder:(CPCoder)aCoder
{
    return self;
}

- (Class)classForKeyedArchiver
{
    return [self classForCoder];
}

- (Class)classForCoder
{
    return [self class];
}

- (id)replacementObjectForArchiver:(CPArchiver)anArchiver
{
    return [self replacementObjectForCoder:anArchiver];
}

- (id)replacementObjectForKeyedArchiver:(CPKeyedArchiver)anArchiver
{
    return [self replacementObjectForCoder:anArchiver];
}

- (id)replacementObjectForCoder:(CPCoder)aCoder
{
    return self;
}

+ (id)setVersion:(int)aVersion
{
    version = aVersion;
    
    return self;
}

+ (int)version
{
    return version;
}

// Scripting (?)

- (CPString)className
{
    return isa.name;
}

// Extras

- (id)autorelease
{
    return self;
}

- (unsigned)hash
{
    return __address;
}

- (BOOL)isEqual:(id)anObject
{
    return self === anObject;
}

- (void)retain
{
    return self;
}

- (void)release
{
}

- (id)self
{
    return self;
}

- (Class)superclass
{
    return isa.super_class;
}

@end
