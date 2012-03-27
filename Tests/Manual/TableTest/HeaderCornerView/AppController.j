/*
 * AppController.j
 * Header-CornerView
 *
 * Created by Alexander Ljungberg on March 18, 2012.
 * Copyright 2012, SlevenBits Ltd. All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib

    CPArray contentArray @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    [CPScrollView setGlobalScrollerStyle:CPScrollerStyleLegacy];

    [self makeContent:3];
    [theWindow center];
}

- (void)makeContent:(int)rows
{
    var r = [];
    for (var i = 0; i < rows; i++)
        [r addObject:[CPDictionary dictionaryWithJSObject:{'col0': 'row ' + i + ' col 0', 'col1': 'row ' + i + ' col 1'}]];
    [self setContentArray:r];
}

- (@action)takeFewRows:(id)sender
{
    [self makeContent:3];
}

- (@action)takeManyRows:(id)sender
{
    [self makeContent:20];
}

@end
