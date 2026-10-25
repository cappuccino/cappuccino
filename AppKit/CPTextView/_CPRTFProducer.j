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
@import "CPTextList.j"

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

/*
    Escapes text for RTF. Backslashes and braces are escaped, and every character outside ASCII
    is written as a Unicode control word, \uN, with no fallback characters (\uc0), as Cocoa
    writes it. Values above 32767 are written as negative numbers, as RTF requires.
*/
var _CPRTFEscapeUnicode = function(aString)
{
    return aString.replace(/[^\x00-\x7f]/g, function(aCharacter)
    {
        var code = aCharacter.charCodeAt(0);

        return "\\uc0\\u" + (code > 32767 ? code - 65536 : code) + " ";
    });
};

/*
    Returns aNumber as two hexadecimal digits, for the \'hh escapes of a list level's text.
*/
var _CPRTFHexByte = function(aNumber)
{
    return ("0" + (aNumber & 0xff).toString(16)).slice(-2);
};

/*
    The RTF number format (\levelnfc) of each marker format name. Bullets are 23. Hexadecimal and
    octal have no RTF number format, so other readers show them as decimal numbers; Cocoa reads
    the marker format itself from \levelmarker.
*/
var _CPRTFLevelNumberFormats = {
        "decimal": 0,
        "upper-roman": 1,
        "lower-roman": 2,
        "upper-alpha": 3,
        "upper-latin": 3,
        "lower-alpha": 4,
        "lower-latin": 4
    };

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

    // The outermost text lists in the text, each written as one RTF list, and for each, the text
    // list of every level, as first met.
    CPArray             textLists;
    CPArray             textListLevels;
}

// MARK: -
// MARK: Class methods


+ (CPString)produceRTF:(CPAttributedString)aText documentAttributes:(CPDictionary)dict
{
    var mynew = [self new];

    return [mynew RTFDStringFromAttributedString:aText documentAttributes:dict];
}


// MARK: -
// MARK: init methods

- (id)init
{
    if (self = [super init])
    {
        colorDict = [CPMutableDictionary new];
        fontDict = [CPMutableDictionary new];

        fgColor = [CPColor blackColor];
        bgColor= [CPColor whiteColor];

        textLists = [];
        textListLevels = [];
    }

    return self;
}

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
    result += [self listTables];
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

    // In RTF the first line indent is an offset from the left indent.
    var twips = _points2twips([paraStyle firstLineHeadIndent] - [paraStyle headIndent]);

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

    // A list item names its RTF list and its level.
    var lists = [paraStyle textLists];

    if ([lists count])
        headerString += [CPString stringWithFormat:@"\\ls%d\\ilvl%d", [self listNumberForTextLists:lists], [lists count] - 1];

    return headerString;
}

// MARK: -
// MARK: Text lists

/*
    Returns the number of the RTF list for a paragraph's text lists, and records the list of each
    level. Each outermost text list becomes one RTF list, with one level for each nesting depth.
*/
- (int)listNumberForTextLists:(CPArray)someLists
{
    var index = [textLists indexOfObjectIdenticalTo:someLists[0]];

    if (index === CPNotFound)
    {
        index = textLists.length;
        textLists.push(someLists[0]);
        textListLevels.push([]);
    }

    var levels = textListLevels[index];

    for (var level = 0; level < someLists.length; level++)
        if (!levels[level])
            levels[level] = someLists[level];

    return index + 1;
}

/*
    Returns the list table and the list override table for the text lists in the text. Each RTF
    list is a hybrid list with one level for each nesting depth, and one override, \lsN, that
    paragraphs refer to.
*/
- (CPString)listTables
{
    if (!textLists.length)
        return @"";

    var listTable = @"{\\*\\listtable",
        overrideTable = @"{\\*\\listoverridetable";

    for (var i = 0; i < textLists.length; i++)
    {
        var listNumber = i + 1,
            levels = textListLevels[i];

        listTable += "{\\list\\listtemplateid" + listNumber + "\\listhybrid";

        for (var level = 0; level < levels.length; level++)
            listTable += [self listLevelString:levels atLevel:level templateID:listNumber * 100 + level + 1];

        listTable += "{\\listname ;}\\listid" + listNumber + "}";
        overrideTable += "{\\listoverride\\listid" + listNumber + "\\listoverridecount0\\ls" + listNumber + "}";
    }

    return listTable + "}\n" + overrideTable + "}\n";
}

