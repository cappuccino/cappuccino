/*
 * AppController.j
 * Nib2CibBaselineAlignementTest
 *
 * Created by You on July 12, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet CPView      view1;
    @outlet CPView      view2;
    @outlet CPView      view3;
    @outlet CPView      view4;
    @outlet CPView      view5;
    @outlet CPView      view6;
    @outlet CPView      view7;
    @outlet CPView      view8;
    @outlet CPTextField      t1;
    @outlet CPTextField      t2;
    @outlet CPTextField      t3;
    @outlet CPTextField      t4;
    @outlet CPTextField      t5;
    @outlet CPTextField      t6;
    @outlet CPTextField      t7;
    @outlet CPTextField      t8;

    @outlet CPCheckBox       swicth;

}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    [view1 setBackgroundColor:[CPColor redColor]];
    [view2 setBackgroundColor:[CPColor redColor]];
    [view3 setBackgroundColor:[CPColor redColor]];
    [view4 setBackgroundColor:[CPColor redColor]];
    [view5 setBackgroundColor:[CPColor redColor]];
    [view6 setBackgroundColor:[CPColor redColor]];
    [view7 setBackgroundColor:[CPColor redColor]];
    [view8 setBackgroundColor:[CPColor redColor]];

    [self switchBg:swicth];
    [theWindow setFullPlatformWindow:YES];
}

- (IBAction)switchBg:(id)aSender
{
    var color = [aSender state] ? [CPColor greenColor] : [CPColor colorWithCalibratedRed:0 green:1 blue:0 alpha:0.5];

    [t1 setBackgroundColor:color];
    [t2 setBackgroundColor:color];
    [t3 setBackgroundColor:color];
    [t4 setBackgroundColor:color];
    [t5 setBackgroundColor:color];
    [t6 setBackgroundColor:color];
    [t7 setBackgroundColor:color];
    [t8 setBackgroundColor:color];
}

@end
