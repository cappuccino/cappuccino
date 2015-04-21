/*
 * AppController.j
 * CPLocalizationTest
 *
 * Created by You on April 20, 2015.
 * Copyright 2015, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    var label = [CPTextField labelWithTitle:CPLocalizedString(@"Label from file", @"") + " -> Label title from en.lproj from first context"];
    [label setFrameOrigin:CGPointMake(20, 10)];
    [[theWindow contentView] addSubview:label];

    var label2 = [CPTextField labelWithTitle:CPLocalizedString(@"Label from file", @"My second context.") + " -> Label title from en.lproj from second context"];
    [label2 setFrameOrigin:CGPointMake(20, 30)];
    [[theWindow contentView] addSubview:label2];

    var label3 = [CPTextField labelWithTitle:CPLocalizedString(@"Label from file", @"My first context.") + " -> Label title from en.lproj from first context"];
    [label3 setFrameOrigin:CGPointMake(20, 50)];
    [[theWindow contentView] addSubview:label3];

    var label4 = [CPTextField labelWithTitle:CPLocalizedStringFromTable(@"Label from file", @"SecondLocalizable", @"My first context.") + " -> Label title from first context from en.lproj from SecondLocalizable"];
    [label4 setFrameOrigin:CGPointMake(20, 70)];
    [[theWindow contentView] addSubview:label4];

    var label5 = [CPTextField labelWithTitle:CPLocalizedString(@"Wrong key", @"") + " -> Wrong key"];
    [label5 setFrameOrigin:CGPointMake(20, 90)];
    [[theWindow contentView] addSubview:label5];

    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

@end
