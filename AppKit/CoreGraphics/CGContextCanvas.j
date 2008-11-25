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

#define _CGContextAddRectCanvas(aContext, aRect) aContext.rect(_CGRectGetMinX(aRect), _CGRectGetMinY(aRect), _CGRectGetWidth(aRect), _CGRectGetHeight(aRect))
#define _CGContextBeginPathCanvas(aContext) aContext.beginPath()
#define _CGContextFillRectCanvas(aContext, aRect) aContext.fillRect(_CGRectGetMinX(aRect), _CGRectGetMinY(aRect), _CGRectGetWidth(aRect), _CGRectGetHeight(aRect))
#define _CGContextClipCanvas(aContext) aContext.clip()

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
    // Despite the documentation saying otherwise, the last parameter is anti-clockwise not clockwise.
    // http://developer.mozilla.org/en/docs/Canvas_tutorial:Drawing_shapes#Arcs
    _CGContextAddArcCanvas(aContext, x, y, radius, startAngle, endAngle, !clockwise);
}

function CGContextAddArcToPoint(aContext, x1, y1, x2, y2, radius)
{
    _CGContextAddArcToPointCanvas(aContext, x1, y1, x2, y2, radius);
}

function CGContextAddCurveToPoint(aContext, cp1x, cp1y, cp2x, cp2y, x, y)
{
    _CGContextAddCurveToPointCanvas(aContext, cp1x, cp1y, cp2x, cp2y, x, y);
}

function CGContextAddLineToPoint(aContext, x, y)
{
    _CGContextAddLineToPointCanvas(aContext, x, y);
}

function CGContextAddPath(aContext, aPath)
{
    if (!aContext || CGPathIsEmpty(aPath))
        return;

    var elements = aPath.elements,
        
        i = 0,
        count = aPath.count;
    
    for (; i < count; ++i)
    {
        var element = elements[i],
            type = element.type;
            
        switch (type)
        {
            case kCGPathElementMoveToPoint:         _CGContextMoveToPointCanvas(aContext, element.x, element.y);
                                                    break;
            case kCGPathElementAddLineToPoint:      _CGContextAddLineToPointCanvas(aContext, element.x, element.y);
                                                    break;
            case kCGPathElementAddQuadCurveToPoint: _CGContextAddQuadCurveToPointCanvas(aContext, element.cpx, element.cpy, element.x, element.y);
                                                    break;
            case kCGPathElementAddCurveToPoint:     _CGContextAddCurveToPointCanvas(aContext, element.cp1x, element.cp1y, element.cp2x, element.cp2y, element.x, element.y);
                                                    break;
            case kCGPathElementCloseSubpath:        _CGContextClosePathCanvas(aContext);
                                                    break;
            case kCGPathElementAddArc:              _CGContextAddArcCanvas(aContext, element.x, element.y, element.radius, element.startAngle, element.endAngle, element.clockwise);
                                                    break;
            case kCGPathElementAddArcTo:            //_CGContextAddArcToPointCanvas(aContext, element.cp1x, element.cp1.y, element.cp2.x, element.cp2y, element.radius);
                                                    break;
        }
    }
}

function CGContextAddRect(aContext, aRect)
{
    _CGContextAddRectCanvas(aContext, aRect);
}

function CGContextAddRects(aContext, rects, count)
{
    var i = 0;
    
    if (arguments["count"] == NULL)
        var count = rects.length;
    
    for (; i < count; ++i)
    {
        var rect = rects[i];
        _CGContextAddRectCanvas(aContext, rect);
    }
}

function CGContextBeginPath(aContext)
{
    _CGContextBeginPathCanvas(aContext);
}

function CGContextClosePath(aContext)
{
    _CGContextClosePathCanvas(aContext);
}

function CGContextMoveToPoint(aContext, x, y)
{
    _CGContextMoveToPointCanvas(aContext, x, y);
}

function CGContextClearRect(aContext, aRect)
{
    aContext.clearRect(_CGRectGetMinX(aRect), _CGRectGetMinY(aRect), _CGRectGetWidth(aRect), _CGRectGetHeight(aRect));
}

function CGContextDrawPath(aContext, aMode)
{
    if (aMode == kCGPathFill || aMode == kCGPathFillStroke)
        aContext.fill();
    else if (aMode == kCGPathEOFill || aMode == kCGPathEOFillStroke)
        alert("not implemented!!!");
    
    if (aMode == kCGPathStroke || aMode == kCGPathFillStroke || aMode == kCGPathEOFillStroke)
        aContext.stroke();
}

