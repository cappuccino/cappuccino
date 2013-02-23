/*
 * CPGraphicsContext.j
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

@import "CGContext.j"


var CPGraphicsContextCurrent = nil,
    CPGraphicsContextThreadStack = nil;

/*!
    @ingroup appkit
    Provides an interface for drawing to the screen.
*/
@implementation CPGraphicsContext : CPObject
{
    CGContext   _graphicsPort;
}

/*!
    Returns the current graphics context.
*/
+ (CPGraphicsContext)currentContext
{
    return CPGraphicsContextCurrent;
}

/*!
    Sets the current graphics context
*/
+ (void)setCurrentContext:(CPGraphicsContext)aGraphicsContext
{
    CPGraphicsContextCurrent = aGraphicsContext;
}

+ (void)saveGraphicsState
{
    if (!CPGraphicsContextCurrent)
        return;

    if (!CPGraphicsContextThreadStack)
        CPGraphicsContextThreadStack = [CPMutableArray array];

    [CPGraphicsContextThreadStack addObject:CPGraphicsContextCurrent];
    [CPGraphicsContextCurrent saveGraphicsState];
}

+ (void)restoreGraphicsState
{
    var lastContext = [CPGraphicsContextThreadStack lastObject];

    if (lastContext)
    {
        [lastContext restoreGraphicsState];
        [CPGraphicsContextThreadStack removeLastObject];
    }
}

/*!
    Creates a graphics context with a provided port.
    @param aContext the context to initialize with
    @param aFlag whether the context should be flipped
    @return the initialized graphics context
*/
+ (CPGraphicsContext)graphicsContextWithGraphicsPort:(CGContext)aContext flipped:(BOOL)aFlag
{
    return [[self alloc] initWithGraphicsPort:aContext];
}

/*!
    Initializes the context with a graphics port.
    @param aGraphicsPort the graphics port to initialize with
    @return the initialized context
*/
- (id)initWithGraphicsPort:(CPContext)aGraphicsPort
{
    self = [super init];

    if (self)
        _graphicsPort = aGraphicsPort;

    return self;
}

/*!
    Returns the graphics context's port.
*/
- (CGContext)graphicsPort
{
    return _graphicsPort;
}

/*!
    (Not implemented. Always returns Cappuccino's default, `YES`.)

    Return `isFlipped` of the receiver's focused view, unless no view is focused in which case the receiver's
    `flipped` flag, as set by `graphicsContextWithGraphicsPort:flipped:`, is returned.

    Note: Cappuccino is flipped by default.
*/
- (BOOL)isFlipped
{
    return YES;
}

- (void)saveGraphicsState
{
    CGContextSaveGState(_graphicsPort);
}

- (void)restoreGraphicsState
{
    CGContextRestoreGState(_graphicsPort);
}

@end