/*
    Returns the RTF definition of one list level. Cocoa reads the marker format from the
    \levelmarker destination and the prepending of the enclosing marker from \levelprepend. Other
    readers use the number format (\levelnfc), the starting number (\levelstartat) and the
    level's text (\leveltext), in which \'0N stands for the number of level N.
*/
- (CPString)listLevelString:(CPArray)someLevels atLevel:(int)aLevel templateID:(int)aTemplateID
{
    var list = someLevels[aLevel],
        format = [list markerFormat],
        match = format.match(/\{([a-z-]+)\}/),
        name = match ? match[1] : "",
        numberFormat = [list isOrdered] ? (_CPRTFLevelNumberFormats[name] || 0) : 23,
        parts = [self levelTextParts:someLevels atLevel:aLevel],
        levelText = "",
        levelNumbers = "",
        length = 0,
        indent = 720 * (aLevel + 1);

    for (var i = 0; i < parts.length; i++)
    {
        var part = parts[i];

        if (typeof part === "number")
        {
            length++;
            levelText += "\\'" + _CPRTFHexByte(part);
            levelNumbers += "\\'" + _CPRTFHexByte(length);
        }
        else
        {
            length += part.length;
            levelText += _CPRTFEscapeUnicode(part.replace(/[\\{};]/g, function(aCharacter)
            {
                return "\\'" + _CPRTFHexByte(aCharacter.charCodeAt(0));
            }));
        }
    }

    return "{\\listlevel\\levelnfc" + numberFormat + "\\levelnfcn" + numberFormat +
           "\\leveljc0\\leveljcn0\\levelfollow0\\levelstartat" + [list startingItemNumber] +
           "\\levelspace360\\levelindent0{\\*\\levelmarker " + _CPRTFEscapeUnicode(format.replace(/([\\{}])/g, "\\$1")) + "}" +
           (([list listOptions] & CPTextListPrependEnclosingMarker) ? "\\levelprepend" : "") +
           "{\\leveltext\\leveltemplateid" + aTemplateID + "\\'" + _CPRTFHexByte(length) + levelText + ";}" +
           "{\\levelnumbers" + levelNumbers + ";}\\fi-720\\li" + indent + "\\lin" + indent + " }";
}

/*
    Returns the parts of a list level's text: strings, and the level numbers whose item numbers
    take their place. A bullet level is its bullet. A numbered level is the text around its number,
    after the enclosing level's text when the list prepends the enclosing marker.
*/
- (CPArray)levelTextParts:(CPArray)someLevels atLevel:(int)aLevel
{
    var list = someLevels[aLevel],
        format = [list markerFormat];

    if (![list isOrdered])
        return [[list markerForItemNumber:1]];

    var match = format.match(/\{[a-z-]+\}/),
        parts = [];

    if (aLevel > 0 && ([list listOptions] & CPTextListPrependEnclosingMarker))
        parts = [self levelTextParts:someLevels atLevel:aLevel - 1];

    if (match.index > 0)
        parts.push(format.substring(0, match.index));

    parts.push(aLevel);

    if (match.index + match[0].length < format.length)
        parts.push(format.substring(match.index + match[0].length));

    return parts;
}

- (CPString)runStringForString:(CPString) substring
                    attributes:(CPDictionary) attributes
                paragraphStart:(BOOL) first
{
    return [self runStringForString:substring attributes:attributes paragraphStart:first listMarker:NO];
}

