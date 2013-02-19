/*
 * AppController.j
 * CPBrowserTest
 *
 * Created by Ross Boucher on March 23, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPBrowser.j>

@implementation Node : CPObject
{
    id value;
}

+ (id)withValue:(id)aValue
{
    var a = [[self alloc] init];
    a.value = aValue;
    return a;
}

- (id)value
{
    return value;
}

- (CPArray)children
{
    return [[Node withValue:1],
            [Node withValue:2],
            [Node withValue:3],
            [Node withValue:2],
            [Node withValue:3],
            [Node withValue:2],
            [Node withValue:3],
            [Node withValue:2],
            [Node withValue:3],
            [Node withValue:2],
            [Node withValue:3],
            [Node withValue:2],
            [Node withValue:3],
            [Node withValue:4]];
}

@end

@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    var box = [[CPBox alloc] initWithFrame:CGRectMake(0, 0, 500, 300)],
        browser = [[CPBrowser alloc] initWithFrame:CGRectMake(0, 0, 500, 300)];

    [browser setWidth:300 ofColumn:1];
    [box setContentView:browser];
    [box setBorderType:CPBezelBorder];
    [box setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [box setCenter:[contentView center]];
    [contentView addSubview:box];

    [theWindow orderFront:self];

    [browser setDelegate:self];

    [browser setTarget:self];
    [browser setAction:@selector(browserClicked:)];
    [browser setDoubleAction:@selector(dblClicked:)];
    [browser registerForDraggedTypes:["Type"]];

    //[browser setAllowsMultipleSelection:NO];
}

- (BOOL)browser:(CPBrowser)aBrowser writeRowsWithIndexes:(CPIndexSet)indexes inColumn:(int)column toPasteboard:(CPPasteboard)pboard
{
    var encodedData = [CPKeyedArchiver archivedDataWithRootObject:"Foo"];
    [pboard declareTypes:["Type"] owner:self];
    [pboard setData:encodedData forType:"Type"];
    return YES;
}

- (BOOL)browser:(id)aBrowser validateDrop:(id)info proposedRow:(int)row column:(int)column dropOperation:(id)op
{
    return CPDragOperationMove;
}
- (BOOL)browser:(id)aBrowser acceptDrop:(id)info atRow:(int)row column:(int)column dropOperation:(id)op
{
    return YES;
}

- (void)browserClicked:(id)aBrowser
{
    console.log("selected column: " + [aBrowser selectedColumn] + " row: " + [aBrowser selectedRowInColumn:[aBrowser selectedColumn]]);
}

- (void)dblClicked:(id)sender
{
    alert("DOUBLE");
}

/*- (id)rootItemForBrowser:(id)aBrowser
{
    return [Node withValue:0];
}*/

- (id)browser:(id)aBrowser numberOfChildrenOfItem:(id)anItem
{
    if (anItem === nil)
        return 4;
    return [[anItem children] count];
}

- (id)browser:(id)aBrowser child:(int)index ofItem:(id)anItem
{
    if (!anItem)
        return [[[Node withValue:0] children] objectAtIndex:index];

    return [[anItem children] objectAtIndex:index];
}

- (id)browser:(id)aBrowser imageValueForItem:(id)anItem
{
    return [[CPImage alloc] initWithContentsOfFile:"http://cappuccino-project.org/img/favicon.ico" size:CGSizeMake(16, 16)];
}

- (id)browser:(id)aBrowser objectValueForItem:(id)anItem
{
    return [anItem value];
}

- (id)browser:(id)aBrowser isLeafItem:(id)anItem
{
    return ![[anItem children] count] || [anItem value] === 4;
}

@end
