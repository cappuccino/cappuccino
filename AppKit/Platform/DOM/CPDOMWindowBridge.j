/*
 * CPDOMWindowBridge.j
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

@import <Foundation/CPObject.j>
@import <Foundation/CPRunLoop.j>

@import "CPEvent.j"
@import "CPCompatibility.j"


#import "../../CoreGraphics/CGGeometry.h"


CPSharedDOMWindowBridge = nil;

var ExcludedDOMElements = [];

// Define up here so compressor knows about em.
var CPDOMWindowGetFrame,
    CPDOMEventGetClickCount,
    CPDOMEventStop;

@implementation CPDOMWindowBridge : CPObject
{
}

/*!
    Returns the shared DOMWindowBridge.
*/
+ (id)sharedDOMWindowBridge
{
    if (!CPSharedDOMWindowBridge)
        CPSharedDOMWindowBridge = [[CPDOMWindowBridge alloc] _init];

    return CPSharedDOMWindowBridge;
}

/* @ignore */
- (id)_init//_initWithDOMWindow:(DOMWindow)aDOMWindow
{
    self = [super init];

    if (self)
    {
    }

    return self;
}

- (CPRect)frame
{
    return [self contentRect];
}

- (CGRect)visibleFrame
{
    return [[CPPlatformWindow primaryPlatformWindow] usableContentFrame];
}

- (CPRect)contentBounds
{
    var contentBounds = [[CPPlatformWindow primaryPlatformWindow] contentRect];
    contentBounds.origin = CGPointMake(0,0);

    return contentBounds;
}

- (CPArray)orderedWindowsAtLevel:(int)aLevel
{
    return [[CPPlatformWindow primaryPlatformWindow] orderedWindowsAtLevel:aLevel];
}

- (CPDOMWindowLayer)layerAtLevel:(int)aLevel create:(BOOL)aFlag
{
    return [[CPPlatformWindow primaryPlatformWindow] layerAtLevel:aLevel create:aFlag];
}

- (void)order:(CPWindowOrderingMode)aPlace window:(CPWindow)aWindow relativeTo:(CPWindow)otherWindow
{
    return [[CPPlatformWindow primaryPlatformWindow] order:aPlace window:aWindow relativeTo:otherWindow];
}

/* @ignore */
- (id)_dragHitTest:(CPPoint)aPoint pasteboard:(CPPasteboard)aPasteboard
{
    return [[CPPlatformWindow primaryPlatformWindow] _dragHitTest:aPoint pasteboard:aPasteboard];
}

/* @ignore */
- (void)_propagateCurrentDOMEvent:(BOOL)aFlag
{
    return [[CPPlatformWindow primaryPlatformWindow] _propagateCurrentDOMEvent:aFlag];
}

- (CPWindow)hitTest:(CPPoint)location
{
    return [[CPPlatformWindow primaryPlatformWindow] hitTest:location];
}

@end
