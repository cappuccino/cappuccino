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

#include <fcntl.h>

#import <Growl/Growl.h>

#import "XcodeCapp.h"
#import "AppController.h"
#import "FindSourceFilesOperation.h"
#import "Notifications.h"
#import "ProcessSourceOperation.h"
#import "UserDefaults.h"
#import "XcodeProjectCloser.h"


#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_6
#   define kFSEventStreamCreateFlagFileEvents       0x00000010
#   define kFSEventStreamEventFlagItemIsFile        0x00010000
#   define kFSEventStreamEventFlagItemRemoved       0x00000200
#   define kFSEventStreamEventFlagItemCreated       0x00000200
#   define kFSEventStreamEventFlagItemModified      0x00001000
#   define kFSEventStreamEventFlagItemInodeMetaMod  0x00000400
#   define kFSEventStreamEventFlagItemRenamed       0x00000800
#   define kFSEventStreamEventFlagItemFinderInfoMod 0x00002000
#   define kFSEventStreamEventFlagItemChangeOwner   0x00004000
#   define kFSEventStreamEventFlagItemXattrMod      0x00008000
#endif


enum XCCLineSpecifier {
    kLineSpecifierNone,
    kLineSpecifierColon,
    kLineSpecifierMinusL,
    kLineSpecifierPlus
};
typedef enum XCCLineSpecifier XCCLineSpecifier;

// Where we put the generated Cocoa class files
static NSString * const XCCSupportFolderName = @".XcodeSupport";

// We store a compatibility version in .XcodeSupport/Info.plist.
// If the version is less than the version in XcodeCapp's Info.plist, we regenerate .XcodeSupport.
static NSString * const XCCCompatibilityVersionKey = @"XCCCompatibilityVersion";

// We replace "/" in a path with this. It looks like "/",
// but is actually an obscure Unicode character we hope no one uses in a filename.
static NSString * const XCCSlashReplacement = @"∕";  // DIVISION SLASH, Unicode: U+2215

// When scanning the project, we immediately ignore directories that match this regex.
static NSString * const XCCDirectoriesToIgnorePattern = @"^(?:Build|F(?:rameworks|oundation)|AppKit|Objective-J|(?:Browser|CommonJS)\\.environment|Resources|XcodeSupport|.+\\.xcodeproj)$";

// The key for an Info.plist array of the mandatory executables XCC needs.
static NSString * const XCCMandatoryExecutablesKey = @"XCCMandatoryExecutables";

// The regex above is used with this predicate for testing.
static NSPredicate * XCCDirectoriesToIgnorePredicate = nil;

// An array of the default predicates used to ignore paths.
static NSArray *XCCDefaultIgnoredPathPredicates = nil;

NSString * const XCCCappLintDidStartNotification = @"XCCCappLintDidStartNotification";
NSString * const XCCCappLintDidEndNotification = @"XCCCappLintDidEndNotification";
NSString * const XCCObjjDidStartNotification = @"XCCObjjDidStartNotification";
NSString * const XCCObjjDidEndNotification = @"XCCObjjDidEndNotification";

@interface XcodeCapp ()

// Only used with 10.6 when we don't have file-level FSEvents
@property (nonatomic) NSMutableDictionary *pathModificationDates;

@property FSEventStreamRef stream;

// Whether the FSEventStream is started or stopped.
@property BOOL streamStarted;

// The last FSEvent id we received. This is stored in the user prefs
// so we can get all changes since the last time XcodeCapp was launched.
@property NSNumber *lastEventId;

@property NSDate *appStartedTimestamp;

@property NSFileManager *fm;

// An NSString version of XCCCloseXcodeProjectScript
@property NSString *closeXcodeProjectScriptSource;

// Full path to .xcodecapp-ignore
@property NSString *xcodecappIgnorePath;

// The current array of predicates used to ignore paths
@property NSMutableArray *ignoredPathPredicates;

// The environment we pass to tasks launched from XcodeCapp
@property NSMutableDictionary *environment;

// We keep a file descriptor open for the project directory
// so we can locate it if it moves.
@property int projectPathFileDescriptor;

// Coalesces the modifications that have to be made to the Xcode project
// after changes are made to source files. Keys are the actions "add" or "remove",
// values are arrays of full paths to source files that need to be added or removed.
@property NSMutableDictionary *pbxOperations;

// A queue for threaded operations to perform
@property NSOperationQueue *operationQueue;

// We have to declare this because it is referenced by the fsevents_callback function
- (void)handleFSEventsWithPaths:(NSArray *)paths flags:(const FSEventStreamEventFlags[])eventFlags ids:(const FSEventStreamEventId[])eventIds;

@end


void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[])
{
    XcodeCapp *xcc = (__bridge  XcodeCapp *)userData;
    NSArray *paths = (__bridge  NSArray *)eventPaths;

    [xcc handleFSEventsWithPaths:paths flags:eventFlags ids:eventIds];
}


@implementation XcodeCapp

#pragma mark - Initialization

+ (void)initialize
{
    if (self != [XcodeCapp class])
        return;

    // Initialize static values that can't be initialized in their declarations
    
    XCCDirectoriesToIgnorePredicate = [NSPredicate predicateWithFormat:@"SELF matches %@", XCCDirectoriesToIgnorePattern];
    
    NSArray *defaultIgnoredPaths = @[
        @"*/Frameworks/",
        @"!*/Frameworks/Debug/",
        @"!*/Frameworks/Source/",
        @"*/AppKit/",
        @"*/Foundation/",
        @"*/Objective-J/",
        @"*/*.environment/",
        @"*/Build/",
        @"*/*.xcodeproj/",
        @"*/.*/",
        @"*/NS_*.j",
        @"*/main.j",
        @"*/.*",
        @"!*/.xcodecapp-ignore"
    ];

    XCCDefaultIgnoredPathPredicates = [self parseIgnorePaths:defaultIgnoredPaths];
}

- (id)init
{
    self = [super init];

    if (self)
    {
        self.errorList = [NSMutableArray arrayWithCapacity:10];
        self.fm = [NSFileManager defaultManager];
        self.ignoredPathPredicates = [NSMutableArray new];
        self.parserPath = [[NSBundle mainBundle].sharedSupportPath stringByAppendingPathComponent:@"parser.j"];
        self.appStartedTimestamp = [NSDate date];
        self.projectPathsForSourcePaths = [NSMutableDictionary new];
        self.xcodecappIgnorePath = @"";
        self.operationQueue = [NSOperationQueue new];
        self.pbxOperations = [NSMutableDictionary new];
        self.executablePaths = [NSMutableDictionary new];
        self.projectPathFileDescriptor = -1;
        self.isCappBuildDefined = YES;
        self.toolTipSymlinkRadioButton = @"If this is checked, when a Cappuccino project is created, the frameworks of the new project will be symlinked from the $CAPP_BUILD";

        [self initTaskEnvironment];

        self.isUsingFileLevelAPI = NO;
        self.isLoadingProject = NO;
        self.isProcessing = NO;

        // File-level FSEvents are only supported on 10.7+
        SInt32 versionMajor = 0;
        SInt32 versionMinor = 0;
        Gestalt(gestaltSystemVersionMajor, &versionMajor);
        Gestalt(gestaltSystemVersionMinor, &versionMinor);

        self.supportsFileLevelAPI = versionMajor >= 10 && versionMinor >= 7;

        // Uncomment to simulate 10.6 mode
        // self.supportsFileLevelAPI = NO;

        [self configureFileAPI];

        [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
        [GrowlApplicationBridge setGrowlDelegate:self];

        [self initObservers];
    }

    return self;
}

- (void)initTaskEnvironment
{
    // Add possible executable paths to PATH
    self.environment = [NSProcessInfo processInfo].environment.mutableCopy;

    self.environmentPaths =
        @[
            @"/usr/local/bin",
            @"/usr/local/narwhal/bin",
            @"~/narwhal/bin",
            @"~/bin",
            @"/usr/bin"
        ];

    NSMutableArray *paths = [self.environmentPaths mutableCopy];

    for (NSInteger i = 0; i < paths.count; ++i)
        paths[i] = [paths[i] stringByExpandingTildeInPath];

    self.environment[@"PATH"] = [[paths componentsJoinedByString:@":"] stringByAppendingFormat:@":%@", self.environment[@"PATH"]];

    // Make sure we are using jsc as the narwhal engine!
    self.environment[@"NARWHAL_ENGINE"] = @"jsc";
    
    // Make sure to not do something in sudo
    self.environment[@"CAPP_NOSUDO"] = @"1";

    self.executables = @[@"python", @"narwhal-jsc", @"objj", @"nib2cib", @"capp", @"capp_lint", @"jake", @"curl", @"unzip", @"rm"];

    // This is used to get the env var of $CAPP_BUILD
    NSDictionary *processEnvironment = [[NSProcessInfo processInfo] environment];
    NSArray *arguments = [NSArray arrayWithObjects:@"-l", @"-c", @"echo $CAPP_BUILD", nil];

    NSDictionary *taskResult = [self runTaskWithLaunchPath:[processEnvironment objectForKey:@"SHELL"]
                                   arguments:arguments
                                  returnType:kTaskReturnTypeStdOut];

    // Make sure to remove the \n at the end of the response
    NSString *response = [taskResult[@"response"] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    self.environment[@"CAPP_BUILD"] = response;

    // Make sure we have found a CAPP_BUILD
    if ([response length] == 0 || [taskResult[@"status"] intValue] == -1)
    {
        self.toolTipSymlinkRadioButton = @"To use this option you need to have the variable $CAPP_BUILD in your environement (export CAPP_BUILD='path/to/your/cappuccino/build')";
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@NO forKey:kDefaultUseSymlinkWhenCreatingProject];
        self.isCappBuildDefined = NO;
    }
}

- (void)initObservers
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(addSourceToProjectPathMappingHandler:) name:XCCNeedSourceToProjectPathMappingNotification object:nil];
    [center addObserver:self selector:@selector(sourceConversionDidStartHandler:) name:XCCConversionDidStartNotification object:nil];
    [center addObserver:self selector:@selector(sourceConversionDidEndHandler:) name:XCCConversionDidEndNotification object:nil];
    [center addObserver:self selector:@selector(sourceConversionDidGenerateErrorHandler:) name:XCCConversionDidGenerateErrorNotification object:nil];
}

#pragma mark - Properties

- (id)pathModificationDates
{
    if (!_pathModificationDates)
    {
        _pathModificationDates = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kDefaultPathModificationDates] mutableCopy];

        if (!_pathModificationDates)
            _pathModificationDates = [NSMutableDictionary new];
    }

    return _pathModificationDates;
}

