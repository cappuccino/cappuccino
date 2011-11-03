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

#import "TNXCodeCapp.h"

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
        ignoredFilePaths = [NSMutableArray new];
        parserPath = [[NSBundle mainBundle] pathForResource:@"parser" ofType:@"j"];
        lastEventId = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastEventId"];
        
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
            NSAlert *alert = [NSAlert alertWithMessageText:@"Cannot find any valid profile file"
                                             defaultButton:@"Ok"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"We have checked for ~/.bash_profile, ~/.profile, ~/.bashrc and ~/.zshrc without luck.\n\nYou need to have on of this file to tell XCodeCapp-cocoa where is located nib2cib. Now we gonna try to without sourcing one this file and it may fail.\n\nIf you notice any error or weird behaviour, please look at Mac OS' Console.app for log message and open a ticket."];
            [alert runModal];
            profilePath = @"";
        }
    }
    
    return self;
}

- (void)start
{        
    NSString *lastOpenedPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastOpenedPath"];
    if (lastOpenedPath)
    {
        if ([fm fileExistsAtPath:lastOpenedPath])
        {
            NSString *message = [NSString stringWithFormat:@"Resuming project %@", [lastOpenedPath lastPathComponent], nil];
            
            [delegate performSelector:@selector(growlWithTitle:message:) withObject:@"Resume project" withObject:message];
            [self listenProjectAtPath:[NSString stringWithFormat:@"%@/", lastOpenedPath]];
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastOpenedPath"];
        }
    }
}

/*!
 Initializes the FSEvent stream
 @param aPath the path of the folder to listen
 */
- (void)initializeEventStreamWithPath:(NSString*)aPath
{
    NSArray *pathsToWatch = [NSArray arrayWithObject:aPath];
    void *appPointer = (void *)self;
    FSEventStreamContext context = {0, appPointer, NULL, NULL, NULL};
    NSTimeInterval latency = 2.0;
    
    stream = FSEventStreamCreate(NULL, &fsevents_callback, &context, (CFArrayRef) pathsToWatch,
                                 [lastEventId unsignedLongLongValue], (CFAbsoluteTime) latency, kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagNoDefer | 0x00000010 );
    
    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(stream);
}

/*!
 Stop listening the FSEvent stream if active
 */
- (void)stopEventStream
{
    if (stream)
    {
        FSEventStreamStop(stream);
        FSEventStreamInvalidate(stream);
        stream = nil;
    }
}

/*!
 Stops and clear the worker
 */
- (void)clear
{
    currentProjectURL = nil;
    currentProjectName = nil;
    [ignoredFilePaths removeAllObjects];
    [self stopEventStream];
}


#pragma mark -
#pragma mark Utilities

/*!
 Update the last event ID. We use a method because
 This is called from outside the class, in the FSEvent callback
 @param eventId the current event ID value
 */
