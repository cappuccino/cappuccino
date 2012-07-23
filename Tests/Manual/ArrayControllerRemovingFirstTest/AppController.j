/*
 * AppController.j
 * ArrayControllerRemovingFirstTest
 *
 * Created by You on July 17, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPArrayController arrayController;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    arrayController = [[CPArrayController alloc] init];
    [arrayController addObserver:self forKeyPath:@"selectionIndex" options: nil context: nil];
    var items = [CPMutableArray array];
    [items addObject:[[Item alloc] initWithTitle:@"1st Item"]];
    [items addObject:[[Item alloc] initWithTitle:@"2nd Item"]];
    [items addObject:[[Item alloc] initWithTitle:@"3rd Item"]];
    [items addObject:[[Item alloc] initWithTitle:@"4th Item"]];
    [arrayController setContent:items];

    var label = [CPTextField labelWithTitle:@"Press buttons to see [Remove First By Object] fails while [Remove First By Index] succeeds"];
    [label setFrameOrigin:CGPointMake(20, 20)];    
    [contentView addSubview:label];

    var field = [CPTextField textFieldWithStringValue:@"" placeholder:@"" width:100];
    [field setFrameOrigin:CGPointMake(20, 50)];
    [field bind:@"value" toObject:self withKeyPath:@"arrayController.selection.title" options:nil];
    [contentView addSubview:field];

    var button = [CPButton buttonWithTitle:@"Remove First By Object"];
    [button setFrameOrigin:CGPointMake(150, 50)];
    [button setTarget:self];
    [button setAction:@selector(removeFirst:)];
    [contentView addSubview:button];

    var button2 = [CPButton buttonWithTitle:@"Remove First By Index"];
    [button2 setFrameOrigin:CGPointMake(350, 50)];
    [button2 setTarget:self];
    [button2 setAction:@selector(removeFirstByIndex:)];
    [contentView addSubview:button2];

    [arrayController setSelectionIndex:0]

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (void)removeFirst:(id)sender
{
    var selectedObjects = [arrayController selectedObjects];
    [arrayController removeObject:[selectedObjects objectAtIndex:0]];
}

- (void)removeFirstByIndex:(id)sender
{
    [arrayController removeObjectAtArrangedObjectIndex:0];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    var oldIndex = [change valueForKey:CPKeyValueChangeOldKey];
    var newIndex = [change valueForKey:CPKeyValueChangeNewKey];

    CPLog("TCDocument selectionIndexChanged from " + oldIndex + " to " + newIndex + ", contains " + [[arrayController arrangedObjects] count] + " objects");
}

@end

@implementation Item : CPObject
{
    CPString title;
}

- (id)initWithTitle:(CPString)aTitle
{
    self = [super init];
    if (self)
    {
        title = aTitle;
    }
    return self;
}

- (CPString)title
{
    return title;
}

@end

