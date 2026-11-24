/*
 *  CPWindowContentViewControllerTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-24.
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

@import <AppKit/CPApplication.j>
@import <AppKit/CPWindow.j>
@import <AppKit/CPWindowController.j>
@import <AppKit/CPViewController.j>
@import <AppKit/_CPCibWindowTemplate.j>

@class _CPContentTestViewController
@class _CPContentTestObserver

/*
    These tests state the content view controller of a window and of a window controller as
    AppKit's NSWindow and NSWindowController have it: the controller's view becomes the content
    view, the window resizes to fit it, a content view set directly drops the controller, the
    responder chain runs from the view through the controller, and the window controller
    follows the window. They also state the archiving of the controller in a cib window
    template.

    The windows are borderless, so a window's frame is its content rect.
*/
@implementation CPWindowContentViewControllerTest : OJTestCase
{
    CPWindow                        window;
    _CPContentTestViewController    viewController;
}

- (void)setUp
{
    [[CPApplication alloc] init];

    window = [[CPWindow alloc] initWithContentRect:CGRectMake(0, 0, 400, 300) styleMask:CPBorderlessWindowMask];
    viewController = [[_CPContentTestViewController alloc] initWithSize:CGSizeMake(250, 150)];
}

- (void)testAWindowHasNoContentViewControllerByDefault
{
    [self assertNull:[window contentViewController] message:@"no content view controller"];
}

- (void)testTheControllerViewBecomesTheContentView
{
    var oldContentView = [window contentView];

    [window setContentViewController:viewController];

    [self assert:viewController equals:[window contentViewController] message:@"the content view controller"];
    [self assert:[viewController view] equals:[window contentView] message:@"the controller's view is the content view"];
    [self assertNull:[oldContentView superview] message:@"the old content view is removed"];
}

- (void)testTheWindowResizesToFitTheControllerView
{
    [window setContentViewController:viewController];

    [self assert:250 equals:CGRectGetWidth([window frame]) message:@"the window width"];
    [self assert:150 equals:CGRectGetHeight([window frame]) message:@"the window height"];
    [self assert:250 equals:CGRectGetWidth([[window contentView] frame]) message:@"the content view keeps its width"];
}

- (void)testAControllerViewWithoutASizeDoesNotResizeTheWindow
{
    [window setContentViewController:[[_CPContentTestViewController alloc] initWithSize:CGSizeMakeZero()]];

    [self assert:400 equals:CGRectGetWidth([window frame]) message:@"the window keeps its width"];
    [self assert:300 equals:CGRectGetHeight([window frame]) message:@"the window keeps its height"];
}

/*
    ojtest has no browser window for a window to fill, so this test marks the window as one
    that fills its platform window without going through -setFullPlatformWindow:.
*/
- (void)testAWindowThatFillsItsPlatformWindowDoesNotResize
{
    window._isFullPlatformWindow = YES;
    [window setContentViewController:viewController];

    [self assert:400 equals:CGRectGetWidth([window frame]) message:@"the window keeps its width"];
}

- (void)testAContentViewSetDirectlyDropsTheController
{
    var observer = [[_CPContentTestObserver alloc] init];

    [window setContentViewController:viewController];
    [window addObserver:observer forKeyPath:@"contentViewController" options:0 context:nil];
    [window setContentView:[[CPView alloc] initWithFrame:CGRectMakeZero()]];
    [window removeObserver:observer forKeyPath:@"contentViewController"];

    [self assertNull:[window contentViewController] message:@"the controller is dropped"];
    [self assert:1 equals:observer.count message:@"observers learn of the change"];
}

- (void)testSettingNilKeepsTheContentView
{
    [window setContentViewController:viewController];
    [window setContentViewController:nil];

    [self assertNull:[window contentViewController] message:@"no controller"];
    [self assert:[viewController view] equals:[window contentView] message:@"the content view stays"];
}

- (void)testTheResponderChainRunsThroughTheController
{
    [window setContentViewController:viewController];

    [self assert:viewController equals:[[window contentView] nextResponder] message:@"the content view's next responder is the controller"];
}

- (void)testAWindowCanBeMadeWithAContentViewController
{
    [viewController setTitle:@"People"];

    var newWindow = [CPWindow windowWithContentViewController:viewController];

    [self assert:viewController equals:[newWindow contentViewController] message:@"the content view controller"];
    [self assert:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask equals:[newWindow styleMask] message:@"the style mask"];
    [self assert:@"People" equals:[newWindow title] message:@"the title comes from the controller"];

    [viewController setTitle:@"Groups"];
    [self assert:@"Groups" equals:[newWindow title] message:@"the title follows the controller"];
}

- (void)testAWindowControllerFollowsItsWindow
{
    var windowController = [[CPWindowController alloc] initWithWindow:window];

    [windowController setContentViewController:viewController];

    [self assert:viewController equals:[window contentViewController] message:@"the window has the controller"];
    [self assert:viewController equals:[windowController contentViewController] message:@"the window controller reports it"];

    [window setContentView:[[CPView alloc] initWithFrame:CGRectMakeZero()]];
    [self assertNull:[windowController contentViewController] message:@"the window controller follows the window"];
}

- (void)testAControllerSetBeforeTheWindowLoadsIsAppliedWhenItLoads
{
    var windowController = [[CPWindowController alloc] init];

    [windowController setContentViewController:viewController];
    [self assert:viewController equals:[windowController contentViewController] message:@"the pending controller"];

    [windowController setWindow:window];
    [self assert:viewController equals:[window contentViewController] message:@"the window gets the controller"];
}

- (void)testAWindowTemplateArchivesTheContentViewController
{
    var template = [[_CPCibWindowTemplate alloc] init];

    template._windowContentViewController = viewController;
    template._windowView = [viewController view];
    template._windowStyleMask = CPBorderlessWindowMask;
    template._windowRect = CGRectMake(0, 0, 250, 150);

    var copy = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:template]],
        newWindow = [copy _cibInstantiate],
        newController = [newWindow contentViewController];

    [self assertNotNull:newController message:@"the window has a content view controller"];
    [self assert:[newController view] equals:[newWindow contentView] message:@"the controller's view is the content view"];
    [self assert:250 equals:CGRectGetWidth([newWindow frame]) message:@"the window keeps the template's frame"];
}

@end

@implementation _CPContentTestViewController : CPViewController
{
    CGSize _size;
}

- (id)initWithSize:(CGSize)aSize
{
    if (self = [super initWithCibName:nil bundle:nil])
        _size = aSize;

    return self;
}

- (void)loadView
{
    [self setView:[[CPView alloc] initWithFrame:CGRectMake(0, 0, _size.width, _size.height)]];
}

@end

@implementation _CPContentTestObserver : CPObject
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
