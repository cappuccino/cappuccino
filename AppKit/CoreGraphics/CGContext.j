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

#include "CGGeometry.h"
#include "CGAffineTransform.h"

@import "CGGeometry.j"
@import "CGAffineTransform.j"
@import "CGPath.j"

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

/*
    @global
    @group CGBlendMode
*/
kCGBlendModeNormal          = 0;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeMultiply        = 1;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeScreen          = 2;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeOverlay         = 3;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeDarken          = 4;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeLighten         = 5;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeColorDodge      = 6;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeColorBurn       = 7;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeSoftLight       = 8;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeHardLight       = 9;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeDifference      = 10;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeExclusion       = 11;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeHue             = 12;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeSaturation      = 13;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeColor           = 14;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeLuminosity      = 15;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeClear           = 16;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeCopy            = 17;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeSourceIn        = 18;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeSourceOut       = 19;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeSourceAtop      = 20;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeDestinationOver = 21;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeDestinationIn   = 22;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeDestinationOut  = 23;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeDestinationAtop = 24;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModeXOR             = 25;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModePlusDarker      = 26;
/*
    @global
    @group CGBlendMode
*/
kCGBlendModePlusLighter     = 27;

/*!
    This function is just here for source compatability.
    It does nothing.
    @group CGContext
*/
function CGContextRelease()
{
}

/*!
    This function is just here for source compatability.
    It does nothing.
    @param aContext a CGContext
    @return CGContext the context
*/
function CGContextRetain(aContext)
{
    return aContext;
}

