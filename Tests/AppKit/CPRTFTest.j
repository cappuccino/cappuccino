@import <AppKit/CPApplication.j>
@import <AppKit/CPTextView.j>

@implementation CPRTFTest : OJTestCase
{
    CPWindow    theWindow;
    CPTextView  textView;
}

- (void)setUp
{
    [[CPApplication alloc] init];

    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 1024.0, 768.0) styleMask:CPWindowNotSizable];
    textView = [[CPTextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 300.0)];

    [textView setRichText:YES];
    [[theWindow contentView] addSubview:textView];
    [theWindow makeFirstResponder:textView];
}

- (CPAttributedString)roundTrip:(CPAttributedString)aString
{
    var rtf = [_CPRTFProducer produceRTF:aString documentAttributes:@{}];

    return [[_CPRTFParser new] parseRTF:rtf];
}

- (CPArray)textListsAtIndex:(unsigned)anIndex ofString:(CPAttributedString)aString
{
    return [[aString attribute:CPParagraphStyleAttributeName atIndex:anIndex effectiveRange:nil] textLists];
}

// MARK: Unicode

- (void)testUnicodeIsEscapedAndRead
{
    var text = @"Café — “quoted” •",
        rtf = [_CPRTFProducer produceRTF:[[CPAttributedString alloc] initWithString:text] documentAttributes:@{}];

    [self assertTrue:rtf.indexOf("\\u8212 ") !== -1 message:@"an em dash is written as \\u8212"];
    [self assertTrue:/^[\x00-\x7f]*$/.test(rtf) message:@"the RTF holds only ASCII"];
    [self assert:text equals:[[[_CPRTFParser new] parseRTF:rtf] string]];
}

- (void)testUnicodeFallbackCharactersAreSkipped
{
    var parsed = [[_CPRTFParser new] parseRTF:@"{\\rtf1\\ansi\\uc1 a\\u8212?b \\uc0\\u8211 c}"];

    [self assert:@"a—b –c" equals:[parsed string]];
}

// MARK: Indents

- (void)testFirstLineIndentIsRelativeToTheLeftIndent
{
    var parsed = [[_CPRTFParser new] parseRTF:@"{\\rtf1\\ansi\\pard\\li720\\fi-720 text}"],
        paragraphStyle = [parsed attribute:CPParagraphStyleAttributeName atIndex:0 effectiveRange:nil];

    [self assert:36.0 equals:[paragraphStyle headIndent]];
    [self assert:0.0 equals:[paragraphStyle firstLineHeadIndent]];

    var style = [[CPParagraphStyle defaultParagraphStyle] mutableCopy];

    [style setHeadIndent:36.0];
    [style setFirstLineHeadIndent:18.0];

    var roundTripped = [self roundTrip:[[CPAttributedString alloc] initWithString:@"text" attributes:@{CPParagraphStyleAttributeName: style}]],
        roundTrippedStyle = [roundTripped attribute:CPParagraphStyleAttributeName atIndex:0 effectiveRange:nil];

    [self assert:36.0 equals:[roundTrippedStyle headIndent]];
    [self assert:18.0 equals:[roundTrippedStyle firstLineHeadIndent]];
}

// MARK: Lists

