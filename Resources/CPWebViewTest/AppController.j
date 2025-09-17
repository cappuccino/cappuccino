/*
 * AppController.j
 * CPWebViewTest
 *
 * Created by Alexander Ljungberg on March 4, 2011.
 * Copyright 2011, Alexander Ljungberg All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib

    CPWebView   webView1;
    CPWebView   webView2;
    CPWebView   webView3;
    CPWebView   webView4;
    CPWebView   webView5;
    CPWebView   webView6;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    [[theWindow contentView] setBackgroundColor:[CPColor grayColor]];

    [webView1 setScrollMode:CPWebViewScrollAuto];
    [webView1 loadHTMLString:"<html><body style='background-color:transparent'><p>This web view should have a coloured background.</p><img src='http://cappuccino-project.org/images/cappuccino-icon.png'><img src='http://cappuccino-project.org/images/cappuccino-icon.png'></body></html>"];
    [webView1 setBackgroundColor:[CPColor orangeColor]];

    [webView2 setScrollMode:CPWebViewScrollNative];
    [webView2 loadHTMLString:"<html><body style='background-color:transparent'><p>This web view should be transparent.</p><img src='http://cappuccino-project.org/images/cappuccino-icon.png'><img src='http://cappuccino-project.org/images/cappuccino-icon.png'></body></html>"];
    [webView2 setDrawsBackground:NO];
    [webView2 setBackgroundColor:[CPColor clearColor]];

    [webView3 setScrollMode:CPWebViewScrollAuto];
    [webView3 setMainFrameURL:[[CPBundle mainBundle] pathForResource:"hello_world.html"]];
    [webView4 setScrollMode:CPWebViewScrollNative];
    [webView4 setMainFrameURL:[[CPBundle mainBundle] pathForResource:"hello_world.html"]];

    /*
    XXX If this program is run from file:// in Safari, it will actually have SOP access,
    disturbing test #5 and #6. A simple way to run this test is to change the current directory
    to the root of the test and executing:

    python -m "SimpleHTTPServer"
    */
    if (document.location.href.indexOf('file://') == 0)
        alert("This test should be run from http://, not file:// in order to properly enable SOP testing.");
    [webView5 setScrollMode:CPWebViewScrollAuto];
    [webView5 setMainFrameURL:"http://www.cappuccino-project.org"];

    [webView6 setScrollMode:CPWebViewScrollAppKit];
    [webView6 setMainFrameURL:"http://www.cappuccino-project.org"];
}

- (void)clearAll:(id)sender
{
    var allViews = [webView1, webView2, webView3, webView4, webView5, webView6];
    for (var i = 0; i < 6; i++)
    {
        var view = allViews[i];
        [view loadHTMLString:""];
    }
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullBridge:YES];
}

@end
