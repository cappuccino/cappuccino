/*
 * CGContextCanvas.j
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

var CANVAS_LINECAP_TABLE    = [ "butt", "round", "square" ],
    CANVAS_LINEJOIN_TABLE   = [ "miter", "round", "bevel" ],
    CANVAS_COMPOSITE_TABLE  = [ "source-over", "source-over", "source-over", "source-over", "darker",
                                "lighter", "source-over", "source-over", "source-over", "source-over",
                                "source-over", "source-over", "source-over", "source-over", "source-over",
                                "source-over", "source-over",
                                "copy", "source-in", "source-out", "source-atop",
                                "destination-over", "destination-in", "destination-out", "destination-atop",
                                "xor", "source-over", "source-over" ];

#define _CGContextAddArcCanvas(aContext, x, y, radius, startAngle, endAngle, anticlockwise) aContext.arc(x, y, radius, startAngle, endAngle, anticlockwise)
#define _CGContextAddArcToPointCanvas(aContext, x1, y1, x2, y2, radius) aContext.arcTo(x1, y1, x2, y2, radius)
#define _CGContextAddCurveToPointCanvas(aContext, cp1x, cp1y, cp2x, cp2y, x, y) aContext.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y)
#define _CGContextAddQuadCurveToPointCanvas(aContext, cpx, cpy, x, y) aContext.quadraticCurveTo(cpx, cpy, x, y)
#define _CGContextAddLineToPointCanvas(aContext, x, y) aContext.lineTo(x, y)
#define _CGContextClosePathCanvas(aContext) aContext.closePath()
#define _CGContextMoveToPointCanvas(aContext, x, y) aContext.moveTo(x, y)

#define _CGContextAddRectCanvas(aContext, aRect) aContext.rect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect))
#define _CGContextBeginPathCanvas(aContext) aContext.beginPath()
#define _CGContextFillRectCanvas(aContext, aRect) aContext.fillRect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect))
#define _CGContextClipCanvas(aContext) aContext.clip()

// In Cocoa, all primitives excepts rects cannot be added to the context's path
// until a move to point has been done, because an empty path has no current point.
var hasPath = function(aContext, methodName)
{
    if (!aContext.hasPath)
        CPLog.error(methodName + ": no current point");

    return aContext.hasPath;
}

function CGContextSaveGState(aContext)
{
    aContext.save();
}

function CGContextRestoreGState(aContext)
{
    aContext.restore();
}

function CGContextSetLineCap(aContext, aLineCap)
{
    aContext.lineCap = CANVAS_LINECAP_TABLE[aLineCap];
}

function CGContextSetLineDash(aContext, aPhase, someDashes)
{
    if (aContext.setLineDash)
    {
        aContext.setLineDash(someDashes);
        aContext.lineDashOffset = aPhase;
    }
    else if (typeof aContext['webkitLineDash'] !== 'undefined')
    {
        aContext.webkitLineDash = someDashes;
        aContext.webkitLineDashOffset = aPhase;
    }
    else if (typeof aContext['mozDash'] !== 'undefined')
    {
        aContext.mozDash = someDashes;
        aContext.mozDashOffset = aPhase;
    }
    else if (someDashes)
    {
        CPLog.warn("CGContextSetLineDash not implemented in this environment.")
    }
}

function CGContextSetLineJoin(aContext, aLineJoin)
{
    aContext.lineJoin = CANVAS_LINEJOIN_TABLE[aLineJoin];
}

function CGContextSetLineWidth(aContext, aLineWidth)
{
    aContext.lineWidth = aLineWidth;
}

function CGContextSetMiterLimit(aContext, aMiterLimit)
{
    aContext.miterLimit = aMiterLimit;
}

function CGContextSetBlendMode(aContext, aBlendMode)
{
    aContext.globalCompositeOperation = CANVAS_COMPOSITE_TABLE[aBlendMode];
}

function CGContextAddArc(aContext, x, y, radius, startAngle, endAngle, clockwise)
{
    if (!hasPath(aContext, "CGContextAddArc"))
        return;

    // Despite the documentation saying otherwise, the last parameter is anti-clockwise not clockwise.
    // http://developer.mozilla.org/en/docs/Canvas_tutorial:Drawing_shapes#Arcs
    _CGContextAddArcCanvas(aContext, x, y, radius, startAngle, endAngle, !clockwise);
}

function CGContextAddArcToPoint(aContext, x1, y1, x2, y2, radius)
{
    if (!hasPath(aContext, "CGContextAddArcToPoint"))
        return;

    _CGContextAddArcToPointCanvas(aContext, x1, y1, x2, y2, radius);
}

function CGContextAddCurveToPoint(aContext, cp1x, cp1y, cp2x, cp2y, x, y)
{
    if (!hasPath(aContext, "CGContextAddCurveToPoint"))
        return;

    _CGContextAddCurveToPointCanvas(aContext, cp1x, cp1y, cp2x, cp2y, x, y);
}

function CGContextAddLines(aContext, points, count)
{
    // implementation mirrors that of CGPathAddLines()
    if (count === null || count === undefined)
        count = points.length;

    if (count < 1)
        return;

    _CGContextMoveToPointCanvas(aContext, points[0].x, points[0].y);

    for (var i = 1; i < count; ++i)
        _CGContextAddLineToPointCanvas(aContext, points[i].x, points[i].y);

    aContext.hasPath = YES;
}

function CGContextAddLineToPoint(aContext, x, y)
{
    if (!hasPath(aContext, "CGContextAddLineToPoint"))
        return;

    _CGContextAddLineToPointCanvas(aContext, x, y);
}

function CGContextAddPath(aContext, aPath)
{
    if (!aContext || CGPathIsEmpty(aPath))
        return;

    // If the context does not have a path, explicitly begin one
    if (!aContext.hasPath)
        _CGContextBeginPathCanvas(aContext);

    // We must implicitly move to the start of the path
    _CGContextMoveToPointCanvas(aContext, aPath.start.x, aPath.start.y);

    var elements = aPath.elements,
        i = 0,
        count = aPath.count;

    for (; i < count; ++i)
    {
        var element = elements[i],
            type = element.type;

        switch (type)
        {
            case kCGPathElementMoveToPoint:
                _CGContextMoveToPointCanvas(aContext, element.x, element.y);
                break;

            case kCGPathElementAddLineToPoint:
                _CGContextAddLineToPointCanvas(aContext, element.x, element.y);
                break;

            case kCGPathElementAddQuadCurveToPoint:
                _CGContextAddQuadCurveToPointCanvas(aContext, element.cpx, element.cpy, element.x, element.y);
                break;

            case kCGPathElementAddCurveToPoint:
                _CGContextAddCurveToPointCanvas(aContext, element.cp1x, element.cp1y, element.cp2x, element.cp2y, element.x, element.y);
                break;

            case kCGPathElementCloseSubpath:
                _CGContextClosePathCanvas(aContext);
                break;

            case kCGPathElementAddArc:
                _CGContextAddArcCanvas(aContext, element.x, element.y, element.radius, element.startAngle, element.endAngle, element.clockwise);
                break;

            case kCGPathElementAddArcToPoint:
                _CGContextAddArcToPointCanvas(aContext, element.p1x, element.p1y, element.p2x, element.p2y, element.radius);
                break;
        }
    }

    aContext.hasPath = YES;
}

function CGContextAddRect(aContext, aRect)
{
    _CGContextAddRectCanvas(aContext, aRect);
    aContext.hasPath = YES;
}

function CGContextAddQuadCurveToPoint(aContext, cpx, cpy, x, y)
{
    if (!hasPath(aContext, "CGContextAddQuadCurveToPoint"))
        return;

    _CGContextAddQuadCurveToPointCanvas(aContext, cpx, cpy, x, y);
}

function CGContextAddRects(aContext, rects, count)
{
    if (count === null || count === undefined)
        count = rects.length;

    for (var i = 0; i < count; ++i)
    {
        var rect = rects[i];
        _CGContextAddRectCanvas(aContext, rect);
    }

    aContext.hasPath = YES;
}

function CGContextBeginPath(aContext)
{
    _CGContextBeginPathCanvas(aContext);
    aContext.hasPath = NO;
}

function CGContextClosePath(aContext)
{
    _CGContextClosePathCanvas(aContext);
}

function CGContextIsPathEmpty(aContext)
{
    return !aContext.hasPath;
}

function CGContextMoveToPoint(aContext, x, y)
{
    _CGContextMoveToPointCanvas(aContext, x, y);
    aContext.hasPath = YES;
}

function CGContextClearRect(aContext, aRect)
{
    aContext.clearRect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
    aContext.hasPath = NO;
}

function CGContextDrawPath(aContext, aMode)
{
    if (!aContext.hasPath)
        return;

    if (aMode === kCGPathFill || aMode === kCGPathFillStroke)
        aContext.fill();
    else if (aMode === kCGPathStroke || aMode === kCGPathFillStroke || aMode === kCGPathEOFillStroke)
        aContext.stroke();
    else if (aMode === kCGPathEOFill || aMode === kCGPathEOFillStroke)
        CPLog.warn("Unimplemented fill mode in CGContextDrawPath: %d", aMode);

    aContext.hasPath = NO;
}

function CGContextFillRect(aContext, aRect)
{
    _CGContextFillRectCanvas(aContext, aRect);
    aContext.hasPath = NO;
}

function CGContextFillRects(aContext, rects, count)
{
    if (count === null || count === undefined)
        count = rects.length;

    for (var i = 0; i < count; ++i)
    {
        var rect = rects[i];
        _CGContextFillRectCanvas(aContext, rect);
    }

    aContext.hasPath = NO;
}

function CGContextStrokeRect(aContext, aRect)
{
    aContext.strokeRect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
    aContext.hasPath = NO;
}

function CGContextClip(aContext)
{
    _CGContextClipCanvas(aContext);
    aContext.hasPath = NO;
}

function CGContextClipToRect(aContext, aRect)
{
    _CGContextBeginPathCanvas(aContext);
    _CGContextAddRectCanvas(aContext, aRect);
    _CGContextClosePathCanvas(aContext);

    _CGContextClipCanvas(aContext);
    aContext.hasPath = NO;
}

function CGContextClipToRects(aContext, rects, count)
{
    if (count === null || count === undefined)
        count = rects.length;

    _CGContextBeginPathCanvas(aContext);
    CGContextAddRects(aContext, rects, count);
    _CGContextClipCanvas(aContext);
    aContext.hasPath = NO;
}

function CGContextSetAlpha(aContext, anAlpha)
{
    aContext.globalAlpha = anAlpha;
}

function CGContextSetFillColor(aContext, aColor)
{
    var patternImage = [aColor patternImage];

    if ([patternImage isSingleImage])
    {
        var pattern = aContext.createPattern([patternImage image], "repeat");

        aContext.fillStyle = pattern;
    }
    else
        aContext.fillStyle = [aColor cssString];
}

/*!
    Creates a context into which you can render a fill pattern
    of the given size. Once the pattern is rendered, you can
    set the fill or stroke pattern to the rendered pattern
    with CGContextSetFillPattern or CGContextSetStrokePattern.
*/
function CGContextCreatePatternContext(aContext, aSize)
{
    var pattern = document.createElement("canvas");

    pattern.width = aSize.width;
    pattern.height = aSize.height;

    return pattern.getContext("2d");
}

