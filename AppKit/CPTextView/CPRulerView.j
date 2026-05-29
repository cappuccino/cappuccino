/*
 *  CPRulerView.j
 *  AppKit
 *
 *  Created by Daniel Boehringer on 11/01/2014
 *  Copyright Daniel Boehringer 2014.
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
@import "CPView.j"
@import "CPTextField.j"
@import "CPColor.j"
@import "CPFont.j"

// Orientations matching AppKit standards
// typedef enum CPRulerOrientation
CPHorizontalRuler = 0,
CPVerticalRuler = 1,
CPRulerOrientationHorizontal = 0,
CPRulerOrientationVertical = 1

@class CPRulerView;


// MARK: - CPRulerMarker (Interactive High-Res DOM Handle)

@implementation CPRulerMarker : CPView
{
    CPRulerView         _rulerView              @accessors(readonly, property=rulerView);
    float               _imageValue             @accessors(property=imageValue);
    id                  _representedObject     @accessors(property=representedObject);
    CPTextField         _label;
}

- (id)initWithRulerView:(CPRulerView)aRulerView markerLocation:(float)aLocation imageValue:(float)anImageValue representedObject:(id)anObject
{
    // Render a crisp, resizable 12x12 container for the Unicode indicator
    if (self = [super initWithFrame:CGRectMake(0, 0, 12, 12)])
    {
        _rulerView = aRulerView;
        _imageValue = anImageValue;
        _representedObject = anObject;
        
        // Beautiful, razor-sharp upward-pointing triangle for high-res screens
        _label = [[CPTextField alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
        [_label setStringValue:@"▲"]; 
        [_label setFont:[CPFont systemFontOfSize:10.0]];
        [_label setTextColor:[CPColor colorWithWhite:0.2 alpha:1.0]];
        [_label setAlignment:CPCenterTextAlignment];
        [self addSubview:_label];
    }
    return self;
}

@end


// MARK: - CPRulerView (Pure DOM + Interactive Engine)

@implementation CPRulerView : CPView
{
    CPScrollView        _scrollView             @accessors(property=scrollView);
    CPRulerOrientation  _orientation            @accessors(property=orientation);
    CPView              _clientView             @accessors(property=clientView);
    
    float               _ruleThickness          @accessors(property=ruleThickness);
    float               _reservedThicknessForMarkers;
    CPArray             _markers;

    // Dragger variables
    CPRulerMarker       _draggingMarker;
    CGPoint             _dragStartPoint;
    float               _dragStartLocation;
}

- (id)initWithScrollView:(CPScrollView)aScrollView orientation:(CPRulerOrientation)anOrientation
{
    if (self = [super initWithFrame:CGRectMakeZero()])
    {
        _scrollView = aScrollView;
        _orientation = anOrientation;
        _clientView = [aScrollView documentView];
        
        _ruleThickness = (anOrientation === CPHorizontalRuler) ? 16.0 : 24.0;
        _reservedThicknessForMarkers = 0.0;
        _markers = [];
        
        [self setBackgroundColor:[CPColor colorWithWhite:0.96 alpha:1.0]];
    }
    return self;
}

- (void)setFrame:(CGRect)aFrame
{
    [super setFrame:aFrame];
    [self updateRuler];
}

// Markers registration
- (void)addMarker:(CPRulerMarker)aMarker
{
    if ([_markers containsObject:aMarker])
        return;
        
    [_markers addObject:aMarker];
    [self addSubview:aMarker];
    [self _positionMarker:aMarker];
}

- (void)removeMarker:(CPRulerMarker)aMarker
{
    [_markers removeObject:aMarker];
    [aMarker removeFromSuperview];
}

- (void)setMarkers:(CPArray)newMarkers
{
    for (var i = 0; i < [_markers count]; i++)
        [[_markers objectAtIndex:i] removeFromSuperview];
    
    _markers = [newMarkers mutableCopy];
    
    for (var i = 0; i < [_markers count]; i++)
    {
        var marker = [_markers objectAtIndex:i];
        [self addSubview:marker];
        [self _positionMarker:marker];
    }
}

- (CPRulerMarker)_markerAtPoint:(CGPoint)aPoint
{
    for (var i = 0; i < [_markers count]; i++)
    {
        var marker = [_markers objectAtIndex:i];
        if (CGRectContainsPoint([marker frame], aPoint))
            return marker;
    }
    return nil;
}

- (void)_positionMarker:(CPRulerMarker)aMarker
{
    if (!_scrollView)
        return;

    var clipView = [_scrollView contentView],
        scrollPoint = [clipView bounds].origin,
        isHorizontal = (_orientation === CPHorizontalRuler || _orientation === CPRulerOrientationHorizontal),
        rulerHeight = CGRectGetHeight([self bounds]),
        rulerWidth = CGRectGetWidth([self bounds]),
        markerLocation = [aMarker imageValue];

    if (isHorizontal)
    {
        var x = markerLocation - scrollPoint.x - 6.0, // Center the 12px wide marker
            y = rulerHeight - 11.0;                  // Sit perfectly above bottom border
            
        [aMarker setFrame:CGRectMake(x, y, 12.0, 12.0)];
    }
    else
    {
        var x = rulerWidth - 11.0,
            y = markerLocation - scrollPoint.y - 6.0;
            
        [aMarker setFrame:CGRectMake(x, y, 12.0, 12.0)];
    }
}


#pragma mark -
#pragma mark Interaction Handlers

- (void)mouseDown:(CPEvent)anEvent
{
    var locationInWindow = [anEvent locationInWindow],
        localPoint = [self convertPoint:locationInWindow fromView:nil],
        clipView = [_scrollView contentView],
        scrollPoint = [clipView bounds].origin,
        isHorizontal = (_orientation === CPHorizontalRuler || _orientation === CPRulerOrientationHorizontal);

    var rulerLocation = isHorizontal ? (localPoint.x + scrollPoint.x) : (localPoint.y + scrollPoint.y);

    // 1. Check if clicked an existing marker
    var clickedMarker = [self _markerAtPoint:localPoint];
    if (clickedMarker)
    {
        _draggingMarker = clickedMarker;
        _dragStartPoint = localPoint;
        _dragStartLocation = [_draggingMarker imageValue];
    }
    // 2. Otherwise, create a new marker dynamically where the user clicked
    else
    {
        var newMarker = [[CPRulerMarker alloc] initWithRulerView:self 
                                                  markerLocation:rulerLocation 
                                                      imageValue:rulerLocation 
                                               representedObject:nil];
        [self addMarker:newMarker];
        
        _draggingMarker = newMarker;
        _dragStartPoint = localPoint;
        _dragStartLocation = rulerLocation;
        
        // NOTIFY CLIENT OF THE NEW MARKER ADDITION
        var client = [self clientView];
        if (client && [client respondsToSelector:@selector(rulerView:didAddMarker:)])
            [client rulerView:self didAddMarker:newMarker];
    }
}

- (void)mouseDragged:(CPEvent)anEvent
{
    if (!_draggingMarker)
        return;

    var locationInWindow = [anEvent locationInWindow],
        localPoint = [self convertPoint:locationInWindow fromView:nil],
        isHorizontal = (_orientation === CPHorizontalRuler || _orientation === CPRulerOrientationHorizontal);

    var delta = isHorizontal ? (localPoint.x - _dragStartPoint.x) : (localPoint.y - _dragStartPoint.y),
        newLocation = _dragStartLocation + delta;

    if (newLocation < 0) newLocation = 0;

    [_draggingMarker setImageValue:newLocation];
    [self _positionMarker:_draggingMarker];
    
    // Notify the CPTextView that the marker coordinates shifted
    var client = [self clientView];
    if (client && [client respondsToSelector:@selector(rulerView:didMoveMarker:)])
        [client rulerView:self didMoveMarker:_draggingMarker];
}

- (void)mouseUp:(CPEvent)anEvent
{
    if (!_draggingMarker)
        return;

    var localPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        isHorizontal = (_orientation === CPHorizontalRuler || _orientation === CPRulerOrientationHorizontal),
        
        // If dragged more than 15 pixels off the ruler, delete the marker
        draggedOff = isHorizontal ? (localPoint.y < -15 || localPoint.y > CGRectGetHeight([self bounds]) + 15)
                                  : (localPoint.x < -15 || localPoint.x > CGRectGetWidth([self bounds]) + 15);

    if (draggedOff)
    {
        var client = [self clientView];
        if (client && [client respondsToSelector:@selector(rulerView:didRemoveMarker:)])
            [client rulerView:self didRemoveMarker:_draggingMarker];

        [self removeMarker:_draggingMarker];
    }
    
    _draggingMarker = nil;
}


#pragma mark -
#pragma mark DOM Layout Builder

- (void)updateRuler
{
    // Wipe subviews to redraw the dynamic visible tick lines/numbers
    [self setSubviews:@[]];

    if (!_scrollView)
        return;

    var clipView = [_scrollView contentView],
        scrollBounds = [clipView bounds],
        scrollPoint = scrollBounds.origin,
        visibleSize = scrollBounds.size,
        isHorizontal = (_orientation === CPHorizontalRuler || _orientation === CPRulerOrientationHorizontal);

    if (isHorizontal)
    {
        var start = Math.floor(scrollPoint.x / 10) * 10,
            end = scrollPoint.x + visibleSize.width,
            rulerHeight = CGRectGetHeight([self bounds]);

        // Draw solid horizontal bottom border (pure, razor-sharp CSS DOM view)
        var bottomBorder = [[CPView alloc] initWithFrame:CGRectMake(0, rulerHeight - 1, visibleSize.width, 1)];
        [bottomBorder setBackgroundColor:[CPColor colorWithWhite:0.75 alpha:1.0]];
        [self addSubview:bottomBorder];

        for (var val = start; val <= end; val += 10)
        {
            if (val < 0) continue;

            var screenX = val - scrollPoint.x,
                isMajor = (val % 50 === 0),
                tickHeight = isMajor ? 8.0 : 4.0,
                tickY = rulerHeight - tickHeight - 1.0;

            // Tick mark CSS line view
            var tick = [[CPView alloc] initWithFrame:CGRectMake(screenX, tickY, 1.0, tickHeight)];
            [tick setBackgroundColor:[CPColor colorWithWhite:0.65 alpha:1.0]];
            [self addSubview:tick];

            // Unit label
            if (isMajor)
            {
                var label = [[CPTextField alloc] initWithFrame:CGRectMake(screenX - 20.0, 1.0, 40.0, 12.0)];
                [label setStringValue:[CPString stringWithFormat:@"%d", val]];
                [label setFont:[CPFont systemFontOfSize:8.0]];
                [label setTextColor:[CPColor colorWithWhite:0.4 alpha:1.0]];
                [label setAlignment:CPCenterTextAlignment];
                [self addSubview:label];
            }
        }
    }
    else
    {
        // Vertical Ruler
        var start = Math.floor(scrollPoint.y / 10) * 10,
            end = scrollPoint.y + visibleSize.height,
            rulerWidth = CGRectGetWidth([self bounds]);

        // Draw solid vertical right border (pure DOM)
        var rightBorder = [[CPView alloc] initWithFrame:CGRectMake(rulerWidth - 1, 0, 1, visibleSize.height)];
        [rightBorder setBackgroundColor:[CPColor colorWithWhite:0.75 alpha:1.0]];
        [self addSubview:rightBorder];

        for (var val = start; val <= end; val += 10)
        {
            if (val < 0) continue;

            var screenY = val - scrollPoint.y,
                isMajor = (val % 50 === 0),
                tickWidth = isMajor ? 8.0 : 4.0,
                tickX = rulerWidth - tickWidth - 1.0;

            // Tick mark CSS line view
            var tick = [[CPView alloc] initWithFrame:CGRectMake(tickX, screenY, tickWidth, 1.0)];
            [tick setBackgroundColor:[CPColor colorWithWhite:0.65 alpha:1.0]];
            [self addSubview:tick];

            // Unit label
            if (isMajor)
            {
                var label = [[CPTextField alloc] initWithFrame:CGRectMake(1.0, screenY - 6.0, rulerWidth - 12.0, 12.0)];
                [label setStringValue:[CPString stringWithFormat:@"%d", val]];
                [label setFont:[CPFont systemFontOfSize:8.0]];
                [label setTextColor:[CPColor colorWithWhite:0.4 alpha:1.0]];
                [label setAlignment:CPRightTextAlignment];
                [self addSubview:label];
            }
        }
    }

    // Reposition and display active markers
    for (var i = 0; i < [_markers count]; i++)
    {
        var marker = [_markers objectAtIndex:i];
        if ([marker superview] !== self)
            [self addSubview:marker];
        [self _positionMarker:marker];
    }
}

@end
