/*
 * CPStringDrawing.j
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

@import <Foundation/CPString.j>

@import "CGGeometry.j"
@import "CPPlatformString.j"
@import "CPFont.j"
@import "CPCompatibility.j"


var CPStringSizeWithFontInWidthCache = [],
    CPStringSizeWithFontHeightCache = [],
    CPStringSizeMeasuringContext,
    CPStringSizeIsCanvasSizingInvalid,
    CPStringSizeDidTestCanvasSizingValid;

CPStringSizeCachingEnabled = YES;

@implementation CPString (CPStringDrawing)

/*!
    Returns a dictionary with the items "ascender", "descender", "lineHeight"
*/
+ (CPDictionary)metricsOfFont:(CPFont)aFont
{
    return [CPPlatformString metricsOfFont:aFont];
}

/*!
    Returns the string
*/
- (CPString)cssString
{
    return self;
}

- (CGSize)sizeWithFont:(CPFont)aFont
{
    return [self sizeWithFont:aFont inWidth:NULL];
}

- (void) _initializeStringSizing
{
#if PLATFORM(DOM)
    CPStringSizeIsCanvasSizingInvalid = YES;

    if (CPFeatureIsCompatible(CPHTMLCanvasFeature))
    {
        var aFont = [CPFont systemFontOfSize:12.0];

        if (!CPStringSizeMeasuringContext)
            CPStringSizeMeasuringContext = CGBitmapGraphicsContextCreate();

        CPStringSizeMeasuringContext.font = [aFont cssString];
        var teststring = "0123456879abcdefghiklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ,.-()";
        CPStringSizeIsCanvasSizingInvalid = ABS([CPPlatformString sizeOfString:teststring withFont:aFont forWidth:0].width - CPStringSizeMeasuringContext.measureText(teststring).width) > 2;
    }
#endif
}

- (CGSize)sizeWithFont:(CPFont)aFont inWidth:(float)aWidth
{
    var size;

#if PLATFORM(DOM)
    if (!CPStringSizeCachingEnabled)
        return [CPPlatformString sizeOfString:self withFont:aFont forWidth:aWidth];

    var sizeCacheForFont = CPStringSizeWithFontInWidthCache[self];

    if (sizeCacheForFont === undefined)
        sizeCacheForFont = CPStringSizeWithFontInWidthCache[self] = [];

    var cssString = [aFont cssString],
        cacheKey = cssString + '_' + aWidth;

    size = sizeCacheForFont[cacheKey];

    if (size !== undefined && sizeCacheForFont.hasOwnProperty(cacheKey))
        return CGSizeMakeCopy(size);

    if (CPStringSizeDidTestCanvasSizingValid  === undefined)
    {
        [self _initializeStringSizing];
        CPStringSizeDidTestCanvasSizingValid = YES;
    }

    if (CPStringSizeIsCanvasSizingInvalid || aWidth > 0)
        size = [CPPlatformString sizeOfString:self withFont:aFont forWidth:aWidth];
    else
    {
        if (CPStringSizeMeasuringContext.font !== cssString)
            CPStringSizeMeasuringContext.font = cssString;

        var fontHeight = CPStringSizeWithFontHeightCache[cssString];

        if (fontHeight === undefined)
            fontHeight = CPStringSizeWithFontHeightCache[cssString] = [aFont defaultLineHeightForFont];

        size = CGSizeMake(CPStringSizeMeasuringContext.measureText(self).width, fontHeight);
    }

    sizeCacheForFont[cacheKey] = size;
#else
        size = CGSizeMake(0, 0);
#endif
    return CGSizeMakeCopy(size);
}

@end
