
@import <Foundation/CPObject.j>
@import <AppKit/CPCib.j>


@implementation AppController : CPObject
{
    CPWindow    _window;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var cib = [[CPCib alloc] initWithContentsOfURL:[[CPBundle mainBundle] pathForResource:@"MainMenu.cib"]];

    [cib instantiateCibWithExternalNameTable:[CPDictionary dictionaryWithObject:self forKey:CPCibOwner]];

    [_window setFrameOrigin:CGPointMake(0.0, 0.0)];
    [_window orderFront:self];
}

@end
