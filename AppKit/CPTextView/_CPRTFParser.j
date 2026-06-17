/* RTFParser.j

   Parse a RTF string into a CPAttributedString

   Copyright (C) 2014 Daniel Boehringer

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
@import <Foundation/CPGeometry.j>
@import "CPTextStorage.j"
@import "CPFontManager.j"
@import "CPParagraphStyle.j"
@import "_CPTableTextAttachment.j"

@global CPLeftTextAlignment
@global CPRightTextAlignment
@global CPCenterTextAlignment
@global CPJustifiedTextAlignment
@global CPNaturalTextAlignment

@global CPFontAttributeName
@global CPForegroundColorAttributeName
@global CPBackgroundColorAttributeName
@global CPParagraphStyleAttributeName
@global CPAttachmentAttributeName
@global CPUnderlineStyleAttributeName

@global CPLeftTabStopType
@global CPRightTabStopType
@global CPCenterTabStopType
@global CPDecimalTabStopType

var hexTable = [];

var cp1252Map = {
    0x80: 0x20AC, 0x82: 0x201A, 0x83: 0x0192, 0x84: 0x201E, 0x85: 0x2026,
    0x86: 0x2020, 0x87: 0x2021, 0x88: 0x02C6, 0x89: 0x2030, 0x8A: 0x0160,
    0x8B: 0x2039, 0x8C: 0x0152, 0x8E: 0x017D, 0x91: 0x2018, 0x92: 0x2019,
    0x93: 0x201C, 0x94: 0x201D, 0x95: 0x2022, 0x96: 0x2013, 0x97: 0x2014,
    0x98: 0x02DC, 0x99: 0x2122, 0x9A: 0x0161, 0x9B: 0x203A, 0x9C: 0x0153,
    0x9E: 0x017E, 0x9F: 0x0178
};

// Hold the attributes of the current run
@implementation _RTFAttribute : CPObject
{
    CPRange             _range;
    CPParagraphStyle    paragraph;
    CPColor             fgColour;
    CPColor             bgColour;
    CPColor             ulColour;
    CPString            fontName;
    unsigned            fontSize;
    BOOL                bold;
    BOOL                italic;
    BOOL                underline;
    BOOL                strikethrough;
    BOOL                script;
    BOOL                _tabChanged;
    CPTabStopType       _nextTabType;
}

- (id)init
{
    if (self = [super init])
    {
        [self resetFont];
        [self resetParagraphStyle];
        _range = CPMakeRange(0, 0);
        _nextTabType = CPLeftTabStopType;
    }

    return self;
}

- (id)copy
{
    var mynew =  [_RTFAttribute new];

    mynew.paragraph = [paragraph mutableCopy];
    mynew.fontName = fontName;
    mynew.fontSize = fontSize;
    mynew.bold = bold;
    mynew.italic = italic;
    mynew.underline = underline;
    mynew.strikethrough = strikethrough;
    mynew.script = script;
    mynew.fgColour = fgColour;
    mynew.bgColour = bgColour;
    mynew.ulColour = ulColour;
    mynew._tabChanged = _tabChanged;
    mynew._nextTabType = _nextTabType;

    return mynew;
}

- (CPFont)currentFont
{
    var font = [CPFont _fontWithName:fontName size:fontSize bold:bold italic:italic];

    if (font)
        return font;

    var range = [fontName rangeOfString:@"-"];

    if (range.location != CPNotFound)
    {
        var fontFamily = [fontName substringToIndex: range.location];

        font = [CPFont fontWithName:fontFamily size:fontSize];
    }

    if (font == nil)
        font = [CPFont systemFontOfSize:fontSize];

    return font;
}

- (CPNumber)script
{
    return [CPNumber numberWithInt:script];
}

- (CPNumber)underline
{
    if (underline != 0)
        return [CPNumber numberWithInt:underline];
    else
        return nil;
}

- (CPNumber)strikethrough
{
    if (strikethrough != 0)
        return [CPNumber numberWithInt:strikethrough];
    else
        return nil;
}

- (void)resetParagraphStyle
{
    paragraph = [[CPParagraphStyle defaultParagraphStyle] mutableCopy];
    _tabChanged = NO;
    _nextTabType = CPLeftTabStopType;
}

- (void)resetFont
{
    var font = [CPFont systemFontOfSize:12];

    fontName = [font familyName];
    fontSize = 12.0;
    italic = NO;
    bold = NO;
    underline = 0;
    strikethrough = 0;
    script = 0;
}

- (void)addTab:(float)location type:(CPTextTabType)type
{
    var alignment = CPLeftTextAlignment;
    if (type === CPCenterTabStopType || type === CPCenterTextAlignment)
        alignment = CPCenterTextAlignment;
    else if (type === CPRightTabStopType || type === CPRightTextAlignment)
        alignment = CPRightTextAlignment;
    else if (type === CPDecimalTabStopType)
        alignment = CPRightTextAlignment;

    var tab = [[CPTextTab alloc] initWithType:alignment
                                     location:location];

    if (!_tabChanged)
    {
        [paragraph setTabStops:[tab]];
        _tabChanged = YES;
    }
    else
    {
        [paragraph addTabStop: tab];
    }

    _nextTabType = CPLeftTabStopType;
}

- (CPDictionary)dictionary
{
    var ret = @{};
    [ret setObject:[self currentFont] forKey:CPFontAttributeName];
    [ret setObject:paragraph forKey:CPParagraphStyleAttributeName];

    if (fgColour)
        [ret setObject:fgColour forKey:CPForegroundColorAttributeName];

    if (bgColour)
        [ret setObject:bgColour forKey:CPBackgroundColorAttributeName];

    if (underline)
        [ret setObject:[CPNumber numberWithInt:1] forKey:CPUnderlineStyleAttributeName];

    return ret;
}
@end


var kRTFParserType_char = 0,
    kRTFParserType_dest = 1,
    kRTFParserType_prop = 2,
    kRTFParserType_spec = 3;

var kRgsymRtf = {
        "b"                                  : [ "b",        1,        false,     kRTFParserType_prop,    "propBold"],
        "ul"                                 : [ "ul",       1,        false,     kRTFParserType_prop,    "propUnderline"],
        "i"                                  : [ "i",        1,        false,     kRTFParserType_prop,    "propItalic"],
        "pgnucltr"                           : [ "pgnucltr", "pgULtr", true,      kRTFParserType_prop,    "propPgnFormat"],
        "pgnlcltr"                           : [ "pgnlcltr", "pgLLtr", true,      kRTFParserType_prop,    "propPgnFormat"],
        "qc"                                 : [ "qc",       "justC",  true,      kRTFParserType_prop,    "propJust"],
        "ql"                                 : [ "ql",       "justL",  true,      kRTFParserType_prop,    "propJust"],
        "qr"                                 : [ "qr",       "justR",  true,      kRTFParserType_prop,    "propJust"],
        "qj"                                 : [ "qj",       "justF",  true,      kRTFParserType_prop,    "propJust"],
        "paperw"                             : [ "paperw",   12240,    false,     kRTFParserType_prop,    "propXaPage"],
        "paperh"                             : [ "paperh",   15480,    false,     kRTFParserType_prop,    "propYaPage"],
        "margl"                              : [ "margl",    1800,     false,     kRTFParserType_prop,    "propXaLeft"],
        "margr"                              : [ "margr",    1800,     false,     kRTFParserType_prop,    "propXaRight"],
        "margt"                              : [ "margt",    1440,     false,     kRTFParserType_prop,    "propYaTop"],
        "margb"                              : [ "margb",    1440,     false,     kRTFParserType_prop,    "propYaBottom"],
        "pgnstart"                           : [ "pgnstart", 1,        true,      kRTFParserType_prop,    "propPgnStart"],
        "facingp"                            : [ "facingp",  1,        true,      kRTFParserType_prop,    "propFacingp"],
        "landscape"                          : [ "landscape",1,        true,      kRTFParserType_prop,    "propLandscape"],
        "par"                                : [ "par",      0,        false,     kRTFParserType_char,    "\n"],
        "pard"                               : [ "pard",     0,        false,     kRTFParserType_prop,    "propDefaultPara"],
        "\0x0a"                              : [ "\0x0a",    0,        false,     kRTFParserType_char,    "\n"],
        "\0x0d"                              : [ "\0x0d",    0,        false,     kRTFParserType_char,    ""],
        "tab"                                : [ "tab",      0,        false,     kRTFParserType_char,    "\t"],
        "ldblquote"                          : [ "ldblquote",0,        false,     kRTFParserType_char,    '"'],
        "rdblquote"                          : [ "rdblquote",0,        false,     kRTFParserType_char,    '"'],
        "bin"                                : [ "bin",      0,        false,     kRTFParserType_spec,    "ipfnBin"],
        "*"                                  : [ "*",        0,        false,     kRTFParserType_spec,    "ipfnDestSkip"],
        "'"                                  : [ "'",        0,        false,     kRTFParserType_spec,    "ipfnHex"],
        "author"                             : [ "author",   0,        false,     kRTFParserType_dest,    "destSkip"],
        "buptim"                             : [ "buptim",   0,        false,     kRTFParserType_dest,    "destSkip"],
        "colortbl"                           : [ "colortbl", 0,        false,     kRTFParserType_dest,    "destSkip"],
        "comment"                            : [ "comment",  0,        false,     kRTFParserType_dest,    "destSkip"],
        "creatim"                            : [ "creatim",  0,        false,     kRTFParserType_dest,    "destSkip"],
        "doccomm"                            : [ "doccomm",  0,        false,     kRTFParserType_dest,    "destSkip"],
        "fonttbl"                            : [ "fonttbl",  0,        false,     kRTFParserType_dest,    "destSkip"],
        "footer"                             : [ "footer",   0,        false,     kRTFParserType_dest,    "destSkip"],
        "footerf"                            : [ "footerf",  0,        false,     kRTFParserType_dest,    "destSkip"],
        "footerl"                            : [ "footerl",  0,        false,     kRTFParserType_dest,    "destSkip"],
        "footerr"                            : [ "footerr",  0,        false,     kRTFParserType_dest,    "destSkip"],
        "footnote"                           : [ "footnote", 0,        false,     kRTFParserType_dest,    "destSkip"],
        "ftncn"                              : [ "ftncn",    0,        false,     kRTFParserType_dest,    "destSkip"],
        "ftnsep"                             : [ "ftnsep",   0,        false,     kRTFParserType_dest,    "destSkip"],
        "ftnsepc"                            : [ "ftnsepc",  0,        false,     kRTFParserType_dest,    "destSkip"],
        "fprq"                               : [ "fprq",     0,        false,     kRTFParserType_dest,    "destSkip"],
        "rquote"                             : [ "rquote",   0,        false,     kRTFParserType_char,    "'"],
        "header"                             : [ "header",   0,        false,     kRTFParserType_dest,    "destSkip"],
        "headerf"                            : [ "headerf",  0,        false,     kRTFParserType_dest,    "destSkip"],
        "headerl"                            : [ "headerl",  0,        false,     kRTFParserType_dest,    "destSkip"],
        "headerr"                            : [ "headerr",  0,        false,     kRTFParserType_dest,    "destSkip"],
        "info"                               : [ "info",     0,        false,     kRTFParserType_dest,    "destSkip"],
        "keywords"                           : [ "keywords", 0,        false,     kRTFParserType_dest,    "destSkip"],
        "operator"                           : [ "operator", 0,        false,     kRTFParserType_dest,    "destSkip"],
        "pict"                               : [ "pict",     0,        false,     kRTFParserType_dest,    "destSkip"],
        "printim"                            : [ "printim",  0,        false,     kRTFParserType_dest,    "destSkip"],
        "private1"                           : [ "private1", 0,        false,     kRTFParserType_dest,    "destSkip"],
        "revtim"                             : [ "revtim",   0,        false,     kRTFParserType_dest,    "destSkip"],
        "rxe"                                : [ "rxe",      0,        false,     kRTFParserType_dest,    "destSkip"],
        "stylesheet"                         : [ "stylesheet",0,       false,     kRTFParserType_dest,    "destSkip"],
        "subject"                            : [ "subject",  0,        false,     kRTFParserType_dest,    "destSkip"],
        "tc"                                 : [ "tc",       0,        false,     kRTFParserType_dest,    "destSkip"],
        "title"                              : [ "title",    0,        false,     kRTFParserType_dest,    "destSkip"],
        "txe"                                : [ "txe",      0,        false,     kRTFParserType_dest,    "destSkip"],
        "xe"                                 : [ "xe",       0,        false,     kRTFParserType_dest,    "destSkip"],
        "["                                  : [ "[",        0,        false,     kRTFParserType_char,    '['],
        " "                                  : [ " ",        0,        false,     kRTFParserType_char,    ' '],
        "]"                                  : [ "]",        0,        false,     kRTFParserType_char,    ']'],
        "{"                                  : [ "{",        0,        false,     kRTFParserType_char,    '{'],
        "}"                                  : [ "}",        0,        false,     kRTFParserType_char,    '}'],
        "\\"                                 : [ "\\",       0,        false,     kRTFParserType_char,    '\\'],
        "trowd"                              : [ "trowd",    0,        false,     kRTFParserType_spec,    "ipfnTrowd"],
        "cell"                               : [ "cell",     0,        false,     kRTFParserType_spec,    "ipfnCell"],
        "row"                                : [ "row",      0,        false,     kRTFParserType_spec,    "ipfnRow"],
        "cellx"                              : [ "cellx",    0,        false,     kRTFParserType_spec,    "ipfnCellx"],
        "intbl"                              : [ "intbl",    0,        false,     kRTFParserType_spec,    "ipfnIntbl"]
    };

@implementation _CPRTFParser : CPObject
{
    CPString            _codePage;
    CGSize              _paper;
    CPString            _rtf;
    unsigned            _curState;
    CPArray             _states;
    unsigned            _currentParseIndex;
    BOOL                _hexreturn;
    _RTFAttribute       _currentRun;
    CPAttributedString  _result;
    CPArray             _colorArray;
    CPArray             _fontArray;
    CPString            _freename;
    BOOL                _parsingFontTable;

    // Table parsing state
    BOOL                _inTableActive;
    BOOL                _waitingForNextRow;
    CPMutableArray      _tableRows;
    CPMutableArray      _currentRow;
    CPString            _currentCellText;
}

- (id)init
{
    if (self = [super init])
    {
        _paper              = CPMakeSize(0, 0);
        _rtf                = "";
        _curState           = 0;                // 0 = normal, 1 = skip
        _states             = [];
        _currentParseIndex  = 0;
        _hexreturn          = NO;
        _result             = [CPAttributedString new];
        _colorArray         = [];
        _fontArray          = ['Arial'];   // FIXME: should be name of system font
        _freename           = "";
        _parsingFontTable   = NO;

        _inTableActive      = NO;
        _waitingForNextRow  = NO;
        _tableRows          = nil;
        _currentRow         = nil;
        _currentCellText    = "";

        // Safe Initialization
        _currentRun         = [_RTFAttribute new];
    }

    return self;
}

- (CPString)_checkChar:(CPArray)sym parameter:(CPString)ch
{
    switch (_curState)
    {
        case 0:
            if (sym && sym[4])
                return sym[4];

        case 1:
            return '';

        default:
            if (sym && sym[4])
                return sym[4];
     }
}

- (BOOL)pushState
{
    _states.push({
        curState: _curState,
        run: [_currentRun copy]
    });
    return YES;
}

- (BOOL)popState
{
    if (_states.length > 0)
    {
        var state = _states.pop();
        _curState = state.curState;

        [self _flushCurrentRun];
        _currentRun = state.run;

        if (!_currentRun)
        {
            _currentRun = [_RTFAttribute new];
        }

        _currentRun._range = CPMakeRange([_result length], 0);

        if (_curState == 0)
        {
            _parsingFontTable = NO;
        }
    }
    return YES;
}

- (CPString)_parseSpec:(CPArray)sym parameter:(CPString)v
{
    var ch = '';

    switch (sym[4])
    {
        case "ipfnDestSkip":
            _curState++;
            return '';

        case "ipfnHex":
            var hex = '';
            for (var i = 0; i < 2; i++)
            {
                var nextCh = _rtf.charAt(++_currentParseIndex);
                if (/[a-fA-F0-9]/.test(nextCh))
                {
                    hex += nextCh;
                }
                else
                {
                    _currentParseIndex--;
                    break;
                }
            }

            _hexreturn = YES;

            if (_curState !== 0)
               return '';
            else
                return hex;
            break;

         case "codePage":
             ch = _rtf.charAt(++_currentParseIndex);

             var code = '';

             while (new RegExp("[0-9]").test(ch))
             {
                 code += (ch + '');
                 ch = _rtf.charAt(++_currentParseIndex);
             }

             _codePage = code;
             _currentParseIndex--;
             break;

         case "ipfnTrowd":
             if (_waitingForNextRow)
             {
                 _waitingForNextRow = NO;
             }
             if (!_inTableActive)
             {
                 _inTableActive = YES;
                 _tableRows = [CPMutableArray array];
                 _currentRow = [CPMutableArray array];
                 _currentCellText = "";
             }
             else
             {
                 _currentRow = [CPMutableArray array];
             }
             return '';

         case "ipfnIntbl":
             return '';

         case "ipfnCell":
             if (_inTableActive)
             {
                 if (!_currentRow)
                     _currentRow = [CPMutableArray array];
                 [_currentRow addObject:_currentCellText];
                 _currentCellText = "";
             }
             return '';

         case "ipfnRow":
             if (_inTableActive)
             {
                 if (!_currentRow)
                     _currentRow = [CPMutableArray array];
                 [_tableRows addObject:_currentRow];
                 _waitingForNextRow = YES;
             }
             return '';

         case "ipfnCellx":
             return '';
    }

    return '';
}

- (void)_flushTableIfAny
{
    if (_tableRows && [_tableRows count] > 0)
    {
        [self _flushCurrentRun];

        var headers = [_tableRows objectAtIndex:0];
        var rows = [CPMutableArray array];
        for (var idx = 1; idx < [_tableRows count]; idx++)
        {
            [rows addObject:[_tableRows objectAtIndex:idx]];
        }
        
        var attachment = [[_CPTableTextAttachment alloc] initWithHeaders:headers rows:rows width:500.0];
        
        // Use standard Cocoa/Cappuccino NSAttachmentCharacter creation method
        var tableAttrStr = [CPTextStorage attributedStringWithAttachment:attachment];
        
        [_result appendAttributedString:tableAttrStr];
        
        if (_currentRun)
        {
            _currentRun._range = CPMakeRange([_result length], 0);
        }
        
        _tableRows = nil;
        _currentRow = nil;
        _currentCellText = "";
        _inTableActive = NO;
        _waitingForNextRow = NO;
    }
}

- (void)_flushCurrentRun
{
    var newOffset = 0;

    if (_currentRun)
    {
        if ([_result length] == _currentRun._range.location)
            return;

        _currentRun._range.length = [_result length] - _currentRun._range.location;
        newOffset = CPMaxRange(_currentRun._range);

        var dict = [_currentRun dictionary];

        [_result setAttributes:dict range:_currentRun._range];  // flush previous run
        
        _currentRun = [_currentRun copy];
    }
    else
    {
        _currentRun = [_RTFAttribute new];
    }

    _currentRun._range = CPMakeRange(newOffset, 0);  // open a new one
}

- (CPString)_applyPropChange:sym parameter:param
{
    switch (sym[0])
    {
        case "pard":
            [self _flushCurrentRun];
            [_currentRun resetParagraphStyle];
            break;

        case "b": // bold
            if (param === 0)
            {
                if (_currentRun && _currentRun.bold)
                   [self _flushCurrentRun];

                _currentRun.bold = NO;
            }
            else
            {
                if (_currentRun && !_currentRun.bold)
                    [self _flushCurrentRun];

               _currentRun.bold = YES;
            }

            break;

        case "i": // italic
            if (param === 0)
            {
                if (_currentRun && _currentRun.italic)
                   [self _flushCurrentRun];

                _currentRun.italic = NO;
            }
            else
            {
               if (_currentRun && !_currentRun.italic)
                  [self _flushCurrentRun];

               _currentRun.italic = YES;
            }

            break;

        case "ul": // underline
            if (param === 0)
            {
                if (_currentRun && _currentRun.underline)
                   [self _flushCurrentRun];

                _currentRun.underline = NO;
            }
            else
            {
                if (_currentRun && !_currentRun.underline)
                    [self _flushCurrentRun];

               _currentRun.underline = YES;
            }
            break;

        case "qc":  // paragraph center
            [_currentRun.paragraph setAlignment:CPCenterTextAlignment];
            break;

        case "ql":  // paragraph left
            [_currentRun.paragraph setAlignment:CPLeftTextAlignment];
            break;

        case "qr":  // paragraph right
            [_currentRun.paragraph setAlignment:CPRightTextAlignment];
            break;

        case "qj":  // paragraph justified
            [_currentRun.paragraph setAlignment:CPJustifiedTextAlignment];
            break;

        case "paperw":
            _paper.width = param;
            break;

        case "paperh":
            _paper.height = param;
            break;
    }

    return '';
}


- (CPString)_changeDest:(CPArray)sym
{
    switch (sym[0])
    {
        case "colortbl":
            _colorArray.push([CPColor blackColor]);
            break;

        case "fonttbl":
            _parsingFontTable = YES;
            break;
    }

    if (sym[4] == "destSkip")
    {
        _curState++;
    }

    return '';
}

- (CPString)_translateKeyword:(CPString)keyword parameter:(CPString)param fParameter:(BOOL)fParam
{
    if (_waitingForNextRow)
    {
        if (keyword !== "trowd" && keyword !== "cell" && keyword !== "row" && keyword !== "intbl" && keyword !== "cellx")
        {
            [self _flushTableIfAny];
        }
    }

    if (kRgsymRtf[keyword] !== undefined)
    {
        var sym = kRgsymRtf[keyword];

        switch (sym[3])
        {
            case kRTFParserType_prop:
                if (sym[2]  || !fParam)
                    param = sym[1];

                return [self _applyPropChange:sym parameter:param];

            case kRTFParserType_char:
                if((param + '') !== 'NaN' && (param + '') !== 'null' && (param + '').length)
                    _currentParseIndex -= (param + '').length;

                return [self _checkChar:sym parameter:param];

            case kRTFParserType_dest:
                return [self _changeDest:sym];

            case kRTFParserType_spec:
                return [self _parseSpec:sym parameter:param];

            default:
                return '';
        }
    }
    else
    {
        switch (keyword)
        {
            case "red":
                var oldColor = [_colorArray lastObject],
                    green = [oldColor greenComponent],
                    blue = [oldColor blueComponent];

                _colorArray.pop();
                _colorArray.push([CPColor colorWithRed:parseInt(param) / 255 green:green blue:blue alpha:1.0]);
                break;

            case "green":
                var oldColor = [_colorArray lastObject],
                    red = [oldColor redComponent],
                    blue = [oldColor blueComponent];

                _colorArray.pop();
                _colorArray.push([CPColor colorWithRed:red green: parseInt(param) / 255 blue:blue alpha:1.0]);
                break;

            case "blue":
                var oldColor = [_colorArray lastObject],
                    green = [oldColor greenComponent],
                    red = [oldColor redComponent];

                _colorArray.pop();
                _colorArray.push([CPColor colorWithRed:red green:green blue:parseInt(param) / 255 alpha:1.0]);
                _colorArray.push([CPColor blackColor]); // placeholder for next color
                break;

            case "cf":  // change foreground color
                 [self _flushCurrentRun];
                 var fontIndex = parseInt(param) - 1;

                 if (_currentRun && fontIndex >= 0)
                     _currentRun.fgColour = _colorArray[fontIndex];

                break;

            case "cb":  // change background color
            case "highlight":
                 [self _flushCurrentRun];
                 var colorIndex = parseInt(param) - 1;

                 if (_currentRun)
                 {
                     if (colorIndex >= 0 && colorIndex < _colorArray.length)
                         _currentRun.bgColour = _colorArray[colorIndex];
                     else
                         _currentRun.bgColour = nil;
                 }
                 break;

            case "f":  // change font
                 [self _flushCurrentRun];
                 var fontIndex = parseInt(param);

                 if (_currentRun && fontIndex >= 0 && fontIndex < _fontArray.length)
                     _currentRun.fontName = _fontArray[fontIndex];
                 break;

            case "fs":  // change font size
                 [self _flushCurrentRun];
                 _currentRun.fontSize = parseInt(param) / 2;
                 break;

            case "fi":  // first line indent
                 if (_currentRun)
                     [_currentRun.paragraph setFirstLineHeadIndent:parseInt(param) / 20.0];
                 break;

            case "li":  // left indent / head indent
                 if (_currentRun)
                     [_currentRun.paragraph setHeadIndent:parseInt(param) / 20.0];
                 break;

            case "ri":  // right indent / tail indent
                 if (_currentRun)
                     [_currentRun.paragraph setTailIndent:parseInt(param) / 20.0];
                 break;

            case "tqc": // center tab stop style flag
                 if (_currentRun)
                     _currentRun._nextTabType = CPCenterTabStopType;
                 break;

            case "tqr": // right tab stop style flag
                 if (_currentRun)
                     _currentRun._nextTabType = CPRightTabStopType;
                 break;

            case "tqdec": // decimal tab stop style flag
                 if (_currentRun)
                     _currentRun._nextTabType = CPDecimalTabStopType;
                 break;

            case "tx":  // tabstop location definition
                 var location = parseInt(param) / 20;

                 if (_currentRun)
                     [_currentRun addTab:location type:_currentRun._nextTabType];

                 break;

            default:
               break;
        }

        return '';
    }
}

- (CPString)_parseKeyword:(CPString)rtf length:(unsigned)len
{
    var ch = '',
        fParam = false,
        fNeg = false,
        keyword = '',
        param = '';

    _rtf = rtf;

    if (++_currentParseIndex >= len)
        return len;

    ch = rtf.charAt(_currentParseIndex);

    if (!/[a-zA-Z]/.test(ch))
        return [self _translateKeyword:ch parameter:nil fParameter:fParam];

    while (new RegExp("[a-zA-Z]").test(ch))
    {
        keyword += ch;
        ch = rtf.charAt(++_currentParseIndex);
    }

    if (ch == '-')
    {
        fNeg = true;
        ch = rtf.charAt(++_currentParseIndex);
    }

    fParam = true;

    while (new RegExp("[0-9]").test(ch))
    {
        param += (ch + '');
        ch = rtf.charAt(++_currentParseIndex);
    }

    _currentParseIndex--;
    param = parseInt(param);

    if (fNeg)
        param *= -1;

    return [self _translateKeyword:keyword parameter:param fParameter:fParam];
}

- (void)_appendPlainString:(CPString) aString
{
    if (_inTableActive)
    {
        _currentCellText += aString;
    }
    else
    {
        [_result replaceCharactersInRange:CPMakeRange([_result length], 0) withString:aString];
    }
}

- (CPAttributedString)parseRTF:(CPString)rtf
{
    rtf = rtf.replace(/\\\n/g, "\\par\n");

    if (rtf.length == 0)
        return '';

    _currentParseIndex = -1;

    var len = rtf.length,
        tmp = '',
        ch = '',
        hex = '',
        lastchar = 0;

    while (_currentParseIndex < len)
    {
        tmp = rtf.charAt(++_currentParseIndex);

        if (_waitingForNextRow && tmp !== "\\" && tmp !== " " && tmp !== "\n" && tmp !== "\r" && tmp !== "\t")
        {
            [self _flushTableIfAny];
        }

        if (tmp !== "\\" && hex.length > 0)
        {
            [self _appendPlainString: String.fromCharCode(parseInt((hex), 16))];
            hex = '';
        }

        switch (tmp)
        {
            case " ":
                if (lastchar == 1)
                {
                    lastchar = 0;
                }
                else
                {
                    _freename += tmp;
                   [self _appendPlainString:tmp];
                }

                break;

            case "{":
                if (_waitingForNextRow)
                    [self _flushTableIfAny];

                if ([self pushState])
                
                break;

            case "}":
                if (_waitingForNextRow)
                    [self _flushTableIfAny];

                if ([self popState])

                if (_freename)
                {
                    if (_parsingFontTable)
                    {
                         _fontArray.push(_freename);
                         _parsingFontTable = NO;
                    }

                    _freename = "";
                }

                [self _flushCurrentRun];
                break;

            case "\\":
                _freename = '';
                ch = [self _parseKeyword:rtf length:len];

                if (!_hexreturn && ch.length == 0)
                    lastchar = 1;
                else
                    lastchar = 0;

                if (_hexreturn)
                {
                    if (ch.length > 0)
                    {
                        var byteVal = parseInt(ch, 16);
                        var unicodeVal = byteVal;

                        if (byteVal >= 0x80 && byteVal <= 0x9F) {
                            unicodeVal = cp1252Map[byteVal] || byteVal;
                        }

                        [self _appendPlainString: String.fromCharCode(unicodeVal)];
                    }
                    _hexreturn = NO;
                }
                else if (ch !== undefined && _curState === 0)
                {
                    [self _appendPlainString:ch];
                }

                break;

            case 0x0d:
            case 0x0a:
            case '\n':
            case '\r':
                break;

            default:
                lastchar = 0;

                if (_curState == 0)
                {
                    [self _appendPlainString:tmp];
                }
                else
                {
                    if (tmp === ';')
                    {
                        if (_parsingFontTable && _freename)
                        {
                            var cleanFontName = _freename.trim();
                            var lastSpaceIdx = cleanFontName.lastIndexOf(' ');
                            if (lastSpaceIdx !== -1)
                            {
                                cleanFontName = cleanFontName.substring(lastSpaceIdx + 1);
                            }
                            _fontArray.push(cleanFontName);
                            _freename = "";
                        }
                    }
                    else
                    {
                        _freename += tmp;
                    }
                }

                break;
        }
    }

    [self _flushTableIfAny];

    return _result;
}

@end

/*
 * CPMarkdownParser.j
 *
 * Parse a Markdown string into a CPAttributedString with inline style attributes
 * and embedded _CPTableTextAttachment objects.
 *
 * Copyright (C) 2026 by Daniel Böhringer
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

@implementation CPMarkdownParser : CPObject

+ (CPAttributedString)attributedStringFromMarkdown:(CPString)markdown
{
    if (!markdown) {
        return [[CPAttributedString alloc] initWithString:@""];
    }

    var result = [[CPMutableAttributedString alloc] initWithString:@""];
    var lines = markdown.split(/\r?\n/);
    
    var i = 0;
    while (i < lines.length) {
        var line = lines[i];
        
        if ([self isTableHeaderLine:line] && i + 1 < lines.length && [self isTableSeparatorLine:lines[i+1]]) {
            var headers = [self parseTableCells:line];
            var separatorLine = lines[i+1];
            var rows = [CPMutableArray array];
            
            i += 2;
            while (i < lines.length && [self isTableRowLine:lines[i]]) {
                [rows addObject:[self parseTableCells:lines[i]]];
                i++;
            }
            
            var numCols = [headers count];
            if (numCols == 0 && [rows count] > 0) {
                numCols = [[rows objectAtIndex:0] count];
            }

            // Convert raw header strings into CPAttributedStrings
            var parsedHeaders = [CPMutableArray array];
            for (var c = 0; c < [headers count]; c++) {
                var cellText = [headers objectAtIndex:c];
                [parsedHeaders addObject:[self parseTableCellMarkdown:cellText isHeader:YES]];
            }

            // Convert raw row strings into CPAttributedStrings
            var parsedRows = [CPMutableArray array];
            for (var r = 0; r < [rows count]; r++) {
                var rowData = [rows objectAtIndex:r];
                var parsedRow = [CPMutableArray array];
                for (var c = 0; c < [rowData count]; c++) {
                    var cellText = [rowData objectAtIndex:c];
                    [parsedRow addObject:[self parseTableCellMarkdown:cellText isHeader:NO]];
                }
                [parsedRows addObject:parsedRow];
            }
            
            var totalNaturalW = 0.0;
            var colNaturalWidths = [];
            var measureTextField = [[CPTextField alloc] initWithFrame:CGRectMake(0, 0, 10000.0, 24.0)];
            [measureTextField setFont:[CPFont systemFontOfSize:11.0]];
            
            for (var c = 0; c < numCols; c++) {
                var cellW = 80.0;
                
                if (c < [parsedHeaders count]) {
                    var parsedText = [parsedHeaders objectAtIndex:c];
                    [measureTextField setStringValue:parsedText._string];
                    [measureTextField sizeToFit];
                    cellW = Math.max(cellW, CGRectGetWidth([measureTextField frame]) + 24.0);
                }
                
                for (var r = 0; r < [parsedRows count]; r++) {
                    var rowData = [parsedRows objectAtIndex:r];
                    if (c < [rowData count]) {
                        var parsedText = [rowData objectAtIndex:c];
                        [measureTextField setStringValue:parsedText._string];
                        [measureTextField sizeToFit];
                        cellW = Math.max(cellW, CGRectGetWidth([measureTextField frame]) + 24.0);
                    }
                }
                colNaturalWidths[c] = cellW;
                totalNaturalW += cellW;
            }
            
            // Pass the parsed attributed strings to the attachment
            var matrixView = [[_CPTableTextAttachment alloc] initWithHeaders:parsedHeaders rows:parsedRows width:500.0];
            
            // Render utilizing the correct atomic attachment character string
            var tableAttrStr = [CPTextStorage attributedStringWithAttachment:matrixView];
            [result appendAttributedString:tableAttrStr];
            continue;
        }
        
        var isHeader = false;
        var headerLevel = 0;
        
        var headerMatch = line.match(/^(#{1,6})\s+(.*)$/);
        if (headerMatch) {
            headerLevel = headerMatch[1].length;
            line = headerMatch[2];
            isHeader = true;
        }
        
        var isListItem = false;
        var listMatch = line.match(/^(\*|-)\s+(.*)$/);
        if (listMatch) {
            line = "  • " + listMatch[2];
            isListItem = true;
        }
        
        var parsedLine = [self parseInlineMarkdown:line isHeader:isHeader headerLevel:headerLevel];
        [result appendAttributedString:parsedLine];
        
        if (i < lines.length - 1) {
            [result appendAttributedString:[[CPAttributedString alloc] initWithString:@"\n"]];
        }
        
        i++;
    }
    
    return result;
}

// Parses a single table cell's Markdown, converting HTML breaks and handling list items
+ (CPAttributedString)parseTableCellMarkdown:(CPString)cellText isHeader:(BOOL)isHeader
{
    if (!cellText) {
        return [[CPAttributedString alloc] initWithString:@""];
    }

    // Convert HTML line breaks to standard newlines
    var cleanedText = cellText.replace(/<br\s*\/?>/gi, "\n");
    var lines = cleanedText.split(/\r?\n/);
    var cellResult = [[CPMutableAttributedString alloc] initWithString:@""];
    
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        
        // Convert dash or asterisk lists inside the cell to bullets
        var listMatch = line.match(/^(\*|-)\s+(.*)$/);
        if (listMatch) {
            line = "  • " + listMatch[2];
        }
        
        var parsedLine = [self parseInlineMarkdown:line isHeader:isHeader headerLevel:3];
        [cellResult appendAttributedString:parsedLine];
        
        if (i < lines.length - 1) {
            [cellResult appendAttributedString:[[CPAttributedString alloc] initWithString:@"\n"]];
        }
    }
    
    return cellResult;
}

+ (BOOL)isTableHeaderLine:(CPString)line
{
    var trimmed = line.trim();
    return trimmed.indexOf('|') !== -1;
}

+ (BOOL)isTableSeparatorLine:(CPString)line
{
    var trimmed = line.trim();
    if (trimmed.indexOf('|') === -1) return NO;
    var stripped = trimmed.replace(/[\s|:\-]/g, '');
    return stripped.length === 0;
}

+ (BOOL)isTableRowLine:(CPString)line
{
    var trimmed = line.trim();
    return trimmed.indexOf('|') !== -1;
}

+ (CPArray)parseTableCells:(CPString)line
{
    var parts = line.split('|');
    var cells = [CPMutableArray array];
    var startIdx = 0;
    var endIdx = parts.length;
    if (parts[0].trim() === "") startIdx = 1;
    if (parts[parts.length - 1].trim() === "") endIdx = parts.length - 1;
    
    for (var j = startIdx; j < endIdx; j++) {
        [cells addObject:parts[j].trim()];
    }
    return cells;
}

+ (CPAttributedString)parseInlineMarkdown:(CPString)text isHeader:(BOOL)isHeader headerLevel:(int)level
{
    var baseFontSize = 11.0;
    var fontSize = baseFontSize;
    var isBold = isHeader;
    var isItalic = NO;
    
    if (isHeader) {
        if (level == 1) fontSize = 15.0;
        else if (level == 2) fontSize = 13.0;
        else fontSize = 12.0;
    }
    
    var result = [[CPMutableAttributedString alloc] initWithString:@""];
    var currentSegment = "";
    var i = 0;
    var len = text.length;
    
    var defaultFont = [CPFont systemFontOfSize:fontSize];
    if (isBold) {
        defaultFont = [CPFont boldSystemFontOfSize:fontSize];
    }
    
    while (i < len) {
        if (i + 2 < len && text.substr(i, 3) === "***") {
            if (currentSegment.length > 0) {
                [result appendAttributedString:[self attributedStringWithText:currentSegment font:defaultFont bold:isBold italic:isItalic code:NO]];
                currentSegment = "";
            }
            isBold = !isBold;
            isItalic = !isItalic;
            i += 3;
            continue;
        }
        if (i + 1 < len && text.substr(i, 2) === "**") {
            if (currentSegment.length > 0) {
                [result appendAttributedString:[self attributedStringWithText:currentSegment font:defaultFont bold:isBold italic:isItalic code:NO]];
                currentSegment = "";
            }
            isBold = !isBold;
            i += 2;
            continue;
        }
        if (text.charAt(i) === "*") {
            if (currentSegment.length > 0) {
                [result appendAttributedString:[self attributedStringWithText:currentSegment font:defaultFont bold:isBold italic:isItalic code:NO]];
                currentSegment = "";
            }
            isItalic = !isItalic;
            i++;
            continue;
        }
        if (text.charAt(i) === "`") {
            if (currentSegment.length > 0) {
                [result appendAttributedString:[self attributedStringWithText:currentSegment font:defaultFont bold:isBold italic:isItalic code:NO]];
                currentSegment = "";
            }
            var codeText = "";
            i++;
            while (i < len && text.charAt(i) !== "`") {
                codeText += text.charAt(i);
                i++;
            }
            [result appendAttributedString:[self attributedStringWithText:codeText font:defaultFont bold:NO italic:NO code:YES]];
            i++;
            continue;
        }
        
        currentSegment += text.charAt(i);
        i++;
    }
    
    if (currentSegment.length > 0) {
        [result appendAttributedString:[self attributedStringWithText:currentSegment font:defaultFont bold:isBold italic:isItalic code:NO]];
    }
    
    return result;
}

+ (CPAttributedString)attributedStringWithText:(CPString)text font:(CPFont)baseFont bold:(BOOL)b italic:(BOOL)it code:(BOOL)c
{
    var fontName = [baseFont familyName];
    var fontSize = [baseFont size]; 
    var finalFont = baseFont;
    
    if (c) {
        finalFont = [CPFont fontWithName:@"Courier" size:fontSize];
    } else {
        finalFont = [CPFont _fontWithName:fontName size:fontSize bold:b italic:it];
    }
    
    if (!finalFont) {
        finalFont = [CPFont systemFontOfSize:fontSize];
    }
    
    var dict = [CPDictionary dictionaryWithObjectsAndKeys:
        finalFont, CPFontAttributeName,
        [CPColor blackColor], CPForegroundColorAttributeName
    ];
    return [[CPAttributedString alloc] initWithString:text attributes:dict];
}

@end
