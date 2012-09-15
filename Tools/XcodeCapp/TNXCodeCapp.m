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

#import "TNXCodeCapp.h"
#include "macros.h"

NSString * const XCCUnderscoreReplacement = @"DoNotPutThisStringInFileNameOrWorldWillDie";
NSString * const XCCDidPopulateProjectNotification = @"XCCDidPopulateProjectNotification";
NSString * const XCCConversionStartNotification = @"XCCConversionStartNotification";
NSString * const XCCConversionStopNotification = @"XCCConversionStopNotification";
NSString * const XCCListeningStartNotification = @"XCCListeningStartNotification";


@implementation TNXCodeCapp

@synthesize delegate;
@synthesize errorList;
@synthesize XCodeSupportProject;
@synthesize currentProjectURL;
@synthesize currentProjectName;
@synthesize supportsFileBasedListening;
@synthesize reactToInodeModification;
@synthesize currentAPIMode;
@synthesize isListening;
@synthesize supportFileLevelAPI;
@synthesize isUsingFileLevelAPI;


#pragma mark - Initialization

/*!
 Initialize the AppController
 */
- (id)init
{
    self = [super init];

    if (self)
    {
        errorList = [NSMutableArray arrayWithCapacity:10];
        fm = [NSFileManager defaultManager];
        ignoredFilePaths = [NSMutableSet new];
        parserPath = [[NSBundle mainBundle] pathForResource:@"parser" ofType:@"j"];
        lastEventId = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastEventId"];
        appStartedTimestamp = [NSDate date];

        [self setIsListening:NO];
        [self setIsUsingFileLevelAPI:NO];

        SInt32 versionMajor = 0;
        SInt32 versionMinor = 0;
        Gestalt(gestaltSystemVersionMajor, &versionMajor);
        Gestalt(gestaltSystemVersionMinor, &versionMinor);

        [self setSupportFileLevelAPI:versionMajor >= 10 && versionMinor >= 7];
        // Uncomment to simulate 10.6 mode
        // [self setSupportFileLevelAPI:NO];

        [self configure];

        if([fm fileExistsAtPath:[@"~/.bash_profile" stringByExpandingTildeInPath]])
            profilePath = [@"source ~/.bash_profile" stringByExpandingTildeInPath];
        else if([fm fileExistsAtPath:[@"~/.profile" stringByExpandingTildeInPath]])
            profilePath = [@"source ~/.profile" stringByExpandingTildeInPath];
        else if([fm fileExistsAtPath:[@"~/.bashrc" stringByExpandingTildeInPath]])
            profilePath = [@"source ~/.bashrc" stringByExpandingTildeInPath];
        else if([fm fileExistsAtPath:[@"~/.zshrc" stringByExpandingTildeInPath]])
            profilePath = [@"source ~/.zshrc" stringByExpandingTildeInPath];
        else
        {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Cannot find any valid profile file."
                                             defaultButton:@"OK"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"Neither ~/.bash_profile, ~/.profile, ~/.bashrc nor ~/.zshrc can be found.\n\nWithout this XcodeCapp cannot locate nib2cib.\n\nIf you notice any errors or strange behaviour, please look at the system log for messages and open a ticket."];
            [alert runModal];
            profilePath = @"";
        }
    }

    return self;
}

- (void)start
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"XCCReopenLastProject"])
        return;

    NSString *lastOpenedPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastOpenedPath"];

    if (lastOpenedPath)
    {
        if ([fm fileExistsAtPath:lastOpenedPath])
        {
            [self listenProjectAtPath:[NSString stringWithFormat:@"%@/", lastOpenedPath]];
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastOpenedPath"];
        }
    }
}


#pragma mark - Project Management

/*!
 Check if .XcodeSupport needs to be initialized.
 If not needed, check that all J files are mirrored. If no,
 then launch conversion for missing mirrored h files
 @return YES or NO
 */