- (BOOL)xcodeProjectCanBeOpened
{
    return (self.xcodeProjectPath &&
            !self.isProcessing &&
            [self.fm fileExistsAtPath:self.xcodeProjectPath]);
}

#pragma mark - Project Management

- (void)loadProjectAtPath:(NSString *)path
{
    DDLogInfo(@"Loading project: %@", path);

    self.isLoadingProject = YES;
    ++self.projectId;

    [self notifyUserWithTitle:@"Loading project…" message:path.lastPathComponent];

    self.projectPath = path;
    self.xcodecappIgnorePath = [self.projectPath stringByAppendingPathComponent:@".xcodecapp-ignore"];
    self.projectPathsForSourcePaths = [NSMutableDictionary new];
    [self.pbxOperations removeAllObjects];
    self.lastEventId = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultLastEventId];

    [self clearErrors:self];
    [self computeIgnoredPaths];
    
    [self prepareXcodeSupport];
    [self populateXcodeProject];
    [self populatexCodeCappTargetedFiles];
    [self waitForOperationQueueToFinishWithSelector:@selector(projectDidFinishLoading)];
}

/*!
    Create Xcode project and .XcodeSupport directory if necessary.

    @return YES if both exist
*/
- (BOOL)prepareXcodeSupport
{
    NSString *projectName = [self.projectPath.lastPathComponent stringByAppendingString:@".xcodeproj"];

    self.xcodeProjectPath = [self.projectPath stringByAppendingPathComponent:projectName];
    self.supportPath = [self.projectPath stringByAppendingPathComponent:XCCSupportFolderName];
    self.pbxModifierScriptPath = [[NSBundle mainBundle].sharedSupportPath stringByAppendingPathComponent:@"pbxprojModifier.py"];

    // If either the project or the support directory are missing, recreate them both to ensure they are in sync
    BOOL projectExists, projectIsDirectory;
    projectExists = [self.fm fileExistsAtPath:self.xcodeProjectPath isDirectory:&projectIsDirectory];

    BOOL supportExists, supportIsDirectory;
    supportExists = [self.fm fileExistsAtPath:self.supportPath isDirectory:&supportIsDirectory];

    if (!projectExists || !projectIsDirectory || !supportExists)
        [self createXcodeProject];

    // If the project did not exist, reset the XcodeSupport directory to force the new empty project to be populated
    if (!supportExists || !supportIsDirectory || !projectExists || ![self xcodeSupportIsCompatible])
        [self createXcodeSupportDirectory];

    return projectExists && supportExists;
}

- (BOOL)xcodeSupportIsCompatible
{
    double appCompatibilityVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:XCCCompatibilityVersionKey] doubleValue];
    
    NSString *infoPath = [self.supportPath stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:infoPath];
    NSNumber *projectCompatibilityVersion = info[XCCCompatibilityVersionKey];

    if (projectCompatibilityVersion == nil)
    {
        DDLogVerbose(@"No compatibility version in project");
        return NO;
    }

    DDLogVerbose(@"XcodeCapp/project compatibility version: %0.1f/%0.1f", projectCompatibilityVersion.doubleValue, appCompatibilityVersion);

    return projectCompatibilityVersion.doubleValue >= appCompatibilityVersion;
}

- (void)populatexCodeCappTargetedFiles
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *filesOfProject = [fm enumeratorAtPath:self.projectPath];
    NSString *filename;
    
    self.xCodeCappTargetedFiles = [NSMutableArray array];
    
    while ((filename = [filesOfProject nextObject] )) {
        
        NSString *fullPath = [self.projectPath stringByAppendingPathComponent:filename];
        
        if (![self isSourceFile:fullPath])
            continue;
        
        [self.xCodeCappTargetedFiles addObject:fullPath];
    }
}

- (void)createXcodeProject
{
    if ([self.fm fileExistsAtPath:self.xcodeProjectPath])
        [self.fm removeItemAtPath:self.xcodeProjectPath error:nil];

    [self.fm createDirectoryAtPath:self.xcodeProjectPath withIntermediateDirectories:YES attributes:nil error:nil];

    NSString *pbxPath = [self.xcodeProjectPath stringByAppendingPathComponent:@"project.pbxproj"];
    
    [self.fm copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"project" ofType:@"pbxproj"] toPath:pbxPath error:nil];

    NSMutableString *content = [NSMutableString stringWithContentsOfFile:pbxPath encoding:NSUTF8StringEncoding error:nil];

    [content writeToFile:pbxPath atomically:YES encoding:NSUTF8StringEncoding error:nil];

    DDLogInfo(@"Xcode support project created at: %@", self.xcodeProjectPath);
}

- (void)createXcodeSupportDirectory
{
    if ([self.fm fileExistsAtPath:self.supportPath])
        [self.fm removeItemAtPath:self.supportPath error:nil];

    [self.fm createDirectoryAtPath:self.supportPath withIntermediateDirectories:YES attributes:nil error:nil];

    NSNumber *appCompatibilityVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:XCCCompatibilityVersionKey];
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:@{ XCCCompatibilityVersionKey:appCompatibilityVersion }
                                                              format:NSPropertyListXMLFormat_v1_0
                                                    errorDescription:nil];
    [data writeToFile:[self.supportPath stringByAppendingPathComponent:@"Info.plist"] atomically:YES];

    DDLogInfo(@".XcodeSupport directory created at: %@", self.supportPath);
}

- (void)populateXcodeProject
{
    // Populate with all non-framework code
    [self populateXcodeProjectWithProjectRelativePath:@""];

    // Populate with any user source debug frameworks
    [self populateXcodeProjectWithProjectRelativePath:@"Frameworks/Debug"];

    // Populate with any source frameworks
    [self populateXcodeProjectWithProjectRelativePath:@"Frameworks/Source"];

    // Populate resources
    [self populateXcodeProjectWithProjectRelativePath:@"Resources"];
}

- (void)populateXcodeProjectWithProjectRelativePath:(NSString *)path
{
    FindSourceFilesOperation *op = [[FindSourceFilesOperation alloc] initWithXCC:self projectId:[NSNumber numberWithInteger:self.projectId] path:path];
    [self.operationQueue addOperation:op];
}

- (IBAction)openXcodeProject:(id)aSender
{
    BOOL isDirectory, opened = YES;
    BOOL exists = [self.fm fileExistsAtPath:self.xcodeProjectPath isDirectory:&isDirectory];

    if (exists && isDirectory)
    {
        DDLogVerbose(@"Opening Xcode project at: %@", self.xcodeProjectPath);

        opened = [[NSWorkspace sharedWorkspace] openFile:self.xcodeProjectPath];
    }

    if (!exists || !isDirectory || !opened)
    {
        NSString *text;

        if (!opened)
            text = @"The project exists, but failed to open.";
        else
            text = [NSString stringWithFormat:@"%@ %@.", self.xcodeProjectPath, !exists ? @"does not exist" : @"is not an Xcode project"];

        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        NSInteger response = NSRunAlertPanel(@"The project could not be opened.", @"%@\n\nWould you like to regenerate the project?", @"Yes", @"No", nil, text);

        if (response == NSAlertDefaultReturn)
            [self synchronizeProject:self];
    }
}

- (void)resetProject
{
    NSString *projectPath = self.projectPath;

    [self stop];
    [self removeSupportFilesAtPath:projectPath];
    [self removeAllCibsAtPath:[projectPath stringByAppendingPathComponent:@"Resources"]];

    self.projectPath = projectPath;
}

- (IBAction)synchronizeProject:(id)aSender
{
    [self resetProject];
    [self loadProjectAtPath:self.projectPath];
}

- (void)removeAllCibsAtPath:(NSString *)path
{
    NSArray *paths = [self.fm contentsOfDirectoryAtPath:path error:nil];

    for (NSString *filePath in paths)
    {
        if ([filePath.pathExtension.lowercaseString isEqualToString:@"cib"])
            [self.fm removeItemAtPath:[path stringByAppendingPathComponent:filePath] error:nil];
    }
}

- (void)removeSupportFilesAtPath:(NSString *)projectPath
{
    [XcodeProjectCloser closeXcodeProjectForProject:projectPath];

    [self.fm removeItemAtPath:self.xcodeProjectPath error:nil];
    [self.fm removeItemAtPath:self.supportPath error:nil];
}

- (void)stop
{
    // Increment the projectId to ensure remaining notifications in the queue for the current project are ignored
    ++self.projectId;

    self.isLoadingProject = NO;
    [self stopEventStream];
    [self.operationQueue cancelAllOperations];

    self.projectPath = nil;
    [self clearErrors:self];
    [self.ignoredPathPredicates removeAllObjects];

    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Processing

- (void)waitForOperationQueueToFinishWithSelector:(SEL)selector
{
    self.isProcessing = YES;

    [[NSNotificationCenter defaultCenter] postNotificationName:XCCBatchDidStartNotification object:self];

    // Poll every half second to see if the queue has finished
    [NSTimer scheduledTimerWithTimeInterval:0.5
                                     target:self
                                   selector:@selector(didQueueTimerFinish:)
                                   userInfo:NSStringFromSelector(selector)
                                    repeats:YES];
}

- (void)didQueueTimerFinish:(NSTimer *)timer
{
    if (self.operationQueue.operationCount == 0)
    {
        SEL selector = NSSelectorFromString(timer.userInfo);

        [timer invalidate];

        // Can't use plain performSelect: here because ARC doesn't know what the return value is
        // because the selector is determined at runtime. So we use performSelectorOnMainThread:
        // which has no return value.
        [self performSelectorOnMainThread:selector withObject:nil waitUntilDone:NO];
    }
}

- (void)batchDidFinish
{
    if (self.pbxOperations.count)
    {
        // See pbxprojModifier.py for info on the arguments
        NSMutableArray *arguments = [[NSMutableArray alloc] initWithObjects:self.pbxModifierScriptPath, @"update", self.projectPath, nil];

        for (NSString *action in self.pbxOperations)
        {
            NSArray *paths = self.pbxOperations[action];

            if (paths.count)
            {
                [arguments addObject:action];
                [arguments addObjectsFromArray:paths];
            }
        }

        // This task takes less than a second to execute, no need to put it a separate thread

        NSDictionary *taskResult = [self runTaskWithLaunchPath:self.executablePaths[@"python"]
                                                     arguments:arguments
                                                    returnType:kTaskReturnTypeStdError];

        NSInteger status = [taskResult[@"status"] intValue];
        NSString *response = taskResult[@"response"];

        DDLogVerbose(@"Updated Xcode project: [%ld, %@]", status, status ? response : @"");
    }

    [self showErrors];

    // If the event stream was temporarily stopped, restart it
    [self startFSEventStream];

    self.isProcessing = NO;

    [[NSNotificationCenter defaultCenter] postNotificationName:XCCBatchDidEndNotification object:self];
}

- (void)projectDidFinishLoading
{
    [self batchDidFinish];

    DDLogVerbose(@"Project finished loading");

    self.isLoadingProject = NO;

    [[NSNotificationCenter defaultCenter] postNotificationName:XCCProjectDidFinishLoadingNotification object:self];
    [[NSUserDefaults standardUserDefaults] setObject:self.projectPath forKey:kDefaultLastOpenedPath];

    [self notifyUserWithTitle:@"Project loaded" message:self.projectPath.lastPathComponent];

    [self startEventStream];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultAutoOpenXcodeProject])
        [self openXcodeProject:self];
}

