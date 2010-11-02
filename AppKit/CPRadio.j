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


/*!
    @ingroup appkit

    from this mailing list thread:
    http://groups.google.com/group/objectivej/browse_thread/thread/7c41cbd9cbee9ea3

    -----------------------------------

    Creating a checkbox is easy enough:

    checkbox = [[CPCheckBox alloc] initWithFrame:aFrame];

    That's basically all there is to it. Radio buttons are very similar,
    the key difference is the introduction of a new class CPRadioGroup,
    which defines which radio buttons are part of the same group:

    [myRadioButton setRadioGroup:aRadioGroup];

    Every radio button receives a unique radio group by default (so if you
    do nothing further, they will all behave independently), but you can
    use an existing radio button's group with other buttons as so:

    button1 = [[CPRadio alloc] initWithFrame:aFrame];
    ...
    button2 = [[CPRadio alloc] initWithFrame:aFrame radioGroup:[button1
    radioGroup]];
    ...
    button3 = [[CPRadio alloc] initWithFrame:aFrame radioGroup:[button1
    radioGroup]];
    ...etc...

    Here, all the radio buttons will act "together". [[button1 radioGroup]
    allRadios] returns every button that's part of this group, and
    [[button1 radioGroup] selectedRadio] returns the currently selected
    option.

*/

CPRadioImageOffset = 4.0;

@implementation CPRadio : CPButton
{
    CPRadioGroup    _radioGroup;
}

+ (id)radioWithTitle:(CPString)aTitle theme:(CPTheme)aTheme
{
    return [self buttonWithTitle:aTitle theme:aTheme];
}

+ (id)radioWithTitle:(CPString)aTitle
{
    return [self buttonWithTitle:aTitle];
}

+ (CPButton)standardButtonWithTitle:(CPString)aTitle
{
    var button = [[CPRadio alloc] init];

    [button setTitle:aTitle];

    return button;
}

+ (CPString)defaultThemeClass
{
    return @"radio";
}

// Designated Initializer
- (id)initWithFrame:(CGRect)aFrame radioGroup:(CPRadioGroup)aRadioGroup
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        [self setRadioGroup:aRadioGroup];

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
    return [self initWithFrame:aFrame radioGroup:[CPRadioGroup new]];
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

var CPRadioRadioGroupKey    = @"CPRadioRadioGroupKey";

@implementation CPRadio (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
        _radioGroup = [aCoder decodeObjectForKey:CPRadioRadioGroupKey];

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_radioGroup forKey:CPRadioRadioGroupKey];
}

@end

@implementation CPRadioGroup : CPObject
{
    CPSet   _radios;
    CPRadio _selectedRadio;

    id      _target @accessors(property=target);
    SEL     _action @accessors(property=action);
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

    [CPApp sendAction:_action to:_target from:self];
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

var CPRadioGroupRadiosKey           = @"CPRadioGroupRadiosKey",
    CPRadioGroupSelectedRadioKey    = @"CPRadioGroupSelectedRadioKey";

@implementation CPRadioGroup (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _radios = [aCoder decodeObjectForKey:CPRadioGroupRadiosKey];
        _selectedRadio = [aCoder decodeObjectForKey:CPRadioGroupSelectedRadioKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_radios forKey:CPRadioGroupRadiosKey];
    [aCoder encodeObject:_selectedRadio forKey:CPRadioGroupSelectedRadioKey];
}

@end
