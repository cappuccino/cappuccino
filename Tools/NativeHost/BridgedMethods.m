//
//  BridgedMethods.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 10/16/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//


#import <objc/runtime.h>
#import "Application.h"
#import "AppController.h"
#import "BridgedMethods.h"
#import "NSObject+WebAdditions.h"
#import "NSURL+Additions.h"
#import "WebWindow.h"
#import "WebPasteboardProxy.h"

static NSMutableDictionary * MethodClasses;

@implementation GlobalMethods

- (id)isDesktop
{
    return [NSNumber numberWithBool:YES];
}

- (id)openingURLStrings
{
    return [(AppController *)[NSApp delegate] openingURLStrings];
}

- (id)setMainMenu:(id)arguments
{
    [[NSApp delegate] setMainMenuObject:[arguments objectAtIndex:0]];

    return [WebUndefined undefined];
}

- (id)terminate
{
    [(Application *)NSApp _reallyTerminate:self];

    return [WebUndefined undefined];
}

- (id)activateIgnoringOtherApps:(NSArray *)arguments
{
    id argument = [arguments objectAtIndex:0];

    [(NSApplication *)NSApp activateIgnoringOtherApps:[argument isKindOfClass:[NSNumber class]] && [(NSNumber *)argument boolValue]];

    return [WebUndefined undefined];
}

- (id)deactivate
{
    [(NSApplication *)NSApp deactivate];
    return [WebUndefined undefined];
}

- (id)hide
{
    [NSApp hide:self];
    return [WebUndefined undefined];
}

- (id)hideOtherApplications
{
    [NSApp hideOtherApplications:self];
    return [WebUndefined undefined];
}

- (id)openPanel
{
    NSOpenPanel * openPanel = [NSOpenPanel openPanel];

    NSInteger result = [openPanel runModal];

    NSMutableString * resultObject = [NSMutableString stringWithFormat:@"({ button:%d, URLs:", result];

    NSMutableArray * fileSystemURLs = [NSMutableArray array];

    for (NSURL * URL in [openPanel URLs])
        [fileSystemURLs addObject:[URL HTTPFileSystemURL]];

    if (result == NSFileHandlingPanelOKButton)
        [resultObject appendString:[NSString stringWithFormat:@"[\"%@\"] })", [fileSystemURLs componentsJoinedByString:@"\", \""]]];

    else
        [resultObject appendString:@"[] })"];

    return [[webView windowScriptObject] evaluateWebScript:resultObject];
}

- (id)savePanel:(NSArray *)arguments
{
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    WebScriptObject *args = [arguments objectAtIndex:0];

    [savePanel setAllowedFileTypes:[BridgedMethods arrayFromWebScriptObject:[args valueForKey:@"allowedFileTypes"]]];

    id allowsOtherFileTypes = [args valueForKey:@"allowsOtherFileTypes"];

    [savePanel setAllowsOtherFileTypes:allowsOtherFileTypes && [allowsOtherFileTypes webBoolValue]];

    id isExtensionHidden = [args valueForKey:@"isExtensionHidden"];

    [savePanel setExtensionHidden:isExtensionHidden && [isExtensionHidden webBoolValue]];

    id canSelectHiddenExtension = [args valueForKey:@"canSelectHiddenExtension"];

    [savePanel setCanSelectHiddenExtension:canSelectHiddenExtension && canSelectHiddenExtension];

    id canCreateDirectories = [args valueForKey:@"canCreateDirectories"];

    [savePanel setCanCreateDirectories:canCreateDirectories && [canCreateDirectories webBoolValue]];

    NSInteger result = [savePanel runModal];

    return [[webView windowScriptObject] evaluateWebScript:[NSString stringWithFormat:@"({ button:%d, URL:\"%@\" })", result, [[[savePanel URL] HTTPFileSystemURL] absoluteString]]];
}

- (id)clearRecentDocuments
{
    [[NSDocumentController sharedDocumentController] clearRecentDocuments:self];
    return [WebUndefined undefined];
}

- (id)noteNewRecentDocumentPath:(NSArray *)arguments
{
    if (![arguments count])
        return [WebUndefined undefined];

    NSString *aURL = [arguments objectAtIndex:0];
    NSURL *fileURL = [NSURL fileSystemURLFromHTTPFileSystemString:aURL];

    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:fileURL];

    return [WebUndefined undefined];
}

- (id)recentDocumentURLs
{
    NSArray *existingURLs = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
    NSMutableArray *urlsAsStrings = [NSMutableArray array];

    for (int i=0, count = [existingURLs count]; i < count; i++)
        [urlsAsStrings addObject:[[existingURLs objectAtIndex:i] absoluteString]];

    return urlsAsStrings;
}

- (id)pasteboardWithName:(NSArray *)arguments
{
    if (![arguments count])
        return [WebUndefined undefined];

    return [WebPasteboardProxy pasteboardWithName:[arguments objectAtIndex:0]];
}

@end

@implementation WindowMethods

- (id)miniaturize
{
    [[webView window] miniaturize:nil];
	return [WebUndefined undefined];
}

- (id)deminiaturize
{
    [[webView window] deminiaturize:nil];
	return [WebUndefined undefined];
}

- (id)level
{
    return [NSNumber numberWithInt:[[webView window] level]];
}

- (id)setLevel:(NSArray *)arguments
{
    [[webView window] setLevel:[[arguments objectAtIndex:0] intValue]];

    return [WebUndefined undefined];
}

