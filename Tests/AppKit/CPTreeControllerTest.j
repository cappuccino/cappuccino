/*
 * CPTreeControllerTest.j
 *
 * Test suite for CPTreeController
 */

@import <Foundation/CPArray.j>
@import <Foundation/CPIndexPath.j>
@import <AppKit/CPTreeController.j>
@import <AppKit/CPTreeNode.j>
@import <AppKit/CPTextField.j>

@class OrgNode

@implementation CPTreeControllerTest : OJTestCase
{
    CPTreeController    _treeController @accessors(property=treeController);
    CPArray             _contentArray @accessors(property=contentArray);

    CPArray             observations;
    int                 aCount @accessors;
}

- (CPArray)makeTestTree
{
    var engineering = [OrgNode nodeWithName:@"Engineering"],
    marketing = [OrgNode nodeWithName:@"Marketing"];

    var webTeam = [OrgNode nodeWithName:@"Web Team"],
    backendTeam = [OrgNode nodeWithName:@"Backend Team"];

    [engineering setChildren:[CPMutableArray arrayWithObjects:webTeam, backendTeam]];

    var dev1 = [OrgNode nodeWithName:@"Francisco"],
    dev2 = [OrgNode nodeWithName:@"Ross"];

    [webTeam setChildren:[CPMutableArray arrayWithObjects:dev1, dev2]];

    return [CPMutableArray arrayWithObjects:engineering, marketing];
}

- (void)setUp
{
    [[CPApplication alloc] init];

    _contentArray = [self makeTestTree];
    _treeController = [[CPTreeController alloc] init];
    [_treeController setChildrenKeyPath:@"children"];
    [_treeController setContent:[_contentArray copy]];
}

- (void)testInitWithContent
{
    [self assert:[_contentArray count] equals:[[_treeController contentArray] count]];
    [self assert:[CPTreeNode class] equals:[[[self treeController] arrangedObjects] class] message:@"arranged objects should be a proxy CPTreeNode root"];
}

- (void)testInitWithoutContent
{
    var emptyController = [[CPTreeController alloc] init];
    [self assert:[CPArray array] equals:[emptyController contentArray]];
    [self assert:0 equals:[[[emptyController arrangedObjects] childNodes] count]];
}

- (void)testSetContent
{
    var newTree = [CPMutableArray arrayWithObject:[OrgNode nodeWithName:@"Solo Department"]];
    [[self treeController] setContent:newTree];

    [self assert:newTree equals:[[self treeController] contentArray]];
    [self assert:1 equals:[[[[self treeController] arrangedObjects] childNodes] count]];
}

- (void)testSelectionPaths
{
    var controller = [self treeController];

    var path = [[CPIndexPath indexPathWithIndex:0] indexPathByAddingIndex:0];
    [controller setSelectionIndexPath:path];

    var selectedPath = [controller selectionIndexPath];
    [self assert:path equals:selectedPath];

    var selectedNodes = [controller selectedNodes];
    [self assert:1 equals:[selectedNodes count]];
    [self assert:@"Web Team" equals:[[[selectedNodes objectAtIndex:0] representedObject] name]];
}

- (void)testAddChild
{
    var controller = [self treeController];
    [controller setObjectClass:[OrgNode class]];

    var parentPath = [[CPIndexPath indexPathWithIndex:0] indexPathByAddingIndex:1];
    [controller setSelectionIndexPath:parentPath];

    var newDev = [OrgNode nodeWithName:@"Tom"];
    var insertPath = [parentPath indexPathByAddingIndex:0];
    [controller insertObject:newDev atArrangedObjectIndexPath:insertPath];

    var engineering = [[controller contentArray] objectAtIndex:0],
    backendTeam = [[engineering children] objectAtIndex:1];
    [self assert:1 equals:[[backendTeam children] count] message:@"Child should be added to the model object's children array"];
    [self assert:@"Tom" equals:[[[backendTeam children] objectAtIndex:0] name]];
}

- (void)testInsertObjectAtArrangedObjectIndexPath
{
    var controller = [self treeController];

    var path = [CPIndexPath indexPathWithIndex:1];
    var hrDept = [OrgNode nodeWithName:@"Human Resources"];

    [controller insertObject:hrDept atArrangedObjectIndexPath:path];
    [self assert:3 equals:[[controller contentArray] count]];
    [self assert:hrDept equals:[[controller contentArray] objectAtIndex:1]];

    var nestedPath = [[CPIndexPath indexPathWithIndex:0] indexPathByAddingIndex:0];
    var subDept = [OrgNode nodeWithName:@"Sub Dept"];

    [controller insertObject:subDept atArrangedObjectIndexPath:nestedPath];
    var engChildren = [[[controller contentArray] objectAtIndex:0] children];
    [self assert:subDept equals:[engChildren objectAtIndex:0] message:@"Object should be inserted at the correct nested index path"];
}