// BEGIN CANVAS IF
if (!CPFeatureIsCompatible(CPHTMLCanvasFeature))
{

function CGGStateCreate()
{
    return { alpha:1.0, strokeStyle:"#000", fillStyle:"#ccc", lineWidth:1.0, lineJoin:kCGLineJoinMiter, lineCap:kCGLineCapButt, miterLimit:10.0, globalAlpha:1.0, 
        blendMode:kCGBlendModeNormal, 
        shadowOffset:_CGSizeMakeZero(), shadowBlur:0.0, shadowColor:NULL, CTM:_CGAffineTransformMakeIdentity() };
}

function CGGStateCreateCopy(aGState)
{
    return { alpha:aGState.alpha, strokeStyle:aGState.strokeStyle, fillStyle:aGState.fillStyle, lineWidth:aGState.lineWidth, 
        lineJoin:aGState.lineJoin, lineCap:aGState.lineCap, miterLimit:aGState.miterLimit, globalAlpha:aGState.globalAlpha, 
        blendMode:aGState.blendMode, 
        shadowOffset:aGState.shadowOffset, shadowBlur:aGState.shadowBlur, shadowColor:aGState.shadowColor, CTM:_CGAffineTransformMakeCopy(aGState.CTM) };
}

function CGBitmapGraphicsContextCreate()
{
    return { DOMElement:document.createElement("div"), path:NULL, gState:CGGStateCreate(), gStateStack:[] };
}

function CGContextSaveGState(aContext)
{
    aContext.gStateStack.push(CGGStateCreateCopy(aContext.gState));
}

function CGContextRestoreGState(aContext)
{
    aContext.gState = aContext.gStateStack.pop();
}

function CGContextSetLineCap(aContext, aLineCap)
{
    aContext.gState.lineCap = aLineCap;
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

function CGContextAddArcToPoint(aContext, x1, y1, x2, y2, radius)
{
    CGPathAddArcToPoint(aContext.path, aContext.gState.CTM, x1, y1, x2, y2, radius);
}

function CGContextAddCurveToPoint(aContext, cp1x, cp1y, cp2x, cp2y, x, y)
{
    CGPathAddCurveToPoint(aContext.path, aContext.gState.CTM, cp1x, cp1y, cp2x, cp2y, x, y);
}

function CGContextAddLines(aContext, points, count)
{
    CGPathAddLines(aContext.path, aContext.gState.CTM, points, count);
}

function CGContextAddLineToPoint(aContext, x, y)
{
    CGPathAddLineToPoint(aContext.path, aContext.gState.CTM, x, y);
}

function CGContextAddPath(aContext, aPath)
{
    if (!aContext || CGPathIsEmpty(aPath))
        return;
        
    if (!aContext.path)
        aContext.path = CGPathCreateMutable();
        
    CGPathAddPath(aContext.path, aContext.gState.CTM, aPath);
}

function CGContextAddQuadCurveToPoint(aContext, cpx, cpy, x, y)
{
    CGPathAddQuadCurveToPoint(aContext.path, aContext.gState.CTM, cpx, cpy, x, y);
}

function CGContextAddRect(aContext, aRect)
{
    CGPathAddRect(aContext.path, aContext.gState.CTM, aRect);
}

function CGContextAddRects(aContext, rects, count)
{
    CGPathAddRects(aContext.path, aContext.gState.CTM, rects, count);
}

function CGContextBeginPath(aContext)
{
    // This clears any previous path.
    aContext.path = CGPathCreateMutable();
}

function CGContextClosePath(aContext)
{
    CGPathCloseSubpath(aContext.path);
}

function CGContextMoveToPoint(aContext, x, y)
{
    if (!aContext.path)
        aContext.path = CGPathCreateMutable();
    
    CGPathMoveToPoint(aContext.path, aContext.gState.CTM, x, y);
}

function CGContextFillRect(aContext, aRect)
{
    CGContextFillRects(aContext, [aRect], 1);
}

function CGContextFillRects(aContext, rects, count)
{
    if (arguments["count"] == NULL)
        var count = rects.length;
    
    CGContextBeginPath(aContext);
    CGContextAddRects(aContext, rects, count);
    CGContextClosePath(aContext);
    
    CGContextDrawPath(aContext, kCGPathFill);
}

function CGContextStrokeRect(aContext, aRect)
{   
    CGContextBeginPath(aContext);
    CGContextAddRect(aContext, aRect);
    CGContextClosePath(aContext);
    
    CGContextDrawPath(aContext, kCGPathStroke);
}

function CGContextStrokeRectWithWidth(aContext, aRect, aWidth)
{
    CGContextSaveGState(aContext);
    
    CGContextSetLineWidth(aContext, aWidth);
    CGContextStrokeRect(aContext, aRect);
    
    CGContextRestoreGState(aContext);
}

function CGContextConcatCTM(aContext, aTransform)
{
    var CTM = aContext.gState.CTM;
    
    _CGAffineTransformConcatTo(CTM, aTransform, CTM);
}

function CGContextGetCTM(aContext)
{
    return aContext.gState.CTM;
}

function CGContextRotateCTM(aContext, anAngle)
{
    var gState = aContext.gState;
    
    gState.CTM = CGAffineTransformRotate(gState.CTM, anAngle);
}

function CGContextScaleCTM(aContext, sx, sy)
{
    var gState = aContext.gState;
    
    gState.CTM = _CGAffineTransformScale(gState.CTM, sx, sy);
}

function CGContextTranslateCTM(aContext, tx, ty)
{
    var gState = aContext.gState;
    
    gState.CTM = _CGAffineTransformTranslate(gState.CTM, tx, ty);
}

function CGContextSetShadow(aContext, aSize, aBlur)
{
    var gState = aContext.gState;
    
    gState.shadowOffset = _CGSizeMakeCopy(aSize);
    gState.shadowBlur = aBlur;
    gState.shadowColor = [CPColor shadowColor];
}

function CGContextSetShadowWithColor(aContext, aSize, aBlur, aColor)
{
    var gState = aContext.gState;
    
    gState.shadowOffset = _CGSizeMakeCopy(aSize);
    gState.shadowBlur = aBlur;
    gState.shadowColor = aColor;
}

function CGContextSetAlpha(aContext, anAlpha)
{
    aContext.gState.alpha = MAX(MIN(anAlpha, 1.0), 0.0);
}

}   // END CANVAS IF

// GOOD.
/*!
    Fills in the area of the current path, using the even-odd fill rule.
    @param aContext the CGContext of the path
    @return void
    @group CGContext
*/
function CGContextEOFillPath(aContext)
{
    CGContextDrawPath(aContext, kCGPathEOFill);
}

/*!
    Fills in the area of the current path, using  the non-zero winding number rule.
    @param aContext the CGContext of the path
    @return void
    @group CGContext
*/
function CGContextFillPath(aContext)
{
    CGContextDrawPath(aContext, kCGPathFill);
}

var KAPPA = 4.0 * ((SQRT2 - 1.0) / 3.0);

/*!
    Draws the outline of an ellipse bounded by a rectangle.
    @param aContext CGContext to draw on
    @param aRect the rectangle bounding the ellipse
    @return void
    @group CGContext
*/
function CGContextAddEllipseInRect(aContext, aRect)
{
	CGContextBeginPath(aContext);
	
	if (_CGRectGetWidth(aRect) == _CGRectGetHeight(aRect))
	    CGContextAddArc(aContext, _CGRectGetMidX(aRect), _CGRectGetMidY(aRect), _CGRectGetWidth(aRect) / 2.0, 0.0, 2 * PI, YES);
	else
	{
	    var axis = _CGSizeMake(_CGRectGetWidth(aRect) / 2.0, _CGRectGetHeight(aRect) / 2.0),
	        center = _CGPointMake(_CGRectGetMinX(aRect) + axis.width, _CGRectGetMinY(aRect) + axis.height);
	
	    CGContextMoveToPoint(aContext, center.x, center.y - axis.height);
	
	    CGContextAddCurveToPoint(aContext, center.x + (KAPPA * axis.width), center.y - axis.height,  center.x + axis.width, center.y - (KAPPA * axis.height), center.x + axis.width, center.y);
	    CGContextAddCurveToPoint(aContext, center.x + axis.width, center.y + (KAPPA * axis.height), center.x + (KAPPA * axis.width), center.y + axis.height, center.x, center.y + axis.height);
	    CGContextAddCurveToPoint(aContext, center.x - (KAPPA * axis.width), center.y + axis.height, center.x - axis.width, center.y + (KAPPA * axis.height), center.x - axis.width, center.y);
	    CGContextAddCurveToPoint(aContext, center.x - axis.width, center.y - (KAPPA * axis.height), center.x - (KAPPA * axis.width), center.y - axis.height, center.x, center.y - axis.height);
	}
	
	CGContextClosePath(aContext);
}

/*!
    Fills an ellipse bounded by a rectangle.
    @param aContext CGContext to draw on
    @param aRect the rectangle bounding the ellipse
    @return void
    @group CGContext
*/
function CGContextFillEllipseInRect(aContext, aRect)
{
    CGContextAddEllipseInRect(aContext, aRect);
    CGContextFillPath(aContext);
}

/*!
    Strokes an ellipse bounded by the specified rectangle.
    @param aContext CGContext to draw on
    @param aRect the rectangle bounding the ellipse
    @return void
    @group CGContext
*/
function CGContextStrokeEllipseInRect(aContext, aRect)
{
    CGContextAddEllipseInRect(aContext, aRect);
    CGContextStrokePath(aContext);
}

/*!
    Paints a line in the current path of the current context.
    @param aContext CGContext to draw on
    @return void
    @group CGContext
*/
function CGContextStrokePath(aContext)
{
    CGContextDrawPath(aContext, kCGPathStroke);
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
    @group CGContext
*/
function CGContextStrokeLineSegments(aContext, points, count)
{
    var i = 0;
    
    if (arguments["count"] == NULL)
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
    @group CGContext
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
    @group CGContext
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
    @param aRadius the distance from the rectange corner to the rounded corner
    @param ne set it to <code>YES</code> for a rounded northeast corner
    @param se set it to <code>YES</code> for a rounded southeast corner
    @param sw set it to <code>YES</code> for a rounded southwest corner
    @param nw set it to <code>YES</code> for a rounded northwest corner
    @return void
    @group CGContext
*/
function CGContextFillRoundedRectangleInRect(aContext, aRect, aRadius, ne, se, sw, nw)
{
    var xMin = _CGRectGetMinX(aRect),
        xMax = _CGRectGetMaxX(aRect),
        yMin = _CGRectGetMinY(aRect),
        yMax = _CGRectGetMaxY(aRect);

    CGContextBeginPath(aContext);
    CGContextMoveToPoint(aContext, xMin + aRadius, yMin);
	
	if (ne)
	{
		CGContextAddLineToPoint(aContext, xMax - aRadius, yMin);
		CGContextAddCurveToPoint(aContext, xMax - aRadius, yMin, xMax, yMin, xMax, yMin + aRadius);
	}
	else
		CGContextAddLineToPoint(aContext, xMax, yMin);
	
	if (se)
	{
		CGContextAddLineToPoint(aContext, xMax, yMax - aRadius);
		CGContextAddCurveToPoint(aContext, xMax, yMax - aRadius, xMax, yMax, xMax - aRadius, yMax);
	}
	else
		CGContextAddLineToPoint(aContext, xMax, yMax);
	
	if (sw)
	{
		CGContextAddLineToPoint(aContext, xMin + aRadius, yMax);
		CGContextAddCurveToPoint(aContext, xMin + aRadius, yMax, xMin, yMax, xMin, yMax - aRadius);
	}
	else
		CGContextAddLineToPoint(aContext, xMin, yMax);
	
	if (nw)
	{
		CGContextAddLineToPoint(aContext, xMin, yMin + aRadius);
		CGContextAddCurveToPoint(aContext, xMin, yMin + aRadius, xMin, yMin, xMin + aRadius, yMin);
	} else
		CGContextAddLineToPoint(aContext, xMin, yMin);
	
	CGContextClosePath(aContext);
	
    CGContextFillPath(aContext);
}

function CGContextStrokeRoundedRectangleInRect(aContext, aRect, aRadius, ne, se, sw, nw)
{
    var xMin = _CGRectGetMinX(aRect),
        xMax = _CGRectGetMaxX(aRect),
        yMin = _CGRectGetMinY(aRect),
        yMax = _CGRectGetMaxY(aRect);

    CGContextBeginPath(aContext);
    CGContextMoveToPoint(aContext, xMin + aRadius, yMin);
	
	if (ne)
	{
		CGContextAddLineToPoint(aContext, xMax - aRadius, yMin);
		CGContextAddCurveToPoint(aContext, xMax - aRadius, yMin, xMax, yMin, xMax, yMin + aRadius);
	}
	else
		CGContextAddLineToPoint(aContext, xMax, yMin);
	
	if (se)
	{
		CGContextAddLineToPoint(aContext, xMax, yMax - aRadius);
		CGContextAddCurveToPoint(aContext, xMax, yMax - aRadius, xMax, yMax, xMax - aRadius, yMax);
	}
	else
		CGContextAddLineToPoint(aContext, xMax, yMax);
	
	if (sw)
	{
		CGContextAddLineToPoint(aContext, xMin + aRadius, yMax);
		CGContextAddCurveToPoint(aContext, xMin + aRadius, yMax, xMin, yMax, xMin, yMax - aRadius);
	}
	else
		CGContextAddLineToPoint(aContext, xMin, yMax);
	
	if (nw)
	{
		CGContextAddLineToPoint(aContext, xMin, yMin + aRadius);
		CGContextAddCurveToPoint(aContext, xMin, yMin + aRadius, xMin, yMin, xMin + aRadius, yMin);
	} else
		CGContextAddLineToPoint(aContext, xMin, yMin);
	
	CGContextClosePath(aContext);
	
    CGContextStrokePath(aContext);
}

if (CPFeatureIsCompatible(CPHTMLCanvasFeature))
{
#include "CGContextCanvas.j"
}
else if (CPFeatureIsCompatible(CPVMLFeature))
{
#include "CGContextVML.j"
}