- (NSDictionary*)createProject:(NSString*)aPath
{
    NSDictionary *taskResult;
    NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"gen", aPath ,@"-t", @"NibApplication", nil];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // This is used when an user wants to replace an existing project
    NSArray *argumentsRemove = [NSArray arrayWithObjects:@"-rf", aPath, nil];
    [self runTaskWithLaunchPath:@"/bin/rm" arguments:argumentsRemove returnType:kTaskReturnTypeAny];

    if ([defaults boolForKey:kDefaultUseSymlinkWhenCreatingProject])
        [arguments addObject:@"-l"];

    taskResult = [self runTaskWithLaunchPath:self.executablePaths[@"capp"]
                                   arguments:arguments
                                  returnType:kTaskReturnTypeStdOut];

    NSInteger status = [taskResult[@"status"] intValue];
    NSString *response = taskResult[@"response"];

    if (!status)
    {
        DDLogVerbose(@"Created Xcode project: [%ld, %@]", status, status ? response : @"");
        [self notifyUserWithTitle:@"Project created" message:aPath.lastPathComponent];
    }
    else
    {
        DDLogVerbose(@"Created Xcode project failed: [%ld, %@]", status, status ? response : @"");
        NSDictionary *dictionary = [NSDictionary dictionaryWithObject:response forKey:@"message"];
        [self.errorListController addObject:dictionary];
        [self showErrors];
    }

    return taskResult;
}

#pragma mark - Notification handlers

/*
     NOTE: All methods in this section which end with "Handler" are called
     from threaded NSOperations.
*/

/*
     Notifications sent by operations contain an int projectId.
    The notifications are queued up on the main thread. When the main thread
     handles them, it first checks to see if the current projectId
     matches the notification's projectId. If not, the notification is ignored.
*/
- (BOOL)notificationBelongsToCurrentProject:(NSNotification *)note
{
    return [note.userInfo[@"projectId"] intValue] == self.projectId;
}

- (void)addSourceToProjectPathMappingHandler:(NSNotification *)note
{
    [self performSelectorOnMainThread:@selector(addSourceToProjectPathMapping:) withObject:note waitUntilDone:NO];
}

- (void)addSourceToProjectPathMapping:(NSNotification *)note
{
    if (![self notificationBelongsToCurrentProject:note])
        return;

    NSDictionary *info = note.userInfo;
    NSString *sourcePath = info[@"sourcePath"];

    DDLogVerbose(@"Adding source to project mapping: %@ -> %@", sourcePath, info[@"projectPath"]);

    self.projectPathsForSourcePaths[info[@"sourcePath"]] = info[@"projectPath"];
}

- (void)sourceConversionDidStartHandler:(NSNotification *)note
{
    [self performSelectorOnMainThread:@selector(sourceConversionDidStart:) withObject:note waitUntilDone:NO];
}

- (void)sourceConversionDidStart:(NSNotification *)note
{
    if (![self notificationBelongsToCurrentProject:note])
        return;

    NSDictionary *info = note.userInfo;
    NSString *projectPath = info[@"path"];
    
    DDLogVerbose(@"%@ %@", NSStringFromSelector(_cmd), projectPath);
    
    [self pruneProcessingErrorsForProjectPath:projectPath];
}

- (void)sourceConversionDidGenerateErrorHandler:(NSNotification *)note
{
    [self performSelectorOnMainThread:@selector(sourceConversionDidGenerateError:) withObject:note waitUntilDone:NO];
}

- (void)sourceConversionDidGenerateError:(NSNotification *)note
{
    if (![self notificationBelongsToCurrentProject:note])
        return;

    NSMutableDictionary *info = [note.userInfo mutableCopy];

    DDLogVerbose(@"%@ %@", NSStringFromSelector(_cmd), info[@"path"]);

    [self.errorListController addObject:info];
}

- (void)sourceConversionDidEndHandler:(NSNotification *)note
{
    [self performSelectorOnMainThread:@selector(sourceConversionDidEnd:) withObject:note waitUntilDone:NO];
}

- (void)sourceConversionDidEnd:(NSNotification *)note
{
    if (![self notificationBelongsToCurrentProject:note])
        return;

    NSString *path = note.userInfo[@"path"];

    if ([self isObjjFile:path])
    {
        NSMutableArray *addPaths = [self.pbxOperations[@"add"] mutableCopy];

        if (!addPaths)
            self.pbxOperations[@"add"] = @[path];
        else
        {
            [addPaths addObject:path];
            self.pbxOperations[@"add"] = addPaths;
        }
    }
    
    DDLogVerbose(@"%@ %@", NSStringFromSelector(_cmd), path);
}

#pragma mark - Event Stream

- (void)startEventStream
{
    if (self.stream)
        return;

    [self stopEventStream];

    FSEventStreamCreateFlags flags = kFSEventStreamCreateFlagUseCFTypes |
                                     kFSEventStreamCreateFlagWatchRoot  |
                                     kFSEventStreamCreateFlagIgnoreSelf |
                                     kFSEventStreamCreateFlagNoDefer;

    if (self.supportsFileLevelAPI)
        flags |= kFSEventStreamCreateFlagFileEvents;

    // Get a file descriptor to the project directory so we can locate it if it moves
    self.projectPathFileDescriptor = open(self.projectPath.UTF8String, O_EVTONLY);

    NSArray *pathsToWatch = [self getPathsToWatch];
    
    void *appPointer = (__bridge void *)self;
    FSEventStreamContext context = { 0, appPointer, NULL, NULL, NULL };
    CFTimeInterval latency = 2.0;
    UInt64 lastEventId = self.lastEventId.unsignedLongLongValue;

    self.stream = FSEventStreamCreate(NULL,
                                      &fsevents_callback,
                                      &context,
                                      (__bridge CFArrayRef) pathsToWatch,
                                      lastEventId,
                                      latency,
                                      flags);

    FSEventStreamScheduleWithRunLoop(self.stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    [self startFSEventStream];

    DDLogVerbose(@"FSEventStream started for paths: %@", pathsToWatch);
}

- (void)startFSEventStream
{
    if (self.stream && !self.streamStarted)
    {
        FSEventStreamStart(self.stream);
        self.streamStarted = YES;
    }
}

- (NSArray *)getPathsToWatch
{
    NSMutableArray *pathsToWatch = [NSMutableArray arrayWithObject:self.projectPath];
    NSArray *otherPathsToWatch = @[@"", @"Frameworks/Debug", @"Frameworks/Source"];

    for (NSString *path in otherPathsToWatch)
    {
        NSString *fullPath = [self.projectPath stringByAppendingPathComponent:path];

        BOOL exists, isDirectory;
        exists = [self.fm fileExistsAtPath:fullPath isDirectory:&isDirectory];

        if (exists && isDirectory)
            [self watchSymlinkedDirectoriesAtPath:path pathsToWatch:pathsToWatch];
    }

    return [pathsToWatch copy];
}

- (void)watchSymlinkedDirectoriesAtPath:(NSString *)projectPath pathsToWatch:(NSMutableArray *)pathsToWatch
{
    NSString *fullProjectPath = [self.projectPath stringByAppendingPathComponent:projectPath];
    NSError *error = NULL;

    NSArray *urls = [self.fm contentsOfDirectoryAtURL:[NSURL fileURLWithPath:fullProjectPath]
                           includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLIsSymbolicLinkKey]
                                              options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                 error:&error];

    for (NSURL *url in urls)
    {
        NSNumber *isSymlink;
        [url getResourceValue:&isSymlink forKey:NSURLIsSymbolicLinkKey error:nil];

        if (isSymlink.boolValue == NO)
            continue;
        
        NSURL *resolvedURL = [url URLByResolvingSymlinksInPath];

        if (![resolvedURL checkResourceIsReachableAndReturnError:nil])
            continue;
        
        NSNumber *isDirectory;
        [resolvedURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];

        if (isDirectory.boolValue == NO)
            continue;
        
        NSString *path = resolvedURL.path;
        NSString *filename = path.lastPathComponent;

        if (![self shouldIgnoreDirectoryNamed:filename] && ![self pathMatchesIgnoredPaths:path])
        {
            DDLogVerbose(@"Watching symlinked directory: %@", path);

            [pathsToWatch addObject:path];
        }
    }
}

- (void)stopEventStream
{
    if (self.stream)
    {
        [self updateUserDefaultsWithLastEventId];

        [self stopFSEventStream];
        FSEventStreamUnscheduleFromRunLoop(self.stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        FSEventStreamInvalidate(self.stream);
        FSEventStreamRelease(self.stream);
        self.stream = NULL;
    }

    if (self.projectPathFileDescriptor >= 0)
    {
        close(self.projectPathFileDescriptor);
        self.projectPathFileDescriptor = -1;
    }
}

- (void)stopFSEventStream
{
    if (self.stream && self.streamStarted)
    {
        FSEventStreamStop(self.stream);
        self.streamStarted = NO;
    }
}

- (void)configureFileAPI
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (!self.supportsFileLevelAPI)
    {
        DDLogInfo(@"System doesn't support file level API, user folder level API");

        [defaults setObject:[NSNumber numberWithInt:kXCCAPIModeFolder] forKey:kDefaultXCCAPIMode];
    }

    switch ([defaults integerForKey:kDefaultXCCAPIMode])
    {
        case kXCCAPIModeAuto:
            self.isUsingFileLevelAPI = self.supportsFileLevelAPI;
            break;
            
        case kXCCAPIModeFolder:
            self.isUsingFileLevelAPI = NO;
            break;
    }

    self.reactToInodeModification = self.isUsingFileLevelAPI ? [defaults boolForKey:kDefaultXCCReactToInodeMod] : NO;
}

