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

float heightForStringDrawing(NSString *myString, NSFont *myFont, float myWidth)
{
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:myString];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(myWidth, FLT_MAX)];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];

    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    [textStorage addAttribute:NSFontAttributeName value:myFont range:NSMakeRange(0, [textStorage length])];
    [textContainer setLineFragmentPadding:0.0];

    (void) [layoutManager glyphRangeForTextContainer:textContainer];
    return [layoutManager usedRectForTextContainer:textContainer].size.height;
}

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
    
    _archivedDataView = [NSKeyedArchiver archivedDataWithRootObject:dataViewError];

    if (!growlDelegateRef)
        growlDelegateRef = [[PRHEmptyGrowlDelegate alloc] init];
    
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

    [self _prepareHistoryMenu];
}

/*!
 Checks if aplication should show the debug window
 */
- (void)applicationDidFinishLaunching:(NSNotification *)notif
{
    CGEventRef event = CGEventCreate(NULL);
    CGEventFlags modifiers = CGEventGetFlags(event);
    CFRelease(event);

    if (modifiers & kCGEventFlagMaskAlternate)
    {
        [statusMenu insertItem:menuDebug atIndex:6];
    }
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
    [appDefaults setObject:[[NSArray alloc] init] forKey:@"XCCProjectHistory"];
    
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

    if ([errorsPanel isVisible])
        [errorsTable reloadData];
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

/*!
 Prepare the history menu
 */
- (void)_prepareHistoryMenu
{
    NSMenu *menu = [[NSMenu alloc] init];
    NSArray *projectHistory = [[NSUserDefaults standardUserDefaults] objectForKey:@"XCCProjectHistory"];

    for(int i = 0; i < [projectHistory count]; i++)
    {
        NSString *itemTitle = [[projectHistory objectAtIndex:i] lastPathComponent];
        NSString *projectPath = [[projectHistory objectAtIndex:i] stringByStandardizingPath];
        NSString *currentProjectPath  = [[[xcc currentProjectURL] path] stringByStandardizingPath];
        NSMenuItem *item = [menu addItemWithTitle:itemTitle action:@selector(switchProject:) keyEquivalent:@""];

        [item setRepresentedObject:projectPath];

        if ([currentProjectPath isEqualToString:projectPath])
            [item setAction:nil];
    }

    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Clear history" action:@selector(clearProjectHistory:) keyEquivalent:@""];

    [menuHistory setEnabled:([projectHistory count]) ? YES : NO];
    [menuHistory setSubmenu:menu];
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
    
    NSString *projectPath = [NSString stringWithFormat:@"%@/", [[[openPanel URLs] objectAtIndex:0] path]];
    NSMutableArray *projectHistory = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"XCCProjectHistory"]];

    if ([projectHistory containsObject:[projectPath stringByStandardizingPath]])
        [projectHistory removeObject:[projectPath stringByStandardizingPath]];

    [projectHistory insertObject:[projectPath stringByStandardizingPath] atIndex:0];

    [[NSUserDefaults standardUserDefaults] setObject:projectHistory forKey:@"XCCProjectHistory"];

    [xcc listenProjectAtPath:projectPath];

    [self _prepareHistoryMenu];
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
    [self _prepareHistoryMenu];

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastOpenedPath"];
}

- (IBAction)switchProject:(id)aSender
{
    NSString *newPath = [aSender representedObject];

    [self stopListener:aSender];
    [xcc listenProjectAtPath:newPath];
    [self _prepareHistoryMenu];
}

- (IBAction)clearProjectHistory:(id)aSender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray array] forKey:@"XCCProjectHistory"];
    [self _prepareHistoryMenu];
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
    [self openCenteredWindow:windowDebug];
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

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:_archivedDataView];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)aRow
{
    NSString *content = [[[xcc errorList] objectAtIndex:aRow] objectForKey:@"message"];
    NSFont *currentFont = [[dataViewError fieldMessage] font];
    float height = heightForStringDrawing(content, currentFont, [tableView frame].size.width);

    return height + 31;
}

@end
