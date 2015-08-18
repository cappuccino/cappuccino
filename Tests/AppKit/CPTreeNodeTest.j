@import <AppKit/CPTreeNode.j>

@implementation CPTreeNodeTest : OJTestCase
{
    CPTreeNode treeNode;
    CPTreeNode childNode;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    treeNode = [CPTreeNode treeNodeWithRepresentedObject:nil];

    childNode = [CPTreeNode treeNodeWithRepresentedObject:nil];
    [treeNode insertObject:childNode inChildNodesAtIndex:0];
}

- (void)testDescendantNodeAtIndexPath
{
    var indexPath = [CPIndexPath indexPathWithIndex:0];

    [self assert:childNode equals:[treeNode descendantNodeAtIndexPath:indexPath]];

    indexPath = [CPIndexPath indexPathWithIndex:1];

    [self assert:undefined equals:[treeNode descendantNodeAtIndexPath:indexPath]];
}

@end
