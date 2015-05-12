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
    The abstract base class for concrete GraphicsContext to inherit
*/
function CGContext()
{
    this.DOMElement = document.createElement("div");
    this.gState = CGGStateCreate();
    this.gStateStack = [];
}

CGContext.prototype.saveGState = function()
{
    this.gStateStack.push(CGGStateCreateCopy(this.gState));
}

CGContext.prototype.restoreGState = function()
{
    this.gState = this.gStateStack.pop();
}

CGContext.prototype.setLineCap = function(aLineCap)
{
    this.gState.lineCap = aLineCap;
}
CGContext.prototype.setLineDash = function(aPhase, someDashes)
{
    this.gState.lineDashes = someDashes;
    this.gState.lineDashesPhase = aPhase;
}

CGContext.prototype.setLineJoin = function(aLineJoin)
{
    this.gState.lineJoin = aLineJoin;
}

CGContext.prototype.setLineWidth = function(aContext, aLineWidth)
{
    this.gState.lineWidth = aLineWidth;
}

CGContext.prototype.setMiterLimit = function(aMiterLimit)
{
    this.gState.miterLimit = aMiterLimit;
}

CGContext.prototype.setBlendMode = function(aBlendMode)
{
    this.gState.blendMode = aBlendMode;
}

CGContext.prototype.getCTM = function()
{
    return this.gState.CTM;
}

CGContext.prototype.setCTM = function(transform)
{
    this.gState.CTM = transform;
}

CGContext.prototype.concatCTM = function(transform)
{
    var CTM = this.getCTM();

    CGAffineTransformConcatTo(CTM, transform, CTM);
}

CGContext.prototype.rotateCTM = function(anAngle)
{
    var CTM = this.getCTM();

    this.setCTM(CGAffineTransformRotate(CTM, anAngle));
}

CGContext.prototype.scaleCTM = function(sx, sy)
{
    var CTM = this.getCTM();

    this.setCTM(CGAffineTransformScale(CTM, sx, sy));
}

CGContext.prototype.translateCTM = function(aContext, tx, ty)
{
    var CTM = this.getCTM();

    this.setCTM(CGAffineTransformTranslate(CTM, tx, ty));
}

CGContext.prototype.setShadow = function(aSize, aBlur)
{
    this.gState.shadowOffset = CGSizeMakeCopy(aSize);
    this.gState.shadowBlur = aBlur;
    this.gState.shadowColor = [CPShadow color];
}

CGContext.prototype.setShadowWithColor = function(aSize, aBlur, aColor)
{
    this.gState.shadowOffset = CGSizeMakeCopy(aSize);
    this.gState.shadowBlur = aBlur;
    this.gState.shadowColor = aColor;
}

CGContext.prototype.setAlpha = function(anAlpha)
{
    this.gState.alpha = MAX(MIN(anAlpha, 1.0), 0.0);
}

CGContext.prototype.setFillColor = function(aColor)
{
    if (aColor)
        this.gState.fillStyle = [aColor cssString];
}

CGContext.prototype.setStrokeColor = function(aColor)
{
    if (aColor)
        this.gState.strokeStyle = [aColor cssString];
}

CGContext.prototype.drawPath = function(mode)
{
    CPLog.fatal("abstract method: drawPath()");
}

CGContext.prototype.addArc = function(x, y, radius, startAngle, endAngle, clockwise)
{
    CGPathAddArc(this.path, this.getCTM(), x, y, radius, startAngle, endAngle, clockwise);
}

CGContext.prototype.addArcToPoint = function(x1, y1, x2, y2, radius)
{
    CGPathAddArcToPoint(this.path, this.getCTM(), x1, y1, x2, y2, radius);
}

CGContext.prototype.addCurveToPoint = function(cp1x, cp1y, cp2x, cp2y, x, y)
{
    CGPathAddCurveToPoint(this.path, this.getCTM(), cp1x, cp1y, cp2x, cp2y, x, y);
}

CGContext.prototype.addLines = function(points, count)
{
    CGPathAddLines(this.path, this.getCTM(), points, count);
}

CGContext.prototype.addLineToPoint = function(x, y)
{
    CGPathAddLineToPoint(this.path, this.getCTM(), x, y);
}

CGContext.prototype.addPath = function(aPath)
{
    if (CGPathIsEmpty(aPath))
        return;

    if (!this.path)
        this.path = CGPathCreateMutable();

    CGPathAddPath(this.path, this.getCTM(), aPath);
}

