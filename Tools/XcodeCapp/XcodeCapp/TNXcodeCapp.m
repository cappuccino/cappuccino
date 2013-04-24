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

#import <Growl/Growl.h>

#import "TNXcodeCapp.h"
#import "FSEventCallback.h"
#import "UserDefaults.h"

#include "macros.h"

enum XCCTaskReturnType {
    kTaskReturnTypeNone,
    kTaskReturnTypeStdOut,
    kTaskReturnTypeStdError
};
typedef enum XCCTaskReturnType XCCTaskReturnType;

enum XCCLineSpecifier {
    kLineSpecifierNone,
    kLineSpecifierColon,
    kLineSpecifierMinusL,
    kLineSpecifierPlus
};
typedef enum XCCLineSpecifier XCCLineSpecifier;

NSString * const XCCDidPopulateProjectNotification = @"XCCDidPopulateProjectNotification";
NSString * const XCCConversionDidStartNotification = @"XCCConversionDidStartNotification";
NSString * const XCCConversionDidStopNotification = @"XCCConversionDidStopNotification";
NSString * const XCCListeningDidStartNotification = @"XCCListeningDidStartNotification";

NSString * const XCCSlashReplacement = @"∕";  // DIVISION SLASH, Unicode: U+2215
NSString * const XCCBashPath = @"/bin/bash";
NSString * const XCCZShPath = @"/bin/zsh";

NSString * const XCCDirectoriesToIgnorePattern = @"^(?:Build|F(?:rameworks|oundation)|AppKit|Objective-J|(?:Browser|CommonJS)\\.environment|Resources|XcodeSupport|.+\\.xcodeproj)$";
NSRegularExpression * XCCDirectoriesToIgnoreRegex = nil;

NSArray *XCCDefaultIgnoredPathRegexes = nil;


@interface TNXcodeCapp ()

@property FSEventStreamRef		stream;
@property NSFileManager     	*fm;
@property NSMutableArray      	*ignoredPathRegexes;
@property NSNumber          	*lastEventId;
@property NSString          	*parserPath;
@property NSString          	*XcodeSupportPBXPath;
@property NSString          	*XcodeSupportProjectName;
@property NSString          	*XcodeTemplatePBXPath;
@property NSString          	*profilePath;
@property NSString          	*shellPath;
@property NSString          	*PBXModifierScriptPath;
@property NSString              *supportPath;
@property NSDate                *appStartedTimestamp;
@property NSMutableDictionary   *pathModificationDates;
@property NSMutableDictionary	*projectPathsForSourcePaths;
@property NSString				*xcodecappIgnorePath;

@end


@implementation TNXcodeCapp

#pragma mark - Initialization

+ (void)initialize
{
    if (self != [TNXcodeCapp class])
        return;

    NSError *error = NULL;
    XCCDirectoriesToIgnoreRegex = [NSRegularExpression regularExpressionWithPattern:XCCDirectoriesToIgnorePattern options:0 error:&error];
    
    NSArray *defaultIgnoredPaths = @[
        @"*/Frameworks/",
        @"!*/Frameworks/Debug/",
        @"*/AppKit/",
        @"*/Foundation/",
        @"*/Objective-J/",
  		@"*/*.environment/",
        @"*/Build/",
		@"*/.*/",
        @"*/NS_*.j",
        @"*/main.j",
        @"*/.*",
        @"!*/.xcodecapp-ignore"
    ];

    XCCDefaultIgnoredPathRegexes = [self parseIgnorePaths:defaultIgnoredPaths];
}

- (id)init
{
    self = [super init];

    if (self)
    {
        self.errorList = [NSMutableArray arrayWithCapacity:10];
        self.fm = [NSFileManager defaultManager];
        self.ignoredPathRegexes = [NSMutableArray new];
        self.parserPath = [[NSBundle mainBundle] pathForResource:@"parser" ofType:@"j"];
        self.lastEventId = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultLastEventId];
        self.appStartedTimestamp = [NSDate date];
        self.projectPathsForSourcePaths = [NSMutableDictionary new];
        self.xcodecappIgnorePath = @"";

        self.isListening = NO;
        self.isUsingFileLevelAPI = NO;
        self.isLoadingProject = NO;

        SInt32 versionMajor = 0;
        SInt32 versionMinor = 0;
        Gestalt(gestaltSystemVersionMajor, &versionMajor);
        Gestalt(gestaltSystemVersionMinor, &versionMinor);

        self.supportsFileLevelAPI = versionMajor >= 10 && versionMinor >= 7;
        // Uncomment to simulate 10.6 mode
        // self.supportsFileLevelAPI = NO;

        [self configureFileAPI];
        [self getShellProfilePath];

        NSUserNotificationCenter.defaultUserNotificationCenter.delegate = self;
        [GrowlApplicationBridge setGrowlDelegate:self];
    }

    return self;
}

