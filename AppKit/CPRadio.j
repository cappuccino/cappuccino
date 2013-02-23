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

@global CPApp


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

- (void)sendAction:(SEL)anAction to:(id)anObject
{
    [super sendAction:anAction to:anObject];

    if (_radioGroup)
        [CPApp sendAction:[_radioGroup action] to:[_radioGroup target] from:_radioGroup];
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

- (CPImage)image
{
    return [self currentValueForThemeAttribute:@"image"];
}

- (CPImage)alternateImage
{
    return [self currentValueForThemeAttribute:@"image"];
}

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    var startedTracking = [super startTrackingAt:aPoint];
    [self highlight:YES];
    return startedTracking;
}

@end

@implementation CPRadioGroup : CPObject
{
    CPArray _radios;
    CPRadio _selectedRadio;

    BOOL    _enabled @accessors(getter=enabled);
    BOOL    _hidden @accessors(getter=hidden);

    id      _target @accessors(property=target);
    SEL     _action @accessors(property=action);
}

+ (void)initialize
{
    if (self !== [CPRadioGroup class])
        return;

    [self exposeBinding:CPSelectedValueBinding];
    [self exposeBinding:CPSelectedTagBinding];
    [self exposeBinding:CPSelectedIndexBinding];

    [self exposeBinding:CPEnabledBinding];
    [self exposeBinding:CPHiddenBinding];
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _radios = [];
        _selectedRadio = nil;
        _enabled = YES;
        _hidden = NO;
    }

    return self;
}

/*!
    Selects the radio button at the given index within the group.
    If index is -1, all of the radio buttons are turned off.
*/
- (void)selectRadioAtIndex:(int)index
{
    if (index === -1)
        [self _setSelectedRadio:nil];
    else
    {
        var radio = [_radios objectAtIndex:index];

        [self _setSelectedRadio:radio];
        [radio setState:CPOnState];
    }
}

/*!
    Selects the first radio button within the group with the given tag.
    If a radio button with the given tag is found, selects it
    and returns YES. Otherwise returns NO.
*/
- (BOOL)selectRadioWithTag:(int)tag
{
    var index = [_radios indexOfObjectPassingTest:function(radio)
                    {
                        return [radio tag] === tag;
                    }];

    if (index !== CPNotFound)
    {
        [self selectRadioAtIndex:index];
        return YES;
    }
    else
        return NO;
}

/*!
    Returns the CPRadio that is currently selected within the group,
    or nil if none are selected.
*/
- (CPRadio)selectedRadio
{
    return _selectedRadio;
}

/*!
    Returns the index of the selected radio within the array of radio buttons.
    Buttons are numbered going left to right and top to bottom. Returns -1
    if no radio within the group is selected.
*/
- (int)selectedRadioIndex
{
    return [_radios indexOfObject:_selectedRadio];
}

- (CPArray)radios
{
    return _radios;
}

- (void)setEnabled:(BOOL)enabled
{
    [_radios makeObjectsPerformSelector:@selector(setEnabled:) withObject:enabled];
}

- (void)setHidden:(BOOL)hidden
{
    [_radios makeObjectsPerformSelector:@selector(setHidden:) withObject:hidden];
}

#pragma mark Private

- (void)_addRadio:(CPRadio)aRadio
{
    if ([_radios indexOfObject:aRadio] === CPNotFound)
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

/*!
    Selects the first radio button within the group with the given tag.
    If a radio button with the given tag is found, selects it
    and returns YES. Otherwise returns NO.
*/
- (void)_selectRadioWithTitle:(CPString)aTitle
{
    var index = [_radios indexOfObjectPassingTest:function(radio)
                    {
                        return [radio title] === aTitle;
                    }];

    [self selectRadioAtIndex:index];
}

- (void)_setSelectedRadio:(CPRadio)aRadio
{
    if (_selectedRadio === aRadio)
        return;

    [_selectedRadio setState:CPOffState];

    _selectedRadio = aRadio;
    [_CPRadioGroupSelectionBinder reverseSetValueForObject:self];
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

@implementation CPRadioGroup (BindingSupport)

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding === CPSelectedValueBinding   ||
        aBinding === CPSelectedTagBinding     ||
        aBinding === CPSelectedIndexBinding)
    {
        var capitalizedBinding = aBinding.charAt(0).toUpperCase() + aBinding.substr(1);

        return [CPClassFromString(@"_CPRadioGroup" + capitalizedBinding + "Binder") class];
    }
    else if ([aBinding hasPrefix:CPEnabledBinding])
        return [CPMultipleValueAndBinding class];
    else if ([aBinding hasPrefix:CPHiddenBinding])
        return [CPMultipleValueOrBinding class];

    return [super _binderClassForBinding:aBinding];
}

@end

var binderForObject = {};

@implementation _CPRadioGroupSelectionBinder : CPBinder
{
    CPString _selectionBinding @accessors;
}

- (id)initWithBinding:(CPString)aBinding name:(CPString)aName to:(id)aDestination keyPath:(CPString)aKeyPath options:(CPDictionary)options from:(id)aSource
{
    self = [super initWithBinding:aBinding name:aName to:aDestination keyPath:aKeyPath options:options from:aSource];

    if (self)
    {
        binderForObject[[aSource UID]] = self;
        _selectionBinding = aName;
    }

    return self;
}

+ (void)reverseSetValueForObject:(id)aSource
{
    var binder = binderForObject[[aSource UID]];
    [binder reverseSetValueFor:[binder _selectionBinding]];
}

- (void)setPlaceholderValue:(id)aValue withMarker:(CPString)aMarker forBinding:(CPString)aBinding
{
    [self setValue:aValue forBinding:aBinding];
}

@end

@implementation _CPRadioGroupSelectedIndexBinder : _CPRadioGroupSelectionBinder

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    [_source selectRadioAtIndex:aValue];
}

- (id)valueForBinding:(CPString)aBinding
{
    return [_source selectedRadioIndex];
}

@end

@implementation _CPRadioGroupSelectedTagBinder : _CPRadioGroupSelectionBinder

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    [_source selectRadioWithTag:aValue];
}

- (id)valueForBinding:(CPString)aBinding
{
    return [[_source selectedRadio] tag];
}

@end

@implementation _CPRadioGroupSelectedValueBinder : _CPRadioGroupSelectionBinder

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    [_source _selectRadioWithTitle:aValue];
}

- (id)valueForBinding:(CPString)aBinding
{
    return [[_source selectedRadio] title];
}

@end
