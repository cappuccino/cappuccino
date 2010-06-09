//
//  ReflectMenuItem.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 9/2/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import "WebScripObject+Objective-J.h"
#import "MenuBridge.h"
#import "MenuItemBridge.h"


@implementation MenuItemBridge

+ (id)menuItemBridgeWithMenuItemObject:(WebScriptObject *)aMenuItemObject
{
    if (!aMenuItemObject)
        return nil;
    
    static NSMapTable * cache = nil;
    
    if (!cache)
        cache = [[NSMapTable mapTableWithStrongToStrongObjects] retain];
    
    MenuItemBridge * menuItemBridge = [cache objectForKey:aMenuItemObject];
    
    if (!menuItemBridge)
    {
        menuItemBridge = [MenuBridge alloc];

        [cache setObject:menuItemBridge forKey:aMenuItemObject];

        [[menuItemBridge initWithMenuItemObject:aMenuItemObject] autorelease];
    }
    
    return menuItemBridge;
}

- (id)initWithMenuItemObject:(WebScriptObject *)aMenuItemObject
{
    if ([[aMenuItemObject bridgeSelector:@selector(isSeparatorItem)] boolValue])
        return [[NSMenuItem separatorItem] retain];

    self = [super init];

    if (self)
    {
        menuItemObject = aMenuItemObject;

        [self updateFromMenuItemObject];
    }

    return self;
}
/*
- (BOOL)isSeparatorItem
{
    return [[menuItemObject bridgeSelector:@selector(isSeparatorItem)] boolValue];
}
*/
- (void)updateFromMenuItemObject
{
    [self setTitle:[menuItemObject bridgeSelector:@selector(title)]];
    [self setSubmenu:[MenuBridge menuBridgeWithMenuObject:[menuItemObject bridgeSelector:@selector(submenu)]]];
    [self setKeyEquivalent:[menuItemObject bridgeSelector:@selector(keyEquivalent)]];
    [self setKeyEquivalentModifierMask:[[menuItemObject evaluateObjectiveJ:[NSString stringWithFormat:@"(function() { var mask = %u; return (((mask & CPAlphaShiftKeyMask) ? %u : 0) | ((mask & CPShiftKeyMask) ? %u : 0) | ((mask & CPControlKeyMask) ? %u : 0) | ((mask & CPAlternateKeyMask) ? %u : 0) | ((mask & CPCommandKeyMask) ? %u : 0) | ((mask & CPNumericPadKeyMask) ? %u : 0) | ((mask & CPHelpKeyMask) ? %u : 0) | ((mask & CPFunctionKeyMask) ? %u : 0)) }())", [[menuItemObject bridgeSelector:@selector(keyEquivalentModifierMask)] unsignedIntegerValue], NSAlphaShiftKeyMask, NSShiftKeyMask, NSControlKeyMask, NSAlternateKeyMask, NSCommandKeyMask, NSNumericPadKeyMask, NSHelpKeyMask, NSFunctionKeyMask, NSDeviceIndependentModifierFlagsMask]] unsignedIntegerValue]];[self setAction:@selector(bridgeAction:)];
    [self setTarget:self];
    [self setAction:@selector(bridgeAction:)];
}

// This exists so that the menu items are enabled.
- (void)bridgeAction:(id)aSender
{
}

@end