- (void)start
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults boolForKey:kDefaultXCCReopenLastProject])
        return;

    NSString *lastOpenedPath = [defaults objectForKey:kDefaultLastOpenedPath];

    if (lastOpenedPath)
    {
        if ([self.fm fileExistsAtPath:lastOpenedPath])
            [self listenToProjectAtPath:lastOpenedPath];
        else
            [defaults removeObjectForKey:kDefaultLastOpenedPath];
    }
}

/*!
 Stops the event listener, clears state
 */
- (void)stop
{
    [self stopEventStream];
    [self clearErrors:self];
    [self updateUserDefaultsWithLastEventId];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.currentProjectPath = nil;
    [self.ignoredPathRegexes removeAllObjects];
}


#pragma mark - Project Management

/*!
	Check if XcodeSupport needs to be initialized.
	If not needed, check that all .j files are mirrored.
	If not, then launch conversion for missing mirrored .h files.
 
 	@return YES if Xcode project exists, NO if not 
*/
- (BOOL)prepareXcodeSupportProject
{
    self.XcodeSupportProjectName    = [NSString stringWithFormat:@"%@.xcodeproj", self.currentProjectPath.lastPathComponent];
    self.XcodeTemplatePBXPath       = [[NSBundle mainBundle] pathForResource:@"project" ofType:@"pbxproj"];

    NSURL *projectURL = [NSURL fileURLWithPath:self.currentProjectPath];
    self.XcodeSupportProjectURL     = [NSURL URLWithString:self.XcodeSupportProjectName relativeToURL:projectURL];
    self.supportPath 				= [[NSURL URLWithString:@"XcodeSupport" relativeToURL:projectURL] path];
    self.XcodeSupportPBXPath        = [self.XcodeSupportProjectURL.path stringByAppendingPathComponent:@"project.pbxproj"];
    self.PBXModifierScriptPath      = [[NSBundle mainBundle] pathForResource:@"pbxprojModifier" ofType:@"py"];

    // Create the template project if it doesn't exist
    if (![self.fm fileExistsAtPath:self.supportPath])
    {
        NSLog(@"%@ Xcode support folder created at: %@", NSStringFromSelector(_cmd), self.XcodeSupportProjectURL.path);
        [self.fm createDirectoryAtPath:self.XcodeSupportProjectURL.path withIntermediateDirectories:YES attributes:nil error:nil];

        DLog(@"%@ Copying project.pbxproj from %@ to %@", NSStringFromSelector(_cmd), self.XcodeTemplatePBXPath, self.XcodeSupportProjectURL.path);
        [self.fm copyItemAtPath:self.XcodeTemplatePBXPath toPath:self.XcodeSupportPBXPath error:nil];

        DLog(@"%@ Reading the content of the project.pbxproj", NSStringFromSelector(_cmd));
        NSMutableString *PBXContent = [NSMutableString stringWithContentsOfFile:self.XcodeSupportPBXPath encoding:NSUTF8StringEncoding error:nil];

        [PBXContent writeToFile:self.XcodeSupportPBXPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        DLog(@"%@ PBX file adapted to the project", NSStringFromSelector(_cmd));

        [self.fm createDirectoryAtPath:self.supportPath withIntermediateDirectories:YES attributes:nil error:nil];

        return NO;
    }

    return YES;
}

/*!
 	Create and initialize the Xcode project.

	@param shouldNotify If YES, XCCDidPopulateProjectNotification will be sent
*/
- (void)populateXcodeProject:(BOOL)shouldNotify
{
    if (shouldNotify)
        [self notifyUserWithTitle:@"Loading project" message:self.currentProjectPath.lastPathComponent];

	// First populate with all non-framework code
    [self populateXcodeProjectWithProjectRelativePath:@""];

    // Now populate with any user source debug frameworks
    [self populateXcodeProjectWithProjectRelativePath:@"Frameworks/Debug"];

    // Now populate with any source frameworks
    [self populateXcodeProjectWithProjectRelativePath:@"Frameworks/Source"];

    // Now populate resources
    [self populateXcodeProjectWithProjectRelativePath:@"Resources"];

    if (shouldNotify)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:XCCDidPopulateProjectNotification object:self userInfo:nil];
        [self notifyUserWithTitle:@"Project loaded" message:self.currentProjectPath.lastPathComponent];
	}
}

