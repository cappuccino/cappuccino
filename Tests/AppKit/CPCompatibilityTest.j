@import <Foundation/Foundation.j>
@import <AppKit/CPCompatibility.j>

var SafariUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/27.0.1 Safari/605.1.15";

@implementation CPCompatibilityTest : OJTestCase

/*!
    When CPCompatibility.j loads, it identifies the browser engine from the user
    agent string. For WebKit and Blink browsers (user agent containing
    "AppleWebKit/"), that detection calls +[CPPlatform isBrowser], which reads
    CPDOMAvailable, so CPDOMAvailable must already be assigned at that point.

    The test suite runs outside a browser, with no user agent, so this code is
    never reached when the frameworks load for testing. The test reproduces a
    WebKit or Blink browser load instead: it supplies an AppleWebKit user agent,
    removes CPDOMAvailable, and runs CPCompatibility.j again.
*/
- (void)testLoadUnderWebKitUserAgentDoesNotReadCPDOMAvailableBeforeAssignment
{
    var executable = compatibilityExecutable(),
        runtimeWindow = ObjectiveJ.window,
        savedNavigator = runtimeWindow.navigator,
        savedDOMAvailable = CPDOMAvailable,
        loadException = nil;

    [self assertNotNull:executable message:@"CPCompatibility.j executable not found"];

    runtimeWindow.navigator = { userAgent: SafariUserAgent };
    delete global.CPDOMAvailable;

    try
    {
        executable.execute(YES);
    }
    catch (anException)
    {
        loadException = anException;
    }

    // Restore the Node environment and re-run detection so later tests see it.
    if (savedNavigator === undefined)
        delete runtimeWindow.navigator;
    else
        runtimeWindow.navigator = savedNavigator;

    CPDOMAvailable = savedDOMAvailable;
    executable.execute(YES);

    if (loadException)
        [self fail:@"CPCompatibility.j threw while loading under a WebKit user agent: " + loadException];
}

@end

function compatibilityExecutable()
{
    var executables = ObjectiveJ.FileExecutable.allFileExecutables();

    for (var i = 0; i < executables.length; i++)
        if (/\/CPCompatibility\.j$/.test(executables[i].URL().absoluteString()))
            return executables[i];

    return nil;
}
