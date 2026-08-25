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
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0, 0, 850, 400) styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask],
        contentView = [theWindow contentView];

    [theWindow setTitle:@"CPTreeController Bindings Test"];

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
    [treeController setObjectClass:[Node class]];
    [treeController setChildrenKeyPath:@"children"];
    [treeController setContent:contentArray];

    // 3. Setup Outline View 1 (Left)
    var scrollView1 = [[CPScrollView alloc] initWithFrame:CGRectMake(20, 20, 240, 300)];
    [scrollView1 setAutohidesScrollers:YES];

    var outlineView1 = [[CPOutlineView alloc] initWithFrame:CGRectMake(0, 0, 240, 300)],
        column1 = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [[column1 headerView] setStringValue:@"Outline View 1"];
    [column1 setWidth:230];
    [column1 setEditable:YES];

    [outlineView1 addTableColumn:column1];
    [outlineView1 setOutlineTableColumn:column1];
    [outlineView1 setAllowsMultipleSelection:YES];
    [scrollView1 setDocumentView:outlineView1];
    [contentView addSubview:scrollView1];

    // Bind Outline View 1 (Content & Selection)
    [outlineView1 bind:@"content" toObject:treeController withKeyPath:@"arrangedObjects" options:nil];
    [outlineView1 bind:@"selectionIndexPaths" toObject:treeController withKeyPath:@"selectionIndexPaths" options:nil];

    // 4. Setup Outline View 2 (Middle - Synced)
    var scrollView2 = [[CPScrollView alloc] initWithFrame:CGRectMake(280, 20, 240, 300)];
    [scrollView2 setAutohidesScrollers:YES];

    var outlineView2 = [[CPOutlineView alloc] initWithFrame:CGRectMake(0, 0, 240, 300)],
        column2 = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [[column2 headerView] setStringValue:@"Outline View 2 (Synced)"];
    [column2 setWidth:230];
    [column2 setEditable:YES];

    [outlineView2 addTableColumn:column2];
    [outlineView2 setOutlineTableColumn:column2];
    [outlineView2 setAllowsMultipleSelection:YES];
    [scrollView2 setDocumentView:outlineView2];
    [contentView addSubview:scrollView2];

    // Bind Outline View 2 (Content & Selection)
    [outlineView2 bind:@"content" toObject:treeController withKeyPath:@"arrangedObjects" options:nil];
    [outlineView2 bind:@"selectionIndexPaths" toObject:treeController withKeyPath:@"selectionIndexPaths" options:nil];

    // 5. Setup Inspector / Detail Controls (Right Panel)
    var panelX = 540;

    // Label: Detail Inspector
    var detailLabel = [CPTextField labelWithTitle:@"Detail Binding (selection.name):"];
    [detailLabel setFrameOrigin:CGPointMake(panelX, 20)];
    [contentView addSubview:detailLabel];

    // 2-Way Detail Binding TextField
    var nameField = [CPTextField textFieldWithStringValue:@"" placeholder:@"No Selection" width:260];
    [nameField setFrameOrigin:CGPointMake(panelX, 45)];
    [nameField setEditable:YES];
    [nameField bind:@"value" toObject:treeController withKeyPath:@"selection.name" options:nil];
    [contentView addSubview:nameField];

    // Programmatic Selection Button
    var selectBtn = [CPButton buttonWithTitle:@"Select 'Child 1.2' [0, 1]"];
    [selectBtn setFrame:CGRectMake(panelX, 90, 260, 28)];
    [selectBtn setTarget:self];
    [selectBtn setAction:@selector(selectSpecificNode:)];
    [contentView addSubview:selectBtn];

    // Add Child Button (Action + Enabled Binding)
    var addChildBtn = [CPButton buttonWithTitle:@"Add Child to Selection"];
    [addChildBtn setFrame:CGRectMake(panelX, 125, 260, 28)];
    [addChildBtn setTarget:treeController];
    [addChildBtn setAction:@selector(addChild:)];
    [addChildBtn bind:@"enabled" toObject:treeController withKeyPath:@"canAddChild" options:nil];
    [contentView addSubview:addChildBtn];

    // Remove Selected Button
    var removeBtn = [CPButton buttonWithTitle:@"Remove Selected"];
    [removeBtn setFrame:CGRectMake(panelX, 160, 260, 28)];
    [removeBtn setTarget:treeController];
    [removeBtn setAction:@selector(remove:)];
    [contentView addSubview:removeBtn];

    // Selection Log Label
    var logHeaderLabel = [CPTextField labelWithTitle:@"KVO selectionIndexPaths Log:"];
    [logHeaderLabel setFrameOrigin:CGPointMake(panelX, 210)];
    [contentView addSubview:logHeaderLabel];

    logField = [CPTextField labelWithTitle:@"Selected: Root 1"];
    [logField setFrame:CGRectMake(panelX, 235, 260, 60)];
    [logField setLineBreakMode:CPLineBreakByWordWrapping];
    [contentView addSubview:logField];

    // 6. Register Observer for Live Selection Log
    [treeController addObserver:self forKeyPath:@"selectionIndexPaths" options:CPKeyValueObservingOptionNew context:nil];

    [theWindow center];
    [theWindow orderFront:self];
}

- (void)selectSpecificNode:(id)sender
{
    // Programmatically select index path [0, 1] which is "Child 1.2"
    var path = [CPIndexPath indexPathWithIndexes:[0, 1]];
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
            for (var i = 0; i < [selectedObjects count]; i++)
                [names addObject:[selectedObjects[i] name]];

            [logField setStringValue:[CPString stringWithFormat:@"Selected: %@", [names componentsJoinedByString:@", "]]];
        }
        else
        {
            [logField setStringValue:@"Selected: (Nothing selected)"];
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
        children = someChildren || [];
    }
    return self;
}

- (id)init
{
    return [self initWithName:@"New Node" children:[]];
}

- (void)setName:(CPString)aName
{
    [self willChangeValueForKey:@"name"];
    name = aName;
    [self didChangeValueForKey:@"name"];
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

- (CPString)description
{
    return [CPString stringWithFormat:@"<Node %@>", [self name]];
}

@end