- (void)populateXcodeProjectWithProjectRelativePath:(NSString *)aProjectPath
{
    NSError *error = NULL;
    NSString *projectPath = [self.currentProjectPath stringByAppendingPathComponent:aProjectPath];
    
	NSArray *urls = [self.fm contentsOfDirectoryAtURL:[NSURL fileURLWithPath:[projectPath stringByResolvingSymlinksInPath]]
                           includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLIsSymbolicLinkKey]
                                              options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                         		error:&error];
    
	if (!urls)
        return;
    
    for (NSURL *url in urls)
    {
        NSString *filename = url.lastPathComponent;

		NSString *projectRelativePath = [aProjectPath stringByAppendingPathComponent:filename];
        NSString *realPath = url.path;
        NSURL *resolvedURL = url;

        NSNumber *isDirectory, *isSymlink;
        [url getResourceValue:&isSymlink forKey:NSURLIsSymbolicLinkKey error:nil];

        if (isSymlink.boolValue == YES)
        {
            resolvedURL = [url URLByResolvingSymlinksInPath];

            if ([resolvedURL checkResourceIsReachableAndReturnError:nil])
            {
                filename = resolvedURL.lastPathComponent;
                realPath = resolvedURL.path;
            }
            else
                continue;
        }

        [resolvedURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];

        if (isDirectory.boolValue == YES)
        {
            if ([XCCDirectoriesToIgnoreRegex numberOfMatchesInString:filename options:0 range:NSMakeRange(0, filename.length)] > 0)
                continue;
            
            // If the resolved path is not within the project directory, add a mapping to it
            // so we can map the resolved path back to the project directory later.
            if (isSymlink.boolValue == YES)
            {
                NSString *fullProjectPath = [self.currentProjectPath stringByAppendingPathComponent:projectRelativePath];

                if (![realPath hasPrefix:fullProjectPath])
                    self.projectPathsForSourcePaths[realPath] = fullProjectPath;
            }

            [self populateXcodeProjectWithProjectRelativePath:projectRelativePath];
            continue;
        }

        if ([self pathMatchesIgnoredPaths:realPath])
            continue;

        NSString *projectSourcePath = [self.currentProjectPath stringByAppendingPathComponent:projectRelativePath];

        if ([self isObjjFile:filename] || [self isXibFile:filename])
        {
            NSString *processedPath;

            if ([self isObjjFile:filename])
                processedPath = [[self shadowBasePathForSourcePath:realPath] stringByAppendingPathExtension:@"h"];
            else
                processedPath = [[realPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"cib"];

            if (![self.fm fileExistsAtPath:processedPath])
                [self processModifiedFileAtPath:realPath projectSourcePath:projectSourcePath notify:YES];
        }
    }
}

- (void)listenToProjectAtPath:(NSString *)path
{
    self.isLoadingProject = YES;
    
    [self clearErrors:self];
    self.currentProjectPath = path;
    self.xcodecappIgnorePath = [self.currentProjectPath stringByAppendingPathComponent:@".xcodecapp-ignore"];
    self.projectPathsForSourcePaths = [NSMutableDictionary new];
    [self computeIgnoredPaths];

    BOOL isProjectReady = [self prepareXcodeSupportProject];
    [self populateXcodeProject:!isProjectReady];

    self.isLoadingProject = NO;
    
    [self initializeEventStreamWithPath:self.currentProjectPath];

    NSDictionary *info = @{ @"path": path, @"ready": [NSNumber numberWithBool:isProjectReady] };
    [[NSNotificationCenter defaultCenter] postNotificationName:XCCListeningDidStartNotification object:self userInfo:info];

    [[NSUserDefaults standardUserDefaults] setObject:self.currentProjectPath forKey:kDefaultLastOpenedPath];

    [self notifyUserWithTitle:@"Listening to project" message:self.currentProjectPath.lastPathComponent];
}


