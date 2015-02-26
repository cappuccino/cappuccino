/*
 * AppController.j
 * CPSegmentedControlTest
 *
 * Created by You on January 4, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */
@import <AppKit/AppKit.j>
@import <Foundation/CPObject.j>

CPLogRegister(CPLogConsole);

@implementation AppController : CPObject
{
    @outlet CPSegmentedControl segmentedControl1;
    @outlet CPSegmentedControl segmentedControl2;

    @outlet CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
}

- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];
}

- (IBAction)addSegment:(id)aSender
{
    var n = [segmentedControl1 segmentCount];

    [segmentedControl1 setSegmentCount:n + 1];
    [segmentedControl1 setLabel:@"" + n + 1 forSegment:n];

    [segmentedControl2 setSegmentCount:n + 1];
    [segmentedControl2 setLabel:@"" + n + 1 forSegment:n];
}

- (IBAction)addSegmentWithFixedSize:(id)aSender
{
    var width = [[[theWindow contentView] viewWithTag:1] intValue];
    var n = [segmentedControl1 segmentCount];

    [segmentedControl1 setSegmentCount:n + 1];
    [segmentedControl1 setLabel:@"" + n + 1 forSegment:n];
    [segmentedControl1 setWidth:width forSegment:n];

    [segmentedControl2 setSegmentCount:n + 1];
    [segmentedControl2 setLabel:@"" + n + 1 forSegment:n];
    [segmentedControl2 setWidth:width forSegment:n];
}

- (IBAction)removeSegment:(id)aSender
{
    var n = [[[theWindow contentView] viewWithTag:4] intValue];

    [segmentedControl1 setSegmentCount:n];
    [segmentedControl2 setSegmentCount:n];
}

/*
- (IBAction)removeSelectedSegment:(id)sender
{
    var selectedSegment1 = [segmentedControl1 selectedSegment];
    [segmentedControl1 removeSegmentsAtIndexes:[CPIndexSet indexSetWithIndex:selectedSegment1]];

    var selectedSegment2 = [segmentedControl2 selectedSegment];
    [segmentedControl2 removeSegmentsAtIndexes:[CPIndexSet indexSetWithIndex:selectedSegment2]];
}
*/
- (IBAction)changeLabel:(id)sender
{
    var segment = [[[theWindow contentView] viewWithTag:2] intValue];
    [segmentedControl1 setLabel:(@"New Label " + segment) forSegment:segment];
    [segmentedControl2 setLabel:(@"New Label " + segment) forSegment:segment];

    CPLog.debug("Segment " + segment + " frame=" + CPStringFromRect([segmentedControl2 frameForSegment:segment]) + " width=" + [segmentedControl2 widthForSegment:0]);
}

- (IBAction)changeImage:(id)sender
{
    var image = CPImageInBundle(@"CPImageNameAdvanced.png", 20, 20);

    var segment = [[[theWindow contentView] viewWithTag:3] intValue];

    [segmentedControl1 setImage:image forSegment:segment];
    [segmentedControl2 setImage:image forSegment:segment];
}

- (IBAction)setTrackingMode:(id)sender
{
    var mode = [sender indexOfSelectedItem];
    [segmentedControl1 setTrackingMode:mode];
    [segmentedControl2 setTrackingMode:mode];
}

@end
