@import <AppKit/CPAlert.j>
@import <AppKit/CPApplication.j>
@import <AppKit/CPPopover.j>
@import <AppKit/CPViewController.j>
@import <AppKit/CPWindowController.j>

@implementation SheetWindowController : CPWindowController
{
    @outlet CPButton        _closeButton;
    @outlet CPButton        _sheetWindowHackCheckbox;
    @outlet CPButton        _altCloseButton;
    @outlet CPButton        _otherCloseButton;
    @outlet CPButton        _orderOutAfterCheckbox;
    @outlet CPRadioGroup    _windowTypeMatrix;
    @outlet CPButton        _titledMaskButton;
    @outlet CPButton        _closableMaskButton;
    @outlet CPButton        _miniaturizableMaskButton;
    @outlet CPButton        _resizableMaskButton;
    @outlet CPButton        _shadeWindowView;
    @outlet CPButton        _shadeContentView;
    @outlet CPButton        _shadeParentWindow;
    @outlet CPTextField     _textField;
    @outlet CPTokenField    _tokenField;

    CPModalSession          _modalSession;
    CPWindow                _parentWindow;
    CPWindow                _sheet;
    int                     _returnCode;
    CPColor                 _savedColor;

    BOOL                    _hud;
}

- (void)initWithWindowCibName:(CPString)cibName
{
    CPLog.debug("[%@ %@]", [self class], _cmd);

    self = [super initWithWindowCibName:cibName];

    _closeButton = nil;

    return self;
}

- (void)positionWindow
{
    var keyWindow = [CPApp keyWindow],
        origin = CGPointMake(40, 40);

    if (keyWindow)
    {
        origin = ([keyWindow frame]).origin;
        origin = CGPointMake(origin.x + 20, origin.y + 20);
    }

    [[self window] setFrameOrigin:origin];
}

- (void)awakeFromCib
{
    CPLog.debug("[%@ %@]", [self class], _cmd);

    if (!_closeButton)
        CPLog.fatal("_closeButton is not connected!");

    [_closeButton setTarget:self];
    [_closeButton setAction:@selector(unsetAction:)];
    [_altCloseButton setTarget:self];
    [_altCloseButton setAction:@selector(unsetAction:)];
    [_otherCloseButton setTarget:self];
    [_otherCloseButton setAction:@selector(unsetAction:)];

    if (_hud)
    {
        var theWindow = [self window],
            contentView = [theWindow contentView],
            hudWindow = [[CPWindow alloc] initWithContentRect:[contentView bounds] styleMask:[theWindow styleMask] | CPHUDBackgroundWindowMask];
        [theWindow orderOut:nil];
        [hudWindow setFrame:[theWindow frame]];
        [hudWindow setContentView:contentView];
        [hudWindow orderFront:nil];
        [self setWindow:hudWindow];
        [contentView _setThemeIncludingDescendants:[CPTheme defaultHudTheme]];
    }

    [[_textField window] makeFirstResponder:_textField];
}

- (void)unsetAction:(id)sender
{
    CPLog.warn("No action set on this %@", [sender class]);
}

- (void)addButtons:(CPWindow)aWindow
{
    var x = 10,
        unsetAction = @selector(unsetAction:);

    _closeButton = [[CPButton alloc] initWithFrame:CGRectMake(x, 10, 32, 100)];
    [_closeButton setTitle:@"Close"];
    [_closeButton setButtonType:CPMomentaryPushInButton];
    [_closeButton setBezelStyle:CPBezelBorder];
    [_closeButton sizeToFit];
    [_closeButton setTarget:self];
    [_closeButton setAction:unsetAction];
    [[aWindow contentView] addSubview:_closeButton positioned:CPWindowAbove relativeTo:nil];
    x += 10 + CGRectGetWidth([_closeButton frame]);

    _altCloseButton = [[CPButton alloc] initWithFrame:CGRectMake(x, 10, 32, 100)];
    [_altCloseButton setTitle:@"Close Parent Too"];
    [_altCloseButton setButtonType:CPMomentaryPushInButton];
    [_altCloseButton setBezelStyle:CPBezelBorder];
    [_altCloseButton sizeToFit];
    [_altCloseButton setTarget:self];
    [_altCloseButton setAction:unsetAction];
    [[aWindow contentView] addSubview:_altCloseButton positioned:CPWindowAbove relativeTo:nil];
    x += 10 + CGRectGetWidth([_altCloseButton frame]);

    _otherCloseButton = [[CPButton alloc] initWithFrame:CGRectMake(x, 10, 32, 100)];
    [_otherCloseButton setTitle:@"Chain Sheets"];
    [_otherCloseButton setButtonType:CPMomentaryPushInButton];
    [_otherCloseButton setBezelStyle:CPBezelBorder];
    [_otherCloseButton sizeToFit];
    [_otherCloseButton setTarget:self];
    [_otherCloseButton setAction:unsetAction];
    [[aWindow contentView] addSubview:_otherCloseButton positioned:CPWindowAbove relativeTo:nil];

    if ([aWindow styleMask] & CPHUDBackgroundWindowMask)
        [[_closeButton, _altCloseButton, _otherCloseButton] makeObjectsPerformSelector:@selector(setTheme:) withObject:[CPTheme defaultHudTheme]];
}

