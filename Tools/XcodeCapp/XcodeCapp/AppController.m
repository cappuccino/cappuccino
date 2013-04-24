/*
 * This file is a part of program XcodeCapp
 * Copyright (C) 2011  Antoine Mercadal (<primalmotion@archipelproject.org>)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#import <AppKit/NSApplication.h>

#import "AppController.h"
#import "TNXcodeCapp.h"
#import "UserDefaults.h"

#include "macros.h"


const NSInteger kHelpMenuItemTag = 7;

AppController *SharedAppControllerInstance = nil;


@interface AppController ()

@property BOOL 					supportsFileModeListening;
@property (nonatomic) NSImage	*iconActive;
@property (nonatomic) NSImage 	*iconInactive;
@property (nonatomic) NSImage 	*iconWorking;
@property (nonatomic) NSMenu	*menuHistory;
@property NSStatusItem			*statusItem;

@end


@implementation AppController

+ (AppController *)sharedAppController
{
    return SharedAppControllerInstance;
}

#pragma mark - Initialization

- (void)awakeFromNib
{
    SharedAppControllerInstance = self;
        
    [self registerDefaults];
        
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.menu = self.statusMenu;
    self.statusItem.image = self.iconInactive;
    self.statusItem.highlightMode = YES;
    self.statusItem.length = self.iconInactive.size.width + 8;  // Add some space around the icon
    self.statusMenu.delegate = self;
    self.helpTextView.textContainerInset = NSMakeSize(10.0, 10.0);

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultFirstLaunch])
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDefaultFirstLaunch];
        [self openHelp:self];
    }

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter addObserver:self selector:@selector(XcodeCappConversionDidStart:) name:XCCConversionDidStartNotification object:self.xcc];
    [defaultCenter addObserver:self selector:@selector(XcodeCappConversionDidStop:) name:XCCConversionDidStopNotification object:self.xcc];
    [defaultCenter addObserver:self selector:@selector(XcodeCappDidPopulateProject:) name:XCCDidPopulateProjectNotification object:self.xcc];
    [defaultCenter addObserver:self selector:@selector(XcodeCappListeningDidStart:) name:XCCListeningDidStartNotification object:self.xcc];

    [self pruneProjectHistory];
    [self updateHistoryMenu];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self.xcc start];
}

/*!
	Register default values for preferences
*/
- (void)registerDefaults
{
    NSDictionary *appDefaults = @{
        kDefaultLastEventId:  			[NSNumber numberWithUnsignedLongLong:kFSEventStreamEventIdSinceNow],
        kDefaultFirstLaunch:  			@YES,
        kDefaultXCCAPIMode:   			[NSNumber numberWithInt:kXCCAPIModeAuto],
        kDefaultXCCReactMode: 			@YES,
        kDefaultXCCReopenLastProject: 	@YES,
        kDefaultXCCAutoOpenErrorsPanel:	@YES,
        kDefaultXCCProjectHistory:		[NSArray new],
        kDefaultMaxRecentProjects:		@20
    };
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[defaults registerDefaults:appDefaults];

	[defaults addObserver:self
               forKeyPath:kDefaultMaxRecentProjects
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
}

- (void)pruneProjectHistory
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *projectHistory = [[defaults arrayForKey:kDefaultXCCProjectHistory] mutableCopy];
    NSFileManager *fm = [NSFileManager new];

    for (NSInteger i = projectHistory.count - 1; i >= 0; --i)
    {
        if (![fm fileExistsAtPath:projectHistory[i]])
			[projectHistory removeObjectAtIndex:i];
    }

    NSInteger maxProjects = [defaults integerForKey:kDefaultMaxRecentProjects];

    if (projectHistory.count > maxProjects)
        [projectHistory removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(maxProjects, projectHistory.count - maxProjects)]];

    [defaults setObject:projectHistory forKey:kDefaultXCCProjectHistory];
}

#pragma mark - Properties

- (NSImage *)iconActive
{
    if (!_iconActive)
        _iconActive = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"icon-active.png"]];

    return _iconActive;
}

- (NSImage *)iconInactive
{
    if (!_iconInactive)
        _iconInactive = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"icon-inactive.png"]];

    return _iconInactive;
}

- (NSImage *)iconWorking
{
    if (!_iconWorking)
        _iconWorking = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"icon-working.png"]];

    return _iconWorking;
}

- (NSMenu *)menuHistory
{
    if (!_menuHistory)
    {
        _menuHistory = [NSMenu new];
        _menuHistory.autoenablesItems = NO;
        self.menuItemHistory.submenu = _menuHistory;
	}

    return _menuHistory;
}


#pragma mark - Notification handlers

