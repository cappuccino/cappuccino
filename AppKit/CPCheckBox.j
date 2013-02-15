/*
 * CPCheckBox.j
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

@import "CPButton.j"


CPCheckBoxImageOffset = 4.0;

@implementation CPCheckBox : CPButton
{
}

+ (id)checkBoxWithTitle:(CPString)aTitle theme:(CPTheme)aTheme
{
    return [self buttonWithTitle:aTitle theme:aTheme];
}

+ (id)checkBoxWithTitle:(CPString)aTitle
{
    return [self buttonWithTitle:aTitle];
}

+ (CPString)defaultThemeClass
{
    return @"check-box";
}

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding === CPValueBinding)
        return [_CPCheckBoxValueBinder class];

    return [super _binderClassForBinding:aBinding];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        [self setHighlightsBy:CPContentsCellMask];
        [self setShowsStateBy:CPContentsCellMask];

        // Defaults?
        [self setImagePosition:CPImageLeft];
        [self setAlignment:CPLeftTextAlignment];

        [self setBordered:NO];
    }

    return self;
}

- (void)takeStateFromKeyPath:(CPString)aKeyPath ofObjects:(CPArray)objects
{
    var count = objects.length,
        value = [objects[0] valueForKeyPath:aKeyPath] ? CPOnState : CPOffState;

    [self setAllowsMixedState:NO];
    [self setState:value];

    while (count-- > 1)
    {
        if (value !== ([objects[count] valueForKeyPath:aKeyPath] ? CPOnState : CPOffState))
        {
            [self setAllowsMixedState:YES];
            [self setState:CPMixedState];
        }
    }
}

- (void)takeValueFromKeyPath:(CPString)aKeyPath ofObjects:(CPArray)objects
{
    [self takeStateFromKeyPath:aKeyPath ofObjects:objects];
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

@implementation _CPCheckBoxValueBinder : CPBinder
{
}

- (void)_updatePlaceholdersWithOptions:(CPDictionary)options
{
    [super _updatePlaceholdersWithOptions:options];

    [self _setPlaceholder:CPMixedState forMarker:CPMultipleValuesMarker isDefault:YES];
    [self _setPlaceholder:CPOffState forMarker:CPNoSelectionMarker isDefault:YES];
    [self _setPlaceholder:CPOffState forMarker:CPNotApplicableMarker isDefault:YES];
    [self _setPlaceholder:CPOffState forMarker:CPNullMarker isDefault:YES];
}

- (void)setPlaceholderValue:(id)aValue withMarker:(CPString)aMarker forBinding:(CPString)aBinding
{
    [_source setAllowsMixedState:(aValue === CPMixedState)];
    [_source setState:aValue];
}

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    [_source setState:aValue];
}

@end