- (BOOL)prepareXCodeSupportProject
{
    XCodeSupportProjectName    = [NSString stringWithFormat:@"%@.xcodeproj/", currentProjectName];
    XCodeTemplatePBXPath       = [[NSBundle mainBundle] pathForResource:@"project.pbxproj" ofType:@"sample"];
    XCodeSupportProject        = [NSURL URLWithString:XCodeSupportProjectName relativeToURL:currentProjectURL];
    XCodeSupportProjectSources = [NSURL URLWithString:@".XcodeSupport/" relativeToURL:currentProjectURL];
    XCodeSupportPBXPath        = [NSString stringWithFormat:@"%@/project.pbxproj", [XCodeSupportProject path]];
    PBXModifierScriptPath      = [[NSBundle mainBundle] pathForResource:@"pbxprojModifier" ofType:@"py"];


    //[fm removeItemAtURL:XCodeSupportProjectSources error:nil];
    //[fm removeItemAtURL:XCodeSupportProject error:nil];

    // create the template project if it doesn't exist
    if (![fm fileExistsAtPath:[XCodeSupportProjectSources path]])
    {
        NSLog(@"prepareXCodeSupportProject: Xcode support folder created at: %@", [XCodeSupportProject path]);
        [fm createDirectoryAtPath:[XCodeSupportProject path] withIntermediateDirectories:YES attributes:nil error:nil];

        DLog(@"prepareXCodeSupportProject: Copying project.pbxproj from %@ to %@", XCodeTemplatePBXPath, [XCodeSupportProject path]);
        [fm copyItemAtPath:XCodeTemplatePBXPath toPath:XCodeSupportPBXPath error:nil];

        DLog(@"prepareXCodeSupportProject: Reading the content of the project.pbxproj");
        NSMutableString *PBXContent = [NSMutableString stringWithContentsOfFile:XCodeSupportPBXPath encoding:NSUTF8StringEncoding error:nil];

        [PBXContent writeToFile:XCodeSupportPBXPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        DLog(@"prepareXCodeSupportProject: PBX file adapted to the project");

        [self createXcodeSupportProjectSourcesDirIfNecessary];
        return NO;
    }

    [self createXcodeSupportProjectSourcesDirIfNecessary];
    return YES;
}

/*!
 Create the .XcodeSupport/Sources folder if necessary.
 */
- (void)createXcodeSupportProjectSourcesDirIfNecessary
{
    if ([fm fileExistsAtPath:[XCodeSupportProjectSources path]])
        return;

    DLog(@"createXcodeSupportProjectSourcesDirIfNecessary: Creating source folder %@", [XCodeSupportProjectSources path]);
    [fm createDirectoryAtPath:[XCodeSupportProjectSources path] withIntermediateDirectories:YES attributes:nil error:nil];
}

/*!
 Initialize the creation of the .XcodeSupport project. This
 Operation is threaded
 @param arguments Thread arguments (not used)
 @param shouldNotify is YES, XCCDidPopulateProjectNotification will be send
 */
- (void)populateXCodeProject:(NSNumber *)shouldNotify
{
    if ([shouldNotify boolValue])
        [delegate performSelector:@selector(growlWithTitle:message:) withObject:@"Loading project" withObject:[currentProjectURL path]];

    NSArray *subdpaths = [fm subpathsAtPath:[currentProjectURL path]];

    for (NSString *p in subdpaths)
    {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", [currentProjectURL path], p];

        BOOL isDir = NO;
        [fm fileExistsAtPath:filePath isDirectory:&isDir];

        if (isDir || ![self isObjJFile:filePath] || [self isPathMatchingIgnoredPaths:filePath])
            continue;

        NSURL *eventualShadow = [self shadowHeaderURLForSourceURL:[NSURL fileURLWithPath:filePath]];

        if (![fm fileExistsAtPath:[eventualShadow path]])
        {
            DLog(@"populateXCodeProject: Computing missing shadow file for %@", filePath);
            [self handleFileModification:filePath notify:NO];
        }
    }

    if ([shouldNotify boolValue])
    {
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:currentProjectURL, @"URL", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:XCCDidPopulateProjectNotification object:self userInfo:info];
    }
}

/*!
 Start all needed processes for listening to a given path
 @param path The folder path to listen to
 */
