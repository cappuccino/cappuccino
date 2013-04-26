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
@property (nonatomic) NSImage   *iconActive;
@property (nonatomic) NSImage 	*iconInactive;
@property (nonatomic) NSImage 	*iconWorking;
@property (nonatomic) NSImage 	*iconError;
@property (nonatomic) NSMenu    *recentMenu;
@property NSStatusItem    		*statusItem;

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
    self.statusItem.length = self.iconInactive.size.width + 12;  // Add some space around the icon
    self.statusMenu.delegate = self;
    self.helpTextView.textContainerInset = NSMakeSize(10.0, 10.0);

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    double firstLaunchVersion = [defaults doubleForKey:kDefaultFirstLaunchVersion];

    // Note: the scanner will only get the major.minor version numbers, which is what we want.
    NSScanner *scanner = [NSScanner scannerWithString:[self bundleVersion]];
    double appVersion = 0.0;
    [scanner scanDouble:&appVersion];

    if ([defaults boolForKey:kDefaultFirstLaunch] || appVersion > firstLaunchVersion)
    {
        [defaults setBool:NO forKey:kDefaultFirstLaunch];
        [defaults setDouble:appVersion forKey:kDefaultFirstLaunchVersion];
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
        kDefaultLastEventId:  						[NSNumber numberWithUnsignedLongLong:kFSEventStreamEventIdSinceNow],
        kDefaultFirstLaunch:  						@YES,
        kDefaultFirstLaunchVersion:  				@2.0,
        kDefaultXCCAPIMode:   						[NSNumber numberWithInt:kXCCAPIModeAuto],
        kDefaultXCCReactMode: 						@YES,
        kDefaultXCCReopenLastProject: 				@YES,
        kDefaultXCCAutoOpenErrorsPanelOnWarnings:	@YES,
        kDefaultXCCAutoOpenErrorsPanelOnErrors:		@YES,
        kDefaultXCCProjectHistory:					[NSArray new],
        kDefaultMaxRecentProjects:					@20
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
        _iconActive = [NSImage imageNamed:@"icon-active"];

    return _iconActive;
}

- (NSImage *)iconInactive
{
    if (!_iconInactive)
        _iconInactive = [NSImage imageNamed:@"icon-inactive"];

    return _iconInactive;
}

- (NSImage *)iconWorking
{
    if (!_iconWorking)
        _iconWorking = [NSImage imageNamed:@"icon-working"];

    return _iconWorking;
}

- (NSImage *)iconError
{
    if (!_iconError)
        _iconError = [NSImage imageNamed:@"icon-error"];

    return _iconError;
}

- (NSMenu *)recentMenu
{
    if (!_recentMenu)
    {
        _recentMenu = [NSMenu new];
        _recentMenu.delegate = self;
        self.menuItemHistory.submenu = _recentMenu;
	}

    return _recentMenu;
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
        self.statusItem.image = self.xcc.hasErrors ? self.iconError : self.iconActive;
}

- (void)XcodeCappDidPopulateProject:(NSNotification *)aNotification
{
}

- (void)XcodeCappListeningDidStart:(NSNotification *)aNotification
{
    self.statusItem.image = self.xcc.hasErrors ? self.iconError : self.iconActive;
    self.menuItemListen.title = [NSString stringWithFormat:@"Close “%@”", self.xcc.currentProjectPath.lastPathComponent];
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
    [self.recentMenu removeAllItems];
    NSArray *projectHistory = [[NSUserDefaults standardUserDefaults] arrayForKey:kDefaultXCCProjectHistory];

    for (NSString *path in projectHistory)
    {
        NSMenuItem *item = [self.recentMenu addItemWithTitle:path.lastPathComponent action:@selector(switchToProject:) keyEquivalent:@""];
        [item setEnabled:YES];
        item.representedObject = path;
    }

    [self.recentMenu addItem:[NSMenuItem separatorItem]];
    [self.recentMenu addItemWithTitle:@"Clear history" action:@selector(clearProjectHistory:) keyEquivalent:@""];

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
    [self stopListening:self];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *projectHistory = [[defaults arrayForKey:kDefaultXCCProjectHistory] mutableCopy];

    if ([projectHistory containsObject:path])
        [projectHistory removeObject:path];

    // The path may no longer be there, validate it
    NSFileManager *fm = [NSFileManager defaultManager];
    
    BOOL exists, isDirectory;
    exists = [fm fileExistsAtPath:path isDirectory:&isDirectory];

    if (exists && isDirectory)
    {
        [projectHistory insertObject:path atIndex:0];
    }
    else
    {
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Project not found.";
        alert.informativeText = [NSString stringWithFormat:@"%@ %@", path, !exists ? @"no longer exists." : @"is not a directory."];
        [alert runModal];
    }

    [defaults setObject:projectHistory forKey:kDefaultXCCProjectHistory];
    [self pruneProjectHistory];
    [self updateHistoryMenu];

    if (exists && isDirectory)
        [self.xcc listenToProjectAtPath:path];
}

- (void)stopListening:(id)aSender
{
    [self.xcc stop];
    
    self.statusItem.image = self.iconInactive;
    self.menuItemListen.title = @"Open Project…";
    self.menuItemListen.action = @selector(listenToProject:);

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDefaultLastOpenedPath];
}

- (void)switchToProject:(id)aSender
{
    [self listenToProjectAtPath:[aSender representedObject]];
}

- (void)clearProjectHistory:(id)aSender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray array] forKey:kDefaultXCCProjectHistory];
    [self updateHistoryMenu];
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
    NSMenu *menu = aMenuItem.menu;
    
    if (aMenuItem == self.menuItemListen)
    {
        return !!self.xcc.currentProjectPath;
    }
    else if (menu == self.recentMenu)
    {
        // Disable recent items if they don't exist or are not directories,
        // but enable the Clear History item, which is last in the menu.
        if ([menu indexOfItem:aMenuItem] == menu.itemArray.count - 1)
            return YES;
        
        NSFileManager *fm = [NSFileManager defaultManager];

        BOOL exists, isDirectory;
        exists = [fm fileExistsAtPath:aMenuItem.representedObject isDirectory:&isDirectory];

        return exists && isDirectory;
    }
    
    return YES;
}

#pragma mark - Private Helpers

- (NSString *)bundleVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

@end
