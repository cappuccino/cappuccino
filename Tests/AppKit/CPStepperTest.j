@import <AppKit/CPStepper.j>
@import <AppKit/CPApplication.j>

@implementation CPStepperTest : OJTestCase
{
    CPStepper stepper;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    stepper = [CPStepper stepper];
    [stepper setValueWraps:NO];
}

- (void)testCanCreate
{
    [self assertTrue:!!stepper];
}

- (void)testPerformIncrease
{
    [stepper performClickUp:nil];
    [self assert:1 equals:[stepper doubleValue]];
}

- (void)testPerformDecrease
{
    [stepper setDoubleValue:2];
    [stepper performClickDown:nil];
    [self assert:1 equals:[stepper doubleValue]];
}

- (void)testPerformClickUpIncreaseWithIncrement
{
    [stepper setIncrement:10];
    [stepper performClickUp:nil];
    [self assert:10 equals:[stepper doubleValue]];
}

- (void)testPerformClickDownIncreaseWithIncrement
{
    [stepper setIncrement:10];
    [stepper performClickDown:nil];
    [self assert:0 equals:[stepper doubleValue]];
}

- (void)testPerformMaxValue
{
    [stepper setDoubleValue:59];
    [stepper performClickUp:nil];
    [stepper performClickUp:nil];
    [stepper performClickUp:nil];
    [self assert:59 equals:[stepper doubleValue]];
}

- (void)testPerformMinValue
{
    [stepper setDoubleValue:-0];
    [stepper performClickDown:nil];
    [stepper performClickDown:nil];
    [stepper performClickDown:nil];
    [self assert:0 equals:[stepper doubleValue]];
}

- (void)setToBigValue
{
    [stepper setDoubleValue:1000];
    [self assert:100 equals:[stepper doubleValue]];
}

- (void)setToSmallValue
{
    [stepper setDoubleValue:-1000];
    [self assert:-100 equals:[stepper doubleValue]];
}



@end
