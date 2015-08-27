
//  ProcessSourceOperation.m
//  XcodeCapp
//
//  Created by Aparajita on 4/27/13.
//  Copyright (c) 2013 Cappuccino Project. All rights reserved.
//

#import "XCCSourceProcessingOperation.h"
#import "XCCTaskLauncher.h"

NSString * const XCCConversionDidEndNotification                    = @"XCCConversionDidStopNotification";
NSString * const XCCConversionDidStartNotification                  = @"XCCConversionDidStartNotification";
NSString * const XCCObjjDidStartNotification                        = @"XCCObjjDidStartNotification";
NSString * const XCCObjjDidGenerateErrorNotification                = @"XCCObjjDidGenerateErrorNotification";
NSString * const XCCObjjDidEndNotification                          = @"XCCObjjDidEndNotification";
NSString * const XCCCappLintDidStartNotification                    = @"XCCCappLintDidStartNotification";
NSString * const XCCCappLintDidGenerateErrorNotification            = @"XCCCappLintDidGenerateErrorNotification";
NSString * const XCCCappLintDidEndNotification                      = @"XCCCappLintDidEndNotification";
NSString * const XCCObjj2ObjcSkeletonDidStartNotification           = @"XCCObjj2ObjcSkeletonDidStartNotification";
NSString * const XCCObjj2ObjcSkeletonDidGenerateErrorNotification   = @"XCCObjj2ObjcSkeletonDidGenerateErrorNotification";
NSString * const XCCObjj2ObjcSkeletonDidEndNotification             = @"XCCObjj2ObjcSkeletonDidEndNotification";
NSString * const XCCNib2CibDidStartNotification                     = @"XCCNib2CibDidStartNotification";
NSString * const XCCNib2CibDidGenerateErrorNotification             = @"XCCNib2CibDidGenerateErrorNotification";
NSString * const XCCNib2CibDidEndNotification                       = @"XCCNib2CibDidEndNotification";


@implementation XCCSourceProcessingOperation


#pragma mark - Initialization

- (instancetype)initWithCappuccinoProject:(XCCCappuccinoProject *)aCappuccinoProject taskLauncher:(XCCTaskLauncher*)aTaskLauncher sourcePath:(NSString *)sourcePath
{
    if (self = [super initWithCappuccinoProject:aCappuccinoProject taskLauncher:aTaskLauncher])
    {
        NSString *projectPath       = [NSString stringWithFormat:@"%@/", self.cappuccinoProject.projectPath];

        self.sourcePath             = sourcePath;
        self.operationName          = @"Pending source processing";
        self.operationDescription   = [self.sourcePath stringByReplacingOccurrencesOfString:projectPath withString:@""];
    }

    return self;
}


#pragma mark - Utilities

- (NSMutableDictionary *)operationInformations
{
    NSMutableDictionary *info = [super operationInformations];

    info[@"sourcePath"] = self.sourcePath;

    return info;
}

- (void)_updateOperationInformation
{
    NSString *commandName = self->task.launchPath.lastPathComponent;

    if ([commandName isEqualToString:@"objj2objcskeleton"])
        self.operationName = @"Creating Objective-C Class Pair";

    else if ([commandName isEqualToString:@"nib2cib"])
        self.operationName = @"Converting Interface Files";

    else if ([commandName isEqualToString:@"objj"])
        self.operationName = @"Verifying compilation Warnings";

    else if ([commandName isEqualToString:@"capp_lint"])
        self.operationName = @"Verifying coding style";
    else
        self.operationName = commandName;
}

- (void)_postProcessingErrorNotificationName:(NSString *)notificationName error:(NSString *)errors
{
    if (self.isCancelled)
        return;

    if (errors.length == 0)
        errors = @"An unspecified error occurred";

    NSMutableDictionary *info = [self operationInformations];
    info[@"errors"]           = errors;

    [self dispatchNotificationName:notificationName userInfo:info];
}

- (NSDictionary*)_launchTaskWithCommand:(NSString*)aCommand arguments:(NSArray*)arguments
{
    DDLogVerbose(@"Running processing task: %@ on file: %@", aCommand, self.sourcePath);

    self->task = [self->taskLauncher taskWithCommand:aCommand arguments:arguments];

    [self _updateOperationInformation];

    return [self->taskLauncher runTask:self->task returnType:kTaskReturnTypeAny];
}


#pragma Task Launcher