/*!
	Clean up when the application stops.
	It will stop the FSEvent listener, and store the last event id.
*/
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app
{
    [self.xcc stop];
    
    return NSTerminateNow;
}

- (void)XcodeCappConversionDidStart:(NSNotification *)aNotification
{
    self.statusItem.image = self.iconWorking;
}

- (void)XcodeCappConversionDidStop:(NSNotification *)aNotification
{
    if (!self.xcc.isLoadingProject)
        self.statusItem.image = self.iconActive;
}

- (void)XcodeCappDidPopulateProject:(NSNotification *)aNotification
{
}

- (void)XcodeCappListeningDidStart:(NSNotification *)aNotification
{
    self.statusItem.image = self.iconActive;
    self.menuItemListen.title = [NSString stringWithFormat:@"Stop Listening to “%@”", self.xcc.currentProjectPath.lastPathComponent];
    self.menuItemListen.action = @selector(stopListening:);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:kDefaultMaxRecentProjects])
        [self pruneProjectHistory];
}

#pragma mark - Utilities

- (void)updateHistoryMenu
{
    [self.menuHistory removeAllItems];
    NSArray *projectHistory = [[NSUserDefaults standardUserDefaults] arrayForKey:kDefaultXCCProjectHistory];

    for (NSString *path in projectHistory)
    {
        NSMenuItem *item = [self.menuHistory addItemWithTitle:path.lastPathComponent action:@selector(switchToProject:) keyEquivalent:@""];
        [item setEnabled:YES];
        item.representedObject = path;
    }

    [self.menuHistory addItem:[NSMenuItem separatorItem]];
    [self.menuHistory addItemWithTitle:@"Clear history" action:@selector(clearProjectHistory:) keyEquivalent:@""];

    self.menuItemHistory.enabled = [projectHistory count] > 0;
}


#pragma mark - Actions

- (IBAction)listenToProject:(id)aSender
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.title = @"Choose Cappuccino Project";
    openPanel.canChooseDirectories = YES;
    openPanel.canCreateDirectories = YES;
    openPanel.canChooseFiles = NO;
    
    if ([openPanel runModal] != NSFileHandlingPanelOKButton)
        return;

    NSString *projectPath = [[openPanel.URLs[0] path] stringByStandardizingPath];
    [self listenToProjectAtPath:projectPath];
}

- (void)listenToProjectAtPath:(NSString *)path
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *projectHistory = [[defaults arrayForKey:kDefaultXCCProjectHistory] mutableCopy];

    if ([projectHistory containsObject:path])
        [projectHistory removeObject:path];

    [projectHistory insertObject:path atIndex:0];

    [defaults setObject:projectHistory forKey:kDefaultXCCProjectHistory];
    [self pruneProjectHistory];
    [self updateHistoryMenu];

    [self stopListening:self];
    [self.xcc listenToProjectAtPath:path];
}

- (void)stopListening:(id)aSender
{
    [self.xcc stop];
    
    self.statusItem.image = self.iconInactive;
    self.menuItemListen.title = @"Listen to Project…";
    self.menuItemListen.action = @selector(listenToProject:);

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDefaultLastOpenedPath];
}

- (void)switchToProject:(id)aSender
{
    NSString *projectPath = [aSender representedObject];

    [self stopListening:aSender];
    [self listenToProjectAtPath:projectPath];
}

- (void)clearProjectHistory:(id)aSender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray array] forKey:kDefaultXCCProjectHistory];
    [self updateHistoryMenu];
}

- (IBAction)openInXcode:(id)aSender
{
    if (!self.xcc.currentProjectPath)
        return;
    
    DLog(@"Opening Xcode project at: %@", self.xcc.XcodeSupportProjectURL.path);
    system([[NSString stringWithFormat:@"open \"%@\"", self.xcc.XcodeSupportProjectURL.path] UTF8String]);
}

- (IBAction)openHelp:(id)aSender
{
    [self.helpTextView readRTFDFromFile:[[NSBundle mainBundle] pathForResource:@"help" ofType:@"rtfd"]];
    
    [self openWindow:self.helpWindow centered:YES];
}

- (IBAction)openAbout:(id)aSender
{
    [self openWindow:self.aboutWindow centered:YES];
}

- (IBAction)openPreferences:(id)aSender
{
    [self openWindow:self.preferencesWindow centered:NO];
}

- (void)openWindow:(NSWindow *)aWindow centered:(BOOL)shouldBeCentered
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    
    if (shouldBeCentered)
        [aWindow center];

    [aWindow makeKeyAndOrderFront:nil];
}


#pragma mark - Delegates

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem
{
    if (aMenuItem == self.menuItemListen)
        return !!self.xcc.currentProjectPath;
    
    return YES;
}

#pragma mark - Private Helpers

- (NSString *)bundleVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

@end
