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
        errorList = [NSMutableArray arrayWithCapacity:10];

		if (!growlDelegateRef)
			growlDelegateRef = [[[PRHEmptyGrowlDelegate alloc] init] autorelease];

        [GrowlApplicationBridge setGrowlDelegate:growlDelegateRef];

        fm                  = [NSFileManager defaultManager];
        modifiedXIBs        = [NSMutableArray new];
        ignoredFilePaths    = [NSMutableArray new];
        parserPath          = [[NSBundle mainBundle] pathForResource:@"parser" ofType:@"j"];

        if([fm fileExistsAtPath:[@"~/.bash_profile" stringByExpandingTildeInPath]])
            _profilePath = [@"source ~/.bash_profile" stringByExpandingTildeInPath];
        else if([fm fileExistsAtPath:[@"~/.profile" stringByExpandingTildeInPath]])
            _profilePath = [@"source ~/.profile" stringByExpandingTildeInPath];
        else if([fm fileExistsAtPath:[@"~/.bashrc" stringByExpandingTildeInPath]])
            _profilePath = [@"source ~/.bashrc" stringByExpandingTildeInPath];
        else if([fm fileExistsAtPath:[@"~/.zshrc" stringByExpandingTildeInPath]])
            _profilePath = [@"source ~/.zshrc" stringByExpandingTildeInPath];
        else
        {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Cannot find any valid profile file"
                            defaultButton:@"Ok"
                          alternateButton:nil
                              otherButton:nil
                informativeTextWithFormat:@"We have checked for ~/.bash_profile, ~/.profile, ~/.bashrc and ~/.zshrc without luck.\n\nYou need to have on of this file to tell XCodeCapp-cocoa where is located nib2cib. Now we gonna try to without sourcing one this file and it may fail.\n\nIf you notice any error or weird behaviour, please look at Mac OS' Console.app for log message and open a ticket."];
            [alert runModal];
             _profilePath = @"";
        }
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

    NSBundle *bundle = [NSBundle mainBundle];

    _iconInactive   = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"xcodecapp-cocoa-icon-inactive" ofType:@"png"]];
    _iconActive     = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"xcodecapp-cocoa-icon-active" ofType:@"png"]];
    [_iconActive setSize:NSMakeSize(14.0, 16.0)];
    [_iconInactive setSize:NSMakeSize(14.0, 16.0)];

    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setMenu:statusMenu];
    [_statusItem setImage:_iconInactive];
    [_statusItem setHighlightMode:YES];
    [statusMenu setDelegate:self];
}

