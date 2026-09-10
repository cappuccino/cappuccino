/*
 * AppController.j
 * CopyAndPaste
 *
 * Created by Alexander Ljungberg on June 13, 2013.
 * Copyright 2013, SlevenBits, Ltd. All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "CollectionViewItem.j"

@implementation AppController : CPObject
{
    @outlet CPWindow            theWindow;
    @outlet CPCollectionView    aCollectionView;
    @outlet CPArrayController   anArrayController;
    @outlet CPTextField         selectableTextField;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    // http://www.flickr.com/photos/viamoi/2952609526/
    var anImage = CPImageInBundle("2952609526_9fd245dfcd_q.jpg");

    [anArrayController setContent:@[@"Cat", @"Rabbit", @"Dinosaur", anImage]];

    [selectableTextField setStringValue:@"Lion"];

    [theWindow setFullPlatformWindow:YES];
}

- (void)copy:(id)sender
{
    var selected = [anArrayController selectedObjects],
        strings = [],
        images = [];

    for (var i = 0; i < selected.length; i++)
        ([selected[i] isKindOfClass:CPImage] ? images : strings).push(selected[i]);

    var stringValue = strings.join(", "),
        pasteboard = [CPPasteboard generalPasteboard],
        types = [];

    if (stringValue)
        [types addObject:CPStringPboardType]
    if (images)
        [types addObject:CPImagesPboardType]

    [pasteboard declareTypes:types owner:nil];
    if (stringValue)
        [pasteboard setString:stringValue forType:CPStringPboardType];
    if (images)
        [pasteboard setData:[CPKeyedArchiver archivedDataWithRootObject:images] forType:CPImagesPboardType];

    CPLog.info("Copied %@.", (stringValue || "") + " " + (images || ""));
}

- (void)cut:(id)sender
{
    [self copy:sender];
    [anArrayController remove:self];
}

- (void)paste:(id)sender
{
    console.log(self + "paste: " + sender);
    var pasteboard = [CPPasteboard generalPasteboard],
        parts = [];

    if ([[pasteboard types] containsObject:CPStringPboardType])
    {
        var stringValue = [pasteboard stringForType:CPStringPboardType];

        [parts addObjectsFromArray:[stringValue componentsSeparatedByString:@", "]];
    }

    if ([[pasteboard types] containsObject:CPImagesPboardType])
    {
        var images = [CPKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:CPImagesPboardType]];

        [parts addObjectsFromArray:images];
    }

    [anArrayController addObjects:parts];
    CPLog.info("Pasted %@.", parts);
}

@end