- (void)listenProjectAtPath:(NSString *)path
{
    NSMutableString *tempName = [NSMutableString stringWithString:[path lastPathComponent]];

    currentProjectURL = [NSURL fileURLWithPath:path];

    [tempName replaceOccurrencesOfString:@" "
                              withString:@"_"
                                 options:NSCaseInsensitiveSearch
                                   range:NSMakeRange(0, [tempName length])];
    currentProjectName = [NSString stringWithString:tempName];

    [self computeIgnoredPaths];

    BOOL isProjectReady = [self prepareXCodeSupportProject];

    [NSThread detachNewThreadSelector:@selector(populateXCodeProject:) toTarget:self withObject:[NSNumber numberWithBool:!isProjectReady]];

    [self initializeEventStreamWithPath:[currentProjectURL path]];

    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:path, @"path", [NSNumber numberWithInt:(isProjectReady) ? 1 : 0], @"ready", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:XCCListeningStartNotification object:self userInfo:info];

    [[NSUserDefaults standardUserDefaults] setObject:[currentProjectURL path] forKey:@"LastOpenedPath"];
}


#pragma mark - Event Stream

/*!
 Initializes the FSEvent stream
 @param aPath the path of the folder to listen
 */
- (void)initializeEventStreamWithPath:(NSString*)aPath
{
    if ([self isListening])
        return;

    [self stopEventStream];

    NSMutableArray *pathsToWatch = [NSMutableArray arrayWithObject:aPath];
    void *appPointer = (void *)self;
    FSEventStreamContext context = {0, appPointer, NULL, NULL, NULL};
    CFTimeInterval latency = 2.0;
    FSEventStreamCreateFlags flags = 0;

    if (supportsFileBasedListening)
    {
        DLog(@"initializeEventStreamWithPath: Initializing the FSEventStream at file level (clean)");
        flags = kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagFileEvents;
    }
    else
    {
        NSLog(@"Initializing the FSEventStream at folder level (dirty)");
        flags = kFSEventStreamCreateFlagUseCFTypes;
    }

    // add symlinked directories
    NSArray *fileList = [fm contentsOfDirectoryAtPath:aPath error:nil];

    for (NSString *node in fileList)
    {
        NSDictionary *attributes = [fm attributesOfItemAtPath:aPath error:nil];
        if ([[attributes objectForKey:@"NSFileType"] isEqualTo:NSFileTypeDirectory])
        {
            NSString *subDirectoryPath = [aPath stringByAppendingPathComponent:node];
            NSString *symlinkDestination = [fm destinationOfSymbolicLinkAtPath:subDirectoryPath error:nil];

            if (symlinkDestination)
            {
                [pathsToWatch addObject:subDirectoryPath];
            }
        }
    }

    stream = FSEventStreamCreate(NULL, &fsevents_callback, &context, (CFArrayRef) pathsToWatch,
                                 [lastEventId unsignedLongLongValue], latency, flags);

    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(stream);
    [self setIsListening:YES];
}

/*!
 Stop listening the FSEvent stream if active
 */
- (void)stopEventStream
{
    if (stream)
    {
        FSEventStreamStop(stream);
        FSEventStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        FSEventStreamInvalidate(stream);
        FSEventStreamRelease(stream);
        stream = NULL;
    }

    [self setIsListening:NO];
}

/*!
 Stops and clear the worker
 */
- (void)clear
{
    [self updateUserDefaultsWithLastEventId];
    [self synchronizeUserDefaultsWithDisk];
    currentProjectURL = nil;
    currentProjectName = nil;
    [ignoredFilePaths removeAllObjects];
    [self stopEventStream];
}

/*!
 Choose the API mode according to default
 */
- (void)configure
{
    if (![self supportFileLevelAPI])
    {
        DLog(@"configure: System doesn't support file level API");
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:2] forKey:@"XCCAPIMode"];
    }

    switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"XCCAPIMode"])
    {
        case 0:
            supportsFileBasedListening = [self supportFileLevelAPI] ? YES : NO;
            break;
        case 1:
            supportsFileBasedListening = YES;
            break;
        case 2:
            supportsFileBasedListening = NO;
            break;
    }

    if (supportsFileBasedListening)
    {
        DLog(@"configure: using 10.7+ mode listening (clean)");

        [self setCurrentAPIMode:@"File level (Lion)"];
        [self setIsUsingFileLevelAPI:YES];
        reactToInodeModification = [[NSUserDefaults standardUserDefaults] boolForKey:@"XCCReactMode"];
    }
    else
    {
        DLog(@"configure: using 10.6 mode listening (dirty)");
        reactToInodeModification = NO;
        [self setCurrentAPIMode:@"Folder level (Snow Leopard)"];
        [self setIsUsingFileLevelAPI:NO];
    }
}

