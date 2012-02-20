
@import <Foundation/CPObject.j>
@import <AppKit/CPCib.j>


@implementation AppController : CPObject
{
    CPWindow    _window;
    CPView      _view;
    CPTextField textField;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var cib = [[CPCib alloc] initWithContentsOfURL:@"MainMenu.cib"],
        theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    [cib instantiateCibWithExternalNameTable:[CPDictionary dictionaryWithObject:self forKey:CPCibOwner]];

    [_view setBackgroundColor:[CPColor colorWithCalibratedRed:0.7 green:0.77 blue:0.85 alpha:1.0]];

    [contentView addSubview:_view];
    [theWindow orderFront:self];
    
    CPLogConsole("NSTextField tag was 0 in IB. CPTextField tag is " + [textField tag]);
    
    // HACK: shift the window down to accomodate for menubar
    [theWindow setFrameOrigin:CGPointMake([theWindow frame].origin.x, [theWindow frame].origin.y + 29)];
}

@end