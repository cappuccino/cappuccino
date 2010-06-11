@import <AppKit/CPView.j>
@import <AppKit/CPApplication.j>
@import <AppKit/CPText.j>

@import <AppKit/CPPlatformWindow+DOMKeys.j>

[CPApplication sharedApplication]

@implementation CPResponderTest : OJTestCase
{
    CPWindow    theWindow;
    CPResponder responder;
}

- (void)setUp
{
    responder = [TestResponder new];
    responder.doCommandCalls = [];
}

- (void)testInterpretKeyEvents
{
    var tests = [
        CPKeyCodes.PAGE_UP,     CPPageUpFunctionKey,        @selector(pageUp:),
        CPKeyCodes.PAGE_DOWN,   CPPageDownFunctionKey,      @selector(pageDown:),
        CPKeyCodes.LEFT,        CPLeftArrowFunctionKey,     @selector(moveLeft:),
        CPKeyCodes.RIGHT,       CPRightArrowFunctionKey,    @selector(moveRight:),
        CPKeyCodes.UP,          CPUpArrowFunctionKey,       @selector(moveUp:),
        CPKeyCodes.DOWN,        CPDownArrowFunctionKey,     @selector(moveDown:),
        CPKeyCodes.BACKSPACE,   CPDeleteCharacter,          @selector(deleteBackward:),
        CPKeyCodes.ENTER,       CPCarriageReturnCharacter,  @selector(insertLineBreak:),
        0,                      CPNewlineCharacter,         @selector(insertLineBreak:),
        CPKeyCodes.ESC,         CPEscapeFunctionKey,        @selector(cancel:),
        CPKeyCodes.TAB,         CPTabCharacter,             @selector(insertTab:)
    ];

    for (var i=0; i<tests.length; i += 3)
    {
        var keyCode = tests[i],
            character = tests[i+1],
            selector = tests[i+2];

        responder.doCommandCalls = [];
        keyEvent = [CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:0
            timestamp:nil windowNumber:nil context:nil
            characters:character charactersIgnoringModifiers:character isARepeat:NO keyCode:keyCode];
        [responder interpretKeyEvents:[keyEvent]];
        [self assert:[selector] equals:responder.doCommandCalls];
    }

    responder.doCommandCalls = [];
    keyEvent = [CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:CPShiftKeyMask
        timestamp:nil windowNumber:nil context:nil
        characters:CPTabCharacter charactersIgnoringModifiers:CPTabCharacter isARepeat:NO keyCode:CPKeyCodes.TAB];
    [responder interpretKeyEvents:[keyEvent]];
    [self assert:[@selector(insertBackTab:)] equals:responder.doCommandCalls];
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