#pragma mark - Event Stream

/*!
	Initializes the FSEvent stream

 	@param path the path of the folder to watch
 */
- (void)initializeEventStreamWithPath:(NSString *)path
{
    if (self.isListening)
        return;

    [self stopEventStream];

    NSMutableArray *pathsToWatch = [NSMutableArray arrayWithObject:path];
    FSEventStreamCreateFlags flags = 0;

    if (self.supportsFileBasedListening)
    {
        DLog(@"%@ Initializing the FSEventStream at file level (clean)", NSStringFromSelector(_cmd));
        flags = kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagFileEvents;
    }
    else
    {
        NSLog(@"Initializing the FSEventStream at folder level (dirty)");
        flags = kFSEventStreamCreateFlagUseCFTypes;
    }

    NSArray *directoriesToWatch = @[@"", @"Frameworks/Debug", @"Frameworks/Source"];

    for (NSString *directory in directoriesToWatch)
    {
        NSString *fullPath = [self.currentProjectPath stringByAppendingPathComponent:directory];

        BOOL exists, isDirectory;
        exists = [self.fm fileExistsAtPath:fullPath isDirectory:&isDirectory];

        if (exists && isDirectory)
            [self watchSymlinkedDirectoriesAtPath:directory pathsToWatch:pathsToWatch];
	}
    
    void *appPointer = (__bridge void *)self;
    FSEventStreamContext context = { 0, appPointer, NULL, NULL, NULL };
    CFTimeInterval latency = 2.0;

    self.stream = FSEventStreamCreate(NULL, &fsevents_callback, &context, (__bridge CFArrayRef) pathsToWatch,
                                 	  self.lastEventId.unsignedLongLongValue, latency, flags);

    FSEventStreamScheduleWithRunLoop(self.stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(self.stream);
    self.isListening = YES;
}

- (void)watchSymlinkedDirectoriesAtPath:(NSString *)projectPath pathsToWatch:(NSMutableArray *)pathsToWatch
{
    NSString *fullProjectPath = [self.currentProjectPath stringByAppendingPathComponent:projectPath];
    NSError *error = NULL;

	NSArray *urls = [self.fm contentsOfDirectoryAtURL:[NSURL fileURLWithPath:fullProjectPath]
                           includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLIsSymbolicLinkKey]
                                              options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                         		error:&error];

    for (NSURL *url in urls)
    {
        NSNumber *isSymlink;
        [url getResourceValue:&isSymlink forKey:NSURLIsSymbolicLinkKey error:nil];

        if (isSymlink.boolValue == YES)
        {
            NSURL *resolvedURL = [url URLByResolvingSymlinksInPath];

            if ([resolvedURL checkResourceIsReachableAndReturnError:nil])
            {
                NSNumber *isDirectory;
                [resolvedURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];

                if (isDirectory.boolValue == YES)
                {
                    NSString *filename = resolvedURL.lastPathComponent;
                    
                    if ([XCCDirectoriesToIgnoreRegex numberOfMatchesInString:filename options:0 range:NSMakeRange(0, filename.length)] == 0)
                        [pathsToWatch addObject:resolvedURL.path];
                }
            }
        }
    }
}

