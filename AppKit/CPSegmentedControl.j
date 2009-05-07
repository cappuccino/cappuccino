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

#include "CoreGraphics/CGGeometry.h"

/*
    @global
    @group CPSegmentSwitchTracking
*/
CPSegmentSwitchTrackingSelectOne = 0;
/*
    @global
    @group CPSegmentSwitchTracking
*/
CPSegmentSwitchTrackingSelectAny = 1;
/*
    @global
    @group CPSegmentSwitchTracking
*/
CPSegmentSwitchTrackingMomentary = 2;

/*! @class CPSegmentedControl

    This class is a horizontal button with multiple segments.
*/
@implementation CPSegmentedControl : CPControl
{
    CPArray                 _segments;
    CPArray                 _controlStates;

    int                     _selectedSegment;
    int                     _segmentStyle;
    CPSegmentSwitchTracking _trackingMode;

    unsigned                _trackingSegment;
    BOOL                    _trackingHighlighted;
}

+ (id)themedAttributes
{
    return [CPDictionary dictionaryWithObjects:[_CGInsetMakeZero(), _CGInsetMakeZero(), nil, nil, nil, nil, 1.0, 24.0]
                                       forKeys:[@"bezel-inset", @"content-inset", @"left-segment-bezel-color", @"right-segment-bezel-color", @"center-segment-bezel-color", @"divider-bezel-color", @"divider-thickness", @"default-height"]];
}

- (id)initWithFrame:(CGRect)aRect
{
    _segments = [];
    _controlStates = [];
    
    self = [super initWithFrame:aRect];
    
    if (self)
    {
        _selectedSegment = -1;
        
        _trackingMode = CPSegmentSwitchTrackingSelectOne;
    }
    
    return self;
}