- (void)testListFromTextEdit
{
    var rtf = @"{\\rtf1\\ansi\\ansicpg1252\\cocoartf2822\n" +
              @"{\\fonttbl\\f0\\fswiss\\fcharset0 Helvetica;}\n" +
              @"{\\colortbl;\\red255\\green255\\blue255;}\n" +
              @"{\\*\\expandedcolortbl;;}\n" +
              @"{\\*\\listtable{\\list\\listtemplateid1\\listhybrid{\\listlevel\\levelnfc23\\levelnfcn23\\leveljc0\\leveljcn0\\levelfollow0\\levelstartat1\\levelspace360\\levelindent0{\\*\\levelmarker \\{disc\\}}{\\leveltext\\leveltemplateid1\\'01\\uc0\\u8226 ;}{\\levelnumbers;}\\fi-360\\li720\\lin720 }{\\listname ;}\\listid1}}\n" +
              @"{\\*\\listoverridetable{\\listoverride\\listid1\\listoverridecount0\\ls1}}\n" +
              @"\\pard\\tx220\\tx720\\li720\\fi-720\\pardirnatural\\partightenfactor0\n" +
              @"\\ls1\\ilvl0\n" +
              @"\\f0\\fs24 \\cf0 {\\listtext\t\\uc0\\u8226 \t}one\\\n" +
              @"{\\listtext\t\\uc0\\u8226 \t}two}",
        parsed = [[_CPRTFParser new] parseRTF:rtf],
        firstLists = [self textListsAtIndex:0 ofString:parsed],
        secondLists = [self textListsAtIndex:[[parsed string] length] - 1 ofString:parsed];

    [self assert:@"\t•\tone\n\t•\ttwo" equals:[parsed string]];
    [self assert:1 equals:[firstLists count]];
    [self assert:@"{disc}" equals:[firstLists[0] markerFormat]];
    [self assert:firstLists[0] equals:secondLists[0] message:@"the items of one RTF list share one text list"];
    [self assert:0.0 equals:[[parsed attribute:CPParagraphStyleAttributeName atIndex:0 effectiveRange:nil] firstLineHeadIndent]];
}

- (void)testListFromLevelTextWithoutMarkerFormat
{
    var rtf = @"{\\rtf1\\ansi{\\*\\listtable{\\list\\listtemplateid1{\\listlevel\\levelnfc4\\levelstartat3{\\leveltext\\'03(\\'00);}{\\levelnumbers\\'02;}}{\\listlevel\\levelnfc0{\\leveltext\\'03\\'00.\\'01;}{\\levelnumbers\\'01\\'03;}}\\listid7}}" +
              @"{\\*\\listoverridetable{\\listoverride\\listid7\\listoverridecount0\\ls2}}" +
              @"\\pard\\ls2\\ilvl1 item}",
        lists = [self textListsAtIndex:0 ofString:[[_CPRTFParser new] parseRTF:rtf]];

    [self assert:2 equals:[lists count]];
    [self assert:@"({lower-alpha})" equals:[lists[0] markerFormat]];
    [self assert:3 equals:[lists[0] startingItemNumber]];
    [self assert:@"{decimal}" equals:[lists[1] markerFormat]];
    [self assertTrue:([lists[1] listOptions] & CPTextListPrependEnclosingMarker) message:@"a level text with the enclosing number prepends it"];
}

- (void)testNestedListRoundTrip
{
    [textView setString:@"one\ntwo\nthree"];
    [textView setSelectedRange:CPMakeRange(0, 13)];
    [textView setTextList:[[CPTextList alloc] initWithMarkerFormat:@"{decimal}." options:CPTextListPrependEnclosingMarker]];
    [textView setSelectedRange:CPMakeRange([[textView string] rangeOfString:@"two"].location, 0)];
    [textView insertTab:nil];

    var original = [textView textStorage],
        rtf = [_CPRTFProducer produceRTF:original documentAttributes:@{}],
        parsed = [[_CPRTFParser new] parseRTF:rtf],
        nestedIndex = [[parsed string] rangeOfString:@"two"].location,
        nestedLists = [self textListsAtIndex:nestedIndex ofString:parsed];

    [self assertTrue:rtf.indexOf("{\\listtext ") !== -1 message:@"markers are written in \\listtext groups"];
    [self assertTrue:rtf.indexOf("\\levelprepend") !== -1];
    [self assert:[original string] equals:[parsed string]];
    [self assert:2 equals:[nestedLists count]];
    [self assert:@"{decimal}." equals:[nestedLists[1] markerFormat]];
    [self assertTrue:([nestedLists[1] listOptions] & CPTextListPrependEnclosingMarker)];
    [self assert:nestedLists[0] equals:[self textListsAtIndex:0 ofString:parsed][0] message:@"the nested item stays in the outer list"];
    [self assert:36.0 equals:[[parsed attribute:CPParagraphStyleAttributeName atIndex:0 effectiveRange:nil] headIndent]];
}

@end
