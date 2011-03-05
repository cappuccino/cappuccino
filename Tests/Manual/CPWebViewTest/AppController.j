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
    // This is called when the application is done loading.

    [webView1 setScrollMode:CPWebViewScrollAuto];
    [webView1 loadHTMLString:"<html><body><img src='http://cappuccino.org/images/cappuccino-icon.png'><img src='http://cappuccino.org/images/cappuccino-icon.png'></body></html>"];

    [webView2 setScrollMode:CPWebViewScrollNative];
    [webView2 loadHTMLString:"<html><body><img src='http://cappuccino.org/images/cappuccino-icon.png'><img src='http://cappuccino.org/images/cappuccino-icon.png'></body></html>"];

    [webView3 setScrollMode:CPWebViewScrollAuto];
    [webView3 setMainFrameURL:[[CPBundle mainBundle] pathForResource:"hello_world.html"]];
    [webView4 setScrollMode:CPWebViewScrollNative];
    [webView4 setMainFrameURL:[[CPBundle mainBundle] pathForResource:"hello_world.html"]];

    // XXX If this program is run from file:// in Safari, it will actually have SOP access.
    [webView5 setScrollMode:CPWebViewScrollAuto];
    [webView5 setMainFrameURL:"http://www.cappuccino.org"];

    [webView6 setScrollMode:CPWebViewScrollAppKit];
    [webView6 setMainFrameURL:"http://www.cappuccino.org"];
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
