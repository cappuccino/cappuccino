@import <AppKit/CPView.j>
@import <AppKit/CPApplication.j>
@import <AppKit/CPKeyBinding.j>
@import <AppKit/CPText.j>

@import <AppKit/CPPlatformWindow+DOMKeys.j>

@implementation CPResponderTest : OJTestCase
{
    CPWindow    theWindow;
    CPResponder responder;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    responder = [TestResponder new];
    responder.doCommandCalls = [];
}

- (void)testInterpretKeyEvents
{
    var tests = [
            CPKeyCodes.PAGE_UP,     CPPageUpFunctionKey,        @selector(scrollPageUp:),
            CPKeyCodes.PAGE_DOWN,   CPPageDownFunctionKey,      @selector(scrollPageDown:),
            CPKeyCodes.LEFT,        CPLeftArrowFunctionKey,     @selector(moveLeft:),
            CPKeyCodes.RIGHT,       CPRightArrowFunctionKey,    @selector(moveRight:),
            CPKeyCodes.UP,          CPUpArrowFunctionKey,       @selector(moveUp:),
            CPKeyCodes.DOWN,        CPDownArrowFunctionKey,     @selector(moveDown:),
            CPKeyCodes.BACKSPACE,   CPDeleteCharacter,          @selector(deleteBackward:),
            CPKeyCodes.ENTER,       CPCarriageReturnCharacter,  @selector(insertNewline:),
            0,                      CPNewlineCharacter,         @selector(insertNewline:),
            CPKeyCodes.ESC,         CPEscapeFunctionKey,        @selector(cancelOperation:),
            CPKeyCodes.TAB,         CPTabCharacter,             @selector(insertTab:)
        ];

    for (var i = 0; i < tests.length; i += 3)
    {
        var keyCode = tests[i],
            character = tests[i + 1],
            selector = tests[i + 2];

        responder.doCommandCalls = [];

        var keyEvent = [CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:0
            timestamp:0 windowNumber:0 context:nil
            characters:character charactersIgnoringModifiers:character isARepeat:NO keyCode:keyCode isActionKey:YES];
        [responder interpretKeyEvents:[keyEvent]];
        [self assert:[selector] equals:responder.doCommandCalls];
    }
}

- (void)testInterpretKeyEventsWithModifierFlags
{
    responder.doCommandCalls = [];

    var keyEvent = [CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:CPShiftKeyMask
        timestamp:0 windowNumber:0 context:nil
        characters:CPLeftArrowFunctionKey charactersIgnoringModifiers:CPLeftArrowFunctionKey isARepeat:NO keyCode:CPKeyCodes.LEFT isActionKey:YES];
    [responder interpretKeyEvents:[keyEvent]];
    [self assert:[@selector(moveLeftAndModifySelection:)] equals:responder.doCommandCalls];
}

- (void)testPlatformEditingShortcuts
{
    var isMac = CPBrowserIsOperatingSystem(CPMacOperatingSystem),
        cases = [
            [@"a", CPPlatformActionKeyMask, @"selectAll:"],
            [@"a", CPControlKeyMask, isMac ? @"moveToBeginningOfParagraph:" : @"selectAll:"],
            [@"v", CPControlKeyMask, isMac ? @"pageDown:" : @"paste:"],
            [@"y", CPControlKeyMask, isMac ? @"yank:" : @"redo:"],
            [@"k", CPControlKeyMask, isMac ? @"deleteToEndOfParagraph:" : nil],
            [CPLeftArrowFunctionKey, CPControlKeyMask, isMac ? @"moveToLeftEndOfLine:" : @"moveWordLeft:"],
            [CPRightArrowFunctionKey, CPControlKeyMask | CPShiftKeyMask, isMac ? @"moveToRightEndOfLineAndModifySelection:" : @"moveWordRightAndModifySelection:"],
            [CPHomeFunctionKey, 0, isMac ? @"scrollToBeginningOfDocument:" : @"moveToLeftEndOfLine:"],
            [CPEndFunctionKey, CPShiftKeyMask, isMac ? @"moveToEndOfDocumentAndModifySelection:" : @"moveToRightEndOfLineAndModifySelection:"],
            [CPHomeFunctionKey, CPControlKeyMask, isMac ? nil : @"moveToBeginningOfDocument:"],
            [CPEndFunctionKey, CPControlKeyMask | CPShiftKeyMask, isMac ? nil : @"moveToEndOfDocumentAndModifySelection:"]
        ];

    for (var i = 0; i < cases.length; i++)
    {
        var character = cases[i][0],
            expected = cases[i][2] ? [cases[i][2]] : [],
            keyEvent = [CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:cases[i][1]
                timestamp:0 windowNumber:0 context:nil
                characters:character charactersIgnoringModifiers:character isARepeat:NO keyCode:0 isActionKey:YES];

        responder.doCommandCalls = [];
        [responder interpretKeyEvents:[keyEvent]];
        [self assert:expected equals:responder.doCommandCalls];
    }
}

- (void)testCustomBindingOverridesPlatformDefault
{
    var original = [CPKeyBinding selectorsForKey:@"a" modifierFlags:CPControlKeyMask],
        command = [CPKeyBinding selectorsForKey:@"a" modifierFlags:CPCommandKeyMask];

    try
    {
        [CPKeyBinding createKeyBindingsFromJSObject:{"^a": @"cancelOperation:"}];
        [self assert:[@"cancelOperation:"] equals:[CPKeyBinding selectorsForKey:@"a" modifierFlags:CPControlKeyMask]];
        [self assert:command equals:[CPKeyBinding selectorsForKey:@"a" modifierFlags:CPCommandKeyMask]];
    }
    finally
    {
        [CPKeyBinding createKeyBindingsFromJSObject:{"^a": original}];
    }
}

@end

@implementation TestResponder : CPResponder
{
    CPArray   doCommandCalls;
}

- (void)doCommandBySelector:(SEL)aSelector
{
    doCommandCalls.push(aSelector);
    [super doCommandBySelector:aSelector];
}

@end
