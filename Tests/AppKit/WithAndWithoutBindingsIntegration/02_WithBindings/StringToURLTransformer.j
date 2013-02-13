/*
 * StringToURLTransformer.j
 * AppKit Tests
 *
 * Created by Alexander Ljungberg.
 * Copyright 2010, WireLoad, LLC.
 *
 * Adapted from StringToURLTransformer.m in WithAndWithoutBindings by Apple Inc.
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

@import <Foundation/CPURL.j>
@import <Foundation/CPValueTransformer.j>

@implementation StringToURLTransformer : CPValueTransformer

+ (void)initialize
{
    if (self !== [StringToURLTransformer class])
        return;

    [CPValueTransformer setValueTransformer:[self new]
                                    forName:@"StringToURLTransformer"];
}

+ (Class)transformedValueClass
{
    return [CPString class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    return (value && ![value isEqual:[CPNull null]]) ? [value absoluteString] : nil;
}

- (id)reverseTransformedValue:(id)value
{
    return (value && ![value isEqual:[CPNull null]]) ? [CPURL URLWithString:value] : nil;
}

@end
