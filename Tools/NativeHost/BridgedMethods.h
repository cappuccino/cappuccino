//
//  BridgedMethods.h
//  NativeHost
//
//  Created by Francisco Tolmasky on 10/16/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BridgedMethods : NSObject
{
    WebView * webView;
}
+ (NSMutableArray *)arrayFromWebScriptObject:(WebScriptObject *)incomingObject;
+ (void)enhanceWindowObject:(WebScriptObject *)aWindowObject ofWebView:(WebView *)aWebView;
@end

@interface GlobalMethods : BridgedMethods
{
}
- (id)isDesktop;

- (id)openingURLStrings;

- (id)setMainMenu:(id)arguments;

- (id)terminate;
- (id)activateIgnoringOtherApps:(NSArray *)arguments;
- (id)deactivate;
- (id)hide;
- (id)hideOtherApplications;

- (id)savePanel:(NSArray *)arguments; // FIXME: This should be implemented in Cappuccino.
- (id)openPanel; // FIXME: This should be implemented in Cappuccino.

- (id)clearRecentDocuments;
- (id)noteNewRecentDocumentPath:(NSArray *)aURL;
- (id)recentDocumentURLs;

- (id)pasteboardWithName:(NSArray *)arguments;

@end

@interface WindowMethods : BridgedMethods
{
}
- (id)miniaturize;
- (id)deminiaturize;

- (id)level;
- (id)setLevel:(NSArray *)arguments;

- (id)hasShadow;
- (id)setHasShadow:(NSArray *)arguments;

- (id)shadowStyle;
- (id)setShadowStyle:(NSArray *)arguments;

- (id)frame;
- (id)setFrame:(NSArray *)arguments;

@end

