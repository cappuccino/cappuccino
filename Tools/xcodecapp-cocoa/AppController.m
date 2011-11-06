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
#include "macros.h"


AppController *SharedAppControllerInstance = nil;


@implementation AppController

@synthesize supportsFileModeListening;
@synthesize xcc;

+ (AppController *)sharedAppController
{
    return SharedAppControllerInstance;
}

#pragma mark -
#pragma mark Initialization

/*!
 Called when NIB is ready
 */
- (void)awakeFromNib
{
    SharedAppControllerInstance = self;
    
    if (!growlDelegateRef)
        growlDelegateRef = [[[PRHEmptyGrowlDelegate alloc] init] autorelease];
    
    [GrowlApplicationBridge setGrowlDelegate:growlDelegateRef];
    
    NSBundle *bundle = [NSBundle mainBundle];
    
    [labelVersion setStringValue:[NSString stringWithFormat:@"Version %@", [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]]];

    [self registerDefaults];
    
    _iconInactive = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"xcodecapp-icon-inactive" ofType:@"png"]];
    _iconActive = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"xcodecapp-icon-active" ofType:@"png"]];
    _iconWorking = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"xcodecapp-icon-working" ofType:@"png"]];
    [_iconActive setSize:NSMakeSize(14.0, 16.0)];
    [_iconInactive setSize:NSMakeSize(14.0, 16.0)];
    [_iconWorking setSize:NSMakeSize(14.0, 16.0)];
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setMenu:statusMenu];
    [_statusItem setImage:_iconInactive];
    [_statusItem setHighlightMode:YES];
    [statusMenu setDelegate:self];
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"FirstLaunch"])
    {
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:0] forKey:@"FirstLaunch"];
        [self openHelp:self];
    }

    [xcc setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(XCodeCappConversionDidStart:) name:XCCConversionStartNotification object:xcc];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(XCodeCappConversionDidStop:) name:XCCConversionStopNotification object:xcc];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(XCodeCappPopulateProject:) name:XCCDidPopulateProjectNotification object:xcc];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(XCodeCappListeningDidStart:) name:XCCListeningStartNotification object:xcc];
    
    [helpTextView setTextContainerInset:NSSizeFromCGSize(CGSizeMake(10.0, 10.0))];
    
    [xcc start];
}


/*!
 Register the application defaults
 */
- (void)registerDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *streamEventIdSinceNow = [NSNumber numberWithUnsignedLongLong:kFSEventStreamEventIdSinceNow];
    NSMutableDictionary *appDefaults = [NSMutableDictionary new];
    
    [appDefaults setObject:streamEventIdSinceNow forKey:@"lastEventId"];
    [appDefaults setObject:[NSNumber numberWithInt:1] forKey:@"FirstLaunch"];
    [appDefaults setObject:[NSNumber numberWithInt:0] forKey:@"XCCAPIMode"];
    [appDefaults setObject:[NSNumber numberWithInt:1] forKey:@"XCCReactMode"];
    [appDefaults setObject:[NSNumber numberWithInt:1] forKey:@"XCCReopenLastProject"];
    
    [defaults registerDefaults:appDefaults];
}


#pragma mark -
#pragma mark Notification handlers

/*!
 Handle cleaning operation when application will stop.
 It will stop the FSEvent listener, and store the last event id
 */
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app
{
    [xcc clear];
    
    return NSTerminateNow;
}

/*!
 Called when XCC start a conversion
 @param aNotification the notification
 */
- (void)XCodeCappConversionDidStart:(NSNotification *)aNotification
{
    [_statusItem setImage:_iconWorking];
}

/*!
 Called when XCC finish a conversion
 @param aNotification the notification
 */
- (void)XCodeCappConversionDidStop:(NSNotification *)aNotification
{
    [_statusItem setImage:_iconActive];
}

/*!
 Called when XCC has populated a project
 @param aNotification the notification
 */
- (void)XCodeCappPopulateProject:(NSNotification *)aNotification
{
    [self growlWithTitle:@"Project loaded" message:[[[aNotification userInfo] objectForKey:@"URL"] path]];
}

/*!
 Called when XCC start a to listen to a project
 @param aNotification the notification
 */
- (void)XCodeCappListeningDidStart:(NSNotification *)aNotification
{
    [_statusItem setImage:_iconActive];
    [menuItemStartStop setTitle:[NSString stringWithFormat:@"Stop Listening to “%@”", [xcc currentProjectName]]];
    [menuItemStartStop setAction:@selector(stopListener:)];

    [self growlWithTitle:@"Listening to project" message:[[xcc currentProjectURL] path]];
}


