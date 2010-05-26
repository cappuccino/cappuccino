//
//  ReflectMenuItem.h
//  NativeHost
//
//  Created by Francisco Tolmasky on 9/2/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class WebScriptObject;

@interface MenuItemBridge : NSMenuItem
{
    WebScriptObject * menuItemObject;
}

+ (id)menuItemBridgeWithMenuItemObject:(WebScriptObject *)aMenuItemObject;
- (id)initWithMenuItemObject:(WebScriptObject *)aMenuItemObject;

- (void)updateFromMenuItemObject;

@end