- (void)stopEventStream
{
    if (self.stream)
    {
        FSEventStreamStop(self.stream);
        FSEventStreamUnscheduleFromRunLoop(self.stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        FSEventStreamInvalidate(self.stream);
        FSEventStreamRelease(self.stream);
        self.stream = NULL;
    }

    self.isListening = NO;
}

/*!
	Choose the API mode according to default
 */
- (void)configureFileAPI
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (!self.supportsFileLevelAPI)
    {
        DLog(@"%@ System doesn't support file level API", NSStringFromSelector(_cmd));
        [defaults setObject:[NSNumber numberWithInt:kXCCAPIModeFolder] forKey:kDefaultXCCAPIMode];
    }

    switch ([defaults integerForKey:kDefaultXCCAPIMode])
    {
        case kXCCAPIModeAuto:
            self.supportsFileBasedListening = self.supportsFileLevelAPI;
            break;
            
        case kXCCAPIModeFile:
            self.supportsFileBasedListening = YES;
            break;
            
        case kXCCAPIModeFolder:
            self.supportsFileBasedListening = NO;
            break;
    }

    if (self.supportsFileBasedListening)
    {
        DLog(@"%@ using 10.7+ mode listening (clean)", NSStringFromSelector(_cmd));

        self.currentAPIMode = @"File level (Lion)";
        self.isUsingFileLevelAPI = YES;
        self.reactToInodeModification = [defaults boolForKey:kDefaultXCCReactMode];
    }
    else
    {
        DLog(@"%@ using 10.6 mode listening (dirty)", NSStringFromSelector(_cmd));
        self.reactToInodeModification = NO;
        self.currentAPIMode = @"Folder level (Snow Leopard)";
        self.isUsingFileLevelAPI = NO;
    }
}

/*!
	Update the last event ID. We use a method because
	this is called from outside the class, in the FSEvent callback.
 
 	@param eventId the current event ID value
*/
- (void)updateLastEventId:(uint64_t)eventId
{
    self.lastEventId = [NSNumber numberWithUnsignedLongLong:eventId];
}

/*!
	Updates the user defaults with the last recorded event Id.
*/
- (void)updateUserDefaultsWithLastEventId
{
    if (self.lastEventId && self.lastEventId.longLongValue != 0)
        [[NSUserDefaults standardUserDefaults] setObject:self.lastEventId forKey:kDefaultLastEventId];
}


#pragma mark - Shell Helpers

/*!
	Run an NSTask with the given arguments
 
 	@param arguments NSArray containing the NSTask arguments
 	@return NSarray containing the return status (int) and the response (string)
 */
- (NSDictionary *)runTaskWithLaunchPath:(NSString *)launchPath arguments:(NSArray *)arguments returnType:(XCCTaskReturnType)returnType
{
    NSTask *task = [NSTask new];
    
    task.launchPath = launchPath;
    task.arguments = arguments;
    task.standardOutput = [NSPipe pipe];
    task.standardError = [NSPipe pipe];
    [task launch];

    if (returnType != kTaskReturnTypeNone)
    {
        [task waitUntilExit];

        NSData *data = [[(returnType == kTaskReturnTypeStdOut ? task.standardOutput : task.standardError) fileHandleForReading] availableData];
        NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSNumber *status = [NSNumber numberWithInt:task.terminationStatus];

    	return @{ @"status":status, @"response":response };
    }
    else
    {
        return @{ @"status":@0, @"response":@"" };
    }
}

- (void)getShellProfilePath
{
    NSString* myShell = [[[NSProcessInfo processInfo] environment] objectForKey:@"SHELL"];
    self.shellPath = myShell ? myShell : XCCBashPath;
    self.profilePath = @"";
    NSArray *profiles;
    NSString *path;

    if ([self.shellPath hasSuffix:@"/bash"])
    {
        profiles = @[@"~/.bash_profile", @"~/.bashrc", @"~/.profile"];
    }
    else if ([self.shellPath hasSuffix:@"/zsh"])
    {
        profiles = @[@"~/.zshrc", @"~/.profile"];
    }
    else
    {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Unsupported shell."
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"You are using %@ as your shell. XcodeCapp requires either bash or zsh to run.", self.shellPath];
        [alert runModal];

        [[NSRunningApplication currentApplication] terminate];
        return;
    }

    for (NSString *profile in profiles)
    {
        path = [profile stringByExpandingTildeInPath];

        if ([self.fm fileExistsAtPath:path])
        {
            self.profilePath = path;
            return;
        }
    }
}

#pragma mark - Event Handlers

