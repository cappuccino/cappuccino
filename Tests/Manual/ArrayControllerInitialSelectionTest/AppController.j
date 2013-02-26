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
    CPString log;
    CPString selectedValue;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        contentWidth = [contentView frame].size.width;

    // instantiate a controller
    var controller = [[CPArrayController alloc] init];
    var content = [CPMutableArray array],
        message = [[Message alloc] initWithMessage:@"This is an initial content" withAppController:self];
    [content addObject:message];
    [controller setContent:content];

    // listen to selectedIndex change
    [controller addObserver:self forKeyPath:@"selectionIndex" options: nil context: nil];

    // create a field, and establish a binding
    var field = [CPTextField textFieldWithStringValue:@"" placeholder:@"bound value appears here..." width:contentWidth/2];
    [field setFrameOrigin:CGPointMake(20, 20)];
    [field bind:@"value" toObject:controller withKeyPath:@"selection.message" options:nil];
    [field setEditable:NO];
    [contentView addSubview:field];

    var logField = [CPTextField textFieldWithStringValue:@"" placeholder:@"access to bound field is logged here..." width:contentWidth/2];
    [logField setFrameOrigin:CGPointMake(20, 50)];
    [logField bind:@"value" toObject:self withKeyPath:@"log" options:nil];
    [logField setEditable:NO];
    [contentView addSubview:logField];

    var selectedField = [CPTextField textFieldWithStringValue:@"" placeholder:@"waiting for a selection" width:contentWidth/2];
    [selectedField setFrameOrigin:CGPointMake(20, 80)];
    [selectedField bind:@"value" toObject:self withKeyPath:@"selectedValue" options:nil];
    [selectedField setEditable:NO];
    [contentView addSubview:selectedField];

    [theWindow orderFront:self];

    // later, a content is retrieved from a server, and updated by setContent or contetnArray binding. 
    // Here, uses setContent
    var newContent = [CPMutableArray array],
        newMessage = [[Message alloc] initWithMessage:@"Successfully you see a new content" withAppController:self];
    [newContent addObject:newMessage];
    [controller setContent:newContent];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (CPArrayController)controller
{
    return controller;
}

- (CPString)log
{
    return log;
}

- (void)setLog:(CPString)aLog
{
    log = aLog;
}

- (CPString)selectedValue
{
    return selectedValue;
}

- (void)setSelectedValue:(CPString)aSelectedValue
{
    selectedValue = aSelectedValue;
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    var newIndex = [change valueForKey:CPKeyValueChangeNewKey],
        selectedObject = [[object content] objectAtIndex:newIndex];

    return [self setSelectedValue:@"Current Value via selectionIndex: " + [selectedObject messageWithoutCheck]];
}

@end

@implementation Message : CPObject
{
    CPString message;
    AppController app;
}

- (id)initWithMessage:(CPString)aMessage withAppController:(AppController)anApp
{
    self = [super init];
    if (self)
    {
        message = aMessage;
        app = anApp;
    }
    return self;
}

- (CPString)message
{
    [app setLog:@"the following message is about to be read: " + message];
    return message;
}

- (CPString)messageWithoutCheck
{
    return message;
}

@end