- (void)updateUserDefaultsWithLastEventId
{
    UInt64 lastEventId = FSEventStreamGetLatestEventId(self.stream);

    // Just in case the stream callback was never called...
    if (lastEventId != 0)
        self.lastEventId = [NSNumber numberWithUnsignedLongLong:lastEventId];
        
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.lastEventId forKey:kDefaultLastEventId];
    [defaults synchronize];
}

- (NSString *)dumpFSEventFlags:(FSEventStreamEventFlags)flags
{
    BOOL created = (flags & kFSEventStreamEventFlagItemCreated) != 0;
    BOOL removed = (flags & kFSEventStreamEventFlagItemRemoved) != 0;
    BOOL inodeMetaModified = (flags & kFSEventStreamEventFlagItemInodeMetaMod) != 0;
    BOOL renamed = (flags & kFSEventStreamEventFlagItemRenamed) != 0;
    BOOL modified = (flags & kFSEventStreamEventFlagItemModified) != 0;
    BOOL finderInfoModified = (flags & kFSEventStreamEventFlagItemFinderInfoMod) != 0;
    BOOL changedOwner = (flags & kFSEventStreamEventFlagItemChangeOwner) != 0;
    BOOL xattrModified = (flags & kFSEventStreamEventFlagItemXattrMod) != 0;
    BOOL isFile = (flags & kFSEventStreamEventFlagItemIsFile) != 0;
    BOOL isDir = (flags & kFSEventStreamEventFlagItemIsDir) != 0;
    BOOL isSymlink = (flags & kFSEventStreamEventFlagItemIsSymlink) != 0;

    NSMutableArray *flagNames = [NSMutableArray new];

    if (created)
        [flagNames addObject:@"created"];

    if (removed)
        [flagNames addObject:@"removed"];

    if (inodeMetaModified)
        [flagNames addObject:@"inode"];

    if (renamed)
        [flagNames addObject:@"renamed"];

    if (modified)
        [flagNames addObject:@"modified"];

    if (finderInfoModified)
        [flagNames addObject:@"Finder info"];

    if (changedOwner)
        [flagNames addObject:@"owner"];

    if (xattrModified)
        [flagNames addObject:@"xattr"];

    if (isFile)
        [flagNames addObject:@"file"];

    if (isDir)
        [flagNames addObject:@"dir"];

    if (isSymlink)
        [flagNames addObject:@"symlink"];

    return [flagNames componentsJoinedByString:@", "];
}

#pragma mark - Event Handlers

- (void)handleFSEventsWithPaths:(NSArray *)paths flags:(const FSEventStreamEventFlags[])eventFlags ids:(const FSEventStreamEventId[])eventIds
{
    DDLogVerbose(@"FSEvents: %ld path(s)", paths.count);

    [self.pbxOperations removeAllObjects];

    NSMutableArray *modifiedPaths = [NSMutableArray new];
    NSMutableArray *renamedDirectories = [NSMutableArray new];
    
    BOOL needUpdate = NO;

    for (size_t i = 0; i < paths.count; ++i)
    {
        FSEventStreamEventFlags flags = eventFlags[i];
        NSString *path = [paths[i] stringByStandardizingPath];

        BOOL rootChanged = (flags & kFSEventStreamEventFlagRootChanged) != 0;

        if (rootChanged)
        {
            DDLogVerbose(@"Watched path changed: %@", path);

            [self resetProjectForWatchedPath:path];
            return;
        }

        BOOL isHistoryDoneSentinalEvent = (flags & kFSEventStreamEventFlagHistoryDone) != 0;

        if (isHistoryDoneSentinalEvent)
        {
            DDLogVerbose(@"History done sentinal event");
            continue;
        }

        BOOL isMountEvent = (flags & kFSEventStreamEventFlagMount) || (flags & kFSEventStreamEventFlagUnmount);

        if (isMountEvent)
        {
            DDLogVerbose(@"Volume %@: %@", (flags & kFSEventStreamEventFlagMount) ? @"mounted" : @"unmounted", path);
            continue;
        }

        BOOL needRescan = (flags & kFSEventStreamEventFlagMustScanSubDirs) != 0;

        if (needRescan)
        {
            // A rescan requires a reset
            [self resetProjectForWatchedPath:path];

            return;
        }

        if (self.isUsingFileLevelAPI)
        {
            // BOOL finderInfoModified = (flags & kFSEventStreamEventFlagItemFinderInfoMod) != 0;
            // BOOL changedOwner = (flags & kFSEventStreamEventFlagItemChangeOwner) != 0;
            // BOOL xattrModified = (flags & kFSEventStreamEventFlagItemXattrMod) != 0;
            // BOOL isSymlink = (flags & kFSEventStreamEventFlagItemIsSymlink) != 0;
            BOOL inodeMetaModified = (flags & kFSEventStreamEventFlagItemInodeMetaMod) != 0;
            BOOL isFile = (flags & kFSEventStreamEventFlagItemIsFile) != 0;
            BOOL isDir = (flags & kFSEventStreamEventFlagItemIsDir) != 0;
            BOOL renamed = (flags & kFSEventStreamEventFlagItemRenamed) != 0;
            BOOL modified = (flags & kFSEventStreamEventFlagItemModified) != 0;
            BOOL created = (flags & kFSEventStreamEventFlagItemCreated) != 0;
            BOOL removed = (flags & kFSEventStreamEventFlagItemRemoved) != 0;

            DDLogVerbose(@"FSEvent: %@ (%@)", path, [self dumpFSEventFlags:flags]);

            if (isDir)
            {
                /*
                    When a project is opened for the first time after it is created,
                    we get an event where the first path is a create for the root directory.
                    In that case all of the paths have been processed, and we ignore the event.
                */
                if (created && [path isEqualToString:self.projectPath.stringByResolvingSymlinksInPath])
                    return;
                
                if (renamed &&
                    !(created || removed) &&
                    ![self shouldIgnoreDirectoryNamed:path.lastPathComponent] &&
                    ![self pathMatchesIgnoredPaths:path])
                {
                    DDLogVerbose(@"Renamed directory: %@", path);
                    
                    [renamedDirectories addObject:path];
                }

                continue;
            }
            else if (isFile &&
                     (created || modified || renamed || removed || (self.reactToInodeModification && inodeMetaModified)) &&
                     [self isSourceFile:path])
            {
                DDLogVerbose(@"FSEvent accepted");

                if ([self.fm fileExistsAtPath:path])
                    [modifiedPaths addObject:path];
                else if ([path.pathExtension isEqualToString:@"xib"])
                {
                    // If a xib is deleted, delete its cib. There is no need to update when a xib is deleted,
                    // it is inside a folder in Xcode, which updates automatically.

                    if (![self.fm fileExistsAtPath:path])
                    {
                        NSString *cibPath = [path.stringByDeletingPathExtension stringByAppendingPathExtension:@"cib"];

                        if ([self.fm fileExistsAtPath:cibPath])
                            [self.fm removeItemAtPath:cibPath error:nil];

                        continue;
                    }
                }

                needUpdate = YES;
            }
            else if (isFile && (renamed || removed) && !(modified || created) && [path.pathExtension isEqualToString:@"cib"])
            {
                // If a cib is deleted, mark its xib as needing update so the cib is regenerated
                NSString *xibPath = [path.stringByDeletingPathExtension stringByAppendingPathExtension:@"xib"];

                if ([self.fm fileExistsAtPath:xibPath])
                {
                    [modifiedPaths addObject:xibPath];
                    needUpdate = YES;
                }
            }
        }
        else  // directory-based listening
        {
            // We should drop support for Snow Leopard soon.

            BOOL isDirectory = NO;
            [self.fm fileExistsAtPath:path isDirectory:&isDirectory];

            // If for some reason the path is not a directory,
            // we don't want to deal with it in this mode.
            if (!isDirectory)
                continue;

            NSFileManager *fm = [NSFileManager defaultManager];
            NSArray *subpaths = [fm contentsOfDirectoryAtPath:path error:NULL];

            for (NSString *subpath in subpaths)
            {
                NSString *fullPath = [path stringByAppendingPathComponent:subpath];

                if (![self isSourceFile:fullPath])
                    continue;

                NSDate *lastModifiedDate = [self lastModificationDateForPath:fullPath];
                NSDictionary *fileAttributes = [fm attributesOfItemAtPath:fullPath error:nil];
                NSDate *fileModDate = [fileAttributes objectForKey:NSFileModificationDate];

                if ([fileModDate compare:lastModifiedDate] == NSOrderedDescending)
                {
                    [self updateLastModificationDate:fileModDate forPath:fullPath];
                    [modifiedPaths addObject:fullPath];
                    needUpdate = YES;
                }
            }
        }
    }

    // If directories were renamed, we take the easy way out and reset the project
    if (renamedDirectories.count)
        [self handleRenamedDirectories:renamedDirectories];
    else if (needUpdate)
        [self updateSupportFilesWithModifiedPaths:modifiedPaths];
}

- (void)handleRenamedDirectories:(NSArray *)directories
{
    // Make sure we don't get any more events while handling these events
    [self stopFSEventStream];

    DDLogVerbose(@"Renamed directories: %@", directories);
    
    [self tidyShadowedFiles];

    for (NSString *directory in directories)
    {
        // If it doesn't exist, it's the old name. Nothing to do.
        // If it does exist, populate the project with the directory.
        
        if ([self.fm fileExistsAtPath:directory])
        {
            // If the directory is within the project, we can populate it directly.
            // Otherwise we have to start at the top level and repopulate everything.
            if ([directory hasPrefix:self.projectPath])
                [self populateXcodeProjectWithProjectRelativePath:[self projectRelativePathForPath:directory]];
            else
            {
                [self populateXcodeProject];

                // Since everything has been repopulated, no point in continuing
                break;
            }
        }
    }

    [self waitForOperationQueueToFinishWithSelector:@selector(batchDidFinish)];
}

- (void)updateSupportFilesWithModifiedPaths:(NSArray *)modifiedPaths
{
    // Make sure we don't get any more events while handling these events
    [self stopFSEventStream];

    NSArray *removedFiles = [self tidyShadowedFiles];

    if (removedFiles.count || modifiedPaths.count)
    {
        for (NSString *path in modifiedPaths)
            [self handleFileModificationAtPath:path];

        [self waitForOperationQueueToFinishWithSelector:@selector(batchDidFinish)];
    }
}