/*!
	Handle a file modification. If it's a .j or xib/nib,
	perform the appropriate conversion. If it's .xcodecapp-ignore, it will
	update the list of ignored files.

 	@param fullPath The full path of the modified file
	@param shouldNotify If YES, Growl notifications will be displayed
*/
- (void)handleFileModificationAtPath:(NSString*)path notify:(BOOL)shouldNotify
{
    if (![self isXibFile:path] && ![self isObjjFile:path] && ![self isXCCIgnoreFile:path])
        return;

    if ([self pathMatchesIgnoredPaths:path] || ![self.fm fileExistsAtPath:path])
        return;

    NSString *projectPath = [self projectPathForSourcePath:path];
    BOOL success = [self processModifiedFileAtPath:path projectSourcePath:projectPath notify:shouldNotify];

    if (success)
        [self notifyUserWithTitle:@"File successfully processed" message:path.lastPathComponent];
}

- (BOOL)processModifiedFileAtPath:(NSString *)realSourcePath projectSourcePath:(NSString *)projectSourcePath notify:(BOOL)shouldNotify
{
    DLog(@"Processing modified file: %@", realSourcePath);

    BOOL success = YES;
    
    NSArray *arguments = nil;
    NSArray *pbxArguments = nil;
    NSString *growlTitle = nil;
    NSString *growlMessage = nil;
    NSString *response = nil;

    NSString *projectRelativePath = [projectSourcePath substringFromIndex:self.currentProjectPath.length + 1];

    [[NSNotificationCenter defaultCenter] postNotificationName:XCCConversionDidStartNotification object:self];

    // Remove all errors for the path being processed
    BOOL (^pathMatcher)(id obj, NSUInteger idx, BOOL *stop);

    pathMatcher = ^(id obj, NSUInteger idx, BOOL *stop)
    				{
                        return [[obj valueForKey:@"path"] isEqualToString:realSourcePath];
                    };

    NSIndexSet *matchingErrors = [self.errorList indexesOfObjectsPassingTest:pathMatcher];
    [self.errorListController removeObjectsAtArrangedObjectIndexes:matchingErrors];

    if ([self isXibFile:realSourcePath])
    {
        arguments = @[
                      	@"-c",
                     	[NSString stringWithFormat:@"source '%@'; nib2cib --no-colors '%@'", self.profilePath, realSourcePath],
						@""
                    ];

        growlTitle = @"Converting xib...";
        growlMessage = projectRelativePath.lastPathComponent;
    }
    else if ([self isObjjFile:realSourcePath])
    {
        arguments = @[
                      	@"-c",
                    	[NSString stringWithFormat:@"(source '%@'; objj '%@' '%@' '%@') 2>&1",
                      				self.profilePath,
                      				self.parserPath,
                      				realSourcePath,
                      				self.supportPath]
                    ];

        pbxArguments = @[
                         	@"-c",
                        	[NSString stringWithFormat:@"(source '%@'; python '%@' add '%@' '%@') 2>&1",
                         				self.profilePath,
                         				self.PBXModifierScriptPath,
                             			self.currentProjectPath,
                             			projectSourcePath]
                        ];

        growlTitle = @"Processing Objective-J source...";
        growlMessage = projectRelativePath.lastPathComponent;
    }
    else if ([self isXCCIgnoreFile:realSourcePath])
    {
        [self computeIgnoredPaths];
        growlTitle = @"Parsing .xcodecapp-ignore...";
        growlMessage = @"Updating ignored paths";
        arguments = nil;
    }

    // Run the task and get the response if needed
    if (arguments)
    {
        DLog(@"%@ Running conversion task...", NSStringFromSelector(_cmd));

        [self notifyUserWithTitle:growlTitle message:growlMessage];
        
		NSDictionary *taskResult = [self runTaskWithLaunchPath:self.shellPath
                                                     arguments:arguments
                                                    returnType:[self isObjjFile:realSourcePath] ? kTaskReturnTypeStdOut : kTaskReturnTypeStdError];

        NSInteger status = [taskResult[@"status"] intValue];
        response = taskResult[@"response"];

        DLog(@"%@ Conversion task result/response: %ld/%@", NSStringFromSelector(_cmd), status, response);

        if (status != 0)
        {
            success = NO;
            
            if (response.length == 0)
                response = @"An unspecified error occurred";
            
            if ([self isXibFile:realSourcePath])
            {
                NSString *message = [NSString stringWithFormat:@"%@\n%@", realSourcePath.lastPathComponent, response];
                [self.errorListController addObject:@{ @"message":message, @"path":realSourcePath }];
            }
            else
            {
                NSArray *errors = [response propertyList];

                for (NSDictionary *error in errors)
                {
                    NSMutableDictionary *newError = [error mutableCopy];
                    newError[@"message"] = [NSString stringWithFormat:@"%@, line %d\n%@", [error[@"path"] lastPathComponent], [error[@"line"] intValue], error[@"message"]];
                    [self.errorListController addObject:newError];
                }
            }

            if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultXCCAutoOpenErrorsPanel])
                [self openErrorsPanel:self];

            [self notifyUserWithTitle:@"Error processing file" message:projectRelativePath.lastPathComponent];
        }
    }

    if (pbxArguments)
    {
        DLog(@"%@ Running update PBX task...", NSStringFromSelector(_cmd));
        NSDictionary *taskResult = [self runTaskWithLaunchPath:self.shellPath arguments:pbxArguments returnType:kTaskReturnTypeStdOut];
        DLog(@"%@ Update PBX Task result/response: %@/%@", NSStringFromSelector(_cmd), taskResult[@"status"], taskResult[@"response"]);
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:XCCConversionDidStopNotification object:self];
    DLog(@"%@ Processed: %@", NSStringFromSelector(_cmd), realSourcePath);

    return success;
}

