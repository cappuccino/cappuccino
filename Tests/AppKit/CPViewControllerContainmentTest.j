/*
 *  CPViewControllerContainmentTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-23.
 *  Copyright David Richardson 2026.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <AppKit/CPViewController.j>

@class _CPContainmentTestContainer
@class _CPContainmentTestObserver

/*
    These tests state the child view controller API of CPViewController as AppKit's
    NSViewController has it: the children in order, the parent of each child, the insert and
    remove primitives that a container subclass overrides, and archiving.
*/
@implementation CPViewControllerContainmentTest : OJTestCase
{
    CPViewController    parent;
    CPViewController    childA;
    CPViewController    childB;
}

- (void)setUp
{
    parent = [[CPViewController alloc] init];
    childA = [[CPViewController alloc] init];
    childB = [[CPViewController alloc] init];
}

- (void)testANewViewControllerHasNoChildrenAndNoParent
{
    [self assert:0 equals:[[parent childViewControllers] count] message:@"no children"];
    [self assertNull:[parent parentViewController] message:@"no parent"];
}

- (void)testAddedChildrenKeepTheirOrderAndKnowTheirParent
{
    [parent addChildViewController:childA];
    [parent addChildViewController:childB];

    [self assert:[childA, childB] equals:[parent childViewControllers] message:@"the children in order"];
    [self assert:parent equals:[childA parentViewController] message:@"the parent of the first child"];
    [self assert:parent equals:[childB parentViewController] message:@"the parent of the second child"];
}

- (void)testAChildCanBeInsertedAtAnIndex
{
    [parent addChildViewController:childA];
    [parent insertChildViewController:childB atIndex:0];

    [self assert:[childB, childA] equals:[parent childViewControllers] message:@"the inserted child comes first"];
}

- (void)testAnInsertionPastTheEndRaisesARangeException
{
    var raised = nil;

    try
    {
        [parent insertChildViewController:childA atIndex:1];
    }
    catch (anException)
    {
        raised = [anException name];
    }

    [self assert:CPRangeException equals:raised message:@"an index past the end raises"];
    [self assertNull:[childA parentViewController] message:@"the child gets no parent"];
}

- (void)testAChildOfAnotherParentMovesToTheNewParent
{
    var otherParent = [[CPViewController alloc] init];

    [otherParent addChildViewController:childA];
    [parent addChildViewController:childA];

    [self assert:0 equals:[[otherParent childViewControllers] count] message:@"the old parent loses the child"];
    [self assert:[childA] equals:[parent childViewControllers] message:@"the new parent has the child"];
    [self assert:parent equals:[childA parentViewController] message:@"the child knows its new parent"];
}

- (void)testAChildCanBeRemovedByIndexOrFromItsParent
{
    [parent addChildViewController:childA];
    [parent addChildViewController:childB];

    [parent removeChildViewControllerAtIndex:0];
    [self assert:[childB] equals:[parent childViewControllers] message:@"removal by index"];
    [self assertNull:[childA parentViewController] message:@"a removed child has no parent"];

    [childB removeFromParentViewController];
    [self assert:0 equals:[[parent childViewControllers] count] message:@"removal from the parent"];
    [self assertNull:[childB parentViewController] message:@"the second removed child has no parent"];
}

- (void)testARemovalByAnIndexOutOfRangeRaisesARangeException
{
    var raised = nil;

    try
    {
        [parent removeChildViewControllerAtIndex:0];
    }
    catch (anException)
    {
        raised = [anException name];
    }

    [self assert:CPRangeException equals:raised message:@"an index out of range raises"];
}

- (void)testSettingTheChildrenGoesThroughTheInsertAndRemovePrimitives
{
    var container = [[_CPContainmentTestContainer alloc] init],
        childC = [[CPViewController alloc] init];

    [container addChildViewController:childA];
    [container addChildViewController:childB];
    container.log = [];

    [container setChildViewControllers:[childB, childC]];

    [self assert:[childB, childC] equals:[container childViewControllers] message:@"the new children"];
    [self assert:["remove 0", "insert 1"] equals:container.log message:@"each change goes through a primitive"];
    [self assertNull:[childA parentViewController] message:@"the dropped child has no parent"];
}

- (void)testTheChildrenChangeIsObservable
{
    var observer = [[_CPContainmentTestObserver alloc] init];

    [parent addObserver:observer forKeyPath:@"childViewControllers" options:0 context:nil];
    [parent addChildViewController:childA];
    [parent removeChildViewControllerAtIndex:0];
    [parent removeObserver:observer forKeyPath:@"childViewControllers"];

    [self assert:2 equals:observer.count message:@"one notification for each change"];
}

- (void)testTheChildrenAreArchived
{
    [childA setTitle:@"First"];
    [childB setTitle:@"Second"];
    [parent addChildViewController:childA];
    [parent addChildViewController:childB];

    var copy = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:parent]],
        children = [copy childViewControllers];

    [self assert:2 equals:[children count] message:@"both children are decoded"];
    [self assert:@"First" equals:[children[0] title] message:@"the first child"];
    [self assert:@"Second" equals:[children[1] title] message:@"the second child"];
    [self assert:copy equals:[children[0] parentViewController] message:@"a decoded child knows its parent"];
}

@end

@implementation _CPContainmentTestContainer : CPViewController
{
    CPArray log;
}

- (void)insertChildViewController:(CPViewController)aChild atIndex:(CPInteger)anIndex
{
    if (log)
        log.push("insert " + anIndex);

    [super insertChildViewController:aChild atIndex:anIndex];
}

- (void)removeChildViewControllerAtIndex:(CPInteger)anIndex
{
    if (log)
        log.push("remove " + anIndex);

    [super removeChildViewControllerAtIndex:anIndex];
}

@end

@implementation _CPContainmentTestObserver : CPObject
{
    int count;
}

- (id)init
{
    if (self = [super init])
        count = 0;

    return self;
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)aChange context:(id)aContext
{
    count++;
}

@end
