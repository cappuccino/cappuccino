/*  
 * xcodecapp-cocoa.sh
 *    
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@interface AppController : NSObject
{
    IBOutlet NSTextField            *labelStatus;
    IBOutlet NSTextField            *labelPath;
    IBOutlet NSTextField            *labelCurrentPath;
    IBOutlet NSButton               *buttonOpenXCode;
    IBOutlet NSButton               *buttonStart;
    IBOutlet NSButton               *buttonStop;
    IBOutlet NSProgressIndicator    *spinner;
    IBOutlet NSWindow               *mainWindow;
    
    NSFileManager           *fm;
    NSMutableArray          *modifiedSources;
    NSMutableArray          *modifiedXIBs;
    NSMutableDictionary     *pathModificationDates;
    NSDate                  *appStartedTimestamp;
    NSNumber                *lastEventId;
    NSURL                   *currentProjectURL;
    NSString                *currentProjectName;
    FSEventStreamRef        stream;
    NSString                *XCodeSupportProjectName;
    NSString                *XCodeTemplatePBXPath;
    NSURL                   *XCodeSupportFolder;
    NSURL                   *XCodeSupportProject;
    NSURL                   *XCodeSupportProjectSources;
    NSString                *XCodeSupportPBXPath;
    NSString                *parserPath;
    NSMutableArray          *ignoredFilePaths;
}

- (void)registerDefaults;
- (void)initializeEventStreamWithPath:(NSString*)aPath;
- (void)handleFileModification:(NSString*)path ignoreDate:(BOOL)shouldIgnoreDate;
- (void)updateLastEventId:(uint64_t)eventId;
- (BOOL)isObjJFile:(NSString*)path;
- (BOOL)isXIBFile:(NSString *)path;
- (NSURL*)shadowURLForSourceURL:(NSURL*)aSourceURL;
- (BOOL)prepareXCodeSupportProject;
- (BOOL)isPathMatchingIgnoredPaths:(NSString*)aPath;

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag;

- (IBAction)chooseFolder:(id)aSender;
- (IBAction)stopListener:(id)aSender;
- (IBAction)openXCode:(id)aSender;

@end