- (id)hasShadow
{
    return [NSNumber numberWithBool:[[webView window] hasShadow]];
}

- (id)setHasShadow:(NSArray *)arguments
{
    [[webView window] setHasShadow:[[arguments objectAtIndex:0] boolValue]];

    return [WebUndefined undefined];
}

- (id)frame
{
    NSRect frame = [[webView window] frame];

    return [[webView windowScriptObject] evaluateWebScript:[NSString stringWithFormat:@"({ origin:{%f, %f}, size:{%f, %f}})", NSMinX(frame), NSMinY(frame), NSWidth(frame), NSHeight(frame)]];
}

- (id)setFrame:(NSArray *)arguments
{
    id  origin = [[arguments objectAtIndex:0] valueForKey:@"origin"],
    size = [[arguments objectAtIndex:0] valueForKey:@"size"];

    NSWindow * window = [webView window];
    NSScreen * screen = [window screen];

    if (!screen)
    screen = [NSScreen mainScreen]; // Is this correct?

    float height = [[size valueForKey:@"height"] floatValue];

    [[webView window] setFrame:NSMakeRect([[origin valueForKey:@"x"] floatValue], NSMaxY([screen frame]) - [[origin valueForKey:@"y"] floatValue] - height, [[size valueForKey:@"width"] floatValue], height) display:YES];
    /*
     NSLog([webView description]);
     NSLog(@"%@ %@", [window screen], NSStringFromRect([window frame]));
     NSLog(@"%f - %f - %f = %f", NSMaxY([[window screen] frame]), [[origin valueForKey:@"y"] floatValue], height, NSMaxY([[window screen] frame]) - [[origin valueForKey:@"y"] floatValue] - height);
     NSLog(@"FROM: %@", NSStringFromRect(NSMakeRect([[origin valueForKey:@"x"] floatValue], [[origin valueForKey:@"y"] floatValue], [[size valueForKey:@"width"] floatValue], height)));
     NSLog(@"  TO: %@", NSStringFromRect([[webView window] frame]));
     */

    return [WebUndefined undefined];
}

- (id)shadowStyle
{
    WebWindow * window = (WebWindow *)[webView window];

    return [NSNumber numberWithInt:[window shadowStyle]];
}

- (id)setShadowStyle:(id)arguments
{
    int type = [[arguments objectAtIndex:0] intValue];

    WebWindow * window = (WebWindow *)[webView window];

    [window setShadowStyle:type];

    return [WebUndefined undefined];
}

@end


@interface WindowScriptObjectMethod : NSObject
{
    WebView * webView;
}

- (id)initWithWebView:(WebView *)aWebView;

@end

@implementation WindowScriptObjectMethod

- (id)initWithWebView:(WebView *)aWebView
{
    self = [super init];

	if (self)
        webView = aWebView;

    return self;
}

@end

@implementation BridgedMethods

+ (NSMutableArray *)arrayFromWebScriptObject:(WebScriptObject *)incomingObject
{
    if (!incomingObject)
        return nil;

    NSMutableArray * newItems = [[NSMutableArray alloc] init];

    for (int i=0; [incomingObject webScriptValueAtIndex:i]!=[WebUndefined undefined]; i++)
    {
        id oneItem =[incomingObject webScriptValueAtIndex:i];
        [newItems addObject:oneItem];
    }

    return [newItems autorelease];
}

+ (void)enhanceWindowObject:(WebScriptObject *)aWindowObject ofWebView:(WebView *)aWebView
{
    NSDictionary * classMethods = [MethodClasses objectForKey:[self className]];
    NSString * key = nil;
    NSEnumerator * keyEnumerator = [classMethods keyEnumerator];

    while (key = [keyEnumerator nextObject])
        [aWindowObject setValue:[(WindowScriptObjectMethod *)[[[classMethods objectForKey:key] alloc] initWithWebView:aWebView] autorelease] forKey:key];
}

+ (void)bridgeMethod:(Method)aMethod dictionary:(NSMutableDictionary *)aDictionary
{
    NSString    * methodName = NSStringFromSelector(method_getName(aMethod)),
                * publicMethodName = [NSString stringWithFormat:@"cp%@", [[NSString stringWithFormat:@"%@%@", [[methodName substringToIndex:1] uppercaseString], [methodName substringFromIndex:1]] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]]];

    Class methodClass = objc_allocateClassPair([WindowScriptObjectMethod class], [[NSString stringWithFormat:@"WebScriptObjectMethod_%@", publicMethodName] cString], 0);

    class_addMethod(methodClass, @selector(invokeDefaultMethodWithArguments:), method_getImplementation(aMethod), "@@:@");

    objc_registerClassPair(methodClass);

    [aDictionary setObject:methodClass forKey:publicMethodName];
}

+ (void)initialize
{
    if (!MethodClasses)
        MethodClasses = [[NSMutableDictionary alloc] init];

    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];

    [MethodClasses setObject:dictionary forKey:[self className]];
    [dictionary release];

    unsigned int methodCount = 0;
    Method * methods = class_copyMethodList(self, &methodCount);

    if (!methods)
        return;

    int index = 0;

    for (; index < methodCount; ++index)
        [self bridgeMethod:methods[index] dictionary:dictionary];

    free(methods);
    methods = NULL;
}

@end