CGContext.prototype.addQuadCurveToPoint = function(cpx, cpy, x, y)
{
    CGPathAddQuadCurveToPoint(this.path, this.getCTM(), cpx, cpy, x, y);
}

CGContext.prototype.addRect = function(aRect)
{
    CGPathAddRect(this.path, this.getCTM(), aRect);
}

CGContext.prototype.addRects = function(rects, count)
{
    CGPathAddRects(this.path, this.getCTM(), rects, count);
}

CGContext.prototype.beginPath = function()
{
    // This clears any previous path.
    this.path = CGPathCreateMutable();
}

CGContext.prototype.closePath = function()
{
    CGPathCloseSubpath(this.path);
}

CGContext.prototype.isPathEmpty = function()
{
    return (!this.path || CGPathIsEmpty(this.path));
}

CGContext.prototype.moveToPoint = function(x, y)
{
    if (!this.path)
        this.path = CGPathCreateMutable();

    CGPathMoveToPoint(this.path, this.getCTM(), x, y);
}

CGContext.prototype.fillRects = function(rects, count)
{
    if (arguments[1] === undefined)
        var count = rects.length;

    this.beginPath();
    this.addRects(rects, count);
    this.closePath();

    this.drawPath(kCGPathFill);
}

CGContext.prototype.strokeRect = function(aRect)
{
    this.beginPath();
    this.addRect(aRect);
    this.closePath();

    this.strokePath();
}

CGContext.prototype.addEllipseInRect = function(aRect)
{
    this.beginPath();
    this.addPath(CGPathWithEllipseInRect(aRect));
    this.closePath();
}

CGContext.prototype.strokePath = function()
{
    this.drawPath(kCGPathStroke);
    this.closePath();
}

CGContext.prototype.strokeLineSegments = function(points, count)
{
    var i = 0;

    if (count === NULL)
        var count = points.length;

    this.beginPath();

    for (; i < count; i += 2)
    {
        this.moveToPoint(points[i].x, points[i].y);
        this.addLineToPoint(points[i + 1].x, points[i + 1].y);
    }

    this.strokePath();
}

CGContext.prototype.clearRect = function(aRect)
{
    CPLog.warn("CGContext.prototype.clearRect() unimplemented");
}

CGContext.prototype.clip = function()
{
    CPLog.warn("CGContext.prototype.clip() unimplemented");
}

CGContext.prototype.clipToRect = function(aRect)
{
    CPLog.warn("CGContext.prototype.clipToRect() unimplemented");
}

CGContext.prototype.clipToRects = function(aRect)
{
    CPLog.warn("CGContext.prototype.clipToRect() unimplemented");
}

CGContext.prototype.createPatternContext = function(aSize)
{
    CPLog.warn("CGContext.prototype.createPatternContext() unimplemented");
}

CGContext.prototype.setFillPattern = function(aPatternContext)
{
    CPLog.warn("CGContext.prototype.setFillPattern() unimplemented");
}

CGContext.prototype.setStrokePattern = function(aPatternContext)
{
    CPLog.warn("CGContext.prototype.setStrokePattern() unimplemented");
}

CGContext.prototype.drawImage = function(aRect, anImage)
{
    CPLog.warn("CGContext.prototype.drawImage() unimplemented");
}

CGContext.prototype.drawLinearGradient = function(aGradient, aStartPoint, anEndPoint, options)
{
    CPLog.warn("CGContext.prototype.drawLinearGradient() unimplemented");
}

CGContext.prototype.drawRadialGradient = function(aGradient, aStartCenter, aStartRadius, anEndCenter, anEndRadius, options)
{
    CPLog.warn("CGContext.prototype.drawRadialGradient() unimplemented");
}

CGContext.prototype.showTextAtPositions = function(text, positions, count)
{
    CPLog.warn("CGContext.prototype.showTextAtPositions() unimplemented");
}

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
    return new CGContext();
}

/*!
    Pushes the current graphics state of aContext onto the top of a stack.
    @param aContext the CGContext to edit
    @return void
*/
function CGContextSaveGState(aContext)
{
    aContext.saveGState();
}

/*!
    Pops the most recent graphics state of the top of the graphics stack and restores it.
    @param aContext the CGContext to edit
    @return void
*/
function CGContextRestoreGState(aContext)
{
    aContext.restoreGState();
}

function CGContextSetLineCap(aContext, aLineCap)
{
    aContext.setLineCap(aLineCap);
}

function CGContextSetLineDash(aContext, aPhase, someDashes)
{
    aContext.setLineDash(aPhase, someDashes);
}

