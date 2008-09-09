
import <Foundation/CPObject.j>
import <AppKit/CPCib.j>


@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var cib = [[CPCib alloc] initWithContentsOfURL:@"MainMenu.cib"],
        x = [cib instantiateCibWithExternalNameTable:nil];

    [x setBackgroundColor:[CPColor blueColor]];

    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];
        
    [contentView addSubview:x];
    
    [theWindow orderFront:self];
}

@end