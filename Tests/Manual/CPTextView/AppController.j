/*
 * AppController.j
 *
 *  Manual test application for the cappuccino text system
 *  Copyright (C) 2014 Daniel Boehringer
 */

@import <Foundation/Foundation.j>
@import <AppKit/CPTextView.j>
@import <AppKit/CPFontPanel.j>
@import <AppKit/CPRulerView.j>
@import <AppKit/CPSplitView.j>
@import <AppKit/CPButton.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPScrollView.j>
@import <AppKit/CPParagraphStyle.j>
@import <AppKit/CPTextStorage.j>
@import <AppKit/_CPTableTextAttachment.j>

@implementation AppController : CPObject
{
    CPTextView      _textView;
    CPTextView      _textView2;
    CPScrollView    _scrollView;
    CPScrollView    _scrollView2;
}

- (void)openSheet:(id)sender
{
    var plusPopover = [CPPopover new];
    [plusPopover setDelegate:self];
    [plusPopover setAnimates:NO];
    [plusPopover setBehavior:CPPopoverBehaviorTransient];
    [plusPopover setAppearance:CPPopoverAppearanceMinimal];
    
    var myViewController = [CPViewController new];
    [plusPopover setContentViewController:myViewController];
    
    var textView = [[CPTextView alloc] initWithFrame:CGRectMake(0, 0, 200, 10)];
    [textView setBackgroundColor:[CPColor whiteColor]];
    
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, 200, 150)];
    [scrollView setDocumentView:textView];
    
    [myViewController setView:scrollView];
    [plusPopover showRelativeToRect:NULL ofView:sender preferredEdge:nil];
    [[textView window] makeFirstResponder:textView];
}