- (void)resetProjectForWatchedPath:(NSString *)path
{
    // If a watched path changes we don't have much choice but to reset the project.
    [self stopFSEventStream];
    
    if ([path isEqualToString:self.projectPath])
    {
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        NSInteger response = NSRunAlertPanel(@"The project moved.", @"Your project directory has moved. Would you like to reload the project or quit XcodeCapp?", @"Reload", @"Quit", nil);

        BOOL shouldQuit = YES;

        if (response == NSAlertDefaultReturn)
        {
            char newPathBuf[MAXPATHLEN + 1];

            int result = fcntl(self.projectPathFileDescriptor, F_GETPATH, newPathBuf);

            if (result == 0)
            {
                self.projectPath = [NSString stringWithUTF8String:newPathBuf];
                shouldQuit = NO;
            }
            else
                NSRunAlertPanel(@"The project can’t be located.", @"I’m sorry Dave, but I don’t know where the project went. I’m afraid I have to quit now.", @"OK, HAL", nil, nil);
        }

        if (shouldQuit)
        {
            [[NSApplication sharedApplication] terminate:self];
            return;
        }
    }
    
    [self synchronizeProject:self];
}

/*!
    Handle a file modification. If it's a .j or xib/nib,
    perform the appropriate conversion. If it's .xcodecapp-ignore, it will
    update the list of ignored files.

     @param path The full resolved path of the modified file
*/
- (void)handleFileModificationAtPath:(NSString*)resolvedPath
{
    if (![self.fm fileExistsAtPath:resolvedPath])
        return;

    NSString *projectPath = [self projectPathForSourcePath:resolvedPath];

    ProcessSourceOperation *op = [[ProcessSourceOperation alloc] initWithXCC:self
                                                                   projectId:[NSNumber numberWithInteger:self.projectId]
                                                                  sourcePath:projectPath];
    [self.operationQueue addOperation:op];
}

#pragma mark - Shell Helpers

/*!
 Run an NSTask with the given arguments
 
 @param launchPath The executable to launch
 @param arguments NSArray containing the NSTask arguments
 @param returnType Determines whether to return stdout, stderr, either, or nothing in the response
 @return NSDictionary containing the return status (NSNumber) and the response (NSString)
 */
- (NSDictionary *)runTaskWithLaunchPath:(NSString *)launchPath arguments:(NSArray *)arguments returnType:(XCCTaskReturnType)returnType
{
    return [self runTaskWithLaunchPath:launchPath arguments:arguments returnType:returnType currentDirectoryPath:nil];
}

/*!
    Run an NSTask with the given arguments
 
     @param launchPath The executable to launch
     @param arguments NSArray containing the NSTask arguments
     @param returnType Determines whether to return stdout, stderr, either, or nothing in the response
     @param the currentDirectoryPath for the task
     @return NSDictionary containing the return status (NSNumber) and the response (NSString)
 */
- (NSDictionary *)runTaskWithLaunchPath:(NSString *)launchPath arguments:(NSArray *)arguments returnType:(XCCTaskReturnType)returnType currentDirectoryPath:(NSString*)aCurrentDirectoryPath
{
    NSTask *task = [NSTask new];
    
    task.launchPath = launchPath;
    task.arguments = arguments;
    task.environment = self.environment;
    task.standardOutput = [NSPipe pipe];
    task.standardError = [NSPipe pipe];
    
    if (aCurrentDirectoryPath)
        task.currentDirectoryPath = aCurrentDirectoryPath;
    
    [task launch];

    DDLogVerbose(@"Task launched: %@\n%@", launchPath, arguments);

    if (returnType != kTaskReturnTypeNone)
    {
        [task waitUntilExit];

        DDLogVerbose(@"Task exited: %@:%d", launchPath, task.terminationStatus);

        NSData *data = nil;

        if (returnType == kTaskReturnTypeStdOut || returnType == kTaskReturnTypeAny)
            data = [[task.standardOutput fileHandleForReading] availableData];

        if (returnType == kTaskReturnTypeStdError || (returnType == kTaskReturnTypeAny && [data length] == 0))
            data = [[task.standardError fileHandleForReading] availableData];
        
        NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSNumber *status = [NSNumber numberWithInt:task.terminationStatus];

        return @{ @"status":status, @"response":response };
    }
    else
    {
        return @{ @"status":@0, @"response":@"" };
    }
}

- (BOOL)executablesAreAccessible
{
    for (NSString *executable in self.executables)
    {
        NSDictionary *response = [self runTaskWithLaunchPath:@"/usr/bin/which"
                                                   arguments:@[executable]
                                                  returnType:kTaskReturnTypeStdOut];

        NSString *path = [response[@"response"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        if (path.length)
            self.executablePaths[executable] = path;
        else
        {
            DDLogError(@"Could not find executable '%@' in PATH: %@", executable, self.environment[@"PATH"]);
            return NO;
        }
    }

    DDLogVerbose(@"Executable paths: %@", self.executablePaths);

    return YES;
}


#pragma mark - Source Files Management

- (BOOL)isObjjFile:(NSString *)path
{
    return [path.pathExtension.lowercaseString isEqual:@"j"];
}

- (BOOL)isXibFile:(NSString *)path
{
    NSString *extension = path.pathExtension.lowercaseString;

    if ([extension isEqual:@"xib"] || [extension isEqual:@"nib"])
    {
        // Xcode creates temp files called <filename>~.xib. Filter those out.
        NSString *baseFilename = path.lastPathComponent.stringByDeletingPathExtension;

        return [baseFilename characterAtIndex:baseFilename.length - 1] != '~';
    }

    return NO;
}

- (BOOL)isXCCIgnoreFile:(NSString *)path
{
    return [path isEqualToString:self.xcodecappIgnorePath];
}

- (BOOL)isSourceFile:(NSString *)path
{
    return ([self isXibFile:path] || [self isObjjFile:path] || [self isXCCIgnoreFile:path]) && ![self pathMatchesIgnoredPaths:path];
}

- (NSString *)projectPathForSourcePath:(NSString *)path
{
    NSString *base = path.stringByDeletingLastPathComponent;
    NSString *projectPath = self.projectPathsForSourcePaths[base];

    return projectPath ? [projectPath stringByAppendingPathComponent:path.lastPathComponent] : path;
}

- (NSString *)projectRelativePathForPath:(NSString *)path
{
    return [path substringFromIndex:self.projectPath.length + 1];
}


#pragma mark - Shadow Files Management

- (NSString *)shadowBasePathForProjectSourcePath:(NSString *)path
{
    if (path.isAbsolutePath)
        path = [self projectRelativePathForPath:path];
    
    NSString *filename = [path.stringByDeletingPathExtension stringByReplacingOccurrencesOfString:@"/" withString:XCCSlashReplacement];

    return [self.supportPath stringByAppendingPathComponent:filename];
}

- (NSString *)sourcePathForShadowPath:(NSString *)path
{
    NSString *filename = [path stringByReplacingOccurrencesOfString:XCCSlashReplacement withString:@"/"];
    filename = [filename.stringByDeletingPathExtension stringByAppendingPathExtension:@"j"];

    return [self.projectPath stringByAppendingPathComponent:filename];
}

/*!
     Clean up any shadow files and PBX entries related to given the Cappuccino source file path
*/
- (void)removeReferencesToSourcePaths:(NSArray *)sourcePaths
{
    BOOL updateLastModDate = !self.supportsFileLevelAPI && [self respondsToSelector:@selector(updateLastModificationDate:forPath:)];
    
    for (NSString *sourcePath in sourcePaths)
    {
        if (updateLastModDate)
            [self updateLastModificationDate:nil forPath:sourcePath];

        NSString *shadowBasePath = [self shadowBasePathForProjectSourcePath:sourcePath];
        NSString *shadowHeaderPath = [shadowBasePath stringByAppendingPathExtension:@"h"];
        NSString *shadowImplementationPath = [shadowBasePath stringByAppendingPathExtension:@"m"];

        [self.fm removeItemAtPath:shadowHeaderPath error:nil];
        [self.fm removeItemAtPath:shadowImplementationPath error:nil];

        [self pruneProcessingErrorsForProjectPath:sourcePath];
    }

    if (sourcePaths.count)
        DDLogVerbose(@"Removed shadow references to: %@", sourcePaths);
}

- (NSArray *)tidyShadowedFiles
{
    NSArray *subpaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.supportPath error:nil];
    NSMutableArray *pathsToRemove = [NSMutableArray new];

    for (NSString *path in subpaths)
    {
        NSString *extension = path.pathExtension;
        
        if ([extension isEqualToString:@"h"] && ![path.lastPathComponent isEqualToString:@"xcc_general_include.h"])
        {
            NSString *sourcePath = [self sourcePathForShadowPath:path];

            if (![self.fm fileExistsAtPath:sourcePath])
                [pathsToRemove addObject:sourcePath];
        }
    }

    [self removeReferencesToSourcePaths:pathsToRemove];
    
    if (pathsToRemove.count)
        self.pbxOperations[@"remove"] = pathsToRemove;

    return pathsToRemove;
}

#pragma mark - XCC Ignore management

+ (NSString *)globToRegexPattern:(NSString *)glob
{
    NSMutableString *regex = [glob mutableCopy];

    if ([regex characterAtIndex:0] == '!')
        [regex deleteCharactersInRange:NSMakeRange(0, 1)];

    [regex replaceOccurrencesOfString:@"."
                           withString:@"\\."
                              options:0
                                range:NSMakeRange(0, [regex length])];

    [regex replaceOccurrencesOfString:@"*"
                           withString:@".*"
                              options:0
                                range:NSMakeRange(0, [regex length])];

    // If the glob ends with "/", match that directory and anything below it.
    if ([regex characterAtIndex:regex.length - 1] == '/')
        [regex replaceCharactersInRange:NSMakeRange(regex.length - 1, 1) withString:@"(?:/.*)?"];

    return [NSString stringWithFormat:@"^%@$", regex];
}

+ (NSArray *)parseIgnorePaths:(NSArray *)paths
{
    NSMutableArray *parsedPaths = [NSMutableArray array];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];

    for (NSString *pattern in paths)
    {
        if ([pattern stringByTrimmingCharactersInSet:whitespace].length == 0)
            continue;

        NSString *regexPattern = [self globToRegexPattern:pattern];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", regexPattern];
        [parsedPaths addObject:@{ @"predicate": predicate, @"exclude": @([pattern characterAtIndex:0] != '!') }];
    }
    
    return parsedPaths;
}

/*!
    Compute the ignored paths according to any existing .xcodecapp-ignore file
*/
- (void)computeIgnoredPaths
{
    self.ignoredPathPredicates = [XCCDefaultIgnoredPathPredicates mutableCopy];
    NSString *ignorePath = [self.projectPath stringByAppendingPathComponent:@".xcodecapp-ignore"];

    if ([self.fm fileExistsAtPath:ignorePath])
    {
        NSString *ignoreFileContent = [NSString stringWithContentsOfFile:ignorePath encoding:NSUTF8StringEncoding error:nil];
        NSArray *ignoredPatterns = [ignoreFileContent componentsSeparatedByString:@"\n"];
        NSArray *parsedPaths = [[self class] parseIgnorePaths:ignoredPatterns];
        [self.ignoredPathPredicates addObjectsFromArray:parsedPaths];
    }

    DDLogVerbose(@"Ignoring file paths: %@", self.ignoredPathPredicates);
}

