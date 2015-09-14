/*
 * CPSegmentedControl.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

@import <Foundation/CPArray.j>

@import "CPControl.j"
@import "CPWindow_Constants.j"
@import "_CPImageAndTextView.j"
@import "CPMenu.j"

@global CPApp

@typedef CPSegmentSwitchTracking
CPSegmentSwitchTrackingSelectOne = 0;
CPSegmentSwitchTrackingSelectAny = 1;
CPSegmentSwitchTrackingMomentary = 2;

/*!
    @ingroup appkit
    @class CPSegmentedControl

    This class is a horizontal button with multiple segments.
*/
@implementation CPSegmentedControl : CPControl
{
    CPArray                 _segments @accessors(getter=segments);
    CPArray                 _themeStates;

    int                     _selectedSegment;
    int                     _segmentStyle;
    CPSegmentSwitchTracking _trackingMode;

    unsigned                _trackingSegment;
    BOOL                    _trackingHighlighted;
}

+ (CPString)defaultThemeClass
{
    return "segmented-control";
}

+ (CPDictionary)themeAttributes
{
    return @{
            @"alignment": CPCenterTextAlignment,
            @"vertical-alignment": CPCenterVerticalTextAlignment,
            @"image-position": CPImageLeft,
            @"image-scaling": CPImageScaleNone,
            @"bezel-inset": CGInsetMakeZero(),
            @"content-inset": CGInsetMakeZero(),
            @"left-segment-bezel-color": [CPNull null],
            @"right-segment-bezel-color": [CPNull null],
            @"center-segment-bezel-color": [CPNull null],
            @"divider-bezel-color": [CPNull null],
            @"divider-thickness": 1.0,
        };
}

- (id)initWithFrame:(CGRect)aRect
{
    _segments = [];
    _themeStates = [];

    self = [super initWithFrame:aRect];

    if (self)
    {
        _selectedSegment = -1;

        _trackingMode = CPSegmentSwitchTrackingSelectOne;
        _trackingHighlighted = NO;
        _trackingSegment = -1;
    }

    return self;
}

/*!
    Sets the control's size.
    @param aControlSize the control's size
*/
- (void)setControlSize:(CPControlSize)aControlSize
{
    [super setControlSize:aControlSize];
    [self _sizeToControlSize];
}

/*!
    Returns the tag of the selected segment.
*/
- (int)selectedTag
{
    return [[_segments objectAtIndex:_selectedSegment] tag];
}

/*! @ignore */
- (void)setSegments:(CPArray)segments
{
    [self removeSegmentsAtIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self  segmentCount])]];

    [self insertSegments:segments atIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [segments count])]];
}

/*! @ignore */
- (void)insertSegments:(CPArray)segments atIndexes:(CPIndexSet)indices
{
    if ([segments count] == 0)
        return;

    var newStates = @[],
        count = [indices count];

    while (count--)
        [newStates addObject:CPThemeStateNormal];

    [_segments insertObjects:segments atIndexes:indices];
    [_themeStates insertObjects:newStates atIndexes:indices];

    if (_selectedSegment >= [indices firstIndex])
        _selectedSegment += [indices count];
}

/*! @ignore */
- (void)removeSegmentsAtIndexes:(CPIndexSet)indices
{
    if ([indices count] == 0)
        return;

    [indices enumerateIndexesUsingBlock:function(idx, stop)
    {
        [[_segments objectAtIndex:idx] setSelected:NO];
    }];

    if ([indices containsIndex:_selectedSegment])
        _selectedSegment = -1;
    else if ([indices lastIndex] < _selectedSegment)
        _selectedSegment -= [indices count];

    [_segments removeObjectsAtIndexes:indices];
    [_themeStates removeObjectsAtIndexes:indices];
}

// Specifying the number of segments
/*!
    Sets the number of segments in the button.
    @param aCount the number of segments on the button
*/
- (void)setSegmentCount:(unsigned)aCount
{
    var prevCount = [_segments count];

    if (aCount == prevCount)
        return;

    if (aCount > prevCount)
    {
        var count = aCount - prevCount,
            segments = @[];

        while (count--)
            [segments addObject:[[_CPSegmentItem alloc] init]];

        [self insertSegments:segments atIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(prevCount, aCount - prevCount)]];
    }
    else
        [self removeSegmentsAtIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(aCount, prevCount - aCount)]];

    [self _updateSelectionIfNeeded];
    [self tileWithChangedSegment:MAX(MIN(prevCount, aCount) - 1, 0)];
}