#pragma mark -
#pragma mark Utilities

/*!
 Simple growl wrapper
 @param aTitle the growl title
 @param aMessage the growl message
 */
- (void)growlWithTitle:(NSString *)aTitle message:(NSString *)aMessage
{
    [GrowlApplicationBridge notifyWithTitle:aTitle
                                description:aMessage
                           notificationName:@"DefaultNotifications"
                                   iconData:nil
                                   priority:0
                                   isSticky:NO
                               clickContext:nil];
}



#pragma mark -
#pragma mark Actions

/*!
 Save preferences
 @param aSender the sender of the action
 */
- (IBAction)updatePreferences:(id)aSender
{
    [preferencesController save:aSender];
    NSLog(@"Preferences change notified");

    [xcc configure];
}

/*!
 Open the folder chooser and eventually start to listen
 @param aSender the sender of the action
 */
- (IBAction)chooseFolder:(id)aSender
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setTitle:@"Choose Cappuccino Project"];
    [openPanel setCanChooseFiles:NO];
    
    if ([openPanel runModal] != NSFileHandlingPanelOKButton)
        return;
    
    [xcc listenProjectAtPath:[NSString stringWithFormat:@"%@/", [[[openPanel URLs] objectAtIndex:0] path]]];
}

/*!
 Stop listening to a project
 @param aSender the sender of the action
 */
- (IBAction)stopListener:(id)aSender
{
    [xcc clear];
    
    [_statusItem setImage:_iconInactive];
    [menuItemStartStop setTitle:@"Listen to Project…"];
    [menuItemStartStop setAction:@selector(chooseFolder:)];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastOpenedPath"];
}

/*!
 Open the xCode support project in xCode
 @param aSender the sender of the action
 */
- (IBAction)openXCode:(id)aSender
{
    if (![xcc currentProjectURL])
        return;
    
    DLog(@"Opening Xcode project at URL: '%@'", [[xcc XCodeSupportProject] path]);
    system([[NSString stringWithFormat:@"open \"%@\"", [[xcc XCodeSupportProject] path]] UTF8String]);
}

/*!
 reload error table data and show it
 @param aSender the sender of the action
 */
- (void)updateErrorTable
{
    [errorsTable reloadData];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [errorsPanel orderFront:self];
}

/*!
 Open the errors window
 @param aSender the sender of the action
 */
- (IBAction)openErrors:(id)aSender
{
    [self openCenteredWindow:errorsPanel];
}

/*!
 Clear all errors in errors table
 @param aSender the sender of the action
 */
- (IBAction)clearErrors:(id)sender
{
    [[xcc errorList] removeAllObjects];
    [errorsTable reloadData];
}

/*!
 Open the help file
 @param aSender the sender of the action
 */
- (IBAction)openHelp:(id)aSender
{
    [helpTextView readRTFDFromFile:[[NSBundle mainBundle] pathForResource:@"help" ofType:@"rtfd"]];
    
    [self openCenteredWindow:helpWindow];
}

/*!
 Open the about window
 @param aSender the sender of the action
 */
- (IBAction)openAbout:(id)aSender
{
    [self openCenteredWindow:aboutWindow];
}

/*!
 Open the preferences window
 @param aSender the sender of the action
 */
- (IBAction)openPreferences:(id)aSender
{
    [self openCenteredWindow:preferencesWindow];
}

/*!
 Open a centered window.
*/
- (void)openCenteredWindow:(NSWindow *)aWindow
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    
    [aWindow center];
    [aWindow makeKeyAndOrderFront:nil];
}


#pragma mark -
#pragma mark Delegates

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem
{
    if (aMenuItem == menuItemOpenXCode)
        return !![xcc currentProjectURL];
    
    return YES;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[xcc errorList] count];
}

- (id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [[xcc errorList] objectAtIndex:row];
}

- (void)tableViewColumnDidResize:(NSNotification *)tableView
{
    [errorsTable noteHeightOfRowsWithIndexesChanged:
     [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[xcc errorList] count])]];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(int)aRow
{
    // Get column you want - first in this case:
    NSTableColumn *tabCol = [[tableView tableColumns] objectAtIndex:0];
    float width = [tabCol width];
    NSRect r = NSMakeRect(0,0,width,1000.0);
    NSCell *cell = [tabCol dataCellForRow:aRow];
    NSString *content = [[xcc errorList] objectAtIndex:aRow];
    [cell setObjectValue:content];
    float height = [cell cellSizeForBounds:r].height;
    
    if (height <= 0)
        height = 16.0; // Ensure miniumum height is 16.0
    
    return height;
}

@end
