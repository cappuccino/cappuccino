//
// CPController.j
// AppKit
//
// Created by Ross Boucher 1/15/09
// Copyright 280 North
//
// Adapted from GNUStep
// Copyright (C) 2007 Free Software Foundation, Inc
// Released under the LGPL.
//


@import <Foundation/CPObject.j>

var CPControllerDeclaredKeysKey = @"CPControllerDeclaredKeysKey";

@implementation CPController : CPObject
{
    CPArray     _editors;
    CPArray     _declaredKeys;
}

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

- (void)encodeWithCoder:(CPCoder)aCoder
{
    if ([_declaredKeys count] > 0)
        [aCoder encodeObject:_declaredKeys forKey:CPControllerDeclaredKeysKey];
}

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

- (BOOL)isEditing
{
    return [_editors count] > 0;
}

- (BOOL)commitEditing
{
    var index = 0,
        count = _editors.length;

    for (; index < count; ++index)
        if (![[_editors objectAtIndex:index] commitEditing])
            return NO;

    return YES;
}

- (void)discardEditing
{
    [_editors makeObjectsPerformSelector:@selector(discardEditing)];
}

- (void)objectDidBeginEditing:(id)anEditor
{
    [_editors addObject:anEditor];
}

- (void)objectDidEndEditing:(id)anEditor
{
    [_editors removeObject:anEditor];
}

@end
