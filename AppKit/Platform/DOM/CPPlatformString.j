/*
 * CPPlatformString.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2010, 280 North, Inc.
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

var DOMFixedWidthSpanElement    = nil,
    DOMFlexibleWidthSpanElement = nil,
    DOMMetricsDivElement        = nil,
    DOMMetricsImgElement        = nil,
    DefaultFont                 = nil;

@implementation CPPlatformString : CPBasePlatformString
{
}

+ (void)initialize
{
    if (self !== [CPPlatformString class])
        return;

    DefaultFont = [CPFont systemFontOfSize:CPFontCurrentSystemSize];
}

+ (void)bootstrap
{
    [self createDOMElements];
}

+ (void)createDOMElements
{
    var style,
        bodyElement = [CPPlatform mainBodyElement];

    DOMFlexibleWidthSpanElement = document.createElement("span");
    DOMFlexibleWidthSpanElement.className = "cpdontremove";
    style = DOMFlexibleWidthSpanElement.style;
    style.position = "absolute";
    style.left = "-100000px";
    style.zIndex = -100000;
    style.visibility = "visible";
    style.padding = "0px";
    style.margin = "0px";
    style.whiteSpace = "pre";

    DOMFixedWidthSpanElement = document.createElement("span");
    DOMFixedWidthSpanElement.className = "cpdontremove";
    style = DOMFixedWidthSpanElement.style;
    style.display = "block";
    style.position = "absolute";
    style.left = "-100000px";
    style.zIndex = -10000;
    style.visibility = "visible";
    style.padding = "0px";
    style.margin = "0px";
    style.width = "1px";
    style.wordWrap = "break-word";

    try
    {
        style.whiteSpace = "pre";
        style.whiteSpace = "-o-pre-wrap";
        style.whiteSpace = "-pre-wrap";
        style.whiteSpace = "-moz-pre-wrap";
        style.whiteSpace = "pre-wrap";
    }
    catch(e)
    {
        //some versions of IE throw exceptions for unsupported properties.
        style.whiteSpace = "pre";
    }

    bodyElement.appendChild(DOMFlexibleWidthSpanElement);
    bodyElement.appendChild(DOMFixedWidthSpanElement);
}

+ (void)createDOMMetricsElements
{
    var style,
        bodyElement = [CPPlatform mainBodyElement];

    DOMMetricsDivElement = document.createElement("div");
    DOMMetricsDivElement.className = "cpdontremove";
    style = DOMMetricsDivElement.style;
    style.position = "absolute";
    style.left = "-10000px";
    style.zIndex = -10000;
    style.width = "100000px";
    style.whiteSpace = "nowrap";
    style.lineHeight = "1em";
    style.padding = "0px";
    style.margin = "0px";
    DOMMetricsDivElement.innerHTML = "x";

    bodyElement.appendChild(DOMMetricsDivElement);

    var imgPath = [[CPBundle bundleForClass:[CPView class]] pathForResource:@"empty.png"];

    DOMMetricsImgElement = document.createElement("img");
    DOMMetricsImgElement.className = "cpdontremove";
    DOMMetricsImgElement.setAttribute("src", imgPath);
    DOMMetricsImgElement.setAttribute("width", "1");
    DOMMetricsImgElement.setAttribute("height", "1");
    DOMMetricsImgElement.setAttribute("alt", "");
    style = DOMMetricsImgElement.style;
    style.zIndex = -10000;
    style.visibility = "visible";
    style.padding = "0px";
    style.margin = "0px";
    style.border = "none";
    style.verticalAlign = "baseline";

    DOMMetricsDivElement.appendChild(DOMMetricsImgElement);
}

+ (CGSize)sizeOfString:(CPString)aString withFont:(CPFont)aFont forWidth:(float)aWidth
{
    if (!DOMFixedWidthSpanElement)
        [self createDOMElements];

    var span;

    if (!aWidth)
        span = DOMFlexibleWidthSpanElement;
    else
    {
        span = DOMFixedWidthSpanElement;
        span.style.width = ROUND(aWidth) + "px";
    }

    span.style.font = [(aFont || DefaultFont) cssString];

    if (CPFeatureIsCompatible(CPJavaScriptInnerTextFeature))
        span.innerText = aString;
    else if (CPFeatureIsCompatible(CPJavaScriptTextContentFeature))
        span.textContent = aString;

    return CGSizeMake(span.clientWidth, span.clientHeight);
}

+ (CPDictionary)metricsOfFont:(CPFont)aFont
{
    if (!DOMMetricsDivElement)
        [self createDOMMetricsElements];

    DOMMetricsDivElement.style.font = [(aFont || DefaultFont) cssString];

    var lineHeight = DOMMetricsDivElement.offsetHeight,
        baseline = DOMMetricsImgElement.offsetTop + DOMMetricsImgElement.offsetHeight,
        descender = baseline - lineHeight;

    return @{
            @"ascender": baseline,
            @"descender": descender,
            @"lineHeight": lineHeight,
        };
}

@end
