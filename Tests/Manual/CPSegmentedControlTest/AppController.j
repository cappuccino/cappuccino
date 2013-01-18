/*
 * AppController.j
 * CPSegmentedControlTest
 *
 * Created by You on January 4, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    @outlet CPSegmentedControl segmentedControl1;
    @outlet CPSegmentedControl segmentedControl2;

    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
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
    var n = [segmentedControl1 segmentCount];

    [segmentedControl1 setSegmentCount:n + 1];
    [segmentedControl1 setLabel:@"" + n + 1 forSegment:n];
    [segmentedControl1 setWidth:100 forSegment:n];

    [segmentedControl2 setSegmentCount:n + 1];
    [segmentedControl2 setLabel:@"" + n + 1 forSegment:n];
    [segmentedControl2 setWidth:100 forSegment:n];

}

- (IBAction)removeSegment:(id)aSender
{
    var n = [segmentedControl1 segmentCount];

    [segmentedControl1 setSegmentCount:n - 1];
    [segmentedControl2 setSegmentCount:n - 1];
}

@end
