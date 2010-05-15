//
//  AppController.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 6/4/09.
//  Copyright 2009 280 North, Inc. All rights reserved.
//

#import "Console.h"
#import "Server.h"
#import "AppController.h"
#import "NSURL+Additions.h"
#import "BridgedMethods.h"
#import "WebWindow.h"
#import "WebScripObject+Objective-J.h"

extern int interactive;

int SERVER_PORT = 9191;
NSString *SERVER_PASSWORD = nil;
NSString *SERVER_USER = nil;


@implementation AppController

- (id)init
{
    self = [super init];

    if (self)
        openingURLStrings = [NSMutableArray new];

    return self;
}

- (void)dealloc
{
    [webView release];
    [webViewWindow release];

    [openingURLStrings release];

    [super dealloc];
}

- (BOOL)application:(NSApplication *)anApplication openFile:(NSString *)aFilename
{
    id canOpenFilesImmediately = [[webView windowScriptObject] evaluateWebScript:@"CPApp && CPApp._finishedLaunching"];

    NSString *path = [[[NSURL fileURLWithPath:aFilename] HTTPFileSystemURL] absoluteString];
    if ([canOpenFilesImmediately isKindOfClass:[NSNumber class]] && [canOpenFilesImmediately boolValue])
        [[webView windowScriptObject] evaluateObjectiveJ:[NSString stringWithFormat:@"[CPApp _openURL:[CPURL URLWithString:\"%@\"]]", path]];
    else
        [openingURLStrings addObject:path];

    return NO;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    NSUserDefaults  * defaults = [NSUserDefaults standardUserDefaults];

    [defaults registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"WebKitDeveloperExtras"]];

    [self startServer];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self startCappuccinoApplication];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification
{
    // FIXME: handle this better.
    [[self windowScriptObject] evaluateObjectiveJ:@"[CPApp _willResignActive];"];
    [[self windowScriptObject] evaluateObjectiveJ:@"CPApp._isActive = NO;"];
    [[self windowScriptObject] evaluateObjectiveJ:@"[CPApp _didResignActive];"];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    // FIXME: handle this better.
    [[self windowScriptObject] evaluateObjectiveJ:@"[CPApp _willBecomeActive];"];
    [[self windowScriptObject] evaluateObjectiveJ:@"CPApp._isActive = YES;"];
    [[self windowScriptObject] evaluateObjectiveJ:@"[CPApp _didBecomeActive];"];
}

- (NSArray *)openingURLStrings
{
    return openingURLStrings;
}

- (NSView *)keyView
{
    return [[[webView mainFrame] frameView] documentView];
}

- (WebView *)webView
{
    return webView;
}

- (WebScriptObject *)windowScriptObject
{
    return [webView windowScriptObject];
}

- (void)startServer
{
    server = [[Server alloc] init];

    if (![server start])
        exit(0);

	if (interactive)
	{
        stdinFileHandle = [[NSFileHandle fileHandleWithStandardInput] retain];
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(didReadStdin:)
         name:NSFileHandleReadCompletionNotification
         object:stdinFileHandle];

        fprintf(stdout, "objj> ");
        fflush(stdout);
        [stdinFileHandle readInBackgroundAndNotify];
    }
}

- (void)didReadStdin:(NSNotification *)aNotification
{
    NSString *string = [[NSString alloc] initWithData:[[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem] encoding:NSASCIIStringEncoding];
    NSString *result = [[self windowScriptObject] evaluateObjectiveJReturningString:string];
    [string release];
    if ([result respondsToSelector:@selector(UTF8String)])
        fprintf(stdout, "%s\n", [result UTF8String]);
    fprintf(stdout, "objj> ");
    fflush(stdout);
    [stdinFileHandle readInBackgroundAndNotify];
}

- (NSURL *)baseURL
{
    return baseURL;
}

- (void)startCappuccinoApplication
{
    NSString *initialURL = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NHInitialURL"];
    BOOL prependServer = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"NHInitialURLPrependServer"] boolValue];

    if (!initialURL)
    {
        NSString *initialResource = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NHInitialResource"];
        
        if (!initialResource)
            initialResource = @"Application/index.html";

        initialURL = [[NSString stringWithFormat:@"file://%@/%@", [[NSBundle mainBundle] resourcePath], initialResource] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        baseURL = [[NSURL alloc] initWithString:@"file:///"];
    }
    else if (prependServer)
    {
        initialURL = [NSString stringWithFormat:@"http://127.0.0.1:%d/%@", SERVER_PORT, initialURL];
        baseURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://127.0.0.1:%d/", SERVER_PORT]];
    }

	NHLog(@"STARTUP", [initialURL description]);
	
    [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:initialURL]]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [server stop];
}

- (void)awakeFromNib
{
    webView = [[WebView alloc] init];

    [webView setUIDelegate:self];
    [webView setFrameLoadDelegate:self];
    [webView setResourceLoadDelegate:self];
    [webView setPolicyDelegate:self];

    webViewWindow = [[NSWindow alloc] init];

    [webViewWindow setContentView:webView];
}

@end

void NHLog(NSString *type, NSString *message)
{
    NSArray *lines = [message componentsSeparatedByString:@"\n"];
    for (NSString *line in lines)
    {
        if ([line length] > 0)
            NSLog(@"%10@: %@", type, line);
    }
}
