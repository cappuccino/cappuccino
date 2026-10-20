/*
 * CGContext.j
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

@import "CGAffineTransform.j"
@import "CPCompatibility.j"
@import "CGGeometry.j"
@import "CGPath.j"
@import "CGContextText.j"

@typedef CGContext

kCGLineCapButt              = 0;
kCGLineCapRound             = 1;
kCGLineCapSquare            = 2;

kCGLineJoinMiter            = 0;
kCGLineJoinRound            = 1;
kCGLineJoinBevel            = 2;

kCGPathFill                 = 0;
kCGPathEOFill               = 1;
kCGPathStroke               = 2;
kCGPathFillStroke           = 3;
kCGPathEOFillStroke         = 4;

/*!
    @group CGBlendMode
*/

kCGBlendModeNormal          = 0;
kCGBlendModeMultiply        = 1;
kCGBlendModeScreen          = 2;
kCGBlendModeOverlay         = 3;
kCGBlendModeDarken          = 4;
kCGBlendModeLighten         = 5;
kCGBlendModeColorDodge      = 6;
kCGBlendModeColorBurn       = 7;
kCGBlendModeSoftLight       = 8;
kCGBlendModeHardLight       = 9;
kCGBlendModeDifference      = 10;
kCGBlendModeExclusion       = 11;
kCGBlendModeHue             = 12;
kCGBlendModeSaturation      = 13;
kCGBlendModeColor           = 14;
kCGBlendModeLuminosity      = 15;
kCGBlendModeClear           = 16;
kCGBlendModeCopy            = 17;
kCGBlendModeSourceIn        = 18;
kCGBlendModeSourceOut       = 19;
kCGBlendModeSourceAtop      = 20;
kCGBlendModeDestinationOver = 21;
kCGBlendModeDestinationIn   = 22;
kCGBlendModeDestinationOut  = 23;
kCGBlendModeDestinationAtop = 24;
kCGBlendModeXOR             = 25;
kCGBlendModePlusDarker      = 26;
kCGBlendModePlusLighter     = 27;

/*!
    @defgroup coregraphics CoreGraphics
    @{
*/

/*!
    This function is just here for source compatibility.
    It does nothing.
    @group CGContext
*/
function CGContextRelease()
{
}

/*!
    This function is just here for source compatibility.
    It does nothing.
    @param aContext a CGContext
    @return CGContext the context
*/
function CGContextRetain(aContext)
{
    return aContext;
}

