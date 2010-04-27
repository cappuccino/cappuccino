//
//  Console.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 6/16/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import "Console.h"

#import "AppController.h"


@implementation Console

+ (id)sharedConsole
{
    static Console * console = nil;

    if (!console)
        console = [[Console alloc] init];

    return console;
}

- (id)init
{
    self = [super init];

    if (self)
        contents = [[NSMutableAttributedString alloc] init];

    return self;
}

- (void)dealloc
{
    [contents release];
    [super dealloc];
}

- (NSAttributedString *)contents
{
    return contents;
}

- (void)webView:(WebView *)aWebView addMessageToConsole:(NSDictionary *)aDictionary
{
    NSString * message = [aDictionary objectForKey:@"message"];

    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", message, nil]];
    [contents appendAttributedString:attrString];
    [attrString release];

    NHLog(@"CONSOLE", message);
}

- (void)webView:(WebView *)aSender runJavaScriptAlertPanelWithMessage:(NSString *)aMessage initiatedByFrame:(WebFrame *)aFrame
{
    WebDataSource * dataSource = [aFrame dataSource];
    NSString * title = [dataSource pageTitle];

    if (![title length])
        title = [[[dataSource request] URL] absoluteString];

    [[NSAlert alertWithMessageText:title defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:aMessage, nil] runModal];
}

@end
