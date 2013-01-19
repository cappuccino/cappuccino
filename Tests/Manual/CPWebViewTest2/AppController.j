@import <Foundation/CPObject.j>

/*!
    This test is based on the code by `tiredashell` for issue #684 and can be used to verify that when a CPWebView is hidden at an initial small size and then later unhidden at a larger, the content reflows properly.

    When you click "Unhide (loadHTMLString)" you should see:

    WITHOUT the fix: the Lorem ipsum text is constrained to a too narrow width and does not reflow.
    WITH fix c42295f0c7b6ed0a12a8ed472991a3e3ebcc2ecb: the Lorem ipsum text reflows but the scrollbars may not reflect the new content size.
    WITH fix c42295f0c7b6ed0a12a8ed472991a3e3ebcc2ecb and 2563cb5dc13778074f5b20b8989b1f5ac1e4af2b: the Lorem ipsum text reflows to the available width and the scrollbars update.

    The web view on the right "Unhide (URL)" should work with and without the fixes.
*/
@implementation AppController : CPObject
{
	CPButton unhideHtmlButton;
	CPButton unhideUrlButton;
	CPWebView webview;
	CPWebView webview2;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

	unhideHtmlButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
	[unhideHtmlButton setTitle:"Unhide (loadHTMLString)"];
	[unhideHtmlButton sizeToFit];
	[unhideHtmlButton setTarget:self];
	[unhideHtmlButton setAction:@selector(unhideHtmlButtonClicked:)];
	[contentView addSubview:unhideHtmlButton];

	unhideUrlButton = [[CPButton alloc] initWithFrame:CGRectMake([contentView frameSize].width / 2 + 10, 0, 0, 0)];
	[unhideUrlButton setTitle:"Unhide (URL)"];
	[unhideUrlButton sizeToFit];
	[unhideUrlButton setTarget:self];
	[unhideUrlButton setAction:@selector(unhideUrlButtonClicked:)];
	[contentView addSubview:unhideUrlButton];

    webview = [[CPWebView alloc] initWithFrame:CGRectMake(0, 40, [contentView frameSize].width / 2 - 10, [contentView frameSize].height - 40)];
	[webview setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
	[webview setHidden:YES];
	[webview loadHTMLString:"<html><body><font size='8'>	Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</font></body></html>"];
	[contentView addSubview:webview];

    webview2 = [[CPWebView alloc] initWithFrame:CGRectMake([contentView frameSize].width / 2 + 10, 40, [contentView frameSize].width / 2 - 10, [contentView frameSize].height - 40)];
	[webview2 setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
	[webview2 setHidden:YES];
	[webview2 setMainFrameURL:"http://www.cappuccino-project.org"];
	[contentView addSubview:webview2];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (void)unhideHtmlButtonClicked:(id)sender
{
	[webview setHidden:NO];
}

- (void)unhideUrlButtonClicked:(id)sender
{
	[webview2 setHidden:NO];
}

@end
