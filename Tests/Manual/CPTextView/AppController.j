/*
 * AppController.j
 *
 *  Manual test application for the cappuccino text system 
 *  Copyright (C) 2014 Daniel Boehringer
 */
 
@import <AppKit/CPTextView.j>
@import <AppKit/_CPRTFProducer.j>
@import <AppKit/_CPRTFParser.j>

@implementation AppController : CPObject
{
    CPTextView  _textView;
    CPTextView  _textView2;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
   // CPLogRegister(CPLogConsole);

    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];
    
    [contentView setBackgroundColor:[CPColor colorWithWhite:0.95 alpha:1.0]];

    _textView = [[CPTextView alloc] initWithFrame:CGRectMake(0,0,500,500)];
    _textView2 = [[CPTextView alloc] initWithFrame:CGRectMake(0,0,500,500)];
    _textView2._isRichText = NO;
    [_textView setBackgroundColor:[CPColor whiteColor]];
    [_textView2 setBackgroundColor:[CPColor whiteColor]];

    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(20, 20,520,510)];
    var scrollView2 = [[CPScrollView alloc] initWithFrame:CGRectMake(560, 20,520,510)];
    //  [scrollView setAutohidesScrollers:YES];
    [scrollView setDocumentView:_textView]; 
    [scrollView2 setDocumentView:_textView2];

    [contentView addSubview: scrollView];
    [contentView addSubview: scrollView2];

   [_textView setDelegate:self];

    /* build our menu */
    var mainMenu = [CPApp mainMenu];

    while ([mainMenu numberOfItems] > 0)
        [mainMenu removeItemAtIndex:0];

    var item = [mainMenu insertItemWithTitle:@"Edit" action:nil keyEquivalent:nil atIndex:0],
        editMenu = [[CPMenu alloc] initWithTitle:@"Edit Menu"];
 
   [_textView2 insertText:"RTF goes here"];

    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Delete" action:@selector(delete:) keyEquivalent:@""];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    [editMenu addItemWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@"Z"];

    [mainMenu setSubmenu:editMenu forItem:item];

    item = [mainMenu insertItemWithTitle:@"Font" action:@selector(orderFrontFontPanel:) keyEquivalent:nil atIndex:1];    
    item = [mainMenu insertItemWithTitle:@"RTFRoundtrip" action:@selector(makeRTF:) keyEquivalent:nil atIndex:1];    

    var centeredParagraph=[CPParagraphStyle new];
    [centeredParagraph setAlignment: CPCenterTextAlignment];
    [_textView insertText:[[CPAttributedString alloc] initWithString:@"Fusce\n"
               attributes:[CPDictionary dictionaryWithObjects:[centeredParagraph, [CPFont boldFontWithName:"Arial" size:18], [CPColor redColor]]
                                        forKeys:[CPParagraphStyleAttributeName, CPFontAttributeName, CPForegroundColorAttributeName]]]];

    [_textView insertText: [[CPAttributedString alloc] initWithString:@"lectus neque cr     as eget lectus neque cr as eget lectus cr as eget lectus" 
                attributes:[CPDictionary dictionaryWithObjects:[ [CPFont fontWithName:"Arial" size:12]] forKeys: [CPFontAttributeName]]]];

    [_textView insertText:[[CPAttributedString alloc] initWithString:@" proin, this is text in boldface " 
                attributes:[CPDictionary dictionaryWithObjects:[ [CPFont boldFontWithName:"Arial" size:12]] forKeys: [CPFontAttributeName]]]];
    [_textView insertText:[[CPAttributedString alloc] initWithString:@"111111 neque cr as eget lectus neque cr as eget lectus cr as eget lectus" 
                attributes:[CPDictionary dictionaryWithObjects:[ [CPFont fontWithName:"Arial" size:12.0]] forKeys: [CPFontAttributeName]]]];

    [theWindow orderFront:self];
    [CPMenu setMenuBarVisible:YES];
}

//-> CPApplication (?)
- (void)orderFrontFontPanel:sender
{
   [[CPFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (void) makeRTF:sender
{
   [_textView2 setString: [_CPRTFProducer produceRTF:[_textView textStorage] documentAttributes: @{}] ];
   var tc = [_CPRTFParser new];
   var mystr=[tc parseRTF:[_textView2 stringValue]];
   [_textView selectAll: self];
   [_textView insertText: mystr];

}

@end
