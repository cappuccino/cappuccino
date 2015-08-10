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

var SVGNameSpace = "http://www.w3.org/2000/svg";

var SVG_TRUTH_TABLE     = [ "f", "t"],
    SVG_LINECAP_TABLE   = [ "flat", "round", "square" ],
    SVG_LINEJOIN_TABLE  = [ "miter", "round", "bevel" ],
    SVG_ELEMENT_TABLE   = [ " M ", " L ", " Q ", " C ", " Z ", [" at ", " wa "]];

function CGSVGGraphicsContext(width, height)
{
    CGContext.call(this);
    
    this.DOMElement = document.createElementNS(SVGNameSpace, "svg");
    // SVG is not included in the default Javascript elements so width and height will be ignored
    // if the property syntax is used.
    this.DOMElement.setAttribute("width", width + "px");
    this.DOMElement.setAttribute("height", height + "px");
    this.defsElement = document.createElementNS(SVGNameSpace, "defs");
    this.DOMElement.appendChild(this.defsElement);
    this.gradients = new Object();
    this.shadowFilters = new Object();
    this.groups = new Array();
    this.shadowID = 0;
    
    CPDOMDisplayServerSetStyleSize(this.DOMElement, width, height);
}

CGSVGGraphicsContext.prototype = Object.create(CGContext.prototype);

CGSVGGraphicsContext.prototype.constructor = CGSVGGraphicsContext;

CGSVGGraphicsContext.prototype.toString = function()
{
    return "CGSVGGraphicsContext";
}

function CGSVGGraphicsContextCreate(width, height)
{
    return new CGSVGGraphicsContext(width, height);
}

