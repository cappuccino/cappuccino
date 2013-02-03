/*
 * _CPPopoverWindowView.j
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

@import <Foundation/CPGeometry.j>

@import "CGGeometry.j"
@import "CGGradient.j"
@import "_CPWindowView.j"

@global CPPopoverAppearanceMinimal

var _CPPopoverWindowViewDefaultCursorSize = _CGSizeMake(16, 10),
    _CPPopoverWindowViewRadius = 5.0,
    _CPPopoverWindowViewStrokeWidth = 1.0,
    _CPPopoverWindowViewShadowSize = _CGSizeMake(0, 6),
    _CPPopoverWindowViewShadowBlur = 15.0;

/*!
    @ignore

    A custom CPWindowView that manages a border and cursor
*/
@implementation _CPPopoverWindowView : _CPWindowView
{
    float       _arrowOffsetX   @accessors(property=arrowOffsetX);
    float       _arrowOffsetY   @accessors(property=arrowOffsetY);
    int         _appearance     @accessors(property=appearance);
    unsigned    _preferredEdge  @accessors(property=preferredEdge);

    CGSize      _cursorSize;
}

+ (CPString)defaultThemeClass
{
    return @"popover-window-view";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[[CPNull null],
                                                [CPNull null],
                                                [CPNull null],
                                                [CPNull null]]
                                       forKeys:[@"background-gradient",
                                                @"background-gradient-hud",
                                                @"stroke-color",
                                                @"stroke-color-hud"]];
}

/*!
    Compute the contentView frame from a given window frame

    @param aFrameRect the window frame
*/
- (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    var contentRect = _CGRectMakeCopy(aFrameRect),
        modifierX = 16,
        modifierY = 19;

    // @todo change border art and remove this pixel perfect adaptation
    //
    // @comment: If we use this, each time we open the popover, the content
    // view is reduced a little over and over
    // return _CGRectInset(contentRect, modifierX, modifierY);

    contentRect.origin.x += modifierX;
    contentRect.origin.y += modifierY;
    contentRect.size.width -= modifierX * 2;
    contentRect.size.height -= modifierY * 2;

    return contentRect;
}

/*!
    Compute the window frame from a given contentView frame

    @param aContentRect the contentView frame
*/
+ (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    var frameRect = _CGRectMakeCopy(aContentRect),
        modifierX = 16,
        modifierY = 19;

    // @todo change border art and remove this pixel perfect adaptation
    // @comment: If we use this, each time we open the popover, the content
    //
    // view is reduced a little over and over
    // return _CGRectOffset(frameRect, modifierX, modifierY);

    frameRect.origin.x -= modifierX;
    frameRect.origin.y -= modifierY;
    frameRect.size.width += modifierX * 2;
    frameRect.size.height += modifierY * 2;

    return frameRect;
}

/*!
    Initialize the _CPWindowView
*/
- (id)initWithFrame:(CGRect)aFrame styleMask:(unsigned)aStyleMask
{
    if (self = [super initWithFrame:aFrame styleMask:aStyleMask])
    {
        _arrowOffsetX = 0.0;
        _arrowOffsetY = 0.0;
        _appearance = CPPopoverAppearanceMinimal;
        _cursorSize = _CGSizeMakeCopy(_CPPopoverWindowViewDefaultCursorSize);
    }

    return self;
}

/*!
    Hide the cursor
*/
- (void)hideCursor
{
    _cursorSize = _CGSizeMakeZero();
    [self setNeedsDisplay:YES];
}

/*!
    Show the cursor
*/
- (void)showCursor
{
    _cursorSize = _CGSizeMakeCopy(_CPPopoverWindowViewDefaultCursorSize);
    [self setNeedsDisplay:YES];
}