function CGContextFillRect(aContext, aRect)
{
    _CGContextFillRectCanvas(aContext, aRect);
}

function CGContextFillRects(aContext, rects, count)
{
    var i = 0;
    
    if (arguments["count"] == NULL)
        var count = rects.length;
    
    for (; i < count; ++i)
    {
        var rect = rects[i];
        _CGContextFillRectCanvas(aContext, rect);
    }
}

function CGContextStrokeRect(aContext, aRect)
{
    aContext.strokeRect(_CGRectGetMinX(aRect), _CGRectGetMinY(aRect), _CGRectGetWidth(aRect), _CGRectGetHeight(aRect));
}

function CGContextClip(aContext)
{
    _CGContextClipCanvas(aContext);
}

function CGContextClipToRect(aContext, aRect)
{
    _CGContextBeginPathCanvas(aContext);
    _CGContextAddRectCanvas(aContext, aRect);
    _CGContextClosePathCanvas(aContext);
    
    _CGContextClipCanvas(aContext);
}

function CGContextClipToRects(aContext, rects, count)
{
    if (arguments["count"] == NULL)
        var count = rects.length;

    _CGContextBeginPathCanvas(aContext);
    CGContextAddRects(aContext, rects, count);
    _CGContextClipCanvas(aContext);
}

function CGContextSetAlpha(aContext, anAlpha)
{
    aContext.globalAlpha = anAlpha;
}

function CGContextSetFillColor(aContext, aColor)
{
    aContext.fillStyle = [aColor cssString];
}

function CGContextSetStrokeColor(aContext, aColor)
{
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

#define scale_rotate(a, b, c, d) \
        var sign = (a * d < 0.0 || b * c > 0.0) ? -1.0 : 1.0, \
            a2 = (ATAN2(b, d) + ATAN2(-sign * c, sign * a)) / 2.0, \
            cos = COS(a2),\
            sin = SIN(a2);\
        \
        if (cos == 0)\
        {\
            sx = -c / sin;\
            sy = b / sin;\
        }\
        else if (sin == 0)\
        {\
            sx = a / cos;\
            sy = d / cos;\
        }\
        else\
        {\
            abs_cos = ABS(cos);\
            abs_sin = ABS(sin);\
            \
            sx = (abs_cos * a / cos + abs_sin * -c / sin) / (abs_cos + abs_sin);\
            sy = (abs_cos * d / cos + abs_sin * b / sin) / (abs_cos + abs_sin);\
        }\
        
#define rotate_scale(a, b, c, d) \
        var sign = (a * d < 0.0 || b * c > 0.0) ? -1.0 : 1.0;\
            a1 = (Math.atan2(sign * b, sign * a) + Math.atan2(-c, d)) / 2.0,\
            cos = COS(a1),\
            sin = SIN(a1);\
               \
        if (cos == 0)\
        {\
            sx = b / sin;\
            sy = -c / sin;\
        }\
        else if (sin == 0)\
        {\
            sx = a / cos;\
            sy = d / cos;\
        }\
        else\
        {\
            abs_cos = ABS(cos);\
            abs_sin = ABS(sin);\
            \
            sx = (abs_cos * a / cos + abs_sin * b / sin) / (abs_cos + abs_sin);\
            sy = (abs_cos * d / cos + abs_sin * -c / sin) / (abs_cos + abs_sin);\
        }\

function eigen(anAffineTransform)
{
    alert("IMPLEMENT ME!");
}


if (CPFeatureIsCompatible(CPJavaScriptCanvasTransformFeature))
{

CGContextConcatCTM = function(aContext, anAffineTransform)
{
    aContext.transform(anAffineTransform.a, anAffineTransform.b, anAffineTransform.c, anAffineTransform.d, anAffineTransform.tx, anAffineTransform.ty);
}

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
    if (b == 0.0 && c == 0.0)
    {
        sx = a;
        sy = d;
    }
    
    // a scale followed by a rotate
    else if (a * b == -c * d)
    {
        scale_rotate(a, b, c, d)
    }
        
    // rotate, then scale.
    else if (a * c == -b * d)
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
}

}

function CGContextDrawImage(aContext, aRect, anImage)
{
    aContext.drawImage(anImage._image, _CGRectGetMinX(aRect), _CGRectGetMinY(aRect), _CGRectGetWidth(aRect), _CGRectGetHeight(aRect));
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
}

function CGBitmapGraphicsContextCreate()
{
    var DOMElement = document.createElement("canvas"),
        context = DOMElement.getContext("2d");
    
    context.DOMElement = DOMElement;
    
    return context;
}
