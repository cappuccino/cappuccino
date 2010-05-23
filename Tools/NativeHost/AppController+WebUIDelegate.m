//
//  AppController+WebUIDelegate.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 7/28/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import "AppController.h"
#import "WebWindow.h"


@implementation AppController (WebUIDelegate)

- (void)webView:(WebView *)aWebView setFrame:(NSRect)aFrame
{
    [[aWebView window] setFrame:aFrame display:YES];
}

- (NSRect)webViewFrame:(WebView *)aWebView
{
    return [[aWebView window] frame];
}

- (WebView *)webView:(WebView *)aWebView createWebViewWithRequest:(NSURLRequest *)aRequest
{
    return [[WebWindow webWindow] webView];
}

- (void)webViewClose:(WebView *)aWebView
{
    // Important to call close and not:
    // -performClose:, which beeps without the presence of a close button.
    // -orderOut:, which doesn't release the window.
    [[aWebView window] close];
    //[[aWebView window] orderOut:self];
}

- (void)webViewShow:(WebView *)aWebView
{
    [[aWebView window] makeKeyAndOrderFront:self];
}

- (NSAttributedString *)loggedOutput;
{
    return loggedOutput;
}

- (void)webView:(WebView *)aWebView addMessageToConsole:(NSDictionary *)aDictionary
{
    NSString * message = [aDictionary objectForKey:@"message"];
    NSAttributedString * attributedString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", message, nil]];
    
    [loggedOutput appendAttributedString:attributedString];

    [attributedString release];
    NHLog(@"CONSOLE", message);
}

- (void)webView:(WebView *)aSender runJavaScriptAlertPanelWithMessage:(NSString *)aMessage initiatedByFrame:(WebFrame *)aFrame
{
    WebDataSource * dataSource = [aFrame dataSource];
    NSString * title = [dataSource pageTitle];
    
    if (![title length])
        title = [[[dataSource request] URL] absoluteString];
    
    [[NSAlert alertWithMessageText:title defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", aMessage, nil] runModal];
}

@end
