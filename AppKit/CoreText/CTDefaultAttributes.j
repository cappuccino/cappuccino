/*
 * CTDefaultAttributes.j
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

@import "CTFont.j"
@import "CTParagraphStyle.j"

kCTCharacterShapeAttributeName              = "CTCharacterShapeAttributeName";
kCTFontAttributeName                        = "CTFontAttributeName";
kCTKernAttributeName                        = "CTKernAttributeName";
kCTLigatureAttributeName                    = "CTLigatureAttributeName";
kCTForegroundColorAttributeName             = "CTForegroundColorAttributeName";
kCTForegroundColorFromContextAttributeName  = "CTForegroundColorFromContextAttributeName";
kCTParagraphStyleAttributeName              = "CTParagraphStyleAttributeName";
kCTStrokeWidthAttributeName                 = "CTStrokeWidthAttributeName";
kCTStrokeColorAttributeName                 = "CTStrokeColorAttributeName";
kCTSuperscriptAttributeName                 = "CTSuperscriptAttributeName";
kCTUnderlineColorAttributeName              = "CTUnderlineColorAttributeName";
kCTUnderlineStyleAttributeName              = "CTUnderlineStyleAttributeName";
kCTVerticalFormsAttributeName               = "CTVerticalFormsAttributeName";
kCTGlyphInfoAttributeName                   = "CTGlyphInfoAttributeName";
kCTRunDelegateAttributeName                 = "CTRunDelegateAttributeName"; 

@typedef CTUnderlineStyle

kCTUnderlineStyleNone                       = 0x00;
kCTUnderlineStyleSingle                     = 0x01;
kCTUnderlineStyleThick                      = 0x02;
kCTUnderlineStyleDouble                     = 0x09; 

@typedef CTUnderlineStyleModifiers

kCTUnderlinePatternSolid                    = 0x0000;
kCTUnderlinePatternDot                      = 0x0100;
kCTUnderlinePatternDash                     = 0x0200;
kCTUnderlinePatternDashDot                  = 0x0300;
kCTUnderlinePatternDashDotDot               = 0x0400;

var CTDefaultTextAttributes = nil;

function CTGetDefaultAttributes()
{
    if (CTDefaultTextAttributes === nil)
    {
        CTDefaultTextAttributes = [[CPDictionary alloc] init];
        [CTDefaultTextAttributes setValue: CTFontCreateWithFontName("Arial", 12, nil) forKey: kCTFontAttributeName];
        [CTDefaultTextAttributes setValue: [CPColor blackColor] forKey: kCTForegroundColorAttributeName];
        [CTDefaultTextAttributes setValue: [CPColor blackColor] forKey: kCTStrokeColorAttributeName];
        [CTDefaultTextAttributes setValue: [CPNumber numberWithFloat: 2] forKey: kCTStrokeWidthAttributeName];
        [CTDefaultTextAttributes setValue: CTDefaultParagraphStyle() forKey: kCTParagraphStyleAttributeName];
    }
    return CTDefaultTextAttributes;
}
