@import <AppKit/CPApplication.j>
@import <AppKit/CPWindow.j>
@import <AppKit/_CPStandardWindowView.j>

var globalResults = [];

@implementation MyAppDelegate : CPObject
{
}

- (void)delegateMethod
{
    globalResults.push(@"delegateMethod called");
}
@end

@implementation CPApplication(TestMethods)
{
}

- (void)someTestMethod:(id)someArg
{
    globalResults.push(@"someTestMethod called with: " + someArg);
}
@end

@implementation TestMainWindow : CPWindow
{
}

- (void)onlyOnMain
{
    globalResults.push(@"onlyOnMain called");
}

- (void)onBoth
{
    globalResults.push(@"onBoth called on main");
}
@end

@implementation TestKeyWindow : CPWindow
{
}

- (void)onlyOnKey
{
    globalResults.push(@"onlyOnKey called");
}

- (void)onBoth
{
    globalResults.push(@"onBoth called on key");
}
@end


@implementation CPApplicationTest : OJTestCase
{
    CPApplication app;
    CPWindow aWindow;
}

- (void)setUp
{
    // This sets up the CPApp convenience variable, the unit tests fails
    // if this is not done, because the framework internally uses CPApp.
    app = [CPApplication sharedApplication];

    // fake the window.location.hash
    window.location = {hash: "#var1=1/var2=2"};
    [app setDelegate:[[MyAppDelegate alloc] init]];

    aWindow = [[CPWindow alloc] init];
    aWindow._isVisible = YES;
    [aWindow setTitle:@"My Great Window"];

    globalResults = []
}

- (void)tearDown
{
    // This is the only way to clear the global window list between tests. You'd normally never do this.
    CPApp = nil;
}

- (void)receiveNotification:(CPNotification)aNote
{
    globalResults.push(aNote);
}

- (void)testRunModalForWindow
{
    var modalWindow = [[CPWindow alloc] init];
    [app runModalForWindow:modalWindow];

    [self assertTrue:[modalWindow isKeyWindow] message:@"A window must be made key when it's run modally"];
    [self assertFalse:[modalWindow isMainWindow] message:@"A window must not become the main window when it's run modally"];

    [app abortModal];
}

- (void)testModalWindow
{
    var modalWindow = [[CPWindow alloc] init];
    [modalWindow setTitle:@"I am so modal!"];
    [self assert:nil equals:[app modalWindow]];
    [app runModalForWindow:modalWindow];
    [self assert:@"I am so modal!" equals:[[app modalWindow] title]];
    [app abortModal];
}

- (void)testAbortModal
{
    var modalWindow = [[CPWindow alloc] init];
    [modalWindow setTitle:@"I am so modal!"];
    [self assert:nil equals:[app modalWindow]];
    [app runModalForWindow:modalWindow];
    [self assert:@"I am so modal!" equals:[[app modalWindow] title]];
    [app abortModal];

    [self assert:nil equals:[app modalWindow]];
}

- (void)testStopModal
{
    var modalWindow = [[CPWindow alloc] init];
    [modalWindow setTitle:@"I am so modal!"];
    [self assert:nil equals:[app modalWindow]];
    [app runModalForWindow:modalWindow];
    [self assert:@"I am so modal!" equals:[[app modalWindow] title]];
    [app stopModal];

    [self assert:nil equals:[app modalWindow]];
}

- (void)testArguments
{
    [self assert:["var1=1", "var2=2"] equals:[app arguments]];
}

- (void)testSetArguments
{
    [app setArguments:["a", "b"]];
    [self assert:["a", "b"] equals:[app arguments]];

    [app setArguments:@"c/d"];
    [self assert:["c/d"] equals:[app arguments]];
}

- (void)testDelegate
{
    [self assert:[[app delegate] class] equals:MyAppDelegate];
}

- (void)testDoCommandBySelector
{
    [app doCommandBySelector:@selector(delegateMethod)];
    [self assert:@"delegateMethod called" equals:globalResults[0]];
}

- (void)testActivateIgnoringOtherApps
{
    [app activateIgnoringOtherApps:YES];
    [self assertTrue:[app isActive]];
}

- (void)testDeactivate
{
    [app deactivate];
    [self assertFalse:[app isActive]];
}

- (void)testMainWindow
{
    [self assertTrue:[aWindow canBecomeMainWindow]];
    [aWindow makeMainWindow];
    [self assert:@"My Great Window" equals:[[app mainWindow] title]];
}

- (void)testKeyWindow
{
    [self assert:nil equals:[app keyWindow]];
    [aWindow becomeKeyWindow];
    [self assert:@"My Great Window" equals:[[app keyWindow] title]];
    [aWindow resignKeyWindow];
    [self assert:nil equals:[app keyWindow]];
}

- (void)testWindows
{
    [self assert:[[aWindow title]] equals:[[app windows] valueForKey:@"title"]];
}

- (void)testWindowWithWindowNumber
{
    [self assert:@"My Great Window" equals:[[app windowWithWindowNumber:[aWindow windowNumber]] title]];
}

- (void)testReplyToApplicationShouldTerminate
{
    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:)
                                                 name:CPApplicationWillTerminateNotification
                                               object:nil];

    [app replyToApplicationShouldTerminate:CPTerminateNow];
    [self assert:CPApplicationWillTerminateNotification equals:[globalResults[0] name]];

    [[CPNotificationCenter defaultCenter] removeObserver:self];
}

- (void)testTryToPerformWith
{
    //first on self
    var success = [app tryToPerform:@selector(someTestMethod:) with:@"Sweet!"];
    [self assertTrue:success];
    [self assert:@"someTestMethod called with: Sweet!" equals:globalResults[0]];

    //if the method isn't found on self, it should be called on the delegate
    globalResults = []
    var success = [app tryToPerform:@selector(delegateMethod) with:nil];
    [self assertTrue:success];
    [self assert:@"delegateMethod called" equals:globalResults[0]];

    //method isn't defined anywhere
    var success = [app tryToPerform:@selector(someMethodThatDoesNotExist:) with:@"Sweet!"];
    [self assertFalse:success];
}

- (void)testTargetForAction
{
    var mainWin = [[TestMainWindow alloc] init],
        keyWin = [[TestKeyWindow alloc] init];
    mainWin._isVisible = YES;
    keyWin._isVisible = YES;
    [mainWin makeMainWindow];
    [keyWin becomeKeyWindow];

    //key should be first
    [self assert:keyWin equals:[app targetForAction:@selector(onBoth)]];
    [self assert:keyWin equals:[app targetForAction:@selector(onlyOnKey)]];

    //then main
    [self assert:mainWin equals:[app targetForAction:@selector(onlyOnMain)]];
    [keyWin resignKeyWindow];
    [self assert:mainWin equals:[app targetForAction:@selector(onBoth)]];

    //then self
    [self assert:app equals:[app targetForAction:@selector(someTestMethod:)]];

    //then the delegate
    [self assert:MyAppDelegate equals:[[app targetForAction:@selector(delegateMethod)] class]];
}

- (void)testTargetForActionToFrom
{
    [self assert:@"some object" equals:[app targetForAction:@selector(anything) to:@"some object" from:nil]];

    // when no target is given, targetForAction is called
    [self assert:app equals:[app targetForAction:@selector(someTestMethod:) to:nil from:nil]];
}

@end
