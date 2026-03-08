/*
 * AppController.j
 * TreeControllerBindingsTest
 *
 * Created for testing CPOutlineView and CPTreeController bindings.
 */

@import <AppKit/AppKit.j>
@import <AppKit/CPTreeController.j>

@implementation AppController : CPObject
{
    CPTreeController treeController;
    CPTextField      logField;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    // 1. Create the Data Model
    var root1 = [[Node alloc] initWithName:@"Root 1" children:[]],
        child1 = [[Node alloc] initWithName:@"Child 1.1" children:[]],
        child2 = [[Node alloc] initWithName:@"Child 1.2" children:[]],
        root2 = [[Node alloc] initWithName:@"Root 2" children:[]],
        child3 = [[Node alloc] initWithName:@"Child 2.1" children:[]];

    [root1 setChildren:[child1, child2]];
    [root2 setChildren:[child3]];
    var contentArray = [root1, root2];

    // 2. Setup the Tree Controller
    treeController = [[CPTreeController alloc] init];
    [treeController setChildrenKeyPath:@"children"];
    [treeController setContent:contentArray];

    // 3. Setup the Outline View
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(20, 20, 250, 300)];
    [scrollView setAutohidesScrollers:YES];

    var outlineView = [[CPOutlineView alloc] initWithFrame:CGRectMake(0, 0, 250, 300)];
    var column = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [[column headerView] setStringValue:@"Node Name"];
    [column setWidth:240];
    [column setEditable:YES]; // Editable to test bidirectional bindings in the tree
    
    [outlineView addTableColumn:column];
    [outlineView setOutlineTableColumn:column];
    [outlineView setAllowsMultipleSelection:YES];
    [scrollView setDocumentView:outlineView];
    [contentView addSubview:scrollView];

    // 4. Establish Bindings for the Outline View
    [outlineView bind:@"content" toObject:treeController withKeyPath:@"arrangedObjects" options:nil];
    [outlineView bind:@"selectionIndexPaths" toObject:treeController withKeyPath:@"selectionIndexPaths" options:nil];

    var scrollView2 = [[CPScrollView alloc] initWithFrame:CGRectMake(300, 20, 250, 300)];
    [scrollView2 setAutohidesScrollers:YES];
    var outlineView2 = [[CPOutlineView alloc] initWithFrame:CGRectMake(0, 0, 250, 300)];
    var column2 = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [[column2 headerView] setStringValue:@"Node Name"];
    [column2 setWidth:240];
    [column2 setEditable:YES]; // Editable to test bidirectional bindings in the tree

    [outlineView2 addTableColumn:column2];
    [outlineView2 setOutlineTableColumn:column2];
    [outlineView2 setAllowsMultipleSelection:YES];
    [scrollView2 setDocumentView:outlineView2];
    [contentView addSubview:scrollView2];

    // 4. Establish Bindings for the Outline View
    [outlineView2 bind:@"content" toObject:treeController withKeyPath:@"arrangedObjects" options:nil];
    [outlineView2 bind:@"selectionIndexPaths" toObject:treeController withKeyPath:@"selectionIndexPaths" options:nil];



    [theWindow orderFront:self];
}

- (void)selectSpecificNode:(id)sender
{
    // Programmatically select index path [0, 1] which is "Child 1.2"
    // This tests the `_CPOutlineViewSelectionIndexPathsBinder` auto-expand logic.
    var path =[CPIndexPath indexPathWithIndexes:[0, 1]];
    [treeController setSelectionIndexPath:path];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    if (keyPath === @"selectionIndexPaths")
    {
        var selectedObjects = [treeController selectedObjects];
        if ([selectedObjects count] > 0)
        {
            var names = [CPMutableArray array];
            for (var i = 0; i <[selectedObjects count]; i++)
                [names addObject:[selectedObjects[i] name]];[logField setStringValue:[names componentsJoinedByString:@", "]];
        }
        else
        {
            [logField setStringValue:@"Nothing selected"];
        }
    }
}

@end


// --- Custom Data Model ---

@implementation Node : CPObject
{
    CPString name;
    CPArray  children;
}

- (id)initWithName:(CPString)aName children:(CPArray)someChildren
{
    self = [super init];
    if (self)
    {
        name = aName;
        children = someChildren;
    }
    return self;
}

// Explicit accessors to ensure Key-Value Observing (KVO) works flawlessly.
- (void)setName:(CPString)aName
{
    [self willChangeValueForKey:@"name"];
    name = aName;[self didChangeValueForKey:@"name"];
}

- (CPString)name
{
    return name;
}

- (void)setChildren:(CPArray)someChildren
{
    [self willChangeValueForKey:@"children"];
    children = someChildren;
    [self didChangeValueForKey:@"children"];
}

- (CPArray)children
{
    return children;
}

@end
