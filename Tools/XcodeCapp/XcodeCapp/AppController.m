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
#import "Notifications.h"
#import "XcodeCapp.h"
#import "UserDefaults.h"


AppController *SharedAppControllerInstance = nil;


@interface AppController ()

@property (nonatomic) NSImage *iconActive;
@property (nonatomic) NSImage *iconInactive;
@property (nonatomic) NSImage *iconWorking;
@property (nonatomic) NSImage *iconError;
@property (nonatomic) NSMenu  *recentMenu;
@property NSStatusItem        *statusItem;
@property NSString            *finderName;
@property BOOL                appFinishedLaunching;
@property NSString            *pathToOpenAtLaunch;
@property NSFileManager       *fm;

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
    self.fm = [NSFileManager defaultManager];
        
    [self registerDefaultPreferences];
    [self initLogging];

    DDLogVerbose(@"\n******************************\n**    XcodeCapp started     **\n******************************\n");

    self.aboutWindow.backgroundColor = [NSColor whiteColor];
    [self initStatusItem];
    [self initObservers];
    [self initShowInFinderItem];
    [self pruneProjectHistory];
    [self updateHistoryMenu];
    [self checkFirstLaunch];
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    if (filename)
    {
        NSString *path = filename.stringByStandardizingPath;
        
        if (self.appFinishedLaunching)
            return [self loadProjectAtPath:path reopening:YES];
        else
            self.pathToOpenAtLaunch = path;
    }

    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    self.appFinishedLaunching = YES;
    
    if (![self.xcc executablesAreAccessible])
    {
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];            

        NSRunAlertPanel(
                        @"Executables are missing.",
                        @"Please make sure that each one of these executables:\n\n"
                        @"%@\n\n"
                        @"(or a symlink to it) is within one these directories:\n\n"
                        @"%@\n\n"
                        @"They do not all have to be in the same directory.",
                        @"Quit",
                        nil,
                        nil,
                        [self.xcc.executables componentsJoinedByString:@"\n"],
                        [self.xcc.environmentPaths componentsJoinedByString:@"\n"]);

        [[NSApplication sharedApplication] terminate:self];
        return;
    }

    // If we were opened from the command line, self.pathToOpenAtLaunch will be set.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (!self.pathToOpenAtLaunch)
    {
        if (![defaults boolForKey:kDefaultXCCReopenLastProject])
            return;

        self.pathToOpenAtLaunch = [defaults objectForKey:kDefaultLastOpenedPath];
    }
    
    if (self.pathToOpenAtLaunch)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.pathToOpenAtLaunch])
            [self loadProjectAtPath:self.pathToOpenAtLaunch reopening:YES];
        else
            [defaults removeObjectForKey:kDefaultLastOpenedPath];
    }
}

/*!
    Register default values for preferences
*/
- (void)registerDefaultPreferences
{
    NSDictionary *appDefaults = @{
        kDefaultLastEventId:                        [NSNumber numberWithUnsignedLongLong:kFSEventStreamEventIdSinceNow],
        kDefaultFirstLaunch:                        @YES,
        kDefaultFirstLaunchVersion:                 @2.0,
        kDefaultXCCAPIMode:                         [NSNumber numberWithInt:kXCCAPIModeAuto],
        kDefaultXCCReactToInodeMod:                 @YES,
        kDefaultXCCReopenLastProject:               @YES,
        kDefaultXCCAutoOpenErrorsPanelOnWarnings:   @YES,
        kDefaultXCCAutoOpenErrorsPanelOnErrors:     @YES,
        kDefaultXCCProjectHistory:                  [NSArray new],
        kDefaultMaxRecentProjects:                  @20,
        kDefaultLogLevel:                           [NSNumber numberWithInt:LOG_LEVEL_WARN],
        kDefaultAutoOpenXcodeProject:               @YES,
        kDefaultShowProcessingNotices:              @YES
    };
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults registerDefaults:appDefaults];
    [defaults synchronize];

    [defaults addObserver:self
               forKeyPath:kDefaultMaxRecentProjects
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
}

- (void)initLogging
{
#if DEBUG
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    [DDLogLevel setLogLevel:LOG_LEVEL_VERBOSE];
#else
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int logLevel = (int)[defaults integerForKey:kDefaultLogLevel];
    NSUInteger modifiers = [NSEvent modifierFlags];

    if (modifiers & NSAlternateKeyMask)
        logLevel = LOG_LEVEL_VERBOSE;

    [DDLogLevel setLogLevel:logLevel];
#endif
}

- (void)initStatusItem
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.menu = self.statusMenu;
    self.statusItem.image = self.iconInactive;
    self.statusItem.highlightMode = YES;
    self.statusItem.length = self.iconInactive.size.width + 12;  // Add some space around the icon
    self.statusMenu.delegate = self;
}

