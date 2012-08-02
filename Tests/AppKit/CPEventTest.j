@import <AppKit/CPApplication.j>
@import <AppKit/CPEvent.j>

@implementation CPEventTest : OJTestCase
{
}

- (void)setUp
{
    // CPApplication must be initialised for some event handling to work.
    [CPApplication sharedApplication];
}

/*!
    This test isn't very useful but it checks for any trouble related to issue #1202.
*/
- (void)testDelta
{
    var anEvent = [CPEvent mouseEventWithType:CPLeftMouseUp location:CGPointMake(50, 50) modifierFlags:0
                           timestamp:0 windowNumber:0 context:nil eventNumber:0 clickCount:2 pressure:0];
    [self assert:0 equals:[anEvent deltaX] message:"default event delta X should be 0"];
    [self assert:0 equals:[anEvent deltaY] message:"default event delta Y should be 0"];
    [self assert:0 equals:[anEvent deltaZ] message:"default event delta Z should be 0"];
}

- (void)testModifierFlags
{
    [self assert:0 equals:[CPEvent modifierFlags] message:@"no modifier flags active in a newly started app"];

    var anEvent = [CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:CPShiftKeyMask timestamp:0 windowNumber:0 context:nil characters:"A" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0];
    [CPApp sendEvent:anEvent];

    [self assert:CPShiftKeyMask equals:[CPEvent modifierFlags] message:@"shift key pressed"];

    // When the key up event is sent the modifier flags are cleared.
    anEvent = [CPEvent keyEventWithType:CPKeyUp location:CGPointMakeZero() modifierFlags:0 timestamp:0 windowNumber:0 context:nil characters:"A" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0];
    [CPApp sendEvent:anEvent];

    [self assert:0 equals:[CPEvent modifierFlags] message:@"shift key released"];
}

@end
