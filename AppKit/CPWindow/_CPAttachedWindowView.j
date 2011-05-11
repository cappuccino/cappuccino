/*
 * _CPAttachedWindowView.j
 * AppKit
 *
 * Created by Antoine Mercadal 
 * Copyright 2011 <antoine.mercadal@inframonde.eu>
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

@import "_CPWindowView.j"

CPAttachedWindowGravityUp      = 0;
CPAttachedWindowGravityDown    = 1;
CPAttachedWindowGravityLeft    = 2;
CPAttachedWindowGravityRight   = 3;
CPAttachedWindowGravityAuto    = 4;

/*! a custom CPWindowView that manage border and cursor
*/
@implementation _CPAttachedWindowView : _CPWindowView
{
    BOOL            _mouseDownPressed           @accessors(getter=isMouseDownPressed, setter=setMouseDownPressed:);
    unsigned        _gravity                    @accessors(property=gravity);

    BOOL            _useGlowingEffect;
    CPColor         _backgroundTopColor;
    CPColor         _backgroundBottomColor;
    CPColor         _strokeColor;
    CPImage         _cursorBackgroundBottom;
    CPImage         _cursorBackgroundLeft;
    CPImage         _cursorBackgroundRight;
    CPImage         _cursorBackgroundTop;
    CPSize          _cursorSize;
}

/*! compute the contentView frame from a given window frame
    @param aFrameRect the window frame
*/
+ (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    var contentRect = CGRectMakeCopy(aFrameRect);

    // @todo change border art and remove this pixel perfect adaptation
    // return CGRectInset(contentRect, 20, 20);

    contentRect.origin.x += 18;
    contentRect.origin.y += 17;
    contentRect.size.width -= 35;
    contentRect.size.height -= 37;

    return contentRect;
}

/*! compute the window frame from a given contentView frame
    @param aContentRect the contentView frame
*/
+ (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    var frameRect = CGRectMakeCopy(aContentRect);

    // @todo change border art and remove this pixel perfect adaptation
    //return CGRectOffset(frameRect, 20, 20);

    frameRect.origin.x -= 18;
    frameRect.origin.y -= 17;
    frameRect.size.width += 35;
    frameRect.size.height += 37;
    return frameRect;
}

- (id)initWithFrame:(CPRect)aFrame styleMask:(unsigned)aStyleMask
{
    if (self = [super initWithFrame:aFrame styleMask:aStyleMask])
    {
        _cursorSize = CPSizeMake(15, 10);
    }

    return self;
}

- (void)hideCursor
{
    _cursorSize = CPSizeMakeZero();
    [self setNeedsDisplay:YES];
}

- (void)showCursor
{
    _cursorSize = CPSizeMake(15, 10);
    [self setNeedsDisplay:YES];
    _mouseDownPressed = NO;
}


- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        gradientColor = [[_backgroundTopColor redComponent], [_backgroundTopColor greenComponent], [_backgroundTopColor blueComponent],1.0, [_backgroundBottomColor redComponent], [_backgroundBottomColor greenComponent], [_backgroundBottomColor blueComponent],1.0],
        gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), gradientColor, [0,1], 2),
        radius = 5,
        arrowWidth = _cursorSize.width,
        arrowHeight = _cursorSize.height,
        strokeWidth = 2;

    CGContextSetStrokeColor(context, _strokeColor);
    CGContextSetLineWidth(context, strokeWidth);
    CGContextBeginPath(context);

    aRect.origin.x += strokeWidth;
    aRect.origin.y += strokeWidth;
    aRect.size.width -= strokeWidth * 2;
    aRect.size.height -= strokeWidth * 2;

    if (_useGlowingEffect)
    {
        var shadowColor = [[CPColor blackColor] colorWithAlphaComponent:.1],
            shadowSize = CGSizeMake(0, 0),
            shadowBlur = 5;

        //compensate for the shadow blur
        aRect.origin.x += shadowBlur;
        aRect.origin.y += shadowBlur;
        aRect.size.width -= shadowBlur * 2;
        aRect.size.height -= shadowBlur * 2;

        //set the shadow
        CGContextSetShadow(context, CGSizeMake(0,0), 20);
        CGContextSetShadowWithColor(context, shadowSize, shadowBlur, shadowColor);
    }

    //Remodulate size and origin
    aRect.size.width -= 10;
    aRect.origin.x += 5;
    aRect.size.height -= 10;
    aRect.origin.y += 5;

    CGContextAddPath(context, CGPathWithRoundedRectangleInRect(aRect, radius, radius, YES, YES, YES, YES));
    CGContextDrawLinearGradient(context, gradient, CGPointMake(CPRectGetMidX(aRect), 0.0), CGPointMake(CPRectGetMidX(aRect), aRect.size.height), 0);
    CGContextClosePath(context);

    //Start the arrow
    switch (_gravity)
    {
        case CPAttachedWindowGravityLeft:
            CGContextMoveToPoint(context, aRect.size.width + aRect.origin.x, (aRect.size.height / 2 - (arrowWidth / 2)) + aRect.origin.y);
            CGContextAddLineToPoint(context, aRect.size.width + arrowHeight + aRect.origin.x, (aRect.size.height / 2) + aRect.origin.y);
            CGContextAddLineToPoint(context, aRect.size.width + aRect.origin.x, (aRect.size.height / 2 + (arrowWidth / 2)) + aRect.origin.y);
            break;

        case CPAttachedWindowGravityRight:
            CGContextMoveToPoint(context, aRect.origin.x, (aRect.size.height / 2 - (arrowWidth / 2)) + aRect.origin.y);
            CGContextAddLineToPoint(context, aRect.origin.x - arrowHeight, (aRect.size.height / 2) + aRect.origin.y);
            CGContextAddLineToPoint(context, aRect.origin.x, (aRect.size.height / 2 + (arrowWidth / 2) + aRect.origin.y));
            break;

        case CPAttachedWindowGravityDown:
            CGContextMoveToPoint(context, (aRect.size.width / 2 - (arrowWidth / 2)) + aRect.origin.x, aRect.origin.y);
            CGContextAddLineToPoint(context, (aRect.size.width / 2) + aRect.origin.x, aRect.origin.y - arrowHeight);
            CGContextAddLineToPoint(context, (aRect.size.width / 2) + (arrowWidth / 2) + aRect.origin.x , aRect.origin.y);
            break;

        case CPAttachedWindowGravityUp:
            CGContextMoveToPoint(context, (aRect.size.width / 2 - (arrowWidth / 2)) + aRect.origin.x, aRect.size.height + aRect.origin.y);
            CGContextAddLineToPoint(context, (aRect.size.width / 2) + aRect.origin.x, aRect.size.height + aRect.origin.y + arrowHeight);
            CGContextAddLineToPoint(context, (aRect.size.width / 2) + (arrowWidth / 2) + aRect.origin.x , aRect.size.height + aRect.origin.y);
            break;
    }

    //Draw it
    CGContextStrokePath(context);
    CGContextFillPath(context);
}


- (void)mouseDown:(CPEvent)anEvent
{
    _mouseDownPressed = YES;
    [super mouseDown:anEvent];
}

- (void)mouseUp:(CPEvent)anEvent
{
    _mouseDownPressed = NO;
    [super mouseUp:anEvent];
}

@end



@implementation _CPAttachedWindowViewBlack : _CPAttachedWindowView

- (id)initWithFrame:(CPRect)aFrame styleMask:(unsigned)aStyleMask
{
    if (self = [super initWithFrame:aFrame styleMask:aStyleMask])
    {
        _useGlowingEffect = YES;
        _strokeColor = [CPColor colorWithHexString:@"131313"];
        _backgroundTopColor = [CPColor colorWithHexString:@"363636"];
        _backgroundBottomColor = [CPColor colorWithHexString:@"212121"];
        _cursorSize = CPSizeMake(15, 10);
    }

    return self;
}

@end


@implementation _CPAttachedWindowViewWhite : _CPAttachedWindowView

- (id)initWithFrame:(CPRect)aFrame styleMask:(unsigned)aStyleMask
{
    if (self = [super initWithFrame:aFrame styleMask:aStyleMask])
    {
        _useGlowingEffect = YES;
        _strokeColor = [CPColor colorWithHexString:@"ADEDFF"];
        _backgroundTopColor = [CPColor colorWithHexString:@"ffffff"];
        _backgroundBottomColor = [CPColor colorWithHexString:@"ebebeb"];
        _cursorSize = CPSizeMake(15, 10);
    }

    return self;
}

@end