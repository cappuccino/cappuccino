@import <AppKit/CPSlider.j>

@implementation CPSliderTest : OJTestCase
{
}

- (void)testIsContinuous
{
    // While normally testing simple instance variables is a waste of time,
    // the 'Continuous' flag is stored in a special way.
    var slider = [[CPSlider alloc] initWithFrame:CGRectMakeZero()];

    [slider setContinuous:NO];
    [self assertFalse:[slider isContinuous]];

    [slider setContinuous:YES];
    [self assertTrue:[slider isContinuous]];
}

- (void)testEncoding
{
    // Previously, the isContinuous state has not been properly preserved through cpcoding.
    var slider = [[CPSlider alloc] initWithFrame:CGRectMakeZero()];

    [slider setContinuous:NO];

    var decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:slider]];
    [self assert:[slider isContinuous] equals:[decoded isContinuous] message:@"a decoded slider should preserve isContinuous (NO case)"];

    [slider setContinuous:YES];
    decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:slider]];
    [self assert:[slider isContinuous] equals:[decoded isContinuous] message:@"a decoded slider should preserve isContinuous (YES case)"];
}

@end
