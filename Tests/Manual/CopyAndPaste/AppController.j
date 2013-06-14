/*
 * AppController.j
 * CopyAndPaste
 *
 * Created by Alexander Ljungberg on June 13, 2013.
 * Copyright 2013, SlevenBits, Ltd. All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "../CPTrace.j"
@import "CollectionViewItem.j"

@implementation AppController : CPObject
{
    @outlet CPWindow            theWindow;
    @outlet CPCollectionView    aCollectionView;
    @outlet CPArrayController   anArrayController;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    [anArrayController setContent:@[@"Cat", @"Rabbit", @"Dinosaur"]];

    [theWindow setFullPlatformWindow:YES];
}

- (void)copy:(id)sender
{
    // For now just combine multiple selections into a single string.
    var selected = [anArrayController selectedObjects],
        stringValue = selected.join(", "),
        pasteboard = [CPPasteboard generalPasteboard];

    [pasteboard declareTypes:[CPStringPboardType] owner:nil];
    [pasteboard setString:stringValue forType:CPStringPboardType];

    CPLog.info("Copied %@.", stringValue);
}

- (void)cut:(id)sender
{
    [self copy:sender];
    [anArrayController remove:self];
}

- (void)paste:(id)sender
{
    console.log(self + "paste: " + sender);
    var pasteboard = [CPPasteboard generalPasteboard];

    if (![[pasteboard types] containsObject:CPStringPboardType])
        return;

    var stringValue = [pasteboard stringForType:CPStringPboardType],
        parts = [stringValue componentsSeparatedByString:@", "];

    [anArrayController addObjects:parts];

    CPLog.info("Pasted %@.", parts);
}

@end
