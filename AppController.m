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


#import "AppController.h"

void fsevents_callback(ConstFSEventStreamRef streamRef, void *userData, size_t numEvents, 
                       void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[])
{
    AppController *ac = (AppController *)userData;
	size_t i;
	for(i = 0; i < numEvents; i++)
    {
        [ac handleFileModification:[(NSArray *)eventPaths objectAtIndex:i] ignoreDate:NO];
		[ac updateLastEventId:eventIds[i]];
	}
}



@implementation AppController

#pragma mark -
#pragma mark Initialization

- (id)init
{
    self = [super init];

    if (self)
    {
        [GrowlApplicationBridge setGrowlDelegate:@""];
        
        fm                  = [NSFileManager defaultManager];
        modifiedSources     = [NSMutableArray new];
        modifiedXIBs        = [NSMutableArray new];
        ignoredFilePaths    = [NSMutableArray new];
        parserPath          = [[NSBundle mainBundle] pathForResource:@"parser" ofType:@"j"];
    }

	return self;
}

- (void)awakeFromNib
{
	[self registerDefaults];
    [labelCurrentPath setHidden:YES];
    [buttonOpenXCode setEnabled:NO];
    [buttonStop setEnabled:NO];
    [buttonStart setEnabled:YES];
    [spinner setHidden:YES];
	appStartedTimestamp     = [NSDate date];
    pathModificationDates   = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"pathModificationDates"] mutableCopy];
	lastEventId             = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastEventId"];
}

- (void)initializeEventStreamWithPath:(NSString*)aPath
{
    NSArray                 *pathsToWatch   = [NSArray arrayWithObject:aPath];
    void                    *appPointer     = (void *)self;
    FSEventStreamContext    context         = {0, appPointer, NULL, NULL, NULL};
    NSTimeInterval          latency         = 3.0;

	stream = FSEventStreamCreate(NULL, &fsevents_callback, &context, (CFArrayRef) pathsToWatch,
	                             [lastEventId unsignedLongLongValue], (CFAbsoluteTime) latency,kFSEventStreamCreateFlagUseCFTypes);

	FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	FSEventStreamStart(stream);
}

- (void)stopEventStream
{
    if (stream)
    {
        FSEventStreamStop(stream);
        FSEventStreamInvalidate(stream);
        stream = nil;
    }
}

- (void)registerDefaults
{
	NSUserDefaults  *defaults       = [NSUserDefaults standardUserDefaults];
	NSDictionary    *appDefaults    = [NSDictionary
                                       dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLongLong:kFSEventStreamEventIdSinceNow], [NSMutableDictionary new], nil]
                                       forKeys:[NSArray arrayWithObjects:@"lastEventId", @"pathModificationDates", nil]];
	[defaults registerDefaults:appDefaults];
}


#pragma mark -
#pragma mark Notification handlers

- (NSApplicationTerminateReply)applicationShouldTerminate: (NSApplication *)app
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:lastEventId forKey:@"lastEventId"];
	[defaults setObject:pathModificationDates forKey:@"pathModificationDates"];
	[defaults synchronize];
    
    [self stopEventStream];
    
    return NSTerminateNow;
}


#pragma mark -
#pragma mark Utilities

- (void)updateLastModificationDateForPath: (NSString *)path
{
	[pathModificationDates setObject:[NSDate date] forKey:path];
}

- (NSDate*)lastModificationDateForPath: (NSString *)path
{
	if(nil != [pathModificationDates valueForKey:path])
		return [pathModificationDates valueForKey:path];
	else
		return appStartedTimestamp;
}

- (void)updateLastEventId:(uint64_t)eventId
{
	lastEventId = [NSNumber numberWithUnsignedLongLong:eventId];
}

