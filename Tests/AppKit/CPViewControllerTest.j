@import <AppKit/CPViewController.j>
@import <AppKit/CPApplication.j>

var methodsCalled;
var testResponderChainActionCalled;

@implementation CPViewControllerTest : OJTestCase
{
    CPBundle bundle;
}

- (async void)setUp
{
    bundle = [CPBundle bundleWithPath:@"Tests/AppKit/BundleTest"];
    await [bundle loadWithDelegate:self];
}

- (void)bundleDidFinishLoading:(CPBundle)aBundle
{

}

- (void)testViewControllerCallbacks
{
    methodsCalled = @[];

    var expectedResult = @[@"viewDidLoad",
                           @"viewWillAppear",
                           @"viewDidAppear",
                           @"viewWillDisappear",
                           @"viewDidDisappear"];

    [self assertTrue:[bundle isLoaded]];
    var viewController = [[ViewController alloc] initWithCibName:@"NSViewController.cib" bundle:bundle];
    [self assertNotNull:viewController];

    var superview = [[CPView  alloc] initWithFrame:CGRectMakeZero()];
    var view = [viewController view];

    [superview addSubview:view];
    [view removeFromSuperview];
    [self assert:expectedResult equals:methodsCalled];

    // Explicitely change the view.
    methodsCalled = [];
    expectedResult = @[@"viewWillAppear",
                       @"viewDidAppear",
                       @"viewWillDisappear",
                       @"viewDidDisappear"];

    var newView = [[CPView alloc] initWithFrame:CGRectMake(0,0,100,100)];
    [viewController setView:newView];

    [superview addSubview:newView];
    [newView removeFromSuperview];
    // Checks that with receive notifs from the new view and not from the old view.
    [self assert:expectedResult equals:methodsCalled];
}

- (void)testResponderChain
{
    testResponderChainActionCalled = NO;

    // 1. Create the controller, its view, and a superview.
    var viewController = [[ResponderTestViewController alloc] init];
    var view = [viewController view];
    var superview = [[CPView alloc] init];

    // 2. Add the view to the view hierarchy.
    [superview addSubview:view];

    // 3. Assert the responder chain is correctly wired.
    // The view's next responder should be its controller.
    [self assert:viewController equals:[view nextResponder] message:@"The view controller should be the next responder of its view."];
    // The controller's next responder should be its view's superview.
    [self assert:superview equals:[viewController nextResponder] message:@"The view's superview should be the next responder of the view controller."];

    // 4. Test that an action sent to the view is handled by the controller.
    var wasHandled = [view tryToPerform:@selector(testAction:) with:nil];
    [self assertTrue:wasHandled message:@"The action should be handled by the responder chain."];
    [self assertTrue:testResponderChainActionCalled message:@"The view controller's action method should have been called."];

    // 5. Test that the chain unwires correctly when the view is removed.
    [view removeFromSuperview];
    [self assert:nil equals:[viewController nextResponder] message:@"The next responder should be nil after the view is removed from its superview."];
}

@end

@implementation ViewController : CPViewController
{
}

- (void)viewDidLoad
{
    [methodsCalled addObject:_cmd];
}

- (void)viewDidAppear
{
    [methodsCalled addObject:_cmd];
}

- (void)viewWillAppear
{
    [methodsCalled addObject:_cmd];
}

- (void)viewDidDisappear
{
    [methodsCalled addObject:_cmd];
}

- (void)viewWillDisappear
{
    [methodsCalled addObject:_cmd];
}
@end

@implementation ResponderTestViewController : CPViewController
{
}

- (void)testAction:(id)sender
{
    testResponderChainActionCalled = YES;
}

@end
