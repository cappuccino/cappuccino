@import <AppKit/CPApplication.j>
@import <AppKit/CPTextList.j>
@import <AppKit/CPTextView.j>

@implementation CPTextListTest : OJTestCase
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

- (id)roundTrip:(id)anObject
{
    return [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:anObject]];
}

// MARK: CPTextList

- (void)testBulletMarkers
{
    [self assert:@"•" equals:[[[CPTextList alloc] initWithMarkerFormat:CPTextListMarkerDisc options:0] markerForItemNumber:3]];
    [self assert:@"◦" equals:[[[CPTextList alloc] initWithMarkerFormat:CPTextListMarkerCircle options:0] markerForItemNumber:1]];
    [self assert:@"⁃" equals:[[[CPTextList alloc] initWithMarkerFormat:CPTextListMarkerHyphen options:0] markerForItemNumber:1]];
}

- (void)testOrderedMarkers
{
    [self assert:@"12." equals:[[[CPTextList alloc] initWithMarkerFormat:@"{decimal}." options:0] markerForItemNumber:12]];
    [self assert:@"(c)" equals:[[[CPTextList alloc] initWithMarkerFormat:@"({lower-alpha})" options:0] markerForItemNumber:3]];
    [self assert:@"AA" equals:[[[CPTextList alloc] initWithMarkerFormat:CPTextListMarkerUppercaseAlpha options:0] markerForItemNumber:27]];
    [self assert:@"xiv" equals:[[[CPTextList alloc] initWithMarkerFormat:CPTextListMarkerLowercaseRoman options:0] markerForItemNumber:14]];
    [self assert:@"MCMXCIX" equals:[[[CPTextList alloc] initWithMarkerFormat:CPTextListMarkerUppercaseRoman options:0] markerForItemNumber:1999]];
    [self assert:@"FF" equals:[[[CPTextList alloc] initWithMarkerFormat:CPTextListMarkerUppercaseHexadecimal options:0] markerForItemNumber:255]];
    [self assert:@"17" equals:[[[CPTextList alloc] initWithMarkerFormat:CPTextListMarkerOctal options:0] markerForItemNumber:15]];
}

- (void)testIsOrdered
{
    [self assertFalse:[[[CPTextList alloc] initWithMarkerFormat:CPTextListMarkerSquare options:0] isOrdered]];
    [self assertTrue:[[[CPTextList alloc] initWithMarkerFormat:@"{decimal}." options:0] isOrdered]];
}

- (void)testTextListArchiving
{
    var list = [[CPTextList alloc] initWithMarkerFormat:@"{upper-roman}." options:CPTextListPrependEnclosingMarker startingItemNumber:4],
        decodedList = [self roundTrip:list];

    [self assert:@"{upper-roman}." equals:[decodedList markerFormat]];
    [self assert:CPTextListPrependEnclosingMarker equals:[decodedList listOptions]];
    [self assert:4 equals:[decodedList startingItemNumber]];
}

- (void)testParagraphStyleTextLists
{
    var list = [[CPTextList alloc] initWithMarkerFormat:CPTextListMarkerDisc options:0],
        paragraphStyle = [[CPParagraphStyle defaultParagraphStyle] mutableCopy];

    [self assert:0 equals:[[paragraphStyle textLists] count]];

    [paragraphStyle setTextLists:[list]];
    [self assert:list equals:[[[paragraphStyle copy] textLists] firstObject]];
    [self assertFalse:[paragraphStyle isEqual:[CPParagraphStyle defaultParagraphStyle]] message:@"a paragraph style with a list differs from one without"];
    [self assert:@"{disc}" equals:[[[[self roundTrip:paragraphStyle] textLists] firstObject] markerFormat]];
}

// MARK: CPAttributedString

- (void)testRangeAndItemNumberOfTextList
{
    var outer = [[CPTextList alloc] initWithMarkerFormat:@"{decimal}." options:0],
        inner = [[CPTextList alloc] initWithMarkerFormat:CPTextListMarkerDisc options:0],
        outerStyle = [[CPParagraphStyle defaultParagraphStyle] mutableCopy],
        innerStyle = [[CPParagraphStyle defaultParagraphStyle] mutableCopy],
        string = [[CPAttributedString alloc] initWithString:@"Intro\none\ntwo\nnested\nthree\nEnd"];

    [outerStyle setTextLists:[outer]];
    [innerStyle setTextLists:[outer, inner]];

    [string addAttribute:CPParagraphStyleAttributeName value:outerStyle range:CPMakeRange(6, 8)];
    [string addAttribute:CPParagraphStyleAttributeName value:innerStyle range:CPMakeRange(14, 7)];
    [string addAttribute:CPParagraphStyleAttributeName value:outerStyle range:CPMakeRange(21, 6)];

    var outerRange = [string rangeOfTextList:outer atIndex:15];

    [self assert:6 equals:outerRange.location];
    [self assert:21 equals:outerRange.length];
    [self assert:CPNotFound equals:[string rangeOfTextList:outer atIndex:2].location];

    [self assert:1 equals:[string itemNumberInTextList:outer atIndex:7]];
    [self assert:2 equals:[string itemNumberInTextList:outer atIndex:11]];
    [self assert:3 equals:[string itemNumberInTextList:outer atIndex:23] message:@"nested items do not count in the enclosing list"];
    [self assert:1 equals:[string itemNumberInTextList:inner atIndex:16]];
}

// MARK: CPTextView