/*!
    Returns the tag of the selected segment.
*/
- (int)selectedTag
{
    return _segments[_selectedSegment].tag;
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
        
    var height = CGRectGetHeight([self bounds]);
    
    if (_segments.length < aCount)
    {
        var index = _segments.length;
        
        for (; index < aCount; ++index)
        {
            _segments[index] = [[_CPSegmentItem alloc] init];
            _segments[index].frame.size.height = height;

            _controlStates[index] = CPControlStateNormal;
        }
    }
    else if (aCount < _segments.length)
    {
        var index = aCount;
        
        for (; index < _segments.length; ++index)
        {
            [_segments[index].imageView removeFromSuperview];
            [_segments[index].labelView removeFromSuperview];
            
            _segments[index] = nil;
        }
    }
    
    if (_selectedSegment < _segments.length)
        _selectedSegment = -1;
    
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
    @throws CPRangeException if <code>aSegment</code> is out of bounds
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
            if (_segments[index].selected)
                if (selected)
                    [self setSelected:NO forSegment:index];
                else
                    selected = YES;
    }
    
    else if (_trackingMode == CPSegmentSwitchTrackingMomentary)
    {
        var index = 0;
        
        for (; index < _segments.length; ++index)
            if (_segments[index].selected)
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
    @throws CPRangeException if <code>aSegment</code> is out of bounds
*/
- (void)setWidth:(float)aWidth forSegment:(unsigned)aSegment
{
    _segments[aSegment].width = aWidth;
    
    [self tileWithChangedSegment:aSegment];
}

/*!
    Returns the width for the specified segment.
    @param aSegment the segment to get the width for
    @throws CPRangeException if <code>aSegment</code> is out of bounds
*/
- (float)widthForSegment:(unsigned)aSegment
{
    return _segments[aSegment].width;
}

/*!
    Sets the image for the specified segment.
    @param anImage the image for the segment
    @param aSegment the segment to set the image on
    @throws CPRangeException if <code>aSegment</code> is out of bounds
*/
- (void)setImage:(CPImage)anImage forSegment:(unsigned)aSegment
{
    var segment = _segments[aSegment];
    
    if (!anImage)
    {
        [segment.imageView removeFromSuperview];
        
        segment.imageView = nil;
    }
    
    else
    {
        if (!segment.imageView)
        {
            segment.imageView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
            
            [self addSubview:segment.imageView];
        }
        
        [segment.imageView setImage:anImage];
        [segment.imageView setFrameSize:CGSizeMakeCopy([anImage size])];
    }
    
    segment.image = anImage;

    if (segment.width)
        [self drawSegment:aSegment highlight:NO];
    else
        [self tileWithChangedSegment:aSegment];
}

/*!
    Returns the image for the specified segment
    @param aSegment the segment to obtain the image for
    @throws CPRangeException if <code>aSegment</code> is out of bounds
*/
- (CPImage)imageForSegment:(unsigned)aSegment
{
    return _segments[aSegment].image;
}

/*!
    Sets the label for the specified segment
    @param aLabel the label for the segment
    @param aSegment the segment to label
    @throws CPRangeException if <code>aSegment</code> is out of bounds
*/
- (void)setLabel:(CPString)aLabel forSegment:(unsigned)aSegment
{
    var segment = _segments[aSegment];
    
    if (!aLabel || !aLabel.length)
    {
        [segment.labelView removeFromSuperview];
        
        segment.labelView = nil;
    }
    
    else
    {
        if (!segment.labelView)
        {
            segment.labelView = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
            
            [segment.labelView setFont:[self font]];
            
            [self addSubview:segment.labelView];
        }
        
        [segment.labelView setStringValue:aLabel];
        [segment.labelView sizeToFit];
    }
    
    _segments[aSegment].label = aLabel;
    
    if (segment.width)
        [self drawSegment:aSegment highlight:NO];
    else
        [self tileWithChangedSegment:aSegment];
}

/*!
    Returns the label for the specified segment
    @param the segment to obtain the label for
    @throws CPRangeException if <code>aSegment</code> is out of bounds
*/
- (CPString)labelForSegment:(unsigned)aSegment
{
    return _segments[aSegment].label;
}

/*!
    Sets the menu for the specified segment
    @param aMenu the menu to set
    @param aSegment the segment to set the menu on
    @throws CPRangeException if <code>aSegment</code> is out of bounds
*/
- (void)setMenu:(CPMenu)aMenu forSegment:(unsigned)aSegment
{
    _segments[aSegment].menu = aMenu;
}

/*!
    Returns the menu for the specified segment.
    @param aSegment the segment to obtain the menu for
    @throws CPRangeException if <code>aSegment</code> is out of bounds
*/
- (CPMenu)menuForSegment:(unsigned)aSegment
{
    return _segments[aSegment].menu;
}

/*!
    Sets the selection for the specified segment. If only one segment
    can be selected at a time, any other segment will be deselected.
    @param isSelected <code>YES</code> selects the segment. <code>NO</code> deselects it.
    @param aSegment the segment to set the selection for
    @throws CPRangeException if <code>aSegment</code> is out of bounds
*/
- (void)setSelected:(BOOL)isSelected forSegment:(unsigned)aSegment
{
    var segment = _segments[aSegment];
    
    // If we're already in this state, bail.
    if (segment.selected == isSelected)
        return;
    
    segment.selected = isSelected;

    _controlStates[aSegment] = isSelected ? CPControlStateSelected : CPControlStateNormal;

    // We need to do some cleanup if we only allow one selection.
    if (isSelected)
    {
        var oldSelectedSegment = _selectedSegment;
        
        _selectedSegment = aSegment;
        
        if (_trackingMode == CPSegmentSwitchTrackingSelectOne && oldSelectedSegment != aSegment && oldSelectedSegment != -1)
        {
            _segments[oldSelectedSegment].selected = NO;
            _controlStates[oldSelectedSegment] = CPControlStateNormal;

            [self drawSegmentBezel:oldSelectedSegment highlight:NO];
        }
    }
    
    if (_trackingMode != CPSegmentSwitchTrackingMomentary)
        [self drawSegmentBezel:aSegment highlight:NO];

    [self setNeedsLayout];
}

/*!
    Returns <code>YES</code> if the specified segment is selected.
    @param aSegment the segment to check for selection
    @throws CPRangeException if <code>aSegment</code> is out of bounds
*/
- (BOOL)isSelectedForSegment:(unsigned)aSegment
{
    return _segments[aSegment].selected;
}

/*!
    Enables/diables the specified segment.
    @param isEnabled <code>YES</code> enables the segment
    @param aSegment the segment to enable/disble
    @throws CPRangeException if <code>aSegment</code> is out of bounds
*/
- (void)setEnabled:(BOOL)isEnabled forSegment:(unsigned)aSegment
{
    _segments[aSegment].enabled = isEnabled;
}

/*!
    Returns <code>YES</code> if the specified segment is enabled.
    @param aSegment the segment to check
    @throws CPRangeException if <code>aSegment</code> is out of bounds
*/
- (BOOL)isEnabledForSegment:(unsigned)aSegment
{
    return _segments[aSegment].enabled;
}

/*!
    Sets a tag for the specified segment.
    @param aTag the tag to set
    @param aSegment the segment to set the tag on
*/
- (void)setTag:(int)aTag forSegment:(unsigned)aSegment
{
    _segments[aSegment].tag = aTag;
}

/*!
    Returns the tag for the specified segment.
    @param aSegment the segment to obtain the tag for
*/
- (int)tagForSegment:(unsigned)aSegment
{
    return _segments[aSegment].tag;
}

// Drawings
/*!
    Draws the specified segment bezel
    @param aSegment the segment to draw the bezel for
    @param shouldHighlight <code>YES</code> highlights the bezel
*/
- (void)drawSegmentBezel:(int)aSegment highlight:(BOOL)shouldHighlight
{
    if (shouldHighlight)
        _controlStates[aSegment] |= CPControlStateHighlighted;
    else
        _controlStates[aSegment] &= ~CPControlStateHighlighted;

    [self setNeedsLayout];
}

- (float)_leftOffsetForSegment:(unsigned)segment
{
    var bezelInset = [self currentValueForThemedAttributeName:@"bezel-inset"];

    if (segment == 0)
        return bezelInset.left;

    var thickness = [self currentValueForThemedAttributeName:@"divider-thickness"];

    return [self _leftOffsetForSegment:segment - 1] + [self widthForSegment:segment - 1] + thickness;
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    var height = [self currentValueForThemedAttributeName:@"default-height"],
        contentInset = [self currentValueForThemedAttributeName:@"content-inset"],
        bezelInset = [self currentValueForThemedAttributeName:@"bezel-inset"],
        bounds = [self bounds];

    if (aName === "left-segment-bezel")
    {
        return CGRectMake(bezelInset.left, bezelInset.top, contentInset.left, height);
    }
    else if (aName === "right-segment-bezel")
    {
        return CGRectMake(CGRectGetMaxX(bounds) - contentInset.right, bezelInset.top, contentInset.right, height);
    }
    else if (aName.substring(0, "segment-bezel".length) == "segment-bezel")
    {
        var segment = parseInt(aName.substring("segment-bezel-".length), 10),
            width = [self widthForSegment:segment],
            left = [self _leftOffsetForSegment:segment];

        if (_segments.length == 1)
            return CGRectMake(left + contentInset.left, bezelInset.top, width - contentInset.left - contentInset.right, height);
        else if (segment == 0)
            return CGRectMake(left + contentInset.left, bezelInset.top, width - contentInset.left, height);
        else if (segment == _segments.length - 1)
            return CGRectMake(left, bezelInset.top, width - contentInset.right, height);
        else
            return CGRectMake(left, bezelInset.top, width, height);
    }
    else if (aName.substring(0, "divider-bezel".length) == "divider-bezel")
    {
        var segment = parseInt(aName.substring("divider-bezel-".length), 10),
            width = [self widthForSegment:segment],
            left = [self _leftOffsetForSegment:segment],
            thickness = [self currentValueForThemedAttributeName:@"divider-thickness"];

        return CGRectMake(left + width, bezelInset.top, thickness, height);
    }

    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    return [[CPView alloc] initWithFrame:_CGRectMakeZero()];
}

- (void)layoutSubviews
{
    var leftCapColor = [self valueForThemedAttributeName:@"left-segment-bezel-color" 
                                          inControlState:_controlStates[0]];

    var leftBezelView = [self layoutEphemeralSubviewNamed:@"left-segment-bezel"
                                               positioned:CPWindowBelow
                          relativeToEphemeralSubviewNamed:nil];

    [leftBezelView setBackgroundColor:leftCapColor];

    var rightCapColor = [self valueForThemedAttributeName:@"right-segment-bezel-color" 
                                           inControlState:_controlStates[_controlStates.length - 1]];

    var rightBezelView = [self layoutEphemeralSubviewNamed:@"right-segment-bezel"
                                               positioned:CPWindowBelow
                          relativeToEphemeralSubviewNamed:nil];

    [rightBezelView setBackgroundColor:rightCapColor];

    for (var i=0, count = _controlStates.length; i<count; i++)
    {
        var bezelColor = [self valueForThemedAttributeName:@"center-segment-bezel-color" 
                                            inControlState:_controlStates[i]];

        var bezelView = [self layoutEphemeralSubviewNamed:"segment-bezel-"+i 
                                               positioned:CPWindowBelow 
                          relativeToEphemeralSubviewNamed:nil];

        [bezelView setBackgroundColor:bezelColor];

        if (i == count - 1)
            continue;

        var borderState = _controlStates[i] | _controlStates[i+1];
        
        borderState = (borderState & CPControlStateSelected & ~CPControlStateHighlighted) ? CPControlStateSelected : CPControlStateNormal;
    
        var borderColor = [self valueForThemedAttributeName:@"divider-bezel-color"
                                             inControlState:borderState];

        var borderView = [self layoutEphemeralSubviewNamed:"divider-bezel-"+i 
                                                positioned:CPWindowBelow 
                           relativeToEphemeralSubviewNamed:nil];

        [borderView setBackgroundColor:borderColor];
    }
}


/*!
    Draws the specified segment
    @param aSegment the segment to draw
    @param shouldHighlight <code>YES</code> highlights the bezel
*/
- (void)drawSegment:(int)aSegment highlight:(BOOL)shouldHighlight
{
    var segment = _segments[aSegment],
            
        imageView = segment.imageView,
        labelView = segment.labelView,
        
        frame = segment.frame,
            
        segmentX = CGRectGetMinX(frame),
        segmentWidth = CGRectGetWidth(frame),
        segmentHeight = CGRectGetHeight(frame) - 1.0;
                    
    if (imageView && labelView)
    {
        var imageViewSize = [imageView frame].size,
            labelViewSize = [labelView frame].size,
            totalHeight = imageViewSize.height + labelViewSize.height,
            labelWidth = MIN(labelViewSize.width, width),
            y = (segmentHeight - totalHeight) / 2.0;
        
        [imageView setFrameOrigin:CGPointMake(segmentX + (segmentWidth - imageViewSize.width) / 2.0, y)];
        
        if (labelWidth < labelViewSize.width)
            [labelView setFrameSize:CGSizeMake(labelWidth, labelViewSize.height)];
        
        [labelView setFrameOrigin:CGPointMake(segmentX + (segmentWidth - labelWidth) / 2.0, y + imageViewSize.height)];
    }
    else if (imageView)
    {
        var imageViewSize = [imageView frame].size;
        
        [imageView setFrameOrigin:CGPointMake(segmentX + (segmentWidth - imageViewSize.width) / 2.0, (segmentHeight - imageViewSize.height) / 2.0)];
    }
    else if (labelView)
    {
        var labelViewSize = [labelView frame].size,
            labelWidth = MIN(labelViewSize.width, segmentWidth);
        
        if (labelWidth < labelViewSize.width)
            [labelView setFrameSize:CGSizeMake(labelWidth, labelViewSize.height)];
        
        [labelView setFrameOrigin:CGPointMake(segmentX + (segmentWidth - labelWidth) / 2.0, (segmentHeight - labelViewSize.height) / 2.0)];
    }
}

- (void)tileWithChangedSegment:(unsigned)aSegment
{
    var segment = _segments[aSegment],
        segmentWidth = segment.width;
    
    if (!segmentWidth)
    {
        if (segment.labelView && segment.imageView)
            segmentWidth = MAX(CGRectGetWidth([segment.labelView frame]) , CGRectGetWidth([segment.imageView frame]));
        else if (segment.labelView)
            segmentWidth = CGRectGetWidth([segment.labelView frame]);
        else if (segment.imageView)
            segmentWidth = CGRectGetWidth([segment.imageView frame]);
    }
    
    var delta = segmentWidth - CGRectGetWidth(segment.frame);
    
    if (!delta)
        return;

    // Update Contorl Size
    var frame = [self frame];
    
    [self setFrameSize:CGSizeMake(CGRectGetWidth(frame) + delta, CGRectGetHeight(frame))];

    // Update Segment Width
    segment.frame.size.width = segmentWidth;

    // Update Following Segments Widths
    var index = aSegment + 1;
    
    for (; index < _segments.length; ++index)
    {
        _segments[index].frame.origin.x += delta;
        
        [self drawSegmentBezel:index highlight:NO];
        [self drawSegment:index highlight:NO];
    }
    
    [self drawSegmentBezel:aSegment highlight:NO];
    [self drawSegment:aSegment highlight:NO];
}

/*!
    Returns the bounding rectangle for the specified segment.
    @param aSegment the segment to get the rectangle for
*/
- (CGRect)frameForSegment:(unsigned)aSegment
{
    return _segments[aSegment].frame;
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
        if (CGRectContainsPoint(_segments[count].frame, aPoint))
            return count;
    
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
        if (CGRectContainsPoint(_segments[_trackingSegment].frame, location))
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
        _trackingHighlighted = YES;
        _trackingSegment = [self testSegment:location];

        
        [self drawSegmentBezel:_trackingSegment highlight:YES];
    }
    
    else if (type == CPLeftMouseDragged)
    {
        var highlighted = CGRectContainsPoint(_segments[_trackingSegment].frame, location);
        
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
    
    var count = _segments.length;
    
    if (!count)
        return;
    
    while (count--)
        [_segments[count].labelView setFont:aFont];
    
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
        _segments           = [aCoder decodeObjectForKey:CPSegmentedControlSegmentsKey];
        _segmentStyle       = [aCoder decodeIntForKey:CPSegmentedControlSegmentStyleKey];
        
        _controlStates = [];
        for (var i = 0; i < _segments.length; i++)
            _controlStates[i] = 0;

        if ([aCoder containsValueForKey:CPSegmentedControlSelectedKey])
            _selectedSegment = [aCoder decodeIntForKey:CPSegmentedControlSelectedKey];
        else    
            _selectedSegment = -1;
        
        if ([aCoder containsValueForKey:CPSegmentedControlTrackingModeKey])
            _trackingMode    = [aCoder decodeIntForKey:CPSegmentedControlTrackingModeKey];
        else
            _trackingMode = CPSegmentSwitchTrackingSelectOne;
        
        // HACK
        for (var i = 0; i < _segments.length; i++)
        {
            if (_segments[i].image != undefined)
                [self setImage:_segments[i].image forSegment:i];
            if (_segments[i].label != undefined)
                [self setLabel:_segments[i].label forSegment:i];
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    var actualSubviews = _subviews;

    _subviews = [];
    
    [super encodeWithCoder:aCoder];

    _subviews = actualSubviews;
    
    [aCoder encodeObject:_segments forKey:CPSegmentedControlSegmentsKey];
    [aCoder encodeInt:_selectedSegment forKey:CPSegmentedControlSelectedKey];
    [aCoder encodeInt:_segmentStyle forKey:CPSegmentedControlSegmentStyleKey];
    [aCoder encodeInt:_trackingMode forKey:CPSegmentedControlTrackingModeKey];
}

@end


@implementation _CPSegmentItem : CPObject
{
    CPImage     image;
    CPString    label;
    CPMenu      menu;
    BOOL        selected;
    BOOL        enabled;
    int         tag;

    int         width;
    CPView      labelView;
    CPView      imageView;
    CPRect      frame;
}

- (id)init
{
    if (self = [super init])
    {
        image       = nil;
        label       = @"";
        menu        = nil;
        selected    = NO;
        enabled     = NO;
        tag         = 0;
        
        labelView   = nil;
        imageView   = nil;
        
        width       = 0;
        frame       = CGRectMakeZero();
    }
    return self;
}

@end

var CPSegmentItemImageKey       = "CPSegmentItemImageKey",
    CPSegmentItemLabelKey       = "CPSegmentItemLabelKey",
    CPSegmentItemMenuKey        = "CPSegmentItemMenuKey",
    CPSegmentItemSelectedKey    = "CPSegmentItemSelectedKey",
    CPSegmentItemEnabledKey     = "CPSegmentItemEnabledKey",
    CPSegmentItemTagKey         = "CPSegmentItemTagKey";

@implementation _CPSegmentItem (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        image       = [aCoder decodeObjectForKey:CPSegmentItemImageKey];
        label       = [aCoder decodeObjectForKey:CPSegmentItemLabelKey];
        menu        = [aCoder decodeObjectForKey:CPSegmentItemMenuKey];
        selected    = [aCoder decodeBoolForKey:CPSegmentItemSelectedKey];
        enabled     = [aCoder decodeBoolForKey:CPSegmentItemEnabledKey];
        tag         = [aCoder decodeIntForKey:CPSegmentItemTagKey];
        
        labelView   = nil;
        imageView   = nil;
        
        width       = 0;
        frame       = CGRectMakeZero();
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
}

@end

