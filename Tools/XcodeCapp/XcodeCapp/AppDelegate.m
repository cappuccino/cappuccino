//
//  AppDelegate.m
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/5/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import "AppDelegate.h"
#import "XCCMainController.h"
#import "XCCUserDefaults.h"

@implementation AppDelegate


#pragma mark - Utilities

- (void)_initUserDefaults
{
    NSDictionary *appDefaults = @{
                                XCCUserDefaultsAutoOpenXcodeProject: @YES,
                                XCCUserDefaultsLogLevel: @LOG_LEVEL_WARN,
                                XCCUserDefaultsMaxNumberOfConcurrentOperations: @20
                                };

    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)_initStatusItem
{
    self->imageStatusInactive   = [NSImage imageNamed:@"status-icon-inactive"];
    self->imageStatusProcessing = [NSImage imageNamed:@"status-icon-working"];
    self->imageStatusError      = [NSImage imageNamed:@"status-icon-error"];
    
    self->statusItem                 = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self->statusItem.menu            = self->statusMenu;
    self->statusItem.image           = self->imageStatusInactive;
    self->statusItem.highlightMode   = YES;
    self->statusItem.length          = self->imageStatusInactive.size.width + 12;
}

- (void)_initLogging
{
#if DEBUG
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    [DDLogLevel setLogLevel:LOG_LEVEL_VERBOSE];
#else
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int logLevel = (int)[defaults integerForKey:XCCUserDefaultsLogLevel];
    NSUInteger modifiers = [NSEvent modifierFlags];
    
    if (modifiers & NSAlternateKeyMask)
        logLevel = LOG_LEVEL_VERBOSE;
    
    [DDLogLevel setLogLevel:logLevel];
#endif
}

- (void)_initOperationQueue
{
    self.mainOperationQueue = [NSOperationQueue new];

    [self.mainOperationQueue setMaxConcurrentOperationCount:[[[NSUserDefaults standardUserDefaults] objectForKey:XCCUserDefaultsMaxNumberOfConcurrentOperations] intValue]];
}

#pragma mark - Actions

- (IBAction)openPreferences:(id)aSender
{
    [self->preferencesWindow makeKeyAndOrderFront:nil];
}

- (IBAction)openAbout:(id)aSender
{
    [self->aboutWindow makeKeyAndOrderFront:nil];
}


#pragma mark - Observers

- (void)_startObservers
{
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:XCCUserDefaultsMaxNumberOfConcurrentOperations options:NSKeyValueObservingOptionNew context:nil];

    [self.mainOperationQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    [self.mainWindowController addObserver:self forKeyPath:@"totalNumberOfErrors" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == [NSUserDefaults standardUserDefaults] && [keyPath isEqualToString:XCCUserDefaultsMaxNumberOfConcurrentOperations])
    {
        [self.mainOperationQueue setMaxConcurrentOperationCount:[change[NSKeyValueChangeNewKey] intValue]];
    }
    else
    {
        NSImage *image;

        if (self.mainOperationQueue.operationCount)
            image = self->imageStatusProcessing;
        else if ([self.mainWindowController totalNumberOfErrors])
            image = self->imageStatusError;
        else
            image = self->imageStatusInactive;

        [self->statusItem performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
    }
}


#pragma mark - Delegates

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    DDLogVerbose(@"\n******************************\n**    XcodeCapp started     **\n******************************\n");

    self.version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];

    [self _initUserDefaults];
    [self _initLogging];
    [self _initOperationQueue];
    [self _initStatusItem];

    [self _startObservers];
    
    [self->_mainWindowController windowDidLoad];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app
{
    DDLogVerbose(@"Stop listening to all projects");
    [self.mainWindowController notifyCappuccinoControllersApplicationIsClosing];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    DDLogVerbose(@"\n******************************\n**    XcodeCapp stopped     **\n******************************\n");
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    [self.mainWindowController showWindow:self];
    return YES;
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)filename
{
    BOOL isDir;
    
    [[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDir];
    
    if (isDir)
    {
        [self.mainWindowController manageCappuccinoProjectControllerForPath:filename];
        return YES;
    }
    else
    {
        return NO;
    }
}

@end