- (void)_updateSelectionIfNeeded
{
    if (_selectedSegment >= [self segmentCount])
        _selectedSegment = -1;
}

/*!
    Returns the number of segments in the button.
*/
- (unsigned)segmentCount
{
    return [_segments count];
}

// Specifying Selected Segment
/*!
    Selects a segment.
    @param aSegment the segment to select
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (void)setSelectedSegment:(unsigned)aSegment
{
    // setSelected:forSegment throws the exception for us (if necessary)
    if (_selectedSegment == aSegment)
        return;

    if (aSegment == -1)
    {
        var count = [self segmentCount];

        while (count--)
            [self setSelected:NO forSegment:count];

        _selectedSegment = -1;
    }
    else
        [self setSelected:YES forSegment:aSegment];
}

/*!
    Returns the selected segment.
*/
- (unsigned)selectedSegment
{
    return _selectedSegment;
}

/*!
    Selects the button segment with the specified tag.
*/
- (BOOL)selectSegmentWithTag:(int)aTag
{
    var index = 0;

    for (; index < [_segments count]; ++index)
        if ([[_segments objectAtIndex:index] tag] == aTag)
        {
            [self setSelectedSegment:index];

            return YES;
        }

    return NO;
}

- (BOOL)_selectSegmentWithLabel:(CPString)aLabel
{
    var index = 0;

    for (; index < [_segments count]; ++index)
        if ([[_segments objectAtIndex:index] label] == aLabel)
        {
            [self setSelectedSegment:index];

            return YES;
        }

    return NO;
}

// Specifying Tracking Mode
/*! @ignore */
- (BOOL)isTracking
{

}

- (void)setTrackingMode:(CPSegmentSwitchTracking)aTrackingMode
{
    if (_trackingMode == aTrackingMode)
        return;

    _trackingMode = aTrackingMode;

    if (_trackingMode == CPSegmentSwitchTrackingSelectOne)
    {
        var index = 0,
            selected = NO;

        for (; index < [self segmentCount]; ++index)
            if ([_segments[index] selected])
                if (selected)
                    [self setSelected:NO forSegment:index];
                else
                    selected = YES;
    }

    else if (_trackingMode == CPSegmentSwitchTrackingMomentary)
    {
        var index = 0;

        for (; index < [self segmentCount]; ++index)
            if ([_segments[index] selected])
                [self setSelected:NO forSegment:index];
    }
}

/*!
    Returns the control's tracking mode.
*/
- (CPSegmentSwitchTracking)trackingMode
{
    return _trackingMode;
}

