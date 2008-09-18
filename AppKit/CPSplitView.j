/*
 * CPSplitView.j
 * AppKit
 *
 * Created by Thomas Robinson.
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

import "CPImage.j"
import "CPView.j"

#include "CoreGraphics/CGGeometry.h"
#include "Platform/Platform.h"
#include "Platform/DOM/CPDOMDisplayServer.h"

CPSplitViewDidResizeSubviewsNotification = @"CPSplitViewDidResizeSubviewsNotification";
CPSplitViewWillResizeSubviewsNotification = @"CPSplitViewWillResizeSubviewsNotification";

var CPSplitViewHorizontalImage = nil,
    CPSplitViewVerticalImage = nil;

@implementation CPSplitView : CPView
{
    id          _delegate;
    BOOL        _isVertical;
    BOOL        _isPaneSplitter;
    
    int         _currentDivider;
    float       _initialOffset;
    
    CPString    _originComponent;
    CPString    _sizeComponent;
    
    CPArray     _DOMDividerElements;
    CPString    _dividerImagePath;
    int         _drawingDivider;
}

/*
    @ignore
*/
//+ (void)initialize
//{
//    if (self != [CPSplitView class])
//        return;
//
//    var bundle = [CPBundle bundleForClass:self];
//
//    CPSplitViewHorizontalImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPSplitView/CPSplitViewHorizontal.png"] size:CPSizeMake(5.0, 10.0)];
//    CPSplitViewVerticalImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPSplitView/CPSplitViewVertical.png"] size:CPSizeMake(10.0, 5.0)];
//}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _currentDivider = CPNotFound;
        
        _DOMDividerElements = [];
        
        [self setVertical:YES];
        [self setIsPaneSplitter:YES];
    }
    
    return self;
}

- (float)dividerThickness
{
    return 10.0;
}

- (BOOL)isVertical
{
    return _isVertical;
}
- (void)setVertical:(BOOL)flag
{
    _isVertical = flag;
    
    _originComponent = [self isVertical] ? "x" : "y";
    _sizeComponent   = [self isVertical] ? "width" : "height";
    _dividerImagePath = [self isVertical] ? [CPSplitViewVerticalImage filename] : [CPSplitViewHorizontalImage filename];
    
    [self adjustSubviews];
}

- (BOOL)isPaneSplitter
{
    return _isPaneSplitter;
}
- (void)setIsPaneSplitter:(BOOL)flag
{
    _isPaneSplitter = flag;
}

- (void)didAddSubview:(CPView)subview
{
    [self adjustSubviews];
}

- (void)adjustSubviews
{
    var frame = [self frame],
        dividerThickness = [self dividerThickness];
    
    [self _postNotificationWillResize];
    
    var eachSize = (frame.size[_sizeComponent] - dividerThickness * (_subviews.length - 1)) / _subviews.length;
    
    for (var i = 0; i < [_subviews count]; i++)
    {
        if ([self isVertical])
            [_subviews[i] setFrame:CGRectMake(Math.round((eachSize + dividerThickness) * i), 0, Math.round(eachSize), frame.size.height)];
        else
            [_subviews[i] setFrame:CGRectMake(0, Math.round((eachSize + dividerThickness) * i), frame.size.width, Math.round(eachSize))];
    }
    
    [self setNeedsDisplay:YES];
    
    [self _postNotificationDidResize];
}

- (BOOL)isSubviewCollapsed:(CPView)subview
{
    return [subview frame].size[_sizeComponent] < 1 ? YES : NO;
}

- (CGRect)rectOfDividerAtIndex:(int)aDivider
{
    var frame = [_subviews[aDivider] frame];
    
    var rect = CGRectMakeZero();
    rect.size = CPSizeCreateCopy([self frame].size);
    
    rect.size[_sizeComponent] = [self dividerThickness];
    rect.origin[_originComponent] = frame.origin[_originComponent] + frame.size[_sizeComponent];

    return rect;
}