/*!
 Update the last event ID. We use a method because
 This is called from outside the class, in the FSEvent callback
 @param eventId the current event ID value
 */
- (void)updateLastEventId:(uint64_t)eventId
{
    lastEventId = [NSNumber numberWithUnsignedLongLong:eventId];
}

/*!
 Updates the user defaults with the last recorded event Id.
 */
- (void)updateUserDefaultsWithLastEventId
{
    if (lastEventId && [lastEventId longLongValue] != 0)
    {
        [[NSUserDefaults standardUserDefaults] setObject:lastEventId forKey:@"lastEventId"];
    }
}

/*!
 Tells the standard user defaults to synchronize with disk.
 */
- (void)synchronizeUserDefaultsWithDisk
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - Shell Helpers

/*!
 Run a NSTask with the given arguments
 @param arguments NSArray containing the NSTask arguments
 @return NSarray containing the return code (int) and the eventual response (string)
 */
- (NSArray *)runTask:(NSArray *)arguments
{
    NSTask *task;
    NSData *stdOut;
    NSString *response;
    NSNumber *status;

    task = [[NSTask alloc] init];

    [task setLaunchPath: @"/bin/bash"];
    [task setArguments: arguments];
    [task setStandardOutput:[NSPipe pipe]];
    [task launch];
    [task waitUntilExit];

    stdOut = [[[task standardOutput] fileHandleForReading] availableData];
    response = [[NSString alloc] initWithData:stdOut encoding:NSUTF8StringEncoding];
    status = [NSNumber numberWithInt:[task terminationStatus]];

    return [NSArray arrayWithObjects:status, response, nil];
}


#pragma mark - Event Handlers

/*!
 Handle a file modification. If it's a .J or XIB or NIB, it will
 perform the according conversion. If it's .xcodecapp-ignore, it will
 update the list of ignored files.
 @param fullPath the full path of the modified file
 @param shouldNotify if YES, Growl notifications will be displayed
 */
