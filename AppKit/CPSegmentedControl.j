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

@global CPApp

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
    CPArray                 _segments;
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
            @"default-height": 24.0,
        };
}

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

- (id)initWithFrame:(CGRect)aRect
{
    _segments = [];
    _themeStates = [];

    self = [super initWithFrame:aRect];

    if (self)
    {
        _selectedSegment = -1;

        _trackingMode = CPSegmentSwitchTrackingSelectOne;
    }

    return self;
}

- (void)bind:(CPString)aBinding toObject:(id)anObject withKeyPath:(CPString)aKeyPath options:(CPDictionary)options
{
    if ([[self class] _isSelectionBinding:aBinding] && _trackingMode !== CPSegmentSwitchTrackingSelectOne)
        CPLog.warn("Binding " + aBinding + " needs CPSegmentSwitchTrackingSelectOne tracking mode");
    else
        [super bind:aBinding toObject:anObject withKeyPath:aKeyPath options:options];
}

- (void)_reverseSetBinding
{
    [_CPSegmentedControlBinder reverseSetValueForObject:self];
}

/*!
    Returns the tag of the selected segment.
*/
- (int)selectedTag
{
    return [_segments[_selectedSegment] tag];
}

// Specifying the number of segments
/*!
    Sets the number of segments in the button.
    @param aCount the number of segments on the button
*/
- (void)setSegmentCount:(unsigned)aCount
{
    if (_segments.length == aCount)
        return;

    var height = CGRectGetHeight([self bounds]),
        dividersBefore = MAX(0, _segments.length - 1),
        dividersAfter = MAX(0, aCount - 1);

    if (_segments.length < aCount)
    {
        for (var index = _segments.length; index < aCount; ++index)
        {
            _segments[index] = [[_CPSegmentItem alloc] init];
            _themeStates[index] = CPThemeStateNormal;
        }
    }
    else if (aCount < _segments.length)
    {
        _segments.length = aCount;
        _themeStates.length = aCount;
    }

    if (_selectedSegment >= _segments.length)
        _selectedSegment = -1;

    var thickness = [self currentValueForThemeAttribute:@"divider-thickness"],
        frame = [self frame],
        widthOfAllSegments = 0,
        dividerExtraSpace = ([_segments count] - 1) * thickness;

    for (var i = 0; i < [_segments count]; i++)
        widthOfAllSegments += [_segments[i] width];

    [self setFrameSize:CGSizeMake(widthOfAllSegments + dividerExtraSpace, frame.size.height)];

    [self tileWithChangedSegment:0];
}

/*!
    Returns the number of segments in the button.
*/
- (unsigned)segmentCount
{
    return _segments.length;
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

    for (; index < _segments.length; ++index)
        if (_segments[index].tag == aTag)
        {
            [self setSelectedSegment:index];

            return YES;
        }

    return NO;
}

- (BOOL)_selectSegmentWithLabel:(CPString)aLabel
{
    var index = 0;

    for (; index < _segments.length; ++index)
        if (_segments[index].label == aLabel)
        {
            [self setSelectedSegment:index];

            return YES;
        }

    return NO;
}

// Specifying Tracking Mode

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

        for (; index < _segments.length; ++index)
            if ([_segments[index] selected])
                if (selected)
                    [self setSelected:NO forSegment:index];
                else
                    selected = YES;
    }

    else if (_trackingMode == CPSegmentSwitchTrackingMomentary)
    {
        var index = 0;

        for (; index < _segments.length; ++index)
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
    [_segments[aSegment] setWidth:aWidth];
    [self tileWithChangedSegment:aSegment];
}