- (BOOL)pathMatchesIgnoredPaths:(NSString*)aPath
{
    BOOL ignore = NO;

    for (NSDictionary *ignoreInfo in self.ignoredPathPredicates)
    {
        BOOL matches = [ignoreInfo[@"predicate"] evaluateWithObject:aPath];

        if (matches)
            ignore = [ignoreInfo[@"exclude"] boolValue];
    }

    return ignore;
}

- (BOOL)shouldIgnoreDirectoryNamed:(NSString *)filename
{
    return [XCCDirectoriesToIgnorePredicate evaluateWithObject:filename];
}

#pragma mark - Errors

- (IBAction)openErrorsPanel:(id)aSender
{
    [self.errorsPanel setFloatingPanel:[[NSUserDefaults standardUserDefaults] boolForKey:kDefaultXCCPanelStyleUtility]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultXCCPanelActiveAppWhenOpening])
    {
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        [self.errorsPanel makeKeyAndOrderFront:nil];
    }
    else
    {
        [self.errorsPanel orderFrontRegardless];
    }
}

- (IBAction)openErrorInEditor:(id)sender
{
    id info = self.errorListController.selection;

    NSString *path = [info valueForKey:@"realPath"] ? [info valueForKey:@"realPath"] : [info valueForKey:@"path"];
    
    if (path == NSNoSelectionMarker)
        return;
    
    if ([self isObjjFile:path])
    {
        [self openObjjFile:path line:[[info valueForKey:@"line"] intValue]];
    }
    else // xib
    {
        [[NSWorkspace sharedWorkspace] openFile:path];
    }
}

- (void)openObjjFile:(NSString *)path line:(NSInteger)line
{
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];

    NSString *app, *type;
    BOOL success = [workspace getInfoForFile:path application:&app type:&type];

    if (!success)
    {
        NSBeep();
        return;
    }

    NSBundle *bundle = [NSBundle bundleWithPath:app];
    NSString *identifier = bundle.bundleIdentifier;
    NSString *executablePath = nil;
    XCCLineSpecifier lineSpecifier = kLineSpecifierNone;

    if ([identifier hasPrefix:@"com.sublimetext."])
    {
        lineSpecifier = kLineSpecifierColon;
        executablePath = [[bundle sharedSupportPath] stringByAppendingPathComponent:@"bin/subl"];
    }
    else if ([identifier isEqualToString:@"com.barebones.textwrangler"])
    {
        lineSpecifier = kLineSpecifierColon;
        executablePath = [[bundle bundlePath] stringByAppendingPathComponent:@"Contents/Helpers/edit"];
    }
    else if ([identifier isEqualToString:@"com.barebones.bbedit"])
    {
        lineSpecifier = kLineSpecifierColon;
        executablePath = [[bundle bundlePath] stringByAppendingPathComponent:@"Contents/Helpers/bbedit"];
    }
    else if ([identifier isEqualToString:@"com.macromates.textmate"])  // TextMate 1.x
    {
        lineSpecifier = kLineSpecifierMinusL;
        executablePath = [[bundle sharedSupportPath] stringByAppendingPathComponent:@"Support/bin/mate"];
    }
    else if ([identifier hasPrefix:@"com.macromates.TextMate"])  // TextMate 2.x
    {
        lineSpecifier = kLineSpecifierMinusL;
        executablePath = [bundle pathForResource:@"mate" ofType:@""];
    }
    else if ([identifier isEqualToString:@"com.chocolatapp.Chocolat"])
    {
        lineSpecifier = kLineSpecifierMinusL;
        executablePath = [[bundle sharedSupportPath] stringByAppendingPathComponent:@"choc"];
    }
    else if ([identifier isEqualToString:@"org.vim.MacVim"])
    {
        lineSpecifier = kLineSpecifierPlus;
        executablePath = @"/usr/local/bin/mvim";
    }
    else if ([identifier isEqualToString:@"org.gnu.Aquamacs"])
    {
        if ([self.fm isExecutableFileAtPath:@"/usr/bin/aquamacs"])
            executablePath = @"/usr/bin/aquamacs";
        else if ([self.fm isExecutableFileAtPath:@"/usr/local/bin/aquamacs"])
            executablePath = @"/usr/local/bin/aquamacs";
    }
    else if ([identifier isEqualToString:@"com.apple.dt.Xcode"])
    {
        executablePath = [[bundle bundlePath] stringByAppendingPathComponent:@"Contents/Developer/usr/bin/xed"];
    }

    if (!executablePath || ![self.fm isExecutableFileAtPath:executablePath])
    {
        [workspace openFile:path];
        return;
    }
    
    NSArray *args;

    switch (lineSpecifier)
    {
        case kLineSpecifierNone:
            args = @[path];
            break;

        case kLineSpecifierColon:
            args = @[[NSString stringWithFormat:@"%1$@:%2$ld", path, line]];
            break;

        case kLineSpecifierMinusL:
            args = @[@"-l", [NSString stringWithFormat:@"%ld", line], path];
            break;

        case kLineSpecifierPlus:
            args = @[[NSString stringWithFormat:@"+%ld", line], path];
            break;
    }

    [self runTaskWithLaunchPath:executablePath arguments:args returnType:kTaskReturnTypeNone];
}

- (BOOL)shouldShowErrorNotification
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDefaultXCCAutoShowNotificationOnErrors];
}

- (BOOL)shouldProcessWithCappLint
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    return [defaults boolForKey:kDefaultXCCAutoOpenErrorsPanelOnCappLint]
            || [defaults boolForKey:kDefaultXCCAutoShowNotificationOnCappLint];
}

- (BOOL)shouldProcessWithObjjWarnings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    return ([defaults boolForKey:kDefaultXCCAutoOpenErrorsPanelOnErrors] || [defaults boolForKey:kDefaultXCCAutoShowNotificationOnErrors]) && [defaults boolForKey:kDefaultXCCShouldProcessObjj];
}

- (void)showErrors
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults boolForKey:kDefaultXCCAutoOpenErrorsPanelOnErrors] && self.errorList.count)
    {
        [self openErrorsPanel:self];
    }
}

- (void)showCappLintWarnings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSUInteger numberError = [self.errorList count];
    NSDictionary *firstError;
    NSUInteger i = 0;
    
    for (i = 0; i < numberError; i++)
    {
        NSDictionary *dict = [self.errorList objectAtIndex:i];
        
        if ([[dict valueForKey:@"type"] isEqualToString: @"capp_lint"])
        {
            firstError = dict;
            break;
        }
    }
    
    if ([defaults boolForKey:kDefaultXCCAutoOpenErrorsPanelOnCappLint] && firstError)
        [self openErrorsPanel:self];

    if ([defaults boolForKey:kDefaultXCCAutoShowNotificationOnCappLint] && firstError)
    {
        NSDictionary *error = [self.errorList objectAtIndex:0];
        NSString *filename = [error objectForKey:@"path"];
            
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInteger:self.projectId] , @"projectId",
                                    @"Code Style Issues", @"title",
                                    filename.lastPathComponent , @"message",
                                    nil];
            
        [self wantUserNotificationWithInfo:dict];
    }
}

- (void)showObjjWarnings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSUInteger numberError = [self.errorList count];
    NSDictionary *firstError;
    NSUInteger i = 0;
    
    for (i = 0; i < numberError; i++)
    {
        NSDictionary *dict = [self.errorList objectAtIndex:i];
        
        if ([[dict valueForKey:@"type"] isEqualToString: @"objj"])
        {
            firstError = dict;
            break;
        }
    }
    
    if ([defaults boolForKey:kDefaultXCCAutoOpenErrorsPanelOnErrors] && firstError)
        [self openErrorsPanel:self];
    
    if ([defaults boolForKey:kDefaultXCCAutoShowNotificationOnErrors] && firstError)
    {
        NSDictionary *error = [self.errorList objectAtIndex:0];
        NSString *filename = [error objectForKey:@"path"];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInteger:self.projectId] , @"projectId",
                                     @"Compiling Issues", @"title",
                                     filename.lastPathComponent , @"message",
                                     nil];
        
        [self wantUserNotificationWithInfo:dict];
    }
}

- (void)pruneProcessingErrorsForProjectPath:(NSString *)path
{
    [self pruneProcessingErrorsForProjectPath:path type:nil];
}

- (void)pruneProcessingErrorsForProjectPath:(NSString *)path type:(NSString*)type
{
    // Remove all errors for the path being processed
    NSIndexSet *matchingErrors = [self.errorList indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
                                  {
                                      if (type)
                                          return ([[obj valueForKey:@"path"] isEqualToString:path] || [[obj valueForKey:@"realPath"] isEqualToString:path]) && [[obj valueForKey:@"type"] isEqualToString:type];
                                      else
                                          return [[obj valueForKey:@"path"] isEqualToString:path] || [[obj valueForKey:@"realPath"] isEqualToString:path];
                                  }];
    
    [self.errorListController removeObjectsAtArrangedObjectIndexes:matchingErrors];
}

- (IBAction)clearErrors:(id)sender
{
    [self.errorList removeAllObjects];
    self.errorListController.content = self.errorList;
}

- (BOOL)hasErrors
{
    NSInteger index = [self.errorList indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
    {
        return [[obj valueForKey:@"status"] intValue] == XCCStatusCodeError;
    }];

    return index != NSNotFound;
}

#pragma mark - objjj check

- (NSString*)_getObjjIncludePaths
{
    NSRegularExpression *regulareExpressionFramework = [NSRegularExpression regularExpressionWithPattern:@"OBJJ_INCLUDE_PATHS ?= ?\\[\"(.*)\"\\," options:0 error:nil];

    NSString *indexPath;    
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultXCCUseDebugFrameworkWithObjj])
        indexPath = [NSString stringWithFormat:@"%@/index-debug.html", self.projectPath];
    else
        indexPath = [NSString stringWithFormat:@"%@/index.html", self.projectPath];
    
    NSDictionary *taskResult = [self runTaskWithLaunchPath:@"/bin/cat" arguments:[NSMutableArray arrayWithObject:indexPath] returnType:kTaskReturnTypeAny];
    
    NSString *response = taskResult[@"response"];
    
    NSArray *matches = [regulareExpressionFramework matchesInString:response options:0 range:NSMakeRange(0, [response length])];
    
    for (NSTextCheckingResult *match in matches)
        return [NSString stringWithFormat:@"%@/%@", self.projectPath, [response substringWithRange:[match rangeAtIndex:1]]];
    
    return [NSString stringWithFormat:@"%@/%@", self.projectPath ,@"Frameworks/"];
}

