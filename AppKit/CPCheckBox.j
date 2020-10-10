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


#pragma mark -
#pragma mark Override methods from CPButton

- (CGSize)_minimumFrameSize
{
    var size = [super _minimumFrameSize],
        contentView = [self ephemeralSubviewNamed:@"content-view"];

    if (!contentView && [[self title] length])
    {
        var minSize = [self currentValueForThemeAttribute:@"min-size"],
            maxSize = [self currentValueForThemeAttribute:@"max-size"];

        // Here we always add the min size to the control which is the size of the view of the checkBox
        size.width += minSize.width + CPCheckBoxImageOffset;

        if (maxSize.width >= 0.0)
            size.width = MIN(size.width, maxSize.width);
    }

    return size;
}

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

#pragma mark -

@implementation CPCheckBox (TableDataView)

// We overide here _CPObject+Theme setValue:forThemeAttribute as CPCheckBox can be used as tableView data view
// So, when outside a table data view, setValue:forThemeAttribute should store the value with the CPThemeStateNormal (default behavior)
// When inside a table data view, it should store the value with the CPThemeStateTableDataView. If not, the value won't be used if the
// theme defined a value for this attribute for state CPThemeStateTableDataView

- (void)setValue:(id)aValue forThemeAttribute:(CPString)aName
{
    [super setValue:aValue forThemeAttribute:aName];
    [super setValue:aValue forThemeAttribute:aName inState:CPThemeStateTableDataView];
}

@end
