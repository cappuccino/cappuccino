
@import <AppKit/CPButton.j>
@import <AppKit/CPApplication.j>
@import <AppKit/CPText.j>

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

- (void)testSpecialKeyEquivalent
{
    [button setTarget:self];
    [button setAction:@selector(clickMe:)];
    [button setKeyEquivalent:CPEscapeFunctionKey];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:nil windowNumber:nil context:nil
        characters:CPDeleteCharacter charactersIgnoringModifiers:CPDeleteCharacter isARepeat:NO keyCode:0]];
    [self assertFalse:wasClicked];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:nil windowNumber:nil context:nil
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0]];
    [self assertFalse:wasClicked];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:nil windowNumber:nil context:nil
        characters:CPEscapeFunctionKey charactersIgnoringModifiers:CPEscapeFunctionKey isARepeat:NO keyCode:0]];
    [self assertTrue:wasClicked];
}

- (void)testSetObjectValue
{
    [button setObjectValue:CPOnState];
    [self assert:CPOnState equals:[button objectValue] message:@"object value should be CPOnState"];
    [self assert:CPOnState equals:[button state] message:@"state should be CPOnState"];

    // YES !== CPOnState, we used to fail on this
    [button setObjectValue:YES];
    [self assert:CPOnState equals:[button objectValue] message:@"YES should be translated to CPOnState"];
    [self assert:CPOnState equals:[button state] message:@"YES should be translated CPOnState"];

    [button setObjectValue:NO];
    [self assert:CPOffState equals:[button objectValue] message:@"NO should be translated to CPOffState"];
    [self assert:CPOffState equals:[button state] message:@"NO should be translated to CPOffState"];

    [button setObjectValue:CPOffState];
    [self assert:CPOffState equals:[button objectValue] message:@"object value should be CPOffState"];
    [self assert:CPOffState equals:[button state] message:@"state should be CPOnState"];

    [button setAllowsMixedState:NO];
    [button setObjectValue:CPMixedState];
    [self assert:CPOnState equals:[button objectValue] message:@"Mixed state is not allowed, object value should be CPOnState"];
    [self assert:CPOnState equals:[button state] message:@"Mixed state is not allowed, state should be CPOnState"];

    [button setAllowsMixedState:YES];
    [button setObjectValue:CPMixedState];
    [self assert:CPMixedState equals:[button objectValue] message:@"Mixed state is allowed, object value should be CPMixedState"];
    [self assert:CPMixedState equals:[button state] message:@"Mixed state is allowed, state should be CPMixedState"];
}

- (void)testThemeAttributes
{
    var attributes = [CPButton themeAttributes];

    if (attributes)
    {
        var keys = [attributes allKeys],
            firstKey = [keys objectAtIndex:0];

        [self assertTrue:[button hasThemeAttribute:[firstKey]] message:[button className] + " should have the theme attribute \"" + firstKey + "\""];
    }

    [self assertFalse:[button hasThemeAttribute:@"foobar"] message:[button className] + " should not have theme attribute \"" + firstKey + "\""];
}

@end
