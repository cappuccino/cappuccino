
@import <AppKit/CPStepper.j>
@import <AppKit/CPApplication.j>

[CPApplication sharedApplication]

@implementation CPStepperTest : OJTestCase
{
    CPStepper stepper;
}

- (void)setUp
{
    stepper = [CPStepper stepper];
}

- (void)testCanCreate
{
    [self assertTrue:!!stepper];
}

- (void)testPerformIncrease
{
    [stepper performClickUp:nil];
    [self assert:1 equals:[stepper value]];
}

- (void)testPerformDecrease
{
    [stepper performClickDown:nil];
    [self assert:-1 equals:[stepper value]];
}

- (void)testPerformIncreaseWithIncrement
{
    [stepper setIncrement:10];
    [stepper performClickUp:nil];
    [self assert:10 equals:[stepper value]];
}

- (void)testPerformIncreaseWithIncrement
{
    [stepper setIncrement:10];
    [stepper performClickDown:nil];
    [self assert:-10 equals:[stepper value]];
}

- (void)testPerformMaxValue
{
    [stepper setValue:100];
    [stepper performClickUp:nil];
    [stepper performClickUp:nil];
    [stepper performClickUp:nil];
    [self assert:100 equals:[stepper value]];
}

- (void)testPerformMinValue
{
    [stepper setValue:-100];
    [stepper performClickDown:nil];
    [stepper performClickDown:nil];
    [stepper performClickDown:nil];
    [self assert:-100 equals:[stepper value]];
}

- (void)setToBigValue
{
    [stepper setValue:1000];
    [self assert:100 equals:[stepper value]];
}

- (void)setToSmallValue
{
    [stepper setValue:-1000];
    [self assert:-100 equals:[stepper value]];
}



@end
