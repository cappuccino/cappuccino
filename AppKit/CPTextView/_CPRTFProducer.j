/*
 *  _CPRTFProducer.j
 *
 *  Serialize CPAttributedString to a RTF String
 *
 *  Copyright (C) 2014 Daniel Boehringer
 *  This file is based on the RTFProducer from GNUStep
 *  (which I co-authored with Fred Kiefer in 1999)
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

@import <Foundation/CPAttributedString.j>
@import "CPParagraphStyle.j"
@import "CPColor.j"
@import "CPGraphics.j"
@import "CPFontManager.j"
@import "_CPTableTextAttachment.j"

@global CPForegroundColorAttributeName
@global CPBackgroundColorAttributeName
@global CPUnderlineStyleAttributeName
@global CPSuperscriptAttributeName
@global CPBaselineOffsetAttributeName
@global CPAttachmentAttributeName
@global CPLigatureAttributeName
@global CPKernAttributeName

@global CPLeftTextAlignment
@global CPRightTextAlignment
@global CPCenterTextAlignment
@global CPJustifiedTextAlignment
@global CPNaturalTextAlignment

@global CPLeftTabStopType
@global CPRightTabStopType
@global CPCenterTabStopType
@global CPDecimalTabStopType

var PAPERSIZE = @"PaperSize",
    LEFTMARGIN = @"LeftMargin",
    RIGHTMARGIN = @"RightMargin",
    TOPMARGIN = @"TopMargin",
    BUTTOMMARGIN = @"ButtomMargin";

function _points2twips(a) { return (a) * 20.0; }

@implementation _CPRTFProducer : CPObject
{
    CPAttributedString  text;
    CPMutableDictionary fontDict;
    CPMutableDictionary colorDict;
    CPDictionary        docDict;
    CPMutableArray      attachments;
    CPFont              currentFont;
    CPColor             fgColor;
    CPColor             bgColor;
    CPColor             ulColor;
}

#pragma mark -
#pragma mark Class methods


+ (CPString)produceRTF:(CPAttributedString)aText documentAttributes:(CPDictionary)dict
{
    var mynew = [self new];

    return [mynew RTFDStringFromAttributedString:aText documentAttributes:dict];
}


#pragma mark -
#pragma mark init methods

- (id)init
{
    if (self = [super init])
    {
        // maintain a dictionary for the used colours
        // (for rtf-header generation)
        colorDict = [CPMutableDictionary new];

        //maintain a dictionary for the used fonts
        //(for rtf-header generation)
        fontDict = [CPMutableDictionary new];

        fgColor = [CPColor blackColor];
        bgColor= [CPColor whiteColor];
    }

    return self;
}

// private stuff follows
- (CPString)fontTable
{
    if (![fontDict count])
        return @"";

    var fontlistString = "",
        fontEnum,
        currFont,
        keyArray;

    keyArray = [fontDict allKeys];
    keyArray = [keyArray sortedArrayUsingSelector:@selector(compare:)];
    fontEnum = [keyArray objectEnumerator];

    while ((currFont = [fontEnum nextObject]) != nil)
    {
        var fontFamily,
            detail;

        if ([currFont isEqualToString:@"Symbol"])
            fontFamily = @"tech";
        else if ([currFont isEqualToString:@"Helvetica"])
            fontFamily = @"swiss";
        else if ([currFont isEqualToString:@"Arial"])
            fontFamily = @"swiss";
        else if ([currFont isEqualToString:@"Courier"])
            fontFamily = @"modern";
        else if ([currFont isEqualToString:@"Times"])
            fontFamily = @"roman";
        else fontFamily = @"nil";

        detail = [CPString stringWithFormat:@"%@\\f%@ %@;", [fontDict objectForKey:currFont], fontFamily, currFont];
        fontlistString += detail;
    }

    return [CPString stringWithFormat:@"{\\fonttbl%@}\n", fontlistString];
}

- (CPString)colorTable
{
    if (![colorDict count])
        return @"";

    var result,
        count = [colorDict count],
        list = [CPMutableArray arrayWithCapacity:count],
        keyEnum = [colorDict keyEnumerator],
        next,
        i;

    while ((next = [keyEnum nextObject]) != nil)
    {
        var cn = [colorDict objectForKey:next];
        [list insertObject:[CPColor colorWithCSSString:next] atIndex:[cn intValue]-1];
    }

    result = [CPString stringWithString:@"{\\colortbl;"];

    for (i = 0; i < count; i++)
    {
        var color = [[list objectAtIndex:i]
                           colorUsingColorSpaceName:CPCalibratedRGBColorSpace];

        result += [CPString stringWithFormat:@"\\red%d\\green%d\\blue%d;",
                                             ([color redComponent] * 255),
                                             ([color greenComponent] * 255),
                                             ([color blueComponent] * 255)];
    }

    result += @"}\n";

    return result;
}

- (CPString)documentAttributes
{
    if (!docDict)
        return @"";

    var result,
        detail,
        val,
        num;

    result = [CPString string];

    val = [docDict objectForKey:PAPERSIZE];

    if (val)
    {
        detail = [CPString stringWithFormat:@"\\paperw%d \\paperh%d",
                         _points2twips(val.width),
                         _points2twips(val.height)];

        result += detail;
    }

    num = [docDict objectForKey:LEFTMARGIN];

    if (num)
    {
        var f = [num floatValue];

        detail = [CPString stringWithFormat:@"\\margl%d", _points2twips(f)];
        result += detail;
    }

    num = [docDict objectForKey:RIGHTMARGIN];

    if (num)
    {
        var f = [num floatValue];

        detail = [CPString stringWithFormat:@"\\margr%d", _points2twips(f)];
        result += detail;
    }

    num = [docDict objectForKey:TOPMARGIN];

    if (num)
    {
        var f = [num floatValue];

        detail = [CPString stringWithFormat:@"\\margt%d", _points2twips(f)];
        result += detail;
    }

    num = [docDict objectForKey:BUTTOMMARGIN];

    if (num)
    {
        var f = [num floatValue];

        detail = [CPString stringWithFormat:@"\\margb%d", _points2twips(f)];
        result += detail;
    }

    return result;
}

- (CPString)headerString
{
    var result;

    result = [CPString stringWithString:@"{\\rtf1\\ansi"];
    result += [self fontTable];
    result += [self colorTable];
    result += [self documentAttributes];

    return result;
}

- (CPString)trailerString
{
    return @"}";
}

- (CPString)fontToken:(CPString) fontName
{
    var fCount = [fontDict objectForKey:fontName];

    if (fCount == nil)
    {
        var count = [fontDict count];

        fCount = [CPString stringWithFormat:@"\\f%d", count];
        [fontDict setObject:fCount forKey:fontName];
    }

    return fCount;
}

- (int)numberForColor:(CPColor)color
{
    var num = [colorDict objectForKey:[color cssString]];

    if (!num)
        [colorDict setObject:num = [CPNumber numberWithInt:[colorDict count] + 1]
		              forKey:[color cssString]];

    return [num intValue];
}

- (CPString)paragraphStyle:(CPParagraphStyle)paraStyle
{
    var headerString = [CPString stringWithString:@"\\pard"],
        twips;

    if (paraStyle == nil)
        return headerString;

    switch ([paraStyle alignment])
    {
        case CPRightTextAlignment:
            headerString += @"\\qr";
            break;

        case CPCenterTextAlignment:
            headerString += @"\\qc";
            break;

        case CPLeftTextAlignment:
            headerString += @"\\ql";
            break;

        case CPJustifiedTextAlignment:
            headerString += @"\\qj";
            break;

        default:
            headerString += @"\\ql";
            break;
    }

    // write first line indent and left indent
    var twips = _points2twips([paraStyle firstLineHeadIndent]);

    if (twips != 0.0)
        headerString += [CPString stringWithFormat:@"\\fi%d", twips];

    twips = _points2twips([paraStyle headIndent]);

    if (twips != 0.0)
        headerString += [CPString stringWithFormat:@"\\li%d", twips];

    twips = _points2twips([paraStyle tailIndent]);

    if (twips != 0.0)
        headerString += [CPString stringWithFormat:@"\\ri%d", twips];

    twips = _points2twips([paraStyle paragraphSpacing]);

    if (twips != 0.0)
        headerString += [CPString stringWithFormat:@"\\sa%d", twips];

    twips = _points2twips([paraStyle minimumLineHeight]);

    if (twips != 0.0)
        headerString += [CPString stringWithFormat:@"\\sl%d", twips];

    twips = _points2twips([paraStyle maximumLineHeight]);

    if (twips != 0.0)
        headerString += [CPString stringWithFormat:@"\\sl-%d", twips];

    var enumerator,
        tab;

    enumerator = [[paraStyle tabStops] objectEnumerator];

    while ((tab = [enumerator nextObject]))
    {
        var tabType = [tab respondsToSelector:@selector(tabStopType)] ? [tab tabStopType] : nil;
        if (tabType === nil && [tab respondsToSelector:@selector(alignment)])
            tabType = [tab alignment];

        switch (tabType)
        {
            case CPLeftTabStopType:
            case CPLeftTextAlignment:
                break;
            case CPRightTabStopType:
            case CPRightTextAlignment:
                headerString += @"\\tqr";
                break;
            case CPCenterTabStopType:
            case CPCenterTextAlignment:
                headerString += @"\\tqc";
                break;
            case CPDecimalTabStopType:
                headerString += @"\\tqdec";
                break;
        }

        headerString += [CPString stringWithFormat:@"\\tx%d",_points2twips([tab location])];
    }

    return headerString;
}

- (CPString)runStringForString:(CPString) substring
                    attributes:(CPDictionary) attributes
                paragraphStart:(BOOL) first
{
    var unwrap = function(obj) {
        if (!obj) return null;

        // If the object contains the table structures, bypass unwrapping
        if ((typeof obj.respondsToSelector === "function" && ([obj respondsToSelector:@selector(headers)] || [obj respondsToSelector:@selector(rows)])) ||
            obj.headers || obj._headers || obj.rows || obj._rows) {
            return obj;
        }

        var unwrapped = null;
        if (typeof obj.respondsToSelector === "function") {
            if ([obj respondsToSelector:@selector(attachmentCell)]) {
                unwrapped = [obj attachmentCell];
            } else if ([obj respondsToSelector:@selector(content)]) {
                unwrapped = [obj content];
            } else if ([obj respondsToSelector:@selector(view)]) {
                unwrapped = [obj view];
            }
        }
        if (!unwrapped) {
            unwrapped = obj._attachmentCell || obj._content || obj._view || obj.attachmentCell || obj.content || obj.view;
        }
        return unwrapped ? unwrapped : obj;
    };

    var tableAttachment = null;
    
    if (typeof CPAttachmentAttributeName !== "undefined") {
        tableAttachment = [attributes objectForKey:CPAttachmentAttributeName];
    }
    if (!tableAttachment) {
        tableAttachment = [attributes objectForKey:@"CPAttachmentAttributeName"];
    }
    if (!tableAttachment) {
        tableAttachment = [attributes objectForKey:@"TableAttachmentAttribute"];
    }
    if (!tableAttachment) {
        tableAttachment = [attributes objectForKey:@"_CPAttachmentView"];
    }
    if (!tableAttachment && typeof _CPAttachmentView !== "undefined") {
        tableAttachment = [attributes objectForKey:_CPAttachmentView];
    }

    tableAttachment = unwrap(tableAttachment);

    // Ultimate fallback scanner for layout character placeholder sequences
    if (!tableAttachment && (substring === "\uFFFC" || substring === "￼"))
    {
        var keys = [attributes allKeys],
            count = [keys count];

        for (var i = 0; i < count; i++)
        {
            var key = [keys objectAtIndex:i],
                val = unwrap([attributes objectForKey:key]);

            if (val && (
                (typeof val.respondsToSelector === "function" && [val respondsToSelector:@selector(headers)]) || 
                val._headers || 
                val.headers ||
                (typeof _CPTableTextAttachment !== "undefined" && [val isKindOfClass:[_CPTableTextAttachment class]])
            )) {
                tableAttachment = val;
                break;
            }
        }
    }

    if (tableAttachment)
    {
        var headers = null,
            rows = null;

        if (typeof tableAttachment.respondsToSelector === "function") {
            if ([tableAttachment respondsToSelector:@selector(headers)]) {
                headers = [tableAttachment headers];
            }
            if ([tableAttachment respondsToSelector:@selector(rows)]) {
                rows = [tableAttachment rows];
            }
        }
        
        if (!headers) {
            headers = tableAttachment._headers || tableAttachment.headers;
        }
        if (!rows) {
            rows = tableAttachment._rows || tableAttachment.rows;
        }

        var getCount = function(arr) {
            if (!arr) return 0;
            if (typeof arr.count === "function") return [arr count];
            return arr.length;
        };

        var getObjectAtIndex = function(arr, idx) {
            if (!arr) return null;
            if (typeof arr.objectAtIndex === "function") return [arr objectAtIndex:idx];
            return arr[idx];
        };

        var numCols = getCount(headers);
        if (numCols == 0 && getCount(rows) > 0) {
            numCols = getCount(getObjectAtIndex(rows, 0));
        }

        if (numCols > 0)
        {
            var totalWidthTwips = 10000;
            var colWidthTwips = Math.floor(totalWidthTwips / numCols);
            var cellBoundaries = [];
            var currentBoundary = 0;
            for (var i = 0; i < numCols; i++)
            {
                currentBoundary += colWidthTwips;
                cellBoundaries.push(currentBoundary);
            }

            var tableRTF = "";
            var writeRow = function(rowData, isHeaderRow) {
                var rowRTF = "\\trowd\\trgaph115\\trleft0";
                for (var c = 0; c < numCols; c++) {
                    rowRTF += "\\clbrdrt\\brdrs\\brdrw10\\clbrdrb\\brdrs\\brdrw10\\clbrdrl\\brdrs\\brdrw10\\clbrdrr\\brdrs\\brdrw10";
                    rowRTF += "\\cellx" + cellBoundaries[c];
                }
                for (var c = 0; c < numCols; c++) {
                    var cellText = "";
                    if (c < getCount(rowData)) {
                        cellText = getObjectAtIndex(rowData, c);
                    }
                    if (cellText === null || cellText === undefined) {
                        cellText = "";
                    }
                    
                    cellText = String(cellText);
                    cellText = cellText.replace(/\\/g, '\\\\');
                    cellText = cellText.replace(/{/g, '\\{');
                    cellText = cellText.replace(/}/g, '\\}');
                    cellText = cellText.replace(/\n/g, '\\line ');

                    if (isHeaderRow) {
                        rowRTF += "{\\intbl\\b " + cellText + "\\b0\\cell}";
                    } else {
                        rowRTF += "{\\intbl " + cellText + "\\cell}";
                    }
                }
                rowRTF += "\\row\n";
                return rowRTF;
            };

            if (getCount(headers) > 0) {
                tableRTF += writeRow(headers, YES);
            }
            var rowCount = getCount(rows);
            for (var r = 0; r < rowCount; r++) {
                tableRTF += writeRow(getObjectAtIndex(rows, r), NO);
            }

            return tableRTF;
        }
    }

    var result = "",
        headerString = "",
        trailerString = "",
        attribEnum,
        currAttrib;

    if (first)
    {
        var paraStyle = [attributes objectForKey:CPParagraphStyleAttributeName];
        headerString += [self paragraphStyle:paraStyle];
    }

  /*
   * analyze attributes of current run
   *
   * FIXME: All the character attributes should be output relative to the font
   * attributes of the paragraph. So if the paragraph has underline on it should
   * still be possible to switch it off for some characters, which currently is
   * not possible.
   */
    attribEnum = [attributes keyEnumerator];

    while ((currAttrib = [attribEnum nextObject]) != nil)
    {
        if ([currAttrib isEqualToString:CPFontAttributeName])
        {
          /*
           * handle fonts
           */
            var font,
                fontName,
                traits;

            font = [attributes objectForKey:CPFontAttributeName];
            fontName = [font familyName];
            traits = [[CPFontManager sharedFontManager] traitsOfFont:font];

          /*
           * font name
           */
            if (currentFont == nil || ![fontName isEqualToString:[currentFont familyName]])
                headerString += [self fontToken:fontName];

          /*
           * font size
           */
            if (currentFont == nil || [font size] != [currentFont size])
            {
                var points = [font size] * 2,
                    pString;

                pString = [CPString stringWithFormat:@"\\fs%d", points];
                headerString += pString;
            }
          /*
           * font attributes
           */
            if (traits & CPItalicFontMask)
            {
                headerString += @"\\i";
                trailerString += @"\\i0";
            }

            if (traits & CPBoldFontMask)
            {
                headerString += @"\\b";
                trailerString += @"\\b0";
            }

            if (first)
                currentFont = font;
        }
        else if ([currAttrib isEqualToString:CPForegroundColorAttributeName])
        {
            var color = [attributes objectForKey:CPForegroundColorAttributeName];

            if (![color isEqual:fgColor])
            {
                headerString += [CPString stringWithFormat:@"\\cf%d", [self numberForColor:color]];
                trailerString += @"\\cf0";
            }
        }
        else if ([currAttrib isEqualToString:CPBackgroundColorAttributeName])
        {
            var color = [attributes objectForKey:CPBackgroundColorAttributeName];

            if (![color isEqual:bgColor])
            {
                headerString += [CPString stringWithFormat:@"\\cb%d", [self numberForColor:color]];
                trailerString += @"\\cb0";
            }
        }
        else if ([currAttrib isEqualToString:CPUnderlineStyleAttributeName])
        {
            headerString += @"\\ul";
            trailerString += @"\\ulnone";
        }
        else if ([currAttrib isEqualToString:CPSuperscriptAttributeName])
        {
            var value = [attributes objectForKey:CPSuperscriptAttributeName],
                svalue = [value intValue] * 6;

            if (svalue > 0)
            {
                headerString += [CPString stringWithFormat:@"\\up%d", svalue];
                trailerString += @"\\up0";
            }
            else if (svalue < 0)
            {
                headerString += [CPString stringWithFormat:@"\\dn-%d", svalue];
                trailerString += @"\\dn0";
            }
        }
        else if ([currAttrib isEqualToString:CPBaselineOffsetAttributeName])
        {
            var value = [attributes objectForKey:CPBaselineOffsetAttributeName],
                svalue = [value floatValue] * 2;

            if (svalue > 0)
            {
                headerString += [CPString stringWithFormat:@"\\up%d", svalue];
                trailerString += @"\\up0";
            }
            else if (svalue < 0)
            {
                headerString += [CPString stringWithFormat:@"\\dn-%d", svalue];
                trailerString += @"\\dn0";
            }
        }
        else if ([currAttrib isEqualToString:CPAttachmentAttributeName])
        {
        }
        else if ([currAttrib isEqualToString:CPLigatureAttributeName])
        {
        }
        else if ([currAttrib isEqualToString:CPKernAttributeName])
        {
        }
    }

    substring = substring.replace(/\\/g, '\\\\');
    substring = substring.replace(/\n/g, '\\par\n');
    substring = substring.replace(/\t/g, '\\tab ');
    substring = substring.replace(/{/g, '\\{');
    substring = substring.replace(/}/g, '\\}');

    if (!first)
    {
        var braces;

        if ([headerString length])
             braces = [CPString stringWithFormat:@"{%@ %@}", headerString, substring];
        else
             braces = substring;

        result += braces;
    }
    else
    {
        var nobraces;

        if ([headerString length])
            nobraces = [CPString stringWithFormat:@"%@ %@", headerString, substring];
        else
            nobraces = substring;

        result += nobraces;
    }

    return result + trailerString;
}