/*!
	Handle a file deletion. If it's a .j, it will
	remove the shadowed .h file. If it's .xcodecapp-ignore
	it will reset the list of ignored files.
 
	@param fullPath the full path of the modified file
	@param shouldNotify if YES, Growl notifications will be displayed
*/
- (void)handleFileRemovalAtPath:(NSString*)path
{
    if ([self pathMatchesIgnoredPaths:path] || [self.fm fileExistsAtPath:path])
        return;

    if ([self isObjjFile:path])
    {
        [self removeReferencesToSourcePath:path];
        [self notifyUserWithTitle:@"Removed Objective-J file" message:path.lastPathComponent];
    }
    else if ([self isXCCIgnoreFile:path])
        [self computeIgnoredPaths];
}

#pragma mark - Source Files Management

- (BOOL)isObjjFile:(NSString *)path
{
    return [path.pathExtension.lowercaseString isEqual:@"j"];
}

- (BOOL)isXibFile:(NSString *)path
{
    NSString *extension = path.pathExtension.lowercaseString;
    return  [extension isEqual:@"xib"] || [extension isEqual:@"nib"];
}

- (BOOL)isXCCIgnoreFile:(NSString *)path
{
    return [path isEqualToString:self.xcodecappIgnorePath];
}

- (NSString *)projectPathForSourcePath:(NSString *)path
{
    NSString *base = [path stringByDeletingLastPathComponent];
	NSString *projectPath = self.projectPathsForSourcePaths[base];

    return projectPath ? [projectPath stringByAppendingPathComponent:path.lastPathComponent] : path;
}

#pragma mark - Shadow Files Management

