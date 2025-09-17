/*
 * AppController.j
 * CPButtonKeyEquivalentDefaultTest
 *
 * Created by Aparajita Fishman on August 20, 2010.
 */

@import <Foundation/CPObject.j>

CPLogRegister(CPLogConsole);


@implementation AppController : CPObject
{
    CPWindow    window1; //this "outlet" is connected automatically by the Cib
    CPWindow    window2;

    CPButton    button1;
    CPButton    button2;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    window2 = [[CPWindow alloc] initWithContentRect:CGRectMake(50.0, 70.0, 300.0, 300.0) styleMask:CPTitledWindowMask];
    [window2 setTitle:@"Code Window"];

    var contentView = [window2 contentView],
        button1 = [CPButton buttonWithTitle:@"Button 1"],
        button2 = [CPButton buttonWithTitle:@"Button 2"],
        changeButton = [CPButton buttonWithTitle:@"Change Default Button"];

    [button1 setFrameOrigin:CGPointMake(20, 20)];
    [button1 setTarget:self];
    [button1 setAction:@selector(buttonWasPressed:)];
    [button1 setTag:1];
    [contentView addSubview:button1];

    [button2 setFrameOrigin:CGPointMake(170, 20)];
    [button2 setTarget:self];
    [button2 setAction:@selector(buttonWasPressed:)];
    [button2 setTag:2];
    [contentView addSubview:button2];

    [changeButton setFrameOrigin:CGPointMake(50, 70)];
    [changeButton setTarget:self];
    [changeButton setAction:@selector(changeDefault:)];
    [contentView addSubview:changeButton];

    [window2 setDefaultButton:button1];
    [window2 orderFront:nil];
}

- (void)buttonWasPressed:(id)sender
{
    var alert = [[CPAlert alloc] init];

    [alert setTitle:@"Test"];
    [alert setMessageText:[CPString stringWithFormat:@"%s - %s", [[sender window] title], [sender title]]];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)changeDefault:(id)sender
{
    var buttonWindow = [sender window],
        tag = [[buttonWindow defaultButton] tag] === 1 ? 2 : 1;

    [buttonWindow setDefaultButton:[[buttonWindow contentView] viewWithTag:tag]];
}

@end
