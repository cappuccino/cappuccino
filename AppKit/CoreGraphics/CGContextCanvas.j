/*
 * CGContextCanvas.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Modified by David Richardson.
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

// MODIFICATION: Converted 'var' to 'const' for immutable lookup tables.
const CANVAS_LINECAP_TABLE   = [ "butt", "round", "square" ];
const CANVAS_LINEJOIN_TABLE  = [ "miter", "round", "bevel" ];
const CANVAS_COMPOSITE_TABLE = [ "source-over", "source-over", "source-over", "source-over", "darker",
								 "lighter", "source-over", "source-over", "source-over", "source-over",
								 "source-over", "source-over", "source-over", "source-over", "source-over",
								 "source-over", "source-over",
								 "copy", "source-in", "source-out", "source-atop",
								 "destination-over", "destination-in", "destination-out", "destination-atop",
								 "xor", "source-over", "source-over" ];

// MODIFICATION: Removed all #define macros. Canvas methods are now invoked directly within the target functions
// to eliminate the preprocessor pass and simplify AST generation.

// In Cocoa, all primitives excepts rects and arcs cannot be added to the context's path
// until a move to point has been done, because an empty path has no current point.
// MODIFICATION: Converted to const function expression and applied Allman formatting.
const hasPath = function(aContext, methodName)
{
	if (!aContext.hasPath)
	{
		CPLog.error(methodName + ": no current point");
	}

	return aContext.hasPath;
};

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
	// MODIFICATION: Removed obsolete vendor prefixes (webkitLineDash, mozDash).
	if (aContext.setLineDash)
	{
		aContext.setLineDash(someDashes);
		aContext.lineDashOffset = aPhase;
	}
	else if (someDashes)
	{
		CPLog.warn("CGContextSetLineDash not implemented in this environment.");
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
	// MODIFICATION: Direct invocation replacing _CGContextAddArcCanvas macro.
	aContext.arc(x, y, radius, startAngle, endAngle, !clockwise);

	// AddArc implicitly starts a path
	aContext.hasPath = YES;
}

function CGContextAddArcToPoint(aContext, x1, y1, x2, y2, radius)
{
	if (!hasPath(aContext, "CGContextAddArcToPoint"))
	{
		return;
	}

	// MODIFICATION: Direct invocation replacing _CGContextAddArcToPointCanvas macro.
	aContext.arcTo(x1, y1, x2, y2, radius);
}

function CGContextAddCurveToPoint(aContext, cp1x, cp1y, cp2x, cp2y, x, y)
{
	if (!hasPath(aContext, "CGContextAddCurveToPoint"))
	{
		return;
	}

	// MODIFICATION: Direct invocation replacing _CGContextAddCurveToPointCanvas macro.
	aContext.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
}

function CGContextAddLines(aContext, points, count)
{
	// implementation mirrors that of CGPathAddLines()
	if (count == null)
	{
		count = points.length;
	}

	if (count < 1)
	{
		return;
	}

	// MODIFICATION: Direct invocations replacing macros.
	aContext.moveTo(points[0].x, points[0].y);

	// MODIFICATION: Replaced 'var' with 'let'.
	for (let i = 1; i < count; ++i)
	{
		aContext.lineTo(points[i].x, points[i].y);
	}

	aContext.hasPath = YES;
}

function CGContextAddLineToPoint(aContext, x, y)
{
	if (!hasPath(aContext, "CGContextAddLineToPoint"))
	{
		return;
	}

	// MODIFICATION: Direct invocation replacing macro.
	aContext.lineTo(x, y);
}

function CGContextAddPath(aContext, aPath)
{
	if (!aContext || CGPathIsEmpty(aPath))
	{
		return;
	}

	// If the context does not have a path, explicitly begin one
	if (!aContext.hasPath)
	{
		aContext.beginPath();
	}

	// We must implicitly move to the start of the path
	aContext.moveTo(aPath.start.x, aPath.start.y);

	// MODIFICATION: Replaced 'var' with 'const'/'let'.
	const elements = aPath.elements,
		  count    = aPath.count;

	for (let i = 0; i < count; ++i)
	{
		const element = elements[i],
		      type    = element.type;

		switch (type)
		{
			case kCGPathElementMoveToPoint:
				aContext.moveTo(element.x, element.y);
				break;

			case kCGPathElementAddLineToPoint:
				aContext.lineTo(element.x, element.y);
				break;

			case kCGPathElementAddQuadCurveToPoint:
				aContext.quadraticCurveTo(element.cpx, element.cpy, element.x, element.y);
				break;

			case kCGPathElementAddCurveToPoint:
				aContext.bezierCurveTo(element.cp1x, element.cp1y, element.cp2x, element.cp2y, element.x, element.y);
				break;

			case kCGPathElementCloseSubpath:
				aContext.closePath();
				break;

			case kCGPathElementAddArc:
				aContext.arc(element.x, element.y, element.radius, element.startAngle, element.endAngle, element.clockwise);
				break;

			case kCGPathElementAddArcToPoint:
				aContext.arcTo(element.p1x, element.p1y, element.p2x, element.p2y, element.radius);
				break;
		}
	}

	aContext.hasPath = YES;
}

function CGContextAddRect(aContext, aRect)
{
	// MODIFICATION: Direct invocation replacing _CGContextAddRectCanvas macro.
	aContext.rect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
	aContext.hasPath = YES;
}

function CGContextAddQuadCurveToPoint(aContext, cpx, cpy, x, y)
{
	if (!hasPath(aContext, "CGContextAddQuadCurveToPoint"))
	{
		return;
	}

	// MODIFICATION: Direct invocation replacing macro.
	aContext.quadraticCurveTo(cpx, cpy, x, y);
}

function CGContextAddRects(aContext, rects, count)
{
	if (count == null)
	{
		count = rects.length;
	}

	for (let i = 0; i < count; ++i)
	{
		const rect = rects[i];
		aContext.rect(CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetWidth(rect), CGRectGetHeight(rect));
	}

	aContext.hasPath = YES;
}

function CGContextBeginPath(aContext)
{
	aContext.beginPath();
	aContext.hasPath = NO;
}

function CGContextClosePath(aContext)
{
	aContext.closePath();
}

function CGContextIsPathEmpty(aContext)
{
	return !aContext.hasPath;
}

function CGContextMoveToPoint(aContext, x, y)
{
	aContext.moveTo(x, y);
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
	{
		return;
	}

	if (aMode === kCGPathFill || aMode === kCGPathFillStroke)
	{
		aContext.fill();
	}
	else if (aMode === kCGPathStroke || aMode === kCGPathFillStroke || aMode === kCGPathEOFillStroke)
	{
		aContext.stroke();
	}
	else if (aMode === kCGPathEOFill || aMode === kCGPathEOFillStroke)
	{
		CPLog.warn("Unimplemented fill mode in CGContextDrawPath: %d", aMode);
	}

	aContext.hasPath = NO;
}

function CGContextFillRect(aContext, aRect)
{
	// MODIFICATION: Direct invocation replacing macro.
	aContext.fillRect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
	aContext.hasPath = NO;
}

function CGContextFillRects(aContext, rects, count)
{
	if (count == null)
	{
		count = rects.length;
	}

	for (let i = 0; i < count; ++i)
	{
		const rect = rects[i];
		aContext.fillRect(CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetWidth(rect), CGRectGetHeight(rect));
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
	aContext.clip();
	aContext.hasPath = NO;
}

function CGContextClipToRect(aContext, aRect)
{
	aContext.beginPath();
	aContext.rect(CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
	aContext.closePath();

	aContext.clip();
	aContext.hasPath = NO;
}

function CGContextClipToRects(aContext, rects, count)
{
	if (count == null)
	{
		count = rects.length;
	}

	aContext.beginPath();
	CGContextAddRects(aContext, rects, count);
	aContext.clip();
	aContext.hasPath = NO;
}

function CGContextSetAlpha(aContext, anAlpha)
{
	aContext.globalAlpha = anAlpha;
}

function CGContextSetFillColor(aContext, aColor)
{
	const patternImage = [aColor patternImage];

	if ([patternImage isSingleImage])
	{
		const pattern = aContext.createPattern([patternImage image], "repeat");
		aContext.fillStyle = pattern;
	}
	else
	{
		aContext.fillStyle = [aColor cssString];
	}
}

/*!
 Creates a context into which you can render a fill pattern
 of the given size. Once the pattern is rendered, you can
 set the fill or stroke pattern to the rendered pattern
 with CGContextSetFillPattern or CGContextSetStrokePattern.
 */
