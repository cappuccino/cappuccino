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
            @"~/bin"
        ];

    NSMutableArray *paths = [self.environmentPaths mutableCopy];

    for (NSInteger i = 0; i < paths.count; ++i)
        paths[i] = [paths[i] stringByExpandingTildeInPath];

    self.environment[@"PATH"] = [[paths componentsJoinedByString:@":"] stringByAppendingFormat:@":%@", self.environment[@"PATH"]];

    // Make sure we are using jsc as the narwhal engine!
    self.environment[@"NARWHAL_ENGINE"] = @"jsc";

    self.executables = @[@"python", @"narwhal-jsc", @"objj", @"nib2cib"];
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
    NSTask *task = [NSTask new];
    
    task.launchPath = launchPath;
    task.arguments = arguments;
    task.environment = self.environment;
    task.standardOutput = [NSPipe pipe];
    task.standardError = [NSPipe pipe];

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
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.errorsPanel makeKeyAndOrderFront:nil];
}

- (IBAction)openErrorInEditor:(id)sender
{
    id info = self.errorListController.selection;

    NSString *path = [info valueForKey:@"path"];

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

- (void)showErrors
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (([defaults boolForKey:kDefaultXCCAutoOpenErrorsPanelOnErrors] && self.hasErrors) ||
        ([defaults boolForKey:kDefaultXCCAutoOpenErrorsPanelOnWarnings] && self.errorList.count))
    {
        [self openErrorsPanel:self];
    }
}

- (void)pruneProcessingErrorsForProjectPath:(NSString *)path
{
    // Remove all errors for the path being processed
    NSIndexSet *matchingErrors = [self.errorList indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
                                  {
                                      return [[obj valueForKey:@"path"] isEqualToString:path];
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

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultShowProcessingNotices])
        [self notifyUserWithTitle:info[@"title"] message:info[@"message"]];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    // Notification Center may decide not to show a notification. We always want them to show.
    return YES;
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