/*!
    Sets the fill pattern for aContext to the rendered pattern context
    returned by CGContextCreatePatternContext.
*/
function CGContextSetFillPattern(aContext, aPatternContext)
{
    var pattern = aContext.createPattern(aPatternContext.canvas, "repeat");
    aContext.fillStyle = pattern;
}

/*!
    Sets the stroke pattern for aContext to the rendered pattern context
    returned by CGContextCreatePatternContext.
*/
function CGContextSetStrokePattern(aContext, aPatternContext)
{
    var pattern = aContext.createPattern(aPatternContext.canvas, "repeat");
    aContext.strokeStyle = pattern;
}

function CGContextSetStrokeColor(aContext, aColor)
{
    var patternImage = [aColor patternImage];

    if ([patternImage isSingleImage])
    {
        var pattern = aContext.createPattern([patternImage image], "repeat");

        aContext.strokeStyle = pattern;
    }
    else
        aContext.strokeStyle = [aColor cssString];
}

function CGContextSetShadow(aContext, aSize, aBlur)
{
    aContext.shadowOffsetX = aSize.width;
    aContext.shadowOffsetY = aSize.height;
    aContext.shadowBlur = aBlur;
}

function CGContextSetShadowWithColor(aContext, aSize, aBlur, aColor)
{
    aContext.shadowOffsetX = aSize.width;
    aContext.shadowOffsetY = aSize.height;
    aContext.shadowBlur = aBlur;
    aContext.shadowColor = [aColor cssString];
}

