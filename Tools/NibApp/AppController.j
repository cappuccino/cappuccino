
import <Foundation/CPObject.j>
import <AppKit/CPCib.j>


@implementation AppController : CPObject
{
    CPWindow    _window;
    CPWindow    _secondWindow;
    CPView      _view;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var cib = [[CPCib alloc] initWithContentsOfURL:@"MainMenu.cib"],
        theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    [cib instantiateCibWithExternalNameTable:[CPDictionary dictionaryWithObject:self forKey:CPCibOwner]];

    [_view setBackgroundColor:[CPColor blueColor]];

    [contentView addSubview:_view];
    [theWindow orderFront:self];
    
    [_secondWindow orderFront:self];
}

@end