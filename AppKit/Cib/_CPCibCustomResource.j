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

@import "CPCompatibility.j"
@import "CPImage.j"
@import "CPTheme.j"

@class CPButtonBar
@class CPView

var _CPCibCustomResourceClassNameKey    = @"_CPCibCustomResourceClassNameKey",
    _CPCibCustomResourceResourceNameKey = @"_CPCibCustomResourceResourceNameKey",
    _CPCibCustomResourcePropertiesKey   = @"_CPCibCustomResourcePropertiesKey";

@implementation _CPCibCustomResource : CPObject
{
    CPString        _className;
    CPString        _resourceName;
    CPDictionary    _properties;
    CPBundle        _bundle;
}

+ (id)imageResourceWithName:(CPString)aResourceName size:(CGSize)aSize
{
    return [[self alloc] initWithClassName:@"CPImage" resourceName:aResourceName properties:@{ @"size": aSize }];
}

+ (id)imageResourceWithName:(CPString)aResourceName size:(CGSize)aSize bundleClass:(CPString)aBundleClass
{
    return [[self alloc] initWithClassName:@"CPImage" resourceName:aResourceName properties:@{ @"size": aSize, @"bundleClass": aBundleClass }];
}

- (id)initWithClassName:(CPString)aClassName resourceName:(CPString)aResourceName properties:(CPDictionary)properties
{
    self = [super init];

    if (self)
    {
        _className = aClassName;
        _resourceName = aResourceName;
        _properties = properties;
        _bundle = nil;
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
        _bundle = nil;
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
                return [[CPTheme defaultTheme] valueForAttributeWithName:@"button-image-plus" forClass:[CPButtonBar class]];
            else if (_resourceName == "CPRemoveTemplate")
                return [[CPTheme defaultTheme] valueForAttributeWithName:@"button-image-minus" forClass:[CPButtonBar class]];

            return [self imageFromCoder:aCoder];
        }

    return self;
}

@end

@implementation _CPCibCustomResource (CPImage)

- (CPBundle)imageBundleWithCoder:(CPCoder)aCoder
{
    if (_bundle)
        return _bundle;

    var bundleIdentifier = [_properties valueForKey:@"bundleIdentifier"];

    if (bundleIdentifier)
        _bundle = [CPBundle bundleWithIdentifier:bundleIdentifier];
    else
    {
        var bundleClass = [_properties valueForKey:@"bundleClass"];

        if (bundleClass)
        {
            bundleClass = CPClassFromString(bundleClass);

            if (bundleClass)
                _bundle = [CPBundle bundleForClass:bundleClass];
        }
    }

    if (!_bundle)
    {
        var framework = [_properties valueForKey:@"framework"];

        if (framework)
        {
            // Get AppKit and hope the framework is in the same directory
            var appKit = [CPBundle bundleForClass:[CPView class]],
                url = [[appKit bundleURL] URLByDeletingLastPathComponent];

            url = [CPURL URLWithString:framework relativeToURL:url];
            _bundle = [CPBundle bundleWithURL:url];
        }
    }

    if (!_bundle)
    {
        if (aCoder)
            _bundle = [aCoder bundle];
        else
            _bundle = [CPBundle mainBundle];
    }

    return _bundle;
}

- (CPImage)imageFromCoder:(CPCoder)aCoder
{
    return [[CPImage alloc] initWithContentsOfFile:[[self imageBundleWithCoder:aCoder] pathForResource:_resourceName] size:[_properties valueForKey:@"size"]];
}

- (CPString)filename
{
    return [[self imageBundleWithCoder:nil] pathForResource:_resourceName];
}

- (CGSize)size
{
    return [_properties objectForKey:@"size"];
}

- (BOOL)isSingleImage
{
    return YES;
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
    var image = [self imageFromCoder:nil];

    return [image description];
}

@end
