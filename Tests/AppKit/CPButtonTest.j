@import <AppKit/CPButton.j>
@import <AppKit/CPApplication.j>
@import <AppKit/CPText.j>
@import <AppKit/CPRadio.j>
@import <AppKit/CPObjectController.j>

@implementation CPButtonTest : OJTestCase
{
    CPButton button;
    BOOL wasClicked;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

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
        characters:"b" charactersIgnoringModifiers:"b" isARepeat:NO keyCode:0 isActionKey:NO]];
    [self assertFalse:wasClicked];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:0 windowNumber:0 context:nil
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0 isActionKey:NO]];
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
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0 isActionKey:NO]];
    [self assertFalse:wasClicked];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:CPAlternateKeyMask
        timestamp:0 windowNumber:0 context:nil
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0 isActionKey:NO]];
    [self assertTrue:wasClicked];
}

- (void)testKeyEquivalentWithShiftMask
{
    [button setTarget:self];
    [button setAction:@selector(clickMe:)];
    [button setKeyEquivalent:"A"];

    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:0 windowNumber:0 context:nil
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0 isActionKey:NO]];
    [self assertFalse:wasClicked];

    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:CPShiftKeyMask
        timestamp:0 windowNumber:0 context:nil
        characters:"A" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0 isActionKey:NO]];
    [self assertTrue:wasClicked];
}

- (void)testSpecialKeyEquivalent
{
    [button setTarget:self];
    [button setAction:@selector(clickMe:)];
    [button setKeyEquivalent:CPEscapeFunctionKey];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:0 windowNumber:0 context:nil
        characters:CPDeleteCharacter charactersIgnoringModifiers:CPDeleteCharacter isARepeat:NO keyCode:0 isActionKey:NO]];
    [self assertFalse:wasClicked];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:0 windowNumber:0 context:nil
        characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0 isActionKey:NO]];
    [self assertFalse:wasClicked];
    [button performKeyEquivalent:[CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0
        timestamp:0 windowNumber:0 context:nil
        characters:CPEscapeFunctionKey charactersIgnoringModifiers:CPEscapeFunctionKey isARepeat:NO keyCode:0 isActionKey:NO]];
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

// PR #2920 modifies how theme states are used. This test is no more usable.
//- (void)testThemeStateWhenSettingObjectValue
//{
//    [button unsetThemeState:[button themeState]];
//    [button setObjectValue:CPOnState];
//    [self assert:String(CPThemeStateSelected) equals:String([button themeState]) message:@"object should be in the selected themestate"];
//
//    [button setObjectValue:CPOffState];
//    [self assert:String(CPThemeStateNormal) equals:String([button themeState]) message:@"object should be in the normal themestate"];
//}

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

- (void)testAutomaticRadioGroup
{
    var radioButton1 = [CPRadio radioWithTitle:@"Radio 1"],
        radioButton2 = [CPRadio radioWithTitle:@"Radio 2"],
        radioButton3 = [CPRadio radioWithTitle:@"Radio 3"],
        simpleView1  = [[CPView alloc] initWithFrame:CGRectMakeZero()],
        simpleView2  = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    // Initially, buttons are isolated
    [self assertFalse:([radioButton1 radioGroup] === [radioButton2 radioGroup]) message:@"initially, buttons should be isolated"];

    [simpleView1 addSubview:radioButton1];
    [simpleView1 addSubview:radioButton2];

    // As no actions are defined, buttons are still isolated
    [self assertFalse:([radioButton1 radioGroup] === [radioButton2 radioGroup]) message:@"no actions defined, buttons should be isolated"];

    [radioButton1 setAction:@selector(dummyAction1:)];
    [radioButton2 setAction:@selector(dummyAction2:)];

    // As different actions are defined, buttons are still isolatdd
    [self assertFalse:([radioButton1 radioGroup] === [radioButton2 radioGroup]) message:@"different actions defined, buttons should be isolated"];

    [radioButton2 setAction:@selector(dummyAction1:)];

    // As the same action is defined, buttons must be grouped
    [self assertTrue:([radioButton1 radioGroup] === [radioButton2 radioGroup]) message:@"same action defined, buttons should be grouped"];

    [radioButton3 setAction:@selector(dummyAction1:)];

    // As radioButton3 is not inserted in a view, it's isolated
    [self assertTrue:([[radioButton3 radioGroup] size] === 1) message:@"not in a view, button should be isolated"];

    [simpleView2 addSubview:radioButton3];

    // As radioButton3 is in another view, it's isolated from radioButton1 & 2
    [self assertTrue:([[radioButton3 radioGroup] size] === 1) message:@"alone in a view, button should be isolated"];

    [simpleView1 addSubview:radioButton3];

    // As all 3 buttons are in the same view, with the same action, they are grouped
    [self assertTrue:([[radioButton3 radioGroup] size] === 3) message:@"after moving to the same view, buttons should be grouped"];

    [radioButton3 setAction:@selector(dummyAction2:)];

    // As the action of button 3 is now different, it's isolated
    [self assertTrue:([[radioButton3 radioGroup] size] === 1) message:@"after changing the action, button 3 should be isolated"];

    // And buttons 1 & 2 are still grouped
    [self assertTrue:([radioButton1 radioGroup] === [radioButton2 radioGroup]) message:@"buttons 1 & 2 should remain grouped"];
    [self assertTrue:([[radioButton1 radioGroup] size] === 2) message:@"radio group should contain only buttons 1 & 2"];
}

- (IBAction)dummyAction1:(id)sender
{

}

- (IBAction)dummyAction2:(id)sender
{

}

- (void)testRadioValueBinding {
    var content1 = [@{ @"state": NO } mutableCopy],
        content2 = [@{ @"state": NO } mutableCopy];

    var objectController1 = [[CPObjectController alloc] initWithContent:content1],
        objectController2 = [[CPObjectController alloc] initWithContent:content2];

    var parentView = [[CPView alloc] initWithFrame:CGRectMakeZero()],
        radio1 = [CPRadio radioWithTitle:@"Radio 1"],
        radio2 = [CPRadio radioWithTitle:@"Radio 2"];

    [radio1 setAction:@selector(dummyAction1:)];
    [radio2 setAction:@selector(dummyAction1:)];

    [parentView addSubview:radio1];
    [parentView addSubview:radio2];

    [radio1 bind:CPValueBinding toObject:objectController1 withKeyPath:@"selection.state" options:nil];
    [radio2 bind:CPValueBinding toObject:objectController2 withKeyPath:@"selection.state" options:nil];

    [radio1 performClick:self];

    [self assertTrue:[content1 valueForKey:@"state"] == YES message:@"pressed radio should set value"];
    [self assertTrue:[content2 valueForKey:@"state"] == NO message:@"not pressed radio should still have old value"];

    [radio2 performClick:self];

    [self assertTrue:[content2 valueForKey:@"state"] == YES message:@"second pressed radio should set value"];
    // Observe that the radio1 radio binding is not reversed set when the radio2
    // button is clicked
    [self assertTrue:[content1 valueForKey:@"state"] == YES message:@"old selected radio should still have on value"];
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