- (CPString)bodyString
{
    var string = [text string],
        result = "",
        loc = 0,
        length = [string length],
        currRange = CPMakeRange(loc, 0),
        completeRange = CPMakeRange(0, length),
        paragraphStart = YES;

    while (CPMaxRange(currRange) < CPMaxRange(completeRange))  // save all "runs"
    {
        var attributes,
            substring,
            runString;

        attributes = [text attributesAtIndex:CPMaxRange(currRange)
                       longestEffectiveRange:currRange
                                     inRange:completeRange];
        substring = [string substringWithRange:currRange];
        runString = [self runStringForString:substring
                                  attributes:attributes
                              paragraphStart:paragraphStart];

        result += runString;
        
        // Dynamically compute paragraph boundaries based on standard line feeds
        if (substring.length > 0 && substring.charAt(substring.length - 1) === '\n')
            paragraphStart = YES;
        else
            paragraphStart = NO;
    }

    return result;
}


- (CPString)RTFDStringFromAttributedString:(CPAttributedString)aText
                        documentAttributes:(CPDictionary)dict
{
    var output = [CPString string],
        headerString,
        trailerString,
        bodyString;

    text = aText;
    docDict = dict;

    bodyString = [self bodyString];
    trailerString = [self trailerString];
    headerString = [self headerString];

    output += headerString;
    output += bodyString;
    output += trailerString;
    return output;
}
@end
