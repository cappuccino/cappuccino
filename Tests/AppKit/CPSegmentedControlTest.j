@import <AppKit/AppKit.j>

// TODO: Maybe create one test file for each tracking mode so they can be tested separately without confusion.
@implementation CPSegmentedControlTest : OJTestCase
{
    CPSegmentedControlTest _segmentedControl;
}

- (void)setUp
{
    _segmentedControl = [[CPSegmentedControl alloc] initWithFrame:CGRectMakeZero()];
    [_segmentedControl setSegmentCount:3];
}

- (void)testMakeCPSegmentedControlInstance
{
    [self assertNotNull:_segmentedControl];
}

- (void)testDefaultsToSelectOneTrackingMode
{
    [self assert:[_segmentedControl trackingMode] equals:CPSegmentSwitchTrackingSelectOne];
}

- (void)testSelectsOneSegmentStartingAtBlankState
{
    [self assert:[_segmentedControl selectedSegment] equals:-1];
    [_segmentedControl setSelectedSegment:1];
    [self assert:[_segmentedControl selectedSegment] equals:1];
}

@end