- (void)testRemoveObjectAtArrangedObjectIndexPath
{
    var controller = [self treeController];

    var path = [[[CPIndexPath indexPathWithIndex:0] indexPathByAddingIndex:0] indexPathByAddingIndex:0];

    [controller removeObjectAtArrangedObjectIndexPath:path];

    var engineering = [[controller contentArray] objectAtIndex:0],
    webTeam = [[engineering children] objectAtIndex:0];

    [self assert:1 equals:[[webTeam children] count] message:@"Francisco should be removed, leaving only Ross"];
    [self assert:@"Ross" equals:[[[webTeam children] objectAtIndex:0] name]];
}

- (void)testRemoveObjectsAtArrangedObjectIndexPaths
{
    var controller = [self treeController];

    var paths = [CPArray arrayWithObjects:[CPIndexPath indexPathWithIndex:0], [CPIndexPath indexPathWithIndex:1]];

    [controller removeObjectsAtArrangedObjectIndexPaths:paths];

    [self assert:0 equals:[[controller contentArray] count] message:@"All root nodes should be removed"];
}

- (void)testSelectingEmptyIndexPathsExplicitlyWithAvoidsEmptySelection
{
    var controller = [self treeController];

    [controller setAvoidsEmptySelection:YES];

    [controller setSelectionIndexPath:[CPIndexPath indexPathWithIndex:0]];
    [controller setSelectionIndexPaths:[CPArray array]];

    [self assertTrue:([[controller selectionIndexPaths] count] == 0) message:@"Selection should be empty when unselecting explicitly, even with avoidsEmptySelection"];
}

- (void)testAvoidsEmptySelectionWhenRemoving
{
    var controller = [self treeController];
    [controller setAvoidsEmptySelection:YES];

    var path = [CPIndexPath indexPathWithIndex:0];
    [controller setSelectionIndexPath:path];

    // Remove "Engineering"
    [controller removeObjectAtArrangedObjectIndexPath:path];

    [self assertTrue:([[controller selectionIndexPaths] count] == 1) message:@"Selection should fallback to the first item when avoidsEmptySelection is YES"];
    // "Marketing" is now at index 0
    [self assert:[CPIndexPath indexPathWithIndex:0] equals:[controller selectionIndexPath]];

    // Test behavior when AvoidsEmptySelection is NO[controller insertObject:[OrgNode nodeWithName:@"New Dept"] atArrangedObjectIndexPath:[CPIndexPath indexPathWithIndex:1]];
    [controller setAvoidsEmptySelection:NO];

    // Reselect "Marketing" at index 0
    [controller setSelectionIndexPath:[CPIndexPath indexPathWithIndex:0]];

    // Remove "Marketing"
    [controller removeObjectAtArrangedObjectIndexPath:[CPIndexPath indexPathWithIndex:0]];

    [self assertTrue:([[controller selectionIndexPaths] count] == 0) message:@"Selection should be allowed to be empty when avoidsEmptySelection is NO"];
}

- (void)testChildrenKeyPathOverride
{
    var controller = [[CPTreeController alloc] init];
    [controller setChildrenKeyPath:@"subItems"];

    var data = [OrgNode nodeWithName:@"Root"];

    [data setValue:[CPMutableArray arrayWithObject:[OrgNode nodeWithName:@"Sub"]] forKey:@"subItems"];
    [controller setContent:[CPMutableArray arrayWithObject:data]];

    var path = [[CPIndexPath indexPathWithIndex:0] indexPathByAddingIndex:0];
    var newItem = [OrgNode nodeWithName:@"New Sub"];
    [controller insertObject:newItem atArrangedObjectIndexPath:path];

    var subs = [data valueForKey:@"subItems"];
    [self assert:2 equals:[subs count]];
    [self assert:newItem equals:[subs objectAtIndex:0] message:@"Object should be inserted using the custom childrenKeyPath"];
}

- (void)testContentBinding
{
    var controller = [[CPTreeController alloc] init];

    [controller bind:@"contentArray" toObject:self withKeyPath:@"contentArray" options:nil];
    [self assert:[self contentArray] equals:[controller contentArray]];
    [self assert:2 equals:[[[controller arrangedObjects] childNodes] count]];
}

- (void)testSelectedObjects
{
    var controller = [self treeController];

    var path = [CPIndexPath indexPathWithIndex:1];
    [controller setSelectionIndexPath:path];

    var selectedObjects = [controller selectedObjects];

    [self assert:1 equals:[selectedObjects count]];
    [self assert:@"Marketing" equals:[[selectedObjects objectAtIndex:0] name]];
}

@end

/*
 * Dummy Model Class for Testing
 */
@implementation OrgNode : CPObject
{
    CPString        _name @accessors(property=name);
    CPMutableArray  _children @accessors(property=children);
    CPMutableArray  _subItems @accessors(property=subItems);
}

+ (id)nodeWithName:(CPString)aName
{
    return [[self alloc] initWithName:aName];
}

- (id)initWithName:(CPString)aName
{
    if (self = [super init])
    {
        _name = aName;
        _children = [CPMutableArray array];
        _subItems = [CPMutableArray array];
    }

    return self;
}

- (CPString)description
{
    return [CPString stringWithFormat:@"<OrgNode %@>", [self name]];
}

@end
