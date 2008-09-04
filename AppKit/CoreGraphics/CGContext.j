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

import "CGGeometry.j"
import "CGAffineTransform.j"
import "CGPath.j"

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

function CGContextRelease()
{
}

function CGContextRetain(aContext)
{
    return aContext;
}

if (!CPFeatureIsCompatible(CPHTMLCanvasFeature))
{

function CGGStateCreate()
{
    return { strokeStyle:"#000", fillStyle:"#ccc", lineWidth:1.0, lineJoin:kCGLineJoinMiter, lineCap:kCGLineCapButt, miterLimit:10.0, globalAlpha:1.0, 
        blendMode:kCGBlendModeNormal, 
        shadowOffset:_CGSizeMakeZero(), shadowBlur:0.0, shadowColor:NULL, CTM:_CGAffineTransformMakeIdentity() };
}

function CGGStateCreateCopy(aGState)
{
    return { strokeStyle:aGState.strokeStyle, fillStyle:aGState.fillStyle, lineWidth:aGState.lineWidth, 
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

}

// GOOD.

function CGContextEOFillPath(aContext, aMode)
{
    CGContextDrawPath(aContext, kCGPathEOFill);
}

function CGContextFillPath(aContext)
{
    CGContextDrawPath(aContext, kCGPathFill);
}

var KAPPA = 4.0 * ((SQRT2 - 1.0) / 3.0);

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


function CGContextFillEllipseInRect(aContext, aRect)
{
    CGContextAddEllipseInRect(aContext, aRect);
    CGContextFillPath(aContext);
}

function CGContextStrokeEllipseInRect(aContext, aRect)
{
    CGContextAddEllipseInRect(aContext, aRect);
    CGContextStrokePath(aContext);
}

function CGContextStrokePath(aContext)
{
    CGContextDrawPath(aContext, kCGPathStroke);
}

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

// FIXME: THIS IS WRONG!!!

function CGContextSetFillColor(aContext, aColor)
{
    if (aColor)
        aContext.gState.fillStyle = [aColor cssString];
}

function CGContextSetStrokeColor(aContext, aColor)
{
    if (aColor)
        aContext.gState.strokeStyle = [aColor cssString];
}

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

if (CPFeatureIsCompatible(CPHTMLCanvasFeature))
{
#include "CGContextCanvas.j"
}
else if (CPFeatureIsCompatible(CPVMLFeature))
{
#include "CGContextVML.j"
}
