/*
 * CGContextSVG.j
 * AppKit
 *
 * Created by Robert Grant.
 * Copyright 2015, plasq LLC.
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

@import "CGContext.j"

var SVG_TRUTH_TABLE     = [ "f", "t"],
    SVG_LINECAP_TABLE   = [ "flat", "round", "square" ],
    SVG_LINEJOIN_TABLE  = [ "miter", "round", "bevel" ],
    SVG_ELEMENT_TABLE   = [ " M ", " L ", " Q ", " C ", " Z ", [" at ", " wa "]];

function CGSVGGraphicsContext(width, height)
{
    CGContext.call(this);
    
    this.DOMElement = document.createElement("svg");
    // SVG is not included in the default Javascript elements so width and height will be ignored
    // if the property syntax is used.
    this.DOMElement.setAttribute("width", width);
    this.DOMElement.setAttribute("height", height);
}

CGSVGGraphicsContext.prototype = Object.create(CGContext.prototype);

CGSVGGraphicsContext.prototype.constructor = CGSVGGraphicsContext;

function CGSVGGraphicsContextCreate(width, height)
{
    return new CGSVGGraphicsContext(width, height);
}

function CGSVGGraphicsContextCreateImage(anSVGContext)
{
    return anSVGContext.DOMElement;
}

function CGContextDrawSVGImageAtPoint(aDIVContext, anSVGImage, aLocation)
{
    // Simply attach the SVG element to the DOMElement of the DIV context and set the
    // absolute location.
    anSVGImage.style.position = "absolute";
    anSVGImage.style.visibility = "visible";
    
    CPDOMDisplayServerSetStyleLeftTop(anSVGImage, NULL, aLocation.x, aLocation.y);
    aDIVContext.DOMElement.appendChild(anSVGImage);
}

CGSVGGraphicsContext.prototype.clearRect = function(aRect)
{
    // aRect is ignored!
    
    while (this.DOMElement.firstChild)
    {
        this.DOMElement.removeChild(this.DOMElement.firstChild);
    }
}

CGSVGGraphicsContext.prototype.applyStyleToElement = function(anElement, aMode)
{
    var style = new Array(),
        gState = this.gState,
        fill = (aMode == kCGPathFill || aMode == kCGPathFillStroke) ? 1 : 0,
        stroke = (aMode == kCGPathStroke || aMode == kCGPathFillStroke) ? 1 : 0,
        opacity = gState.alpha;
        
    if (fill) {
        style.push("fill: " + gState.fillStyle);
    } else {
        style.push("fill: none");
    }

    if (stroke) {
        style.push("stroke: " + gState.strokeStyle);
    } else {
        style.push("stroke: none");
    }
    anElement.setAttribute("style", style.join(";"));
}

CGSVGGraphicsContext.prototype.drawPath = function(aMode)
{
    if (CGPathIsEmpty(this.path))
        return;

    var elements = this.path.elements,

        i = 0,
        count = this.path.count,

        svgPath = document.createElement("path"),
        pathDescription = new Array();

    this.applyStyleToElement(svgPath, aMode);
    
    for (; i < count; ++i)
    {
        var element = elements[i],
            type = element.type;

        switch (type)
        {
            case kCGPathElementMoveToPoint:
            case kCGPathElementAddLineToPoint:      pathDescription.push(SVG_ELEMENT_TABLE[type], element.x, ',', element.y);
                                                    break;

            case kCGPathElementAddQuadCurveToPoint: pathDescription.push(SVG_ELEMENT_TABLE[type],
                                                        element.cpx, ',', element.cpy, ',',
                                                        element.x, ',', element.y);
                                                    break;

            case kCGPathElementAddCurveToPoint:     pathDescription.push(SVG_ELEMENT_TABLE[type],
                                                        element.cp1x, ',', element.cp1y, ',',
                                                        element.cp2x, ',', element.cp2y, ',',
                                                        element.x, ',', element.y);
                                                    break;

            case kCGPathElementCloseSubpath:        pathDescription.push(SVG_ELEMENT_TABLE[type]);
                                                    break;

/*
            case kCGPathElementAddArc:              var x = element.x,
                                                        y = element.y,
                                                        radius = element.radius,
                                                        clockwise = element.clockwise ? 1 : 0,
                                                        endAngle = element.endAngle,
                                                        startAngle = element.startAngle,

                                                        start = CGPointMake(x + radius * COS(startAngle), y + radius * SIN(startAngle));

                                                    // If the angle's are equal, then we won't actually draw an arc, but instead
                                                    // simply move to its start/end to get the proper fill.
                                                    // We only need this special case for anti-clockwise because start == end is
                                                    // interpreted as a full circle with anti-clockwise, but empty for clockwise.
                                                    if (startAngle == endAngle && !clockwise)
                                                    {
                                                        pathDescription.push(VML_ELEMENT_TABLE[kCGPathElementMoveToPoint], start.x), ',', start.y));

                                                        continue;
                                                    }

                                                    var end = CGPointMake(x + radius * COS(endAngle), y + radius * SIN(endAngle));

                                                    // Only do the start correction if the angles aren't equal.  If they are, then
                                                    // let the circle be empty.
                                                    // FIXME: Should this be |star.x - end.x| < 0.125 ?
                                                    if (clockwise && startAngle != endAngle && CGPointEqualToPoint(start, end))
                                                        if (start.x >= x)
                                                        {
                                                            if (start.y < y)
                                                                start.x += 0.125;
                                                            else
                                                                start.y += 0.125;
                                                        }
                                                        else
                                                        {
                                                            if (end.y <= y)
                                                                end.x += 0.125;
                                                            else
                                                                end.y += 0.125;
                                                        }

                                                    pathDescription.push(VML_ELEMENT_TABLE[type][clockwise],
                                                        x - radius), ',', y - radius), " ",
                                                        x + radius), ',', y + radius), " ",
                                                        start.x), ',', start.y), " ",
                                                        end.x), ',', end.y));
                                                    break;
            case kCGPathElementAddArcToPoint:       break;
*/
        }
    }

    svgPath.setAttribute("d", pathDescription.join(""));

    this.DOMElement.appendChild(svgPath);
}