- (BOOL)checkObjjWarningsForPath:(NSArray*)paths
{
    DDLogVerbose(@"Checking path %@ with objj", paths);
    
    NSUInteger numberOfFiles = [paths count];
    NSUInteger i = 0;
    NSMutableArray *objjPaths = [NSMutableArray array];
    
    // We only want the objj files
    for (i = 0; i < numberOfFiles; i++)
    {
        NSString *path = [paths objectAtIndex:i];
        
        if ([self isObjjFile:path])
            [objjPaths addObject:path];
    }
    
    if (![objjPaths count])
        return YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:XCCBatchDidStartNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:XCCObjjDidStartNotification object:self];
    
    NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"-I", [self _getObjjIncludePaths], @"-m", nil];
    [arguments addObjectsFromArray:objjPaths];
    
    NSDictionary *taskResult = [self runTaskWithLaunchPath:self.executablePaths[@"objj"]
                                                 arguments:arguments
                                                returnType:kTaskReturnTypeStdOut];
    
    NSInteger status = [taskResult[@"status"] intValue];
    NSString *response = taskResult[@"response"];
    
    if (status == 0 && [response length] == 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:XCCObjjDidEndNotification object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:XCCBatchDidEndNotification object:self];
        return YES;
    }
    
    NSMutableArray *errors = [NSMutableArray arrayWithArray:[response componentsSeparatedByString:@"\n\n"]];
    
    NSInteger numberOfErrors = [errors count];
    NSMutableArray *dicts = [NSMutableArray array];
    
    // When checking of the entire project, we have to be ready to find errors
    NSRegularExpression *regulareExpressionFramework = [NSRegularExpression regularExpressionWithPattern:@"([\\S\\s]*)(WARNING|ERROR) line ([0-9]*) in file\\:(.*)\\: ([\\S\\s]*)" options:0 error:nil];
    
    NSString *filePath;
    
    if ([paths count] == 1)
        filePath = [paths firstObject];
    
    i = 0;
    
    for (i = 0; i < numberOfErrors; i++)
    {
        NSMutableString *error = (NSMutableString*)[errors objectAtIndex:i];
        NSString *line;
        NSString *path;
        NSString *messageError;
        
        // We have an extra new line for the first error
        if (i == 0)
            error = (NSMutableString*)[error substringFromIndex:1];
        
        NSArray *matches = [regulareExpressionFramework matchesInString:error options:0 range:NSMakeRange(0, [error length])];
        NSInteger j = 0;
        
        if (![matches count])
        {
            // This shouldn't happen
            DDLogVerbose(@"Error %@ doesn't respect any pattern", error);
            
            path = @"";
            line = 0;
            messageError = [NSString stringWithFormat:@"Compiling issue at line %@ of file %@:\n%@", line, path.lastPathComponent, error];
        }
        
        for (NSTextCheckingResult *match in matches)
        {
            for (j = 0; j < [match numberOfRanges]; j++)
            {
                switch (j) {
                    case 1:
                        messageError = [error substringWithRange:[match rangeAtIndex:j]];
                        break;
                        
                    case 3:
                        line = [error substringWithRange:[match rangeAtIndex:j]];
                        break;
                        
                    case 4:
                        path = [error substringWithRange:[match rangeAtIndex:j]];
                        break;
                        
                    case 5:
                        messageError = [NSString stringWithFormat:@"Compiling issue at line %@ of file %@:\n%@ \n%@", line, path.lastPathComponent, [error substringWithRange:[match rangeAtIndex:j]], messageError];
                        break;
                        
                    default:
                        break;
                }
            }
        }
        
        // Make sure to delete all the compilations issue form the tableView
        [self pruneProcessingErrorsForProjectPath:path type:@"objj"];
        
        // Path and realPath are needed, we can get error on ViewController2.j while checking ViewController.j.
        // When recompiling ViewController.j, realPath is used to know which errors have to be erased form the table
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInt:[line intValue]], @"line",
                                     messageError , @"message",
                                     (filePath ? filePath:path), @"path",
                                     @"objj", @"type",
                                     path , @"realPath",
                                     nil];
        
        // Block to compare dicts
        BOOL (^dictComparaison)(id obj, NSUInteger idx, BOOL *stop) = ^(id obj, NSUInteger idx, BOOL *stop){
            if ([obj valueForKey:@"line"] == [dict valueForKey:@"line"])
            {
                // For an unknown reason, trim doesn't work
                NSString *messsageObj = [obj valueForKey:@"message"];
                NSString *messsageDict = [dict valueForKey:@"message"];
                
                messsageDict = [messsageDict stringByReplacingOccurrencesOfString:@" " withString:@""];
                messsageDict = [messsageDict stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                
                messsageObj = [messsageObj stringByReplacingOccurrencesOfString:@" " withString:@""];
                messsageObj = [messsageObj stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                
                if ([messsageDict isEqualToString:messsageObj])
                {
                    *stop = YES;
                    return YES;
                }
            }
            
            return NO;
        };
        
        NSUInteger isInDict = [dicts indexOfObjectPassingTest:dictComparaison];
        NSUInteger isInList = [self.errorList indexOfObjectPassingTest:dictComparaison];
        
        // Compiler can show several times the same errors
        if (isInDict == NSNotFound && isInList == NSNotFound)
            [dicts addObject:dict];
    }
    
    [self performSelectorOnMainThread:@selector(objjCompilerDidGenerateError:) withObject:dicts waitUntilDone:YES];
    
    self.isProcessing = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:XCCObjjDidEndNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:XCCBatchDidEndNotification object:self];
    
    return NO;
}

- (IBAction)checkProjectWithObjj:(id)sender
{
    [self clearErrors:self];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(objjDidEndNotification:) name:XCCObjjDidEndNotification object:nil];
    
    [self performSelectorInBackground:@selector(checkObjjWarningsForPath:) withObject:self.xCodeCappTargetedFiles];
}

- (void)objjDidEndNotification:(NSNotification*)aNotification
{
    [self showObjjWarnings];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:XCCObjjDidEndNotification object:nil];
}

- (void)objjCompilerDidGenerateError:(NSArray*)errors
{
    [self.errorListController addObjects:errors];
}


#pragma mark - capp_lint

- (IBAction)checkProjectWithCappLint:(id)aSender
{
    [self clearErrors:self];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(cappLintDidEndNotification:) name:XCCCappLintDidEndNotification object:nil];
    
    [self performSelectorInBackground:@selector(checkCappLintForPath:) withObject:self.xCodeCappTargetedFiles];
}

- (void)cappLintDidEndNotification:(NSNotification*)aNotification
{
    [self showCappLintWarnings];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:XCCCappLintDidEndNotification object:nil];
}

- (BOOL)checkCappLintForPath:(NSArray*)paths
{
    DDLogVerbose(@"Checking path %@ with capp_lint", paths);
    
    NSUInteger numberOfFiles = [paths count];
    
    if (!numberOfFiles)
        return YES;
    
    self.isProcessing = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:XCCBatchDidStartNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:XCCCappLintDidStartNotification object:self];
    
    NSString *baseDirectory = [NSString stringWithFormat:@"--basedir='%@'", self.projectPath];
    NSMutableArray *arguments = [NSMutableArray arrayWithObjects:baseDirectory, nil];
    [arguments addObjectsFromArray:paths];
    
    NSDictionary *taskResult = [self runTaskWithLaunchPath:self.executablePaths[@"capp_lint"]
                                                 arguments:arguments
                                                returnType:kTaskReturnTypeStdOut];
    
    NSInteger status = [taskResult[@"status"] intValue];
    
    if (status == 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:XCCBatchDidEndNotification object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:XCCCappLintDidEndNotification object:self];
        return YES;
    }
    
    NSString *response = taskResult[@"response"];
    NSMutableArray *errors = [NSMutableArray arrayWithArray:[response componentsSeparatedByString:@"\n\n"]];
    
    // We need to remove the first object who is the number of errors and the last object who is an empty line
    [errors removeLastObject];
    [errors removeObjectAtIndex:0];
    
    NSInteger numberOfErrors = [errors count];
    NSInteger i = 0;
    NSString *path;
    NSMutableArray *dicts = [NSMutableArray array];
    
    if (numberOfFiles == 1)
        path = [paths objectAtIndex:0];
    
    for (i = 0; i < numberOfErrors; i++)
    {
        NSMutableString *error = (NSMutableString*)[errors objectAtIndex:i];
        NSString *line;
        NSString *firstCaract = [NSString stringWithFormat:@"%c" ,[error characterAtIndex:0]];
        
        if ([[NSScanner scannerWithString:firstCaract] scanInt:nil])
            error = (NSMutableString*)[NSString stringWithFormat:@"%@:%@", path, error];
        
        NSInteger positionOfFirstColon = [error rangeOfString:@":"].location;
        
        if (numberOfFiles > 1)
            path = [error substringToIndex:positionOfFirstColon];
        
        NSString *errorWithoutPath = [error substringFromIndex:(positionOfFirstColon + 1)];
        NSInteger positionOfSecondColon = [errorWithoutPath rangeOfString:@":"].location;
        line = [errorWithoutPath substringToIndex:positionOfSecondColon];
        
        NSString *messageError = [NSString stringWithFormat:@"Code style issue at line %@ of file %@:\n%@", line, path.lastPathComponent, errorWithoutPath];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInt:[line intValue]], @"line",
                                     messageError , @"message",
                                     path, @"path",
                                     @"capp_lint", @"type",
                                     nil];
        
        [dicts addObject:dict];
    }
    
    [self performSelectorOnMainThread:@selector(cappLintConversionDidGenerateError:) withObject:dicts waitUntilDone:YES];
    
    self.isProcessing = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:XCCBatchDidEndNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:XCCCappLintDidEndNotification object:self];
    
    return NO;
}

- (void)cappLintConversionDidGenerateError:(NSArray*)errors
{
    [self.errorListController addObjects:errors];
}

#pragma mark - Cappuccino update

