@import <AppKit/CPView.j>

@implementation MyView : CPView
{
}

- (CPMenu)menu
{
    var menu = [[CPMenu alloc] initWithTitle:@""];

    [menu addItemWithTitle:@"Item 1" action:nil keyEquivalent:nil];
    [menu addItemWithTitle:@"Item 2" action:nil keyEquivalent:nil];
    [menu addItemWithTitle:@"Item 3" action:nil keyEquivalent:nil];

    return menu;
}

@end