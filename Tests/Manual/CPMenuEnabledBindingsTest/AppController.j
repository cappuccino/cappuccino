/*
 * AppController.j
 * CPMenuTest
 *
 * Created by Daniel Boehringer 2014.
 * Verifies that enabled bindings actually work for menu items
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var mainMenu = [CPApp mainMenu];

    while ([mainMenu numberOfItems] > 0)
        [mainMenu removeItemAtIndex:0];

    var item = [mainMenu insertItemWithTitle:@"My enabled state is bound to the checkbox below" action:nil keyEquivalent:nil atIndex:0];

    [CPMenu setMenuBarVisible:YES];
    var button= [[CPCheckBox alloc] initWithFrame:CGRectMake(30,30,100,25)];
    [item bind: CPEnabledBinding toObject:button withKeyPath:"objectValue" options: nil];
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];
    [contentView addSubview: button];
    [theWindow orderFront:self];
}


@end
