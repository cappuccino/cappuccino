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

function CGCanvasGraphicsContext(aSize)
{
    CGContext.call(this);
    
    this.DOMElement = document.createElement("canvas");

    if (aSize)
    {
        this.DOMElement.width = aSize.width;
        this.DOMElement.height = aSize.height;
    }

    this.canvasAPI = this.DOMElement.getContext("2d");
    this.hasPath = NO;
}

CGCanvasGraphicsContext.prototype = Object.create(CGContext.prototype);

CGCanvasGraphicsContext.prototype.constructor = CGCanvasGraphicsContext;

function CGCanvasGraphicsContextCreate(aSize)
{
    return new CGCanvasGraphicsContext(aSize);
}

CGCanvasGraphicsContext.prototype.saveGState = function()
{
    this.canvasAPI.save();
}

CGCanvasGraphicsContext.prototype.restoreGState = function()
{
    this.canvasAPI.restore();
}

CGCanvasGraphicsContext.prototype.setLineCap = function(aLineCap)
{
    this.canvasAPI.lineCap = CANVAS_LINECAP_TABLE[aLineCap];
}

CGCanvasGraphicsContext.prototype.setLineDash = function(aPhase, someDashes)
{
    if (this.canvasAPI.setLineDash)
    {
        this.canvasAPI.setLineDash(someDashes);
        this.canvasAPI.lineDashOffset = aPhase;
    }
    else if (typeof this.canvas['webkitLineDash'] !== 'undefined')
    {
        this.canvasAPI.webkitLineDash = someDashes;
        this.canvasAPI.webkitLineDashOffset = aPhase;
    }
    else if (typeof this.canvas['mozDash'] !== 'undefined')
    {
        this.canvasAPI.mozDash = someDashes;
        this.canvasAPI.mozDashOffset = aPhase;
    }
    else if (someDashes)
    {
        CPLog.warn("CGCanvasGraphicsContext.setLineDash not implemented in this environment.")
    }
}

CGCanvasGraphicsContext.prototype.setLineJoin = function(aLineJoin)
{
    this.canvasAPI.lineJoin = CANVAS_LINEJOIN_TABLE[aLineJoin];
}

CGCanvasGraphicsContext.prototype.setLineWidth = function(aLineWidth)
{
    this.canvasAPI.lineWidth = aLineWidth;
}

CGCanvasGraphicsContext.prototype.setMiterLimit = function(aMiterLimit)
{
    this.canvasAPI.miterLimit = aMiterLimit;
}

CGCanvasGraphicsContext.prototype.setBlendMode = function(aBlendMode)
{
    this.canvasAPI.globalCompositeOperation = CANVAS_COMPOSITE_TABLE[aBlendMode];
}

CGCanvasGraphicsContext.prototype.addArc = function(x, y, radius, startAngle, endAngle, clockwise)
{
    // Despite the documentation saying otherwise, the last parameter is anti-clockwise not clockwise.
    // http://developer.mozilla.org/en/docs/Canvas_tutorial:Drawing_shapes#Arcs
    this.canvasAPI.arc(x, y, radius, startAngle, endAngle, !clockwise);

    // AddArc implicitly starts a path
    this.hasPath = YES;
}

CGCanvasGraphicsContext.prototype.addArcToPoint = function(x1, y1, x2, y2, radius)
{
    if (!hasPath(this, "CGCanvasGraphicsContext.prototype.addArcToPoint()"))
        return;

    this.canvasAPI.arcTo(x1, y1, x2, y2, radius);
}

CGCanvasGraphicsContext.prototype.addCurveToPoint = function(aContext, cp1x, cp1y, cp2x, cp2y, x, y)
{
    if (!hasPath(this, "CGCanvasGraphicsContext.prototype.addCurveToPoint()"))
        return;

    this.canvasAPI.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
}

CGCanvasGraphicsContext.prototype.addLines = function(points, count)
{
    // implementation mirrors that of CGPathAddLines()
    if (count === null || count === undefined)
        count = points.length;

    if (count < 1)
        return;

    this.canvasAPI.moveTo(points[0].x, points[0].y);

    for (var i = 1; i < count; ++i)
        this.canvasAPI.lineTo(points[i].x, points[i].y);

    this.hasPath = YES;
}

CGCanvasGraphicsContext.prototype.addLineToPoint = function(x, y)
{
    if (!hasPath(this, "CGCanvasGraphicsContext.prototype.addLineToPoint()"))
        return;

    this.canvasAPI.lineTo(x, y);
}

