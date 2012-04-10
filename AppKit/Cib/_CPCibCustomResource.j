/*
 * _CPCibCustomResource.j
 * AppKit
 *
 * Portions based on NSCustomResource.m (01/08/2009) in Cocotron (http://www.cocotron.org/)
 * Copyright (c) 2006-2007 Christopher J. W. Lloyd
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

@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>


var _CPCibCustomResourceClassNameKey    = @"_CPCibCustomResourceClassNameKey",
    _CPCibCustomResourceResourceNameKey = @"_CPCibCustomResourceResourceNameKey",
    _CPCibCustomResourcePropertiesKey   = @"_CPCibCustomResourcePropertiesKey";

@implementation _CPCibCustomResource : CPObject
{
    CPString        _className;
    CPString        _resourceName;
    CPDictionary    _properties;
}

+ (id)imageResourceWithName:(CPString)aResourceName size:(CGSize)aSize
{
    return [[self alloc] initWithClassName:@"CPImage" resourceName:aResourceName properties:[CPDictionary dictionaryWithObject:aSize forKey:@"size"]];
}

+ (id)imageResourceWithName:(CPString)aResourceName size:(CGSize)aSize bundleClass:(CPString)aBundleClass
{
    return [[self alloc] initWithClassName:@"CPImage" resourceName:aResourceName properties:[CPDictionary dictionaryWithObjects:[aSize, aBundleClass] forKeys:[@"size", @"bundleClass"]]];
}

- (id)initWithClassName:(CPString)aClassName resourceName:(CPString)aResourceName properties:(CPDictionary)properties
{
    self = [super init];

    if (self)
    {
        _className = aClassName;
        _resourceName = aResourceName;
        _properties = properties;
    }

    return self;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _className = [aCoder decodeObjectForKey:_CPCibCustomResourceClassNameKey];
        _resourceName = [aCoder decodeObjectForKey:_CPCibCustomResourceResourceNameKey];
        _properties = [aCoder decodeObjectForKey:_CPCibCustomResourcePropertiesKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_className forKey:_CPCibCustomResourceClassNameKey];
    [aCoder encodeObject:_resourceName forKey:_CPCibCustomResourceResourceNameKey];
    [aCoder encodeObject:_properties forKey:_CPCibCustomResourcePropertiesKey];
}

- (id)awakeAfterUsingCoder:(CPCoder)aCoder
{
    if ([aCoder respondsToSelector:@selector(bundle)] &&
        (![aCoder respondsToSelector:@selector(awakenCustomResources)] || [aCoder awakenCustomResources]))
        if (_className === @"CPImage")
        {
            if (_resourceName == "CPAddTemplate")
                return [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[CPButtonBar class]] pathForResource:@"plus_button.png"] size:CGSizeMake(11, 12)];
            else if (_resourceName == "CPRemoveTemplate")
                return [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[CPButtonBar class]] pathForResource:@"minus_button.png"] size:CGSizeMake(11, 4)];

            return [self imageFromBundle:[aCoder bundle]];
        }

    return self;
}

- (CPImage)imageFromBundle:(CPBundle)aBundle
{
    if (!aBundle)
    {
        var bundleClass = _properties.valueForKey(@"bundleClass");

        if (bundleClass)
        {
            bundleClass = CPClassFromString(bundleClass);

            if (bundleClass)
                aBundle = [CPBundle bundleForClass:bundleClass];
        }
        else
            aBundle = [CPBundle mainBundle];
    }

    return [[CPImage alloc] initWithContentsOfFile:[aBundle pathForResource:_resourceName] size:_properties.valueForKey(@"size")];
}

@end

@implementation _CPCibCustomResource (CPImage)

- (CPString)filename
{
    return [[CPBundle mainBundle] pathForResource:_resourceName];
}

- (CGSize)size
{
    return [_properties objectForKey:@"size"];
}

- (BOOL)isThreePartImage
{
    return NO;
}

- (BOOL)isNinePartImage
{
    return NO;
}

- (unsigned)loadStatus
{
    return CPImageLoadStatusCompleted;
}

- (id)delegate
{
    return nil;
}

- (CPString)description
{
    var image = [self imageFromBundle:nil];

    return [image description];
}

@end