- (CGRect)effectiveRectOfDividerAtIndex:(int)aDivider
{
    var realRect = [self rectOfDividerAtIndex:aDivider];
    
    realRect.size[_sizeComponent] += 4;
    realRect.origin[_originComponent] -= 2;
    
    return realRect;
}

- (void)drawRect:(CGRect)rect
{
    var count = [_subviews count];
    for (var _drawingDivider = 0; _drawingDivider < count-1; _drawingDivider++)
    {
        [self drawDividerInRect:[self rectOfDividerAtIndex:_drawingDivider]];
    }
}

- (void)drawDividerInRect:(CGRect)aRect
{
#if PLATFORM(DOM)
    if (!_DOMDividerElements[_drawingDivider])
    {
        _DOMDividerElements[_drawingDivider] = document.createElement("div");
        _DOMDividerElements[_drawingDivider].style.cursor = "move";
        _DOMDividerElements[_drawingDivider].style.position = "absolute";
        _DOMDividerElements[_drawingDivider].style.backgroundRepeat = "repeat";
        CPDOMDisplayServerAppendChild(_DOMElement, _DOMDividerElements[_drawingDivider]);
    }    
        
    CPDOMDisplayServerSetStyleLeftTop(_DOMDividerElements[_drawingDivider], NULL, _CGRectGetMinX(aRect), _CGRectGetMinY(aRect));
    CPDOMDisplayServerSetStyleSize(_DOMDividerElements[_drawingDivider], _CGRectGetWidth(aRect), _CGRectGetHeight(aRect));
    
    _DOMDividerElements[_drawingDivider].style.backgroundImage = "url('"+_dividerImagePath+"')";
#endif
}

- (BOOL)cursorAtPoint:(CPPoint)aPoint hitDividerAtIndex:(int)anIndex
{
    var frame = [_subviews[anIndex] frame],
        startPosition = frame.origin[_originComponent] + frame.size[_sizeComponent],
        effectiveRect = [self effectiveRectOfDividerAtIndex:anIndex],
        additionalRect = null;
    
    if ([_delegate respondsToSelector:@selector(splitView:effectiveRect:forDrawnRect:ofDividerAtIndex:)])
        effectiveRect = [_delegate splitView:self effectiveRect:effectiveRect forDrawnRect:effectiveRect ofDividerAtIndex:anIndex];
    
    if ([_delegate respondsToSelector:@selector(splitView:additionalEffectiveRectOfDividerAtIndex:)])
        additionalRect = [_delegate splitView:self additionalEffectiveRectOfDividerAtIndex:anIndex];

    return CGRectContainsPoint(effectiveRect, aPoint) || (additionalRect && CGRectContainsPoint(additionalRect, aPoint));
}