- (SheetWindowController)initWithStyleMask:(int)styleMask debug:(int)debug hud:(BOOL)shouldBeHud
{
    CPLog.debug("[%@ %@] mask=%d radioGroup=%@", [self class], _cmd, styleMask, _windowTypeMatrix);

    _hud = shouldBeHud;

    if (styleMask < 0)
        return [self initWithWindowCibName:@"Window"];

    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0, 0, 400, 300) styleMask:styleMask];

    if (debug & 1)
        [theWindow setBackgroundColor:[CPColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:0.5]];

    if (debug & 2)
        [[theWindow contentView] setBackgroundColor:[CPColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:0.5]];

    if (self = [super initWithWindow:theWindow])
        [self addButtons:theWindow];

    return self;
}

- (SheetWindowController)allocController
{
    CPLog.debug("[%@ %@] groupClass=%@", [self class], _cmd,
        [[_windowTypeMatrix selectedRadio] tag]);

    var type = 1;

    if (_windowTypeMatrix)
        type = [[_windowTypeMatrix selectedRadio] tag];

    var styleMask = 0;

    if ([_titledMaskButton state])
        styleMask |= CPTitledWindowMask;

    if ([_closableMaskButton state])
        styleMask |= CPClosableWindowMask;

    if ([_miniaturizableMaskButton state])
        styleMask |= CPMiniaturizableWindowMask;

    switch (type)
    {
        case 2:
            styleMask |= CPHUDBackgroundWindowMask;
            break;

        case 3:
            styleMask = CPBorderlessWindowMask;
            break;

        case 4:
            styleMask |= CPTexturedBackgroundWindowMask;
            break;

        case 5:
            styleMask = CPDocModalWindowMask;
            break;

        default:
            break;
    }

    if ([_resizableMaskButton state])
        styleMask |= CPResizableWindowMask;

    if (type == 1 || type == -1)
        styleMask = -1;

    var debug = 0;

    if ([_shadeWindowView state])
        debug |= 1;

    if ([_shadeContentView state])
         debug |= 2;

    var hud = type === -1;

    return [[SheetWindowController alloc] initWithStyleMask:styleMask debug:debug hud:hud];
}

- (SheetWindowController)allocWithPanel:(CPPanel)panel
{
    return [[SheetWindowController alloc] initWithWindow:panel];
}

- (void)disableUnlinkedButtons
{
    CPLog.debug("[%@ %@]", [self class], _cmd);

    var unsetSelector = @selector(unsetAction:);

    if (_closeButton)
        [_closeButton setEnabled:[_closeButton action] != unsetSelector];

    if (_altCloseButton)
        [_altCloseButton setEnabled:[_altCloseButton action] != unsetSelector];

    if (_otherCloseButton)
        [_otherCloseButton setEnabled:[_otherCloseButton action] != unsetSelector];
}

//
// Normal window
//
- (void)newDocument:(id)sender
{
    [self newWindow:sender];
}

- (void)newWindow:(id)sender
{
    [[self allocController] runNormalWindow];
}

- (void)runNormalWindow
{
    CPLog.debug("[%@ %@]", [self class], _cmd);

    [self positionWindow];
    [[self window] setTitle:@"Normal Window"];
    [_closeButton setTarget:[self window]];
    [_closeButton setAction:@selector(orderOut:)];
    [self disableUnlinkedButtons];

    [self showWindow:self];

    // This code exposes the bug described in issue #1911 by adding a CPPanel child window at a different window
    // level than the parent window and then immediately closing it. To test, click the Window button. If a
    // crash ensues the #1911 fix is not operating. On the other hand if the panel widnow is never seen and
    // the window opens like normal everything is correct.
    var windows = [CPApp windows];

    if ([windows count] >= 2)
    {
        var w = [[CPPanel alloc] initWithContentRect:CGRectMake(100, 100, 100, 100)
                                           styleMask:CPTitledWindowMask | CPClosableWindowMask | CPResizableWindowMask | CPHUDBackgroundWindowMask];
        [w setLevel:CPFloatingWindowLevel];
        [[windows objectAtIndex:0] addChildWindow:w ordered:CPWindowAbove];
        [[windows objectAtIndex:0] makeKeyAndOrderFront:nil];
        [w orderOut:nil];
        [[self window] makeKeyAndOrderFront:nil];
    }
}

