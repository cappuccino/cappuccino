/*
 *  CPWindowCursorUpdateTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-17.
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

@import <AppKit/AppKit.j>

/*
    When the pointer enters several cursor-update tracking areas at once, the window sends
    cursorUpdate: for the area of the frontmost view only. These tests cover views inside the
    content view and views outside it. A toolbar is a subview of the window view, not of the
    content view, so a view added to the window view stands for a toolbar item.
*/

var CursorUpdateTestUpdatedAreas = [];

/*
    A view that records the name of each tracking area for which it receives cursorUpdate:.
*/
@implementation _CursorUpdateTestView : CPView
{
}

- (CPTrackingArea)addCursorAreaNamed:(CPString)aName
{
    var trackingArea = [[CPTrackingArea alloc] initWithRect:[self bounds]
                                                    options:CPTrackingCursorUpdate | CPTrackingActiveInActiveApp
                                                      owner:self
                                                   userInfo:@{ @"name": aName }];

    [self addTrackingArea:trackingArea];

    return trackingArea;
}

- (void)cursorUpdate:(CPEvent)anEvent
{
    CursorUpdateTestUpdatedAreas.push([[[anEvent trackingArea] userInfo] objectForKey:@"name"]);
}

@end

@implementation CPWindowCursorUpdateTest : OJTestCase
{
    CPWindow    window;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 400.0) styleMask:CPWindowNotSizable];
    CursorUpdateTestUpdatedAreas = [];
}

- (CPView)frameView
{
    return [[window contentView] superview];
}

- (void)moveMouseToPoint:(CGPoint)aPoint
{
    var anEvent = [CPEvent mouseEventWithType:CPMouseMoved
                                     location:aPoint
                                modifierFlags:0
                                    timestamp:0
                                 windowNumber:[window windowNumber]
                                      context:nil
                                  eventNumber:-1
                                   clickCount:0
                                     pressure:0];

    [[CPApplication sharedApplication] sendEvent:anEvent];
}

- (void)testTheTopSiblingTakesTheCursorInTheContentView
{
    var lowerView = [[_CursorUpdateTestView alloc] initWithFrame:CGRectMake(10.0, 10.0, 100.0, 100.0)],
        upperView = [[_CursorUpdateTestView alloc] initWithFrame:CGRectMake(50.0, 50.0, 100.0, 100.0)];

    [[window contentView] addSubview:lowerView];
    [[window contentView] addSubview:upperView];
    [lowerView addCursorAreaNamed:@"lower"];
    [upperView addCursorAreaNamed:@"upper"];

    [self moveMouseToPoint:CGPointMake(75.0, 75.0)];

    [self assert:[@"upper"] equals:CursorUpdateTestUpdatedAreas];
}

- (void)testOneViewOutsideTheContentViewTakesTheCursorForItsFirstArea
{
    var view = [[_CursorUpdateTestView alloc] initWithFrame:CGRectMake(10.0, 10.0, 100.0, 100.0)];

    [[self frameView] addSubview:view];
    [view addCursorAreaNamed:@"first"];
    [view addCursorAreaNamed:@"second"];

    [self moveMouseToPoint:CGPointMake(50.0, 50.0)];

    [self assert:[@"first"] equals:CursorUpdateTestUpdatedAreas];
}

- (void)testANestedViewOutsideTheContentViewTakesTheCursorFromItsParent
{
    var parentView = [[_CursorUpdateTestView alloc] initWithFrame:CGRectMake(10.0, 10.0, 200.0, 200.0)],
        childView = [[_CursorUpdateTestView alloc] initWithFrame:CGRectMake(10.0, 10.0, 100.0, 100.0)];

    [[self frameView] addSubview:parentView];
    [parentView addSubview:childView];

    // The child's area is added first, so the window compares the parent against the child.
    [childView addCursorAreaNamed:@"child"];
    [parentView addCursorAreaNamed:@"parent"];

    [self moveMouseToPoint:CGPointMake(50.0, 50.0)];

    [self assert:[@"child"] equals:CursorUpdateTestUpdatedAreas];
}

@end
