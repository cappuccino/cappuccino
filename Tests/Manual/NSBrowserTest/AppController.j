/*
 * AppController.j
 * CPBrowserTest
 *
 * Created by You on February 10, 2013.
 * Copyright 2013, Your Company All rights reserved.
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
    @outlet     CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet     CPBrowser   browser;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
    [browser setDelegate:self];

    [browser setTarget:self];
    [browser setAction:@selector(browserClicked:)];
    [browser setDoubleAction:@selector(dblClicked:)];
    [browser registerForDraggedTypes:["Type"]];

    console.log(browser);

}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    // [theWindow setFullPlatformWindow:YES];
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