- (void)orderFrontFontPanel:(id)sender
{
   [[CPFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (void)toggleRuler:(id)sender
{
    [_scrollView setRulersVisible:![_scrollView rulersVisible]];
}

- (void)alignLeft:(id)sender
{
    [_textView alignLeft:self];
}

- (void)alignCenter:(id)sender
{
    [_textView alignCenter:self];
}

- (void)alignRight:(id)sender
{
    [_textView alignRight:self];
}

- (void)alignJustified:(id)sender
{
    [_textView alignJustified:self];
}

- (void)insertAttachment:(id)sender
{
    // Insert modern spinner image attachment
    var tempImageView = [[CPImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [tempImageView setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/spinner.gif" size:CGSizeMake(32, 32)]];
    [_textView insertText:[CPTextStorage attributedStringWithAttachment:tempImageView]];
    [_textView insertText:@" "];

    // Insert an interactive button attachment
    var tempButton = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, 80, 28)];
    [tempButton setTitle:@"Click Me"];
    [_textView insertText:[CPTextStorage attributedStringWithAttachment:tempButton]];
    [_textView insertText:@" "];
}

- (void)insertTable:(id)sender
{
    var headers = [@"Item Description", @"Quantity", @"Unit Price"];
    var rows = [
        [@"Cappuccino Web Framework Lic.", @"2", @"$199.00"],
        [@"Objective-J Development Support", @"5", @"$150.00"],
        [@"Cloud Compilation VM Server", @"1", @"$49.00"]
    ];
    
    var tableAttachment = [[_CPTableTextAttachment alloc] initWithHeaders:headers rows:rows width:500.0];
    
    // Insert single-character atomic text attachment
    var tableAttrStr = [CPTextStorage attributedStringWithAttachment:tableAttachment];

    [_textView insertText:@"\ntable (own line)\n"];
    [_textView insertText:tableAttrStr];
    [_textView insertText:@"\nend table"];
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    [contentView setBackgroundColor:[CPColor colorWithWhite:0.95 alpha:1.0]];

    // 1. Clean visual header / toolbar area
    var toolbarView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([contentView bounds]), 60)];
    [toolbarView setAutoresizingMask:CPViewWidthSizable];
    [toolbarView setBackgroundColor:[CPColor colorWithWhite:0.88 alpha:1.0]];
    [contentView addSubview:toolbarView];

    var currentX = 15;

    // Popover Trigger
    var sheetButton = [[CPButton alloc] initWithFrame:CGRectMake(currentX, 15, 145, 30)];
    [sheetButton setTitle:@"Open Popover Sheet"];
    [sheetButton setTarget:self];
    [sheetButton setAction:@selector(openSheet:)];
    [toolbarView addSubview:sheetButton];
    currentX += 155;

    // Font Panel Trigger
    var fontButton = [[CPButton alloc] initWithFrame:CGRectMake(currentX, 15, 125, 30)];
    [fontButton setTitle:@"Show Font Panel"];
    [fontButton setTarget:self];
    [fontButton setAction:@selector(orderFrontFontPanel:)];
    [toolbarView addSubview:fontButton];
    currentX += 135;

    // Toggle Ruler Trigger
    var rulerButton = [[CPButton alloc] initWithFrame:CGRectMake(currentX, 15, 120, 30)];
    [rulerButton setTitle:@"Toggle Ruler"];
    [rulerButton setTarget:self];
    [rulerButton setAction:@selector(toggleRuler:)];
    [toolbarView addSubview:rulerButton];
    currentX += 130;

    // RTF Roundtrip Trigger
    var rtfButton = [[CPButton alloc] initWithFrame:CGRectMake(currentX, 15, 150, 30)];
    [rtfButton setTitle:@"RTF Round-trip ➔"];
    [rtfButton setTarget:self];
    [rtfButton setAction:@selector(makeRTF:)];
    [toolbarView addSubview:rtfButton];
    currentX += 160;

    // Insert Attachment Trigger
    var attachButton = [[CPButton alloc] initWithFrame:CGRectMake(currentX, 15, 140, 30)];
    [attachButton setTitle:@"Insert Attachment"];
    [attachButton setTarget:self];
    [attachButton setAction:@selector(insertAttachment:)];
    [toolbarView addSubview:attachButton];
    currentX += 150;

    // Add Table Trigger
    var tableButton = [[CPButton alloc] initWithFrame:CGRectMake(currentX, 15, 100, 30)];
    [tableButton setTitle:@"Add Table"];
    [tableButton setTarget:self];
    [tableButton setAction:@selector(insertTable:)];
    [toolbarView addSubview:tableButton];
    currentX += 110;

    // Text Alignment Group
    var labelAlign = [[CPTextField alloc] initWithFrame:CGRectMake(currentX, 22, 45, 20)];
    [labelAlign setStringValue:@"Align:"];
    [labelAlign setFont:[CPFont systemFontOfSize:12]];
    [toolbarView addSubview:labelAlign];
    currentX += 45;

    var alignLeftBtn = [[CPButton alloc] initWithFrame:CGRectMake(currentX, 15, 50, 30)];
    [alignLeftBtn setTitle:@"Left"];
    [alignLeftBtn setTarget:self];
    [alignLeftBtn setAction:@selector(alignLeft:)];
    [toolbarView addSubview:alignLeftBtn];
    currentX += 55;

    var alignCenterBtn = [[CPButton alloc] initWithFrame:CGRectMake(currentX, 15, 60, 30)];
    [alignCenterBtn setTitle:@"Center"];
    [alignCenterBtn setTarget:self];
    [alignCenterBtn setAction:@selector(alignCenter:)];
    [toolbarView addSubview:alignCenterBtn];
    currentX += 65;

    var alignRightBtn = [[CPButton alloc] initWithFrame:CGRectMake(currentX, 15, 55, 30)];
    [alignRightBtn setTitle:@"Right"];
    [alignRightBtn setTarget:self];
    [alignRightBtn setAction:@selector(alignRight:)];
    [toolbarView addSubview:alignRightBtn];
    currentX += 60;

    var alignJustifyBtn = [[CPButton alloc] initWithFrame:CGRectMake(currentX, 15, 65, 30)];
    [alignJustifyBtn setTitle:@"Justify"];
    [alignJustifyBtn setTarget:self];
    [alignJustifyBtn setAction:@selector(alignJustified:)];
    [toolbarView addSubview:alignJustifyBtn];

    // Default return key target test
    var returnButton = [[CPButton alloc] initWithFrame:CGRectMake(CGRectGetWidth([contentView bounds]) - 270, 15, 250, 30)];
    [returnButton setAutoresizingMask:CPViewMinXMargin];
    [returnButton setTitle:@"Key Return Target"];
    [returnButton setTarget:self];
    [returnButton setAction:@selector(openSheet:)];
    [returnButton setKeyEquivalent:@"\r"];
    [toolbarView addSubview:returnButton];

    // 2. Main content area: Split View Layout for side-by-side comparison
    var splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0, 60, CGRectGetWidth([contentView bounds]), CGRectGetHeight([contentView bounds]) - 60)];
    [splitView setVertical:YES];
    [splitView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    
    var leftContainer = [[CPView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([splitView bounds]) / 2, CGRectGetHeight([splitView bounds]))];
    [leftContainer setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    
    var rightContainer = [[CPView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([splitView bounds]) / 2, CGRectGetHeight([splitView bounds]))];
    [rightContainer setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    
    [splitView addSubview:leftContainer];
    [splitView addSubview:rightContainer];
    [contentView addSubview:splitView];

    // Left Container: label & Scroll/TextView containing Ruler
    var leftLabel = [[CPTextField alloc] initWithFrame:CGRectMake(15, 10, CGRectGetWidth([leftContainer bounds]) - 30, 20)];
    [leftLabel setStringValue:@"Rich Text Editor"];
    [leftLabel setFont:[CPFont boldSystemFontOfSize:14]];
    [leftLabel setAutoresizingMask:CPViewWidthSizable];
    [leftContainer addSubview:leftLabel];

    _textView = [[CPTextView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([leftContainer bounds]) - 30, 0)];
    [_textView setRichText:YES];
    [_textView setBackgroundColor:[CPColor whiteColor]];
    [[_textView textContainer] setWidthTracksTextView:YES];

    _scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(15, 40, CGRectGetWidth([leftContainer bounds]) - 30, CGRectGetHeight([leftContainer bounds]) - 65)];
    [_scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_scrollView setDocumentView:_textView];

    // ATTACH THE NEW CPRULERVIEW SYSTEM
    [_scrollView setHasHorizontalRuler:YES];
    [_scrollView setRulersVisible:YES];
    [leftContainer addSubview:_scrollView];

    // Right Container: RTF Plain-Text Source and Parser Window
    var rightLabel = [[CPTextField alloc] initWithFrame:CGRectMake(15, 10, CGRectGetWidth([rightContainer bounds]) - 30, 20)];
    [rightLabel setStringValue:@"RTF Raw Output & Source Parser Window"];
    [rightLabel setFont:[CPFont boldSystemFontOfSize:14]];
    [rightLabel setAutoresizingMask:CPViewWidthSizable];
    [rightContainer addSubview:rightLabel];

    _textView2 = [[CPTextView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([rightContainer bounds]) - 30, CGRectGetHeight([rightContainer bounds]) - 70)];
    _textView2._isRichText = NO;
    [_textView2 setBackgroundColor:[CPColor whiteColor]];

    _scrollView2 = [[CPScrollView alloc] initWithFrame:CGRectMake(15, 40, CGRectGetWidth([rightContainer bounds]) - 30, CGRectGetHeight([rightContainer bounds]) - 65)];
    [_scrollView2 setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_scrollView2 setDocumentView:_textView2];
    [rightContainer addSubview:_scrollView2];

    // 3. Build application Main Menu
    var mainMenu = [CPApp mainMenu];

    while ([mainMenu numberOfItems] > 0)
        [mainMenu removeItemAtIndex:0];

    var item = [mainMenu insertItemWithTitle:@"Edit" action:nil keyEquivalent:nil atIndex:0],
        editMenu = [[CPMenu alloc] initWithTitle:@"Edit Menu"];

    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Delete" action:@selector(delete:) keyEquivalent:@""];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    [editMenu addItemWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@"Z"];
    [mainMenu setSubmenu:editMenu forItem:item];

    item = [mainMenu insertItemWithTitle:@"Format" action:nil keyEquivalent:nil atIndex:0];
    // Format Menu
    item = [mainMenu insertItemWithTitle:@"Format" action:nil keyEquivalent:nil atIndex:0];
    var formatMenu = [[CPMenu alloc] initWithTitle:@"Format Menu"];
    
    [formatMenu addItemWithTitle:@"Font panel" action:@selector(orderFrontFontPanel:) keyEquivalent:@"t"];
    [formatMenu addItem:[CPMenuItem separatorItem]];
    // Styles
    [formatMenu addItemWithTitle:@"Bold" action:@selector(bold:) keyEquivalent:@"b"];
    [formatMenu addItemWithTitle:@"Italic" action:@selector(italic:) keyEquivalent:@"i"];
    [formatMenu addItemWithTitle:@"Underline" action:@selector(underline:) keyEquivalent:@"u"];
    [formatMenu addItem:[CPMenuItem separatorItem]];
    // Alignment
    [formatMenu addItemWithTitle:@"Align Left" action:@selector(alignLeft:) keyEquivalent:@"{"];
    [formatMenu addItemWithTitle:@"Center" action:@selector(alignCenter:) keyEquivalent:@"|"];
    [formatMenu addItemWithTitle:@"Align Right" action:@selector(alignRight:) keyEquivalent:@"}"];
    [formatMenu addItemWithTitle:@"Justify" action:@selector(alignJustified:) keyEquivalent:@""];
    [mainMenu setSubmenu:formatMenu forItem:item];

    // 4. Load Rich Sample Text content
    [_textView insertText:@"123 456 "];

    // Elegant Slate-Blue & Soft Light Blue paragraph
    var centeredParagraph = [CPMutableParagraphStyle new];
    [centeredParagraph setAlignment:CPCenterTextAlignment];
    [_textView insertText:@"\n"];
    
    var elegantForeground = [CPColor colorWithRed:0.18 green:0.24 blue:0.35 alpha:1.0]; // Slate Blue
    var elegantBackground = [CPColor colorWithRed:0.92 green:0.95 blue:0.98 alpha:1.0]; // Soft Sky Blue tint
    
    [_textView insertText:[[CPAttributedString alloc] initWithString:@"My Headline with blue background\n"
                                                          attributes:[CPDictionary dictionaryWithObjects:[centeredParagraph, [CPFont boldFontWithName:@"Arial" size:18], elegantForeground, elegantBackground]
                                                                                                 forKeys:[CPParagraphStyleAttributeName, CPFontAttributeName, CPForegroundColorAttributeName, CPBackgroundColorAttributeName]]]];

    // Highlighted Heading - Pine & Sage Green tones
    [_textView insertText:@"\n"];
    var showcaseForeground = [CPColor colorWithRed:0.15 green:0.25 blue:0.15 alpha:1.0]; // Forest Green
    var showcaseBackground = [CPColor colorWithRed:0.94 green:0.97 blue:0.92 alpha:1.0]; // Light Sage Green
    
    [_textView insertText:[[CPAttributedString alloc] initWithString:@"Interactive Ruler Showcase\n"
                                                          attributes:[CPDictionary dictionaryWithObjects:[[CPFont boldFontWithName:@"Arial" size:22], showcaseForeground, showcaseBackground]
                                                                                                 forKeys:[CPFontAttributeName, CPForegroundColorAttributeName, CPBackgroundColorAttributeName]]]];

    // DEMONSTRATION OF CPRULERVIEW TAB MARKERS
    var tabParagraph = [[CPParagraphStyle defaultParagraphStyle] mutableCopy];
    var tab1 = [[CPTextTab alloc] initWithType:CPLeftTextAlignment location:100.0];
    var tab2 = [[CPTextTab alloc] initWithType:CPCenterTextAlignment location:220.0];
    var tab3 = [[CPTextTab alloc] initWithType:CPRightTextAlignment location:340.0];
    [tabParagraph setTabStops:[tab1, tab2, tab3]];

    [_textView insertText:@"\n"];
    [_textView insertText:[[CPAttributedString alloc] initWithString:@"\tTab1\tTab2\tTab3\n\tLeftAlign\tCenterAlign\tRightAlign\n"
                                                      attributes:[CPDictionary dictionaryWithObject:tabParagraph forKey:CPParagraphStyleAttributeName]]];

    // DEMONSTRATION OF INDENTATION MARKERS
    var indentParagraph = [[CPParagraphStyle defaultParagraphStyle] mutableCopy];
    [indentParagraph setFirstLineHeadIndent:30.0];
    [indentParagraph setHeadIndent:50.0];
    [indentParagraph setTailIndent:-30.0];

    [_textView insertText:@"\n"];
    [_textView insertText:[[CPAttributedString alloc] initWithString:@"This paragraph has a first-line indent of 30pt, a head indent of 50pt, and a tail indent of -30pt. Check the horizontal ruler above to see how the indent markers align with this paragraph, and adjust them directly!\n"
                                                          attributes:[CPDictionary dictionaryWithObject:indentParagraph forKey:CPParagraphStyleAttributeName]]];

    [_textView insertText:@"\n"];

    [theWindow orderFront:self];
    [CPMenu setMenuBarVisible:YES];
}

- (void)makeRTF:(id)sender
{
    [_textView2 setString: [_CPRTFProducer produceRTF:[_textView textStorage] documentAttributes: @{}] ];
    var tc = [_CPRTFParser new];
    var mystr=[tc parseRTF:[_textView2 stringValue]];
    [_textView selectAll: self];
    [_textView insertText: mystr];
}

@end
