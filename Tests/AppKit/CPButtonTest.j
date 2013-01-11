
@import <AppKit/CPButton.j>
@import <AppKit/CPApplication.j>
@import <AppKit/CPText.j>

[CPApplication sharedApplication];

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
        timestamp:0 windowNumber:0 context:nil
        characters:"b" charactersIgnoringModifiers:"b" isARepeat:NO keyCode:0]];
    [self assertFalse:wasClicked];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:0 windowNumber:0 context:nil
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
        timestamp:0 windowNumber:0 context:nil
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0]];
    [self assertFalse:wasClicked];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:CPAlternateKeyMask
        timestamp:0 windowNumber:0 context:nil
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0]];
    [self assertTrue:wasClicked];
}

- (void)testKeyEquivalentWithShiftMask
{
    [button setTarget:self];
    [button setAction:@selector(clickMe:)];
    [button setKeyEquivalent:"A"];

    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:0 windowNumber:0 context:nil
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0]];
    [self assertFalse:wasClicked];

    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:CPShiftKeyMask
        timestamp:0 windowNumber:0 context:nil
        characters:"A" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0]];
    [self assertTrue:wasClicked];
}

- (void)testSpecialKeyEquivalent
{
    [button setTarget:self];
    [button setAction:@selector(clickMe:)];
    [button setKeyEquivalent:CPEscapeFunctionKey];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:0 windowNumber:0 context:nil
        characters:CPDeleteCharacter charactersIgnoringModifiers:CPDeleteCharacter isARepeat:NO keyCode:0]];
    [self assertFalse:wasClicked];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:0 windowNumber:0 context:nil
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0]];
    [self assertFalse:wasClicked];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:0 windowNumber:0 context:nil
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

- (void)testRadioAction
{
    var radioGroup = [CPRadioGroup new],
        radioButton1 = [[CPRadio alloc] initWithFrame:CGRectMakeZero() radioGroup:radioGroup],
        radioButton2 = [[CPRadio alloc] initWithFrame:CGRectMakeZero() radioGroup:radioGroup];

    wasClicked = NO;
    [radioButton2 setTarget:self];
    [radioButton2 setAction:@selector(clickMe:)];

    [radioButton2 setState:CPOnState];
    [radioButton1 setState:CPOnState];
    [self assertFalse:wasClicked message:@"a programmatic selection of a radio button should not fire the action"];

    [radioButton2 performClick:self];
    [self assertTrue:wasClicked message:@"a user click on a radio button should fire the action"]

    // The same goes for the action of the radio group.
    [radioButton2 setTarget:nil];

    wasClicked = NO;
    [radioGroup setTarget:self];
    [radioGroup setAction:@selector(clickMe:)];

    [radioButton1 setState:CPOnState];
    [radioButton2 setState:CPOnState];
    [self assertFalse:wasClicked message:@"a programmatic selection of a radio button should not fire the group action"];

    [radioButton1 performClick:self];
    [self assertTrue:wasClicked message:@"a user click on a radio button should fire the group action"];
}

- (void)testTypeMasks
{
    button = [[CPButton alloc] initWithFrame:CGRectMakeZero()];

    // The default mask should be that of CPMomentaryPushInButton.
    [self assert:CPPushInButtonMask | CPGrayButtonMask | CPBackgroundButtonMask equals:[button highlightsBy]];
    [self assert:0 equals:[button showsStateBy]];

    [button setButtonType:CPPushOnPushOffButton];

    [self assert:CPPushInCellMask | CPChangeGrayCellMask | CPChangeBackgroundCellMask equals:[button highlightsBy]];
    [self assert:CPChangeBackgroundCellMask | CPChangeGrayCellMask equals:[button showsStateBy]];

    // Test archiving.

    var archived = [CPKeyedArchiver archivedDataWithRootObject:button],
        unarchived = [CPKeyedUnarchiver unarchiveObjectWithData:archived];

    [self assert:CPPushInCellMask | CPChangeGrayCellMask | CPChangeBackgroundCellMask equals:[button highlightsBy]];
    [self assert:CPChangeBackgroundCellMask | CPChangeGrayCellMask equals:[button showsStateBy]];

    // Make sure that if highlightsBy and showsStateBy were explicitly set to 0 and 0 (making the button basically
    // not react to clicks), these settings are not replaced by the defaults when decoding.
    [button setHighlightsBy:0];
    [button setShowsStateBy:0];

    archived = [CPKeyedArchiver archivedDataWithRootObject:button];
    unarchived = [CPKeyedUnarchiver unarchiveObjectWithData:archived];

    [self assert:0 equals:[button highlightsBy]];
    [self assert:0 equals:[button showsStateBy]];
}

@end
