

//
//  AppController+WebFrameLoadDelegate.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 7/28/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import "AppController.h"

#import "BridgedMethods.h"


@implementation AppController (WebFrameLoadDelegate)

- (void)webView:(WebView *)aWebView didClearWindowObject:(WebScriptObject *)aWindowObject forFrame:(WebFrame *)aFrame
{
    if (aWebView == webView)
        [GlobalMethods enhanceWindowObject:aWindowObject ofWebView:aWebView];
    else
        [WindowMethods enhanceWindowObject:aWindowObject ofWebView:aWebView];
}

@end