CGCanvasGraphicsContext.prototype.addPath = function(aPath)
{
    if (CGPathIsEmpty(aPath))
        return;

    // If the context does not have a path, explicitly begin one
    if (!this.hasPath)
        this.canvasAPI.beginPath();

    // We must implicitly move to the start of the path
    this.canvasAPI.moveTo(aPath.start.x, aPath.start.y);

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
                this.canvasAPI.moveTo(element.x, element.y);
                break;

            case kCGPathElementAddLineToPoint:
                this.canvasAPI.lineTo(element.x, element.y);
                break;

            case kCGPathElementAddQuadCurveToPoint:
                this.canvasAPI.quadraticCurveTo(element.cpx, element.cpy, element.x, element.y);
                break;

            case kCGPathElementAddCurveToPoint:
                this.canvasAPI.bezierCurveTo(element.cp1x, element.cp1y, element.cp2x, element.cp2y, element.x, element.y);
                break;

            case kCGPathElementCloseSubpath:
                this.canvasAPI.closePath();
                break;

            case kCGPathElementAddArc:
                this.canvasAPI.arc(element.x, element.y, element.radius, element.startAngle, element.endAngle, !element.clockwise);
                break;

            case kCGPathElementAddArcToPoint:
                this.canvasAPI.arcTo(element.p1x, element.p1y, element.p2x, element.p2y, element.radius);
                break;
        }
    }

    this.hasPath = YES;
}

CGCanvasGraphicsContext.prototype.addRect = function(aRect)
{
    this.canvasAPI.rect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
    this.hasPath = YES;
}

CGCanvasGraphicsContext.prototype.addQuadCurveToPoint = function(cpx, cpy, x, y)
{
    if (!hasPath(this, "CGCanvasGraphicsContext.prototype.addQuadCurveToPoint()"))
        return;

    this.canvasAPI.quadraticCurveTo(cpx, cpy, x, y);
}

CGCanvasGraphicsContext.prototype.addRects = function(rects, count)
{
    if (count === null || count === undefined)
        count = rects.length;

    for (var i = 0; i < count; ++i)
    {
        var aRect = rects[i];
        this.canvasAPI.rect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
    }

    this.hasPath = YES;
}

CGCanvasGraphicsContext.prototype.beginPath = function()
{
    this.canvasAPI.beginPath();
    this.hasPath = NO;
}

CGCanvasGraphicsContext.prototype.closePath = function()
{
    this.canvasAPI.closePath();
}

CGCanvasGraphicsContext.prototype.isPathEmpty = function()
{
    return !this.hasPath;
}

CGCanvasGraphicsContext.prototype.moveToPoint = function(x, y)
{
    this.canvasAPI.moveTo(x, y);
    this.hasPath = YES;
}

CGCanvasGraphicsContext.prototype.clearRect = function(aRect)
{
    this.canvasAPI.clearRect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
    this.hasPath = NO;
}

CGCanvasGraphicsContext.prototype.drawPath = function(aMode)
{
    if (!this.hasPath)
        return;

    if (aMode === kCGPathFill || aMode === kCGPathFillStroke)
        this.canvasAPI.fill();
    else if (aMode === kCGPathStroke || aMode === kCGPathFillStroke || aMode === kCGPathEOFillStroke)
        this.canvasAPI.stroke();
    else if (aMode === kCGPathEOFill || aMode === kCGPathEOFillStroke)
        CPLog.warn("Unimplemented fill mode in CGCanvasGraphicsContext.prototype.drawPath(%d)", aMode);

    this.hasPath = NO;
}

CGCanvasGraphicsContext.prototype.fillRect = function(aRect)
{
    this.canvasAPI.fillRect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
    this.hasPath = NO;
}

CGCanvasGraphicsContext.prototype.fillRects = function(rects, count)
{
    if (count === null || count === undefined)
        count = rects.length;

    for (var i = 0; i < count; ++i)
    {
        var aRect = rects[i];
        this.canvasAPI.fillRect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
    }

    this.hasPath = NO;
}

CGCanvasGraphicsContext.prototype.strokeRect = function(aRect)
{
    this.canvasAPI.strokeRect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
    this.hasPath = NO;
}

CGCanvasGraphicsContext.prototype.clip = function()
{
    this.canvasAPI.clip();
    this.hasPath = NO;
}

CGCanvasGraphicsContext.prototype.clipToRect = function(aRect)
{
    this.canvasAPI.beginPath();
    this.canvasAPI.rect(aRect);
    this.canvasAPI.closePath();

    this.canvasAPI.clip();
    this.hasPath = NO;
}

CGCanvasGraphicsContext.prototype.clipToRects = function(rects, count)
{
    if (count === null || count === undefined)
        count = rects.length;

    this.canvasAPI.beginPath();
    this.canvasAPI.addRects(rects, count);
    this.canvasAPI.clip();
    this.hasPath = NO;
}

CGCanvasGraphicsContext.prototype.setAlpha = function(anAlpha)
{
    this.canvasAPI.globalAlpha = anAlpha;
}

CGCanvasGraphicsContext.prototype.setFillColor = function(aColor)
{
    var patternImage = [aColor patternImage];

    if ([patternImage isSingleImage])
    {
        var pattern = this.canvas.createPattern([patternImage image], "repeat");

        this.canvasAPI.fillStyle = pattern;
    }
    else
        this.canvasAPI.fillStyle = [aColor cssString];
}

/*!
    Creates a context into which you can render a fill pattern
    of the given size. Once the pattern is rendered, you can
    set the fill or stroke pattern to the rendered pattern
    with CGContextSetFillPattern or CGContextSetStrokePattern.
*/
CGCanvasGraphicsContext.prototype.createPatternContext = function(aSize)
{
    return new CGCanvasGraphicsContext(aSize);
}

