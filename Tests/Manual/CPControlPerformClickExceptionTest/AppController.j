/*
 * AppController.j
 * CPControlPerformClickExceptionTest
 *
 * Created by Aparajita Fishman on August 21, 2010.
 */

@import <Foundation/CPObject.j>

CPLogRegister(CPLogConsole);

var UseFix = NO;


@implementation AppController : CPObject
{
    CPWindow    theWindow;

    CPButton    button;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(70.0, 70.0, 400.0, 300.0) styleMask:CPTitledWindowMask];
    [theWindow setTitle:@"CPControlPerformClickExceptionTest"];

    var contentView = [theWindow contentView],
        label = [CPTextField labelWithTitle:@"Press the Return key to see the problem and fix"],
        button = [MyButton buttonWithTitle:@"Button"],
        checkbox = [CPCheckBox checkBoxWithTitle:@"Use Fix"];

    [label setFrameOrigin:CGPointMake(50, 50)];
    [contentView addSubview:label];

    [button setFrameOrigin:CGPointMake(50, 90)];
    [button setTarget:self];
    [button setAction:@selector(buttonWasPressed:)];
    [contentView addSubview:button];

    [checkbox setFrameOrigin:CGPointMake(50, 130)];
    [checkbox setTarget:self];
    [checkbox setAction:@selector(useFix:)];
    [contentView addSubview:checkbox];

    [theWindow setDefaultButton:button];
    [theWindow orderFront:nil];
}

- (void)buttonWasPressed:(id)sender
{
    try
    {
        [CPException raise:[[sender window] title] reason:[sender title]];
    }
    finally
    {
        var alert = [[CPAlert alloc] init];

        [alert setTitle:@"Test"];
        [alert setMessageText:UseFix ? @"Note the button has already been unhighlighted." : @"Note the button has not been unhighlighted. It will be when this alert is closed."];
        [alert addButtonWithTitle:@"OK"];
        [alert setDelegate:self];
        [alert runModal];
    }
}

-(void)alertDidEnd:(CPAlert)theAlert returnCode:(int)returnCode
{
    [button highlight:NO];
}

- (void)useFix:(id)sender
{
    UseFix = [sender state] == CPOnState;
}

@end

@implementation MyButton : CPButton

+ (id)buttonWithTitle:(CPString)aTitle
{
    var button = [[[self class] alloc] init];

    [button setTheme:[CPTheme defaultTheme]];
    [button setTitle:aTitle];
    [button sizeToFit];

    return button;
}

- (void)performClick:(id)sender
{
    if (UseFix)
    {
        [super performClick:sender];
        return;
    }

    if (![self isEnabled])
        return;

    [self highlight:YES];
    [self setState:[self nextState]];
    [self sendAction:[self action] to:[self target]];

    [CPTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(unhighlightButtonTimerDidFinish:) userInfo:nil repeats:NO];
}

@end
