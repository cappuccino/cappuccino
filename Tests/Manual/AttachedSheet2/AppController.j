@import <Foundation/CPObject.j>

@import "SheetWindowController.j"

@implementation AppController : CPObject
{
    SheetController _sheetController;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
}

- (void)awakeFromCib
{
    _sheetController = [[SheetWindowController alloc] initWithWindowCibName:@"Window"];
    [self newDocument:self];
}

- (void)newDocument:(id)sender
{
    [_sheetController newWindow:self];
}

@end
