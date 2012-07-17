/*
 * AppController.j
 * ArrayControllerSetContentTest
 *
 * Created by You on July 17, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPArrayController.j>
@import <AppKit/CPTextField.j>

@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        contentWidth = [contentView frame].size.width;

    // instantiate a controller
    var controller = [[CPArrayController alloc] init];
    var content = [CPMutableArray array],
        message = [[Message alloc] initWithMessage:@"This is an initial content"];
    [content addObject:message];
    [controller setContent:content];

    // create a field, and establish a binding
    var field = [CPTextField textFieldWithStringValue:@"" placeholder:@"Failed to see a new content" width:contentWidth/2];
    [field setFrameOrigin:CGPointMake(20, 20)];
    [field bind:@"value" toObject:controller withKeyPath:@"selection.message" options:nil];
    [contentView addSubview:field];

    [theWindow orderFront:self];

    [field resignFirstResponder];

    // later, a content is retrieved from a server, and updated by setContent or contetnArray binding. 
    // Here, uses setContent
    var newContent = [CPMutableArray array],
        newMessage = [[Message alloc] initWithMessage:@"Successfully you see a new content"];
    [newContent addObject:newMessage];
    [controller setContent:newContent];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (CPArrayController)controller
{
    return controller;
}

@end

@implementation Message : CPObject
{
    CPString message;
}

- (id)initWithMessage:(CPString)aMessage
{
    self = [super init];
    if (self)
    {
        message = aMessage;
    }
    return self;
}

- (CPString)message
{
    return message;
}

@end

