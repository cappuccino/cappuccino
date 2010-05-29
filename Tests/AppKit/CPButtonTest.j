
@import <AppKit/CPButton.j>
@import <AppKit/CPApplication.j>

[CPApplication sharedApplication]

@implementation CPButtonTest : OJTestCase
{
    CPButton button;
    BOOL wasClicked;
}

- (void)setUp
{
    button = [CPButton buttonWithTitle:"hello world"];
    wasClicked = NO;
}

- (void)testCanCreate
{
    [self assertTrue:!!button];
}

- (void)testPerformClick
{
    [button setTarget:self];
    [button setAction:@selector(clickMe:)];
    [button performClick:nil];
    [self assertTrue:wasClicked];
}

- (void)clickMe:(id)sender
{
    wasClicked = YES;
}

- (void)testKeyEquivalent
{
    [button setTarget:self];
    [button setAction:@selector(clickMe:)];
    [button setKeyEquivalent:"a"];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:nil windowNumber:nil context:nil
        characters:"b" charactersIgnoringModifiers:"b" isARepeat:NO keyCode:0]];
    [self assertFalse:wasClicked];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:nil windowNumber:nil context:nil
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0]];
    [self assertTrue:wasClicked];
}

- (void)testKeyEquivalentWithModifierMask
{
    [button setTarget:self];
    [button setAction:@selector(clickMe:)];
    [button setKeyEquivalent:"a"];
    [button setKeyEquivalentModifierMask:CPAlternateKeyMask];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:nil windowNumber:nil context:nil
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0]];
    [self assertFalse:wasClicked];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:CPAlternateKeyMask
        timestamp:nil windowNumber:nil context:nil
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0]];
    [self assertTrue:wasClicked];
}

- (void)testKeyEquivalentWithShiftMask
{
    [button setTarget:self];
    [button setAction:@selector(clickMe:)];
    [button setKeyEquivalent:"A"];

    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:nil windowNumber:nil context:nil
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0]];
    [self assertFalse:wasClicked];

    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:CPShiftKeyMask
        timestamp:nil windowNumber:nil context:nil
        characters:"A" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0]];
    [self assertTrue:wasClicked];
}

- (void)testKeyCodeKeyEquivalent
{
    [button setTarget:self];
    [button setAction:@selector(clickMe:)];
    [button setKeyEquivalent:CPEscapeKeyCode];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:nil windowNumber:nil context:nil
        characters:"" charactersIgnoringModifiers:"" isARepeat:NO keyCode:CPSpaceKeyCode]];
    [self assertFalse:wasClicked];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:nil windowNumber:nil context:nil
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0]];
    [self assertFalse:wasClicked];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:nil windowNumber:nil context:nil
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:CPEscapeKeyCode]];
    [self assertTrue:wasClicked];
}

@end
