/*
 * CGContextVML.j
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

var VML_TRUTH_TABLE     = [ "f", "t"],
    VML_LINECAP_TABLE   = [ "flat", "round", "square" ],
    VML_LINEJOIN_TABLE  = [ "miter", "round", "bevel" ],
    VML_ELEMENT_TABLE   = [ " m ", " l ", "qb", " c ", " x ", [" at ", " wa "]];

var _CGBitmapGraphicsContextCreate = CGBitmapGraphicsContextCreate;

function CGBitmapGraphicsContextCreate()
{
    // The first time around, we have to set up our environment to support vml.
    document.namespaces.add("cg_vml_", "urn:schemas-microsoft-com:vml");
    document.createStyleSheet().cssText = "cg_vml_\\:*{behavior:url(#default#VML)}";

    CGBitmapGraphicsContextCreate = _CGBitmapGraphicsContextCreate;

    return _CGBitmapGraphicsContextCreate();
}

function CGContextSetFillColor(aContext, aColor)
{
    if ([aColor patternImage])
        // Prefix a marker character to the string so we know it's a pattern image filename
        aContext.gState.fillStyle = "!" + [[aColor patternImage] filename];
    else
        aContext.gState.fillStyle = [aColor cssString];
}

// FIXME: aRect is ignored.
function CGContextClearRect(aContext, aRect)
{
    if (aContext.buffer != nil)
        aContext.buffer = "";
    else
        aContext.DOMElement.innerHTML = "";

    aContext.path = NULL;
}

var W = 10.0,
    H = 10.0,
    Z = 10.0,
    Z_2 = Z / 2.0;

#define COORD(aCoordinate) (aCoordinate === 0.0 ? 0 : ROUND(Z * (aCoordinate) - Z_2))

function CGContextDrawImage(aContext, aRect, anImage)
{
    var string = "";

    if (anImage.buffer != nil)
        string = anImage.buffer;
    else
    {
        var ctm = aContext.gState.CTM,
            origin = CGPointApplyAffineTransform(aRect.origin, ctm),
            similarity = ctm.a == ctm.d && ctm.b == -ctm.c,
            vml = ["<cg_vml_:group coordsize=\"1,1\" coordorigin=\"0,0\" style=\"width:1;height:1;position:absolute"];

        /*if (similarity)
        {
            var angle = CGPointMake(1.0, 0.0);

            angle = CGPointApplyAffineTransform(angle, ctm);

            vml.push(";rotation:", ATAN2(angle.y - ctm.ty, angle.x - ctm.tx) * 180 / PI);
        }*/

        // Only create a filter if absolutely necessary.  This actually
        // turns out to only be the case if our transform matrix is not
        // a similarity matrix, that is to say, the transform actually
        // morphs the shape beyond scaling and rotation.
        //if (!similarity && (ctm.a != 1.0 || ctm.b || ctm.c || ctm.d != 1.0))
        {
            var transformedRect = CGRectApplyAffineTransform(aRect, ctm);

            vml.push(   ";padding:0 ", ROUND(CGRectGetMaxX(transformedRect)), "px ", ROUND(CGRectGetMaxY(transformedRect)),
                        "px 0;filter:progid:DXImageTransform.Microsoft.Matrix(",
                        "M11='", ctm.a, "',M12='", ctm.c, "',M21='", ctm.b, "',M22='", ctm.d, "',",
                        "Dx='", ROUND(origin.x), "', Dy='", ROUND(origin.y), "', sizingmethod='clip');");
        }
        //else
        //    vml.push(";top:", ROUND(origin.y - 0.5), "px;left:", ROUND(origin.x - 0.5), "px;");

        vml.push(   "\"><cg_vml_:image src=\"", anImage._image.src,
                    "\" style=\"width:", CGRectGetWidth(aRect), "px;height:", CGRectGetHeight(aRect),
                    "px;\"/></g_vml_:group>");

        string = vml.join("");
    }

    if (aContext.buffer != nil)
        aContext.buffer += string;
    else
        aContext.DOMElement.insertAdjacentHTML("BeforeEnd", string);
}

