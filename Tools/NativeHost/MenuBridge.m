//
//  MenuBridge.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 9/2/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import "WebScripObject+Objective-J.h"
#import "MenuItemBridge.h"
#import "MenuBridge.h"


@implementation MenuBridge

+ (id)menuBridgeWithMenuObject:(WebScriptObject *)aMenuObject
{
    if (!aMenuObject)
        return nil;

    static NSMapTable * cache = nil;

    if (!cache)
        cache = [[NSMapTable mapTableWithStrongToStrongObjects] retain];

    MenuBridge * menuBridge = [cache objectForKey:aMenuObject];

    if (!menuBridge)
    {
        menuBridge = [MenuBridge alloc];

        [cache setObject:menuBridge forKey:aMenuObject];

        [[menuBridge initWithMenuObject:aMenuObject] autorelease];
    }

    return menuBridge;
}

- (id)initWithMenuObject:(WebScriptObject *)aMenuObject
{
    self = [super initWithTitle:[aMenuObject bridgeSelector:@selector(title)]];

    if (self)
    {
        menuObject = aMenuObject;

        NSInteger   index = 0,
                    count = [[aMenuObject bridgeSelector:@selector(numberOfItems)] intValue];

        for (; index < count; ++index)
            [self addItem:[[[MenuItemBridge alloc] initWithMenuItemObject:[aMenuObject bridgeSelector:@selector(itemAtIndex:) withObject:[NSNumber numberWithInt:index]]] autorelease]];
    }

    return self;
}

- (void)performActionForItemAtIndex:(NSInteger)anIndex
{
    [menuObject bridgeSelector:@selector(performActionForItemAtIndex:) withObject:[NSNumber numberWithInt:anIndex]];
}

@end
