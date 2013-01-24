/*
 * CPUserDefaultsController.j
 * AppKit
 *
 * Portions based on NSUserDefaultsController.m (2009-06-04) in Cocotron (http://www.cocotron.org/)
 * Copyright (c) 2006-2007 Christopher J. W. Lloyd
 *
 * Created by Alexander Ljungberg.
 * Copyright 2011, WireLoad Inc.
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

@import <Foundation/CPDictionary.j>
@import <Foundation/CPNotificationCenter.j>
@import <Foundation/CPString.j>
@import <Foundation/CPUserDefaults.j>

@import "CPController.j"

@global CPUserDefaultsDidChangeNotification


var SharedUserDefaultsController = nil;

@implementation CPUserDefaultsController : CPController
{
    CPUserDefaults  _defaults           @accessors(readonly, property=defaults);
    CPDictionary    _initialValues      @accessors(property=initialValues);
    BOOL            _appliesImmediately @accessors(property=appliesImmediately);
    id              _valueProxy;
}

+ (id)sharedUserDefaultsController
{
    if (!SharedUserDefaultsController)
        SharedUserDefaultsController = [[CPUserDefaultsController alloc] initWithDefaults:nil initialValues:nil];

    return SharedUserDefaultsController;
}

- (id)initWithDefaults:(CPUserDefaults)someDefaults initialValues:(CPDictionary)initialValues
{
    if (self = [super init])
    {
        if (!someDefaults)
            someDefaults = [CPUserDefaults standardUserDefaults];

        _defaults = someDefaults;
        _initialValues = [initialValues copy];
        _appliesImmediately = YES;
        _valueProxy = [[_CPUserDefaultsControllerProxy alloc] initWithController:self];
    }

    return self;
}

- (id)values
{
    return _valueProxy;
}

- (BOOL)hasUnappliedChanges
{
    return [_valueProxy hasUnappliedChanges];
}

- (void)save:(id)sender
{
    [_valueProxy save];
}

- (void)revert:(id)sender
{
    [_valueProxy revert];
}

- (void)revertToInitialValues:(id)sender
{
    [_valueProxy revertToInitialValues];
}

@end


var CPUserDefaultsControllerSharedKey = "CPUserDefaultsControllerSharedKey";

@implementation CPUserDefaultsController (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if ([aCoder decodeBoolForKey:CPUserDefaultsControllerSharedKey])
        return [CPUserDefaultsController sharedUserDefaultsController];

    self = [super initWithCoder:aCoder];

    if (self)
    {
        [CPException raise:CPUnsupportedMethodException reason:@"decoding of non-shared CPUserDefaultsController not implemented"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    if (self === SharedUserDefaultsController)
    {
        [aCoder encodeBool:YES forKey:CPUserDefaultsControllerSharedKey];
        return;
    }

    [CPException raise:CPUnsupportedMethodException reason:@"encoding of non-shared CPUserDefaultsController not implemented"];
}

@end


@implementation _CPUserDefaultsControllerProxy : CPObject
{
    CPUserDefaultsController    _controller;
    // TODO Could be optimised with a JS dict.
    CPMutableDictionary         _cachedValues;
}

- (id)initWithController:(CPUserDefaultsController)aController
{
    if (self = [super init])
    {
        _controller = aController;
        _cachedValues = [CPMutableDictionary dictionary];

        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:CPUserDefaultsDidChangeNotification object:[_controller defaults]];
    }

    return self;
}

- (void)dealloc
{
    // FIXME No dealloc in Cappuccino.
    [[CPNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (id)valueForKey:(CPString)aKey
{
    var value = [_cachedValues objectForKey:aKey];
    if (value === nil)
    {
        value = [[_controller defaults] objectForKey:aKey];
        if (value === nil)
            value = [[_controller initialValues] objectForKey:aKey];

        if (value !== nil)
            [_cachedValues setObject:value forKey:aKey];
    }
    return value;
}

- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    [self willChangeValueForKey:aKey];
    [_cachedValues setObject:aValue forKey:aKey];
    if ([_controller appliesImmediately])
        [[_controller defaults] setObject:aValue forKey:aKey];
    [self didChangeValueForKey:aKey];
}


- (void)revert
{
    var keys = [_cachedValues allKeys],
        keysCount = [keys count];

    while (keysCount--)
    {
        var key = keys[keysCount];
        [self willChangeValueForKey:key];
        [_cachedValues removeObjectForKey:key];
        [self didChangeValueForKey:key];
    }
}

- (void)save
{
    var keys = [_cachedValues allKeys],
        keysCount = [keys count];

    while (keysCount--)
    {
        var key = keys[keysCount];
        [[_controller defaults] setObject:[_cachedValues objectForKey:key] forKey:key];
    }
}

- (void)revertToInitialValues
{
    var initial = [_controller initialValues],
        keys = [_cachedValues allKeys],
        keysCount = [keys count];

    while (keysCount--)
    {
        var key = keys[keysCount];
        [self willChangeValueForKey:key];

        var initialValue = [initial objectForKey:key];
        if (initialValue !== nil)
            [_cachedValues setObject:initialValue forKey:key];
        else
            [_cachedValues removeObjectForKey:key];

        [self didChangeValueForKey:key];

    }
}

- (void)userDefaultsDidChange:(CPNotification)aNotification
{
    var defaults = [_controller defaults],
        keys = [_cachedValues allKeys],
        keysCount = [keys count];

    while (keysCount--)
    {
        var key = keys[keysCount],
            value = [_cachedValues objectForKey:key],
            newValue = [defaults objectForKey:key];

        if (![value isEqual:newValue])
        {
            [self willChangeValueForKey:key];
            [_cachedValues setObject:newValue forKey:key];
            [self didChangeValueForKey:key];
        }
    }
}

- (BOOL)hasUnappliedChanges
{
    var defaults = [_controller defaults],
        keys = [_cachedValues allKeys],
        keysCount = [keys count];

    while (keysCount--)
    {
        var key = keys[keysCount],
            value = [_cachedValues objectForKey:key],
            newValue = [defaults objectForKey:key];

        if (![value isEqual:newValue])
            return YES;
    }

    return NO;
}

@end

