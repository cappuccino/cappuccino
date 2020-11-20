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

@class CPRadioGroup

@global CPApp

CPRadioImageOffset = 4.0;

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

    UPDATE 09/2020 : Implementation of modern Cocoa behavior :

    As in Cocoa, radio buttons grouping is now automatic.

    To be associated in a common group (and so being mutually exclusive),
    radio buttons must combine 2 criteria :

    - same superview (enclosing view)
    - same action

    TODO: This first implementation uses "as is" CPRadioGroup. This could
          be simplified (no more need for radio group action, for example)
*/
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

- (BOOL)sendAction:(SEL)anAction to:(id)anObject
{
    [super sendAction:anAction to:anObject];

    if (_radioGroup)
        [CPApp sendAction:[_radioGroup action] to:[_radioGroup target] from:_radioGroup];
}

- (void)viewDidMoveToSuperview
{
    [self _setRadioGroup];
    [super viewDidMoveToSuperview];
}

- (void)setAction:(SEL)anAction
{
    if (anAction === _action)
        return;

    [super setAction:anAction];
    [self _setRadioGroup];
}

#pragma mark Private methods

- (void)_setRadioGroup
{
    // Implementation of modern Cocoa behavior : automatic radio group

    // If no action is set or no superview, no grouping can be done.
    if (![self action] || ![self superview])
    {
        // If this radio is in a group (size > 1), remove it.
        if ([[self radioGroup] size] > 1)
        {
            [self setRadioGroup:[CPRadioGroup new]];

            if ([self state] === CPOnState)
                [_radioGroup _setSelectedRadio:self];
        }

        return;
    }

    // Search in superview subviews for other radio buttons having the same action.
    // Take the one with the radio group having the greatest number of members.

    var radioGroup;

    for (var i = 0, superviewSubviews = [[self superview] subviews], count = [superviewSubviews count], aSubview, myAction = [self action], radioGroupSize = -1; (i < count); i++)
    {
        aSubview = superviewSubviews[i];

        if ([aSubview isKindOfClass:CPRadio] && (aSubview !== self) && ([aSubview action] === myAction) && ([[aSubview radioGroup] size] > radioGroupSize))
        {
            radioGroup     = [aSubview radioGroup];
            radioGroupSize = [radioGroup size];
        }
    }

    if (radioGroup)
        [self setRadioGroup:radioGroup];
    else
        // No other radio buttons to group with found.
        // It may be because this radio button was in a radio group and its action was changed.
        // If this is the case, we must reisolate it in a new radio group.
        if ([_radioGroup size] > 1)
            [self setRadioGroup:[CPRadioGroup new]];

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

#pragma mark -
#pragma mark Override methods from CPButton

- (CPThemeState)_contentVisualState
{
    // Note : Behavior differs from CPButton as title doesn't follow the highlightsBy content flag

    var visualState  = [self themeState] || CPThemeStateNormal, // Needed during theme compilation
        currentState = [self state];

    if ((currentState !== CPOffState) && (_showsStateBy & CPContentsCellMask))
        visualState = visualState.and((currentState === CPOnState) ? CPThemeStateSelected : CPButtonStateMixed);

    return visualState;
}

- (CPThemeState)_imageVisualState
{
    // Note : Behavior differs from CPButton as we don't force "not selected" theme state
    //        when button is highglighted and selected

    var visualState  = [self themeState] || CPThemeStateNormal, // Needed during theme compilation
        currentState = [self state];

    if (_isHighlighted && (_highlightsBy & CPContentsCellMask))
        visualState = visualState.and(CPThemeStateHighlighted);

    if ((currentState !== CPOffState) && (_showsStateBy & CPContentsCellMask))
        visualState = visualState.and((currentState === CPOnState) ? CPThemeStateSelected : CPButtonStateMixed);

    return visualState;
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

- (int)size
{
    return [_radios count];
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
    [_CPRadioGroupSelectionBinder _reverseSetValueFromExclusiveBinderForObject:self];
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

+ (BOOL)isBindingExclusive:(CPString)aBinding
{
    return (aBinding == CPSelectedIndexBinding ||
           aBinding == CPSelectedTagBinding ||
           aBinding == CPSelectedValueBinding);
}

@end

@implementation _CPRadioGroupSelectionBinder : CPBinder
{
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
