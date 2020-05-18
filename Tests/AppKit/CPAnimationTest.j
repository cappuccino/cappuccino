@import <AppKit/CPApplication.j>
@import <AppKit/CPAnimation.j>

@implementation CPAnimation (TestMethods)
{
}

- (CPTimer)timer
{
    return _timer;
}

@end

@implementation CPAnimationTest : OJTestCase
{
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

- (void)testScheduleTimerWithIntervalBasedOnDefaultFrameRate
{
    var animation = [[CPAnimation alloc] initWithDuration:0.1 animationCurve:CPAnimationLinear];
    [animation startAnimation];

    [self assert:1.0/60.0 equals:[[animation timer] timeInterval]];
}

- (void)testScheduleTimerWithIntervalBasedOnCustomFrameRate
{
    var animation = [[CPAnimation alloc] initWithDuration:0.1 animationCurve:CPAnimationLinear];
    [animation setFrameRate:30];
    [animation startAnimation];

    [self assert:1.0/30.0 equals:[[animation timer] timeInterval]];
}

- (void)testScheduleTimerWithIntervalBasedOnAsFastAsPossibleFrameRate
{
    var animation = [[CPAnimation alloc] initWithDuration:0.1 animationCurve:CPAnimationLinear];
    [animation setFrameRate:0];
    [animation startAnimation];

    [self assert:0.0001 equals:[[animation timer] timeInterval]];
}

@end
