@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
	CPButton button;
	CPButton button2;
	CPWebView webview;
	CPWebView webview2;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

	button = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
	[button setTitle:"Unhide (loadHTMLString)"];
	[button sizeToFit];
	[button setTarget:self];
	[button setAction:@selector(buttonClicked:)];
	[contentView addSubview:button];

	button2 = [[CPButton alloc] initWithFrame:CGRectMake([contentView frameSize].width / 2 + 10, 0, 0, 0)];
	[button2 setTitle:"Unhide (URL)"];
	[button2 sizeToFit];
	[button2 setTarget:self];
	[button2 setAction:@selector(button2Clicked:)];
	[contentView addSubview:button2];

    webview = [[CPWebView alloc] initWithFrame:CGRectMake(0, 40, [contentView frameSize].width / 2 - 10, [contentView frameSize].height - 40)];
	[webview setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
	[webview setHidden:YES];
	[webview loadHTMLString:"<html><body><font size='8'>	Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</font></body></html>"];
	[contentView addSubview:webview];

    webview2 = [[CPWebView alloc] initWithFrame:CGRectMake([contentView frameSize].width / 2 + 10, 40, [contentView frameSize].width / 2 - 10, [contentView frameSize].height - 40)];
	[webview2 setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
	[webview2 setHidden:YES];
	[webview2 setMainFrameURL:"http://www.cappuccino.org"];
	[contentView addSubview:webview2];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (void)buttonClicked:(id)sender
{
	[webview setHidden:NO];
}

- (void)button2Clicked:(id)sender
{
	[webview2 setHidden:NO];
}

@end