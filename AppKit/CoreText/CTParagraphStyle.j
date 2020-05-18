/*
 * CTParagraphStyle.j
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

@typedef CTTextAlignment

kCTLeftTextAlignment        = 0;
kCTRightTextAlignment       = 1;
kCTCenterTextAlignment      = 2;
kCTJustifiedTextAlignment   = 3;
kCTNaturalTextAlignment     = 4;

kCTLineBreakByWordWrapping      = 0;
kCTLineBreakByCharWrapping      = 1;
kCTLineBreakByClipping          = 2;
kCTLineBreakByTruncatingHead    = 3;
kCTLineBreakByTruncatingTail    = 4;
kCTLineBreakByTruncatingMiddle  = 5;

kCTWritingDirectionNatural      = -1;
kCTWritingDirectionLeftToRight  = 0;
kCTWritingDirectionRightToLeft  = 1;

kCTParagraphStyleSpecifierAlignment              = "alignment";
kCTParagraphStyleSpecifierFirstLineHeadIndent    = "firstLineHeadIndent";
kCTParagraphStyleSpecifierHeadIndent             = "headIndent";
kCTParagraphStyleSpecifierTailIndent             = "tailIndent";
kCTParagraphStyleSpecifierTabStops               = "tabStops";
kCTParagraphStyleSpecifierDefaultTabInterval     = "defaultTabInterval";
kCTParagraphStyleSpecifierLineBreakMode          = "lineBreakMode";
kCTParagraphStyleSpecifierLineHeightMultiple     = "lineHeightMultiple";
kCTParagraphStyleSpecifierMaximumLineHeight      = "maximumLineHeight";
kCTParagraphStyleSpecifierMinimumLineHeight      = "minimumLineHeight";
kCTParagraphStyleSpecifierLineSpacing            = "lineSpacing";
kCTParagraphStyleSpecifierParagraphSpacing       = "paragraphSpacing";
kCTParagraphStyleSpecifierParagraphSpacingBefore = "paragraphSpacingBefore";
kCTParagraphStyleSpecifierBaseWritingDirection   = "baseWritingDirection";
kCTParagraphStyleSpecifierMaximumLineSpacing     = "maximumLineSpacing";
kCTParagraphStyleSpecifierMinimumLineSpacing     = "minimumLineSpacing";
kCTParagraphStyleSpecifierLineSpacingAdjustment  = "lineSpacingAdjustment";

CTDefaultParagraphStyleDictionary = nil;

@typedef CTParagraphStyle

function CTDefaultParagraphStyle()
{
    if (CTDefaultParagraphStyleDictionary == nil)
    {
        CTDefaultParagraphStyleDictionary = [CPDictionary dictionaryWithObjectsAndKeys:

                                        [CPNumber numberWithInt: kCTNaturalTextAlignment],
                                         kCTParagraphStyleSpecifierAlignment,
                                         
                                        [CPNumber numberWithInt: 0],
                                         kCTParagraphStyleSpecifierFirstLineHeadIndent,

                                        [CPNumber numberWithInt: 0],
                                         kCTParagraphStyleSpecifierHeadIndent,

                                        [CPNumber numberWithInt: 0],
                                         kCTParagraphStyleSpecifierTailIndent,

                                        [[CPArray alloc] init],
                                         kCTParagraphStyleSpecifierTabStops,

                                        [CPNumber numberWithInt: 0],
                                         kCTParagraphStyleSpecifierDefaultTabInterval,

                                        [CPNumber numberWithInt: kCTLineBreakByWordWrapping],
                                         kCTParagraphStyleSpecifierLineBreakMode,

                                        [CPNumber numberWithInt: 0],
                                         kCTParagraphStyleSpecifierLineHeightMultiple,

                                        [CPNumber numberWithInt: 0],
                                         kCTParagraphStyleSpecifierMaximumLineHeight,

                                        [CPNumber numberWithInt: 0],
                                         kCTParagraphStyleSpecifierMinimumLineHeight,

                                        [CPNumber numberWithInt: 0],
                                         kCTParagraphStyleSpecifierLineSpacing,
 
                                        [CPNumber numberWithInt: 0],
                                         kCTParagraphStyleSpecifierParagraphSpacing,
 
                                        [CPNumber numberWithInt: 0],
                                         kCTParagraphStyleSpecifierParagraphSpacingBefore,
 
                                        [CPNumber numberWithInt: kCTWritingDirectionLeftToRight],
                                         kCTParagraphStyleSpecifierBaseWritingDirection,
 
                                        [CPNumber numberWithInt: 0],
                                         kCTParagraphStyleSpecifierMaximumLineSpacing,
 
                                        [CPNumber numberWithInt: 0],
                                         kCTParagraphStyleSpecifierMinimumLineSpacing,
 
                                        [CPNumber numberWithInt: 0],
                                         kCTParagraphStyleSpecifierLineSpacingAdjustment
                                        ];
    }
    return CTDefaultParagraphStyleDictionary;
}

function CTParagraphStyleCreate(settings, count)
{
    return [CPDictionary dictionaryWithDictionary: settings];
}

function CTParagraphStyleCreateCopy(aParagraphStyle)
{
    return [CPDictionary dictionaryWithDictinary: aParagraphStyle];
}

function CTParagraphStyleGetValueForSpecifier(aParagraphStyle, aSpecifier)
{
    return [aParagraphStyle objectForKey: aSpecifier];
}