/*
    As -runStringForString:attributes:paragraphStart:. When isListMarker is YES, the run is the
    marker at the start of a list item, and is written in a \listtext group, as Cocoa writes it.
    Readers that understand lists number the items themselves; others show the marker text.
*/
- (CPString)runStringForString:(CPString) substring
                    attributes:(CPDictionary) attributes
                paragraphStart:(BOOL) first
                    listMarker:(BOOL) isListMarker
{
    var unwrap = function(obj) {
        if (!obj) return null;

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

        // Try to fetch from the active live view of the attachment first to capture user edits
        var activeView = null;
        if (typeof tableAttachment.respondsToSelector === "function" && [tableAttachment respondsToSelector:@selector(view)]) {
            activeView = [tableAttachment view];
        }
        if (!activeView) {
            activeView = tableAttachment._view || tableAttachment.view;
        }

        if (activeView) {
            if (typeof activeView.respondsToSelector === "function") {
                if ([activeView respondsToSelector:@selector(headers)]) {
                    headers = [activeView headers];
                }
                if ([activeView respondsToSelector:@selector(rows)]) {
                    rows = [activeView rows];
                }
            }
            if (!headers) {
                headers = activeView._headers || activeView.headers;
            }
            if (!rows) {
                rows = activeView._rows || activeView.rows;
            }
        }

        // Fall back to the attachment's parsed properties if the view is nil or lacks the properties
        if (!headers || !rows) {
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
                    
                    // Safely extract text representation from CPAttributedString / CPTextStorage if present
                    if (cellText && typeof cellText === "object") {
                        if (typeof cellText.string === "function") {
                            cellText = [cellText string];
                        } else if (cellText._string !== undefined) {
                            cellText = cellText._string;
                        } else if (cellText.string !== undefined) {
                            cellText = cellText.string;
                        }
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

    attribEnum = [attributes keyEnumerator];

    while ((currAttrib = [attribEnum nextObject]) != nil)
    {
        if ([currAttrib isEqualToString:CPFontAttributeName])
        {
            var font,
                fontName,
                traits;

            font = [attributes objectForKey:CPFontAttributeName];
            fontName = [font familyName];
            traits = [[CPFontManager sharedFontManager] traitsOfFont:font];

            if (currentFont == nil || ![fontName isEqualToString:[currentFont familyName]])
                headerString += [self fontToken:fontName];

            if (currentFont == nil || [font size] != [currentFont size])
            {
                var points = [font size] * 2,
                    pString;

                pString = [CPString stringWithFormat:@"\\fs%d", points];
                headerString += pString;
            }

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
            trailerString += @"\\ulnone "; // trailing space important!
        }
        else if ([currAttrib isEqualToString:CPSuperscriptAttributeName])
        {
            var value = [attributes objectForKey:CPSuperscriptAttributeName],
                ivalue = [value intValue];

            if (ivalue > 0)
            {
                headerString += @"\\super";
                trailerString += @"\\nosupersub "; // trailing space important!
            }
            else if (ivalue < 0)
            {
                headerString += @"\\sub";
                trailerString += @"\\nosupersub "; // trailing space important!
            }
        }
        else if ([currAttrib isEqualToString:CPBaselineOffsetAttributeName])
        {
            var value = [attributes objectForKey:CPBaselineOffsetAttributeName],
                fvalue = [value floatValue],
                svalue = Math.round(fvalue * 2.0); // Convert standard points to RTF half-points

            if (svalue > 0)
            {
                headerString += [CPString stringWithFormat:@"\\up%d", svalue];
                trailerString += @"\\up0";
            }
            else if (svalue < 0)
            {
                // Correct negative formatting using safe positive boundary
                headerString += [CPString stringWithFormat:@"\\dn%d", Math.abs(svalue)];
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

    // An image attachment is not written yet, so its attachment character is left out.
    substring = substring.replace(/\uFFFC/g, '');

    substring = substring.replace(/\\/g, '\\\\');
    substring = substring.replace(/\n/g, '\\par\n');
    substring = substring.replace(/\t/g, '\\tab ');
    substring = substring.replace(/{/g, '\\{');
    substring = substring.replace(/}/g, '\\}');
    substring = _CPRTFEscapeUnicode(substring);

    if (isListMarker)
        substring = "{\\listtext " + substring + "}";

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

    while (CPMaxRange(currRange) < CPMaxRange(completeRange))
    {
        var attributes,
            substring,
            runString;

        var runStart = CPMaxRange(currRange);

        attributes = [text attributesAtIndex:runStart
                       longestEffectiveRange:currRange
                                     inRange:completeRange];

        // The longest effective range can reach back before the run's start, after a list marker
        // that shares its attributes was written as a run of its own.
        if (currRange.location < runStart)
            currRange = CPMakeRange(runStart, CPMaxRange(currRange) - runStart);

        // A list item's marker, a tab, the marker and a tab, is written as a run of its own.
        var markerLength = paragraphStart ? [self listMarkerLengthAtIndex:currRange.location attributes:attributes] : 0,
            isListMarker = markerLength > 0 && markerLength <= currRange.length;

        if (isListMarker)
            currRange.length = markerLength;

        substring = [string substringWithRange:currRange];
        runString = [self runStringForString:substring
                                  attributes:attributes
                              paragraphStart:paragraphStart
                                  listMarker:isListMarker];

        result += runString;
        
        if (substring.length > 0 && substring.charAt(substring.length - 1) === '\n')
            paragraphStart = YES;
        else
            paragraphStart = NO;
    }

    return result;
}


/*
    Returns the length of the marker at the start of a list item, a tab, the marker and a tab, or
    0 when the paragraph is not a list item or does not start with a marker.
*/
- (unsigned)listMarkerLengthAtIndex:(unsigned)anIndex attributes:(CPDictionary)attributes
{
    var string = [text string];

    if (![[[attributes objectForKey:CPParagraphStyleAttributeName] textLists] count] || string.charAt(anIndex) !== "\t")
        return 0;

    for (var i = anIndex + 1; i < string.length; i++)
    {
        var character = string.charAt(i);

        if (character === "\t")
            return i - anIndex + 1;

        if (character === "\n")
            break;
    }

    return 0;
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
