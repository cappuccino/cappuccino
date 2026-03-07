/*
 * CPTreeControllerTest.j
 *
 * Test suite for CPTreeController, adapted for Cappuccino
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
    // Root Level
    var engineering = [OrgNode nodeWithName:@"Engineering"],
        marketing =[OrgNode nodeWithName:@"Marketing"];

    // Children of Engineering
    var webTeam = [OrgNode nodeWithName:@"Web Team"],
        backendTeam = [OrgNode nodeWithName:@"Backend Team"];
    
    [engineering setChildren:[CPMutableArray arrayWithObjects:webTeam, backendTeam]];

    // Children of Web Team
    var dev1 =[OrgNode nodeWithName:@"Francisco"],
        dev2 = [OrgNode nodeWithName:@"Ross"];
    
    [webTeam setChildren:[CPMutableArray arrayWithObjects:dev1, dev2]];

    return [CPMutableArray arrayWithObjects:engineering, marketing];
}

- (void)setUp
{
    // Init global CPApp used internally in AppKit
    [[CPApplication alloc] init];

    _contentArray = [self makeTestTree];
    _treeController = [[CPTreeController alloc] init];
    [_treeController setChildrenKeyPath:@"children"];[_treeController setContent:[_contentArray copy]];
}

- (void)testInitWithContent
{[self assert:[_contentArray count] equals:[[_treeController contentArray] count]];
    [self assert:[CPTreeNode class] equals:[[[self treeController] arrangedObjects] class] message:@"arranged objects should be a proxy CPTreeNode root"];
}

- (void)testInitWithoutContent
{
    var emptyController = [[CPTreeController alloc] init];
    [self assert:[] equals:[emptyController contentArray]];[self assert:0 equals:[[[emptyController arrangedObjects] childNodes] count]];
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
    
    // Select Engineering -> Web Team (Index Path: [0, 0])
    var path = [[CPIndexPath indexPathWithIndex:0] indexPathByAddingIndex:0];[controller setSelectionIndexPath:path];
    
    var selectedPath = [controller selectionIndexPath];[self assert:path equals:selectedPath];
    
    var selectedNodes = [controller selectedNodes];
    [self assert:1 equals:[selectedNodes count]];
    [self assert:@"Web Team" equals:[[selectedNodes[0] representedObject] name]];
}

- (void)testAddChild
{
    var controller = [self treeController];
    [controller setObjectClass:[OrgNode class]];
    
    // Select Engineering -> Backend Team (Index Path:[0, 1])
    var parentPath = [[CPIndexPath indexPathWithIndex:0] indexPathByAddingIndex:1];
    [controller setSelectionIndexPath:parentPath];
    
    // Insert a child into Backend Team
    var newDev = [OrgNode nodeWithName:@"Tom"];
    var insertPath =[parentPath indexPathByAddingIndex:0];
    
    [controller insertObject:newDev atArrangedObjectIndexPath:insertPath];
    
    // Validate it was added to the content
    var engineering = [[controller contentArray] objectAtIndex:0],
        backendTeam = [[engineering children] objectAtIndex:1];
        
    [self assert:1 equals:[[backendTeam children] count] message:@"Child should be added to the model object's children array"];[self assert:@"Tom" equals:[[[backendTeam children] objectAtIndex:0] name]];
}

- (void)testInsertObjectAtArrangedObjectIndexPath
{
    var controller = [self treeController];
    
    // Insert at root level, index 1 (between Engineering and Marketing)
    var path =[CPIndexPath indexPathWithIndex:1];
    var hrDept = [OrgNode nodeWithName:@"Human Resources"];[controller insertObject:hrDept atArrangedObjectIndexPath:path];
    
    [self assert:3 equals:[[controller contentArray] count]];
    [self assert:hrDept equals:[[controller contentArray] objectAtIndex:1]];
    
    // Insert nested (Engineering -> HR)
    var nestedPath = [[CPIndexPath indexPathWithIndex:0] indexPathByAddingIndex:0];
    var subDept =[OrgNode nodeWithName:@"Sub Dept"];
    
    [controller insertObject:subDept atArrangedObjectIndexPath:nestedPath];
    var engChildren = [[[controller contentArray] objectAtIndex:0] children];
    [self assert:subDept equals:[engChildren objectAtIndex:0] message:@"Object should be inserted at the correct nested index path"];
}

- (void)testRemoveObjectAtArrangedObjectIndexPath
{
    var controller = [self treeController];
    
    // Remove Engineering -> Web Team -> Francisco (Index Path: [0, 0, 0])
    var path = [[[CPIndexPath indexPathWithIndex:0] indexPathByAddingIndex:0] indexPathByAddingIndex:0];
    
    [controller removeObjectAtArrangedObjectIndexPath:path];
    
    var engineering = [[controller contentArray] objectAtIndex:0],
        webTeam = [[engineering children] objectAtIndex:0];[self assert:1 equals:[[webTeam children] count] message:@"Francisco should be removed, leaving only Ross"];
    [self assert:@"Ross" equals:[[[webTeam children] objectAtIndex:0] name]];
}

- (void)testRemoveObjectsAtArrangedObjectIndexPaths
{
    var controller = [self treeController];
    
    // Remove both Engineering (0) and Marketing (1)
    var paths = [[CPIndexPath indexPathWithIndex:0],
        [CPIndexPath indexPathWithIndex:1]
    ];
    
    [controller removeObjectsAtArrangedObjectIndexPaths:paths];
    
    [self assert:0 equals:[[controller contentArray] count] message:@"All root nodes should be removed"];
}

- (void)testAvoidsEmptySelection
{
    var controller = [self treeController];[controller setAvoidsEmptySelection:YES];
    
    // Set empty selection manually
    [controller setSelectionIndexPaths:[]];
    
    [self assertTrue:([[controller selectionIndexPaths] count] == 1) message:@"Selection should fallback to the first item when avoidsEmptySelection is YES"];
    [self assert:[CPIndexPath indexPathWithIndex:0] equals:[controller selectionIndexPath]];
    
    [controller setAvoidsEmptySelection:NO];[controller setSelectionIndexPaths:[]];
    
    [self assertTrue:([[controller selectionIndexPaths] count] == 0) message:@"Selection should be allowed to be empty when avoidsEmptySelection is NO"];
}

- (void)testChildrenKeyPathOverride
{
    var controller = [[CPTreeController alloc] init];
    // Use a custom key path
    [controller setChildrenKeyPath:@"subItems"];
    
    var data =[OrgNode nodeWithName:@"Root"];
    [data setValue:[CPMutableArray arrayWithObject:[OrgNode nodeWithName:@"Sub"]] forKey:@"subItems"];
    
    [controller setContent:[CPMutableArray arrayWithObject:data]];
    
    // Insert at [0, 0]
    var path = [[CPIndexPath indexPathWithIndex:0] indexPathByAddingIndex:0];
    var newItem = [OrgNode nodeWithName:@"New Sub"];[controller insertObject:newItem atArrangedObjectIndexPath:path];
    
    var subs = [data valueForKey:@"subItems"];
    [self assert:2 equals:[subs count]];
    [self assert:newItem equals:[subs objectAtIndex:0] message:@"Object should be inserted using the custom childrenKeyPath"];
}

- (void)testContentBinding
{
    var controller = [[CPTreeController alloc] init];[controller bind:@"contentArray" toObject:self withKeyPath:@"contentArray" options:nil];

    [self assert:[self contentArray] equals:[controller contentArray]];

    // Verify proxy tree rebuilt
    [self assert:2 equals:[[[controller arrangedObjects] childNodes] count]];
}

- (void)testSelectedObjects
{
    var controller =[self treeController];
    
    // Select Marketing [1]
    var path =[CPIndexPath indexPathWithIndex:1];
    [controller setSelectionIndexPath:path];
    
    var selectedObjects =[controller selectedObjects];
    [self assert:1 equals:[selectedObjects count]];[self assert:@"Marketing" equals:[selectedObjects[0] name]];
}

@end

/* 
 * Dummy Model Class for Testing
 */
@implementation OrgNode : CPObject
{
    CPString        _name @accessors(property=name);
    CPMutableArray  _children @accessors(property=children);
    CPMutableArray  _subItems @accessors(property=subItems); // For testing custom key paths
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
        _subItems =[CPMutableArray array];
    }

    return self;
}

- (CPString)description
{
    return [CPString stringWithFormat:@"<OrgNode %@>", [self name]];
}

@end