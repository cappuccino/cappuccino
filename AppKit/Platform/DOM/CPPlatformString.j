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
    DOMMetricsTextSpanElement   = nil,
    DOMMetricsImgElement        = nil,
    DOMIFrameElement            = nil,
    DOMIFrameDocument           = nil,
    DefaultFont                 = nil;

@implementation CPPlatformString : CPBasePlatformString
{
}

+ (void)bootstrap
{
    [self createDOMElements];
}

+ (void)createDOMElements
{
    var style;

    DOMIFrameElement = document.createElement("iframe");
    // necessary for Safari caching bug:
    DOMIFrameElement.name = "iframe_" + FLOOR(RAND() * 10000);
    DOMIFrameElement.className = "cpdontremove";

    style = DOMIFrameElement.style;
    style.position = "absolute";
    style.left = "-100px";
    style.top = "-100px";
    style.width = "1px";
    style.height = "1px";
    style.borderWidth = "0px";
    style.overflow = "hidden";
    style.zIndex = 100000000000;

    var bodyElement = [CPPlatform mainBodyElement];

    bodyElement.appendChild(DOMIFrameElement);

    DOMIFrameDocument = (DOMIFrameElement.contentDocument || DOMIFrameElement.contentWindow.document);
    DOMIFrameDocument.write('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'+
                            '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"><head></head><body></body></html>');
    DOMIFrameDocument.close();

    // IE needs this wide <div> to prevent unwanted text wrapping:
    var DOMDivElement = DOMIFrameDocument.createElement("div");
    DOMDivElement.style.position = "absolute";
    DOMDivElement.style.width = "100000px";

    DOMIFrameDocument.body.appendChild(DOMDivElement);

    DOMFlexibleWidthSpanElement = DOMIFrameDocument.createElement("span");
    style = DOMFlexibleWidthSpanElement.style;
    style.position = "absolute";
    style.visibility = "visible";
    style.padding = "0px";
    style.margin = "0px";
    style.whiteSpace = "pre";

    DOMFixedWidthSpanElement = DOMIFrameDocument.createElement("span");
    style = DOMFixedWidthSpanElement.style;
    style.display = "block";
    style.position = "absolute";
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

    DOMDivElement.appendChild(DOMFlexibleWidthSpanElement);
    DOMDivElement.appendChild(DOMFixedWidthSpanElement);
}

+ (void)createDOMMetricsElements
{
    if (!DOMIFrameElement)
        [self createDOMElements];

    var style;

    DOMMetricsDivElement = DOMIFrameDocument.createElement("div");
    DOMMetricsDivElement.style.position = "absolute";
    DOMMetricsDivElement.style.width = "100000px";

    DOMIFrameDocument.body.appendChild(DOMMetricsDivElement);

    DOMMetricsTextSpanElement = DOMIFrameDocument.createElement("span");
    DOMMetricsTextSpanElement.innerHTML = "x";
    style = DOMMetricsTextSpanElement.style;
    style.position = "absolute";
    style.visibility = "visible";
    style.padding = "0px";
    style.margin = "0px";
    style.whiteSpace = "pre";

    var imgPath = [[CPBundle bundleForClass:[CPView class]] pathForResource:@"empty.png"];

    DOMMetricsImgElement = DOMIFrameDocument.createElement("img");
    DOMMetricsImgElement.setAttribute("src", imgPath);
    DOMMetricsImgElement.setAttribute("width", "1");
    DOMMetricsImgElement.setAttribute("height", "1");
    DOMMetricsImgElement.setAttribute("alt", "");
    style = DOMMetricsImgElement.style;
    style.visibility = "visible";
    style.padding = "0px";
    style.margin = "0px";
    style.border = "none";
    style.verticalAlign = "baseline";

    DOMMetricsDivElement.appendChild(DOMMetricsTextSpanElement);
    DOMMetricsDivElement.appendChild(DOMMetricsImgElement);
}

+ (CGSize)sizeOfString:(CPString)aString withFont:(CPFont)aFont forWidth:(float)aWidth
{
    if (!aFont)
    {
        if (!DefaultFont)
            DefaultFont = [CPFont systemFontOfSize:12.0];

        aFont = DefaultFont;
    }

    if (!DOMIFrameElement)
        [self createDOMElements];

    var span;

    if (!aWidth)
        span = DOMFlexibleWidthSpanElement;
    else
    {
        span = DOMFixedWidthSpanElement;
        span.style.width = ROUND(aWidth) + "px";
    }

    span.style.font = [aFont cssString];

    if (CPFeatureIsCompatible(CPJavascriptInnerTextFeature))
        span.innerText = aString;
    else if (CPFeatureIsCompatible(CPJavascriptTextContentFeature))
        span.textContent = aString;

    return _CGSizeMake(span.clientWidth, span.clientHeight);
}

+ (CPDictionary)metricsOfFont:(CPFont)aFont
{
    if (!aFont)
    {
        if (!DefaultFont)
            DefaultFont = [CPFont systemFontOfSize:12.0];

        aFont = DefaultFont;
    }

    if (!DOMMetricsDivElement)
        [self createDOMMetricsElements];

    DOMMetricsDivElement.style.font = [aFont cssString];

    var baseline = DOMMetricsImgElement.offsetTop - DOMMetricsTextSpanElement.offsetTop + DOMMetricsImgElement.offsetHeight,
        descender = baseline - DOMMetricsTextSpanElement.offsetHeight,
        lineHeight = DOMMetricsTextSpanElement.offsetHeight;

    return [CPDictionary dictionaryWithObjectsAndKeys:baseline, @"ascender", descender, @"descender", lineHeight, @"lineHeight"];
}

@end
