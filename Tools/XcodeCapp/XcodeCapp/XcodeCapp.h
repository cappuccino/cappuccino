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

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

// FSEvent listening mode we use
enum XCCAPIMode {
    kXCCAPIModeAuto = 0,
    kXCCAPIModeFile,
    kXCCAPIModeFolder
};

// Type of output expected from runTaskWithLaunchPath:arguments:returnType:
enum XCCTaskReturnType {
    kTaskReturnTypeNone,
    kTaskReturnTypeStdOut,
    kTaskReturnTypeStdError,
    kTaskReturnTypeAny
};
typedef enum XCCTaskReturnType XCCTaskReturnType;

// Status codes returned by support scripts run as tasks
enum {
    XCCStatusCodeError = 1,
    XCCStatusCodeWarning = 2
};

// Notifications we send
extern NSString * const XCCConversionDidStartNotification;
extern NSString * const XCCConversionDidEndNotification;
extern NSString * const XCCProjectDidFinishLoadingNotification;
extern NSString * const XCCCappLintDidStartNotification;
extern NSString * const XCCCappLintDidEndNotification;

@interface XcodeCapp : NSObject <NSTableViewDelegate, NSUserNotificationCenterDelegate, GrowlApplicationBridgeDelegate>

/*
    Every time the user opens or closes a project, this is incremented. It is passed to threaded operations
    which load the project. These threaded operations generate notifications that get queued up
    on the main thread. Because the user may cancel and start a new load while notifications are
    still queued from the previous load, we compare the projectId returned by a notification
    with the current projectId. If they don't match, we let the notification drain.
*/
@property NSInteger projectId;

// An array of paths we add to the NSTask environment
@property NSArray *environmentPaths;

// An array of executable names we need to have available
@property NSArray *executables;

// Full path to .XcodeSupport
@property NSString *supportPath;

// Full path to the Cappuccino project root directory
@property NSString *projectPath;

// Full path to the <project>.xcodeproj
@property NSString *xcodeProjectPath;

// Full path to parser.j
@property NSString *parserPath;

// Full path to pbxprojModifier.py
@property NSString *pbxModifierScriptPath;

// Tooltip for the radio button symlink
@property NSString *toolTipSymlinkRadioButton;

// Full paths to the executables we rely on: jsc, objj, nib2cib, python
@property NSMutableDictionary *executablePaths;

// Whether the current OS supports file-level FSEvents (10.7+)
@property BOOL supportsFileLevelAPI;

// Whether we are actually using file-level FSEvents
@property BOOL isUsingFileLevelAPI;

// Whether we should process source files that have inode-only modifications
@property BOOL reactToInodeModification;

// Whether we are in the process of loading a project
@property BOOL isLoadingProject;

// Whether we are currently processing source files
@property BOOL isProcessing;

// Whether we are currently processing source files
@property BOOL isCappuccinoUpdating;

// Whether $CAPP_BUILD is defined or not
@property BOOL isCappBuildDefined;

// A mapping from full paths to project-relative paths
@property NSMutableDictionary *projectPathsForSourcePaths;

// A list of errors generated from the current batch of source processing
@property NSMutableArray *errorList;

// A list of files name who can be processed, based on xcapp-ignore and path pf the project
@property NSMutableArray *xCodeCappTargetedFiles;

// Panel, table and controller used to display errors
@property (strong) IBOutlet NSPanel *errorsPanel;
@property (unsafe_unretained) IBOutlet NSTableView *errorTable;
@property (strong) IBOutlet NSArrayController *errorListController;

@property (strong) IBOutlet NSProgressIndicator *progressIndicator;
@property (strong) IBOutlet NSTextField *fieldCurrentTask;
@property (strong) IBOutlet NSPanel *updatingCappuccinoPanel;

- (IBAction)openErrorsPanel:(id)sender;
- (IBAction)clearErrors:(id)sender;
- (IBAction)openErrorInEditor:(id)sender;
- (IBAction)openXcodeProject:(id)aSender;
- (IBAction)synchronizeProject:(id)aSender;
- (IBAction)checkProjectWithCappLint:(id)aSender;

- (BOOL)executablesAreAccessible;
- (void)stop;
- (void)loadProjectAtPath:(NSString *)path;
- (BOOL)pathMatchesIgnoredPaths:(NSString*)aPath;

- (BOOL)notificationBelongsToCurrentProject:(NSNotification *)note;

- (BOOL)isObjjFile:(NSString *)path;
- (BOOL)isXibFile:(NSString *)path;
- (BOOL)isXCCIgnoreFile:(NSString *)path;

- (BOOL)shouldShowErrorNotification;

- (NSString *)shadowBasePathForProjectSourcePath:(NSString *)path;
- (BOOL)hasErrors;

- (void)computeIgnoredPaths;
- (BOOL)shouldIgnoreDirectoryNamed:(NSString *)filename;

- (void)wantUserNotificationWithInfo:(NSDictionary *)info;
- (NSDictionary *)runTaskWithLaunchPath:(NSString *)launchPath arguments:(NSArray *)arguments returnType:(XCCTaskReturnType)returnType;

- (NSDictionary*)createProject:(NSString*)aPath;

- (void)showCappLintWarnings;
- (void)showObjjWarnings;

- (BOOL)shouldProcessWithCappLint;
- (BOOL)checkCappLintForPath:(NSArray*)paths;

- (BOOL)shouldProcessWithObjjWarnings;
- (BOOL)checkObjjWarningsForPath:(NSArray*)paths;

- (void)updateCappuccino;

@end

@interface XcodeCapp (SnowLeopard)

- (void)updateLastModificationDate:(NSDate *)date forPath:(NSString *)path;
- (NSDate *)lastModificationDateForPath:(NSString *)path;

@end
