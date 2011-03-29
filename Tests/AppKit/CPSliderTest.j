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

@end