/*!
    Returns the width for the specified segment.
    @param aSegment the segment to get the width for
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (float)widthForSegment:(unsigned)aSegment
{
    return [_segments[aSegment] width];
}

/*!
    Sets the image for the specified segment.
    @param anImage the image for the segment
    @param aSegment the segment to set the image on
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (void)setImage:(CPImage)anImage forSegment:(unsigned)aSegment
{
    [_segments[aSegment] setImage:anImage];

    [self tileWithChangedSegment:aSegment];
}

/*!
    Returns the image for the specified segment
    @param aSegment the segment to obtain the image for
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (CPImage)imageForSegment:(unsigned)aSegment
{
    return [_segments[aSegment] image];
}

/*!
    Sets the label for the specified segment
    @param aLabel the label for the segment
    @param aSegment the segment to label
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (void)setLabel:(CPString)aLabel forSegment:(unsigned)aSegment
{
    [_segments[aSegment] setLabel:aLabel];

    [self tileWithChangedSegment:aSegment];
}

/*!
    Returns the label for the specified segment
    @param the segment to obtain the label for
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (CPString)labelForSegment:(unsigned)aSegment
{
    return [_segments[aSegment] label];
}

/*!
    Sets the menu for the specified segment
    @param aMenu the menu to set
    @param aSegment the segment to set the menu on
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (void)setMenu:(CPMenu)aMenu forSegment:(unsigned)aSegment
{
    [_segments[aSegment] setMenu:aMenu];
}

/*!
    Returns the menu for the specified segment.
    @param aSegment the segment to obtain the menu for
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (CPMenu)menuForSegment:(unsigned)aSegment
{
    return [_segments[aSegment] menu];
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
    var segment = _segments[aSegment];

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

        if (_trackingMode == CPSegmentSwitchTrackingSelectOne && oldSelectedSegment != aSegment && oldSelectedSegment != -1)
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
    return [_segments[aSegment] selected];
}

/*!
    Enables/disables the specified segment.
    @param isEnabled \c YES enables the segment
    @param aSegment the segment to enable/disable
    @throws CPRangeException if \c aSegment is out of bounds
*/
- (void)setEnabled:(BOOL)shouldBeEnabled forSegment:(unsigned)aSegment
{
    if ([_segments[aSegment] enabled] === shouldBeEnabled)
        return;

    [_segments[aSegment] setEnabled:shouldBeEnabled];

    if (shouldBeEnabled)
        _themeStates[aSegment] = CPThemeState.subtractThemeStates(_themeStates[aSegment], CPThemeStateDisabled);
    else
        _themeStates[aSegment] = CPThemeState(_themeStates[aSegment], CPThemeStateDisabled);

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
    return [_segments[aSegment] enabled];
}

/*!
    Sets a tag for the specified segment.
    @param aTag the tag to set
    @param aSegment the segment to set the tag on
*/
- (void)setTag:(int)aTag forSegment:(unsigned)aSegment
{
    [_segments[aSegment] setTag:aTag];
}

/*!
    Returns the tag for the specified segment.
    @param aSegment the segment to obtain the tag for
*/
- (int)tagForSegment:(unsigned)aSegment
{
    return [_segments[aSegment] tag];
}

