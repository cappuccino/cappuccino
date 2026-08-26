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
@import "CPMenu.j"
@import "CPMenuItem.j"

// Orientations matching AppKit standards
@typedef CPRulerOrientation
CPHorizontalRuler = 0;
CPVerticalRuler = 1;
CPRulerOrientationHorizontal = 0;
CPRulerOrientationVertical = 1;

@class CPRulerView;
@class CPScrollView;
@class CPTextTab;


// MARK: - CPRulerMarker (Interactive Handles with Dynamic Alignment Icons)

@implementation CPRulerMarker : CPView
{
    CPRulerView         _rulerView              @accessors(property=rulerView);
    float               _imageValue             @accessors(property=imageValue);
    id                  _representedObject     @accessors(property=representedObject);
    CPTextField         _label;
    CPView              _customHandleView;
}

- (id)initWithRulerView:(CPRulerView)aRulerView markerLocation:(float)aLocation imageValue:(float)anImageValue representedObject:(id)anObject
{
    if (self = [super initWithFrame:CGRectMake(0, 0, 12, 12)])
    {
        _rulerView = aRulerView;
        _imageValue = anImageValue;
        _representedObject = anObject;
        
        _label = [[CPTextField alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
        [_label setFont:[CPFont systemFontOfSize:10.0]];
        [_label setAlignment:CPCenterTextAlignment];
        [self addSubview:_label];
        
        _customHandleView = [[CPView alloc] initWithFrame:CGRectMakeZero()];
        [self addSubview:_customHandleView];
        
        // Inherit HUD state from ruler if present
        if ([aRulerView hasThemeState:CPThemeStateHUD])
            [self setThemeState:CPThemeStateHUD];

        [self updateMarkerIcon];
    }
    return self;
}

- (BOOL)isHUD
{
    return [self hasThemeState:CPThemeStateHUD] || (_rulerView && [_rulerView hasThemeState:CPThemeStateHUD]);
}

- (void)setThemeState:(CPThemeState)aState
{
    [super setThemeState:aState];
    [self updateMarkerIcon];
}

- (void)unsetThemeState:(CPThemeState)aState
{
    [super unsetThemeState:aState];
    [self updateMarkerIcon];
}

- (CPTextField)label
{
    return _label;
}

- (void)setRepresentedObject:(id)anObject
{
    _representedObject = anObject;
    [self updateMarkerIcon];
}

- (void)setFrame:(CGRect)aFrame
{
    [super setFrame:aFrame];
    [self updateMarkerIcon];
}

// Dynamically sets the Unicode triangle direction based on the alignment or indent type,
// or draws custom split-height grab handles for indentation controls.
- (void)updateMarkerIcon
{
    var isHUD = [self isHUD],
        isIndentMarker = (_representedObject === @"CPFirstLineIndent" || _representedObject === @"CPHeadIndent");
    
    if (isIndentMarker)
    {
        [_label setHidden:YES];
        [_customHandleView setHidden:NO];
        
        var frame = [self bounds];
        [_customHandleView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        
        // Remove old internal rendering to update cleanly
        [[_customHandleView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        var isFirstLine = (_representedObject === @"CPFirstLineIndent");
        
        // Border outline
        if (isHUD)
            [_customHandleView setBackgroundColor:[CPColor colorWithWhite:0.12 alpha:1.0]];
        else
            [_customHandleView setBackgroundColor:[CPColor colorWithWhite:0.5 alpha:1.0]];
        
        // Inner fill
        var innerView = [[CPView alloc] initWithFrame:CGRectMake(1.0, 1.0, frame.size.width - 2.0, frame.size.height - 2.0)];

        if (isHUD)
        {
            if (isFirstLine)
                [innerView setBackgroundColor:[CPColor colorWithWhite:0.38 alpha:1.0]];
            else
                [innerView setBackgroundColor:[CPColor colorWithWhite:0.28 alpha:1.0]];
        }
        else
        {
            if (isFirstLine)
                [innerView setBackgroundColor:[CPColor colorWithWhite:0.92 alpha:1.0]];
            else
                [innerView setBackgroundColor:[CPColor colorWithWhite:0.80 alpha:1.0]];
        }

        [_customHandleView addSubview:innerView];
        
        // Horizontal indicator grip line
        var gripLine = [[CPView alloc] initWithFrame:CGRectMake(Math.floor(frame.size.width / 2.0) - 1.0, 2.0, 1.0, frame.size.height - 4.0)];
        if (isHUD)
            [gripLine setBackgroundColor:[CPColor colorWithWhite:0.65 alpha:1.0]];
        else
            [gripLine setBackgroundColor:[CPColor colorWithWhite:0.60 alpha:1.0]];

        [innerView addSubview:gripLine];
    }
    else
    {
        [_label setHidden:NO];
        [_customHandleView setHidden:YES];
        [_label setFrame:[self bounds]];

        // Label color adapted to HUD state
        if (isHUD)
            [_label setTextColor:[CPColor colorWithWhite:0.92 alpha:1.0]];
        else
            [_label setTextColor:[CPColor colorWithWhite:0.2 alpha:1.0]];
        
        if ([_representedObject isKindOfClass:[CPTextTab class]])
        {
            var align = [_representedObject alignment];
            if (align === CPLeftTextAlignment)
                [_label setStringValue:@"▶"]; // Left-aligned points Right
            else if (align === CPCenterTextAlignment)
                [_label setStringValue:@"▼"]; // Center-aligned points Down
            else if (align === CPRightTextAlignment)
                [_label setStringValue:@"◀"]; // Right-aligned points Left
        }
        else if ([_representedObject isKindOfClass:[CPString class]])
        {
            if (_representedObject === @"CPTailIndent")
                [_label setStringValue:@"⥘"];
            else
                [_label setStringValue:@"⇡"];
        }
        else
        {
            [_label setStringValue:@"⇡"];
        }
    }
}

// MARK: -
// MARK: Context Menu Support

- (CPMenu)menuForEvent:(CPEvent)anEvent
{
    var menu = [[CPMenu alloc] initWithTitle:@"Marker Context Menu"];
    
    if ([_representedObject isKindOfClass:[CPTextTab class]])
    {
        var itemLeft = [menu addItemWithTitle:@"Left Tab Stop" action:@selector(changeTypeToLeft:) keyEquivalent:@""],
            itemCenter = [menu addItemWithTitle:@"Center Tab Stop" action:@selector(changeTypeToCenter:) keyEquivalent:@""],
            itemRight = [menu addItemWithTitle:@"Right Tab Stop" action:@selector(changeTypeToRight:) keyEquivalent:@""];
            
        [itemLeft setTarget:self];
        [itemCenter setTarget:self];
        [itemRight setTarget:self];
        
        var align = [_representedObject alignment];
        if (align === CPLeftTextAlignment) [itemLeft setState:CPOnState];
        else if (align === CPCenterTextAlignment) [itemCenter setState:CPOnState];
        else if (align === CPRightTextAlignment) [itemRight setState:CPOnState];
        
        [menu addItem:[CPMenuItem separatorItem]];
    }
    
    var deleteTitle = @"Delete Tab Stop";
    if ([_representedObject isKindOfClass:[CPString class]])
    {
        if (_representedObject === @"CPFirstLineIndent")
            deleteTitle = @"Delete 1st line indentation marker";
        else if (_representedObject === @"CPHeadIndent")
            deleteTitle = @"Delete head indentation marker";
        else if (_representedObject === @"CPTailIndent")
            deleteTitle = @"Delete tail indentation marker";
    }
    
    var itemDelete = [menu addItemWithTitle:deleteTitle action:@selector(deleteMarker:) keyEquivalent:@""];
    [itemDelete setTarget:self];
    
    return menu;
}

- (void)changeTypeToLeft:(id)sender
{
    [self _changeAlignment:CPLeftTextAlignment];
}

- (void)changeTypeToCenter:(id)sender
{
    [self _changeAlignment:CPCenterTextAlignment];
}

- (void)changeTypeToRight:(id)sender
{
    [self _changeAlignment:CPRightTextAlignment];
}

- (void)_changeAlignment:(CPTextAlignment)alignment
{
    if (![_representedObject isKindOfClass:[CPTextTab class]])
        return;
        
    var oldTab = _representedObject;
    var newTab = [[CPTextTab alloc] initWithType:alignment location:_imageValue];
    
    [self setRepresentedObject:newTab];
    
    var client = [_rulerView clientView];
    if (client && [client respondsToSelector:@selector(rulerView:didUpdateMarker:oldTab:)])
    {
        [client rulerView:_rulerView didUpdateMarker:self oldTab:oldTab];
    }
}

- (void)deleteMarker:(id)sender
{
    var client = [_rulerView clientView];
    if (client && [client respondsToSelector:@selector(rulerView:didRemoveMarker:)])
    {
        [client rulerView:_rulerView didRemoveMarker:self];
    }
    [_rulerView removeMarker:self];
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

- (BOOL)isHUD
{
    return [self hasThemeState:CPThemeStateHUD];
}

- (void)setThemeState:(CPThemeState)aState
{
    [super setThemeState:aState];
    for (var i = 0; i < [_markers count]; i++)
        [[_markers objectAtIndex:i] setThemeState:aState];
    [self updateRuler];
}

- (void)unsetThemeState:(CPThemeState)aState
{
    [super unsetThemeState:aState];
    for (var i = 0; i < [_markers count]; i++)
        [[_markers objectAtIndex:i] unsetThemeState:aState];
    [self updateRuler];
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
        
    if ([self hasThemeState:CPThemeStateHUD])
        [aMarker setThemeState:CPThemeStateHUD];

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
    var isHUD = [self hasThemeState:CPThemeStateHUD];
    
    for (var i = 0; i < [_markers count]; i++)
    {
        var marker = [_markers objectAtIndex:i];
        if (isHUD)
            [marker setThemeState:CPThemeStateHUD];
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
        var x = markerLocation - scrollPoint.x - 6.0,
            y = rulerHeight - 11.0,
            w = 12.0,
            h = 12.0;
            
        if ([aMarker representedObject] === @"CPFirstLineIndent")
        {
            y = 0.0;
            h = Math.floor(rulerHeight / 2.0);
        }
        else if ([aMarker representedObject] === @"CPHeadIndent")
        {
            y = Math.floor(rulerHeight / 2.0);
            h = rulerHeight - y - 1.0;
        }
        else
        {
            if (x < 0.0)
                x = 0.0;
            else if (x + 12.0 > rulerWidth)
                x = rulerWidth - 12.0;
        }
            
        [aMarker setFrame:CGRectMake(x, y, w, h)];
    }
    else
    {
        var x = rulerWidth - 11.0,
            y = markerLocation - scrollPoint.y - 6.0;
            
        if (y < 0.0)
            y = 0.0;
        else if (y + 12.0 > rulerHeight)
            y = rulerHeight - 12.0;
            
        [aMarker setFrame:CGRectMake(x, y, 12.0, 12.0)];
    }
}


// MARK: -
// MARK: Interaction Handlers

- (void)mouseDown:(CPEvent)anEvent
{
    var locationInWindow = [anEvent locationInWindow],
        localPoint = [self convertPoint:locationInWindow fromView:nil],
        clipView = [_scrollView contentView],
        scrollPoint = [clipView bounds].origin,
        isHorizontal = (_orientation === CPHorizontalRuler || _orientation === CPRulerOrientationHorizontal);

    var rulerLocation = isHorizontal ? (localPoint.x + scrollPoint.x) : (localPoint.y + scrollPoint.y);

    var clickedMarker = [self _markerAtPoint:localPoint];
    if (clickedMarker)
    {
        _draggingMarker = clickedMarker;
        _dragStartPoint = localPoint;
        _dragStartLocation = [_draggingMarker imageValue];
    }
    else
    {
        var newMarker = [[CPRulerMarker alloc] initWithRulerView:self 
                                                  markerLocation:rulerLocation 
                                                      imageValue:rulerLocation 
                                               representedObject:nil];
        [self addMarker:newMarker];
        
        var client = [self clientView];
        if (client && [client respondsToSelector:@selector(rulerView:didAddMarker:)])
            [client rulerView:self didAddMarker:newMarker];
        
        _draggingMarker = newMarker;
        _dragStartPoint = localPoint;
        _dragStartLocation = rulerLocation;
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
    [self updateRuler];
    
    var draggedOff = isHorizontal ? (localPoint.y < -15 || localPoint.y > CGRectGetHeight([self bounds]) + 15)
                                  : (localPoint.x < -15 || localPoint.x > CGRectGetWidth([self bounds]) + 15);

    if (draggedOff)
    {
        [_draggingMarker setAlphaValue:0.35];
        [[_draggingMarker label] setTextColor:[CPColor grayColor]];
    }
    else
    {
        [_draggingMarker setAlphaValue:1.0];
        if ([self isHUD])
            [[_draggingMarker label] setTextColor:[CPColor colorWithWhite:0.92 alpha:1.0]];
        else
            [[_draggingMarker label] setTextColor:[CPColor colorWithWhite:0.2 alpha:1.0]];
    }
    
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
        draggedOff = isHorizontal ? (localPoint.y < -15 || localPoint.y > CGRectGetHeight([self bounds]) + 15)
                                  : (localPoint.x < -15 || localPoint.x > CGRectGetWidth([self bounds]) + 15);

    if (draggedOff)
    {
        var client = [self clientView];
        if (client && [client respondsToSelector:@selector(rulerView:didRemoveMarker:)])
            [client rulerView:self didRemoveMarker:_draggingMarker];

        [self removeMarker:_draggingMarker];
    }
    else
    {
        [_draggingMarker setAlphaValue:1.0];
        if ([self isHUD])
            [[_draggingMarker label] setTextColor:[CPColor colorWithWhite:0.92 alpha:1.0]];
        else
            [[_draggingMarker label] setTextColor:[CPColor colorWithWhite:0.2 alpha:1.0]];
    }
    
    _draggingMarker = nil;
    [self updateRuler];
}


// MARK: -
// MARK: DOM Layout Builder

- (void)updateRuler
{
    // Wipe subviews to redraw the dynamic visible tick lines/numbers
    [self setSubviews:@[]];

    if (!_scrollView)
        return;

    var isHUD = [self isHUD];

    // Update ruler base background color
    if (isHUD)
        [self setBackgroundColor:[CPColor colorWithWhite:0.18 alpha:1.0]];
    else
        [self setBackgroundColor:[CPColor colorWithWhite:0.96 alpha:1.0]];

    var clipView = [_scrollView contentView],
        scrollBounds = [clipView bounds],
        scrollPoint = scrollBounds.origin,
        visibleSize = scrollBounds.size,
        isHorizontal = (_orientation === CPHorizontalRuler || _orientation === CPRulerOrientationHorizontal);

    if (isHorizontal)
    {
        var start = Math.floor(scrollPoint.x / 10) * 10,
            end = scrollPoint.x + visibleSize.width,
            rulerHeight = CGRectGetHeight([self bounds]),
            rulerWidth = CGRectGetWidth([self bounds]);

        // Bottom border
        var bottomBorder = [[CPView alloc] initWithFrame:CGRectMake(0, rulerHeight - 1, rulerWidth, 1)];
        if (isHUD)
            [bottomBorder setBackgroundColor:[CPColor colorWithWhite:0.10 alpha:1.0]];
        else
            [bottomBorder setBackgroundColor:[CPColor colorWithWhite:0.75 alpha:1.0]];
        [self addSubview:bottomBorder];

        // Find indent markers to draw background margin bands
        var firstLineMarker = nil,
            headMarker = nil;
        for (var i = 0; i < [_markers count]; i++)
        {
            var m = [_markers objectAtIndex:i];
            if ([m representedObject] === @"CPFirstLineIndent")
                firstLineMarker = m;
            else if ([m representedObject] === @"CPHeadIndent")
                headMarker = m;
        }

        var halfHeight = Math.floor(rulerHeight / 2.0);

        // Draw First Line Indent background - top half
        if (firstLineMarker)
        {
            var firstLineX = [firstLineMarker imageValue] - scrollPoint.x;
            if (firstLineX > 0)
            {
                var firstLineBg = [[CPView alloc] initWithFrame:CGRectMake(0, 0, firstLineX, halfHeight)];
                if (isHUD)
                    [firstLineBg setBackgroundColor:[CPColor colorWithWhite:0.24 alpha:1.0]];
                else
                    [firstLineBg setBackgroundColor:[CPColor colorWithWhite:0.93 alpha:1.0]];
                [self addSubview:firstLineBg];
            }
        }

        // Draw Head Indent background - bottom half
        if (headMarker)
        {
            var headX = [headMarker imageValue] - scrollPoint.x;
            if (headX > 0)
            {
                var headBg = [[CPView alloc] initWithFrame:CGRectMake(0, halfHeight, headX, rulerHeight - halfHeight - 1.0)];
                if (isHUD)
                    [headBg setBackgroundColor:[CPColor colorWithWhite:0.28 alpha:1.0]];
                else
                    [headBg setBackgroundColor:[CPColor colorWithWhite:0.86 alpha:1.0]];
                [self addSubview:headBg];
            }
        }

        // Render ruler tick lines and labels
        for (var val = start; val <= end; val += 10)
        {
            if (val < 0) continue;

            var screenX = val - scrollPoint.x,
                isMajor = (val % 50 === 0),
                tickHeight = isMajor ? 8.0 : 4.0,
                tickY = rulerHeight - tickHeight - 1.0;

            var tick = [[CPView alloc] initWithFrame:CGRectMake(screenX, tickY, 1.0, tickHeight)];
            if (isHUD)
                [tick setBackgroundColor:isMajor ? [CPColor colorWithWhite:0.60 alpha:1.0] : [CPColor colorWithWhite:0.40 alpha:1.0]];
            else
                [tick setBackgroundColor:[CPColor colorWithWhite:0.65 alpha:1.0]];
            [self addSubview:tick];

            if (isMajor)
            {
                var labelX = screenX - 20.0,
                    alignment = CPCenterTextAlignment;

                if (labelX < 0.0)
                {
                    labelX = Math.max(0.0, screenX);
                    alignment = CPLeftTextAlignment;
                }
                else if (labelX + 40.0 > rulerWidth)
                {
                    labelX = rulerWidth - 40.0;
                    alignment = CPRightTextAlignment;
                }

                var label = [[CPTextField alloc] initWithFrame:CGRectMake(labelX, 1.0, 40.0, 12.0)];
                [label setStringValue:[CPString stringWithFormat:@"%d", val]];
                [label setFont:[CPFont systemFontOfSize:8.0]];
                if (isHUD)
                    [label setTextColor:[CPColor colorWithWhite:0.75 alpha:1.0]];
                else
                    [label setTextColor:[CPColor colorWithWhite:0.40 alpha:1.0]];
                [label setAlignment:alignment];
                [self addSubview:label];
            }
        }
    }
    else
    {
        // Vertical Ruler
        var start = Math.floor(scrollPoint.y / 10) * 10,
            end = scrollPoint.y + visibleSize.height,
            rulerHeight = CGRectGetHeight([self bounds]),
            rulerWidth = CGRectGetWidth([self bounds]);

        var rightBorder = [[CPView alloc] initWithFrame:CGRectMake(rulerWidth - 1, 0, 1, rulerHeight)];
        if (isHUD)
            [rightBorder setBackgroundColor:[CPColor colorWithWhite:0.10 alpha:1.0]];
        else
            [rightBorder setBackgroundColor:[CPColor colorWithWhite:0.75 alpha:1.0]];
        [self addSubview:rightBorder];

        for (var val = start; val <= end; val += 10)
        {
            if (val < 0) continue;

            var screenY = val - scrollPoint.y,
                isMajor = (val % 50 === 0),
                tickWidth = isMajor ? 8.0 : 4.0,
                tickX = rulerWidth - tickWidth - 1.0;

            var tick = [[CPView alloc] initWithFrame:CGRectMake(tickX, screenY, tickWidth, 1.0)];
            if (isHUD)
                [tick setBackgroundColor:isMajor ? [CPColor colorWithWhite:0.60 alpha:1.0] : [CPColor colorWithWhite:0.40 alpha:1.0]];
            else
                [tick setBackgroundColor:[CPColor colorWithWhite:0.65 alpha:1.0]];
            [self addSubview:tick];

            if (isMajor)
            {
                var labelY = screenY - 6.0;

                if (labelY < 0.0)
                    labelY = 0.0;
                else if (labelY + 12.0 > rulerHeight)
                    labelY = rulerHeight - 12.0;

                var label = [[CPTextField alloc] initWithFrame:CGRectMake(1.0, labelY, rulerWidth - 12.0, 12.0)];
                [label setStringValue:[CPString stringWithFormat:@"%d", val]];
                [label setFont:[CPFont systemFontOfSize:8.0]];
                if (isHUD)
                    [label setTextColor:[CPColor colorWithWhite:0.75 alpha:1.0]];
                else
                    [label setTextColor:[CPColor colorWithWhite:0.40 alpha:1.0]];
                [label setAlignment:CPRightTextAlignment];
                [self addSubview:label];
            }
        }
    }

    // Reposition active markers and keep their theme in sync
    for (var i = 0; i < [_markers count]; i++)
    {
        var marker = [_markers objectAtIndex:i];
        if (isHUD)
            [marker setThemeState:CPThemeStateHUD];
        else
            [marker unsetThemeState:CPThemeStateHUD];

        if ([marker superview] !== self)
            [self addSubview:marker];
        [self _positionMarker:marker];
    }
}

@end