/*!
    Draw the view
*/
- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        radius = _CPPopoverWindowViewRadius,
        arrowWidth = _cursorSize.width,
        arrowHeight = _cursorSize.height,
        strokeWidth = _CPPopoverWindowViewStrokeWidth,
        halfStrokeWidth = strokeWidth / 2.0,
        strokeColor,
        shadowColor = [[CPColor blackColor] colorWithAlphaComponent:.2],
        shadowSize = _CPPopoverWindowViewShadowSize,
        shadowBlur = _CPPopoverWindowViewShadowBlur,
        gradient,
        frame = [self bounds];

    if (_appearance == CPPopoverAppearanceMinimal)
    {
        gradient = [self valueForThemeAttribute:@"background-gradient"];
        strokeColor = [self valueForThemeAttribute:@"stroke-color"];
    }
    else
    {
        gradient = [self valueForThemeAttribute:@"background-gradient-hud"];
        strokeColor = [self valueForThemeAttribute:@"stroke-color-hud"];
    }

    // fix rect to take care of stroke and shadow
    frame.origin.x += halfStrokeWidth + shadowBlur;
    frame.origin.y += halfStrokeWidth + (shadowBlur + shadowSize.height / 2);
    frame.size.width -= strokeWidth + (shadowBlur * 2);
    frame.size.height -= strokeWidth + (shadowBlur * 2 + shadowSize.height);

    CGContextSetStrokeColor(context, strokeColor);
    CGContextSetLineWidth(context, strokeWidth);
    CGContextBeginPath(context);
    CGContextSetShadowWithColor(context, shadowSize, shadowBlur, shadowColor);
    CGContextDrawLinearGradient(context, gradient, _CGPointMake(_CGRectGetMidX(frame), 0.0), _CGPointMake(_CGRectGetMidX(frame), frame.size.height), 0);

    var xMin = _CGRectGetMinX(frame),
        xMax = _CGRectGetMaxX(frame),
        yMin = _CGRectGetMinY(frame),
        yMax = _CGRectGetMaxY(frame),
        arrowMinX = CGAlignCoordinate(xMin + radius + strokeWidth),
        arrowMaxX = CGAlignCoordinate(xMax - radius - strokeWidth),
        arrowMinY = CGAlignCoordinate(yMin + radius + strokeWidth),
        arrowMaxY = CGAlignCoordinate(yMax - radius + strokeWidth),
        arrowAnchor = _CGPointMakeZero(),
        arrowStart = _CGPointMakeZero(),
        pt = _CGPointMakeZero();

    // draw!
    switch (_preferredEdge)
    {
        case CPMinXEdge:
        case CPMaxXEdge:
            // origin nw
            pt.x = CGAlignCoordinate(xMin + radius);
            pt.y = yMin;
            CGContextMoveToPoint(context, pt.x, pt.y);

            // ne
            pt.x = CGAlignCoordinate(xMax - radius);
            CGContextAddLineToPoint(context, pt.x, pt.y);
            CGContextAddCurveToPoint(context, pt.x, pt.y, xMax, yMin, xMax, CGAlignCoordinate(yMin + radius));

            if (_preferredEdge === CPMinXEdge)
            {
                // arrow CPMinXEdge
                arrowAnchor.x = CGAlignStroke(xMax, strokeWidth);
                arrowAnchor.y = CGAlignCoordinate((frame.size.height / 2) + yMin + _arrowOffsetY);

                // to top edge
                pt.y = CGAlignCoordinate(arrowAnchor.y - (arrowWidth / 2));

                // adjust starting point to not go beyond the corner
                if (pt.y <= arrowMinY)
                    pt.y = arrowMinY;
                else if ((pt.y + arrowWidth) > arrowMaxY)
                    pt.y = arrowMaxY - arrowWidth;

                pt.x = arrowAnchor.x;
                arrowStart = _CGPointMakeCopy(pt);
                CGContextAddLineToPoint(context, pt.x, pt.y);

                // top edge -> point
                pt.x = CGAlignStroke(arrowAnchor.x + arrowHeight, strokeWidth);
                pt.y = arrowAnchor.y;
                CGContextAddLineToPoint(context, pt.x, pt.y);

                // point -> bottom edge
                pt.x = arrowAnchor.x;
                pt.y = CGAlignCoordinate(arrowStart.y + arrowWidth);
                CGContextAddLineToPoint(context, pt.x, pt.y);
            }

            // se
            pt.x = xMax;
            pt.y = CGAlignCoordinate(yMax - radius);
            CGContextAddLineToPoint(context, pt.x, pt.y);
            CGContextAddCurveToPoint(context, pt.x, pt.y, pt.x, yMax, CGAlignCoordinate(xMax - radius), yMax);

            // sw
            pt.x = CGAlignCoordinate(xMin + radius);
            pt.y = yMax;
            CGContextAddLineToPoint(context, pt.x, pt.y);
            CGContextAddCurveToPoint(context, pt.x, pt.y, xMin, pt.y, xMin, CGAlignCoordinate(yMax - radius));

            if (_preferredEdge === CPMaxXEdge)
            {
                // arrow CPMaxXEdge
                arrowAnchor.x = CGAlignStroke(xMin, strokeWidth);
                arrowAnchor.y = CGAlignCoordinate((frame.size.height / 2) + yMin + _arrowOffsetY);

                // to bottom edge
                pt.y = CGAlignCoordinate(arrowAnchor.y + (arrowWidth / 2));

                // adjust starting point to not go beyond the corner
                if ((pt.y - arrowWidth) < arrowMinY)
                    pt.y = arrowMinY + arrowWidth;
                else if (pt.y > arrowMaxY)
                    pt.y = arrowMaxY;

                pt.x = arrowAnchor.x;
                arrowStart = _CGPointMakeCopy(pt);
                CGContextAddLineToPoint(context, pt.x, pt.y);

                // bottom edge -> point
                pt.x = CGAlignStroke(arrowAnchor.x - arrowHeight, strokeWidth);
                pt.y = arrowAnchor.y;
                CGContextAddLineToPoint(context, pt.x, pt.y);

                // point -> top edge
                pt.x = arrowAnchor.x;
                pt.y = CGAlignCoordinate(arrowStart.y - arrowWidth);
                CGContextAddLineToPoint(context, pt.x, pt.y);
            }

            // nw
            pt.x = xMin;
            pt.y = CGAlignCoordinate(yMin + radius);
            CGContextAddLineToPoint(context, pt.x, pt.y);
            CGContextAddCurveToPoint(context, pt.x, pt.y, pt.x, yMin, CGAlignCoordinate(xMin + radius), yMin);
            break;

        case CPMaxYEdge:
        case CPMinYEdge:
            // origin sw
            pt.x = xMin;
            pt.y = CGAlignCoordinate(yMax - radius);
            CGContextMoveToPoint(context, pt.x, pt.y);

            // nw
            pt.y = CGAlignCoordinate(yMin + radius);
            CGContextAddLineToPoint(context, pt.x, pt.y);
            CGContextAddCurveToPoint(context, pt.x, pt.y, pt.x, yMin, CGAlignCoordinate(xMin + radius), yMin);

            if (_preferredEdge === CPMaxYEdge)
            {
                // arrow CPMaxYEdge
                arrowAnchor.x = CGAlignCoordinate((frame.size.width / 2) + xMin + _arrowOffsetX);
                arrowAnchor.y = CGAlignStroke(yMin + _arrowOffsetY, strokeWidth);

                // to left edge
                pt.x = CGAlignCoordinate(arrowAnchor.x - (arrowWidth / 2));

                // adjust starting point to not go beyond the corner
                if (pt.x < arrowMinX)
                    pt.x = arrowMinX;
                else if ((pt.x + arrowWidth) > arrowMaxX)
                    pt.x = arrowMaxX - arrowWidth;

                pt.y = arrowAnchor.y;
                arrowStart = _CGPointMakeCopy(pt);
                CGContextAddLineToPoint(context, pt.x, pt.y);

                // left edge -> point
                pt.x = arrowAnchor.x;
                pt.y = CGAlignStroke(arrowAnchor.y - arrowHeight, strokeWidth);
                CGContextAddLineToPoint(context, pt.x, pt.y);

                // point -> right edge
                pt.x = CGAlignCoordinate(arrowStart.x + arrowWidth);
                pt.y = arrowAnchor.y;
                CGContextAddLineToPoint(context, pt.x, pt.y);
            }

            // ne
            pt.x = CGAlignCoordinate(xMax - radius);
            pt.y = yMin;
            CGContextAddLineToPoint(context, pt.x, pt.y);
            CGContextAddCurveToPoint(context, pt.x, pt.y, xMax, pt.y, xMax, CGAlignCoordinate(yMin + radius));

            // se
            pt.x = xMax;
            pt.y = CGAlignCoordinate(yMax - radius);
            CGContextAddLineToPoint(context, pt.x, pt.y);
            CGContextAddCurveToPoint(context, pt.x, pt.y, pt.x, yMax, CGAlignCoordinate(xMax - radius), yMax);

            if (_preferredEdge === CPMinYEdge)
            {
                // arrow CPMinYEdge
                arrowAnchor.x = CGAlignCoordinate((frame.size.width / 2) + xMin + _arrowOffsetX);
                arrowAnchor.y = CGAlignStroke(yMax + _arrowOffsetY, strokeWidth);

                // to right edge
                pt.x = CGAlignCoordinate(arrowAnchor.x + (arrowWidth / 2));

                // adjust starting point to not go beyond the corner
                if ((pt.x - arrowWidth) < arrowMinX)
                    pt.x = arrowMinX + arrowWidth;
                else if (pt.x > arrowMaxX)
                    pt.x = arrowMaxX;

                pt.y = arrowAnchor.y;
                arrowStart = _CGPointMakeCopy(pt);
                CGContextAddLineToPoint(context, pt.x, pt.y);

                // right edge -> point
                pt.x = arrowAnchor.x;
                pt.y = CGAlignStroke(arrowAnchor.y + arrowHeight, strokeWidth);
                CGContextAddLineToPoint(context, pt.x, pt.y);

                // point -> left edge
                pt.x = CGAlignCoordinate(arrowStart.x - arrowWidth);
                pt.y = arrowAnchor.y;
                CGContextAddLineToPoint(context, pt.x, pt.y);
            }

            // sw
            pt.x = CGAlignCoordinate(xMin + radius);
            pt.y = yMax;
            CGContextAddLineToPoint(context, pt.x, pt.y);
            CGContextAddCurveToPoint(context, pt.x, pt.y, xMin, pt.y, xMin, CGAlignCoordinate(yMax - radius));
            break;

        default:
            // no computed edge means standard rounded rect
            CGContextAddPath(context, CGPathWithRoundedRectangleInRect(frame, radius, radius, YES, YES, YES, YES));
    }

    CGContextClosePath(context);
    CGContextStrokePath(context);
    CGContextFillPath(context);
}

@end