//
// Modal window
//
- (void)newModalWindow:(id)sender
{
    [[self allocController] runModalWindow];
}

- (void)runModalWindow
{
    CPLog.debug("[%@ %@]", [self class], _cmd);

    [[self window] setTitle:@"Modal Window"];
    [[self window] setDelegate:self];
    [_closeButton setTarget:self];
    [_closeButton setAction:@selector(endModalWindow:)];
    [self disableUnlinkedButtons];

    //[self showWindow:self];
    [CPApp runModalForWindow:[self window]];
}

- (void)endModalWindow:(id)sender
{
    CPLog.debug("[%@ %@]", [self class], _cmd);

    // performClose shouldn't work, if the window has no close button
    if ([[self window] styleMask] & CPClosableWindowMask)
        [[self window] performClose:self];
    else
        [[self window] close];
}

- (void)windowWillClose:(CPNotification)notification
{
    CPLog.debug("[%@ %@]", [self class], _cmd);

     // this is one way to handle close button on modal window
    if ([CPApp modalWindow])
        [CPApp stopModal];
}

//
// Sheet
//
- (void)newSheet:(id)sender
{
    [[self allocController] runSheetForWindow:[self window]];
}

- (void)runSheetForWindow:(CPWindow)parentWindow
{
    CPLog.debug("[%@ %@]", [self class], _cmd);

    var sheet = [self window];
    [parentWindow setDelegate:self];
    _parentWindow = parentWindow;
    _sheet = sheet;

    // NOTE: _closeButton doesn't exist until we call [self window] to load window from cib!
    [_closeButton setTarget:self];
    [_closeButton setAction:@selector(closeSheet:)];
    [_altCloseButton setAction:@selector(closeSheetAndParent:)];
    [_otherCloseButton setAction:@selector(closeSheetAndRepeat:)];
    [self disableUnlinkedButtons];

    [CPApp beginSheet:sheet
        modalForWindow:parentWindow
        modalDelegate:self
        didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
        contextInfo:parentWindow];
}

- (void)closeSheet:(id)sender
{
    CPLog.debug("[%@ %@]", [self class], _cmd);
    _returnCode = 1;

    var orderOutAfter = [_orderOutAfterCheckbox state];
    if (!orderOutAfter)
        [[self window] orderOut:nil];

    [CPApp endSheet:[self window] returnCode:_returnCode];

    if (orderOutAfter)
        [[self window] orderOut:nil];
}

- (void)closeSheetAndParent:(id)sender
{
    CPLog.debug("[%@ %@]", [self class], _cmd);

    // common use case is saving document in response to a close,
    // in this case we don't want to show the animation at all,
    // and also get rid of the parent window
    [_parentWindow close];

    var orderOutAfter = [_orderOutAfterCheckbox state];
    if (!orderOutAfter)
        [[self window] orderOut:nil];

    _returnCode = 99;
    [CPApp endSheet:[self window] returnCode:_returnCode];

    if (orderOutAfter)
        [[self window] orderOut:nil];
}

- (void)closeSheetAndRepeat:(id)sender
{
    CPLog.debug("[%@ %@]", [self class], _cmd);

    // common use case is showing a progress bar after a save command,
    // the orderout gets rid of the current sheet,
    // the return code indicates to open another sheet up
    var orderOutAfter = [_orderOutAfterCheckbox state];
    if (!orderOutAfter)
        [[self window] orderOut:nil];

    _returnCode = 77;
    [CPApp endSheet:[self window] returnCode:_returnCode];

    if (orderOutAfter)
        [[self window] orderOut:nil];
}

//
// "Modal" Sheet implemented by using modal session
//
- (void)newModalSheet:(id)sender
{
    [[self allocController] runModalSheetForWindow:[self window]];
}

- (void)runModalSheetForWindow:(CPWindow)parentWindow
{
    CPLog.debug("[%@ %@]", [self class], _cmd);

    var sheet = [self window];
    [parentWindow setDelegate:self];
    _parentWindow = parentWindow;
    _sheet = sheet;

    [_closeButton setTarget:self];
    [_closeButton setAction:@selector(closeModalSheet:)];
    [self disableUnlinkedButtons];

    [CPApp beginSheet:sheet
        modalForWindow:parentWindow
        modalDelegate:self
        didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
        contextInfo:parentWindow];
}

