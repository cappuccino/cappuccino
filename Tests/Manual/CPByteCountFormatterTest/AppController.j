/*
 * AppController.j
 * CPByteCountFormatter
 *
 * Created by You on February 10, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    @outlet CPWindow    testWindow;
    @outlet CPTextField byteCount;
    @outlet CPTextField formattedByteCount;
    @outlet CPBox       properties;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    [byteCount setDelegate:self];
    [byteCount setStringValue:@"0"];
    [formattedByteCount setObjectValue:0];
}

- (void)awakeFromCib
{
}

- (@action)propertyChanged:(id)sender
{
    [formattedByteCount setObjectValue:[byteCount intValue]];
}

- (@action)unitsChanged:(id)sender
{
    var menu = sender,
        index = [menu indexOfSelectedItem],
        item = [menu itemAtIndex:index],
        itemState = [item state],
        units = 0,
        count = [menu numberOfItems];

    if (index < 3)
    {
        for (var i = 0; i < count; ++i)
            [[menu itemAtIndex:i] setState:CPOffState];

        [item setState:CPOnState];

        if (index === 1)
            units = CPByteCountFormatterUseDefault;
        else
            units = CPByteCountFormatterUseAll;
    }
    else
    {
        [[menu itemAtIndex:1] setState:CPOffState];
        [[menu itemAtIndex:2] setState:CPOffState];

        [item setState:itemState === CPOnState ? CPOffState : CPOnState];

        for (var i = 3; i < count; ++i)
            if ([[menu itemAtIndex:i] state] === CPOnState)
                units |= 1 << (i - 3);

        if (units === 0)
            [[menu itemAtIndex:1] setState:CPOnState];
    }

    [[formattedByteCount formatter] setAllowedUnits:units];
    [self propertyChanged:nil];
}

- (void)controlTextDidChange:(CPNotification)aNotification
{
    [self propertyChanged:nil];
}

@end
