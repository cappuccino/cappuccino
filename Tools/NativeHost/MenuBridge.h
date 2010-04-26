//
//  MenuBridge.h
//  NativeHost
//
//  Created by Francisco Tolmasky on 9/2/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class WebScriptObject;

@interface MenuBridge : NSMenu
{
    WebScriptObject * menuObject;
}

+ (id)menuBridgeWithMenuObject:(WebScriptObject *)aMenuObject;
- (id)initWithMenuObject:(WebScriptObject *)aMenuObject;

@end