- (void)handleFileModification:(NSString*)path ignoreDate:(BOOL)shouldIgnoreDate
{
    if ([self isPathMatchingIgnoredPaths:path])
        return;

	NSArray *contents = [fm contentsOfDirectoryAtPath:path error:NULL];

	for(NSString *node in contents)
    {
        NSString        *fullPath       = [NSString stringWithFormat:@"%@/%@", path, node];
        NSDictionary    *fileAttributes = [fm attributesOfItemAtPath:fullPath error:NULL];
		NSDate          *fileModDate    = [fileAttributes objectForKey:NSFileModificationDate];
            
        if(shouldIgnoreDate || [fileModDate compare:[self lastModificationDateForPath:path]] == NSOrderedDescending)
        {
            if ([self isObjJFile:fullPath])
				[modifiedSources addObject:fullPath];
            if ([self isXIBFile:fullPath])
            {
                NSLog(@"nib2cib %@", fullPath);
                int ret = system([[NSString stringWithFormat:@"source ~/.bash_profile; nib2cib %@;", fullPath] UTF8String]);
                if (ret == 0)
                {
                    if (!shouldIgnoreDate)
                        [GrowlApplicationBridge notifyWithTitle:[fullPath lastPathComponent]
                                                    description:@"The XIB file has been converted"
                                               notificationName:@"DefaultNotifications"
                                                       iconData:nil
                                                       priority:0
                                                       isSticky:NO
                                                   clickContext:nil];

                }
                else
                    NSLog(@"Error in conversion: return code is %d", ret);
            }
            if ([self isObjJFile:fullPath])
            {
                NSString *shadowPath    = [[self shadowURLForSourceURL:[NSURL URLWithString:fullPath]] path];
                NSString *command       = [NSString stringWithFormat:@"source ~/.bash_profile; objj %@ %@ %@;", parserPath, fullPath, shadowPath];
                
                NSLog(@"%@", command);
                
                int ret = system([command UTF8String]);
                if (ret == 0)
                {
                    if (!shouldIgnoreDate)
                        [GrowlApplicationBridge notifyWithTitle:[fullPath lastPathComponent]
                                                    description:@"The Objective-J file has been converted"
                                               notificationName:@"DefaultNotifications"
                                                       iconData:nil
                                                       priority:0
                                                       isSticky:NO
                                                   clickContext:nil];

                }
                else
                    NSLog(@"Error in conversion: return code is %d", ret);
            }
        }
	}

	[self updateLastModificationDateForPath:path];
}

- (BOOL)isObjJFile:(NSString *)path
{
    return [[[path pathExtension] uppercaseString] isEqual:@"J"];
}

- (BOOL)isXIBFile:(NSString *)path
{
    return [[[path pathExtension] uppercaseString] isEqual:@"XIB"];
}

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
        NSLog(@"XCode support folder created at: %@", [XCodeSupportProject path]);
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
                                    withString:[currentProjectURL path]
                                       options:NSCaseInsensitiveSearch 
                                         range:NSMakeRange(0, [PBXContent length])];

        [PBXContent writeToFile:XCodeSupportPBXPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        NSLog(@"PBX file adapted to the project");
        
        NSLog(@"Creating source folder");
        [fm createDirectoryAtPath:[XCodeSupportProjectSources path] withIntermediateDirectories:YES attributes:nil error:nil];
        
        
        [NSThread detachNewThreadSelector:@selector(populateXCodeProject:)toTarget:self withObject:nil];
        return NO;
    } 
    return YES;
}