function CGContextCreatePatternContext(aContext, aSize)
{
	const pattern = document.createElement("canvas");

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
	const pattern = aContext.createPattern(aPatternContext.canvas, "repeat");
	aContext.fillStyle = pattern;
}

/*!
 Sets the stroke pattern for aContext to the rendered pattern context
 returned by CGContextCreatePatternContext.
 */
function CGContextSetStrokePattern(aContext, aPatternContext)
{
	const pattern = aContext.createPattern(aPatternContext.canvas, "repeat");
	aContext.strokeStyle = pattern;
}

function CGContextSetStrokeColor(aContext, aColor)
{
	const patternImage = [aColor patternImage];

	if ([patternImage isSingleImage])
	{
		const pattern = aContext.createPattern([patternImage image], "repeat");
		aContext.strokeStyle = pattern;
	}
	else
	{
		aContext.strokeStyle = [aColor cssString];
	}
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

// MODIFICATION: Removed legacy mathematical fallback macros (scale_rotate, rotate_scale, eigen).
// MODIFICATION: Removed CPFeatureIsCompatible(CPJavaScriptCanvasTransformFeature) branch.
// Modern target environments inherently support native canvas transformations.

function CGContextConcatCTM(aContext, anAffineTransform)
{
	aContext.transform(anAffineTransform.a, anAffineTransform.b, anAffineTransform.c, anAffineTransform.d, anAffineTransform.tx, anAffineTransform.ty);
}

function CGContextDrawImage(aContext, aRect, anImage)
{
	aContext.drawImage(anImage._image, CGRectGetMinX(aRect), CGRectGetMinY(aRect), CGRectGetWidth(aRect), CGRectGetHeight(aRect));
	aContext.hasPath = NO;
}

function to_string(aColor)
{
	// MODIFICATION: Replaced macro ROUND with standard Math.round.
	return "rgba(" + Math.round(aColor.components[0] * 255) + ", " + Math.round(aColor.components[1] * 255) + ", " + Math.round(255 * aColor.components[2]) + ", " + aColor.components[3] + ")";
}

function CGContextDrawLinearGradient(aContext, aGradient, aStartPoint, anEndPoint, options)
{
	const colors = aGradient.colors;
	const linearGradient = aContext.createLinearGradient(aStartPoint.x, aStartPoint.y, anEndPoint.x, anEndPoint.y);
	let count = colors.length;

	while (count--)
	{
		linearGradient.addColorStop(aGradient.locations[count], to_string(colors[count]));
	}

	aContext.fillStyle = linearGradient;
	aContext.fill();
	aContext.hasPath = NO;
}

function CGContextDrawRadialGradient(aContext, aGradient, aStartCenter, aStartRadius, anEndCenter, anEndRadius, options)
{
	const colors = aGradient.colors;
	const linearGradient = aContext.createRadialGradient(aStartCenter.x, aStartCenter.y, aStartRadius, anEndCenter.x, anEndCenter.y, anEndRadius);
	let count = colors.length;

	while (count--)
	{
		linearGradient.addColorStop(aGradient.locations[count], to_string(colors[count]));
	}

	aContext.fillStyle = linearGradient;
	aContext.fill();
	aContext.hasPath = NO;
}

function CGBitmapGraphicsContextCreate()
{
	const DOMElement = document.createElement("canvas");
	const context = DOMElement.getContext("2d");

	context.DOMElement = DOMElement;

	// canvas gives us no way to query whether the path is empty or not, so we have to track it ourselves
	context.hasPath = NO;

	return context;
}