- (void)initObservers
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter addObserver:self selector:@selector(batchDidStart:) name:XCCBatchDidStartNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(batchDidEnd:) name:XCCBatchDidEndNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(projectDidFinishLoading:) name:XCCProjectDidFinishLoadingNotification object:nil];
}

- (void)initShowInFinderItem
{
    // See if PathFinder is available
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSString *path = [workspace absolutePathForAppBundleWithIdentifier:@"com.cocoatech.PathFinder"];

    if (path)
        self.finderName = path.lastPathComponent.stringByDeletingPathExtension;
    else
        self.finderName = @"Finder";

    self.menuItemShowInFinder.title = [NSString stringWithFormat:self.menuItemShowInFinder.title, self.finderName];
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

- (void)checkFirstLaunch
{
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

- (void)batchDidStart:(NSNotification *)note
{
    DDLogVerbose(@"Batch start");
    
    self.statusItem.image = self.iconWorking;
}

- (void)batchDidEnd:(NSNotification *)note
{
    DDLogVerbose(@"Batch end");

    if (!self.xcc.isLoadingProject)
        self.statusItem.image = self.xcc.hasErrors ? self.iconError : self.iconActive;
}

- (void)projectDidFinishLoading:(NSNotification *)note
{
    self.statusItem.image = self.xcc.hasErrors ? self.iconError : self.iconActive;
    self.menuItemOpenProject.title = [NSString stringWithFormat:@"Close “%@”", self.xcc.projectPath.lastPathComponent];
    self.menuItemOpenProject.action = @selector(closeProject:);
}

// Watch changes to the max recent projects preference
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kDefaultMaxRecentProjects])
        [self pruneProjectHistory];
}

#pragma mark - Actions

- (IBAction)loadProject:(id)aSender
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
    [self loadProjectAtPath:projectPath reopening:YES];
}

- (void)closeProject:(id)aSender
{
    [self.xcc stop];
    
    self.statusItem.image = self.iconInactive;
    self.menuItemOpenProject.title = @"Open Project…";
    self.menuItemOpenProject.action = @selector(loadProject:);

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDefaultLastOpenedPath];
}

- (void)switchToProject:(NSMenuItem *)aSender
{
    [self loadProjectAtPath:aSender.representedObject reopening:NO];
}

- (void)clearProjectHistory:(id)aSender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray array] forKey:kDefaultXCCProjectHistory];
    [self updateHistoryMenu];
}

- (IBAction)showInFinder:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openFile:self.xcc.projectPath withApplication:self.finderName];
}

- (IBAction)openHelp:(id)aSender
{
    if (!self.helpView.document)
    {
        NSURL *helpURL = [[NSBundle mainBundle] URLForResource:@"help" withExtension:@"pdf"];
        PDFDocument *help = [[PDFDocument alloc] initWithURL:helpURL];
        self.helpView.document = help;
    }

    [self openWindow:self.helpWindow];
}

- (IBAction)openAbout:(id)aSender
{
    [self openWindow:self.aboutWindow];
}

- (IBAction)openPreferences:(id)aSender
{
    [self openWindow:self.preferencesWindow];
}

#pragma mark - Delegates

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app
{
    [self.xcc stop];

    return NSTerminateNow;
}

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem
{
    NSMenu *menu = aMenuItem.menu;

    if (menu == self.recentMenu)
    {
        // Disable recent items if they don't exist or are not directories,
        // but enable the Clear History item, which is last in the menu.
        if ([menu indexOfItem:aMenuItem] == menu.itemArray.count - 1)
            return YES;
        
        BOOL isDirectory;
        BOOL exists = [self.fm fileExistsAtPath:aMenuItem.representedObject isDirectory:&isDirectory];

        return exists && isDirectory;
    }
    
    return YES;
}

#pragma mark - Bindings

- (NSString *)bundleVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

#pragma mark - Private Helpers

- (BOOL)loadProjectAtPath:(NSString *)path reopening:(BOOL)reopen
{
    if (!reopen && [self.xcc.projectPath isEqualToString:path])
        return YES;
    
    [self closeProject:self];

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
        NSRunAlertPanel(@"Project not found.", @"%@ %@", nil, nil, nil, path, !exists ? @"no longer exists." : @"is not a directory.");
    }

    [defaults setObject:projectHistory forKey:kDefaultXCCProjectHistory];
    [self pruneProjectHistory];
    [self updateHistoryMenu];

    if (exists && isDirectory)
    {
        [self.xcc loadProjectAtPath:path];
        return YES;
    }
    else
        return NO;
}

- (void)openWindow:(NSWindow *)aWindow
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [aWindow makeKeyAndOrderFront:nil];
}

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

@end
