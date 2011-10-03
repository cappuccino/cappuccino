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

#import <Cocoa/Cocoa.h>
#import "PRHEmptyGrowlDelegate.h"

@interface AppController : NSObject <NSMenuDelegate>
{
    IBOutlet NSButton               *buttonOpenXCode;
    IBOutlet NSButton               *buttonStart;
    IBOutlet NSButton               *buttonStop;
    IBOutlet NSMenu                 *statusMenu;
    IBOutlet NSMenuItem             *menuItemOpenXCode;
    IBOutlet NSMenuItem             *menuItemStart;
    IBOutlet NSMenuItem             *menuItemStop;
    IBOutlet NSPanel                *errorsPanel;
    IBOutlet NSProgressIndicator    *spinner;
    IBOutlet NSTableView            *errorsTable;
    IBOutlet NSTextField            *labelCurrentPath;
    IBOutlet NSTextField            *labelPath;
    IBOutlet NSTextField            *labelStatus;
    IBOutlet NSWindow               *mainWindow;
    
    FSEventStreamRef                stream;
    NSDate                          *appStartedTimestamp;
    NSFileManager                   *fm;
    NSImage                         *_iconActive;
    NSImage                         *_iconInactive;
    NSMutableArray                  *errorList;
    NSMutableArray                  *ignoredFilePaths;
    NSMutableArray                  *modifiedXIBs;
    NSMutableDictionary             *pathModificationDates;
    NSNumber                        *lastEventId;
    NSStatusItem                    *_statusItem;
    NSString                        *currentProjectName;
    NSString                        *parserPath;
    NSString                        *XCodeSupportPBXPath;
    NSString                        *XCodeSupportProjectName;
    NSString                        *XCodeTemplatePBXPath;
    NSString                        *_profilePath;
    NSURL                           *currentProjectURL;
    NSURL                           *XCodeSupportFolder;
    NSURL                           *XCodeSupportProject;
    NSURL                           *XCodeSupportProjectSources;
    PRHEmptyGrowlDelegate           *growlDelegateRef;
}

- (BOOL)isObjJFile:(NSString*)path;
- (BOOL)isPathMatchingIgnoredPaths:(NSString*)aPath;
- (BOOL)isXIBFile:(NSString *)path;
- (BOOL)prepareXCodeSupportProject;
- (BOOL)validateMenuItem:(NSMenuItem*)menuItem;
- (NSURL*)shadowURLForSourceURL:(NSURL*)aSourceURL;
- (void)handleFileModification:(NSString*)path ignoreDate:(BOOL)shouldIgnoreDate;
- (void)initializeEventStreamWithPath:(NSString*)aPath;
- (void)registerDefaults;
- (void)updateErrorTable;
- (void)updateLastEventId:(uint64_t)eventId;

- (IBAction)chooseFolder:(id)aSender;
- (IBAction)clearErrors:(id)sender;
- (IBAction)openXCode:(id)aSender;
- (IBAction)stopListener:(id)aSender;

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag;
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(int)aRow;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;

@end