/*
    Tracks the divider.
    @param anEvent the input event
*/
- (void)trackDivider:(CPEvent)anEvent
{
    var type = [anEvent type];
    
    if (type == CPLeftMouseUp)
    {
        if (_currentDivider != CPNotFound)
        {
            _currentDivider = CPNotFound;
            [self _postNotificationDidResize];
        }
        
        return;
    }
    
    if (type == CPLeftMouseDown)
    {
        var location = [anEvent locationInWindow],
            point = [self convertPoint:location fromView:nil];

        _currentDivider = CPNotFound;
        for (var i = 0; i < [_subviews count] - 1; i++)
        {
            var frame = [_subviews[i] frame],
                startPosition = frame.origin[_originComponent] + frame.size[_sizeComponent];

            if ([self cursorAtPoint:point hitDividerAtIndex:i])
            {
                if ([anEvent clickCount] == 2 &&
                    [_delegate respondsToSelector:@selector(splitView:canCollapseSubview:)] &&
                    [_delegate respondsToSelector:@selector(splitView:shouldCollapseSubview:forDoubleClickOnDividerAtIndex:)])
                {    
                    var minPosition = [self minPossiblePositionOfDividerAtIndex:i],
                        maxPosition = [self maxPossiblePositionOfDividerAtIndex:i];

                    if ([_delegate splitView:self canCollapseSubview:_subviews[i]] && [_delegate splitView:self shouldCollapseSubview:_subviews[i] forDoubleClickOnDividerAtIndex:i])
                    {
                        if ([self isSubviewCollapsed:_subviews[i]])
                            [self setPosition:(minPosition + (maxPosition - minPosition) / 2) ofDividerAtIndex:i];
                        else
                            [self setPosition:minPosition ofDividerAtIndex:i];
                    }
                    else if ([_delegate splitView:self canCollapseSubview:_subviews[i+1]] && [_delegate splitView:self shouldCollapseSubview:_subviews[i+1] forDoubleClickOnDividerAtIndex:i])
                    {
                        if ([self isSubviewCollapsed:_subviews[i+1]])
                            [self setPosition:(minPosition + (maxPosition - minPosition) / 2) ofDividerAtIndex:i];
                        else
                            [self setPosition:maxPosition ofDividerAtIndex:i];
                    }
                }
                else
                {
                    _currentDivider = i;
                    _initialOffset = startPosition - point[_originComponent];

                    [self _postNotificationWillResize];
                }
            }
        }
    }
    
    else if (type == CPLeftMouseDragged)
    {
        if (_currentDivider != CPNotFound)
        {
            var location = [anEvent locationInWindow],
                point = [self convertPoint:location fromView:nil];

            [self setPosition:(point[_originComponent] + _initialOffset) ofDividerAtIndex:_currentDivider];
        }
    }
    
    [CPApp setTarget:self selector:@selector(trackDivider:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

- (void)mouseDown:(CPEvent)anEvent
{
    [self trackDivider:anEvent];
}

- (float)maxPossiblePositionOfDividerAtIndex:(int)dividerIndex
{
    var frame = [_subviews[dividerIndex + 1] frame];
    
    if (dividerIndex + 1 < [_subviews count] - 1)
        return frame.origin[_originComponent] + frame.size[_sizeComponent] - [self dividerThickness];
    else    
        return [self frame].size[_sizeComponent] - [self dividerThickness];
}

- (float)minPossiblePositionOfDividerAtIndex:(int)dividerIndex
{
    var frame = [_subviews[dividerIndex - 1] frame];
    
    if (dividerIndex > 0)
        return frame.origin[_originComponent] + frame.size[_sizeComponent] + [self dividerThickness];
    else    
        return 0;
}

- (void)setPosition:(float)position ofDividerAtIndex:(int)dividerIndex
{
    // not sure where this should override other positions?
    if ([_delegate respondsToSelector:@selector(splitView:constrainSplitPosition:ofSubviewAt:)])
        position = [_delegate splitView:self constrainSplitPosition:position ofSubviewAt:dividerIndex];

    var proposedMax = [self maxPossiblePositionOfDividerAtIndex:dividerIndex],
        proposedMin = [self minPossiblePositionOfDividerAtIndex:dividerIndex],
        actualMax = proposedMax,
        actualMin = proposedMin;
        
    if([_delegate respondsToSelector:@selector(splitView:constrainMinCoordinate:ofSubviewAt:)])
        actualMin = [_delegate splitView:self constrainMinCoordinate:proposedMin ofSubviewAt:dividerIndex];
        
    if([_delegate respondsToSelector:@selector(splitView:constrainMaxCoordinate:ofSubviewAt:)])
        actualMax = [_delegate splitView:self constrainMaxCoordinate:proposedMax ofSubviewAt:dividerIndex];

    var frame = [self frame],
        viewA = _subviews[dividerIndex],
        frameA = CGRectCreateCopy([viewA frame]),
        viewB = _subviews[dividerIndex+1],
        frameB = CGRectCreateCopy([viewB frame]);
    
    var realPosition = MAX(MIN(position, actualMax), actualMin);
    
    if (position <  proposedMin + (actualMin - proposedMin) / 2)
        if ([_delegate respondsToSelector:@selector(splitView:canCollapseSubview:)])
            if ([_delegate splitView:self canCollapseSubview:viewA])
                realPosition = proposedMin;
    
    frameA.size[_sizeComponent] = realPosition - frameA.origin[_originComponent];
    [_subviews[dividerIndex] setFrame:frameA];
    
    frameB.size[_sizeComponent] = frameB.origin[_originComponent] + frameB.size[_sizeComponent] - realPosition - [self dividerThickness];
    frameB.origin[_originComponent] = realPosition + [self dividerThickness];
    [_subviews[dividerIndex+1] setFrame:frameB];
    
    [self setNeedsDisplay:YES];
}

- (void)resizeSubviewsWithOldSize:(CPSize)oldSize
{
    if ([_delegate respondsToSelector:@selector(splitView:resizeSubviewsWithOldSize:)])
    {
        [_delegate splitView:self resizeSubviewsWithOldSize:oldSize];
        return;
    }

    [self _postNotificationWillResize];
    
    var frame = CGRectCreateCopy([self frame]);
    
    for (var i = 0; i < [_subviews count]; i++)
    {
        var view = [_subviews objectAtIndex:i],
            newFrame = CGRectCreateCopy(frame);
        
        if(i + 1 == [_subviews count])
            newFrame.size[_sizeComponent] = frame.size[_sizeComponent] - newFrame.origin[_originComponent];
        else
            newFrame.size[_sizeComponent] = frame.size[_sizeComponent] * ([view frame].size[_sizeComponent] / oldSize[_sizeComponent]);
    
        frame.origin[_originComponent] += newFrame.size[_sizeComponent];
        frame.origin[_originComponent] += [self dividerThickness];
        
        [view setFrame:newFrame];
    }
    
    [self setNeedsDisplay:YES];

    [self _postNotificationDidResize];
}

- (void)setDelegate:(id)delegate
{
    if ([_delegate respondsToSelector:@selector(splitViewDidResizeSubviews:)])
        [[CPNotificationCenter defaultCenter] removeObserver:_delegate name:CPSplitViewDidResizeSubviewsNotification object:self];
    if ([_delegate respondsToSelector:@selector(splitViewWillResizeSubviews:)])
        [[CPNotificationCenter defaultCenter] removeObserver:_delegate name:CPSplitViewWillResizeSubviewsNotification object:self];
    
   _delegate = delegate;

   if ([_delegate respondsToSelector:@selector(splitViewDidResizeSubviews:)])
       [[CPNotificationCenter defaultCenter] addObserver:_delegate
                                                selector:@selector(splitViewDidResizeSubviews:)
                                                    name:CPSplitViewDidResizeSubviewsNotification
                                                  object:self];
   if ([_delegate respondsToSelector:@selector(splitViewWillResizeSubviews:)])
       [[CPNotificationCenter defaultCenter] addObserver:_delegate
                                                selector:@selector(splitViewWillResizeSubviews:)
                                                    name:CPSplitViewWillResizeSubviewsNotification
                                                  object:self];
}

- (void)_postNotificationWillResize
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPSplitViewWillResizeSubviewsNotification object:self];
}

- (void)_postNotificationDidResize
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPSplitViewDidResizeSubviewsNotification object:self];
}

@end

// FIXME: once +initialize is fixed for superclasses, remove this and uncomment +initialize
var bundle = [CPBundle bundleForClass:CPSplitView];
CPSplitViewHorizontalImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPSplitView/CPSplitViewHorizontal.png"] size:CPSizeMake(5.0, 10.0)];
CPSplitViewVerticalImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPSplitView/CPSplitViewVertical.png"] size:CPSizeMake(10.0, 5.0)];