- (void)initializeEventStreamWithPath:(NSString*)aPath
{
    NSArray                 *pathsToWatch   = [NSArray arrayWithObject:aPath];
    void                    *appPointer     = (void *)self;
    FSEventStreamContext    context         = {0, appPointer, NULL, NULL, NULL};
    NSTimeInterval          latency         = 5.0;

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
        NSString        *splitedPath    = [NSString stringWithFormat:@"%@/%@", [[fullPath pathComponents] objectAtIndex:[[fullPath pathComponents] count] - 2], [fullPath lastPathComponent]];
        NSDictionary    *fileAttributes = [fm attributesOfItemAtPath:fullPath error:NULL];
		NSDate          *fileModDate    = [fileAttributes objectForKey:NSFileModificationDate];

        if(shouldIgnoreDate || [fileModDate compare:[self lastModificationDateForPath:path]] == NSOrderedDescending)
        {
            //Prepare the shell
            NSTask *task;
            task = [[NSTask alloc] init];
            [task setLaunchPath: @"/bin/bash"];
            NSArray *arguments;
            NSString *successMsg;

            if ([self isXIBFile:fullPath] || [self isObjJFile:fullPath])
            {
                if ([self isXIBFile:fullPath])
                {

                    NSLog(@"running command nib2cib %@", fullPath);

                    //Create the nib2cib task
                    arguments = [NSArray arrayWithObjects: @"-c",
                                 [NSString stringWithFormat:@"(%@; nib2cib '%@';) 2>&1", _profilePath, fullPath],@"",nil];
                    successMsg = @"The XIB file has been converted";
                }
                else if ([self isObjJFile:fullPath])
                {
                    NSLog(@"Full path string is: %@", [fullPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
                    NSString *shadowPath = [[self shadowURLForSourceURL:[NSURL URLWithString:[fullPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]] path];
                    NSLog(@"running command objj %@", shadowPath);
                    //Create the objj task
                    arguments = [NSArray arrayWithObjects: @"-c",
                                 [NSString stringWithFormat:@"(%@; objj '%@' '%@' '%@';) 2>&1", _profilePath, parserPath, fullPath, shadowPath],@"",nil];
                    successMsg = @"The Objective-J file has been converted";
                }

                //Run the task and get the response
                [task setArguments: arguments];
                [task setStandardOutput:[NSPipe pipe]];

                [_statusItem setTitle:@"..."];
                [task launch];
                [task waitUntilExit];

                NSData *stdOut;
                stdOut = [[[task standardOutput] fileHandleForReading] availableData];
                NSString *response;
                response = [[NSString alloc] initWithData:stdOut
                                                 encoding:NSUTF8StringEncoding];

                NSLog(@"response was\n%@", response);

                [_statusItem setTitle:@""];
                if ([task terminationStatus] == 0)
                {
                    if (!shouldIgnoreDate)
                    {
                        [GrowlApplicationBridge notifyWithTitle:splitedPath
                                                    description:successMsg
                                               notificationName:@"DefaultNotifications"
                                                       iconData:nil
                                                       priority:0
                                                       isSticky:NO
                                                   clickContext:nil];
                    }

                }
                else
                {
                    NSLog(@"Error in conversion: return message is %@", response);

                    //if (![GrowlApplicationBridge isGrowlRunning])
                    {
                        [errorList addObject:response];
                        [self updateErrorTable];
                    }
                }
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
    path = [[path pathExtension] uppercaseString];
    return  [path isEqual:@"XIB"] || [path isEqual:@"NIB"];
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
    return YES;
}

- (void)populateXCodeProject:(id)argement
{
    [GrowlApplicationBridge notifyWithTitle:[[currentProjectURL path] lastPathComponent]
                                description:@"Loading of project..."
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
    NSLog(@"Flattened path is : %@", flattenedPath);
    [flattenedPath replaceOccurrencesOfString:@"/"
                                   withString:@"_"
                                      options:NSCaseInsensitiveSearch
                                        range:NSMakeRange(0, [[aSourceURL path] length])];

    NSString *basename  = [NSString stringWithFormat:@"%@.h", [[flattenedPath stringByDeletingPathExtension] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

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
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setPrompt:@"Choose Cappuccino project"];
    [openPanel setCanChooseFiles:NO];

    if ([openPanel runModal] != NSFileHandlingPanelOKButton)
        return;

    [spinner setHidden:NO];
    [spinner startAnimation:nil];

    currentProjectURL = [[openPanel URLs] objectAtIndex:0];
    NSMutableString *tempName = [NSMutableString stringWithString:[[[openPanel URLs] objectAtIndex:0] lastPathComponent]];

    [tempName replaceOccurrencesOfString:@" "
                              withString:@"_"
                                 options:NSCaseInsensitiveSearch
                                   range:NSMakeRange(0, [tempName length])];
    currentProjectName = [NSString stringWithString:tempName];

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

    [_statusItem setImage:_iconActive];
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
    [_statusItem setImage:_iconInactive];
}

- (IBAction)openXCode:(id)aSender
{
    if (!currentProjectURL)
        return;

    NSLog(@"Open Xcode project at URL : '%@'", [XCodeSupportProject path]);
    system([[NSString stringWithFormat:@"open \"%@\"", [XCodeSupportProject path]] UTF8String]);
}


- (void)updateErrorTable
{
    [errorsTable reloadData];
    [errorsPanel orderFront:self];
    NSLog(@"update?");
}

- (IBAction)clearErrors:(id)sender
{
    [errorList removeAllObjects];
    [errorsTable reloadData];
}
#pragma mark -
#pragma mark Delegates

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    [mainWindow makeKeyAndOrderFront:nil];

    return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem
{
    if (aMenuItem == menuItemStart)
        return !currentProjectURL;
    if ((aMenuItem == menuItemStop) || (aMenuItem == menuItemOpenXCode))
        return !!currentProjectURL;

    return YES;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [errorList count];
}
- (id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [errorList objectAtIndex:row];
}

- (void)tableViewColumnDidResize:(NSNotification *)tableView
{
    [errorsTable noteHeightOfRowsWithIndexesChanged:
        [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [errorList count])]];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(int)aRow
{
    // Get column you want - first in this case:
    NSTableColumn *tabCol = [[tableView tableColumns] objectAtIndex:0];
    float width = [tabCol width];
    NSRect r = NSMakeRect(0,0,width,1000.0);
    NSCell *cell = [tabCol dataCellForRow:aRow];
    NSString *content = [errorList objectAtIndex:aRow];
    [cell setObjectValue:content];
    float height = [cell cellSizeForBounds:r].height;

    if (height <= 0)
        height = 16.0; // Ensure miniumum height is 16.0

    return height;

}
@end
