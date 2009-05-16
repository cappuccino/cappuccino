/*
 * CPRadio.j
 * AppKit
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
@import <Foundation/CPSet.j>

@import "CPButton.j"


@implementation CPRadio : CPButton
{
    CPRadioGroup    _radioGroup;
}

+ (CPButton)standardButtonWithTitle:(CPString)aTitle
{
    var button = [[CPRadio alloc] init];

    [button setTitle:aTitle];

    return button;
}

+ (CPString)themeClass
{
    return @"radio";
}

// Designated Initializer
- (id)initWithFrame:(CGRect)aFrame radioGroup:(CPRadioGroup)aRadioGroup
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _radioGroup = aRadioGroup || [CPRadioGroup new];
    
        [self setHighlightsBy:CPContentsCellMask];
        [self setShowsStateBy:CPContentsCellMask];

        // Defaults?
        [self setImagePosition:CPImageLeft];
        [self setAlignment:CPLeftTextAlignment];

        [self setBordered:YES];
    }
    
    return self; 
}

- (id)initWithFrame:(CGRect)aFrame
{
    return [self initWithFrame:aFrame radioGroup:nil];
}

- (CPInteger)nextState
{
    return CPOnState;
}

- (void)setRadioGroup:(CPRadioGroup)aRadioGroup
{
    if (_radioGroup === aRadioGroup)
        return;

    [_radioGroup _removeRadio:self];
    _radioGroup = aRadioGroup;
    [_radioGroup _addRadio:self];
}

- (CPRadioGroup)radioGroup
{
    return _radioGroup;
}

- (void)setObjectValue:(id)aValue
{
    [super setObjectValue:aValue];
    
    if ([self state] === CPOnState)
        [_radioGroup _setSelectedRadio:self];
}

@end

@implementation CPRadioGroup : CPObject
{
    CPSet   _radios;
    CPRadio _selectedRadio;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _radios = [CPSet set];
        _selectedRadio = nil;
    }

    return self;
}

- (void)_addRadio:(CPRadio)aRadio
{
    [_radios addObject:aRadio];

    if ([aRadio state] === CPOnState)
        [self _setSelectedRadio:aRadio];
}

- (void)_removeRadio:(CPRadio)aRadio
{
    if (_selectedRadio === aRadio)
        _selectedRadio = nil;

    [_radios removeObject:aRadio];
}

- (void)_setSelectedRadio:(CPRadio)aRadio
{
    if (_selectedRadio === aRadio)
        return;

    [_selectedRadio setState:CPOffState];
    _selectedRadio = aRadio;
}

- (CPRadio)selectedRadio
{
    return _selectedRadio;
}

- (CPArray)radios
{
    return [_radios allObjects];
}

@end