// Working with Individual Segments
/*!
    Sets the width of the specified segment.
    @param aWidth the new width for the segment
    @param aSegment the segment to set the width for
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (void)setWidth:(float)aWidth forSegment:(unsigned)aSegment
{
    [[_segments objectAtIndex:aSegment] setWidth:aWidth];
    [self tileWithChangedSegment:aSegment];
}

/*!
    Returns the width for the specified segment.
    @param aSegment the segment to get the width for
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (float)widthForSegment:(unsigned)aSegment
{
    return [[_segments objectAtIndex:aSegment] width];
}

/*!
    Sets the image for the specified segment.
    @param anImage the image for the segment
    @param aSegment the segment to set the image on
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (void)setImage:(CPImage)anImage forSegment:(unsigned)aSegment
{
    [[_segments objectAtIndex:aSegment] setImage:anImage];

    [self tileWithChangedSegment:aSegment];
}

/*!
    Returns the image for the specified segment
    @param aSegment the segment to obtain the image for
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (CPImage)imageForSegment:(unsigned)aSegment
{
    return [[_segments objectAtIndex:aSegment] image];
}

/*!
    Sets the label for the specified segment
    @param aLabel the label for the segment
    @param aSegment the segment to label
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (void)setLabel:(CPString)aLabel forSegment:(unsigned)aSegment
{
    [[_segments objectAtIndex:aSegment] setLabel:aLabel];

    [self tileWithChangedSegment:aSegment];
}

/*!
    Returns the label for the specified segment
    @param the segment to obtain the label for
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (CPString)labelForSegment:(unsigned)aSegment
{
    return [[_segments objectAtIndex:aSegment] label];
}

/*!
    Sets the menu for the specified segment
    @param aMenu the menu to set
    @param aSegment the segment to set the menu on
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (void)setMenu:(CPMenu)aMenu forSegment:(unsigned)aSegment
{
    [[_segments objectAtIndex:aSegment] setMenu:aMenu];
}

/*!
    Returns the menu for the specified segment.
    @param aSegment the segment to obtain the menu for
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (CPMenu)menuForSegment:(unsigned)aSegment
{
    return [[_segments objectAtIndex:aSegment] menu];
}

/*!
    Sets the selection for the specified segment. If only one segment
    can be selected at a time, any other segment will be deselected.
    @param isSelected \c YES selects the segment. \c NO deselects it.
    @param aSegment the segment to set the selection for
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (void)setSelected:(BOOL)isSelected forSegment:(unsigned)aSegment
{
    var segment = [_segments objectAtIndex:aSegment];

    // If we're already in this state, bail.
    if ([segment selected] == isSelected)
        return;

    [segment setSelected:isSelected];

    _themeStates[aSegment] = isSelected ? CPThemeStateSelected : CPThemeStateNormal;

    // We need to do some cleanup if we only allow one selection.
    if (isSelected)
    {
        var oldSelectedSegment = _selectedSegment;

        _selectedSegment = aSegment;

        if (_trackingMode == CPSegmentSwitchTrackingSelectOne && oldSelectedSegment != aSegment && oldSelectedSegment != -1 && oldSelectedSegment < _segments.length)
        {
            [_segments[oldSelectedSegment] setSelected:NO];
            _themeStates[oldSelectedSegment] = CPThemeStateNormal;

            [self drawSegmentBezel:oldSelectedSegment highlight:NO];
        }
    }

    if (_trackingMode != CPSegmentSwitchTrackingMomentary)
        [self drawSegmentBezel:aSegment highlight:NO];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns \c YES if the specified segment is selected.
    @param aSegment the segment to check for selection
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (BOOL)isSelectedForSegment:(unsigned)aSegment
{
    return [[_segments objectAtIndex:aSegment] selected];
}

/*!
    Enables/disables the specified segment.
    @param isEnabled \c YES enables the segment
    @param aSegment the segment to enable/disable
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (void)setEnabled:(BOOL)shouldBeEnabled forSegment:(unsigned)aSegment
{
    var segment = [_segments objectAtIndex:aSegment];

    if ([segment enabled] === shouldBeEnabled)
        return;

    [segment setEnabled:shouldBeEnabled];

    if (shouldBeEnabled)
        _themeStates[aSegment] = _themeStates[aSegment].without(CPThemeStateDisabled);
    else
        _themeStates[aSegment] = _themeStates[aSegment].and(CPThemeStateDisabled);

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns \c YES if the specified segment is enabled.
    @param aSegment the segment to check
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (BOOL)isEnabledForSegment:(unsigned)aSegment
{
    return [[_segments objectAtIndex:aSegment] enabled];
}

/*!
    Sets a tag for the specified segment.
    @param aTag the tag to set
    @param aSegment the segment to set the tag on
*/
- (void)setTag:(int)aTag forSegment:(unsigned)aSegment
{
    [[_segments objectAtIndex:aSegment] setTag:aTag];
}

/*!
    Returns the tag for the specified segment.
    @param aSegment the segment to obtain the tag for
*/
- (int)tagForSegment:(unsigned)aSegment
{
    return [[_segments objectAtIndex:aSegment] tag];
}