function CGSVGGraphicsContextCreateImage(anSVGContext)
{
    anSVGContext.addDefinitions();
    
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


CGSVGGraphicsContext.prototype.currentDOMElementContainer = function()
{
    if (this.groups.length == 0)
    {
        return this.DOMElement;   
    } else
    {
        return this.groups[this.groups.length - 1];
    }
}

CGSVGGraphicsContext.prototype.defineGradients = function()
{
//    CPLog.trace("CGSVGGraphicsContext.prototype.defineGradients()");
    
    for (var key in this.gradients)
    {
        var gradient = this.gradients[key];
        var gradientDef = document.createElementNS(SVGNameSpace, "linearGradient");
        gradientDef.id = gradient.name;
        var count = gradient.locations.length;
        for (var i = 0; i < count; i++)
        {
            var gradientOffset = document.createElementNS(SVGNameSpace, "stop");
            gradientOffset.setAttribute("offset", gradient.locations[i]);
            var color = gradient.colors[i];
            // CGColor support is lacking!
            var cpcolor = [[CPColor alloc] _initWithRGBA: CGColorGetComponents(color)];
            gradientOffset.setAttribute("style", "stop-color: " + [cpcolor cssString]);
            gradientDef.appendChild(gradientOffset);
        }
        this.defsElement.appendChild(gradientDef);
    }
}

CGSVGGraphicsContext.prototype.defineShadowFilters = function()
{
//    CPLog.trace("CGSVGGraphicsContext.prototype.defineShadowFilters()");
    for (var key in this.shadowFilters)
    {
        var shadowFilter = this.shadowFilters[key];
        
        var shadowFilterDef = document.createElementNS(SVGNameSpace, "filter");
        shadowFilterDef.id = shadowFilter.name;
        {
            var blurDef = document.createElementNS(SVGNameSpace, "feGaussianBlur");
            blurDef.setAttribute("in", "SourceAlpha");
            blurDef.setAttribute("stdDeviation", shadowFilter.blur);
            blurDef.setAttribute("result", "blur");
            shadowFilterDef.appendChild(blurDef);
        }
        
        {
            var offsetDef = document.createElementNS(SVGNameSpace, "feOffset");
            offsetDef.setAttribute("in", "blur");
            offsetDef.setAttribute("dx", shadowFilter.size.width);
            offsetDef.setAttribute("dy", shadowFilter.size.height);
            offsetDef.setAttribute("result", "offset");
            shadowFilterDef.appendChild(offsetDef);
        }

        {
            var mergeDef = document.createElementNS(SVGNameSpace, "feMerge");
            {
                var node = document.createElementNS(SVGNameSpace, "feMergeNode");
                node.setAttribute("in", "offset");
                mergeDef.appendChild(node);
            }
            {
                var node = document.createElementNS(SVGNameSpace, "feMergeNode");
                node.setAttribute("in", "SourceGraphic");
                mergeDef.appendChild(node);
            }
            shadowFilterDef.appendChild(mergeDef);
        }
        
        this.defsElement.appendChild(shadowFilterDef);
    }
}


CGSVGGraphicsContext.prototype.addDefinitions = function()
{
//    CPLog.trace("CGSVGGraphicsContext.prototype.addDefinitions()");
    this.defineGradients();
    this.defineShadowFilters();
}

CGSVGGraphicsContext.prototype.addFilters = function()
{
//    CPLog.trace("CGSVGGraphicsContext.prototype.addFilters()");
    this.defineShadowFilters();
}

CGSVGGraphicsContext.prototype.clearRect = function(aRect)
{
    // aRect is ignored!
    
    while (this.DOMElement.firstChild)
    {
        this.DOMElement.removeChild(this.DOMElement.firstChild);
    }
}

CGSVGGraphicsContext.prototype.setShadowWithColor = function(aSize, aBlur, aColor)
{
    this.gState.shadowOffset = CGSizeMakeCopy(aSize);
    this.gState.shadowBlur = aBlur;
    this.gState.shadowColor = aColor;
    
    if (aColor !== nil)
    {
        var shadowName = "Shadow" + this.shadowID++;
        var shadowFilter = { name: shadowName, size: aSize, blur: aBlur, color: this.gState.shadowColor };
        this.shadowFilters[shadowFilter.name] = shadowFilter;
        this.activeShadow = shadowFilter;
    } else
    {
        this.activeShadow = nil;
    }
}

CGSVGGraphicsContext.prototype.applyStyleToElement = function(anElement, aMode)
{
    var style = new Array(),
        gState = this.gState,
        fill = (aMode == kCGPathFill || aMode == kCGPathFillStroke) ? 1 : 0,
        stroke = (aMode == kCGPathStroke || aMode == kCGPathFillStroke) ? 1 : 0,
        opacity = gState.alpha;
        
    if (this.activeGradient)
    {
        // An active gradient automatically enables a fill
        style.push("fill: url(#" + this.activeGradient.name + ")");
    }
    else
    {
        if (fill) {
            style.push("fill: " + gState.fillStyle);
        } else {
            style.push("fill: none");
        }
    }

    if (stroke) {
        style.push("stroke: " + gState.strokeStyle);
    } else {
        style.push("stroke: none");
    }
    
    if (this.activeShadow)
    {
        anElement.setAttribute("filter", "url(#" + this.activeShadow.name + ")");
    }
    
    anElement.setAttribute("style", style.join(";"));
}

CGSVGGraphicsContext.prototype.applyTransformToElement = function(anElement)
{
    var transform = this.gState.CTM;
    if (CGAffineTransformIsIdentity(transform) == NO)
    {
        anElement.setAttribute("transform", "matrix(" + transform.a + " " + transform.b + " "
                                                      + transform.c + " " + transform.d + " "
                                                      + transform.tx + " " + transform.ty + ")");
    }
}

CGSVGGraphicsContext.prototype.createSVGElement = function(elementType)
{
    var svgElement = document.createElementNS(SVGNameSpace, elementType);
    this.applyTransformToElement(svgElement);
    return svgElement;
}


CGSVGGraphicsContext.prototype.fillRects = function(rects, count)
{
    var group = this.createSVGElement("g");
    group.setAttribute("style", "fill: " + this.gState.fillStyle);
    
    for (var i = 0; i < count; i++)
    {
        var aRect = rects[i];
        var rectElement = document.createElementNS(SVGNameSpace, "rect");
        rectElement.setAttribute("x", CGRectGetMinX(aRect));
        rectElement.setAttribute("y", CGRectGetMinY(aRect));
        rectElement.setAttribute("width", CGRectGetWidth(aRect));
        rectElement.setAttribute("height", CGRectGetHeight(aRect));
        group.appendChild(rectElement);
    }
    
    var container = this.currentDOMElementContainer();
    container.appendChild(group);
}

CGSVGGraphicsContext.prototype.drawPath = function(aMode)
{
    if (CGPathIsEmpty(this.path))
        return;

    var elements = this.path.elements,

    i = 0,
    count = this.path.count;

    var svgPath = this.createSVGElement("path");
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

    var container = this.currentDOMElementContainer();
    container.appendChild(svgPath);
}

CGSVGGraphicsContext.prototype.drawImage = function(aRect, anImage)
{
    var imageElement = this.createSVGElement("image");
    imageElement.setAttributeNS("http://www.w3.org/1999/xlink","href", anImage._filename);
    imageElement.setAttribute("x", CGRectGetMinX(aRect));
    imageElement.setAttribute("y", CGRectGetMinY(aRect));
    imageElement.setAttribute("width", CGRectGetWidth(aRect));
    imageElement.setAttribute("height", CGRectGetHeight(aRect));
    var container = this.currentDOMElementContainer();
    container.appendChild(imageElement);
}


CGSVGGraphicsContext.prototype.drawLinearGradient = function(aGradient, aStartPoint, anEndPoint, options)
{
//    CPLog.trace("CGSVGGraphicsContext.prototype.drawLinearGradient()");
    this.gradients[aGradient.name] = aGradient;
    this.activeGradient = aGradient;
    this.drawPath();
    this.activeGradient = nil;
}

CGSVGGraphicsContext.prototype.drawRadialGradient = function(aGradient, aStartCenter, aStartRadius, anEndCenter, anEndRadius, options)
{
    CPLog.warn("CGSVGGraphicsContext.prototype.drawRadialGradient() unimplemented");
}

CGSVGGraphicsContext.prototype.beginTransparencyLayerWithRect = function(aRect, auxiliaryInfo)
{
    this.saveGState();
    // We don't want any transform on the transparency layer.
    var group = document.createElementNS(SVGNameSpace, "g");

    // Set (and reset) the shadow if any
    if (this.activeShadow)
    {
        group.setAttribute("filter", "url(#" + this.activeShadow.name + ")");
    }

    CGContextSetShadowWithColor(this, CGSizeMake(0, 0), 0, nil);    
    
    // Set (and reset) the alpha
    group.setAttribute("opacity", this.gState.alpha);
    CGContextSetAlpha(this, 1);

    if (this.gState.blendMode != kCGBlendModeNormal)
    {
        CGContextSetAlpha(this, kCGBlendModeNormal);
    }
    
    
    this.groups.push(group);
}

CGSVGGraphicsContext.prototype.endTransparencyLayer = function()
{
    var group = this.groups.pop();
    var container = this.currentDOMElementContainer();
    container.appendChild(group);
    
    this.restoreGState();
}

/*!
    Apply the current configured text style to the style array
    @param force apply the style param even if it is the same as currently currently configured.
*/
function CGSVGGraphicsContextApplyTextStyle(aContext, style, force)
{
    if (force == YES || aContext.textGState.font != aContext.gState.font)
    {
        style.push("font-family: " + CGFontCopyFullName(aContext.gState.font));
    }

    if (force == YES || aContext.textGState.fontSize != aContext.gState.fontSize)
    {
        style.push("font-size: " + aContext.gState.fontSize);
    }

    switch(aContext.gState.textDrawingMode)
    {
        case kCGTextFill:
            if (force == YES || aContext.textGState.fillStyle != aContext.gState.fillStyle)
            {
                style.push("fill: " + aContext.gState.fillStyle);
                style.push("stroke: none");
            }
            break;
        case kCGTextStroke:
            if (force == YES || aContext.textGState.strokeStyle != aContext.gState.strokeStyle)
            {
                style.push("fill: none");
                style.push("stroke: " + aContext.gState.strokeStyle);
            }
        case kCGTextFillStroke:
            if (force == YES || aContext.textGState.strokeStyle != aContext.gState.strokeStyle ||
                aContext.textGState.fillStyle != aContext.gState.fillStyle)
            {
                style.push("fill: " + aContext.gState.fillStyle);
                style.push("stroke: " + aContext.gState.strokeStyle);
            }
        
        default:
            break;
    }
}

/*!
    Creates an SVG 'text' element within which 'tspan' elements can be placed
 */
CGSVGGraphicsContext.prototype.beginText = function()
{
    this.svgText = this.createSVGElement("text");
    var location = this.textPosition();
    this.svgText.setAttribute("x", location.x);
    this.svgText.setAttribute("y", location.y);
    // Preserve the gState so that we know if state deviates
    this.textGState = CGGStateCreateCopy(this.gState);

    style = new Array();
        
    CGSVGGraphicsContextApplyTextStyle(this, style, YES);

    this.svgText.setAttribute("style", style.join(";"));
}

/*!
    Appends the SVG 'text' element and resets itself
 */
CGSVGGraphicsContext.prototype.endText = function()
{
    this.DOMElement.appendChild(this.svgText);
    this.svgText = nil;
}

/*!
    Apply the current configured text style to the style array
    @param text the text to show
    @param positions currently ignored - the configured textPosition is used instead
    @param count currently ignored.
*/
CGSVGGraphicsContext.prototype.showTextAtPositions = function(text, positions, count)
{
    var textElement = nil;
    
    style = new Array();
    if (this.svgText)
    {
        textElement = document.createElementNS(SVGNameSpace, "tspan");
        CGSVGGraphicsContextApplyTextStyle(this, style, NO);
    }
    else
    {
        textElement = document.createElementNS(SVGNameSpace, "text");
        CGSVGGraphicsContextApplyTextStyle(this, style, YES);
    }
    
    textElement.setAttribute("style", style.join(";"));
    if (this.svgText == nil)
    {
        var location = this.textPosition();
        textElement.x = location.x;
        textElement.y = location.y;
    }
    textElement.textContent = text;
    this.textMatrix.tx += textElement.getComputedTextLength();
    if (this.svgText)
        this.svgText.appendChild(textElement);
    else
    {
        var container = this.currentDOMElementContainer();
        container.appendChild(textElement);
    }
}