/*!
@cond
*/
// BEGIN CANVAS IF
if (!CPFeatureIsCompatible(CPHTMLCanvasFeature))
{
/*!
@endcond
*/

/*!
    Creates a new graphics state, which describes all the current values for drawing.
    @return a graphics state
*/
function CGGStateCreate()
{
    return { alpha:1.0, strokeStyle:"#000", fillStyle:"#ccc", lineWidth:1.0, lineJoin:kCGLineJoinMiter, lineCap:kCGLineCapButt, miterLimit:10.0, globalAlpha:1.0,
        blendMode:kCGBlendModeNormal,
        shadowOffset:CGSizeMakeZero(), shadowBlur:0.0, shadowColor:NULL, CTM:CGAffineTransformMakeIdentity() };
}

/*!
    Creates a copy of the given graphics state.
    @param aGState the graphics state to copy
    @return a copy of the given graphics state
*/
function CGGStateCreateCopy(aGState)
{
    return { alpha:aGState.alpha, strokeStyle:aGState.strokeStyle, fillStyle:aGState.fillStyle, lineWidth:aGState.lineWidth,
        lineJoin:aGState.lineJoin, lineCap:aGState.lineCap, miterLimit:aGState.miterLimit, globalAlpha:aGState.globalAlpha,
        blendMode:aGState.blendMode,
        shadowOffset:CGSizeMakeCopy(aGState.shadowOffset), shadowBlur:aGState.shadowBlur, shadowColor:aGState.shadowColor, CTM:CGAffineTransformMakeCopy(aGState.CTM) };
}

/*!
    Returns a new graphics context.
    @return CGContext a new graphics context which can be drawn into
*/
function CGBitmapGraphicsContextCreate()
{
    return { DOMElement:document.createElement("div"), path:NULL, gState:CGGStateCreate(), gStateStack:[] };
}

/*!
    Pushes the current graphics state of aContext onto the top of a stack.
    @param aContext the CGContext to edit
    @return void
*/
function CGContextSaveGState(aContext)
{
    aContext.gStateStack.push(CGGStateCreateCopy(aContext.gState));
}

/*!
    Pops the most recent graphics state of the top of the graphics stack and restores it.
    @param aContext the CGContext to edit
    @return void
*/
function CGContextRestoreGState(aContext)
{
    aContext.gState = aContext.gStateStack.pop();
}

function CGContextSetLineCap(aContext, aLineCap)
{
    aContext.gState.lineCap = aLineCap;
}

function CGContextSetLineDash(aContext, aPhase, someDashes)
{
    aContext.gState.lineDashes = someDashes;
    aContext.gState.lineDashesPhase = aPhase;
}

function CGContextSetLineJoin(aContext, aLineJoin)
{
    aContext.gState.lineJoin = aLineJoin;
}

function CGContextSetLineWidth(aContext, aLineWidth)
{
    aContext.gState.lineWidth = aLineWidth;
}

function CGContextSetMiterLimit(aContext, aMiterLimit)
{
    aContext.gState.miterLimit = aMiterLimit;
}

function CGContextSetBlendMode(aContext, aBlendMode)
{
    aContext.gState.blendMode = aBlendMode;
}

function CGContextAddArc(aContext, x, y, radius, startAngle, endAngle, clockwise)
{
    CGPathAddArc(aContext.path, aContext.gState.CTM, x, y, radius, startAngle, endAngle, clockwise);
}

/*!
    Adds an arc to the current context that ends in the specified point.
    @param aContext the CGContext to edit
    @param x1 the x coordinate of the beginning of the arc
    @param y1 the y coordinate of the beginning of the arc
    @param x2 the x coordinate of the end of the arc
    @param y2 the y coordinate of the end of the arc
    @param radius the radius of the arc to be drawn
    @return void
*/
function CGContextAddArcToPoint(aContext, x1, y1, x2, y2, radius)
{
    CGPathAddArcToPoint(aContext.path, aContext.gState.CTM, x1, y1, x2, y2, radius);
}

/*!
    Adds a cubic curve to the current context
    @param aContext the CGContext to edit
    @param cp1x the x coordinate of the first control point
    @param cp1y the y coordinate of the first control point
    @param cp2x the x coordinate of the second control point
    @param cp2y the y coordinate of the second control point
    @param x the x coordinate of the end of the curve
    @param y the y coordinate of the end of the curve
    @return void
*/
function CGContextAddCurveToPoint(aContext, cp1x, cp1y, cp2x, cp2y, x, y)
{
    CGPathAddCurveToPoint(aContext.path, aContext.gState.CTM, cp1x, cp1y, cp2x, cp2y, x, y);
}

/*!
    Adds a line to each element in the points array
    @param aContext the CGContext to move
    @param points an array of points that are to be consecutively executed as if they were individual addToPoint calls
    @param count an upper bound on the number of points to use
    @return void
*/
function CGContextAddLines(aContext, points, count)
{
    CGPathAddLines(aContext.path, aContext.gState.CTM, points, count);
}

/*!
    Adds a line from the current point to the x/y
    @param aContext the CGContext to move
    @param x the x coordinate of the end point of the line
    @param y the y coordinate of the end point of the line
    @return void
*/
function CGContextAddLineToPoint(aContext, x, y)
{
    CGPathAddLineToPoint(aContext.path, aContext.gState.CTM, x, y);
}

/*!
    Adds aPath to the current path in aContext
    @param aContext the CGContext to add to
    @param aPath the path to be added
    @return void
*/
function CGContextAddPath(aContext, aPath)
{
    if (!aContext || CGPathIsEmpty(aPath))
        return;

    if (!aContext.path)
        aContext.path = CGPathCreateMutable();

    CGPathAddPath(aContext.path, aContext.gState.CTM, aPath);
}

/*!
    Adds a quadratic curve from the current point to the point specified by x/y, using the control point specified by cpx/cpy
    @param aContext the CGContext to add the curve to
    @param cpx the x coordinate for the curve's control point
    @param cpy the y coordinate for the curve's control point
    @param x the x coordinate for the end point of the curve
    @param y the y coordinate for the end point of the curve
    @return void
*/
function CGContextAddQuadCurveToPoint(aContext, cpx, cpy, x, y)
{
    CGPathAddQuadCurveToPoint(aContext.path, aContext.gState.CTM, cpx, cpy, x, y);
}

/*!
    Adds aRect to the current path in the given context
    @param aContext the CGContext to add to
    @param aRect the dimensions of the rectangle to add
    @return void
*/
function CGContextAddRect(aContext, aRect)
{
    CGPathAddRect(aContext.path, aContext.gState.CTM, aRect);
}

/*!
    Adds up to count elements from rects to the current path in aContext
    @param aContext the CGContext to add to
    @param rects an array of CGRects to be added to the context's path
    @param the upper bound of elements to be added
    @return void
*/
function CGContextAddRects(aContext, rects, count)
{
    CGPathAddRects(aContext.path, aContext.gState.CTM, rects, count);
}

/*!
    Begins a new subpath in the given context
    @param aContext the CGContext to create a new path in
    @return void
*/
function CGContextBeginPath(aContext)
{
    // This clears any previous path.
    aContext.path = CGPathCreateMutable();
}

/*!
    Closes the currently open subpath, if any, in aContext
    @param aContext the CGContext to close a path in
    @return void
*/
function CGContextClosePath(aContext)
{
    CGPathCloseSubpath(aContext.path);
}

/*!
    Return YES if the current path in the given context is empty.
    @param aContext the CGContext to examine
    @return BOOL
*/
function CGContextIsPathEmpty(aContext)
{
    return (!aContext.path || CGPathIsEmpty(aContext.path));
}

/*!
    Moves the current location of aContext to the given x and y coordinates
    @param aContext the CGContext to move
    @param x the x location to move the context to
    @param y the y location to move the context to
    @return void
*/
function CGContextMoveToPoint(aContext, x, y)
{
    if (!aContext.path)
        aContext.path = CGPathCreateMutable();

    CGPathMoveToPoint(aContext.path, aContext.gState.CTM, x, y);
}

/*!
    Fills a rectangle in the given context with aRect dimensions, using the context's current fill color
    @param aContext the CGContext to draw into
    @param aRect the dimensions of the rectangle to fill
    @return void
*/
function CGContextFillRect(aContext, aRect)
{
    CGContextFillRects(aContext, [aRect], 1);
}

/*!
    Fills a rectangle in the given context for each CGRect in the given array, up to a total of count rects
    @param aContext the CGContext to draw into
    @param rects an array of rects to fill
    @param count the maximum number of rects from the given array to fill
    @return void
*/
function CGContextFillRects(aContext, rects, count)
{
    if (arguments[2] == nil)
        var count = rects.length;

    CGContextBeginPath(aContext);
    CGContextAddRects(aContext, rects, count);
    CGContextClosePath(aContext);

    CGContextDrawPath(aContext, kCGPathFill);
}

/*!
    Strokes a rectangle with the given location into the given context, using the context's current width and color
    @param aContext the CGContext to draw into
    @param aRect a CGRect indicating the dimensions of the rectangle to be drawn
    @return void
*/
function CGContextStrokeRect(aContext, aRect)
{
    CGContextBeginPath(aContext);
    CGContextAddRect(aContext, aRect);
    CGContextClosePath(aContext);

    CGContextDrawPath(aContext, kCGPathStroke);
}

/*!
    Strokes a rectangle with the given dimensions and the given stroke width
    @param aContext the CGContext to draw into
    @param aRect the CGRect indicating the bounds of the rect to be drawn
    @param aWidth the width with which to stroke the rect
    @return void
*/
function CGContextStrokeRectWithWidth(aContext, aRect, aWidth)
{
    CGContextSaveGState(aContext);

    CGContextSetLineWidth(aContext, aWidth);
    CGContextStrokeRect(aContext, aRect);

    CGContextRestoreGState(aContext);
}

/*!
    Concatenates the given transformation matrix onto the current transformation matrix in aContext
    @param aContext the CGContext to transform
    @param aTransform the CGAffineTransform to apply to the given context
    @return void
*/
function CGContextConcatCTM(aContext, aTransform)
{
    var CTM = aContext.gState.CTM;

    CGAffineTransformConcatTo(CTM, aTransform, CTM);
}

/*!
    Returns the current transformation matrix for the given context
    @param aContext the CGContext for which we are asking for the transform
    @return CGAffineTransform the current transformation matrix of the given context
*/
function CGContextGetCTM(aContext)
{
    return aContext.gState.CTM;
}

/*!
    Rotates the current context by anAngle radians
    @param aContext the CGContext to rotate
    @param anAngle the amount to rotate, in radians
    @return void
*/

function CGContextRotateCTM(aContext, anAngle)
{
    var gState = aContext.gState;

    gState.CTM = CGAffineTransformRotate(gState.CTM, anAngle);
}

/*!
    Scales the current context by sx/sy
    @param aContext the CGContext to scale
    @param sx the amount to scale in the x direction
    @param sy the amount to scale in the y direction
    @return void
*/
function CGContextScaleCTM(aContext, sx, sy)
{
    var gState = aContext.gState;

    gState.CTM = CGAffineTransformScale(gState.CTM, sx, sy);
}

/*!
    Translates the given context by tx in the x direction and ty in the y direction
    @param aContext the CGContext to translate
    @param tx the amount to move in the x direction
    @param ty the amount to move in the y direction
    @return void
*/
function CGContextTranslateCTM(aContext, tx, ty)
{
    var gState = aContext.gState;

    gState.CTM = CGAffineTransformTranslate(gState.CTM, tx, ty);
}

/*!
    Sets the current offset, and blur for shadows in core graphics drawing operations
    @param aContext the CGContext of the shadow
    @param aSize a CGSize indicating the offset of the shadow
    @param aBlur a float indicating the blur radius
    @return void
*/

function CGContextSetShadow(aContext, aSize, aBlur)
{
    var gState = aContext.gState;

    gState.shadowOffset = CGSizeMakeCopy(aSize);
    gState.shadowBlur = aBlur;
    gState.shadowColor = [CPColor shadowColor];
}

/*!
    Sets the current offset, blur, and color for shadows in core graphics drawing operations
    @param aContext the CGContext of the shadow
    @param aSize a CGSize indicating the offset of the shadow
    @param aBlur a float indicating the blur radius
    @param aColor a CPColor object indicating the color of the shadow
    @return void
*/
function CGContextSetShadowWithColor(aContext, aSize, aBlur, aColor)
{
    var gState = aContext.gState;

    gState.shadowOffset = CGSizeMakeCopy(aSize);
    gState.shadowBlur = aBlur;
    gState.shadowColor = aColor;
}

/*!
    Sets the current alpha value for core graphics drawing operations in the given context .
    @param aContext the CGContext who's alpha value should be updated
    @param anAlpha the new alpha value. 1.0 is completely opaque, 0.0 is completely transparent.
    @return void
*/
function CGContextSetAlpha(aContext, anAlpha)
{
    aContext.gState.alpha = MAX(MIN(anAlpha, 1.0), 0.0);
}

/*!
@cond
*/
}   // END CANVAS IF
/*!
@endcond
*/