- (BOOL)launchObjj2ObjcSkeletonCommandForPath:(NSString*)aPath
{
    [self dispatchNotificationName:XCCObjj2ObjcSkeletonDidStartNotification];

    NSString        *targetName = [self.cappuccinoProject flattenedXcodeSupportFileNameForPath:aPath];
    NSArray         *arguments  = @[aPath, self.cappuccinoProject.supportPath, @"-n", targetName];
    NSDictionary    *result     = [self _launchTaskWithCommand:@"objj2objcskeleton" arguments:arguments];
    int             code        = [result[@"status"] intValue];

    if (code != 0)
        [self _postProcessingErrorNotificationName:XCCObjj2ObjcSkeletonDidGenerateErrorNotification error:result[@"response"]];

    [self dispatchNotificationName:XCCObjj2ObjcSkeletonDidEndNotification];

    return code == 0;
}

- (BOOL)launchNib2CibCommandForPath:(NSString*)aPath
{
    [self dispatchNotificationName:XCCNib2CibDidStartNotification];

    NSArray         *arguments  = @[@"--no-colors", self.sourcePath];
    NSDictionary    *result     = [self _launchTaskWithCommand:@"nib2cib" arguments:arguments];
    int             code        = [result[@"status"] intValue];

    if (code != 0)
        [self _postProcessingErrorNotificationName:XCCNib2CibDidGenerateErrorNotification error:result[@"response"]];

    [self dispatchNotificationName:XCCNib2CibDidEndNotification];

    return code == 0;
}

- (BOOL)launchObjjCommandForPath:(NSString*)aPath
{
    [self dispatchNotificationName:XCCObjjDidStartNotification];

    NSArray         *arguments  = @[@"--xml", @"-I", [self.cappuccinoProject objjIncludePath], self.sourcePath];
    NSDictionary    *result     = [self _launchTaskWithCommand:@"objj" arguments:arguments];
    int             code        = [result[@"status"] intValue];

    if (code != 0)
        [self _postProcessingErrorNotificationName:XCCObjjDidGenerateErrorNotification error:result[@"response"]];

    [self dispatchNotificationName:XCCObjjDidEndNotification];

    return code == 0;
}

- (BOOL)launchCappLintCommandForPath:(NSString*)aPath
{
    [self dispatchNotificationName:XCCCappLintDidStartNotification];

    NSString        *baseDirectory  = [NSString stringWithFormat:@"--basedir='%@'", self.cappuccinoProject.projectPath];
    NSArray         *arguments      = @[baseDirectory, self.sourcePath];
    NSDictionary    *result         = [self _launchTaskWithCommand:@"capp_lint" arguments:arguments];
    int             code            = [result[@"status"] intValue];

    if (code != 0)
        [self _postProcessingErrorNotificationName:XCCCappLintDidGenerateErrorNotification error:result[@"response"]];

    [self dispatchNotificationName:XCCCappLintDidEndNotification];

    return code == 0;
}


#pragma mark - NSOperation Protocol

- (void)cancel
{
    if (self->task.isRunning)
        [self->task terminate];

    self.operationName = @"Canceled source processing";

    [super cancel];
}

- (void)main
{
    DDLogVerbose(@"Conversion started: %@", self.sourcePath);

    [self dispatchNotificationName:XCCConversionDidStartNotification];

    @try
    {
        if ([XCCCappuccinoProject isXibFile:self.sourcePath])
        {
            if (self.cappuccinoProject.processNib2Cib)
                [self launchNib2CibCommandForPath:self.sourcePath];
        }
        else if ([XCCCappuccinoProject isObjjFile:self.sourcePath])
        {
            BOOL shouldContinue = YES;

            if (self.cappuccinoProject.processObjj2ObjcSkeleton)
                shouldContinue = [self launchObjj2ObjcSkeletonCommandForPath:self.sourcePath];

            if (shouldContinue &&  self.cappuccinoProject.processObjjWarnings)
                shouldContinue = [self launchObjjCommandForPath:self.sourcePath];

            if (shouldContinue && self.cappuccinoProject.processCappLint)
                [self launchCappLintCommandForPath:self.sourcePath];
        }
    }
    @catch (NSException *exception)
    {
        DDLogVerbose(@"Conversion failed: %@", exception);
    }
    @finally
    {
        __block XCCSourceProcessingOperation *weakOperation = self;
        
        self.completionBlock = ^{
            [weakOperation dispatchNotificationName:XCCConversionDidEndNotification];
        };
    }
	
	DDLogVerbose(@"Conversion ended: %@", self.sourcePath);
}

@end
