//
//  WebPasteboardProxy.m
//  NativeHost
//
//  Created by Ross Boucher on 12/12/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import "WebPasteboardProxy.h"
#import "WebScripObject+Objective-J.h"
#import "BridgedMethods.h"

NSMutableDictionary *WebPasteboardDictionary = nil;

@implementation WebPasteboardProxy

+ (void)initialize
{
    WebPasteboardDictionary = [[NSMutableDictionary dictionary] retain];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
    return NO;
}

+ (id)pasteboardWithName:(NSString *)aName
{
    if ([aName isEqual:@"CPGeneralPboard"])
        return [self pasteboardWithName:NSGeneralPboard];

    id proxy = [WebPasteboardDictionary objectForKey:aName];
    if (!proxy)
    {
        proxy = [[self alloc] initWithPasteboard:[NSPasteboard pasteboardWithName:aName]];
        [WebPasteboardDictionary setObject:proxy forKey:aName];
        [proxy release];
    }

    return proxy;
}

- (id)initWithPasteboard:(NSPasteboard *)aPasteboard
{
    if (self = [super init])
    {
        pasteboard = [aPasteboard retain];
    }

    return self;
}

- (void)dealloc
{
    [pasteboard release];
    [super dealloc];
}

- (int)changeCount
{
    return [pasteboard changeCount];
}

- (void)declareTypes:(WebScriptObject *)args
{
    [pasteboard declareTypes:[BridgedMethods arrayFromWebScriptObject:args] owner:self];
}

- (void)addTypes:(WebScriptObject *)args
{
    [pasteboard addTypes:[BridgedMethods arrayFromWebScriptObject:args ] owner:self];
}

- (NSArray *)types
{
    return [pasteboard types];
}

- (NSString *)stringForType:(NSString *)aType
{
    return [pasteboard stringForType:aType];
}

- (void)pasteboard:(NSPasteboard *)aPasteboard provideDataForType:(NSString *)aType
{
    NSString *name = aPasteboard == [NSPasteboard generalPasteboard] ? @"CPGeneralPboard" : [aPasteboard name];

    NSString *data = [[[NSApp delegate] windowScriptObject] evaluateObjectiveJReturningString:
     [NSString stringWithFormat:@"[[CPPasteboard pasteboardWithName:'%@'] stringForType:'%@']", name, aType]
    ];

    [aPasteboard setString:data forType:aType];
}

@end