- (void)populateXCodeProject:(id)argement
{
    [GrowlApplicationBridge notifyWithTitle:[[currentProjectURL path] lastPathComponent]
                                description:@"Loading of your project is running..."
                           notificationName:@"DefaultNotifications"
                                   iconData:nil
                                   priority:0
                                   isSticky:NO
                               clickContext:nil];
    
    [self handleFileModification:[NSString stringWithFormat:@"%@", [currentProjectURL path]] ignoreDate:YES];
    NSArray *subdirs = [fm subpathsAtPath:[currentProjectURL path]];
    for (NSString *p in subdirs)
        [self handleFileModification:[NSString stringWithFormat:@"%@/%@", [currentProjectURL path], p] ignoreDate:YES];
    
    [labelStatus setStringValue:@"XCodeCapp is running"];
    [buttonOpenXCode setEnabled:YES];
    [buttonStop setEnabled:YES];
    [buttonStart setEnabled:NO];
    [spinner setHidden:YES];
    
    [GrowlApplicationBridge notifyWithTitle:[[currentProjectURL path] lastPathComponent]
                                description:@"Your project has been loaded successfully!"
                           notificationName:@"DefaultNotifications"
                                   iconData:nil
                                   priority:0
                                   isSticky:NO
                               clickContext:nil];

}

- (NSURL*)shadowURLForSourceURL:(NSURL*)aSourceURL
{
    NSMutableString *flattenedPath = [NSMutableString stringWithString:[aSourceURL path]];
    
    [flattenedPath replaceOccurrencesOfString:@"/" 
                                   withString:@"_"
                                      options:NSCaseInsensitiveSearch 
                                        range:NSMakeRange(0, [[aSourceURL path] length])];
    
    NSString *basename  = [NSString stringWithFormat:@"%@.h", [flattenedPath stringByDeletingPathExtension]];
    
    return [NSURL URLWithString:basename relativeToURL:XCodeSupportProjectSources];
}

- (void)computeIgnoredPaths
{
    NSString *ignorePath = [NSString stringWithFormat:@"%@/.xcodecapp-ignore", [currentProjectURL path]];
    
    if (![fm fileExistsAtPath:ignorePath])
        return;

    NSString *ignoreFileContent = [NSString stringWithContentsOfFile:ignorePath encoding:NSUTF8StringEncoding error:nil];
    ignoredFilePaths = [NSMutableArray arrayWithArray:[ignoreFileContent componentsSeparatedByString:@"\n"]];

    NSLog(@"ignored file paths are: %@", ignoredFilePaths);
}

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


#pragma mark -
#pragma mark Actions

- (IBAction)chooseFolder:(id)aSender
{
    [spinner setHidden:NO];
    [spinner startAnimation:nil];
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setPrompt:@"Choose folder"];
    [openPanel setCanChooseFiles:NO];
    
    [openPanel runModal];
    
    currentProjectURL = [openPanel directoryURL];
    currentProjectName = [[openPanel directoryURL] lastPathComponent];
    
    [self computeIgnoredPaths];
    [self initializeEventStreamWithPath:[currentProjectURL path]];
    
    BOOL isProjectReady = [self prepareXCodeSupportProject];
    
    [labelPath setStringValue:[currentProjectURL path]];
    [labelCurrentPath setHidden:NO];
    [buttonStart setEnabled:NO];
    
    if (isProjectReady)
    {
        [spinner setHidden:YES];
        [buttonStop setEnabled:YES];
        [buttonOpenXCode setEnabled:YES];
        [labelStatus setStringValue:@"XCodeCapp is running"];
    }
        
    else
        [labelStatus setStringValue:@"XCodeCapp is loading project..."];
}

- (IBAction)stopListener:(id)aSender
{
    currentProjectURL = nil;
    currentProjectName = nil;
    [ignoredFilePaths removeAllObjects];
    [labelPath setStringValue:@""];
    [labelCurrentPath setHidden:YES];
    [buttonOpenXCode setEnabled:NO];
    [buttonStop setEnabled:NO];
    [buttonStart setEnabled:YES];
    [labelStatus setStringValue:@"XCodeCapp is not running"];
    [self stopEventStream];
}

- (IBAction)openXCode:(id)aSender
{
    if (!currentProjectURL)
        return;
    
    system([[NSString stringWithFormat:@"open %@", [XCodeSupportProject path ]] UTF8String]);
}


#pragma mark -
#pragma mark Delegates

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    [mainWindow makeKeyAndOrderFront:nil];

    return YES;
}

@end