// GOOD.
/*!
    Fills in the area of the current path, using the even-odd fill rule.
    @param aContext the CGContext of the path
    @return void
*/
function CGContextEOFillPath(aContext)
{
    CGContextDrawPath(aContext, kCGPathEOFill);
}

/*!
    Fills in the area of the current path, using  the non-zero winding number rule.
    @param aContext the CGContext of the path
    @return void
*/
function CGContextFillPath(aContext)
{
    CGContextDrawPath(aContext, kCGPathFill);
    CGContextClosePath(aContext);
}

/*!
    Strokes a rectangle with the given dimensions and the given stroke width
    @param aContext the CGContext to draw into
    @param aRect the CGRect indicating the bounds of the rect to be drawn
    @param aWidth the width with which to stroke the rect
    @return void
*/
function CGContextStrokeRectWithWidth(aContext, aRect, aWidth)
{
    CGContextSaveGState(aContext);

    CGContextSetLineWidth(aContext, aWidth);
    CGContextStrokeRect(aContext, aRect);

    CGContextRestoreGState(aContext);
}

var KAPPA = 4.0 * ((SQRT2 - 1.0) / 3.0);

/*!
    Draws the outline of an ellipse bounded by a rectangle.
    @param aContext CGContext to draw on
    @param aRect the rectangle bounding the ellipse
    @return void
*/
function CGContextAddEllipseInRect(aContext, aRect)
{
    CGContextBeginPath(aContext);
    CGContextAddPath(aContext, CGPathWithEllipseInRect(aRect));
    CGContextClosePath(aContext);
}