function CGContextDrawPath(aContext, aMode)
{
    if (!aContext || CGPathIsEmpty(aContext.path))
        return;

    var elements = aContext.path.elements,

        i = 0,
        count = aContext.path.count,

        gState = aContext.gState,
        fill = (aMode == kCGPathFill || aMode == kCGPathFillStroke) ? 1 : 0,
        stroke = (aMode == kCGPathStroke || aMode == kCGPathFillStroke) ? 1 : 0,
        opacity = gState.alpha,
        vml = ["<cg_vml_:shape"];

    if (gState.fillStyle.charAt(0) !== "!")
        vml.push(" fillcolor=\"", gState.fillStyle, "\"");

    vml.push(   " filled=\"", VML_TRUTH_TABLE[fill],
                "\" style=\"position:absolute;width:", W, ";height:", H,
                ";\" coordorigin=\"0 0\" coordsize=\"", Z * W, " ", Z * H,
                "\" stroked=\"", VML_TRUTH_TABLE[stroke],
                "\" strokeweight=\"", gState.lineWidth,
                "\" strokecolor=\"", gState.strokeStyle,
                "\" path=\"");

    for (; i < count; ++i)
    {
        var element = elements[i],
            type = element.type;

        switch (type)
        {
            case kCGPathElementMoveToPoint:
            case kCGPathElementAddLineToPoint:      vml.push(VML_ELEMENT_TABLE[type], COORD(element.x), ',', COORD(element.y));
                                                    break;

            case kCGPathElementAddQuadCurveToPoint: vml.push(VML_ELEMENT_TABLE[type],
                                                        COORD(element.cpx), ',', COORD(element.cpy), ',',
                                                        COORD(element.x), ',', COORD(element.y));
                                                    break;

            case kCGPathElementAddCurveToPoint:     vml.push(VML_ELEMENT_TABLE[type],
                                                        COORD(element.cp1x), ',', COORD(element.cp1y), ',',
                                                        COORD(element.cp2x), ',', COORD(element.cp2y), ',',
                                                        COORD(element.x), ',', COORD(element.y));
                                                    break;

            case kCGPathElementCloseSubpath:        vml.push(VML_ELEMENT_TABLE[type]);
                                                    break;

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
                                                        vml.push(VML_ELEMENT_TABLE[kCGPathElementMoveToPoint], COORD(start.x), ',', COORD(start.y));

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

                                                    vml.push(VML_ELEMENT_TABLE[type][clockwise],
                                                        COORD(x - radius), ',', COORD(y - radius), " ",
                                                        COORD(x + radius), ',', COORD(y + radius), " ",
                                                        COORD(start.x), ',', COORD(start.y), " ",
                                                        COORD(end.x), ',', COORD(end.y));
                                                    break;
            case kCGPathElementAddArcToPoint:       break;
        }

      // TODO: Following is broken for curves due to
      //       move to proper paths.

      // Figure out dimensions so we can do gradient fills
      // properly
      /*if(c) {
        if (min.x == null || c.x < min.x) {
          min.x = c.x;
        }
        if (max.x == null || c.x > max.x) {
          max.x = c.x;
        }
        if (min.y == null || c.y < min.y) {
          min.y = c.y;
        }
        if (max.y == null || c.y > max.y) {
          max.y = c.y;
        }
      }*/
    }

    vml.push("\">");

    if (gState.gradient)
        vml.push(gState.gradient)

    else if (fill)
    {
        if (gState.fillStyle.charAt(0) === "!")
            vml.push("<cg_vml_:fill type=\"tile\" src=\"", gState.fillStyle.substring(1), "\" opacity=\"", opacity, "\" />");
        else // should be a CSS color spec
            vml.push("<cg_vml_:fill color=\"", gState.fillStyle, "\" opacity=\"", opacity, "\" />");
    }

    if (stroke)
        vml.push(   "<cg_vml_:stroke opacity=\"", opacity,
                    "\" joinstyle=\"", VML_LINEJOIN_TABLE[gState.lineJoin],
                    "\" miterlimit=\"", gState.miterLimit,
                    "\" endcap=\"", VML_LINECAP_TABLE[gState.lineCap],
                    "\" weight=\"", gState.lineWidth, "",
                    "px\" color=\"", gState.strokeStyle,"\" />");

    var shadowColor = gState.shadowColor;
    //\"", [shadowColor cssString], "\"
    if (shadowColor)
    {
        var shadowOffset = gState.shadowOffset;

        vml.push("<cg_vml_:shadow on=\"t\" offset=\"",
            shadowOffset.width, "pt ", shadowOffset.height, "pt\" opacity=\"", [shadowColor alphaComponent], "\" color=black />");
    }

    vml.push("</cg_vml_:shape>");

    if (aContext.buffer != nil)
        aContext.buffer += vml.join("");
    else
        aContext.DOMElement.insertAdjacentHTML("BeforeEnd", vml.join(""));
}

function to_string(aColor)
{
    return "rgb(" + ROUND(aColor.components[0] * 255) + ", " + ROUND(aColor.components[1] * 255) + ", " + ROUND(255 * aColor.components[2]) + ")";
}

function CGContextDrawLinearGradient(aContext, aGradient, aStartPoint, anEndPoint, options)
{
    if (!aContext || !aGradient)
        return;

    var vml = nil;

    if (aGradient.vml_gradient)
    {
        var stops = [[aGradient.vml_gradient stops] sortedArrayUsingSelector:@selector(comparePosition:)],
            count = [stops count];

        vml = ["<cg_vml_:fill type=\"gradient\" method=\"linear sigma\" "];
        vml.push("angle=\"" + ([aGradient.vml_gradient angle] + 90) + "\" ");

        vml.push("colors=\"");

        for (var i = 0; i < count; i++)
        {
            vml.push(([stops[i] position] * 100).toFixed(0) + "% ");
            vml.push([[[stops[i] color] colorForSlideBase:nil] cssString]);

            if (i < count - 1)
                vml.push(",");
        }

        vml.push("\" />");
    }
    else
    {
        var colors = aGradient.colors,
            count = colors.length;

        vml = ["<cg_vml_:fill type=\"gradient\" "];

        vml.push("colors=\"");

        for (var i = 0; i < count; i++)
            vml.push((aGradient.locations[i] * 100).toFixed(0)+"% " + to_string(colors[i])+(i < count - 1 ? "," : ""));

        vml.push("\" />");
    }

    aContext.gState.gradient = vml.join("");

    // if (aContext.buffer != nil)
    //     aContext.buffer += vml.join("");
    // else
    //     aContext.DOMElement.innerHTML = vml.join("");
}
