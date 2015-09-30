@import <AppKit/AppKit.j>

// TODO: Maybe create one test file for each tracking mode so they can be tested separately without confusion.
@implementation CPSegmentedControlTest : OJTestCase
{
    CPSegmentedControl _segmentedControl;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

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

- (void)testSegmentWidthAfterLabelChange
{
    [_segmentedControl setWidth:0 forSegment:0]; // This is the default.
    [_segmentedControl setLabel:@"Label 1" forSegment:0];

    [self assert:[_segmentedControl widthForSegment:0] equals:0]; // The width property is still 0 : means sizeToFit content.

    [_segmentedControl setWidth:100 forSegment:0];
    [self assert:[_segmentedControl widthForSegment:0] equals:100];

    //Unfortunatly it is not possible to test frameForSegment: or anything related to the layout.
    // -sizeWithFont: uses the DOM and will always return (0,0) in the terminal.
}

- (void)testRemoveSelection
{
    [_segmentedControl setSelectedSegment:2];
    [_segmentedControl setSegmentCount:2];

    [self assert:[_segmentedControl selectedSegment] equals:-1]; // Removed a selected segment. No selection.
}

- (void)testEmpty
{
    [self assertNoThrow:function()
    {
        [_segmentedControl setSegmentCount:0];
    }];

    [self assert:[_segmentedControl selectedSegment] equals:-1];
}

- (void)testDeselectAll
{
    [_segmentedControl setTrackingMode:CPSegmentSwitchTrackingSelectAny];
    [_segmentedControl setSegmentCount:2];
    [_segmentedControl setSelected:YES forSegment:0];
    [_segmentedControl setSelected:YES forSegment:1];
    [self assert:[_segmentedControl selectedSegment] equals:1];

    [self assertNoThrow:function()
    {
        [_segmentedControl setSelectedSegment:-1];
    }];

    [self assert:[_segmentedControl selectedSegment] equals:-1];
    [self assertFalse:[_segmentedControl isSelectedForSegment:0]];
    [self assertFalse:[_segmentedControl isSelectedForSegment:1]];
}

- (void)testSetSelectedSegmentDoesNotDeselect
{
    [_segmentedControl setTrackingMode:CPSegmentSwitchTrackingSelectAny];
    [_segmentedControl setSelected:YES forSegment:0];
    [_segmentedControl setSelected:YES forSegment:1];
    [self assert:[_segmentedControl selectedSegment] equals:1];

    [_segmentedControl setSelectedSegment:1];

    [self assertTrue:[_segmentedControl isSelectedForSegment:0]];
    [self assertTrue:[_segmentedControl isSelectedForSegment:1]];
}

@end

