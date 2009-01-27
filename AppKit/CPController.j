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

@import "CPKeyValueBinding.j"

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
    [aCoder encodeObject:_declaredKeys forKey:CPControllerDeclaredKeysKey];
}

- (id)initWithCoder:(CPCoder)aDecoder
{
    self = [self init];
    
    if (self)
        _declaredKeys = [aDecoder decodeObjectForKey:CPControllerDeclaredKeysKey] || _declaredKeys;

    return nil;
}

- (BOOL)isEditing
{
    return [_editors count] > 0;
}

- (BOOL)commitEditing
{
    for (var i=0, count=_editors.length; i<count; i++)
    {
        if (![[_editors objectAtIndex:i] commitEditing])
            return NO;
    }

    return YES;
}

- (void)discardEditing
{
    [_editors makeObjectsPerformSelector: @selector(discardEditing)];
}

- (void)objectDidBeginEditing:(id)editor
{
    [_editors addObject:editor];
}

- (void)objectDidEndEditing:(id)editor
{
    [_editors removeObject:editor];
}

@end