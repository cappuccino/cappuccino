/*
 * This file is a part of program xcodecapp-cocoa
 * Copyright (C) 2011  Antoine Mercadal (primalmotion@archipelproject.org)
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


#import "AppController.h"


@implementation AppController

#pragma mark -
#pragma mark Initialization

/*!
 Called when NIB is ready
 */
- (void)awakeFromNib
{
    if (!growlDelegateRef)
        growlDelegateRef = [[[PRHEmptyGrowlDelegate alloc] init] autorelease];
    
    [GrowlApplicationBridge setGrowlDelegate:growlDelegateRef];
    
    NSBundle *bundle = [NSBundle mainBundle];
    
    [labelVersion setStringValue:[NSString stringWithFormat:@"Version %@", [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]]];

    [self registerDefaults];
    
    _iconInactive = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"xcodecapp-cocoa-icon-inactive" ofType:@"png"]];
    _iconActive = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"xcodecapp-cocoa-icon-active" ofType:@"png"]];
    _iconWorking = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"xcodecapp-cocoa-icon-working" ofType:@"png"]];
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
    
    _xcc = [[TNXCodeCapp alloc] init];
    [_xcc setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(XCodeCappConversionDidStart:) name:XCCConversionStartNotification object:_xcc];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(XCodeCappConversionDidStop:) name:XCCConversionStopNotification object:_xcc];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(XCodeCappPopulateProject:) name:XCCDidPopulateProjectNotification object:_xcc];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(XCodeCappListeningDidStart:) name:XCCListeningStartNotification object:_xcc];
    
    [_xcc start];
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
    [_xcc clear];
    
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
    [self growlWithTitle:[[[[aNotification userInfo] objectForKey:@"URL"] path] lastPathComponent]
                 message:@"Your project has been loaded successfully!"];
    
}

/*!
 Called when XCC start a to listen to a project
 @param aNotification the notification
 */
- (void)XCodeCappListeningDidStart:(NSNotification *)aNotification
{
    [_statusItem setImage:_iconActive];
    [menuItemProjectName setTitle:[NSString stringWithFormat:@"Current project: %@", [_xcc currentProjectName]]];
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
 Open the folder chooser and eventually start to listen
 @param aSender the sender of the action
 */
- (IBAction)chooseFolder:(id)aSender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setPrompt:@"Choose Cappuccino project"];
    [openPanel setCanChooseFiles:NO];
    
    if ([openPanel runModal] != NSFileHandlingPanelOKButton)
        return;
    
    [_xcc listenProjectAtPath:[NSString stringWithFormat:@"%@/", [[[openPanel URLs] objectAtIndex:0] path]]];
}

/*!
 Stop listening to a project
 @param aSender the sender of the action
 */
- (IBAction)stopListener:(id)aSender
{
    [_xcc clear];
    
    [_statusItem setImage:_iconInactive];
    [menuItemProjectName setTitle:@"No project selected"];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastOpenedPath"];
}

/*!
 Open the xCode support project in xCode
 @param aSender the sender of the action
 */
- (IBAction)openXCode:(id)aSender
{
    if (![_xcc currentProjectURL])
        return;
    
    NSLog(@"Open Xcode project at URL : '%@'", [[_xcc XCodeSupportProject] path]);
    system([[NSString stringWithFormat:@"open \"%@\"", [[_xcc XCodeSupportProject] path]] UTF8String]);
}

/*!
 reload error table data and show it
 @param aSender the sender of the action
 */
- (void)updateErrorTable
{
    [errorsTable reloadData];
    [errorsPanel orderFront:self];
}

/*!
 Clear all errors in errors table
 @param aSender the sender of the action
 */
- (IBAction)clearErrors:(id)sender
{
    [[_xcc errorList] removeAllObjects];
    [errorsTable reloadData];
}

/*!
 Open the help file
 @param aSender the sender of the action
 */
- (IBAction)openHelp:(id)aSender
{
    [helpTextView readRTFDFromFile:[[NSBundle mainBundle] pathForResource:@"help" ofType:@"rtfd"]];
    
    [helpWindow center];
    [helpWindow makeKeyAndOrderFront:aSender];
}


#pragma mark -
#pragma mark Delegates

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem
{
    if (aMenuItem == menuItemStart)
        return ![_xcc currentProjectURL];
    if ((aMenuItem == menuItemStop) || (aMenuItem == menuItemOpenXCode))
        return !![_xcc currentProjectURL];
    
    return YES;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[_xcc errorList] count];
}

- (id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [[_xcc errorList] objectAtIndex:row];
}

- (void)tableViewColumnDidResize:(NSNotification *)tableView
{
    [errorsTable noteHeightOfRowsWithIndexesChanged:
     [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[_xcc errorList] count])]];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(int)aRow
{
    // Get column you want - first in this case:
    NSTableColumn *tabCol = [[tableView tableColumns] objectAtIndex:0];
    float width = [tabCol width];
    NSRect r = NSMakeRect(0,0,width,1000.0);
    NSCell *cell = [tabCol dataCellForRow:aRow];
    NSString *content = [[_xcc errorList] objectAtIndex:aRow];
    [cell setObjectValue:content];
    float height = [cell cellSizeForBounds:r].height;
    
    if (height <= 0)
        height = 16.0; // Ensure miniumum height is 16.0
    
    return height;
}

@end