function CGContextRotateCTM(aContext, anAngle)
{
    aContext.rotate(anAngle);
}

function CGContextScaleCTM(aContext, sx, sy)
{
    aContext.scale(sx, sy);
}

function CGContextTranslateCTM(aContext, tx, ty)
{
    aContext.translate(tx, ty);
}

var scale_rotate = function(a, b, c, d)
{
    var sign = (a * d < 0.0 || b * c > 0.0) ? -1.0 : 1.0,
        a2 = (ATAN2(b, d) + ATAN2(-sign * c, sign * a)) / 2.0,
        cos = COS(a2),
        sin = SIN(a2);

    if (cos === 0)
    {
        sx = -c / sin;
        sy = b / sin;
    }
    else if (sin === 0)
    {
        sx = a / cos;
        sy = d / cos;
    }
    else
    {
        abs_cos = ABS(cos);
        abs_sin = ABS(sin);

        sx = (abs_cos * a / cos + abs_sin * -c / sin) / (abs_cos + abs_sin);
        sy = (abs_cos * d / cos + abs_sin * b / sin) / (abs_cos + abs_sin);
    }
};

var rotate_scale = function(a, b, c, d)
{
    var sign = (a * d < 0.0 || b * c > 0.0) ? -1.0 : 1.0;
        a1 = (ATAN2(sign * b, sign * a) + ATAN2(-c, d)) / 2.0,
        cos = COS(a1),
        sin = SIN(a1);

    if (cos === 0)
    {
        sx = b / sin;
        sy = -c / sin;
    }
    else if (sin === 0)
    {
        sx = a / cos;
        sy = d / cos;
    }
    else
    {
        abs_cos = ABS(cos);
        abs_sin = ABS(sin);

        sx = (abs_cos * a / cos + abs_sin * b / sin) / (abs_cos + abs_sin);
        sy = (abs_cos * d / cos + abs_sin * -c / sin) / (abs_cos + abs_sin);
    }
};

