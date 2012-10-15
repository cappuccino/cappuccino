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

- (void)testDescription
{
    var anEvent = [CPEvent mouseEventWithType:CPLeftMouseUp location:CGPointMake(50, 50) modifierFlags:CPShiftKeyMask
                           timestamp:400.5 windowNumber:300 context:nil eventNumber:0 clickCount:2 pressure:0.5];
    [self assert:@"CPEvent: type=2 loc={50, 50} time=400.5 flags=0x20000 win=undefined winNum=0 ctxt=null evNum=0 click=2 buttonNumber=0 pressure=0.5" equals:[anEvent description]];

    anEvent = [CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:CPShiftKeyMask | CPCommandKeyMask timestamp:12345.6 windowNumber:10 context:nil characters:"X" charactersIgnoringModifiers:"x" isARepeat:NO keyCode:10];

    [self assert:@"CPEvent: type=10 loc={0, 0} time=12345.6 flags=0x120000 win=null winNum=10 ctxt=null chars=\"X\" unmodchars=\"x\" repeat=0 keyCode=10" equals:[anEvent description]];

    anEvent = [CPEvent otherEventWithType:CPApplicationDefined location:CGPointMakeZero() modifierFlags:0 timestamp:500.5 windowNumber:2 context:nil subtype:5 data1:15 data2:25];

    [self assert:@"CPEvent: type=15 loc={0, 0} time=500.5 flags=0x0 win=null winNum=0 ctxt=null subtype=5 data1=15 data2=25" equals:[anEvent description]];
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
