/*
 * _CPAttachedWindowView.j
 * AppKit
 *
 * Created by Antoine Mercadal
 * Copyright 2011 <primalmotion@archipelproject.org>
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


/*!
    @ignore

    A custom CPWindowView that manage border and cursor
*/
@implementation _CPAttachedWindowView : _CPWindowView
{
    BOOL            _mouseDownPressed           @accessors(getter=isMouseDownPressed, setter=setMouseDownPressed:);
    float           _arrowOffsetX               @accessors(property=arrowOffsetX);
    float           _arrowOffsetY               @accessors(property=arrowOffsetY);
    int             _appearance                 @accessors(property=appearance);
    unsigned        _preferredEdge              @accessors(property=preferredEdge);

    BOOL            _useGlowingEffect;
    CPColor         _backgroundColor;
    CPColor         _strokeColor;
    CPImage         _cursorBackgroundBottom;
    CPImage         _cursorBackgroundLeft;
    CPImage         _cursorBackgroundRight;
    CPImage         _cursorBackgroundTop;
    CPSize          _cursorSize;
}

/*!
    Compute the contentView frame from a given window frame

    @param aFrameRect the window frame
*/
- (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
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

/*!
    Compute the window frame from a given contentView frame

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

/*!
    Initialize the _CPWindowView
*/
- (id)initWithFrame:(CPRect)aFrame styleMask:(unsigned)aStyleMask
{
    if (self = [super initWithFrame:aFrame styleMask:aStyleMask])
    {
        var bundle = [CPBundle bundleForClass:[self class]];
        _arrowOffsetX = 0.0;
        _arrowOffsetY = 0.0;

        // @TODO: make this themable
        _useGlowingEffect = YES;
        _appearance = CPPopoverAppearanceMinimal;
        _cursorSize = CPSizeMake(15, 10);
    }

    return self;
}

/*!
    Hide the cursor
*/
- (void)hideCursor
{
    _cursorSize = CPSizeMakeZero();
    [self setNeedsDisplay:YES];
}

/*!
    Show the cursor
*/
- (void)showCursor
{
    _cursorSize = CPSizeMake(15, 10);
    [self setNeedsDisplay:YES];
    _mouseDownPressed = NO;
}

/*!
    Draw the view
*/
- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];

    if (_appearance == CPPopoverAppearanceMinimal)
    {
        _strokeColor = [CPColor colorWithCalibratedRed:(172.0 / 255) green:(172.0 / 255) blue:(172.0 / 255) alpha:1.0];
        _backgroundColor = [CPColor colorWithCalibratedRed:(241.0 / 255) green:(241.0 / 255) blue:(241.0 / 255) alpha:0.93];
    }
    else
    {
        _strokeColor = [CPColor colorWithCalibratedRed:(172.0 / 255) green:(172.0 / 255) blue:(172.0 / 255) alpha:1.0];
        _backgroundColor = [CPColor colorWithCalibratedRed:(50.0 / 255) green:(50.0 / 255) blue:(50.0 / 255) alpha:0.93];
    }


    var context = [[CPGraphicsContext currentContext] graphicsPort],
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
        var shadowColor = [[CPColor blackColor] colorWithAlphaComponent:.2],
            shadowSize = CGSizeMake(0, 0),
            shadowBlur = 15;

        //compensate for the shadow blur
        aRect.origin.x += shadowBlur;
        aRect.origin.y += shadowBlur;
        aRect.size.width -= shadowBlur * 2;
        aRect.size.height -= shadowBlur * 2;

        //set the shadow
        CGContextSetShadow(context, CGSizeMake(0,0), 20);
        CGContextSetShadowWithColor(context, shadowSize, shadowBlur, shadowColor);
    }

    CGContextSetFillColor(context, _backgroundColor);

    var xMin = _CGRectGetMinX(aRect),
        xMax = _CGRectGetMaxX(aRect),
        yMin = _CGRectGetMinY(aRect),
        yMax = _CGRectGetMaxY(aRect);

    // draw!
    switch (_preferredEdge)
    {
        case CPMinXEdge:
            // origin ne
            CGContextMoveToPoint(context, xMin + radius, yMin);

            // ne
            CGContextAddLineToPoint(context, xMax - radius, yMin);
            CGContextAddCurveToPoint(context, xMax - radius, yMin, xMax, yMin, xMax, yMin + radius);

            // arrow CPMinXEdge
            CGContextAddLineToPoint(context, xMax, (aRect.size.height / 2) + aRect.origin.y + _arrowOffsetY - (arrowHeight - 2));
            CGContextAddLineToPoint(context, aRect.size.width + arrowHeight + aRect.origin.x + _arrowOffsetX, (aRect.size.height / 2) + aRect.origin.y + _arrowOffsetY);
            CGContextAddLineToPoint(context, aRect.size.width + aRect.origin.x + _arrowOffsetX, (aRect.size.height / 2 + (arrowWidth / 2)) + aRect.origin.y + _arrowOffsetY);

            // se
            CGContextAddLineToPoint(context, xMax, yMax - radius);
            CGContextAddCurveToPoint(context, xMax, yMax - radius, xMax, yMax, xMax - radius, yMax);

            // sw
            CGContextAddLineToPoint(context, xMin + radius, yMax);
            CGContextAddCurveToPoint(context, xMin + radius, yMax, xMin, yMax, xMin, yMax - radius);

            // nw
            CGContextAddLineToPoint(context, xMin, yMin + radius);
            CGContextAddCurveToPoint(context, xMin, yMin + radius, xMin, yMin, xMin + radius, yMin);
            break;

        case CPMaxXEdge:
            // origin ne
            CGContextMoveToPoint(context, xMin + radius, yMin);

            // ne
            CGContextAddLineToPoint(context, xMax - radius, yMin);
            CGContextAddCurveToPoint(context, xMax - radius, yMin, xMax, yMin, xMax, yMin + radius);

            // se
            CGContextAddLineToPoint(context, xMax, yMax - radius);
            CGContextAddCurveToPoint(context, xMax, yMax - radius, xMax, yMax, xMax - radius, yMax);

            // sw
            CGContextAddLineToPoint(context, xMin + radius, yMax);
            CGContextAddCurveToPoint(context, xMin + radius, yMax, xMin, yMax, xMin, yMax - radius);

            // arrow CPMaxXEdge
            CGContextAddLineToPoint(context, xMin, (aRect.size.height / 2 + (arrowWidth / 2) + aRect.origin.y + _arrowOffsetY));
            CGContextAddLineToPoint(context, aRect.origin.x - arrowHeight + _arrowOffsetX, (aRect.size.height / 2) + aRect.origin.y + _arrowOffsetY);
            CGContextAddLineToPoint(context, aRect.origin.x + _arrowOffsetX, (aRect.size.height / 2 - (arrowWidth / 2) + aRect.origin.y + _arrowOffsetY));

            // nw
            CGContextAddLineToPoint(context, xMin, yMin + radius);
            CGContextAddCurveToPoint(context, xMin, yMin + radius, xMin, yMin, xMin + radius, yMin);

            break;

        case CPMaxYEdge:
            // origin nw
            CGContextMoveToPoint(context, xMin, yMin + yMin);

            // nw
            CGContextAddLineToPoint(context, xMin, yMin + radius);
            CGContextAddCurveToPoint(context, xMin, yMin + radius, xMin, yMin, xMin + radius, yMin);

            // arrow CPMaxYEdge
            CGContextAddLineToPoint(context, (aRect.size.width / 2) + aRect.origin.x + _arrowOffsetX - (arrowWidth / 2), yMin);
            CGContextAddLineToPoint(context, (aRect.size.width / 2) + aRect.origin.x + _arrowOffsetX, aRect.origin.y - arrowHeight + _arrowOffsetY);
            CGContextAddLineToPoint(context, (aRect.size.width / 2) + (arrowWidth / 2) + aRect.origin.x + _arrowOffsetX, aRect.origin.y + _arrowOffsetY);

            // ne
            CGContextAddLineToPoint(context, xMax - radius, yMin);
            CGContextAddCurveToPoint(context, xMax - radius, yMin, xMax, yMin, xMax, yMin + radius);

            // se
            CGContextAddLineToPoint(context, xMax, yMax - radius);
            CGContextAddCurveToPoint(context, xMax, yMax - radius, xMax, yMax, xMax - radius, yMax);

            // sw
            CGContextAddLineToPoint(context, xMin + radius, yMax);
            CGContextAddCurveToPoint(context, xMin + radius, yMax, xMin, yMax, xMin, yMax - radius);
            break;

        case CPMinYEdge:
            // origin nw
            CGContextMoveToPoint(context, xMin, yMin + yMin);

            // nw
            CGContextAddLineToPoint(context, xMin, yMin + radius);
            CGContextAddCurveToPoint(context, xMin, yMin + radius, xMin, yMin, xMin + radius, yMin);

            // ne
            CGContextAddLineToPoint(context, xMax - radius, yMin);
            CGContextAddCurveToPoint(context, xMax - radius, yMin, xMax, yMin, xMax, yMin + radius);

            // se
            CGContextAddLineToPoint(context, xMax, yMax - radius);
            CGContextAddCurveToPoint(context, xMax, yMax - radius, xMax, yMax, xMax - radius, yMax);

            // arrow CPMinYEdge
            CGContextAddLineToPoint(context,  (aRect.size.width / 2) + (arrowWidth / 2) + aRect.origin.x + _arrowOffsetX , yMax);
            CGContextAddLineToPoint(context, (aRect.size.width / 2) + aRect.origin.x + _arrowOffsetX, aRect.size.height + aRect.origin.y + arrowHeight + _arrowOffsetY);
            CGContextAddLineToPoint(context, (aRect.size.width / 2) - (arrowWidth / 2) + aRect.origin.x + _arrowOffsetX, aRect.size.height + aRect.origin.y + _arrowOffsetY);

            // sw
            CGContextAddLineToPoint(context, xMin + radius, yMax);
            CGContextAddCurveToPoint(context, xMin + radius, yMax, xMin, yMax, xMin, yMax - radius);
            break;

        default:
            // no computed edge means standard rounded rect
            CGContextAddPath(context, CGPathWithRoundedRectangleInRect(aRect, radius, radius, YES, YES, YES, YES));
    }

    CGContextClosePath(context);

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
