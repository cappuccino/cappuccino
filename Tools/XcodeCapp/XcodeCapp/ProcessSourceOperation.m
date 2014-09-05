//
//  ProcessSourceOperation.m
//  XcodeCapp
//
//  Created by Aparajita on 4/27/13.
//  Copyright (c) 2013 Cappuccino Project. All rights reserved.
//

#import "ProcessSourceOperation.h"
#import "Notifications.h"
#import "XcodeCapp.h"


@interface ProcessSourceOperation ()

@property XcodeCapp *xcc;
@property NSNumber *projectId;
@property NSString *sourcePath;
@property NSString *projectPath;

@end


@implementation ProcessSourceOperation

- (id)initWithXCC:(XcodeCapp *)xcc projectId:(NSNumber *)projectId sourcePath:(NSString *)sourcePath
{
    self = [super init];

    if (self)
    {
        self.xcc = xcc;
        self.projectId = projectId;
        self.sourcePath = sourcePath;
        self.projectPath = xcc.projectPath;
    }

    return self;
}

- (void)main
{
    if (self.isCancelled)
        return;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    NSDictionary *info = @{ @"projectId":self.projectId, @"path":self.sourcePath };
    [center postNotificationName:XCCConversionDidStartNotification object:self userInfo:info];

    DDLogVerbose(@"Conversion started: %@", self.sourcePath);

    NSString *launchPath = nil;
    NSArray *arguments = nil;
    NSString *response = nil;
    NSString *projectRelativePath = [self.sourcePath substringFromIndex:self.projectPath.length + 1];
    NSString *notificationTitle = nil;
    NSString *notificationMessage = projectRelativePath.lastPathComponent;

    if ([self.xcc isXibFile:self.sourcePath])
    {
        launchPath = self.xcc.executablePaths[@"nib2cib"];
        arguments = @[
                        @"--no-colors",
                        self.sourcePath
                    ];

        notificationTitle = @"Xib converted";
    }
    else if ([self.xcc isObjjFile:self.sourcePath])
    {
        launchPath = self.xcc.executablePaths[@"objj"];
        arguments = @[
                        self.xcc.parserPath,
                        self.projectPath,
                        self.sourcePath
                    ];

        notificationTitle = @"Objective-J source processed";
    }
    else if ([self.xcc isXCCIgnoreFile:self.sourcePath])
    {
        if (self.isCancelled)
            return;

        [self.xcc performSelectorOnMainThread:@selector(computeIgnoredPaths) withObject:nil waitUntilDone:NO];
        
        notificationTitle = @"Parsed .xcodecapp-ignore";
        notificationMessage = @"Ignored paths updated";
    }

    // Run the task and get the response if needed
    NSInteger status = 0;
    
    if (arguments)
    {
        if (self.isCancelled)
            return;

        DDLogVerbose(@"Running processing task: %@", launchPath);
        
        NSDictionary *taskResult = [self.xcc runTaskWithLaunchPath:launchPath
                                                         arguments:arguments
                                                        returnType:kTaskReturnTypeAny];

        status = [taskResult[@"status"] intValue];
        response = taskResult[@"response"];

        DDLogInfo(@"Processed %@: [%ld, %@]", self.sourcePath, status, status ? response : @"");

        if (self.isCancelled)
            return;

        if (status != 0)
        {
            if ([self.xcc isXibFile:self.sourcePath])
            {
                if (response.length == 0)
                    response = @"An unspecified error occurred";

                notificationTitle = @"Error converting xib";
                NSString *message = [NSString stringWithFormat:@"%@\n%@", self.sourcePath.lastPathComponent, response];
                
                NSDictionary *info =
                    @{
                        @"projectId":self.projectId,
                        @"message":message,
                        @"path":self.sourcePath,
                        @"status":taskResult[@"status"]
                    };

                if (self.isCancelled)
                    return;
                
                [center postNotificationName:XCCConversionDidGenerateErrorNotification object:self userInfo:info];
            }
            else
            {
                notificationTitle = [(status == XCCStatusCodeError ? @"Error" : @"Warning") stringByAppendingString:@" parsing Objective-J source"];

                @try
                {
                    NSArray *errors = [response propertyList];

                    for (NSDictionary *error in errors)
                    {
                        [self postErrorNotificationForPath:error[@"path"] line:[error[@"line"] intValue] message:error[@"message"] status:status];
                    }
                }
                @catch (NSException *exception)
                {
                    [self postErrorNotificationForPath:self.sourcePath line:0 message:response status:status];
                }
            }
            
            if ([self.xcc shouldShowErrorNotification])
                [self notifyUserWithTitle:notificationTitle message:notificationMessage];
        }
        else if (!self.xcc.isLoadingProject)
        {
            BOOL showFinalNotification = YES;
            
            if ([self.xcc shouldProcessWithCappLint])
            {
                showFinalNotification = [self.xcc checkCappLintForPath:[NSArray arrayWithObject:self.sourcePath]];

                if (!showFinalNotification)
                    [self.xcc showCappLintErrors];
            }
                
            if (showFinalNotification)
                [self notifyUserWithTitle:notificationTitle message:notificationMessage];
        }
    }

    if (!self.isCancelled)
    {
        DDLogVerbose(@"Conversion ended: %@", self.sourcePath);

        [center postNotificationName:XCCConversionDidEndNotification object:self userInfo:@{ @"projectId":self.projectId, @"path":self.sourcePath }];
    }
}

- (void)postErrorNotificationForPath:(NSString *)path line:(int)line message:(NSString *)message status:(NSInteger)status
{
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 path, @"path",
                                 [NSNumber numberWithInt:line], @"line",
                                 [NSNumber numberWithInteger:status], @"status",
                                 nil];

    info[@"projectId"] = self.projectId;
    info[@"message"] = [NSString stringWithFormat:@"Compilation issue: %@, line %d\n%@", [self.sourcePath lastPathComponent], 0, message];

    if (self.isCancelled)
        return;

    [[NSNotificationCenter defaultCenter] postNotificationName:XCCConversionDidGenerateErrorNotification object:self userInfo:info];
}

- (void)notifyUserWithTitle:(NSString *)title message:(NSString *)message
{
    NSDictionary *info = @{ @"projectId":self.projectId, @"title":title, @"message":message };

    if (self.isCancelled)
        return;

    // nib2cib can take a while to run, show a message while the conversion is happening
    [self.xcc wantUserNotificationWithInfo:info];
}

@end
