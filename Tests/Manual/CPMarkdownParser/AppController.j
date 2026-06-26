/*
 * AppController.j
 *
 *  Markdown Live Viewer mit kollabiertem Rahmen-Layout und adaptiver Spalten-Projektion
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

// --- MAIN CONTROLLER ---
@implementation AppController : CPObject
{
    CPTextView      _markdownInputTextView;
    CPTextView      _markdownRenderTextView;
    CPScrollView    _inputScrollView;
    CPScrollView    _renderScrollView;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    [contentView setBackgroundColor:[CPColor colorWithWhite:0.95 alpha:1.0]];

    // 1. Tool-Bar
    var toolbarView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([contentView bounds]), 60)];
    [toolbarView setAutoresizingMask:CPViewWidthSizable];
    [toolbarView setBackgroundColor:[CPColor colorWithWhite:0.88 alpha:1.0]];
    [contentView addSubview:toolbarView];

    var currentX = 15;

    var renderButton = [[CPButton alloc] initWithFrame:CGRectMake(currentX, 15, 140, 30)];
    [renderButton setTitle:@"Force Render"];
    [renderButton setTarget:self];
    [renderButton setAction:@selector(renderMarkdownAction:)];
    [toolbarView addSubview:renderButton];
    currentX += 150;

    var clearButton = [[CPButton alloc] initWithFrame:CGRectMake(currentX, 15, 100, 30)];
    [clearButton setTitle:@"Clear All"];
    [clearButton setTarget:self];
    [clearButton setAction:@selector(clearAction:)];
    [toolbarView addSubview:clearButton];

    // 2. Workspace Split-View Layout
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

    // Split-Pane Größenänderung überwachen
    [[CPNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(splitViewDidResizeSubviews:) 
                                                 name:CPSplitViewDidResizeSubviewsNotification 
                                               object:splitView];

    // Linke Seite: Plain-Text Editor
    var leftLabel = [[CPTextField alloc] initWithFrame:CGRectMake(15, 10, CGRectGetWidth([leftContainer bounds]) - 30, 20)];
    [leftLabel setStringValue:@"Markdown Editor (Plain Text)"];
    [leftLabel setFont:[CPFont boldSystemFontOfSize:14]];
    [leftLabel setAutoresizingMask:CPViewWidthSizable];
    [leftContainer addSubview:leftLabel];

    _markdownInputTextView = [[CPTextView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([leftContainer bounds]) - 30, CGRectGetHeight([leftContainer bounds]) - 70)];
    [_markdownInputTextView setRichText:NO];
    [_markdownInputTextView setBackgroundColor:[CPColor whiteColor]];
    [_markdownInputTextView setDelegate:self];
    
    [_markdownInputTextView setVerticallyResizable:YES];
    [_markdownInputTextView setHorizontallyResizable:NO];
    [_markdownInputTextView setAutoresizingMask:CPViewWidthSizable];
    [[_markdownInputTextView textContainer] setWidthTracksTextView:YES];

    _inputScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(15, 40, CGRectGetWidth([leftContainer bounds]) - 30, CGRectGetHeight([leftContainer bounds]) - 65)];
    [_inputScrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_inputScrollView setDocumentView:_markdownInputTextView];
    [leftContainer addSubview:_inputScrollView];

    // Rechte Seite: Formatted Rich-Text Viewer
    var rightLabel = [[CPTextField alloc] initWithFrame:CGRectMake(15, 10, CGRectGetWidth([rightContainer bounds]) - 30, 20)];
    [rightLabel setStringValue:@"Formatted Output (Rich Text View)"];
    [rightLabel setFont:[CPFont boldSystemFontOfSize:14]];
    [rightLabel setAutoresizingMask:CPViewWidthSizable];
    [rightContainer addSubview:rightLabel];

    _markdownRenderTextView = [[CPTextView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([rightContainer bounds]) - 30, CGRectGetHeight([rightContainer bounds]) - 70)];
    [_markdownRenderTextView setRichText:YES];
    [_markdownRenderTextView setEditable:YES];
    [_markdownRenderTextView setBackgroundColor:[CPColor whiteColor]];
    
    [_markdownRenderTextView setVerticallyResizable:YES];
    [_markdownRenderTextView setHorizontallyResizable:NO];
    [_markdownRenderTextView setAutoresizingMask:CPViewWidthSizable];
    [[_markdownRenderTextView textContainer] setWidthTracksTextView:YES];

    _renderScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(15, 40, CGRectGetWidth([rightContainer bounds]) - 30, CGRectGetHeight([rightContainer bounds]) - 65)];
    [_renderScrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_renderScrollView setDocumentView:_markdownRenderTextView];
    [rightContainer addSubview:_renderScrollView];

    // 3. System Menü aufbauen
    var mainMenu = [CPApp mainMenu];
    while ([mainMenu numberOfItems] > 0)
        [mainMenu removeItemAtIndex:0];

    var item = [mainMenu insertItemWithTitle:@"Edit" action:nil keyEquivalent:nil atIndex:0],
        editMenu = [[CPMenu alloc] initWithTitle:@"Edit Menu"];

    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    [mainMenu setSubmenu:editMenu forItem:item];

    [theWindow orderFront:self];
    [CPMenu setMenuBarVisible:YES];

    // 4. Default-Startup-Markdown mit Ihrem Buchungsbeispiel (inkl. geschützten Trennzeichen und Emojis)
    var startupMarkdown = @"**Aufenthalts\u2011Daten Ihrer Pierre\u202f&\u202fVacances\u2011Reservation (Rechnungs\u2011Nr\u202f23651325)**  \n\n" +
                          @"| \uD83D\uDCC5\u202fCheck\u2011in\u2011Datum | \uD83D\uDCC5\u202fCheck\u2011out\u2011Datum | \uD83D\uDD22\u202fN\u00e4chte | \uD83C\uDFE0\u202fUnterkunft | \uD83D\uDCCD\u202fAdresse | \uD83D\uDC65\u202fG\u00e4ste (Erwachsene\u202f/\u202fKinder) | \u23f0\u202fAnkunftszeit | \u23f0\u202fAbreisezeit | \uD83D\uDCDD\u202fBemerkung |\n" +
                          @"|-------------------|--------------------|-----------|--------------|------------|-------------------------------|----------------|----------------|-------------|\n" +
                          @"| 27.\u202fMai\u202f2026 | 03.\u202fJuni\u202f2026 | 7 | **Les\u202fVillas\u202fd\u2019Olonne** \u2013 Premium\u2011Villas | 19\u202fRoute\u202fdes\u202fAmis\u202fde\u202fla\u202fNature, 85340\u202fLes\u202fSables\u2011de\u2011L\u2011Olonne | 2\u202fErwachsene\u202f/\u202f1\u202fKind | 17:00\u202f\u2013\u202f17:30 (je nach Vereinbarung) | 10:00\u202f\u2013\u202f10:30 (Fr\u00fchst\u00fcck inklusive) | Hotel\u2011Check\u2011in erfolgt in der Rezeption; Schl\u00fcssel werden bei Ankunft \u00fcbergeben. |\n" +
                          @"| | | | **Haus\u2011und\u2011Sammelbecken** | | | | | |\n" +
                          @"| **Hinweis** | | | | | | | | |\n\n" +
                          @"> **Kurz\u00fcbersicht**  \n" +
                          @"> \u2022 7\u202fN\u00e4chte von 27\u202fMai bis 3\u202fJuni 2026  \n" +
                          @"> \u2022 2\u202fErwachsene und 1\u202fKind  \n" +
                          @"> \u2022 Check\u2011in um 17:00\u202f\u2013\u202f17:30 Uhr, Check\u2011out um 10:00\u202f\u2013\u202f10:30 Uhr  \n" +
                          @"> \u2022 Unterkunft: Premium\u2011Villas \u201eLes\u202fVillas\u202fd\u2019Olonne\u201c an der Adresse 19\u202fRoute\u202fdes\u202fAmis\u202fde\u202fla\u202fNature, 85340\u202fLes\u202fSables\u2011de\u2011L\u2011Olonne  \n\n" +
                          @"Falls Sie noch weitere Details ben\u00f6tigen (z.\u202fB.\u202fZahlungsbedingungen, Rezeption\u2011Kontaktdaten, Reiseziel\u2011Informationen), lassen Sie es mich einfach wissen!";

    [_markdownInputTextView setString:startupMarkdown];
    [self renderMarkdown];
}

- (void)textDidChange:(CPNotification)aNotification
{
    [self renderMarkdown];
}

- (void)splitViewDidResizeSubviews:(CPNotification)aNotification
{
    [self renderMarkdown];
}

- (void)renderMarkdownAction:(id)sender
{
    [self renderMarkdown];
}

- (void)clearAction:(id)sender
{
    [_markdownInputTextView setString:@""];
    [self renderMarkdown];
}

- (void)renderMarkdown
{
    var rawText = [_markdownInputTextView string];

    if (!rawText) rawText = @"";

    var parsedAttrStr = [CPMarkdownParser attributedStringFromMarkdown:rawText];
    [_markdownRenderTextView setString:parsedAttrStr];
}

@end
