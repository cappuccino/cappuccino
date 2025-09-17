/*
 * AppController.j
 * CPOutlineViewCibTest
 *
 * Created by cacaodev on January 14, 2011.
 * Copyright 2011, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

@implementation AppController : CPObject
{
    @outlet CPWindow      theWindow;
    @outlet CPOutlineView outlineView;

    CPDictionary  rootItem;
}

- (void)awakeFromCib
{
    rootItem = nil;

    var path = [[CPBundle mainBundle] pathForResource:@"InitInfo.dict"],
        request = [CPURLRequest requestWithURL:path],
        connection = [CPURLConnection connectionWithRequest:request delegate:self];

    [theWindow setFullPlatformWindow:YES];
}

- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)dataString
{
    if (!dataString)
        return;

    var data = [[CPData alloc] initWithRawString:dataString];

    rootItem = [CPPropertyListSerialization propertyListFromData:data format:CPPropertyListXMLFormat_v1_0];

    [outlineView reloadData];
}

// ==========================
// ! CPOutlineView Delegate
// ==========================

- (int)outlineView:(CPOutlineView)theOutlineView numberOfChildrenOfItem:(id)theItem
{
    if (theItem == nil)
        theItem = rootItem;

    if ([theItem isKindOfClass:[CPString class]])
        return 0;

    return [[theItem objectForKey:"Children"] count];
}

- (id)outlineView:(CPOutlineView)theOutlineView child:(int)theIndex ofItem:(id)theItem
{
    if (theItem == nil)
        theItem = rootItem;

    return [[theItem objectForKey:"Children"] objectAtIndex:theIndex];
}

- (BOOL)outlineView:(CPOutlineView)theOutlineView isItemExpandable:(id)theItem
{
    if (theItem == nil)
        theItem = rootItem;

    return ![theItem isKindOfClass:[CPString class]];
}

- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)theColumn byItem:(id)theItem
{
    if ([theItem isKindOfClass:[CPString class]])
        return theItem;

    return [theItem objectForKey:"Name"];
}

- (int)outlineView:(CPOutlineView)anOutlineView heightOfRowByItem:(id)anItem
{
    if (!anItem.customHeight)
        anItem.customHeight = 20 + RAND() * 190;

    // strings wont save the property
    if (!anItem.customHeight)
        return 30;


    return anItem.customHeight;
}

@end
