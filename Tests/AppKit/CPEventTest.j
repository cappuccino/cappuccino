@import <AppKit/CPEvent.j>

@implementation CPEventTest : OJTestCase
{
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

@end