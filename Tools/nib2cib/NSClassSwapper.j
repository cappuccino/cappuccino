/*
 * NSClassSwapper.j
 * nib2cib
 *
 * Created by Francisco Tolmasky
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

@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>
@import <AppKit/_CPCibClassSwapper.j>

@class Nib2Cib

@global CP_NSMapClassName

var NSClassSwapperClassNames                = {},
    NSClassSwapperOriginalClassNames        = {};

var _CPCibClassSwapperClassNameKey          = @"_CPCibClassSwapperClassNameKey",
    _CPCibClassSwapperOriginalClassNameKey  = @"_CPCibClassSwapperOriginalClassNameKey";

@implementation NSClassSwapper : _CPCibClassSwapper
{
}

+ (id)swapperClassForClassName:(CPString)aClassName originalClassName:(CPString)anOriginalClassName
{
    var swapperClassName = "$NSClassSwapper_" + aClassName + "_" + anOriginalClassName,
        swapperClass = objj_lookUpClass(swapperClassName);

    if (!swapperClass)
    {
        // If this is a userland NS class, call its KVC methods directly
        var nsClass = nil;

        if ([[[Nib2Cib sharedNib2Cib] userNSClasses] containsObject:aClassName])
            nsClass = objj_lookUpClass("NS_" + aClassName);

        var originalClass = nsClass || objj_lookUpClass(anOriginalClassName);

        swapperClass = objj_allocateClassPair(originalClass, swapperClassName);

        objj_registerClassPair(swapperClass);

        /*
            When calling userland KVC methods, they should think that the class is
            the NS class (not the swapper class) so that they are in their userland space,
            not in AppKit space. For example, this ensures that bundleForClass:[self class] will work correctly.
            We can accomplish this safely by changing the class of self temporarily and sending directly
            to self instead of to super. This swizzle is safe because NSClassSwapper and _CPCibClassSwapper
            do not add any ivars.
        */

        class_addMethod(swapperClass, @selector(initWithCoder:), function(self, _cmd, aCoder)
        {
            if (nsClass)
            {
                // Switch to userland temporarily
                self.isa = nsClass;
                self = objj_msgSend(self, _cmd, aCoder);
                self.isa = swapperClass;
            }
            else
                self = objj_msgSendSuper({super_class:originalClass, receiver:self}, _cmd, aCoder);

            if (self)
            {
                var UID = [self UID];

                NSClassSwapperClassNames[UID] = aClassName;
                NSClassSwapperOriginalClassNames[UID] = anOriginalClassName;
            }

            return self;
        }, "");

        class_addMethod(swapperClass, @selector(classForKeyedArchiver), function(self, _cmd)
        {
            return [_CPCibClassSwapper class];
        }, "");

        class_addMethod(swapperClass, @selector(encodeWithCoder:), function(self, _cmd, aCoder)
        {
            if (nsClass)
            {
                // Switch to userland temporarily
                self.isa = nsClass;
                objj_msgSend(self, _cmd, aCoder);
                self.isa = swapperClass;
            }
            else
                objj_msgSendSuper({super_class:originalClass, receiver:self}, _cmd, aCoder);

            // If this is a custom NS class, lookup its archiver class so that
            // the correct class is swapped during unarchiving.
            if (nsClass)
            {
                var classForArchiver = objj_msgSend(nsClass, "classForKeyedArchiver");

                if (classForArchiver)
                    aClassName = [classForArchiver className];
            }

            [aCoder encodeObject:aClassName forKey:_CPCibClassSwapperClassNameKey];
            [aCoder encodeObject:CP_NSMapClassName(anOriginalClassName) forKey:_CPCibClassSwapperOriginalClassNameKey];
        }, "");
    }

    return swapperClass;
}

+ (id)allocWithCoder:(CPCoder)aCoder
{
    var className = [aCoder decodeObjectForKey:@"NSClassName"],
        originalClassName = [aCoder decodeObjectForKey:@"NSOriginalClassName"];

    return [[self swapperClassForClassName:className originalClassName:originalClassName] alloc];
}

@end