// Drawings
/*!
    Draws the specified segment bezel
    @param aSegment the segment to draw the bezel for
    @param shouldHighlight \c YES highlights the bezel
*/
- (void)drawSegmentBezel:(int)aSegment highlight:(BOOL)shouldHighlight
{
    if (aSegment < _themeStates.length)
    {
        if (shouldHighlight)
            _themeStates[aSegment] = _themeStates[aSegment].and(CPThemeStateHighlighted);
        else
            _themeStates[aSegment] = _themeStates[aSegment].without(CPThemeStateHighlighted);
    }

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (float)_leftOffsetForSegment:(unsigned)segment
{
    if (segment == 0)
        return [self currentValueForThemeAttribute:@"bezel-inset"].left;

    var thickness = [self currentValueForThemeAttribute:@"divider-thickness"];

    return [self _leftOffsetForSegment:segment - 1] + CGRectGetWidth([self frameForSegment:segment - 1]) + thickness;
}

- (unsigned)_indexOfLastSegment
{
    var lastSegmentIndex = [_segments count] - 1;

    if (lastSegmentIndex < 0)
        lastSegmentIndex = 0;

    return lastSegmentIndex;
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    var height = [self currentValueForThemeAttribute:@"min-size"].height,
        contentInset = [self currentValueForThemeAttribute:@"content-inset"],
        bezelInset = [self currentValueForThemeAttribute:@"bezel-inset"],
        bounds = [self bounds];

    if (aName === "left-segment-bezel")
    {
        return CGRectMake(bezelInset.left, bezelInset.top, contentInset.left, height);
    }
    else if (aName === "right-segment-bezel")
    {
        return CGRectMake(CGRectGetWidth([self bounds]) - contentInset.right,
                            bezelInset.top,
                            contentInset.right,
                            height);
    }
    else if (aName.indexOf("segment-bezel") === 0)
    {
        var segment = parseInt(aName.substring("segment-bezel-".length), 10),
            frame = CGRectCreateCopy([self frameForSegment:segment]);

        if (segment === 0)
        {
            frame.origin.x += contentInset.left;
            frame.size.width -= contentInset.left;
        }

        if (segment === [self segmentCount] - 1)
            frame.size.width = CGRectGetWidth([self bounds]) - contentInset.right - frame.origin.x;

        return frame;
    }
    else if (aName.indexOf("divider-bezel") === 0)
    {
        var segment = parseInt(aName.substring("divider-bezel-".length), 10),
            width = CGRectGetWidth([self frameForSegment:segment]),
            left = [self _leftOffsetForSegment:segment],
            thickness = [self currentValueForThemeAttribute:@"divider-thickness"];

        return CGRectMake(left + width, bezelInset.top, thickness, height);
    }
    else if (aName.indexOf("segment-content") === 0)
    {
        var segment = parseInt(aName.substring("segment-content-".length), 10);

        return [self contentFrameForSegment:segment];
    }

    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if ([aName hasPrefix:@"segment-content"])
        return [[_CPImageAndTextView alloc] initWithFrame:CGRectMakeZero()];

    return [[CPView alloc] initWithFrame:CGRectMakeZero()];
}

- (void)layoutSubviews
{
    if ([self segmentCount] <= 0)
        return;

    var themeState = _themeStates[0],
        isDisabled = [self hasThemeState:CPThemeStateDisabled],
        isControlSizeSmall = [self hasThemeState:CPThemeStateControlSizeSmall],
        isControlSizeMini = [self hasThemeState:CPThemeStateControlSizeMini];

    themeState = isDisabled ? themeState.and(CPThemeStateDisabled) : themeState;

    if (isControlSizeSmall)
        themeState = themeState.and(CPThemeStateControlSizeSmall);
    else if (isControlSizeMini)
        themeState = themeState.and(CPThemeStateControlSizeMini);

    var leftCapColor = [self valueForThemeAttribute:@"left-segment-bezel-color"
                                            inState:themeState],

        leftBezelView = [self layoutEphemeralSubviewNamed:@"left-segment-bezel"
                                               positioned:CPWindowBelow
                          relativeToEphemeralSubviewNamed:nil];

    [leftBezelView setBackgroundColor:leftCapColor];

    var themeState = _themeStates[_themeStates.length - 1];

    themeState = isDisabled ? themeState.and(CPThemeStateDisabled) : themeState;

    if (isControlSizeSmall)
        themeState = themeState.and(CPThemeStateControlSizeSmall);
    else if (isControlSizeMini)
        themeState = themeState.and(CPThemeStateControlSizeMini);

    var rightCapColor = [self valueForThemeAttribute:@"right-segment-bezel-color"
                                             inState:themeState],

        rightBezelView = [self layoutEphemeralSubviewNamed:@"right-segment-bezel"
                                               positioned:CPWindowBelow
                          relativeToEphemeralSubviewNamed:nil];

    [rightBezelView setBackgroundColor:rightCapColor];

    for (var i = 0, count = _themeStates.length; i < count; i++)
    {
        var themeState = _themeStates[i];

        themeState = isDisabled ? themeState.and(CPThemeStateDisabled) : themeState;

        if (isControlSizeSmall)
            themeState = themeState.and(CPThemeStateControlSizeSmall);
        else if (isControlSizeMini)
            themeState = themeState.and(CPThemeStateControlSizeMini);

        var bezelColor = [self valueForThemeAttribute:@"center-segment-bezel-color"
                                              inState:themeState],

            bezelView = [self layoutEphemeralSubviewNamed:"segment-bezel-" + i
                                               positioned:CPWindowBelow
                          relativeToEphemeralSubviewNamed:nil];

        [bezelView setBackgroundColor:bezelColor];

        // layout image/title views
        var segment = _segments[i],
            contentView = [self layoutEphemeralSubviewNamed:@"segment-content-" + i
                                                 positioned:CPWindowAbove
                            relativeToEphemeralSubviewNamed:@"segment-bezel-" + i];

        [contentView setText:[segment label]];
        [contentView setImage:[segment image]];

        [contentView setFont:[self valueForThemeAttribute:@"font" inState:themeState]];
        [contentView setTextColor:[self valueForThemeAttribute:@"text-color" inState:themeState]];
        [contentView setAlignment:[self valueForThemeAttribute:@"alignment" inState:themeState]];
        [contentView setVerticalAlignment:[self valueForThemeAttribute:@"vertical-alignment" inState:themeState]];
        [contentView setLineBreakMode:[self valueForThemeAttribute:@"line-break-mode" inState:themeState]];
        [contentView setTextShadowColor:[self valueForThemeAttribute:@"text-shadow-color" inState:themeState]];
        [contentView setTextShadowOffset:[self valueForThemeAttribute:@"text-shadow-offset" inState:themeState]];
        [contentView setImageScaling:[self valueForThemeAttribute:@"image-scaling" inState:themeState]];

        if ([segment image] && [segment label])
            [contentView setImagePosition:[self valueForThemeAttribute:@"image-position" inState:themeState]];
        else if ([segment image])
            [contentView setImagePosition:CPImageOnly];

        if (i == count - 1)
            continue;


        var borderState = _themeStates[i].and(_themeStates[i + 1]);

        borderState = isDisabled ? borderState.and(CPThemeStateDisabled) : borderState;

        if (isControlSizeSmall)
            borderState = borderState.and(CPThemeStateControlSizeSmall);
        else if (isControlSizeMini)
            borderState = borderState.and(CPThemeStateControlSizeMini);

        var borderColor = [self valueForThemeAttribute:@"divider-bezel-color"
                                               inState:borderState],

            borderView = [self layoutEphemeralSubviewNamed:"divider-bezel-" + i
                                                positioned:CPWindowBelow
                           relativeToEphemeralSubviewNamed:nil];

        [borderView setBackgroundColor:borderColor];
    }
}


/*!
    Draws the specified segment
    @param aSegment the segment to draw
    @param shouldHighlight \c YES highlights the bezel
*/
- (void)drawSegment:(int)aSegment highlight:(BOOL)shouldHighlight
{
}

/*! @ignore */
- (void)tile
{
    [self tileWithChangedSegment:0];
}

/*! @ignore */
- (void)tileWithChangedSegment:(CPInteger)aSegment
{
    var segmentCount = [self segmentCount];

    // Corner case: when segmentCount == 0 and aSegment == 0, we do not return here because we still need to set the new frameSize bellow.
    if (aSegment < 0 || (segmentCount > 0 && aSegment >= segmentCount))
        return;

    var width = 0;

    if (segmentCount > 0)
    {
        // Invalidate frames for segments on the right. They will be lazily computed by -frameForSegment:.
        for (var i = aSegment; i < segmentCount; i++)
            [_segments[i] setFrame:CGRectMakeZero()];

        width = CGRectGetMaxX([self frameForSegment:(segmentCount - 1)]);
    }

    [self setFrameSize:CGSizeMake(width, CGRectGetHeight([self frame]))];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns the bounding rectangle for the specified segment.
    @param aSegment the segment to get the rectangle for
*/
- (CGRect)frameForSegment:(unsigned)aSegment
{
    var segment = [_segments objectAtIndex:aSegment],
        frame = [segment frame];

    if (CGRectEqualToRect(frame, CGRectMakeZero()))
    {
        frame = [self bezelFrameForSegment:aSegment];
        [segment setFrame:frame];
    }

    return frame;
}

- (CGRect)bezelFrameForSegment:(unsigned)aSegment
{
    var left = [self _leftOffsetForSegment:aSegment],
        top = [self currentValueForThemeAttribute:@"bezel-inset"].top,
        width = [self widthForSegment:aSegment],
        height = [self currentValueForThemeAttribute:@"min-size"].height;

    if (width == 0)
    {
        var themeState = _themeState.hasThemeState(CPThemeStateDisabled) ? _themeStates[aSegment].and(CPThemeStateDisabled) : _themeStates[aSegment],
            contentInset = [self valueForThemeAttribute:@"content-inset" inState:themeState],
            contentInsetWidth = contentInset.left + contentInset.right,

            segment = _segments[aSegment],
            label = [segment label],
            image = [segment image];

        width = (label ? [label sizeWithFont:[self font]].width : 4.0) + (image ? [image size].width : 0) + contentInsetWidth;
    }

    return CGRectMake(left, top, width, height);
}

- (CGRect)contentFrameForSegment:(unsigned)aSegment
{
    var height = [self currentValueForThemeAttribute:@"min-size"].height,
        contentInset = [self currentValueForThemeAttribute:@"content-inset"],
        width = CGRectGetWidth([self frameForSegment:aSegment]),
        left = [self _leftOffsetForSegment:aSegment];

    return CGRectMake(left + contentInset.left, contentInset.top, width - contentInset.left - contentInset.right, height - contentInset.top - contentInset.bottom);
}

- (CGSize)_minimumFrameSize
{
    // The current width is always the minimum width.
    return CGSizeMake(CGRectGetWidth([self frame]), [self currentValueForThemeAttribute:@"min-size"].height);
}

/*!
    Returns the segment that is hit by the specified point.
    @param aPoint the point to test for a segment hit
    @return the intersecting segment
*/
- (unsigned)testSegment:(CGPoint)aPoint
{
    var location = [self convertPoint:aPoint fromView:nil],
        count = [self segmentCount];

    while (count--)
        if (CGRectContainsPoint([self frameForSegment:count], aPoint))
            return count;

    if ([self segmentCount])
    {
        var adjustedLastFrame = CGRectCreateCopy([self frameForSegment:(_segments.length - 1)]);
        adjustedLastFrame.size.width = CGRectGetWidth([self bounds]) - adjustedLastFrame.origin.x;

        if (CGRectContainsPoint(adjustedLastFrame, aPoint))
            return [self segmentCount] - 1;
    }

    return -1;
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;

    [self trackSegment:anEvent];
}

// FIXME: this should be fixed way up in cpbutton/cpcontrol.
- (void)mouseUp:(CPEvent)anEvent
{
}

/*!
    Handles events for the segment
    @param anEvent the event to handle
*/
- (void)trackSegment:(CPEvent)anEvent
{
    var type = [anEvent type],
        location = [self convertPoint:[anEvent locationInWindow] fromView:nil];

    if (type == CPLeftMouseUp)
    {
        if (_trackingSegment == -1)
            return;

        if (_trackingSegment === [self testSegment:location])
        {
            if (_trackingMode == CPSegmentSwitchTrackingSelectAny)
            {
                [self setSelected:![self isSelectedForSegment:_trackingSegment] forSegment:_trackingSegment];

                // With ANY, _selectedSegment means last pressed.
                _selectedSegment = _trackingSegment;
            }
            else
                [self setSelected:YES forSegment:_trackingSegment];

            [self sendAction:[self action] to:[self target]];

            if (_trackingMode == CPSegmentSwitchTrackingMomentary)
            {
                [self setSelected:NO forSegment:_trackingSegment];

                _selectedSegment = CPNotFound;
            }
        }

        [self drawSegmentBezel:_trackingSegment highlight:NO];

        _trackingSegment = -1;

        return;
    }

    if (type == CPLeftMouseDown)
    {
        var trackingSegment = [self testSegment:location];
        if (trackingSegment > -1 && [self isEnabledForSegment:trackingSegment])
        {
            _trackingHighlighted = YES;
            _trackingSegment = trackingSegment;
            [self drawSegmentBezel:_trackingSegment highlight:YES];
        }
    }

    else if (type == CPLeftMouseDragged)
    {
        if (_trackingSegment == -1)
            return;

        var highlighted = [self testSegment:location] === _trackingSegment;

        if (highlighted != _trackingHighlighted)
        {
            _trackingHighlighted = highlighted;

            [self drawSegmentBezel:_trackingSegment highlight:_trackingHighlighted];
        }
    }

    [CPApp setTarget:self selector:@selector(trackSegment:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

- (void)setFont:(CPFont)aFont
{
    [super setFont:aFont];

    [self tile];
}

@end

var CPSegmentedControlSegmentsKey       = "CPSegmentedControlSegmentsKey",
    CPSegmentedControlSelectedKey       = "CPSegmentedControlSelectedKey",
    CPSegmentedControlSegmentStyleKey   = "CPSegmentedControlSegmentStyleKey",
    CPSegmentedControlTrackingModeKey   = "CPSegmentedControlTrackingModeKey";

@implementation CPSegmentedControl (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        var frame = [self frame],
            originalWidth = frame.size.width;

        frame.size.width = 0;

        [self setFrame:frame];

        _segments       = [aCoder decodeObjectForKey:CPSegmentedControlSegmentsKey];
        _segmentStyle   = [aCoder decodeIntForKey:CPSegmentedControlSegmentStyleKey];
        _themeStates  = [];

        if ([aCoder containsValueForKey:CPSegmentedControlSelectedKey])
            _selectedSegment = [aCoder decodeIntForKey:CPSegmentedControlSelectedKey];
        else
            _selectedSegment = CPNotFound;

        if ([aCoder containsValueForKey:CPSegmentedControlTrackingModeKey])
            _trackingMode = [aCoder decodeIntForKey:CPSegmentedControlTrackingModeKey];
        else
            _trackingMode = CPSegmentSwitchTrackingSelectOne;

        // Here we update the themeStates array for each segments to know if there are selected or not
        for (var i = 0; i < [self segmentCount]; i++)
            _themeStates[i] = [_segments[i] selected] ? CPThemeStateSelected : CPThemeStateNormal;

        [self tile];

        var thickness = [self currentValueForThemeAttribute:@"divider-thickness"],
            dividerExtraSpace = ([_segments count] - 1) * thickness,
            difference = MAX(originalWidth - [self frame].size.width - dividerExtraSpace, 0.0),
            remainingWidth = FLOOR(difference / [self segmentCount]),
            widthOfAllSegments = 0;

        // We do this in a second loop because it relies on all the themeStates being set first
        for (var i = 0; i < [self segmentCount]; i++)
        {
            var frame = [_segments[i] frame];
            frame.size.width += remainingWidth;

            widthOfAllSegments += CGRectGetWidth(frame);
        }

        // Here we handle the leftovers pixel, and we will add one pixel to each segment cell till we have the same size as the originalSize.
        // This is needed to have a perfect/same alignment between our application and xCode.
        var leftOversPixel = originalWidth - (widthOfAllSegments + dividerExtraSpace);

        // Make sure we don't make an out of range
        if (leftOversPixel < [self segmentCount] - 1)
        {
            for (var i = 0; i < leftOversPixel; i++)
            {
                [_segments[i] frame].size.width += 1;
            }
        }

        [self setFrameSize:CGSizeMake(originalWidth, CGRectGetHeight([self frame]))];
        [self tile];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_segments forKey:CPSegmentedControlSegmentsKey];
    [aCoder encodeInt:_selectedSegment forKey:CPSegmentedControlSelectedKey];
    [aCoder encodeInt:_segmentStyle forKey:CPSegmentedControlSegmentStyleKey];
    [aCoder encodeInt:_trackingMode forKey:CPSegmentedControlTrackingModeKey];
}

@end

@implementation CPSegmentedControl (BindingSupport)

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if ([self _isSelectionBinding:aBinding])
        return [_CPSegmentedControlBinder class];

    return [super _binderClassForBinding:aBinding];
}

+ (BOOL)_isSelectionBinding:(CPString)aBinding
{
    return (aBinding === CPSelectedIndexBinding || aBinding === CPSelectedLabelBinding || aBinding === CPSelectedTagBinding);
}

+ (BOOL)isBindingExclusive:(CPString)aBinding
{
    return [self _isSelectionBinding:aBinding];
}

- (void)bind:(CPString)aBinding toObject:(id)anObject withKeyPath:(CPString)aKeyPath options:(CPDictionary)options
{
    if ([[self class] _isSelectionBinding:aBinding] && _trackingMode !== CPSegmentSwitchTrackingSelectOne)
    {
        CPLog.warn("Binding " + aBinding + " needs CPSegmentSwitchTrackingSelectOne tracking mode");
        return;
    }

    [super bind:aBinding toObject:anObject withKeyPath:aKeyPath options:options];
}

- (void)_reverseSetBinding
{
    [_CPSegmentedControlBinder _reverseSetValueFromExclusiveBinderForObject:self];
}

@end

var CPSegmentedControlNoSelectionPlaceholder = "CPSegmentedControlNoSelectionPlaceholder";

@implementation _CPSegmentedControlBinder : CPBinder
{
}

- (void)_updatePlaceholdersWithOptions:(CPDictionary)options
{
    [super _updatePlaceholdersWithOptions:options];

    [self _setPlaceholder:CPSegmentedControlNoSelectionPlaceholder forMarker:CPMultipleValuesMarker isDefault:YES];
    [self _setPlaceholder:CPSegmentedControlNoSelectionPlaceholder forMarker:CPNoSelectionMarker isDefault:YES];
    [self _setPlaceholder:CPSegmentedControlNoSelectionPlaceholder forMarker:CPNotApplicableMarker isDefault:YES];
    [self _setPlaceholder:CPSegmentedControlNoSelectionPlaceholder forMarker:CPNullMarker isDefault:YES];
}

- (void)setPlaceholderValue:(id)aValue withMarker:(CPString)aMarker forBinding:(CPString)aBinding
{
    if (aValue == CPSegmentedControlNoSelectionPlaceholder)
        [_source setSelected:NO forSegment:[_source selectedSegment]];
    else
        [self setValue:aValue forBinding:aBinding];
}

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    if (aBinding == CPSelectedIndexBinding)
        [_source setSelectedSegment:aValue];
    else if (aBinding == CPSelectedTagBinding)
        [_source selectSegmentWithTag:aValue];
    else if (aBinding == CPSelectedLabelBinding)
        [_source _selectSegmentWithLabel:aValue];
}

- (id)valueForBinding:(CPString)aBinding
{
    var selectedIndex = [_source selectedSegment];

    if (aBinding == CPSelectedIndexBinding)
        return selectedIndex;
    else if (aBinding == CPSelectedTagBinding)
        return [_source tagForSegment:selectedIndex];
    else if (aBinding == CPSelectedLabelBinding)
        return [_source labelForSegment:selectedIndex];
}

@end

@implementation _CPSegmentItem : CPObject
{
    CPImage     image       @accessors;
    CPString    label       @accessors;
    CPMenu      menu        @accessors;
    BOOL        selected    @accessors;
    BOOL        enabled     @accessors;
    int         tag         @accessors;
    int         width       @accessors;

    CGRect      frame       @accessors;
}

- (id)init
{
    if (self = [super init])
    {
        image        = nil;
        label        = @"";
        menu         = nil;
        selected     = NO;
        enabled      = YES;
        tag          = -1;
        width        = 0;

        frame        = CGRectMakeZero();
    }
    return self;
}

@end

var CPSegmentItemImageKey       = "CPSegmentItemImageKey",
    CPSegmentItemLabelKey       = "CPSegmentItemLabelKey",
    CPSegmentItemMenuKey        = "CPSegmentItemMenuKey",
    CPSegmentItemSelectedKey    = "CPSegmentItemSelectedKey",
    CPSegmentItemEnabledKey     = "CPSegmentItemEnabledKey",
    CPSegmentItemTagKey         = "CPSegmentItemTagKey",
    CPSegmentItemWidthKey       = "CPSegmentItemWidthKey";

@implementation _CPSegmentItem (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        image        = [aCoder decodeObjectForKey:CPSegmentItemImageKey];
        label        = [aCoder decodeObjectForKey:CPSegmentItemLabelKey];
        menu         = [aCoder decodeObjectForKey:CPSegmentItemMenuKey];
        selected     = [aCoder decodeBoolForKey:CPSegmentItemSelectedKey];
        enabled      = [aCoder decodeBoolForKey:CPSegmentItemEnabledKey];
        tag          = [aCoder decodeIntForKey:CPSegmentItemTagKey];
        width        = [aCoder decodeFloatForKey:CPSegmentItemWidthKey];

        frame        = CGRectMakeZero();
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:image  forKey:CPSegmentItemImageKey];
    [aCoder encodeObject:label  forKey:CPSegmentItemLabelKey];
    [aCoder encodeObject:menu   forKey:CPSegmentItemMenuKey];
    [aCoder encodeBool:selected forKey:CPSegmentItemSelectedKey];
    [aCoder encodeBool:enabled  forKey:CPSegmentItemEnabledKey];
    [aCoder encodeInt:tag       forKey:CPSegmentItemTagKey];
    [aCoder encodeFloat:width   forKey:CPSegmentItemWidthKey];
}

@end