- (void)updateCappuccino
{
    [[NSNotificationCenter defaultCenter] postNotificationName:XCCBatchDidStartNotification object:self];
    
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.updatingCappuccinoPanel makeKeyAndOrderFront:self];
    
    self.isCappuccinoUpdating = YES;
    
    [self.progressIndicator startAnimation:self];
    [self.progressIndicator setMaxValue:4];
    [self.progressIndicator setDoubleValue:0];
    
    NSString *temporaryFolder = NSTemporaryDirectory();
    
    if(![self _hasInitializedUpdateCappuccinoFromFolder:temporaryFolder] ||
       ![self _hasCleanedInstallOfCappuccinoFromFolder:temporaryFolder] ||
       ![self _hasInstalledCappuccinoFromFolder:temporaryFolder])
        return;
    
    [self notifyUserWithTitle:@"Update Cappuccino" message:@"Updating of Cappuccino completed"];
    [self _incrementeProgressBarAndUpdateInformationFieldWithMessage:@"Updating completed"];
    [self.progressIndicator stopAnimation:self];
    self.isCappuccinoUpdating = NO;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:XCCBatchDidEndNotification object:self];
}

- (BOOL)_hasInitializedUpdateCappuccinoFromFolder:(NSString*)aFolder
{
    //Be sure to remove an old install
    NSMutableArray *rmArguments = [NSMutableArray arrayWithObjects:@"-r", @"cappuccino", nil];
    [self runTaskWithLaunchPath:self.executablePaths[@"rm"]
                      arguments:rmArguments
                     returnType:kTaskReturnTypeAny
           currentDirectoryPath:aFolder];
    
    
    [self _incrementeProgressBarAndUpdateInformationFieldWithMessage:@"Downloading Cappuccino"];
    
    // Download the file
    NSString *cappuccinoURL;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultUpdateCappuccinoWithLastVersionOfMasterBranch])
        cappuccinoURL = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"XCCLastCappuccinoMasterBranchURL"];
    else
        cappuccinoURL = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"XCCLastCappuccinoReleaseURL"];
    
    NSString *destination = [NSString stringWithFormat:@"%@cappuccino.zip", aFolder];
    NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"-Lk", cappuccinoURL, @"-o", destination, nil];
    NSDictionary *taskResult = [self runTaskWithLaunchPath:self.executablePaths[@"curl"]
                                                 arguments:arguments
                                                returnType:kTaskReturnTypeStdOut];
    
    NSInteger status = [taskResult[@"status"] intValue];
    
    if (status > 1)
    {
        [self _updatingCappuccinoFailedWithMessage:@"Unable to download Cappuccino"];
        return NO;
    }
    
    //Unzip the file
    NSMutableArray *unzipArguments = [NSMutableArray arrayWithObjects:@"-u", @"-o", @"-q", @"-d", @"cappuccino", @"cappuccino.zip", nil];
    NSDictionary *unzipTaskResult = [self runTaskWithLaunchPath:self.executablePaths[@"unzip"]
                                                      arguments:unzipArguments
                                                     returnType:kTaskReturnTypeAny
                                           currentDirectoryPath:aFolder];
    
    NSInteger unzipStatus = [unzipTaskResult[@"status"] intValue];
    
    if (unzipStatus >= 1)
    {
        DDLogVerbose(@"Unable to unzip Cappuccino");
        [self _updatingCappuccinoFailedWithMessage:@"Unable to unzip Cappuccino"];
        return NO;
    }
    
    return YES;
}

- (BOOL)_hasCleanedInstallOfCappuccinoFromFolder:(NSString*)aFolder
{
    NSString* path = [self _cappuccinoPathForFolder:aFolder];
    
    [self _incrementeProgressBarAndUpdateInformationFieldWithMessage:@"Jake clobber"];
    
    //Jake clobber
    NSMutableArray *jakeClobberArguments = [NSMutableArray arrayWithObjects:@"clobber", nil];
    NSDictionary *jakeClobberTaskResult = [self runJakeTaskWithArguments:jakeClobberArguments currentDirectoryPath:path];
    
    NSInteger jakeInstallStatus = [jakeClobberTaskResult[@"status"] intValue];
    
    if (jakeInstallStatus == 1)
    {
        DDLogVerbose(@"Jake clobber failed: %@", jakeClobberTaskResult[@"response"]);
        [self _updatingCappuccinoFailedWithMessage:@"Jake clobber failed"];
        return NO;
    }
    
    return YES;
}

- (BOOL)_hasInstalledCappuccinoFromFolder:(NSString*)aFolder
{
    NSString* path = [self _cappuccinoPathForFolder:aFolder];
    
    [self _incrementeProgressBarAndUpdateInformationFieldWithMessage:@"Jake install"];
    
    //Jake install
    NSMutableArray *jakeInstallArguments = [NSMutableArray arrayWithObjects:@"install", nil];
    NSDictionary *jakeInstallTaskResult = [self runJakeTaskWithArguments:jakeInstallArguments currentDirectoryPath:path];
    
    NSInteger jakeInstallStatus = [jakeInstallTaskResult[@"status"] intValue];
    
    if (jakeInstallStatus == 1)
    {
        DDLogVerbose(@"Jake install failed: %@", jakeInstallTaskResult[@"response"]);
        [self _updatingCappuccinoFailedWithMessage:@"Jake install failed"];
        return NO;
    }
    
    return YES;
}

- (NSDictionary*)runJakeTaskWithArguments:(NSMutableArray*)arguments currentDirectoryPath:(NSString*)aCurrentDirectoryPath
{
    NSString *launchPath = self.executablePaths[@"jake"];
    
    NSTask *task = [NSTask new];
    
    task.launchPath = launchPath;
    task.arguments = arguments;
    task.environment = self.environment;
    task.standardOutput = [NSPipe new];
    task.standardError = [NSPipe new];
    
    if (aCurrentDirectoryPath)
        task.currentDirectoryPath = aCurrentDirectoryPath;
    
    // This is needed to log the jake
    NSFileHandle* fhOut = [task.standardOutput fileHandleForReading];
    [fhOut readInBackgroundAndNotify];
    NSFileHandle* fhErr = [task.standardError fileHandleForReading];
    [fhErr readInBackgroundAndNotify];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jakeReceivedData:) name:NSFileHandleReadCompletionNotification object:fhOut];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jakeReceivedError:) name:NSFileHandleReadCompletionNotification object:fhErr];
    
    [task launch];
    
    DDLogVerbose(@"Task launched: %@\n%@", launchPath, arguments);
    
    [task waitUntilExit];
    
    DDLogVerbose(@"Task exited: %@:%d", launchPath, task.terminationStatus);
    
    NSNumber *status = [NSNumber numberWithInt:task.terminationStatus];
    NSData *data = nil;
    
    if ([status intValue] == 0)
        data = [[task.standardOutput fileHandleForReading] availableData];
    else
        data = [[task.standardError fileHandleForReading] availableData];
    
    NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:fhOut];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:fhErr];
    
    return @{@"status" : status, @"response" : response};
}

-(void)jakeReceivedData:(NSNotification*)notification
{
    NSData *data     = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    DDLogVerbose(@"%@", string);
    
    [[notification object] readInBackgroundAndNotify];
}

-(void)jakeReceivedError:(NSNotification*)notification
{
    NSData *data     = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    DDLogVerbose(@"%@", string);
}

/*!
 This return the current path where the tmp cappuccino was downloaded
 */
- (NSString*)_cappuccinoPathForFolder:(NSString*)aFolder
{
    NSFileManager *fileManger = [NSFileManager defaultManager];
    NSString *contentOfCappuccinoFolder = [[fileManger contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@cappuccino", aFolder] error:nil] firstObject];
    
    return [NSString stringWithFormat:@"%@cappuccino/%@", aFolder, contentOfCappuccinoFolder];
}

- (void)_incrementeProgressBarAndUpdateInformationFieldWithMessage:(NSString*)aString
{
    double currentValue = [self.progressIndicator doubleValue];
    [self.progressIndicator setDoubleValue:++currentValue];
    
    [self.fieldCurrentTask setStringValue:[NSString stringWithFormat:@"Step %.0f/%.0f : %@", [self.progressIndicator doubleValue], [self.progressIndicator maxValue], aString]];
}

- (void)_updatingCappuccinoFailedWithMessage:(NSString*)aMessage
{
    [self.progressIndicator stopAnimation:self];
    [self.progressIndicator setDoubleValue:0];
    [self.fieldCurrentTask setStringValue:[NSString stringWithFormat:@"Issue : %@", aMessage]];
    
    [self notifyUserWithTitle:@"Error updating Cappuccino" message:aMessage];
    
    self.isCappuccinoUpdating = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:XCCBatchDidEndNotification object:self];
}


#pragma mark - User notifications

- (NSString *)applicationNameForGrowl
{
    return @"XcodeCapp";
}

- (void)notifyUserWithTitle:(NSString *)aTitle message:(NSString *)aMessage
{
    if ([NSUserNotificationCenter class])
    {
        NSUserNotification *note = [NSUserNotification new];
        note.title = aTitle;
        note.informativeText = aMessage;

        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:note];
    }
    else
    {
        [GrowlApplicationBridge notifyWithTitle:aTitle
                                    description:aMessage
                               notificationName:GROWL_NOTIFICATIONS_DEFAULT
                                       iconData:nil
                                       priority:0
                                       isSticky:NO
                                   clickContext:nil];
    }
}

- (void)wantUserNotificationWithInfo:(NSDictionary *)info
{
    [self performSelectorOnMainThread:@selector(notifyUserWithInfo:) withObject:info waitUntilDone:NO];
}

- (void)notifyUserWithInfo:(NSDictionary *)info
{
    if ([info[@"projectId"] intValue] != self.projectId)
        return;

    [self notifyUserWithTitle:info[@"title"] message:info[@"message"]];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    // Notification Center may decide not to show a notification. We always want them to show.
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if ([self.errorList count])
        [self openErrorsPanel:self];
    
    [center removeDeliveredNotification:notification];
}

@end


@implementation XcodeCapp (SnowLeopard)

- (void)updateLastModificationDate:(NSDate *)date forPath:(NSString *)path
{
    if (date)
        [self.pathModificationDates setObject:date forKey:path];
    else
        [self.pathModificationDates removeObjectForKey:path];

    [[NSUserDefaults standardUserDefaults] setObject:self.pathModificationDates forKey:kDefaultPathModificationDates];
}

- (NSDate *)lastModificationDateForPath:(NSString *)path
{
    if (!self.pathModificationDates)
    {
        self.pathModificationDates = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kDefaultPathModificationDates] mutableCopy];

        if (!self.pathModificationDates)
            self.pathModificationDates = [NSMutableDictionary new];
    }

    if ([self.pathModificationDates valueForKey:path] != nil)
        return [self.pathModificationDates valueForKey:path];
    else
        return self.appStartedTimestamp;
}

@end
