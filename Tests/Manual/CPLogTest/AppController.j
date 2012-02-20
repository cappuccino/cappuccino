/*
 * AppController.j
 * CPLogTest
 *
 * Created by Aparajita Fishman on September 3, 2010.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow    theWindow;
}

- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    CPLog.fatal("fatal");
    CPLog.error("error");
    CPLog.warn("warn");
    CPLog.info("info");
    CPLog.debug("debug");
    CPLog.trace("trace");
    CPLog("message");
}

@end