- (void)handleFileModification:(NSString*)fullPath notify:(BOOL)shouldNotify
{
    if (![self isXIBFile:fullPath] && ![self isObjJFile:fullPath] && ![self isXCCIgnoreFile:fullPath])
        return;

    if ([self isPathMatchingIgnoredPaths:fullPath] || ![fm fileExistsAtPath:fullPath])
        return;

    DLog(@"handleFileModification:notify: Parsing modified file: %@", fullPath);

    NSArray *arguments = nil;
    NSArray *PBXArguments = nil;
    NSString *successTitle = nil;
    NSString *successMsg = nil;
    NSString *response = nil;
    NSNumber *status = [NSNumber numberWithInt:0];
    NSString *splitPath = [fullPath substringFromIndex:[[currentProjectURL path] length] + 1];
    NSURL *encodedURL = [NSURL URLWithString:[fullPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *shadowHeaderURL = [self shadowHeaderURLForSourceURL:encodedURL];
    NSURL *shadowImplementationURL = [self shadowImplementationURLForSourceURL:encodedURL];

    DLog(@"handleFileModification:notify: Shadow header path: %@", shadowHeaderURL);
    DLog(@"handleFileModification:notify: Shadow implementation path: %@", shadowImplementationURL);

    [[NSNotificationCenter defaultCenter] postNotificationName:XCCConversionStartNotification object:self];

    if ([self isXIBFile:fullPath])
    {
        arguments = [NSArray arrayWithObjects: @"-c",
                     [NSString stringWithFormat:@"(%@; nib2cib '%@';) 2>&1", profilePath, fullPath],@"",nil];

        successTitle = @"XIB converted";
        successMsg = splitPath;
    }
    else if ([self isObjJFile:fullPath])
    {
        arguments = [NSArray arrayWithObjects: @"-c",
                     [NSString stringWithFormat:@"(%@; objj '%@' '%@' '%@' '%@';) 2>&1",
                      profilePath,
                      parserPath,
                      fullPath,
                      [shadowHeaderURL path],
                      [shadowImplementationURL path]],nil];

        PBXArguments = [NSArray arrayWithObjects: @"-c",
                        [NSString stringWithFormat:@"(%@; python %@ add '%@' '%@' '%@' '%@' '%@') 2>&1",
                         profilePath,
                         PBXModifierScriptPath,
                         XCodeSupportPBXPath,
                         [shadowHeaderURL path],
                         [shadowImplementationURL path],
                         fullPath,
                         [currentProjectURL path]],nil];

        successTitle = @"Objective-J source processed";
        successMsg = splitPath;
    }
    else if ([self isXCCIgnoreFile:fullPath])
    {
        [self computeIgnoredPaths];
        successTitle = @".xcodecapp-ignore processed";
        successMsg = @"Ignored files list updated";
        arguments = nil;
    }

    // Run the task and get the response if needed
    if (arguments)
    {
        DLog(@"handleFileModification:notify: Running conversion task...");
        NSArray *statusInfo = [self runTask:arguments];

        status = [statusInfo objectAtIndex:0];
        response = [statusInfo objectAtIndex:1];

        DLog(@"handleFileModification:notify: Conversion task result/response: %@/%@", status, response);
    }

    if (PBXArguments)
    {
        DLog(@"handleFileModification:notify: Running update PBX task...");
        NSArray *statusInfo = [self runTask:PBXArguments];
        status = [statusInfo objectAtIndex:0];
        response = [statusInfo objectAtIndex:1];
        DLog(@"handleFileModification:notify: Update PBX Task result/response: %@/%@", status, response);
    }

    if ([status intValue] == 0 && shouldNotify)
    {
        [delegate performSelector:@selector(growlWithTitle:message:) withObject:successTitle withObject:successMsg];
    }
    else if (![status intValue] == 0)
    {
        if (response)
            [errorList addObject:response];

        [delegate performSelector:@selector(growlWithTitle:message:) withObject:@"Error processing file" withObject:splitPath];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:XCCConversionStopNotification object:self];
    DLog(@"handleFileModification:notify: Processed: %@", fullPath);
}

/*!
 Handle a file deletion. If it's a .J, it will
 remove the shadowed .h file. If it's .xcodecapp-ignore
 it will reset the list of ignored files.
 @param fullPath the full path of the modified file
 @param shouldNotify if YES, Growl notifications will be displayed
 */
- (void)handleFileRemoval:(NSString*)fullPath
{
    if ([self isPathMatchingIgnoredPaths:fullPath] || [fm fileExistsAtPath:fullPath])
        return;

    NSString *encodedPath = [fullPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    if ([self isObjJFile:fullPath])
        [self cleanUpShadowsRelatedToSourceURL:[NSURL URLWithString:encodedPath]];
    else if ([self isXCCIgnoreFile:fullPath])
        [self computeIgnoredPaths];
}


#pragma mark - Source Files Management

/*!
 Check if given full path is Objective-J file
 @param path the path to check
 @return YES or NO
 */
- (BOOL)isObjJFile:(NSString *)path
{
    return [[[path pathExtension] uppercaseString] isEqual:@"J"];
}

/*!
 Check if given full path is XIB or NIB file
 @param path the path to check
 @return YES or NO
 */
- (BOOL)isXIBFile:(NSString *)path
{
    path = [[path pathExtension] uppercaseString];
    return  [path isEqual:@"XIB"] || [path isEqual:@"NIB"];
}

/*!
 Check if given full path is the .xcodecapp-ignore file
 @param path the path to check
 @return YES or NO
 */
- (BOOL)isXCCIgnoreFile:(NSString *)path
{
    path = [path lastPathComponent];
    return [path isEqual:@".xcodecapp-ignore"];
}


#pragma mark - Shadow Files Management

/*!
 Compute the mirorred (shadow) header file name for a given path
 @param aSourceURL the origin path
 @return NSURL representing the shadow URL for the header file
 */
- (NSURL *)shadowHeaderURLForSourceURL:(NSURL*)aSourceURL
{
    if (!aSourceURL)
        [NSException raise:NSInvalidArgumentException format:@"shadowHeaderURLForSourceURL: aSource URL must not be null"];

    NSMutableString *flattenedPath = [NSMutableString stringWithString:[aSourceURL path]];

    // Replace "_" with a substring that is unlikely to be in a filename
    [flattenedPath replaceOccurrencesOfString:@"_"
                                   withString:XCCUnderscoreReplacement
                                      options:0
                                        range:NSMakeRange(0, [flattenedPath length])];

    [flattenedPath replaceOccurrencesOfString:@"/"
                                   withString:@"_"
                                      options:0
                                        range:NSMakeRange(0, [flattenedPath length])];

    DLog(@"shadowHeaderURLForSourceURL: Flattened path: %@", flattenedPath);
    NSString *basename  = [NSString stringWithFormat:@"%@.h", [[flattenedPath stringByDeletingPathExtension] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    return [NSURL URLWithString:basename relativeToURL:XCodeSupportProjectSources];
}

/*!
 Compute the mirorred (shadow) implementation file name for a given path
 @param aSourceURL the origin path
 @return NSURL representing the shadow URL for the implementation file
 */
- (NSURL *)shadowImplementationURLForSourceURL:(NSURL*)aSourceURL
{
    if (!aSourceURL)
        [NSException raise:NSInvalidArgumentException format:@"shadowImplementationURLForSourceURL: aSource URL must not be null"];

    NSURL *shadowHeaderURL = [self shadowHeaderURLForSourceURL:aSourceURL];
    NSURL *shadowImplPath = [[shadowHeaderURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"m"];

    return shadowImplPath;
}

/*!
 Compute the Cappuccino source file that is related to the given shadow header file URL
 @param aString the origin path
 @return NSURL representing the URL for the related Cappuccino source file
 */
- (NSURL *)sourceURLForShadowName:(NSString *)aString
{
    NSMutableString * unshadowedPath = [NSMutableString stringWithString:aString];

    [unshadowedPath replaceOccurrencesOfString:@"_"
                                    withString:@"/"
                                       options:0
                                         range:NSMakeRange(0, [unshadowedPath length])];

    [unshadowedPath replaceOccurrencesOfString:XCCUnderscoreReplacement
                                    withString:@"_"
                                       options:0
                                         range:NSMakeRange(0, [unshadowedPath length])];

    [unshadowedPath replaceOccurrencesOfString:@".h"
                                    withString:@".j"
                                       options:0
                                         range:NSMakeRange(0, [unshadowedPath length])];

    return [NSURL fileURLWithPath:[NSString stringWithString:unshadowedPath]];
}

/*!
 Clean up any shadow files and PBX entries related to given the Cappuccino source file URL
 @param anURL the Cappuccino source file URL
 */
- (void)cleanUpShadowsRelatedToSourceURL:(NSURL *)anURL
{
    NSURL *shadowHeaderURL = [self shadowHeaderURLForSourceURL:anURL];
    NSURL *shadowImplementationURL = [self shadowImplementationURLForSourceURL:anURL];

    DLog(@"cleanUpShadowsRelatedToSourceURL: Removing shadow header file: %@", shadowHeaderURL);
    [fm removeItemAtURL:shadowHeaderURL error:nil];

    DLog(@"cleanUpShadowsRelatedToSourceURL: Removing shadow implementation file: %@", shadowImplementationURL);
    [fm removeItemAtURL:shadowImplementationURL error:nil];

    DLog(@"cleanUpShadowsRelatedToSourceURL:Removing PBX reference task...");
    NSArray *PBXArguments = [NSArray arrayWithObjects: @"-c",
                             [NSString stringWithFormat:@"(%@; python %@ remove '%@' '%@' '%@' '%@' '%@') 2>&1",
                              profilePath,
                              PBXModifierScriptPath,
                              XCodeSupportPBXPath,
                              [shadowHeaderURL path],
                              [shadowImplementationURL path],
                              [anURL path],
                              [currentProjectURL path]],nil];

    NSArray *statusInfo = [self runTask:PBXArguments];
    NSNumber *status = [statusInfo objectAtIndex:0];
    NSString *response = [statusInfo objectAtIndex:1];
    DLog(@"cleanUpShadowsRelatedToSourceURL: PBX Reference removal status/response: %@/%@", status, response);
}

/*!
 Clean the support folder according to files present in given path
 */
- (void)tidyShadowedFiles
{
    NSArray *subpaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[XCodeSupportProjectSources path] error:NULL];

    for (NSString *subpath in subpaths)
    {
        if ([subpath pathExtension] != @".h" || [subpath lastPathComponent] == @"xcc_general_include.h")
            continue;

        NSURL *unshadowed = [self sourceURLForShadowName:subpath];

        if (![fm fileExistsAtPath:[unshadowed path]])
        {
            [self cleanUpShadowsRelatedToSourceURL:unshadowed];

            if (![self supportFileLevelAPI] && [self respondsToSelector:@selector(updateLastModificationDate:forPath:)])
                [self performSelector:@selector(updateLastModificationDate:forPath:) withObject:nil withObject:unshadowed];
        }
    }
}


#pragma mark - XCC Ignore management

/*!
 Compute the ignored paths according to any existing
 .xcodecapp-ignore file
 */
- (void)computeIgnoredPaths
{
    NSString *ignorePath = [NSString stringWithFormat:@"%@/.xcodecapp-ignore", [currentProjectURL path]];
    [ignoredFilePaths removeAllObjects];

    if ([fm fileExistsAtPath:ignorePath])
    {
        NSString *ignoreFileContent = [NSString stringWithContentsOfFile:ignorePath encoding:NSUTF8StringEncoding error:nil];
        NSArray *ignoredPatterns = [ignoreFileContent componentsSeparatedByString:@"\n"];

        for (NSString *pattern in ignoredPatterns)
        {
            if ([pattern length])
                [ignoredFilePaths addObject:pattern];
        }
    }

    [ignoredFilePaths addObject:@"*/.git/*"];
    [ignoredFilePaths addObject:@"*/.svn/*"];
    [ignoredFilePaths addObject:@"*/.hg/*"];
    [ignoredFilePaths addObject:@"*/Frameworks/*"];
    [ignoredFilePaths addObject:@"*/.XcodeSupport/*"];
    [ignoredFilePaths addObject:@"*/Build/*"];
    [ignoredFilePaths addObject:@"*/NS_*.j"];
    [ignoredFilePaths addObject:@"*main.j"];
    [ignoredFilePaths addObject:@"*.xcodeproj/*"];
    [ignoredFilePaths addObject:@"*.DS_Store"];

    NSLog(@"Ignoring file paths: %@", ignoredFilePaths);
}

/*!
 Check is given path should be ignored
 @param aPath the path to check
 @return YES if it should be ignored, NO otherwise
 */
- (BOOL)isPathMatchingIgnoredPaths:(NSString*)aPath
{
    if ([ignoredFilePaths count] == 0)
        return NO;

    for (NSString *ignoredPath in ignoredFilePaths)
    {
        if ([ignoredPath length] == 0)
            continue;

        NSMutableString *regexp = [ignoredPath mutableCopy];

        [regexp replaceOccurrencesOfString:@"/"
                                withString:@"\\/"
                                   options:0
                                     range:NSMakeRange(0, [regexp length])];

        [regexp replaceOccurrencesOfString:@"."
                                withString:@"\\."
                                   options:0
                                     range:NSMakeRange(0, [regexp length])];

        [regexp replaceOccurrencesOfString:@"*"
                                withString:@".*"
                                   options:0
                                     range:NSMakeRange(0, [regexp length])];

        [regexp replaceOccurrencesOfString:@" "
                                withString:@"\\ "
                                   options:0
                                     range:NSMakeRange(0, [regexp length])];

        NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexp];

        if ([regextest evaluateWithObject:aPath])
            return YES;
    }

    return NO;
}

@end


@implementation TNXCodeCapp (SnowLeopard)

- (void)updateLastModificationDate:(NSDate *)date forPath:(NSString *)path
{
    if (!pathModificationDates)
    {
        pathModificationDates = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"pathModificationDates"] mutableCopy];

        if (!pathModificationDates)
            pathModificationDates = [NSMutableDictionary new];
    }

    if (date)
        [pathModificationDates setObject:[date retain] forKey:path];
    else
        [pathModificationDates removeObjectForKey:path];

    [[NSUserDefaults standardUserDefaults] setObject:pathModificationDates forKey:@"pathModificationDates"];
}

- (NSDate *)lastModificationDateForPath:(NSString *)path
{
    if (!pathModificationDates)
    {
        pathModificationDates = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"pathModificationDates"] mutableCopy];

        if (!pathModificationDates)
            pathModificationDates = [NSMutableDictionary new];
    }

    if ([pathModificationDates valueForKey:path] != nil)
        return [pathModificationDates valueForKey:path];
    else
        return appStartedTimestamp;
}

@end