- (void)testSetTextListAddsAndRemovesMarkers
{
    [textView setString:@"one\ntwo"];
    [textView setSelectedRange:CPMakeRange(0, 7)];
    [textView setTextList:[[CPTextList alloc] initWithMarkerFormat:@"{decimal}." options:0]];

    [self assert:@"\t1.\tone\n\t2.\ttwo" equals:[textView string]];
    [self assert:36.0 equals:[[[textView textStorage] attribute:CPParagraphStyleAttributeName atIndex:0 effectiveRange:nil] headIndent]];

    [textView setSelectedRange:CPMakeRange(0, [[textView string] length])];
    [textView setTextList:nil];

    [self assert:@"one\ntwo" equals:[textView string]];
}

- (void)testNewlineContinuesAndEndsList
{
    [textView setString:@"one"];
    [textView setSelectedRange:CPMakeRange(3, 0)];
    [textView setTextList:[[CPTextList alloc] initWithMarkerFormat:@"{decimal}." options:0]];

    [textView setSelectedRange:CPMakeRange([[textView string] length], 0)];
    [textView insertNewline:nil];
    [textView insertText:@"two"];

    [self assert:@"\t1.\tone\n\t2.\ttwo" equals:[textView string]];

    [textView insertNewline:nil];
    [textView insertNewline:nil];

    [self assert:@"\t1.\tone\n\t2.\ttwo\n" equals:[textView string] message:@"Return in an empty item ends the list"];
}

- (void)testTabNestsAndBacktabReturnsItem
{
    [textView setString:@"one\ntwo\nthree"];
    [textView setSelectedRange:CPMakeRange(0, 13)];
    [textView setTextList:[[CPTextList alloc] initWithMarkerFormat:@"{decimal}." options:0]];

    // The insertion point at the start of the second item's text.
    var secondItemText = [[textView string] rangeOfString:@"two"].location;

    [textView setSelectedRange:CPMakeRange(secondItemText, 0)];
    [textView insertTab:nil];

    [self assert:@"\t1.\tone\n\t1.\ttwo\n\t2.\tthree" equals:[textView string]];
    [self assert:2 equals:[[[[textView textStorage] attribute:CPParagraphStyleAttributeName atIndex:secondItemText effectiveRange:nil] textLists] count]];

    [textView insertBacktab:nil];

    [self assert:@"\t1.\tone\n\t2.\ttwo\n\t3.\tthree" equals:[textView string]];
}

- (void)testDeleteBackwardAtItemStartRemovesItem
{
    [textView setString:@"one\ntwo"];
    [textView setSelectedRange:CPMakeRange(0, 7)];
    [textView setTextList:[[CPTextList alloc] initWithMarkerFormat:@"{decimal}." options:0]];

    [textView setSelectedRange:CPMakeRange([[textView string] rangeOfString:@"one"].location, 0)];
    [textView deleteBackward:nil];

    [self assert:@"one\n\t1.\ttwo" equals:[textView string] message:@"the remaining item is numbered again"];
}

- (void)testPrependEnclosingMarker
{
    [textView setString:@"one\ntwo"];
    [textView setSelectedRange:CPMakeRange(0, 7)];
    [textView setTextList:[[CPTextList alloc] initWithMarkerFormat:@"{decimal}." options:CPTextListPrependEnclosingMarker]];

    [textView setSelectedRange:CPMakeRange([[textView string] rangeOfString:@"two"].location, 0)];
    [textView insertTab:nil];

    [self assert:@"\t1.\tone\n\t1.1.\ttwo" equals:[textView string]];
}

- (void)testPasteRulerAddsAndRemovesMarkers
{
    [textView setString:@"one\ntwo\nthree"];
    [textView setSelectedRange:CPMakeRange(0, 0)];
    [textView setTextList:[[CPTextList alloc] initWithMarkerFormat:@"{decimal}." options:0]];

    // Copy the first item's ruler and paste it on the next paragraph, which joins the list.
    [textView setSelectedRange:CPMakeRange(5, 0)];
    [textView copyRuler:nil];
    [textView setSelectedRange:CPMakeRange([[textView string] rangeOfString:@"two"].location, 0)];
    [textView pasteRuler:nil];

    [self assert:@"\t1.\tone\n\t2.\ttwo\nthree" equals:[textView string]];

    // Copy the plain paragraph's ruler and paste it on the first item, which leaves the list.
    [textView setSelectedRange:CPMakeRange([[textView string] length], 0)];
    [textView copyRuler:nil];
    [textView setSelectedRange:CPMakeRange(5, 0)];
    [textView pasteRuler:nil];

    [self assert:@"one\n\t1.\ttwo\nthree" equals:[textView string]];
}

- (void)testChangeTextListFromMenuItem
{
    var numberedItem = [[CPMenuItem alloc] initWithTitle:@"1. 2. 3." action:@selector(changeTextList:) keyEquivalent:@""],
        noneItem = [[CPMenuItem alloc] initWithTitle:@"None" action:@selector(changeTextList:) keyEquivalent:@""];

    [numberedItem setTag:10];

    [textView setString:@"one\ntwo"];
    [textView setSelectedRange:CPMakeRange(0, 0)];

    [self assertTrue:[textView validateUserInterfaceItem:noneItem]];
    [self assert:CPOnState equals:[noneItem state]];

    [textView changeTextList:numberedItem];
    [self assert:@"\t1.\tone\ntwo" equals:[textView string]];

    [textView validateUserInterfaceItem:numberedItem];
    [textView validateUserInterfaceItem:noneItem];
    [self assert:CPOnState equals:[numberedItem state]];
    [self assert:CPOffState equals:[noneItem state]];

    // The next paragraph joins the list above it, so its numbering continues.
    [textView setSelectedRange:CPMakeRange([[textView string] length], 0)];
    [textView changeTextList:numberedItem];
    [self assert:@"\t1.\tone\n\t2.\ttwo" equals:[textView string]];

    [textView setRichText:NO];
    [self assertFalse:[textView validateUserInterfaceItem:numberedItem]];
}

@end
