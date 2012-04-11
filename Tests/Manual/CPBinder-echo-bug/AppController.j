/*
 * AppController.j
 * CPBinder-echo-bug
 *
 * Created by You on March 29, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    var message = [[CPTextField alloc] initWithFrame:CGRectMake(10,10,1000,32)];
    [message setFont:[CPFont boldSystemFontOfSize:16.0]];
    [message setStringValue:@"Type some text in the text field and press enter. You should NOT see any new call to -setObjectValue: in the console"];
    [contentView addSubview:message];

    var label = [[TextField alloc] initWithFrame:CGRectMake(0,0,400,22)];
    [label setPlaceholderString:@"Type some text and hit enter"];
    [label setBezeled:YES];
    [label setBezelStyle:CPTextFieldSquareBezel];
    [label setBordered:YES];
    [label setEditable:YES];

    var oc = [[CPObjectController alloc] initWithContent:[CPDictionary dictionaryWithObject:@"" forKey:@"foo"]];
    [oc setAutomaticallyPreparesContent:YES];

    [label bind:CPValueBinding toObject:oc withKeyPath:@"selection.foo" options:nil];
    [label setFont:[CPFont boldSystemFontOfSize:24.0]];
    [label setBackgroundColor:[CPColor greenColor]];
    [label sizeToFit];

    [label setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [label setCenter:[contentView center]];

    [contentView addSubview:label];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

@end

@implementation TextField : CPTextField
{
}

- (void)setObjectValue:(id)aValue
{
    CPLogConsole(_cmd + [super objectValue] + " > " + aValue);
    [self setBackgroundColor:[CPColor redColor]];
    [super setObjectValue:aValue];
}

@end