/*!
    Sets the fill pattern for aContext to the rendered pattern context
    returned by CGContextCreatePatternContext.
*/
CGCanvasGraphicsContext.prototype.setFillPattern = function(aPatternContext)
{
    var pattern = this.canvasAPI.createPattern(aPatternContext.canvas.canvas, "repeat");
    this.canvasAPI.fillStyle = pattern;
}

/*!
    Sets the stroke pattern for aContext to the rendered pattern context
    returned by CGContextCreatePatternContext.
*/
CGCanvasGraphicsContext.prototype.setStrokePattern = function(aPatternContext)
{
    var pattern = this.canvasAPI.createPattern(aPatternContext.canvas.canvas, "repeat");
    this.canvasAPI.strokeStyle = pattern;
}

CGCanvasGraphicsContext.prototype.setStrokeColor = function(aColor)
{
    var patternImage = [aColor patternImage];

    if ([patternImage isSingleImage])
    {
        var pattern = this.canvasAPI.createPattern([patternImage image], "repeat");

        this.canvasAPI.strokeStyle = pattern;
    }
    else
        this.canvasAPI.strokeStyle = [aColor cssString];
}

CGCanvasGraphicsContext.prototype.setShadow = function(aSize, aBlur)
{
    this.canvasAPI.shadowOffsetX = aSize.width;
    this.canvasAPI.shadowOffsetY = aSize.height;
    this.canvasAPI.shadowBlur = aBlur;
}

CGCanvasGraphicsContext.prototype.setShadowWithColor = function(aSize, aBlur, aColor)
{
    this.canvasAPI.shadowOffsetX = aSize.width;
    this.canvasAPI.shadowOffsetY = aSize.height;
    this.canvasAPI.shadowBlur = aBlur;
    this.canvasAPI.shadowColor = [aColor cssString];
}

CGCanvasGraphicsContext.prototype.rotateCTM = function(anAngle)
{
    this.canvasAPI.rotate(anAngle);
}

CGCanvasGraphicsContext.prototype.scaleCTM = function(sx, sy)
{
    this.canvasAPI.scale(sx, sy);
}

CGCanvasGraphicsContext.prototype.translateCTM = function(tx, ty)
{
    this.canvasAPI.translate(tx, ty);
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
    var sign = (a * d < 0.0 || b * c > 0.0) ? -1.0 : 1.0,
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

CGCanvasGraphicsContext.prototype.concatCTM = function(anAffineTransform)
{
    if (CPFeatureIsCompatible(CPJavaScriptCanvasTransformFeature))
    {
    
        this.canvasAPI.transform(anAffineTransform.a, anAffineTransform.b, anAffineTransform.c, anAffineTransform.d, anAffineTransform.tx, anAffineTransform.ty);
    
    }
    else
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
            CGContextTranslateCTM(this, tx, ty);
        if (a1 != 0.0)
            CGContextRotateCTM(this, a1);
        if (sx != 1.0 || sy != 1.0)
            CGContextScaleCTM(this, sx, sy);
        if (a2 != 0.0)
            CGContextRotateCTM(this, a2);
    }
    
}

CGCanvasGraphicsContext.prototype.drawImage = function(aRect, anImage)
{
    this.canvasAPI.drawImage(anImage._image, CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
    this.hasPath = NO;
}

function to_string(aColor)
{
    return "rgba(" + ROUND(aColor.components[0] * 255) + ", " + ROUND(aColor.components[1] * 255) + ", " + ROUND(255 * aColor.components[2]) + ", " + aColor.components[3] + ")";
}

CGCanvasGraphicsContext.prototype.drawLinearGradient = function(aGradient, aStartPoint, anEndPoint, options)
{
    var colors = aGradient.colors,
        count = colors.length,
        linearGradient = this.canvasAPI.createLinearGradient(aStartPoint.x, aStartPoint.y, anEndPoint.x, anEndPoint.y);

    while (count--)
        linearGradient.addColorStop(aGradient.locations[count], to_string(colors[count]));

    this.canvasAPI.fillStyle = linearGradient;
    this.canvasAPI.fill();
    this.hasPath = NO;
}

CGCanvasGraphicsContext.prototype.drawRadialGradient = function(aGradient, aStartCenter, aStartRadius, anEndCenter, anEndRadius, options)
{
    var colors = aGradient.colors,
        count = colors.length,
        linearGradient = this.canvasAPI.createRadialGradient(aStartCenter.x, aStartCenter.y, aStartRadius, anEndCenter.x, anEndCenter.y, anEndRadius);

    while (count--)
        linearGradient.addColorStop(aGradient.locations[count], to_string(colors[count]));

    this.canvasAPI.fillStyle = linearGradient;
    this.canvasAPI.fill();
    this.hasPath = NO;
}

/*
 * If the canvas is available it becomes the default implementation
 * for CGBitmapGraphicsContextCreate()
 */
function CGBitmapGraphicsContextCreate()
{
    return new CGCanvasGraphicsContext();
}