/*!
    Fills an ellipse bounded by a rectangle.
    @param aContext CGContext to draw on
    @param aRect the rectangle bounding the ellipse
    @return void
*/
function CGContextFillEllipseInRect(aContext, aRect)
{
    CGContextBeginPath(aContext);
    CGContextAddEllipseInRect(aContext, aRect);
    CGContextClosePath(aContext);
    CGContextFillPath(aContext);
}

/*!
    Strokes an ellipse bounded by the specified rectangle.
    @param aContext CGContext to draw on
    @param aRect the rectangle bounding the ellipse
    @return void
*/
function CGContextStrokeEllipseInRect(aContext, aRect)
{
    CGContextBeginPath(aContext);
    CGContextAddEllipseInRect(aContext, aRect);
    CGContextClosePath(aContext);
    CGContextStrokePath(aContext);
}

/*!
    Paints a line in the current path of the current context.
    @param aContext CGContext to draw on
    @return void
*/
function CGContextStrokePath(aContext)
{
    CGContextDrawPath(aContext, kCGPathStroke);
    CGContextClosePath(aContext);
}

/*!
    Strokes multiple line segments.
    @param aContext CGContext to draw on
    @param points an array with an even number of points. The
    first point is the beginning of the first line segment, the second
    is the end of the first line segment. The third point is
    the beginning of second line segment, etc.
    @param count the number of points in the array
    @return void
*/
function CGContextStrokeLineSegments(aContext, points, count)
{
    var i = 0;

    if (count == NULL)
        var count = points.length;

    CGContextBeginPath(aContext);

    for (; i < count; i += 2)
    {
        CGContextMoveToPoint(aContext, points[i].x, points[i].y);
        CGContextAddLineToPoint(aContext, points[i + 1].x, points[i + 1].y);
    }

    CGContextStrokePath(aContext);
}


