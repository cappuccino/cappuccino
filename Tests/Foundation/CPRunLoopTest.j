@import <Foundation/CPObject.j>
@import <Foundation/CPRunLoop.j>
@import <OJUnit/OJTestCase.j>

@implementation CPRunLoopTest : OJTestCase
{
}

- (void)testDelayedPerform
{
    var aPerformer = [Performer new];

    [aPerformer performSelector:@selector(performWithObject:) withObject:5 afterDelay:0];
    [aPerformer performSelector:@selector(performWithObject:) withObject:1 afterDelay:0 inModes:[CPDefaultRunLoopMode]];
    [aPerformer performSelector:@selector(performWithObject:) withObject:10 afterDelay:9999 inModes:[CPDefaultRunLoopMode]];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self assertTrue:[aPerformer.callArgs containsObject:5]];
    [self assertTrue:[aPerformer.callArgs containsObject:1]];
    [CPObject cancelPreviousPerformRequestsWithTarget:aPerformer];

    var performer1 = [Performer new],
        performer2 = [Performer new];

    [performer1 performSelector:@selector(performWithObject:) withObject:5 afterDelay:0 inModes:[CPDefaultRunLoopMode]];
    [performer2 performSelector:@selector(performWithObject:) withObject:10 afterDelay:0 inModes:[CPDefaultRunLoopMode]];
    [performer1 performSelector:@selector(performWithObject:) withObject:1 afterDelay:0 inModes:[CPDefaultRunLoopMode]];
    [CPObject cancelPreviousPerformRequestsWithTarget:performer1];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self assert:nil equals:performer1.callArgs];
    [self assert:[10] equals:performer2.callArgs];
}

@end

@implementation Performer : CPObject
{
    CPArray callArgs;
}

- (void)performWithObject:(id)anObject
{
    if (!callArgs)
        callArgs = [];

    [callArgs addObject:anObject];
}

@end