function CGContextSetLineJoin(aContext, aLineJoin)
{
    aContext.setLineJoin(aLineJoin);
}

function CGContextSetLineWidth(aContext, aLineWidth)
{
    aContext.setLineWidth(aLineWidth);
}

function CGContextSetMiterLimit(aContext, aMiterLimit)
{
    aContext.setMiterLimit(aMiterLimit);
}

function CGContextSetBlendMode(aContext, aBlendMode)
{
    aContext.setBlendMode(aBlendMode);
}

function CGContextAddArc(aContext, x, y, radius, startAngle, endAngle, clockwise)
{
    aContext.addArc(x, y, radius, startAngle, endAngle, clockwise);
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
    aContext.addArcToPoint(x1, y1, x2, y2, radius);
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
    aContext.addCurveToPoint(cp1x, cp1y, cp2x, cp2y, x, y);
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
    aContext.addLines(points, count);
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
    aContext.addLineToPoint(x, y);
}

/*!
    Adds aPath to the current path in aContext
    @param aContext the CGContext to add to
    @param aPath the path to be added
    @return void
*/
function CGContextAddPath(aContext, aPath)
{
    aContext.addPath(aPath);
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
    aContext.addQuadCurveToPoint(cpx, cpy, x, y);
}

/*!
    Adds aRect to the current path in the given context
    @param aContext the CGContext to add to
    @param aRect the dimensions of the rectangle to add
    @return void
*/
function CGContextAddRect(aContext, aRect)
{
    aContext.addRect(aRect);
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
    aContext.addRects(rects, count);
}

/*!
    Begins a new subpath in the given context
    @param aContext the CGContext to create a new path in
    @return void
*/
function CGContextBeginPath(aContext)
{
    aContext.beginPath();
}

/*!
    Closes the currently open subpath, if any, in aContext
    @param aContext the CGContext to close a path in
    @return void
*/
function CGContextClosePath(aContext)
{
    aContext.closeSubpath();
}

/*!
    Return YES if the current path in the given context is empty.
    @param aContext the CGContext to examine
    @return BOOL
*/
function CGContextIsPathEmpty(aContext)
{
    return aContext.isPathEmpty();
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
    aContext.moveToPoint(x, y);
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
    CPLog.warn("CGContextFillRects, handing off to context...");
    aContext.fillRects(rects, count);
}

/*!
    Strokes a rectangle with the given location into the given context, using the context's current width and color
    @param aContext the CGContext to draw into
    @param aRect a CGRect indicating the dimensions of the rectangle to be drawn
    @return void
*/
function CGContextStrokeRect(aContext, aRect)
{
    aContext.strokeRect(aRect);
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
    aContext.concatCTM(aTransform);
}

/*!
    Returns the current transformation matrix for the given context
    @param aContext the CGContext for which we are asking for the transform
    @return CGAffineTransform the current transformation matrix of the given context
*/
function CGContextGetCTM(aContext)
{
    return aContext.getCTM();
}

/*!
    Rotates the current context by anAngle radians
    @param aContext the CGContext to rotate
    @param anAngle the amount to rotate, in radians
    @return void
*/

function CGContextRotateCTM(aContext, anAngle)
{
    aContext.rotateCTM(anAngle);
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
    aContext.scaleCTM(sx, sy);
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
    aContext.translateCTM(tx, ty);
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
    aContext.setShadow(aSize, aBlur);
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
    aContext.setShadowWithColor(aSize, aBlur, aColor);
}

/*!
    Sets the current alpha value for core graphics drawing operations in the given context .
    @param aContext the CGContext who's alpha value should be updated
    @param anAlpha the new alpha value. 1.0 is completely opaque, 0.0 is completely transparent.
    @return void
*/
function CGContextSetAlpha(aContext, anAlpha)
{
    aContext.setAlpha(MAX(MIN(anAlpha, 1.0), 0.0));
}

// GOOD.
/*!
    Fills in the area of the current path, using the even-odd fill rule.
    @param aContext the CGContext of the path
    @return void
*/
function CGContextEOFillPath(aContext)
{
    aContext.drawPath(kCGPathEOFill);
}

/*!
    Fills in the area of the current path, using  the non-zero winding number rule.
    @param aContext the CGContext of the path
    @return void
*/
function CGContextFillPath(aContext)
{
    aContext.drawPath(kCGPathFill);
    aContext.closePath();
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
    aContext.addEllipseInRect(aRect);
}

/*!
    Fills an ellipse bounded by a rectangle.
    @param aContext CGContext to draw on
    @param aRect the rectangle bounding the ellipse
    @return void
*/
function CGContextFillEllipseInRect(aContext, aRect)
{
    aContext.addEllipseInRect(aRect);
    aContext.drawPath(kCGPathFill);
}