- (void)updateLastEventId:(uint64_t)eventId
{
    lastEventId = [NSNumber numberWithUnsignedLongLong:eventId];
    [[NSUserDefaults standardUserDefaults] setObject:lastEventId forKey:@"lastEventId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

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

/*!
 Handle a file modification. If it's a .J or XIB or NIB, it will
 perform the according conversion. If it's .xcodecapp-ignore, it will
 update the list of ignored files.
 @param fullPath the full path of the modified file
 @param shouldNotify if YES, Growl notifications will be displayed
 */
- (void)handleFileModification:(NSString*)fullPath notify:(BOOL)shouldNotify
{
    if ([self isPathMatchingIgnoredPaths:fullPath] || ![fm fileExistsAtPath:fullPath])
        return;
    
    NSLog(@"Starting to parse file modification %@", fullPath);
    
    NSArray *arguments;
    NSString *successMsg;
    NSNumber *status;
    NSString *response;
    NSString *errorTitle;
    NSString *errorMsg;
    NSString *splitedPath = [NSString stringWithFormat:@"%@/%@", [[fullPath pathComponents] objectAtIndex:[[fullPath pathComponents] count] - 2], [fullPath lastPathComponent]];
    NSString *shadowPath = [[self shadowURLForSourceURL:[NSURL URLWithString:[fullPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]] path];
    
    NSLog(@"Shadow path is: %@", shadowPath);
    
    
    if ([self isXIBFile:fullPath] || [self isObjJFile:fullPath] || [self isXCCIgnoreFile:fullPath])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:XCCConversionStartNotification object:self];
        
        if ([self isXIBFile:fullPath])
        {
            NSLog(@"File is XIB file");
            arguments = [NSArray arrayWithObjects: @"-c", [NSString stringWithFormat:@"(%@; nib2cib '%@';) 2>&1", profilePath, fullPath],@"",nil];
            successMsg = @"The XIB file has been converted";
        }
        else if ([self isObjJFile:fullPath])
        {
            NSLog(@"File is J file");
            arguments = [NSArray arrayWithObjects: @"-c", [NSString stringWithFormat:@"(%@; objj '%@' '%@' '%@';) 2>&1", profilePath, parserPath, fullPath, shadowPath],@"",nil];
            successMsg = @"The Objective-J file has been converted";
        }
        else if ([self isXCCIgnoreFile:fullPath])
        {
            NSLog(@"File is .xcodecapp-ignore");
            [self computeIgnoredPaths];
            successMsg = @"Ignored files list updated";
            arguments = nil;
            status = [NSNumber numberWithInt:0];
        }
        
        //Run the task and get the response if needed
        if (arguments)
        {
            NSLog(@"Running task...");
            NSArray *statusInfo = [self runTask:arguments];
            
            status = [statusInfo objectAtIndex:0];
            response = [statusInfo objectAtIndex:1];
            
            NSLog(@"Task result is   : %@", status);
            NSLog(@"Task response is : %@", response);                
        }
        
        
        if ([status intValue] == 0 && shouldNotify)
        {
            [delegate performSelector:@selector(growlWithTitle:message:) withObject:splitedPath withObject:successMsg];
        }
        else if (![status intValue] == 0)
        {
            [errorList addObject:response];
            
            errorTitle = [NSString stringWithFormat:@"ERROR: %@", splitedPath];
            errorMsg = [NSString stringWithFormat:@"Error was: %@.\n\n You may want to check in error list.", response];
            [delegate performSelector:@selector(growlWithTitle:message:) withObject:splitedPath withObject:errorMsg];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:XCCConversionStopNotification object:self];
    }
    
    NSLog(@"Computing done for file %@", fullPath);
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
    
    if ([self isObjJFile:fullPath])
    {
        NSString *shadowPath = [[self shadowURLForSourceURL:[NSURL URLWithString:[fullPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]] path];
        [fm removeItemAtPath:shadowPath error:nil];
        NSLog(@"Removing shadow file %@", shadowPath);
    }
    else if ([self isXCCIgnoreFile:fullPath])
    {
        [self computeIgnoredPaths];
    }
}

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


/*!
 Check if .xCodeSupport needs to be initialized.
 If not needed, check that all J files are mirrored. If no,
 then launch conversion for missing mirrored h files
 @return YES or NO
 */
- (BOOL)prepareXCodeSupportProject
{
    XCodeSupportProjectName    = [NSString stringWithFormat:@"%@.xcodeproj/", currentProjectName];
    XCodeTemplatePBXPath       = [[NSBundle mainBundle] pathForResource:@"project" ofType:@"pbxproj"];
    XCodeSupportFolder         = [NSURL URLWithString:@".xCodeSupport/" relativeToURL:currentProjectURL];
    XCodeSupportProject        = [NSURL URLWithString:XCodeSupportProjectName relativeToURL:XCodeSupportFolder];
    XCodeSupportProjectSources = [NSURL URLWithString:@"Sources/" relativeToURL:XCodeSupportFolder];
    XCodeSupportPBXPath        = [NSString stringWithFormat:@"%@/project.pbxproj", [XCodeSupportProject path]];
    
    //[fm removeItemAtURL:XCodeSupportFolder error:nil];
    
    // create the template project if it doesn't exist
    if (![fm fileExistsAtPath:[XCodeSupportFolder path]])
    {
        NSLog(@"Xcode support folder created at: %@", [XCodeSupportProject path]);
        [fm createDirectoryAtPath:[XCodeSupportProject path] withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSLog(@"Copying project.pbxproj from %@ to %@", XCodeTemplatePBXPath, [XCodeSupportProject path]);
        [fm copyItemAtPath:XCodeTemplatePBXPath toPath:XCodeSupportPBXPath error:nil];
        
        NSLog(@"Reading the content of the project.pbxproj");
        NSMutableString *PBXContent = [NSMutableString stringWithContentsOfFile:XCodeSupportPBXPath encoding:NSUTF8StringEncoding error:nil];
        [PBXContent replaceOccurrencesOfString:@"${CappuccinoProjectName}"
                                    withString:currentProjectName
                                       options:NSCaseInsensitiveSearch
                                         range:NSMakeRange(0, [PBXContent length])];
        [PBXContent replaceOccurrencesOfString:@"${CappuccinoProjectRelativePath}"
                                    withString:@".."
                                       options:NSCaseInsensitiveSearch
                                         range:NSMakeRange(0, [PBXContent length])];
        
        [PBXContent writeToFile:XCodeSupportPBXPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        NSLog(@"PBX file adapted to the project");
        
        NSLog(@"Creating source folder");
        [fm createDirectoryAtPath:[XCodeSupportProjectSources path] withIntermediateDirectories:YES attributes:nil error:nil];
        
        
        [NSThread detachNewThreadSelector:@selector(populateXCodeProject:)toTarget:self withObject:nil];
        return NO;
    }
    else
    {
        NSArray *subdirs = [fm subpathsAtPath:[currentProjectURL path]];
        for (NSString *p in subdirs)
        {
            NSString *path = [NSString stringWithFormat:@"%@/%@", [currentProjectURL path], p];
            NSString *shadow = [[self shadowURLForSourceURL:[NSURL URLWithString:path]] path];
            if ([self isObjJFile:path] && ![fm fileExistsAtPath:shadow] && ![[path lastPathComponent] isEqualToString:@"main.j"])
            {
                NSLog(@"File %@ seems to be new. Computing it.", path);
                [self handleFileModification:path notify:YES];
            }
        }
        return YES;
    }
}

/*!
 Initialize the creation of the .xCodeSupport project. This
 Operation is threaded
 @param arguments Thread arguments (not used)
 */
- (void)populateXCodeProject:(id)arguments
{
    [delegate performSelector:@selector(growlWithTitle:message:) withObject:[[currentProjectURL path] lastPathComponent] withObject:@"Loading of project..."];
    
    [self handleFileModification:[NSString stringWithFormat:@"%@", [currentProjectURL path]] notify:NO];
    NSArray *subdirs = [fm subpathsAtPath:[currentProjectURL path]];
    for (NSString *p in subdirs)
        [self handleFileModification:[NSString stringWithFormat:@"%@/%@", [currentProjectURL path], p] notify:NO];
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:currentProjectURL, @"URL", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:XCCDidPopulateProjectNotification object:self userInfo:info];
}

/*!
 Compute the mirorred (shadow) name for a given path
 @param aSourceURL the origin path
 @return NSURL representing the shadow path
 */
- (NSURL*)shadowURLForSourceURL:(NSURL*)aSourceURL
{
    NSMutableString *flattenedPath = [NSMutableString stringWithString:[aSourceURL path]];
    NSLog(@"Flattened path is : %@", flattenedPath);
    [flattenedPath replaceOccurrencesOfString:@"/"
                                   withString:@"_"
                                      options:NSCaseInsensitiveSearch
                                        range:NSMakeRange(0, [[aSourceURL path] length])];
    
    NSString *basename  = [NSString stringWithFormat:@"%@.h", [[flattenedPath stringByDeletingPathExtension] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    return [NSURL URLWithString:basename relativeToURL:XCodeSupportProjectSources];
}

/*!
 Compute the ignored paths according to any existing
 .xcodecapp-ignore file
 */
- (void)computeIgnoredPaths
{
    NSString *ignorePath = [NSString stringWithFormat:@"%@/.xcodecapp-ignore", [currentProjectURL path]];
    
    if ([fm fileExistsAtPath:ignorePath])
    {
        NSString *ignoreFileContent = [NSString stringWithContentsOfFile:ignorePath encoding:NSUTF8StringEncoding error:nil];
        ignoredFilePaths = [NSMutableArray arrayWithArray:[ignoreFileContent componentsSeparatedByString:@"\n"]];
    }
    else
    {
        [ignoredFilePaths removeAllObjects];
    }
    
    [ignoredFilePaths addObject:@"*.git*"];
    [ignoredFilePaths addObject:@"*.svn*"];
    [ignoredFilePaths addObject:@"*.hg*"];
    [ignoredFilePaths addObject:@"*Frameworks*"];
    [ignoredFilePaths addObject:@"*.xCodeSupport*"];
    [ignoredFilePaths addObject:@"*Build*"];
    
    NSLog(@"ignored file paths are: %@", ignoredFilePaths);
}

/*!
 Check is given path should be ignored
 @param aPath the path to check
 @return YES if it should be ignored, NO otherwise
 */
- (BOOL)isPathMatchingIgnoredPaths:(NSString*)aPath
{
    BOOL isMatching = NO;
    
    for (NSString *ignoredPath in ignoredFilePaths)
    {
        if ([ignoredPath isEqual:@""])
            continue;
        
        NSMutableString *regexp = [NSMutableString stringWithFormat:@"%@/%@", [currentProjectURL path], ignoredPath];
        [regexp replaceOccurrencesOfString:@"/"
                                withString:@"\\/"
                                   options:NSCaseInsensitiveSearch
                                     range:NSMakeRange(0, [regexp length])];
        
        [regexp replaceOccurrencesOfString:@"."
                                withString:@"\\."
                                   options:NSCaseInsensitiveSearch
                                     range:NSMakeRange(0, [regexp length])];
        
        [regexp replaceOccurrencesOfString:@"*"
                                withString:@".*"
                                   options:NSCaseInsensitiveSearch
                                     range:NSMakeRange(0, [regexp length])];
        
        NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexp];
        if ([regextest evaluateWithObject:aPath])
        {
            isMatching = YES;
            
            break;
        }
    }
    
    return isMatching;
}

/*!
 Start all needed processes for listening to a given path
 @param path The folder path to listen to
 */
- (void)listenProjectAtPath:(NSString *)path
{
    NSMutableString *tempName = [NSMutableString stringWithString:[path lastPathComponent]];
    
    currentProjectURL = [NSURL URLWithString:path];
    
    [tempName replaceOccurrencesOfString:@" "
                              withString:@"_"
                                 options:NSCaseInsensitiveSearch
                                   range:NSMakeRange(0, [tempName length])];
    currentProjectName = [NSString stringWithString:tempName];
    
    [self computeIgnoredPaths];
    
    BOOL isProjectReady = [self prepareXCodeSupportProject];
    
    [self initializeEventStreamWithPath:[currentProjectURL path]];
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:path, @"path", [NSNumber numberWithInt:(isProjectReady) ? 1 : 0], @"ready", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:XCCListeningStartNotification object:self userInfo:info];
    
    [[NSUserDefaults standardUserDefaults] setObject:[currentProjectURL path] forKey:@"LastOpenedPath"];
}

@end
