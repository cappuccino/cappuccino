//
//  AppController.h
//  NativeHost
//
//  Created by Francisco Tolmasky on 6/4/09.
//  Copyright 2009 280 North, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern int SERVER_PORT;
extern NSString *SERVER_PASSWORD;
extern NSString *SERVER_USER;

@class Server;
@class WebScriptObject;

@interface AppController : NSObject
{
    NSWindow                        * webViewWindow;
    WebView                         * webView;

    NSMutableArray                  * openingFilenames;
    NSMutableArray                  * openingURLStrings;

    Server                          * server;
    NSFileHandle                    * stdinFileHandle;

    NSMutableAttributedString       * loggedOutput;

    NSURL                           * baseURL;
}

- (NSURL *)baseURL;

- (void)startServer;
- (void)startCappuccinoApplication;

- (NSArray *)openingURLStrings;

- (NSView *)keyView;
- (WebView *)webView;
- (WebScriptObject *)windowScriptObject;

@end

@interface AppController (MainMenu)

- (void)setMainMenuObject:(WebScriptObject *)aMenuObject;

@end

void NHLog(NSString *type, NSString *message);