/*!
    Strokes an ellipse bounded by the specified rectangle.
    @param aContext CGContext to draw on
    @param aRect the rectangle bounding the ellipse
    @return void
*/
function CGContextStrokeEllipseInRect(aContext, aRect)
{
    aContext.addEllipseInRect(aRect);
    aContext.drawPath(kCGPathStroke);
}

/*!
    Paints a line in the current path of the current context.
    @param aContext CGContext to draw on
    @return void
*/
function CGContextStrokePath(aContext)
{
    aContext.drawPath(kCGPathStroke);
    aContext.closePath();
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
    aContext.strokeLineSegments(points, count);
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
    aContext.setFillColor(aColor);
}

/*!
    Sets the current stroke color.
    @param aContext the CGContext
    @param aColor the new color for the stroke
    @return void
*/
function CGContextSetStrokeColor(aContext, aColor)
{
    aContext.setStrokeColor(aColor);
}

/*!
    Creates a context into which you can render a fill pattern
    of the given size. Once the pattern is rendered, you can
    set the fill or stroke pattern to the rendered pattern
    with CGContextSetFillPattern or CGContextSetStrokePattern.
*/
function CGContextCreatePatternContext(aContext, aSize)
{
    return aContext.createPatternContext(aSize);
}

/*!
    Sets the fill pattern for aContext to the rendered pattern context
    returned by CGContextCreatePatternContext.
*/
function CGContextSetFillPattern(aContext, aPatternContext)
{
    aContext.setFillPattern(aPatternContext);
}

/*!
    Sets the stroke pattern for aContext to the rendered pattern context
    returned by CGContextCreatePatternContext.
*/
function CGContextSetStrokePattern(aContext, aPatternContext)
{
    aContext.setStrokePattern(aPatternContext);
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
    Clears the specified rectangle.
    @param aContext the CGContext to draw into
    @param aRect the rectangle
    @return void
*/
function CGContextClearRect(aContext, aRect)
{
    aContext.clearRect(aRect);
}

/*!
    Sets the current path as the clipping path.
    @param aContext the CGContext to clip
    @return void
*/
function CGContextClip(aContext)
{
    aContext.clip();
}

/*!
    Sets the rect as the clipping path.
    @param aContext the CGContext to clip
    @param aRect the rectangle
    @return void
*/
function CGContextClipToRect(aContext, aRect)
{
    aContext.clipToRect(aRect);
}

/*!
    Sets the rects as the clipping path.
    @param aContext the CGContext to clip
    @param rects the rectangles to use as the clipping reference
    @param count the number of rectangles
    @return void
*/
function CGContextClipToRects(aContext, rects, count)
{
    aContext.clipToRects(rects, count);
}

/*!
    Draws the image in the specified rect
    @param aContext the CGContext within which to draw
    @param aRect the rectangle
    @param anImage the image to draw
    @return void
*/
function CGContextDrawImage(aContext, aRect, anImage)
{
    aContext.drawImage(aRect, anImage);
}

/*!
    Draws a linear gradient
    @param aContext the CGContext within which to draw
    @param aGradient a gradient comprising of a number of color stops
    @param aStartPoint the starting location for the gradient
    @param anEndPoint the ending location for the gradient
    @param options currently ignored
    @return void
*/
function CGContextDrawLinearGradient(aContext, aGradient, aStartPoint, anEndPoint, options)
{
    aContext.drawLinearGradient(aGradient, aStartPoint, anEndPoint, options);
}

/*!
    Draws a radial gradient
    @param aContext the CGContext within which to draw
    @param aGradient a gradient comprising of a number of color stops
    @param aStartPoint the starting location for the gradient
    @param anEndPoint the ending location for the gradient
    @param options currently ignored
    @return void
*/
function CGContextDrawRadialGradient(aContext, aGradient, aStartPoint, anEndPoint, options)
{
    aContext.drawRadialGradient(aGradient, aStartPoint, anEndPoint, options);
}

/*!
    @}
*/

/*!
@cond
*/
if (CPFeatureIsCompatible(CPHTMLCanvasFeature))
{
    CPLog.warn("CPHTMLCanvasFeature is supported!");
#include "CGContextCanvas.j"
}
else if (CPFeatureIsCompatible(CPVMLFeature))
{
    CPLog.warn("CPVMLFeature is supported!");
#include "CGContextVML.j"
}
/*!
@endcond
*/
