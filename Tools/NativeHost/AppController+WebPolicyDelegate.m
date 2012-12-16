//
//  AppController+WebPolicyDelegate.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 5/11/10.
//  Copyright 2010 280 North, Inc. All rights reserved.
//

#import "NSURL+Additions.h"
#import "AppController.h"


@implementation AppController (WebPolicyDelegate)

- (void)webView:(WebView *)aWebView decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)aRequest newFrameName:(NSString *)aFrameName decisionListener:(id /*< WebPolicyDecisionListener >*/)aListener
{
    [[NSWorkspace sharedWorkspace] openURL:[actionInformation objectForKey:WebActionOriginalURLKey]];
    [aListener ignore];
}

- (void)webView:(WebView *)aWebView decidePolicyForNavigationAction:(NSDictionary *)aDictionary request:(NSURLRequest *)aRequest frame:(WebFrame *)aWebFrame decisionListener:(id /*<WebPolicyDecisionListener>*/)aDecisionListener
{
    NSURL * requestURL = [aRequest URL];

    if([aWebView mainFrame] != aWebFrame || 
       [[baseURL scheme] isEqualTo:[requestURL scheme]] &&
       ![baseURL host] || [[baseURL host] isEqualTo:[requestURL host]] &&
       ![baseURL port] || [[baseURL port] isEqualTo:[requestURL port]])
        return [aDecisionListener use];

    [[NSWorkspace sharedWorkspace] openURL:[aDictionary objectForKey:WebActionOriginalURLKey]];
    [aDecisionListener ignore];
}

@end
