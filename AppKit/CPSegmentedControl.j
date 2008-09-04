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

import <Foundation/CPArray.j>

import "CPControl.j"


CPSegmentSwitchTrackingSelectOne = 0;
CPSegmentSwitchTrackingSelectAny = 1;
CPSegmentSwitchTrackingMomentary = 2;

@implementation CPSegmentedControl : CPControl
{
    unsigned                _segmentCount;
    
    CPArray                 _segments;
    CPArray                 _selectedSegment;
    
    CPSegmentSwitchTracking _trackingMode;
    unsigned                _trackingSegment;
    BOOL                    _trackingHighlighted;
}

- (id)initWithFrame:(CGRect)aRect
{
    self = [super initWithFrame:aRect];
    
    if (self)
    {
        _segments = [];
        _selectedSegment = -1;
        
        _segmentCount = 0;
        
        _trackingMode = CPSegmentSwitchTrackingSelectOne;
    }
    
    return self;
}

- (int)selectedTag
{
    return _segments[_selectedSegment].tag;
}

// Specifying the number of segments

- (void)setSegmentCount:(unsigned)aCount
{
    if (_segmentCount == aCount)
        return;
        
    var height = CGRectGetHeight([self bounds]);
    
    if (_segmentCount < aCount)
    {
        var index = _segmentCount;
        
        for (; index < aCount; ++index)
        {
            _segments[index] = _CPSegmentMake();
            _segments[index].frame.size.height = height;
        }
    }
    else if (aCount < _segmentCount)
    {
        var index = aCount;
        
        for (; index < _segmentCount; ++index)
        {
            [_segments[index].imageView removeFromSuperview];
            [_segments[index].labelView removeFromSuperview];
            
            _segments[index] = nil;
        }
    }
    
    _segmentCount = aCount;
    
    if (_selectedSegment < _segmentCount)
        _selectedSegment = -1;
    
    [self tileWithChangedSegment:0];
}

- (unsigned)segmentCount
{
    return _segmentCount;
}

// Specifying Selected Segment

- (void)setSelectedSegment:(unsigned)aSegment
{
    [self setSelected:YES forSegment:aSegment];
}

- (unsigned)selectedSegment
{
    return _selectedSegment;
}

- (BOOL)selectSegmentWithTag:(int)aTag
{
    var index = 0;
    
    for (; index < _segmentCount; ++index)
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
        
        for (; index < _segmentCount; ++index)
            if (_segments[index].selected)
                if (selected)
                    [self setSelected:NO forSegment:index];
                else
                    selected = YES;
    }
    
    else if (_trackingMode == CPSegmentSwitchTrackingMomentary)
    {
        var index = 0;
        
        for (; index < _segmentCount; ++index)
            if (_segments[index].selected)
                [self setSelected:NO forSegment:index];
    }
}

- (CPSegmetnSwitchTracking)trackingMode
{
    return _trackingMode;
}

// Working with Individual Segments

- (void)setWidth:(float)aWidth forSegment:(unsigned)aSegment
{
    _segments[aSegment].width = aWidth;
    
    [self tileWithChangedSegment:aSegment];
}

- (float)widthForSegment:(unsigned)aSegment
{
    return _segments[aSegment].width;
}

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

- (CPImage)imageForSegment:(unsigned)aSegment
{
    return _segments[aSegment].image;
}

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

- (CPImage)labelForSegment:(unsigned)aSegment
{
    return _segments[aSegment].label;
}

- (void)setMenu:(CPMenu)aMenu forSegment:(unsigned)aSegment
{
    _segments[aSegment].menu = aMenu;
}

- (CPImage)menuForSegment:(unsigned)aSegment
{
    return _segments[aSegment].menu;
}

- (void)setSelected:(BOOL)isSelected forSegment:(unsigned)aSegment
{
    // FIXME: EXCEPTION REQUIRED
    if (aSegment < 0 || aSegment >= _segments.length)
        return;
        
    var segment = _segments[aSegment];
    
    // If we're already in this state, bail.
    if (segment.selected == isSelected)
        return;
    
    segment.selected = isSelected;

    // We need to do some cleanup if we only allow one selection.
    if (isSelected)
    {
        var oldSelectedSegment = _selectedSegment;
        
        _selectedSegment = aSegment;
        
        if (_trackingMode == CPSegmentSwitchTrackingSelectOne && oldSelectedSegment != aSegment && oldSelectedSegment != -1)
        {
            _segments[oldSelectedSegment].selected = NO;

            [self drawSegmentBezel:oldSelectedSegment highlight:NO];
        }
    }
    
    if (_trackingMode != CPSegmentSwitchTrackingMomentary)
        [self drawSegmentBezel:aSegment highlight:NO];
}

- (CPImage)isSelectedForSegment:(unsigned)aSegment
{
    return _segments[aSegment].selected;
}

- (void)setEnabled:(BOOL)isEnabled forSegment:(unsigned)aSegment
{
    _segments[aSegment].enabled = isEnabled;
}

- (CPImage)isEnabledForSegment:(unsigned)aSegment
{
    return _segments[aSegment].enabled;
}

- (void)setTag:(int)aTag forSegment:(unsigned)aSegment
{
    _segments[aSegment].tag = aTag;
}

- (int)tagForSegment:(unsigned)aSegment
{
    return _segments[aSegment].tag;
}

// Drawings

- (void)drawSegmentBezel:(int)aSegment highlgiht:(BOOL)shouldHighlight
{
}

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
    
    for (; index < _segmentCount; ++index)
    {
        _segments[index].frame.origin.x += delta;
        
        [self drawSegmentBezel:index highlight:NO];
        [self drawSegment:index highlight:NO];
    }
    
    [self drawSegmentBezel:aSegment highlight:NO];
    [self drawSegment:aSegment highlight:NO];
}

- (CGRect)frameForSegment:(unsigned)aSegment
{
    return _segments[aSegment].frame;
}

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
    
    var count = _segmentCount;
    
    if (!count)
        return;
    
    while (count--)
        [_segments[count].labelView setFont:aFont];
    
    [self tileWithChangedSegment:0];
}

@end

var _CPSegmentMake = function()
{
    return { width:0, image:nil, label:@"", menu:nil, selected:NO, enabled:NO, tag:0, labelView:nil, imageView:nil, frame:CGRectMakeZero() }
}