//FIXME: THIS IS WRONG!!!

/*!
    Sets the current fill color.
    @param aContext the CGContext
    @param aColor the new color for the fill
    @return void
*/

function CGContextSetFillColor(aContext, aColor)
{
    if (aColor)
        aContext.gState.fillStyle = [aColor cssString];
}

/*!
    Sets the current stroke color.
    @param aContext the CGContext
    @param aColor the new color for the stroke
    @return void
*/
function CGContextSetStrokeColor(aContext, aColor)
{
    if (aColor)
        aContext.gState.strokeStyle = [aColor cssString];
}

/*!
    Fills a rounded rectangle.
    @param aContext the CGContext to draw into
    @param aRect the base rectangle
    @param aRadius the distance from the rectangle corner to the rounded corner
    @param ne set it to \c YES for a rounded northeast corner
    @param se set it to \c YES for a rounded southeast corner
    @param sw set it to \c YES for a rounded southwest corner
    @param nw set it to \c YES for a rounded northwest corner
    @return void
*/
function CGContextFillRoundedRectangleInRect(aContext, aRect, aRadius, ne, se, sw, nw)
{
    CGContextBeginPath(aContext);
    CGContextAddPath(aContext, CGPathWithRoundedRectangleInRect(aRect, aRadius, aRadius, ne, se, sw, nw));
    CGContextClosePath(aContext);
    CGContextFillPath(aContext);
}

/*!
    Strokes a rounded rectangle.
    @param aContext the CGContext to draw into
    @param aRect the base rectangle
    @param aRadius the distance from the rectangle corner to the rounded corner
    @param ne set it to \c YES for a rounded northeast corner
    @param se set it to \c YES for a rounded southeast corner
    @param sw set it to \c YES for a rounded southwest corner
    @param nw set it to \c YES for a rounded northwest corner
    @return void
*/
function CGContextStrokeRoundedRectangleInRect(aContext, aRect, aRadius, ne, se, sw, nw)
{
    CGContextBeginPath(aContext);
    CGContextAddPath(aContext, CGPathWithRoundedRectangleInRect(aRect, aRadius, aRadius, ne, se, sw, nw));
    CGContextClosePath(aContext);
    CGContextStrokePath(aContext);
}

