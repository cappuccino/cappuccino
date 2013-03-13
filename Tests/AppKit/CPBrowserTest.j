@import <AppKit/AppKit.j>

@implementation CPBrowserTest : OJTestCase
{
    CPBrowser   browser;
    CPBrowserDelegate delegate;
}

- (void)setUp
{
    browser = [[CPBrowser alloc] initWithFrame:CGRectMake(0, 0, 500, 300)];
    delegate = [CPBrowserDelegate new];
    [delegate setEntries:[".1", ".1.1", ".1.2", ".1.2.1", ".1.2.2", ".2", ".3", ".3.1"]];
    [browser setDelegate:delegate];
}

/*!
    Verify that the items are loaded into rows in their proper columns.
*/
- (void)testRows
{
    [self assert:".1" equals:[browser itemAtRow:0 inColumn:0]];
    [self assert:".2" equals:[browser itemAtRow:1 inColumn:0]];
    [self assert:".3" equals:[browser itemAtRow:2 inColumn:0]];

    // Only one column so far.
    [self assert:nil equals:[browser itemAtRow:0 inColumn:1]];

    // Drill down.
    [browser selectRowIndexes:[CPIndexSet indexSetWithIndex:0] inColumn:0];
    [browser addColumn];
    [self assert:".1.1" equals:[browser itemAtRow:0 inColumn:1]];
    [self assert:".1.2" equals:[browser itemAtRow:1 inColumn:1]];
}

- (void)testCoding
{
    // This should preferably not crash.
    var decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:browser]];

    // This basic test will serve to verify that the decoded object is not broken.
    browser = decoded;
    [self testRows];
}

@end

@implementation CPBrowserDelegate : CPObject
{
    CPArray entries @accessors;
}

- (CPArray)childrenOfPrefix:(CPString)theItem
{
    if (!theItem)
        theItem = "";

    var matcher = new RegExp("^" + theItem + "\\.\\d$"),
        children = [];
    for (var i = 0; i < entries.length; i++)
        if (matcher.exec(entries[i]))
            children.push(entries[i]);

    return children;
}

- (id)browser:(id)aBrowser numberOfChildrenOfItem:(id)theItem
{
    return [[self childrenOfPrefix:theItem] count];
}

- (id)browser:(id)aBrowser child:(int)theIndex ofItem:(id)theItem
{
    return [self childrenOfPrefix:theItem][theIndex];
}

- (id)browser:(id)aBrowser objectValueForItem:(id)theItem
{
    return theItem;
}

- (id)browser:(id)aBrowser isLeafItem:(id)theItem
{
    return ![[self childrenOfPrefix:theItem] count];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        entries = [aCoder decodeObjectForKey:"entries"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:entries forKey:"entries"];
}

@end