function eigen(anAffineTransform)
{
    CPLog.warn("Unimplemented function: eigen");
}


if (CPFeatureIsCompatible(CPJavaScriptCanvasTransformFeature))
{

CGContextConcatCTM = function(aContext, anAffineTransform)
{
    aContext.transform(anAffineTransform.a, anAffineTransform.b, anAffineTransform.c, anAffineTransform.d, anAffineTransform.tx, anAffineTransform.ty);
};

}
else
{

CGContextConcatCTM = function(aContext, anAffineTransform)
{
    var a = anAffineTransform.a,
        b = anAffineTransform.b,
        c = anAffineTransform.c,
        d = anAffineTransform.d,
        tx = anAffineTransform.tx,
        ty = anAffineTransform.ty,
        sx = 1.0,
        sy = 1.0,
        a1 = 0.0,
        a2 = 0.0;

    // Detect the simple case of just scaling.
    if (b === 0.0 && c === 0.0)
    {
        sx = a;
        sy = d;
    }

    // a scale followed by a rotate
    else if (a * b === -c * d)
    {
        scale_rotate(a, b, c, d)
    }

    // rotate, then scale.
    else if (a * c === -b * d)
    {
        rotate_scale(a, b, c, d)
    }
    else
    {
        var transpose = CGAffineTransformMake(a, c, b, d, 0.0, 0.0), // inline
            u = eigen(CGAffineTransformConcat(anAffineTransform, transpose)),
            v = eigen(CGAffineTransformConcat(transpose, anAffineTransform)),
            U = CGAffineTransformMake(u.vector_1.x, u.vector_2.x, u.vector_1.y, u.vector_2.y, 0.0, 0.0), // inline
            VT = CGAffineTransformMake(v.vector_1.x, v.vector_1.y, v.vector_2.x, v.vector_2.y, 0.0, 0.0),
            S = CGAffineTransformConcat(CGAffineTransformConcat(CGAffineTransformInvert(U), anAffineTransform), CGAffineTransformInvert(VT));

        a = VT.a;
        b = VT.b;
        c = VT.c;
        d = VT.d;
        scale_rotate(a, b, c, d)
        S.a *= sx;
        S.d *= sy;
        a = U.a;
        b = U.b;
        c = U.c;
        d = U.d;
        rotate_scale(a, b, c, d)
        sx = S.a * sx;
        sy = S.d * sy;
    }

    if (tx != 0 || ty != 0)
        CGContextTranslateCTM(aContext, tx, ty);
    if (a1 != 0.0)
        CGContextRotateCTM(aContext, a1);
    if (sx != 1.0 || sy != 1.0)
        CGContextScaleCTM(aContext, sx, sy);
    if (a2 != 0.0)
        CGContextRotateCTM(aContext, a2);
};

}

function CGContextDrawImage(aContext, aRect, anImage)
{
    aContext.drawImage(anImage._image, CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
    aContext.hasPath = NO;
}

function to_string(aColor)
{
    return "rgba(" + ROUND(aColor.components[0] * 255) + ", " + ROUND(aColor.components[1] * 255) + ", " + ROUND(255 * aColor.components[2]) + ", " + aColor.components[3] + ")";
}

function CGContextDrawLinearGradient(aContext, aGradient, aStartPoint, anEndPoint, options)
{
    var colors = aGradient.colors,
        count = colors.length,

        linearGradient = aContext.createLinearGradient(aStartPoint.x, aStartPoint.y, anEndPoint.x, anEndPoint.y);

    while (count--)
        linearGradient.addColorStop(aGradient.locations[count], to_string(colors[count]));

    aContext.fillStyle = linearGradient;
    aContext.fill();
    aContext.hasPath = NO;
}

function CGBitmapGraphicsContextCreate()
{
    var DOMElement = document.createElement("canvas"),
        context = DOMElement.getContext("2d");

    context.DOMElement = DOMElement;

    // canvas gives us no way to query whether the path is empty or not, so we have to track it ourselves
    context.hasPath = NO;

    return context;
}
