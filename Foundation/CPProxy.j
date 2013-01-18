/*
 * CPProxy.j
 * Foundation
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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

@import "CPException.j"
@import "CPInvocation.j"
@import "CPObject.j"
@import "CPString.j"

@implementation CPProxy
{
    Class   isa;
}

+ (void)load
{
}

+ (void)initialize
{
}

+ (Class)class
{
    return self;
}

+ (id)alloc
{
    return class_createInstance(self);
}

+ (BOOL)respondsToSelector:(SEL)selector
{
    return !!class_getInstanceMethod(isa, aSelector);
}

- (CPMethodSignature)methodSignatureForSelector:(SEL)aSelector
{
    [CPException raise:CPInvalidArgumentException
                reason:@"-methodSignatureForSelector: called on abstract CPProxy class."];
}

- (void)forwardInvocation:(CPInvocation)anInvocation
{
    [CPException raise:CPInvalidArgumentException
                reason:@"-forwardInvocation: called on abstract CPProxy class."];
}

// FIXME: This should be moved to the runtime?
- (void)forward:(SEL)aSelector :(marg_list)args
{
    return [CPObject methodForSelector:_cmd](self, _cmd, aSelector, args);
}

- (unsigned)hash
{
    return [self UID];
}

- (unsigned)UID
{
    if (typeof self._UID === "undefined")
        self._UID = objj_generateObjectUID();

    return self._UID;
}

- (BOOL)isEqual:(id)anObject
{
   return self === anObject;
}

- (id)self
{
    return self;
}

- (Class)class
{
    return isa;
}

- (Class)superclass
{
    return class_getSuperclass(isa);
}

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

- (BOOL)isProxy
{
    return YES;
}

- (BOOL)isKindOfClass:(Class)aClass
{
    var signature = [self methodSignatureForSelector:_cmd],
        invocation = [CPInvocation invocationWithMethodSignature:signature];

   [self forwardInvocation:invocation];

   return [invocation returnValue];
}

- (BOOL)isMemberOfClass:(Class)aClass
{
    var signature = [self methodSignatureForSelector:_cmd],
        invocation = [CPInvocation invocationWithMethodSignature:signature];

   [self forwardInvocation:invocation];

   return [invocation returnValue];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    var signature = [self methodSignatureForSelector:_cmd],
        invocation = [CPInvocation invocationWithMethodSignature:signature];

   [self forwardInvocation:invocation];

   return [invocation returnValue];
}

- (CPString)description
{
    return "<" + class_getName(isa) + " 0x" + [CPString stringWithHash:[self UID]] + ">";
}

@end