/*!
    @}
*/

/*!
@cond
*/
if (CPFeatureIsCompatible(CPHTMLCanvasFeature))
{
// --- begin CoreGraphics/CGContextCanvas.j (inlined; include fragment removed for preprocessor-free build) ---
var CANVAS_LINECAP_TABLE    = [ "butt", "round", "square" ],
    CANVAS_LINEJOIN_TABLE   = [ "miter", "round", "bevel" ],
    CANVAS_COMPOSITE_TABLE  = [ "source-over", "source-over", "source-over", "source-over", "darker",
                                "lighter", "source-over", "source-over", "source-over", "source-over",
                                "source-over", "source-over", "source-over", "source-over", "source-over",
                                "source-over", "source-over",
                                "copy", "source-in", "source-out", "source-atop",
                                "destination-over", "destination-in", "destination-out", "destination-atop",
                                "xor", "source-over", "source-over" ];

function _CGContextAddArcCanvas(aContext, x, y, radius, startAngle, endAngle, anticlockwise)
{
    return aContext.arc(x, y, radius, startAngle, endAngle, anticlockwise);
}
function _CGContextAddArcToPointCanvas(aContext, x1, y1, x2, y2, radius)
{
    return aContext.arcTo(x1, y1, x2, y2, radius);
}
function _CGContextAddCurveToPointCanvas(aContext, cp1x, cp1y, cp2x, cp2y, x, y)
{
    return aContext.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
}
function _CGContextAddQuadCurveToPointCanvas(aContext, cpx, cpy, x, y)
{
    return aContext.quadraticCurveTo(cpx, cpy, x, y);
}
function _CGContextAddLineToPointCanvas(aContext, x, y)
{
    return aContext.lineTo(x, y);
}
function _CGContextClosePathCanvas(aContext)
{
    return aContext.closePath();
}
function _CGContextMoveToPointCanvas(aContext, x, y)
{
    return aContext.moveTo(x, y);
}

function _CGContextAddRectCanvas(aContext, aRect)
{
    return aContext.rect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
}
function _CGContextBeginPathCanvas(aContext)
{
    return aContext.beginPath();
}
function _CGContextFillRectCanvas(aContext, aRect)
{
    return aContext.fillRect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
}
function _CGContextClipCanvas(aContext)
{
    return aContext.clip();
}

// In Cocoa, all primitives excepts rects and arcs cannot be added to the context's path
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
    // Despite the documentation saying otherwise, the last parameter is anti-clockwise not clockwise.
    // http://developer.mozilla.org/en/docs/Canvas_tutorial:Drawing_shapes#Arcs
    _CGContextAddArcCanvas(aContext, x, y, radius, startAngle, endAngle, !clockwise);

    // AddArc implicitly starts a path
    aContext.hasPath = YES;
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
    if (count == null)
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
    if (count == null)
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
    if (count == null)
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
    if (count == null)
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
    aContext.shadowColor = [[CPColor shadowColor] cssString];
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
        sin = SIN(a2),
        abs_cos,
        abs_sin;

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
        sin = SIN(a1),
        abs_cos,
        abs_sin;

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
        scale_rotate(a, b, c, d);
        S.a *= sx;
        S.d *= sy;
        a = U.a;
        b = U.b;
        c = U.c;
        d = U.d;
        rotate_scale(a, b, c, d);
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

function CGContextDrawRadialGradient(aContext, aGradient, aStartCenter, aStartRadius, anEndCenter, anEndRadius, options)
{
    var colors = aGradient.colors,
        count = colors.length,
        linearGradient = aContext.createRadialGradient(aStartCenter.x, aStartCenter.y, aStartRadius, anEndCenter.x, anEndCenter.y, anEndRadius);

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
}
else
{
    // I have declared these functions here to make it compile without warnings with the new compiler under rhino.
    CGContextClearRect = CGContextDrawLinearGradient = CGContextClip = CGContextClipToRect = CGContextDrawImage = function() {throw new Error("function is not declared in this environment")}
}
/*!
@endcond
*/
