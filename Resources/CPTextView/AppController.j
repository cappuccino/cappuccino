/*
 * AppController.j
 *
 *  Manual test application for the cappuccino text system
 *  Copyright (C) 2014 Daniel Boehringer
 */

@import <Foundation/Foundation.j>
@import <AppKit/CPTextView.j>
@import <AppKit/CPFontPanel.j>

@implementation AppController : CPObject
{
    CPTextView  _textView;
    CPTextView  _textView2;
}



- (void) openSheet:(id)sender
{
    var plusPopover =[CPPopover new];
    [plusPopover setDelegate:self];
    [plusPopover setAnimates:NO];
    [plusPopover setBehavior:CPPopoverBehaviorTransient];
    [plusPopover setAppearance:CPPopoverAppearanceMinimal];
    var myViewController=[CPViewController new];
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

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
   // CPLogRegister(CPLogConsole);

    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    [contentView setBackgroundColor:[CPColor colorWithWhite:0.95 alpha:1.0]];

    var mybutton=[[CPButton alloc] initWithFrame:CGRectMake(0, 0, 250, 25)];
    [mybutton setTitle:"Open sheet (must not be triggered by return)"]
    [mybutton setTarget:self];
    [mybutton setAction:@selector(openSheet:)];
    [mybutton setKeyEquivalent:@"\r"];

    [contentView addSubview:mybutton];


    _textView = [[CPTextView alloc] initWithFrame:CGRectMake(0, 0, 500, 200)];
    [_textView setRichText:YES];

    _textView2 = [[CPTextView alloc] initWithFrame:CGRectMake(0, 0, 1000, 200)];
    _textView2._isRichText = NO;
    [_textView setBackgroundColor:[CPColor whiteColor]];
    [_textView2 setBackgroundColor:[CPColor whiteColor]];

    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(20, 70, 520, 220)];
    var scrollView2 = [[CPScrollView alloc] initWithFrame:CGRectMake(20, 550, 1020, 220)];

    [scrollView setDocumentView:_textView];
    [scrollView2 setDocumentView:_textView2];

    [contentView addSubview: scrollView];
    [contentView addSubview: scrollView2];

    // build our menu
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
   var formatMenu = [[CPMenu alloc] initWithTitle:@"Format Menu"];
   [formatMenu addItemWithTitle:@"Font panel" action:@selector(orderFrontFontPanel:) keyEquivalent:@"f"];
   [formatMenu addItemWithTitle:@"Underline" action:@selector(underline:) keyEquivalent:@"u"];
   [mainMenu setSubmenu:formatMenu forItem:item];

    [_textView insertText:"123"];
    var tempImageView = [[CPImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [tempImageView setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/spinner.gif" size:CGSizeMake(32, 32)]]

    [_textView insertText:[CPTextStorage attributedStringWithAttachment:tempImageView]];
    [_textView insertText:" 456 "];

    var tempButton = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, 64, 28)]
    [_textView insertText:[CPTextStorage attributedStringWithAttachment:tempButton]];

    var centeredParagraph=[CPParagraphStyle new];
    [centeredParagraph setAlignment: CPCenterTextAlignment];
    [_textView insertText:"\n"];
    [_textView insertText:[[CPAttributedString alloc] initWithString:@"Fusce\n"
                                                          attributes:[CPDictionary dictionaryWithObjects:[centeredParagraph, [CPFont boldFontWithName:"Arial" size:18], [CPColor redColor], [CPColor yellowColor]]
                                                                                                 forKeys:[CPParagraphStyleAttributeName, CPFontAttributeName, CPForegroundColorAttributeName, CPBackgroundColorAttributeName]]]];

    [_textView insertText:"\n"];
    [_textView insertText:[[CPAttributedString alloc] initWithString:@"Yellow\n"
                                                          attributes:[CPDictionary dictionaryWithObjects:[[CPFont boldFontWithName:"Arial" size:25], [CPColor yellowColor]]
                                                                                                 forKeys:[CPFontAttributeName, CPBackgroundColorAttributeName]]]];
    [theWindow orderFront:self];
//  [_textView setEditable:NO];
    [CPMenu setMenuBarVisible:YES];

    console.log([[CPFont systemFontOfSize:12] cssString])
    var context = document.createElement("canvas").getContext("2d");
    context.font = '12px Arial, sans-serif';
    var testingText = 'A A A A A A A A';
    console.log(ROUND(context.measureText(testingText).width));
    console.log(ROUND([CPPlatformString sizeOfString:testingText withFont:[CPFont systemFontOfSize:12] forWidth:NULL].width));
}

- (void) makeRTF:(id)sender
{
    [_textView2 setString: [_CPRTFProducer produceRTF:[_textView textStorage] documentAttributes: @{}] ];
    var tc = [_CPRTFParser new];
    var mystr=[tc parseRTF:[_textView2 stringValue]];
    [_textView selectAll: self];
    [_textView insertText: mystr];
}

@end