- (NSString *)shadowBasePathForSourcePath:(NSString *)path
{
    return [self.supportPath stringByAppendingPathComponent:[[path stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"/" withString:XCCSlashReplacement]];
}

- (NSString *)sourcePathForShadowPath:(NSString *)path
{
    path = [path stringByReplacingOccurrencesOfString:XCCSlashReplacement withString:@"/"];
    return [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"j"];
}

/*!
 	Clean up any shadow files and PBX entries related to given the Cappuccino source file path
*/
- (void)removeReferencesToSourcePath:(NSString *)sourcePath
{
    NSString *shadowBasePath = [self shadowBasePathForSourcePath:sourcePath];
    NSString *shadowHeaderPath = [shadowBasePath stringByAppendingPathExtension:@"h"];
    NSString *shadowImplementationPath = [shadowBasePath stringByAppendingPathExtension:@"m"];

    DLog(@"%@ Removing shadow header file: %@", NSStringFromSelector(_cmd), shadowHeaderPath);
    [self.fm removeItemAtPath:shadowHeaderPath error:nil];

    DLog(@"%@ Removing shadow implementation file: %@", NSStringFromSelector(_cmd), shadowImplementationPath);
    [self.fm removeItemAtPath:shadowImplementationPath error:nil];

    DLog(@"%@ Removing PBX reference", NSStringFromSelector(_cmd));
    NSString *projectSourcePath = [self projectPathForSourcePath:sourcePath];

    NSArray *pbxArguments = @[
                                 @"-c",
                                 [NSString stringWithFormat:@"(source %@; python %@ remove '%@' '%@') 2>&1",
                                    self.profilePath,
                                    self.PBXModifierScriptPath,
									self.currentProjectPath,
                                    projectSourcePath]
                            ];

    NSDictionary *taskResult = [self runTaskWithLaunchPath:self.shellPath arguments:pbxArguments returnType:kTaskReturnTypeStdOut];
    DLog(@"%@ PBX Reference removal status/response: %@/%@", NSStringFromSelector(_cmd), taskResult[@"status"], taskResult[@"response"]);
}

/*!
	Clean the support folder according to files present in given path
*/
- (void)tidyShadowedFiles
{
    NSArray *subpaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.supportPath error:nil];

    for (NSString *path in subpaths)
    {
        if ([path.pathExtension isEqual:@"m"] || [path.lastPathComponent isEqualToString:@"xcc_general_include.h"])
            continue;

        NSString *sourcePath = [self sourcePathForShadowPath:path];

        if (![self.fm fileExistsAtPath:sourcePath])
        {
            [self removeReferencesToSourcePath:sourcePath];

            if (!self.supportsFileLevelAPI && [self respondsToSelector:@selector(updateLastModificationDate:forPath:)])
                [self updateLastModificationDate:nil forPath:sourcePath];
        }
    }
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
    NSError *error = NULL;
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];

    for (NSString *pattern in paths)
    {
        if ([pattern stringByTrimmingCharactersInSet:whitespace].length == 0)
            continue;

        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[self globToRegexPattern:pattern] options:0 error:&error];
        [parsedPaths addObject:@{ @"regex": regex, @"exclude": @([pattern characterAtIndex:0] != '!') }];
    }
    
    return parsedPaths;
}

/*!
	Compute the ignored paths according to any existing .xcodecapp-ignore file
*/
- (void)computeIgnoredPaths
{
    self.ignoredPathRegexes = [XCCDefaultIgnoredPathRegexes mutableCopy];
    NSString *ignorePath = [self.currentProjectPath stringByAppendingPathComponent:@".xcodecapp-ignore"];

    if ([self.fm fileExistsAtPath:ignorePath])
    {
        NSString *ignoreFileContent = [NSString stringWithContentsOfFile:ignorePath encoding:NSUTF8StringEncoding error:nil];
        NSArray *ignoredPatterns = [ignoreFileContent componentsSeparatedByString:@"\n"];
		NSArray *parsedPaths = [[self class] parseIgnorePaths:ignoredPatterns];
        [self.ignoredPathRegexes addObjectsFromArray:parsedPaths];
    }

    DLog(@"Ignoring file paths: %@", self.ignoredPathRegexes);
}

- (BOOL)pathMatchesIgnoredPaths:(NSString*)aPath
{
    BOOL ignore = NO;
    NSRange range = NSMakeRange(0, aPath.length);
    
    for (NSDictionary *ignoreInfo in self.ignoredPathRegexes)
    {
        BOOL matches = [ignoreInfo[@"regex"] numberOfMatchesInString:aPath options:0 range:range] > 0;

        if (matches)
            ignore = [ignoreInfo[@"exclude"] boolValue];
    }

    return ignore;
}

#pragma mark - Errors panel

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
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		[workspace openFile:path];
    }

    [self.errorsPanel orderOut:self];
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

- (IBAction)clearErrors:(id)sender
{
    [self.errorList removeAllObjects];
    self.errorListController.content = self.errorList;
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

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    // Notification Center may decide not to show a notification. We always want them to show.
    return YES;
}

@end


@implementation TNXcodeCapp (SnowLeopard)

- (void)updateLastModificationDate:(NSDate *)date forPath:(NSString *)path
{
    if (!self.pathModificationDates)
    {
        self.pathModificationDates = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kDefaultPathModificationDates] mutableCopy];

        if (!self.pathModificationDates)
            self.pathModificationDates = [NSMutableDictionary new];
    }

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