// Drawings
/*!
    Draws the specified segment bezel
    @param aSegment the segment to draw the bezel for
    @param shouldHighlight \c YES highlights the bezel
*/
- (void)drawSegmentBezel:(int)aSegment highlight:(BOOL)shouldHighlight
{
    if (shouldHighlight)
        _themeStates[aSegment] = CPThemeState(_themeStates[aSegment], CPThemeStateHighlighted);
    else
        _themeStates[aSegment] = CPThemeState.subtractThemeStates(_themeStates[aSegment], CPThemeStateHighlighted);

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (float)_leftOffsetForSegment:(unsigned)segment
{
    var bezelInset = [self currentValueForThemeAttribute:@"bezel-inset"];

    if (segment == 0)
        return bezelInset.left;

    var thickness = [self currentValueForThemeAttribute:@"divider-thickness"];

    return [self _leftOffsetForSegment:segment - 1] + [self widthForSegment:segment - 1] + thickness;
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
    var height = [self currentValueForThemeAttribute:@"default-height"],
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
            frame = CGRectCreateCopy([_segments[segment] frame]);

        if (segment === 0)
        {
            frame.origin.x += contentInset.left;
            frame.size.width -= contentInset.left;
        }

        if (segment === _segments.length - 1)
            frame.size.width = CGRectGetWidth([self bounds]) - contentInset.right - frame.origin.x;

        return frame;
    }
    else if (aName.indexOf("divider-bezel") === 0)
    {
        var segment = parseInt(aName.substring("divider-bezel-".length), 10),
            width = [self widthForSegment:segment],
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
    if (_segments.length <= 0)
        return;

    var themeState = _themeStates[0],
        isDisabled = [self hasThemeState:CPThemeStateDisabled];

    themeState = isDisabled ? CPThemeState(themeState, CPThemeStateDisabled) : themeState;

    var leftCapColor = [self valueForThemeAttribute:@"left-segment-bezel-color"
                                            inState:themeState],

        leftBezelView = [self layoutEphemeralSubviewNamed:@"left-segment-bezel"
                                               positioned:CPWindowBelow
                          relativeToEphemeralSubviewNamed:nil];

    [leftBezelView setBackgroundColor:leftCapColor];

    var themeState = _themeStates[_themeStates.length - 1];

    themeState = isDisabled ? CPThemeState(themeState, CPThemeStateDisabled) : themeState;

    var rightCapColor = [self valueForThemeAttribute:@"right-segment-bezel-color"
                                             inState:themeState],

        rightBezelView = [self layoutEphemeralSubviewNamed:@"right-segment-bezel"
                                               positioned:CPWindowBelow
                          relativeToEphemeralSubviewNamed:nil];

    [rightBezelView setBackgroundColor:rightCapColor];

    for (var i = 0, count = _themeStates.length; i < count; i++)
    {
        var themeState = _themeStates[i];

        themeState = isDisabled ? CPThemeState(themeState, CPThemeStateDisabled) : themeState;

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

        var borderState = CPThemeState(_themeStates[i], _themeStates[i + 1]);

        borderState = (borderState.hasThemeState(CPThemeStateSelected) && !borderState.hasThemeState(CPThemeStateHighlighted)) ? CPThemeStateSelected : CPThemeStateNormal;

        if (_themeState.hasThemeState(CPThemeStateDisabled))
            borderState = CPThemeState(borderState, CPThemeStateDisabled);

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

- (void)tileWithChangedSegment:(unsigned)aSegment
{
    if (aSegment >= _segments.length)
        return;

    var segment = _segments[aSegment],
        segmentWidth = [segment width],
        themeState = _themeState.hasThemeState(CPThemeStateDisabled) ? CPThemeState(_themeStates[aSegment], CPThemeStateDisabled) : _themeStates[aSegment];
        contentInset = [self valueForThemeAttribute:@"content-inset" inState:themeState],
        font = [self font];

    if (!segmentWidth)
    {
        if ([segment image] && [segment label])
            segmentWidth = [[segment label] sizeWithFont:font].width + [[segment image] size].width + contentInset.left + contentInset.right;
        else if (segment.image)
            segmentWidth = [[segment image] size].width + contentInset.left + contentInset.right;
        else if (segment.label)
            segmentWidth = [[segment label] sizeWithFont:font].width + contentInset.left + contentInset.right;
        else
            segmentWidth = 0.0;
    }

    var delta = segmentWidth - CGRectGetWidth([segment frame]);

    if (!delta)
    {
        [self setNeedsLayout];
        [self setNeedsDisplay:YES];

        return;
    }

    // Update control size
    var frame = [self frame];

    [self setFrameSize:CGSizeMake(CGRectGetWidth(frame) + delta, CGRectGetHeight(frame))];

    // Update segment width
    [segment setWidth:segmentWidth];
    [segment setFrame:[self frameForSegment:aSegment]];

    // Update following segments widths
    var index = aSegment + 1;

    for (; index < _segments.length; ++index)
    {
        [_segments[index] frame].origin.x += delta;

        [self drawSegmentBezel:index highlight:NO];
        [self drawSegment:index highlight:NO];
    }

    [self drawSegmentBezel:aSegment highlight:NO];
    [self drawSegment:aSegment highlight:NO];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns the bounding rectangle for the specified segment.
    @param aSegment the segment to get the rectangle for
*/
- (CGRect)frameForSegment:(unsigned)aSegment
{
    return [self bezelFrameForSegment:aSegment];
}

- (CGRect)bezelFrameForSegment:(unsigned)aSegment
{
    var height = [self currentValueForThemeAttribute:@"default-height"],
        bezelInset = [self currentValueForThemeAttribute:@"bezel-inset"],
        width = [self widthForSegment:aSegment],
        left = [self _leftOffsetForSegment:aSegment];

    return CGRectMake(left, bezelInset.top, width, height);
}

- (CGRect)contentFrameForSegment:(unsigned)aSegment
{
    var height = [self currentValueForThemeAttribute:@"default-height"],
        contentInset = [self currentValueForThemeAttribute:@"content-inset"],
        width = [self widthForSegment:aSegment],
        left = [self _leftOffsetForSegment:aSegment];

    return CGRectMake(left + contentInset.left, contentInset.top, width - contentInset.left - contentInset.right, height - contentInset.top - contentInset.bottom);
}

/*!
    Returns the segment that is hit by the specified point.
    @param aPoint the point to test for a segment hit
    @return the intersecting segment
*/
- (unsigned)testSegment:(CGPoint)aPoint
{
    var location = [self convertPoint:aPoint fromView:nil],
        count = _segments.length;

    while (count--)
        if (CGRectContainsPoint([_segments[count] frame], aPoint))
            return count;

    if (_segments.length)
    {
        var adjustedLastFrame = CGRectCreateCopy([_segments[_segments.length - 1] frame]);
        adjustedLastFrame.size.width = CGRectGetWidth([self bounds]) - adjustedLastFrame.origin.x;

        if (CGRectContainsPoint(adjustedLastFrame, aPoint))
            return _segments.length - 1;
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

                _selectedSegment = -1;
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

    [self tileWithChangedSegment:0];
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
            _selectedSegment = -1;

        if ([aCoder containsValueForKey:CPSegmentedControlTrackingModeKey])
            _trackingMode = [aCoder decodeIntForKey:CPSegmentedControlTrackingModeKey];
        else
            _trackingMode = CPSegmentSwitchTrackingSelectOne;

        // HACK

        for (var i = 0; i < _segments.length; i++)
        {
            _themeStates[i] = [_segments[i] selected] ? CPThemeStateSelected : CPThemeStateNormal;
        }

        // We do this in a second loop because it relies on all the themeStates being set first
        for (var i = 0; i < _segments.length; i++)
        {
            [self tileWithChangedSegment:i];
        }

        var difference = MAX(originalWidth - [self frame].size.width, 0.0),
            remainingWidth = FLOOR(difference / _segments.length);

        for (var i = 0; i < _segments.length; i++)
            [self setWidth:[_segments[i] width] + remainingWidth forSegment:i];

        [self tileWithChangedSegment:0];
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

var CPSegmentedControlBindersMap = {},
    CPSegmentedControlNoSelectionPlaceholder = "CPSegmentedControlNoSelectionPlaceholder";

@implementation _CPSegmentedControlBinder : CPBinder
{
    CPString _selectionBinding @accessors(readonly, getter=selectionBinding);
}

+ (void)reverseSetValueForObject:(id)aSource
{
    var binder = CPSegmentedControlBindersMap[[aSource UID]];
    [binder reverseSetValueFor:[binder selectionBinding]];
}

- (id)initWithBinding:(CPString)aBinding name:(CPString)aName to:(id)aDestination keyPath:(CPString)aKeyPath options:(CPDictionary)options from:(id)aSource
{
    self = [super initWithBinding:aBinding name:aName to:aDestination keyPath:aKeyPath options:options from:aSource];

    if (self)
    {
        CPSegmentedControlBindersMap[[aSource UID]] = self;
        _selectionBinding = aName;
    }

    return self;
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
