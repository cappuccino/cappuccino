/*
 * CPController.j
 * AppKit
 *
 * Created by Ross Boucher.
 * Copyright 2009, 280 North, Inc.
 *
 * Adapted from GNUstep
 * Copyright (C) 2007 Free Software Foundation, Inc.
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

/* @ignore */
var CPControllerDeclaredKeysKey = @"CPControllerDeclaredKeysKey";

/*!
 @ingroup appkit
 @class CPController
 An abstract base controller class that provides editing management and coordination
 support for controller objects and Cappuccino bindings.
 */
@implementation CPController : CPObject
{
    CPArray     _editors;
    CPArray     _declaredKeys;
}

/*!
 Initializes a newly allocated controller instance.
 @return the initialized controller instance
 */
- (id)init
{
    self = [super init];

    if (self)
    {
        _editors = [];
        _declaredKeys = [];
    }

    return self;
}

/*!
 Encodes the receiver's declared keys using the provided coder.
 @param aCoder the coder to encode data into
 */
- (void)encodeWithCoder:(CPCoder)aCoder
{
    if ([_declaredKeys count] > 0)
        [aCoder encodeObject:_declaredKeys forKey:CPControllerDeclaredKeysKey];
}

/*!
 Initializes the receiver from an unarchiver.
 @param aDecoder the decoder containing the archived controller state
 @return the initialized controller instance
 */
- (id)initWithCoder:(CPCoder)aDecoder
{
    self = [super init];

    if (self)
    {
        _editors = [];
        _declaredKeys = [aDecoder decodeObjectForKey:CPControllerDeclaredKeysKey] || [];
    }

    return self;
}

/*!
 Returns whether the receiver is currently tracking any active editors.
 @return \c YES if one or more editors are active, otherwise \c NO
 */
- (BOOL)isEditing
{
    return [_editors count] > 0;
}

/*!
 Attempts to commit any pending edits across all active registered editors.
 @return \c YES if all editors successfully committed edits, otherwise \c NO
 */
- (BOOL)commitEditing
{
    var index = 0,
        count = _editors.length;

    for (; index < count; ++index)
        if (![[_editors objectAtIndex:index] commitEditing])
            return NO;

    return YES;
}

/*!
 Discards changes across all active registered editors.
 */
- (void)discardEditing
{
    [_editors makeObjectsPerformSelector:@selector(discardEditing)];
}

/*!
 Notifies the controller that a registered editor has begun editing.
 @param anEditor the editor object that began editing
 */
- (void)objectDidBeginEditing:(id)anEditor
{
    [_editors addObject:anEditor];
}

/*!
 Notifies the controller that a registered editor has ended editing.
 @param anEditor the editor object that finished editing
 */
- (void)objectDidEndEditing:(id)anEditor
{
    [_editors removeObject:anEditor];
}

@end
