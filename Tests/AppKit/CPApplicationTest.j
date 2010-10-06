@import <AppKit/CPApplication.j>
@import <AppKit/CPWindow.j>

@implementation CPApplicationTest : OJTestCase
{
}

- (void)setUp
{
    // This sets up the CPApp convenience variable, the unit tests fails
    // if this is not done, because the framework internally uses CPApp.
    [CPApplication sharedApplication]
}

- (void)testRunModalForWindow
{
    var aWindow = [[CPWindow alloc] init];
    [[CPApplication sharedApplication] runModalForWindow:aWindow];

    [self assertTrue:[aWindow isKeyWindow] message:@"A window must be made key when it's run modally"];
    [self assertFalse:[aWindow isMainWindow] message:@"A window must not become the main window when it's run modally"];
}

@end