//
//  XCCPbxCreationOperation.m
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 6/2/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import "XCCPPXOperation.h"
#import "XCCCappuccinoProject.h"
#import "XCCTaskLauncher.h"

NSString * const XCCPBXOperationDidStartNotification = @"XCCPbxCreationDidStartNotification";
NSString * const XCCPbxCreationGenerateErrorNotification = @"XCCPbxCreationDidGenerateErrorNotification";
NSString * const XCCPBXOperationDidEndNotification = @"XCCPbxCreationDidEndNotification";


@implementation XCCPPXOperation

#pragma mark - Initialization

- (instancetype)initWithCappuccinoProject:(XCCCappuccinoProject *)aCappuccinoProject taskLauncher:(XCCTaskLauncher*)aTaskLauncher
{
    if (self = [super initWithCappuccinoProject:aCappuccinoProject taskLauncher:aTaskLauncher])
    {
        self.operationDescription       = self.cappuccinoProject.projectPath;
        self.operationName              = @"Updating the Xcode project";

        self->PBXOperations             = [@{} mutableCopy];
        self->PBXOperations[@"add"]     = [@[] mutableCopy];
        self->PBXOperations[@"remove"]  = [@[] mutableCopy];
    }
    
    return self;
}


#pragma mark - PBX Operations

- (void)registerPathsToAddInPBX:(NSArray *)paths
{
    NSMutableArray *finalPaths = [@[] mutableCopy];

    for (NSString *path in paths)
        if ([XCCCappuccinoProject isObjjFile:path])
            [finalPaths addObject:path];

    [self->PBXOperations[@"add"] addObjectsFromArray:finalPaths];
}

- (void)registerPathsToRemoveFromPBX:(NSArray *)paths
{
    [self->PBXOperations[@"remove"] addObjectsFromArray:paths];
}


#pragma mark - NSOperation API

- (void)cancel
{
    if (self->task.isRunning)
        [self->task terminate];

    [super cancel];
}


- (void)main
{
    [self dispatchNotificationName:XCCPBXOperationDidStartNotification];

    DDLogVerbose(@"Pbx creation started: %@", self.cappuccinoProject.projectPath);
    
    @try
    {
        BOOL            shouldLaunchTask    = NO;
        NSMutableArray *arguments           = [@[self.cappuccinoProject.PBXModifierScriptPath, @"update", self.cappuccinoProject.projectPath] mutableCopy];

        for (NSString *action in self->PBXOperations)
        {
            NSArray *paths = self->PBXOperations[action];
    
            if (paths.count)
            {
                [arguments addObject:action];
                [arguments addObjectsFromArray:paths];
    
                shouldLaunchTask = YES;
            }

            DDLogVerbose(@"PBX: path to %@ : %@", action, paths);
        }
        
        if (shouldLaunchTask)
        {
            self->task = [self->taskLauncher taskWithCommand:@"python" arguments:arguments];

            NSDictionary *result = [self->taskLauncher runTask:self->task returnType:kTaskReturnTypeStdError];
            
            if ([result[@"status"] intValue] != 0)
            {
                NSMutableDictionary *info  = [self operationInformations];
                info[@"errors"]            = result[@"message"];

                [self dispatchNotificationName:XCCPbxCreationGenerateErrorNotification userInfo:info];
            }
        }
    }
    @catch (NSException *exception)
    {
        [self dispatchNotificationName:XCCPbxCreationGenerateErrorNotification];
        DDLogVerbose(@"Pbx creation failed: %@", exception);
    }
    @finally
    {
        __block XCCPPXOperation *weakOperation = self;
        
        self.completionBlock = ^{
            [weakOperation dispatchNotificationName:XCCPBXOperationDidEndNotification];
        };
    }

    DDLogVerbose(@"Pbx creation ended: %@", self.cappuccinoProject.projectPath);
}

@end
