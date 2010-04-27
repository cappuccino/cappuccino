//
//  AppController+MainMenu.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 9/2/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "MenuBridge.h"
#import "AppController.h"


@interface NSApplication (MenuMethods)

- (void)setAppleMenu:(NSMenu *)aMenu;

@end

@implementation AppController (MainMenu)

- (void)setMainMenuObject:(WebScriptObject *)aMenuObject
{
    NSMenu * mainMenu = [[MenuBridge alloc] initWithMenuObject:aMenuObject];

    [NSApp setAppleMenu:[[mainMenu itemArray] objectAtIndex:0]];
    [NSApp setMainMenu:mainMenu];

    [mainMenu release];
}

@end