- (void)closeModalSheet:(id)sender
{
    CPLog.debug("[%@ %@]", [self class], _cmd);

    var orderOutAfter = [_orderOutAfterCheckbox state];
    if (!orderOutAfter)
        [[self window] orderOut:nil];

    _returnCode = 2;
    [CPApp endSheet:[self window] returnCode:_returnCode];

    // what return should we get, the sheet or modal?
    [CPApp stopModalWithCode:999];

    if (orderOutAfter)
        [[self window] orderOut:nil];
}

//
// Test alert panels
//
- (void)newAlertSheet:(id)sender
{
    [self runAlertSheet:[self window]];
}

- (void)runAlertSheet:(CPWindow)parentWindow
{
    // BUG: capp 0.9.5 on WebKit will chop off "bug." in the info text
    var alert = [CPAlert alertWithMessageText:@"Alert message text goes here"
                                defaultButton:@"DefaultButton"
                              alternateButton:@"AltButton"
                                  otherButton:@"OtherButton"
                    informativeTextWithFormat:@"This informative text sentence shows text wrapping bug."];

    [parentWindow setDelegate:self];
    _parentWindow = parentWindow;
    _sheet = alert;
    _returnCode = -1;

    [alert beginSheetModalForWindow:parentWindow
                      modalDelegate:self
                     didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
                        contextInfo:parentWindow];
}

//
// Test popover
//
- (@action)newPopover:(id)sender
{
    [[self allocController] runPopoverForWindow:[self window] withSender:sender];
}

- (void)runPopoverForWindow:(CPWindow)parentWindow withSender:(id)sender
{
    var aPopover = [CPPopover new],
        viewController = [CPViewController new];

    [aPopover setContentViewController:viewController];
    [[self window] close];
    [viewController setView:[[self window] contentView]];
    [aPopover setContentSize:[[[self window] contentView] boundsSize]];
    [aPopover setAnimates:YES];
    [aPopover setBehavior:CPPopoverBehaviorTransient];
    [aPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:CPMaxXEdge];
}

//
// Test notifications/delegate methods
//
- (void)didEndSheet:(CPWindow)sheet returnCode:(int)returnCode contextInfo:(id)parentWindow
{
    CPLog.debug("[%@ %@] returnCode=%d", [self class], _cmd, returnCode);

    if (sheet !== _sheet)
        CPLog.fatal("sheet invalid");

    if (_returnCode >= 0 && returnCode != _returnCode)
        CPLog.fatal("returnCode invalid");

    if (_parentWindow !== parentWindow)
        CPLog.fatal("contextInfo invalid");

    // test sheet chaining. it should be possible to start another sheet from didEndSheet,
    // but only if we orderOut: the sheet before we called endSheet: This is how cocoa works too.
    if (returnCode == 77)
        [self runSheetForWindow:parentWindow];
        //[self runAlertSheet:parentWindow];
}

- (BOOL)shadeWindow
{
    return [_shadeParentWindow state];
}

- (void)windowWillBeginSheet:(CPNotification)notification
{
    CPLog.debug("[%@ %@]", [self class], _cmd);

    if ([notification object] !== _parentWindow)
        CPLog.fatal("notification object should be delegate's window");

    if ([[_parentWindow windowController] shadeWindow])
    {
        _savedColor = [[_parentWindow contentView] backgroundColor];
        [[_parentWindow contentView] setBackgroundColor:
            [CPColor colorWithCalibratedRed:0.0 green:0.7 blue:0.0 alpha:1.0]];
    }
}

- (void)windowDidEndSheet:(CPNotification)notification
{
    CPLog.debug("[%@ %@]", [self class], _cmd);

    if ([notification object] !== _parentWindow)
        CPLog.fatal("notification object should be delegate's window");

    if ([[_parentWindow windowController] shadeWindow])
        [[_parentWindow contentView] setBackgroundColor:_savedColor];
}

- (CPArray)tokenField:(CPTokenField)aTokenField completionsForSubstring:(CPString)substring indexOfToken:(int)tokenIndex indexOfSelectedItem:(int)selectedIndex
{
    var choices = ["aardvark", "baa", "caaing whale"],
        r = [];

    // Don't complete 'blank' - this would show all available matches which is excessive.
    if (!substring)
        return r;

    for (var i = 0; i < choices.length; i++)
        if (choices[i].toLowerCase().indexOf(substring.toLowerCase()) == 0)
            r.push(choices[i]);

    return r;
}

@end
