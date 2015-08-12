//
//  CappuccinoProjectController.m
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/7/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import "AppDelegate.h"
#import "XCCCappuccinoProjectController.h"
#import "XCCCappuccinoProject.h"
#import "XCCFSEventLogUtils.h"
#import "XCCSourcesFinderOperation.h"
#import "XCCPPXOperation.h"
#import "XCCSourceProcessingOperation.h"
#import "XCCMainController.h"
#import "XCCOperationDataView.h"
#import "XCCOperationError.h"
#import "XCCOperationErrorDataView.h"
#import "XCCOperationErrorHeaderDataView.h"
#import "XCCTaskLauncher.h"
#import "XCCUserDefaults.h"
#import "XcodeProjectCloser.h"
#import "XCCOperationsViewController.h"
#import "XCCErrorsViewController.h"

static FSEventStreamCreateFlags const XCCProjectControllerFSEventFlags = kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagWatchRoot
                                                                    | kFSEventStreamCreateFlagIgnoreSelf | kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagFileEvents;
typedef NS_ENUM(NSInteger, XCCLineSpecifier)
{
    kLineSpecifierNone,
    kLineSpecifierColon,
    kLineSpecifierMinusL,
    kLineSpecifierPlus
};


@interface XCCCappuccinoProjectController ()
- (void)_handleFSEventsWithPaths:(NSArray *)paths flags:(const FSEventStreamEventFlags[])eventFlags ids:(const FSEventStreamEventId[])eventIds;
@end

void fsevents_callback(ConstFSEventStreamRef streamRef, void *userData, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[])
{
    XCCCappuccinoProjectController *controller = (__bridge  XCCCappuccinoProjectController *)userData;
    NSArray *paths = (__bridge  NSArray *)eventPaths;
    
    [controller _handleFSEventsWithPaths:paths flags:eventFlags ids:eventIds];
}



@implementation XCCCappuccinoProjectController

@synthesize numberOfErrors  = _numberOfErrors;

#pragma mark - Init methods

- (instancetype)initWithPath:(NSString*)aPath controller:(id)aController
{
    if (self = [super init])
    {
        [self _startListeningToOperationsNotifications];

        self.cappuccinoProject              = [[XCCCappuccinoProject alloc] initWithPath:aPath];
        self.mainXcodeCappController        = aController;
        self->sourceProcessingOperations    = [@{} mutableCopy];
        self->operationQueue                = [[NSApp delegate] mainOperationQueue];
        
        [self _reinitializeProjectController];
    }
    
    return self;
}

- (void)_reinitializeProjectController
{
    [self.cappuccinoProject reinitialize];
    [self _reinitializeOperationsCounters];
    [self _reinitializeOperationErrors];
    [self _prepareXcodeSupport];
}

- (void)_reinitializeTaskLauncher
{
    NSArray *binaryPaths = @[];
    
    if ([self.cappuccinoProject.binaryPaths count])
        binaryPaths = [self.cappuccinoProject.binaryPaths valueForKeyPath:@"name"];
    
    self->taskLauncher = [[XCCTaskLauncher alloc] initWithEnvironmentPaths:binaryPaths];
    
    if (!self->taskLauncher.isValid)
    {
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        
        NSRunAlertPanel(
                        self.cappuccinoProject.nickname,
                        @"XcodeCapp was unable to find all necessary executables in your environment:\n\n"
                        @"%@\n\n"
                        @"You certainly need to change the binary paths in the project settings.",
                        @"OK",
                        nil,
                        nil,
                        [self->taskLauncher.executables componentsJoinedByString:@", "]);
        
        [self _reinitializeProjectController];
    }
}


#pragma mark - Project State Management

- (void)_startListeningToProject
{
    if (![self _projectPathExists] || self.cappuccinoProject.status == XCCCappuccinoProjectStatusListening)
        return;

    DDLogInfo(@"Start to listen project: %@", self.cappuccinoProject.projectPath);

    [self _synchronizeXcodeSupport];

    if (self->taskLauncher.isValid)
    {
        [self _startFSEventStream];

        // this is needed in order to ensure we get a FS event, so we actually get a valid last event ID.
        [self->taskLauncher runTaskWithCommand:@"touch" arguments:@[self.cappuccinoProject.settingsPath] returnType:kTaskReturnTypeNone];

        self.cappuccinoProject.status = XCCCappuccinoProjectStatusListening;
    }

    [self.cappuccinoProject saveSettings];
}

- (void)_stopListeningToProject
{
    if (self.cappuccinoProject.status == XCCCappuccinoProjectStatusStopped)
        return;

    [self _cancelAllProjectRelatedOperations];
    [self _stopFSEventStream];

    [self.mainXcodeCappController.errorsViewController cleanProjectErrors:self];

    self.cappuccinoProject.status = XCCCappuccinoProjectStatusStopped;
    [self.cappuccinoProject saveSettings];
}


#pragma mark - XcodeSupport Management

- (BOOL)_projectPathExists
{
    NSFileManager *fm = [NSFileManager defaultManager];

    if (![fm fileExistsAtPath:self.cappuccinoProject.projectPath isDirectory:nil])
    {
        NSRunAlertPanel(@"The project can’t be located.", @"It seems the project moved while XcodeCapp was not running.", @"Remove Project", nil, nil);

        [self.mainXcodeCappController unmanageCappuccinoProjectController:self];
        return NO;
    }

    return YES;
}

- (void)_synchronizeXcodeSupport
{
    DDLogInfo(@"Synchronize project: %@", self.cappuccinoProject.projectPath);

    [self _reinitializeProjectController];
    [self _reinitializeTaskLauncher];

    if (!self->taskLauncher.isValid)
        return;

    [self _synchronizeXcodeSupportFromPath:@""];
}

- (void)_prepareXcodeSupport
{
    NSFileManager *fm = [NSFileManager defaultManager];

    BOOL projectExists, projectIsDirectory;
    projectExists = [fm fileExistsAtPath:self.cappuccinoProject.XcodeProjectPath isDirectory:&projectIsDirectory];
    
    BOOL supportExists, supportIsDirectory;
    supportExists = [fm fileExistsAtPath:self.cappuccinoProject.supportPath isDirectory:&supportIsDirectory];

    if (!projectExists || !projectIsDirectory || !supportExists)
        [self _createXcodeProject];

    if (!supportExists || !supportIsDirectory || !projectExists || ![self _isXcodeSupportCompatible])
        [self _createXcodeSupportDirectory];
}

- (BOOL)_isXcodeSupportCompatible
{
    double appCompatibilityVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:XCCCompatibilityVersionKey] doubleValue];
    
    NSNumber *projectCompatibilityVersion = @([self.cappuccinoProject.version intValue]);
    
    if (projectCompatibilityVersion == nil)
    {
        DDLogVerbose(@"No compatibility version in project");
        return NO;
    }
    
    DDLogVerbose(@"XcodeCapp/project compatibility version: %0.1f/%0.1f", projectCompatibilityVersion.doubleValue, appCompatibilityVersion);
    
    return projectCompatibilityVersion.doubleValue >= appCompatibilityVersion;
}

- (void)_createXcodeProject
{
    [self _removeXcodeProject];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    [fm createDirectoryAtPath:self.cappuccinoProject.XcodeProjectPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString *pbxPath = [self.cappuccinoProject.XcodeProjectPath stringByAppendingPathComponent:@"project.pbxproj"];
    
    [fm copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"project" ofType:@"pbxproj"] toPath:pbxPath error:nil];
    
    NSMutableString *content = [NSMutableString stringWithContentsOfFile:pbxPath encoding:NSUTF8StringEncoding error:nil];
    
    [content writeToFile:pbxPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    DDLogInfo(@"Xcode support project created at: %@", self.cappuccinoProject.XcodeProjectPath);
}

- (void)_removeXcodeProject
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([fm fileExistsAtPath:self.cappuccinoProject.XcodeProjectPath])
        [fm removeItemAtPath:self.cappuccinoProject.XcodeProjectPath error:nil];
}

- (void)_createXcodeSupportDirectory
{
    [self _removeXcodeSupportDirectory];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:self.cappuccinoProject.supportPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    [self.cappuccinoProject saveSettings];
    
    DDLogInfo(@".XcodeSupport directory created at: %@", self.cappuccinoProject.supportPath);
}

- (void)_removeXcodeSupportDirectory
{
    [XcodeProjectCloser closeXcodeProjectForProject:self.cappuccinoProject.projectPath];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([fm fileExistsAtPath:self.cappuccinoProject.supportPath])
        [fm removeItemAtPath:self.cappuccinoProject.supportPath error:nil];
}

- (void)_synchronizeXcodeSupportFromPath:(NSString *)path
{
    self->operationQueue.suspended = YES;
    [self _cancelCurrentSourceFinderOperation];
    [self _scheduleFinderSourceOperationForPath:path];
    self->operationQueue.suspended = NO;
}

- (void)_removeXcodeSupportOrphanFiles
{
    NSArray         *subpaths       = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.cappuccinoProject.supportPath error:nil];
    NSMutableArray  *orphanFiles    = [@[] mutableCopy];
    NSFileManager   *fm             = [NSFileManager defaultManager];
    
    for (NSString *path in subpaths)
    {
        if ([XCCCappuccinoProject isHeaderFile:path] && ![path.lastPathComponent isEqualToString:@"xcc_general_include.h"])
        {
            NSString *sourcePath = [self.cappuccinoProject sourcePathForShadowPath:path];
            
            if (![fm fileExistsAtPath:sourcePath])
                [orphanFiles addObject:sourcePath];
        }
    }

    NSMutableArray *pathsToRemove = [@[] mutableCopy];

    for (NSString *sourcePath in orphanFiles)
    {
        NSString *shadowBasePath            = [self.cappuccinoProject shadowBasePathForProjectSourcePath:sourcePath];
        NSString *shadowHeaderPath          = [shadowBasePath stringByAppendingPathExtension:@"h"];
        NSString *shadowImplementationPath  = [shadowBasePath stringByAppendingPathExtension:@"m"];
        
        [fm removeItemAtPath:shadowHeaderPath error:nil];
        [fm removeItemAtPath:shadowImplementationPath error:nil];
        
        [self removeOperationErrorsRelatedToSourcePath:sourcePath errorType:XCCDefaultOperationErrorType];

        [pathsToRemove addObject:sourcePath];
    }
    
    [self.mainXcodeCappController.errorsViewController reload];

    if (self->pendingPBXOperation)
        [self->pendingPBXOperation registerPathsToRemoveFromPBX:pathsToRemove];
    else
        [self _schedulePBXOperationWithPathsToAdd:nil pathsToRemove:pathsToRemove];

}

- (void)_updateXcodeSupportFilesWithModifiedPaths:(NSArray *)modifiedPaths
{
    DDLogVerbose(@"Modified files: %@", modifiedPaths);

    for (NSString *path in modifiedPaths)
    {
        if (![[NSFileManager defaultManager] fileExistsAtPath:path])
            continue;

        [self _scheduleSourceProcessingOperationForPath:path];
    }

    [self _removeXcodeSupportOrphanFiles];

    [self _updateOperationsProgress];
}

- (void)_updateXcodeSupportFilesWithRenamedDirectories:(NSArray *)directories
{
    DDLogVerbose(@"Renamed directories: %@", directories);
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSString *directory in directories)
    {
        if ([directory isEqualToString:self.cappuccinoProject.projectPath])
            continue;
        
        if ([fm fileExistsAtPath:directory])
        {
            if ([directory hasPrefix:self.cappuccinoProject.projectPath])
                [self _synchronizeXcodeSupportFromPath:[self.cappuccinoProject projectRelativePathForPath:directory]];
            else
            {
                [self _synchronizeXcodeSupportFromPath:@""];
                break;
            }
        }
    }

    [self _removeXcodeSupportOrphanFiles];
}


#pragma mark - Notifications

- (void)_startListeningToOperationsNotifications
{
    if (self->isListeningToOperationNotifications)
        return;

    self->isListeningToOperationNotifications = YES;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(_didReceiveConversionDidStartNotification:) name:XCCConversionDidStartNotification object:nil];
    [center addObserver:self selector:@selector(_didReceiveConversionDidEndNotification:) name:XCCConversionDidEndNotification object:nil];

    [center addObserver:self selector:@selector(_didReceiveSourcesFinderOperationDidStartNotification:) name:XCCSourcesFinderOperationDidStartNotification object:nil];
    [center addObserver:self selector:@selector(_didReceiveSourcesFinderOperationDidEndNotification:) name:XCCSourcesFinderOperationDidEndNotification object:nil];
    [center addObserver:self selector:@selector(_didReceiveNeedSourceToProjectPathMappingNotification:) name:XCCNeedSourceToProjectPathMappingNotification object:nil];

    [center addObserver:self selector:@selector(_didReceiveObjj2ObjcSkeletonDidStartNotification:) name:XCCObjj2ObjcSkeletonDidStartNotification object:nil];
    [center addObserver:self selector:@selector(_didReceiveObjj2ObjcSeleketonDidGenerateErrorNotification:) name:XCCObjj2ObjcSkeletonDidGenerateErrorNotification object:nil];

    [center addObserver:self selector:@selector(_didReceiveNib2CibDidStartNotifcation:) name:XCCNib2CibDidStartNotification object:nil];
    [center addObserver:self selector:@selector(_didReceiveNib2CibDidGenerateErrorNotification:) name:XCCNib2CibDidGenerateErrorNotification object:nil];

    [center addObserver:self selector:@selector(_didReceiveObjjDidStartNotification:) name:XCCObjjDidStartNotification object:nil];
    [center addObserver:self selector:@selector(_didReceiveObjjDidGenerateErrorNotification:) name:XCCObjjDidGenerateErrorNotification object:nil];

    [center addObserver:self selector:@selector(_didReceiveCappLintDidStartNotification:) name:XCCCappLintDidStartNotification object:nil];
    [center addObserver:self selector:@selector(_didReceiveCappLintDidGenerateErrorNotification:) name:XCCCappLintDidGenerateErrorNotification object:nil];

    [center addObserver:self selector:@selector(_didReceiveUpdatePbxFileDidStartNotification:) name:XCCPBXOperationDidStartNotification object:nil];
    [center addObserver:self selector:@selector(_didReceiveUpdatePbxFileDidEndNotification:) name:XCCPBXOperationDidEndNotification object:nil];
}

- (void)_stopListeningToOperationsNotifications
{
    if (!self->isListeningToOperationNotifications)
        return;

    self->isListeningToOperationNotifications = NO;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center removeObserver:self name:XCCConversionDidStartNotification object:nil];
    [center removeObserver:self name:XCCConversionDidEndNotification object:nil];

    [center removeObserver:self name:XCCSourcesFinderOperationDidStartNotification object:nil];
    [center removeObserver:self name:XCCSourcesFinderOperationDidEndNotification object:nil];
    [center removeObserver:self name:XCCNeedSourceToProjectPathMappingNotification object:nil];

    [center removeObserver:self name:XCCObjj2ObjcSkeletonDidStartNotification object:nil];
    [center removeObserver:self name:XCCObjj2ObjcSkeletonDidGenerateErrorNotification object:nil];

    [center removeObserver:self name:XCCNib2CibDidStartNotification object:nil];
    [center removeObserver:self name:XCCNib2CibDidGenerateErrorNotification object:nil];

    [center removeObserver:self name:XCCObjjDidStartNotification object:nil];
    [center removeObserver:self name:XCCObjjDidGenerateErrorNotification object:nil];

    [center removeObserver:self name:XCCCappLintDidStartNotification object:nil];
    [center removeObserver:self name:XCCCappLintDidGenerateErrorNotification object:nil];

    [center removeObserver:self name:XCCPBXOperationDidStartNotification object:nil];
    [center removeObserver:self name:XCCPBXOperationDidEndNotification object:nil];

}

- (BOOL)_doesNotificationBelongToCurrentProject:(NSNotification *)note
{
    return note.userInfo[@"cappuccinoProject"] == self.cappuccinoProject;
}

- (void)_didReceiveConversionDidStartNotification:(NSNotification *)note
{
    if (![self _doesNotificationBelongToCurrentProject:note])
        return;

    [self _schedulePBXOperation];
    [self->pendingPBXOperation registerPathsToAddInPBX:@[note.userInfo[@"sourcePath"]]];

    [self operationDidStart:note.object type:note.name userInfo:note.userInfo];
}

- (void)_didReceiveConversionDidEndNotification:(NSNotification *)note
{
    if (![self _doesNotificationBelongToCurrentProject:note])
        return;

    [self.mainXcodeCappController reloadTotalNumberOfErrors];

    [self operationDidEnd:note.object type:note.name userInfo:note.userInfo];
}

- (void)_didReceiveSourcesFinderOperationDidStartNotification:(NSNotification *)note
{
    if (![self _doesNotificationBelongToCurrentProject:note])
        return;

    [self operationDidStart:note.object type:note.name userInfo:note.userInfo];
}

- (void)_didReceiveSourcesFinderOperationDidEndNotification:(NSNotification *)note
{
    if (![self _doesNotificationBelongToCurrentProject:note])
        return;

    [self operationDidEnd:note.object type:note.name userInfo:note.userInfo];
}

- (void)_didReceiveNeedSourceToProjectPathMappingNotification:(NSNotification *)note
{
    if (![self _doesNotificationBelongToCurrentProject:note])
        return;

    self.cappuccinoProject.projectPathsForSourcePaths[note.userInfo[@"sourcePath"]] = note.userInfo[@"projectPath"];
}

- (void)_didReceiveObjj2ObjcSkeletonDidStartNotification:(NSNotification *)note
{
    if (![self _doesNotificationBelongToCurrentProject:note])
        return;

    [self removeOperationErrorsRelatedToSourcePath:note.userInfo[@"sourcePath"] errorType:XCCObjj2ObjcSkeletonOperationErrorType];
}

- (void)_didReceiveObjj2ObjcSeleketonDidGenerateErrorNotification:(NSNotification *)note
{
    if (![self _doesNotificationBelongToCurrentProject:note])
        return;

    for (XCCOperationError *operationError in [XCCOperationError operationErrorsFromObjj2ObjcSkeletonInfo:note.userInfo])
        [self addOperationError:operationError];
}

- (void)_didReceiveNib2CibDidStartNotifcation:(NSNotification *)note
{
    if (![self _doesNotificationBelongToCurrentProject:note])
        return;

    [self removeOperationErrorsRelatedToSourcePath:note.userInfo[@"sourcePath"] errorType:XCCNib2CibOperationErrorType];
}

- (void)_didReceiveNib2CibDidGenerateErrorNotification:(NSNotification *)note
{
    if (![self _doesNotificationBelongToCurrentProject:note])
        return;

    [self addOperationError:[XCCOperationError operationErrorFromNib2CibInfo:note.userInfo]];
}

- (void)_didReceiveObjjDidStartNotification:(NSNotification *)note
{
    if (![self _doesNotificationBelongToCurrentProject:note])
        return;

    [self removeOperationErrorsRelatedToSourcePath:note.userInfo[@"sourcePath"] errorType:XCCObjjOperationErrorType];
}

- (void)_didReceiveObjjDidGenerateErrorNotification:(NSNotification *)note
{
    if (![self _doesNotificationBelongToCurrentProject:note])
        return;

    for (XCCOperationError *operationError in [XCCOperationError operationErrorsFromObjjInfo:note.userInfo])
        [self addOperationError:operationError];
}

- (void)_didReceiveCappLintDidStartNotification:(NSNotification *)note
{
    if (![self _doesNotificationBelongToCurrentProject:note])
        return;

    [self removeOperationErrorsRelatedToSourcePath:note.userInfo[@"sourcePath"] errorType:XCCCappLintOperationErrorType];
}

- (void)_didReceiveCappLintDidGenerateErrorNotification:(NSNotification *)note
{
    if (![self _doesNotificationBelongToCurrentProject:note])
        return;

    for (XCCOperationError *operationError in [XCCOperationError operationErrorsFromCappLintInfo:note.userInfo])
        [self addOperationError:operationError];
}

- (void)_didReceiveUpdatePbxFileDidStartNotification:(NSNotification*)note
{
    if (![self _doesNotificationBelongToCurrentProject:note])
        return;

    [self operationDidStart:note.object type:note.name userInfo:note.userInfo];
}

- (void)_didReceiveUpdatePbxFileDidEndNotification:(NSNotification*)note
{
    if (![self _doesNotificationBelongToCurrentProject:note])
        return;
    
    [self operationDidEnd:note.object type:note.name userInfo:note.userInfo];
}


#pragma mark - OperationError Management

- (void)addOperationError:(XCCOperationError *)operationError
{
    if (!operationError.fileName)
        operationError.fileName = @"/No Filename";
    
    [self willChangeValueForKey:@"errors"];
    
    if (!self.errors[operationError.fileName])
        self.errors[operationError.fileName] = [@[] mutableCopy];
    
    [self.errors[operationError.fileName] addObject:operationError];
    
    [self didChangeValueForKey:@"errors"];
    self.numberOfErrors++;
    
    [self _notifyUserWithOperationError:operationError];
}

- (void)removeOperationError:(XCCOperationError *)operationError
{
    if (!operationError.fileName)
        operationError.fileName = @"/No Filename";
    
    [self willChangeValueForKey:@"errors"];
    
    [self.errors[operationError.fileName] removeObject:operationError];
    
    if (![self.errors[operationError.fileName] count])
        [self.errors removeObjectForKey:operationError.fileName];
    
    [self didChangeValueForKey:@"errors"];
    self.numberOfErrors--;
}

- (void)removeAllOperationErrors
{
    [self willChangeValueForKey:@"errors"];
    [self.errors removeAllObjects];
    [self didChangeValueForKey:@"errors"];
    self.numberOfErrors = 0;
}

- (void)removeOperationErrorsRelatedToSourcePath:(NSString *)aPath errorType:(int)anErrorType
{
    NSMutableArray *errorsToRemove = [@[] mutableCopy];
    
    for (XCCOperationError *operationError in self.errors[aPath])
        if ([operationError.fileName isEqualToString:aPath] && (operationError.errorType == anErrorType || anErrorType == XCCDefaultOperationErrorType))
            [errorsToRemove addObject:operationError];
    
    for (XCCOperationError *error in errorsToRemove)
        [self removeOperationError:error];
}

- (NSInteger)numberOfErrors
{
    return _numberOfErrors;
}

- (void)setNumberOfErrors:(NSInteger)numberOfErrors
{
    if (numberOfErrors == _numberOfErrors)
        return;
    
    [self willChangeValueForKey:@"numberOfErrors"];
    _numberOfErrors = numberOfErrors;
    [self didChangeValueForKey:@"numberOfErrors"];
    
    if (!_numberOfErrors)
        self.errorsCountString = @"";
    else
    {
        NSString *plural1 = self.numberOfErrors > 1 ? @"s" : @"";
        NSString *plural2 = self.errors.count > 1 ? @"s" : @"";
        self.errorsCountString = [NSString stringWithFormat:@"%d issue%@ in %d file%@", (int)self.numberOfErrors, plural1, (int)self.errors.count, plural2];
    }
}

- (void)_reinitializeOperationErrors
{
    self.errors         = [@{} mutableCopy];
    self.numberOfErrors = 0;
}


#pragma mark - Operation Management

- (void)operationDidStart:(XCCAbstractOperation*)anOperation type:(NSString *)aType userInfo:(NSDictionary*)userInfo
{
    [self.mainXcodeCappController.operationsViewController reload];
    [self.mainXcodeCappController.errorsViewController reload];
}

- (void)operationDidEnd:(XCCAbstractOperation*)anOperation type:(NSString *)aType userInfo:(NSDictionary*)userInfo
{
    [self _dequeueOperation:anOperation];

    if ([aType isEqualToString:XCCSourcesFinderOperationDidEndNotification])
    {
        self->currentFindSourceOperation = nil;
        [self _updateXcodeSupportFilesWithModifiedPaths:userInfo[@"sourcePaths"]];
    }
    else if ([aType isEqualToString:XCCPBXOperationDidEndNotification])
    {
        self->pendingPBXOperation = nil;
    }

    if (self->stream)
        self.cappuccinoProject.status = XCCCappuccinoProjectStatusListening;

    [self.mainXcodeCappController.operationsViewController reload];
    [self.mainXcodeCappController.errorsViewController reload];
}

- (void)_reinitializeOperationsCounters
{
    self.operationsProgress  = 1.0;
    self.operationsTotal     = 0;
    self.operationsRemaining = 0;
}

- (void)_updateOperationsProgress
{
    if (!self.operationsTotal)
    {
        self.operationsRemaining = 0;
        self.operationsProgress = 1.0;
    }
    else
    {
        self.operationsRemaining =  (long)[[self projectRelatedOperations] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"cancelled = NO"]].count;
        self.operationsProgress = 1.0 - (float)self.operationsRemaining / (float)self.operationsTotal;
    }

    self.operationsRemainingString = [NSString stringWithFormat:@"%d total operations, %d remaining", (int)self.operationsTotal, (int)self.operationsRemaining];

    if (self.operationsProgress == 1.0)
        [self _reinitializeOperationsCounters];
}

- (void)_registerSourceProcessingOperation:(XCCSourceProcessingOperation *)sourceOperation
{
    if (!self->sourceProcessingOperations[sourceOperation.sourcePath])
        self->sourceProcessingOperations[sourceOperation.sourcePath] = [@[] mutableCopy];

    NSMutableArray *operations = self->sourceProcessingOperations[sourceOperation.sourcePath];

    if (![operations containsObject:sourceOperation])
        [operations addObject:sourceOperation];
}

- (void)_unregisterSourceProcessingOperation:(XCCSourceProcessingOperation *)sourceOperation
{
    [self->sourceProcessingOperations[sourceOperation.sourcePath] removeObject:sourceOperation];

    if (!self->sourceProcessingOperations[sourceOperation.sourcePath])
        [self->sourceProcessingOperations removeObjectForKey:sourceOperation.sourcePath];
}

- (NSArray *)_sourceProcessingOperationsForPath:(NSString *)path
{
    return self->sourceProcessingOperations[path];
}

- (void)_enqueueOperation:(NSOperation *)anOperation
{
    if ([self->operationQueue.operations containsObject:anOperation])
        return;

    [self->operationQueue addOperation:anOperation];

    if ([anOperation isKindOfClass:[XCCSourceProcessingOperation class]])
        [self _registerSourceProcessingOperation:(XCCSourceProcessingOperation *)anOperation];

    self.operationsTotal++;
    [self _updateOperationsProgress];
}

- (void)_dequeueOperation:(NSOperation *)anOperation
{
    if ([anOperation isKindOfClass:[XCCSourceProcessingOperation class]])
        [self _unregisterSourceProcessingOperation:(XCCSourceProcessingOperation *)anOperation];

    [self _updateOperationsProgress];
}

- (void)_cancelSourceOperationsForPath:(NSString *)path
{
    NSArray *operations = [self _sourceProcessingOperationsForPath:path];

    for (NSOperation * operation in operations)
    {
        [operation cancel];
        [self _dequeueOperation:operation];
    }
}

- (void)_cancelAllProjectRelatedOperations
{
    [[self projectRelatedOperations] makeObjectsPerformSelector:@selector(cancel)];
    self->sourceProcessingOperations = [@{} mutableCopy];
    self->pendingPBXOperation = nil;
}

- (NSArray*)projectRelatedOperations
{
    return [self->operationQueue.operations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"cappuccinoProject.projectPath == %@", self.cappuccinoProject.projectPath]];
}

- (NSArray *)projectRelatedSourceProcessingOperations
{
    return [[self projectRelatedOperations] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass:  %@", [XCCSourceProcessingOperation class]]];
}

- (void)_cancelCurrentSourceFinderOperation
{
    if (!self->currentFindSourceOperation)
        return;

    [[self projectRelatedSourceProcessingOperations] makeObjectsPerformSelector:@selector(removeDependency:) withObject:self->currentFindSourceOperation];
    [self->currentFindSourceOperation cancel];
    [self _dequeueOperation:self->currentFindSourceOperation];
    self->currentFindSourceOperation = nil;
}

- (void)_scheduleFinderSourceOperationForPath:(NSString *)path
{
    if (self->currentFindSourceOperation)
        return;

    self->currentFindSourceOperation = [[XCCSourcesFinderOperation alloc] initWithCappuccinoProject:self.cappuccinoProject taskLauncher:self->taskLauncher sourcePath:path];
    [[self projectRelatedSourceProcessingOperations] makeObjectsPerformSelector:@selector(addDependency:) withObject:self->currentFindSourceOperation];
    [self _enqueueOperation:self->currentFindSourceOperation];
}

- (void)_schedulePBXOperation
{
    [self _schedulePBXOperationWithPathsToAdd:nil pathsToRemove:nil];
}

- (void)_schedulePBXOperationWithPathsToAdd:(NSArray *)pathsToAdd pathsToRemove:(NSArray *)pathsToRemove;
{
    BOOL needsEnqueue = NO;

    if (!self->pendingPBXOperation)
    {
        self->pendingPBXOperation = [[XCCPPXOperation alloc] initWithCappuccinoProject:self.cappuccinoProject taskLauncher:self->taskLauncher];
        needsEnqueue = YES;
    }

    if (pathsToAdd)
        [self->pendingPBXOperation registerPathsToAddInPBX:pathsToAdd];

    if (pathsToRemove)
        [self->pendingPBXOperation registerPathsToRemoveFromPBX:pathsToRemove];

    for (XCCSourceProcessingOperation *operation in [self projectRelatedSourceProcessingOperations])
        [self->pendingPBXOperation addDependency:operation];

    if (needsEnqueue)
        [self _enqueueOperation:self->pendingPBXOperation];
}

- (void)_scheduleSourceProcessingOperationForPath:(NSString *)path
{
    [self _cancelSourceOperationsForPath:path];

    XCCSourceProcessingOperation *operation = [[XCCSourceProcessingOperation alloc] initWithCappuccinoProject:self.cappuccinoProject
                                                                                                 taskLauncher:self->taskLauncher
                                                                                                   sourcePath:[self.cappuccinoProject projectPathForSourcePath:path]];
    if (self->currentFindSourceOperation)
        [operation addDependency:self->currentFindSourceOperation];

    [self _enqueueOperation:operation];
}


#pragma mark - FS Event Management

- (void)_startFSEventStream
{
    if (self->stream)
        return;

    NSArray                 *pathsToWatch   = [XCCCappuccinoProject getPathsToWatchForCappuccinoProject:self.cappuccinoProject];
    void                    *appPointer     = (__bridge void *)self;
    FSEventStreamContext    context         = { 0, appPointer, NULL, NULL, NULL };
    CFTimeInterval          latency         = 0.5;
    UInt64                  lastEventID     = self.cappuccinoProject.lastEventID ? self.cappuccinoProject.lastEventID.unsignedLongLongValue : kFSEventStreamEventIdSinceNow;

    self->stream = FSEventStreamCreate(NULL, &fsevents_callback, &context, (__bridge CFArrayRef) pathsToWatch, lastEventID, latency, XCCProjectControllerFSEventFlags);

    FSEventStreamScheduleWithRunLoop(self->stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(self->stream);

    DDLogVerbose(@"FSEventStream started for paths: %@", pathsToWatch);
}

- (void)_stopFSEventStream
{
    if (!self->stream)
        return;

    UInt64 lastEventID = FSEventStreamGetLatestEventId(self->stream);

    if (lastEventID != 0 && lastEventID != UINT64_MAX)
    {
        self.cappuccinoProject.lastEventID = @(lastEventID);
        [self.cappuccinoProject saveSettings];
    }

    FSEventStreamStop(self->stream);
    FSEventStreamUnscheduleFromRunLoop(self->stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamInvalidate(self->stream);
    FSEventStreamRelease(self->stream);

    self->stream = NULL;

    DDLogVerbose(@"FSEventStream stopped");
}

- (void)_handleFSEventsWithPaths:(NSArray *)paths flags:(const FSEventStreamEventFlags[])eventFlags ids:(const FSEventStreamEventId[])eventIds
{
    NSMutableArray *modifiedPaths       = [@[] mutableCopy];
    NSMutableArray *renamedDirectories  = [@[] mutableCopy];
    NSFileManager  *fm                  = [NSFileManager defaultManager];
    
    BOOL needUpdate = NO;
    
    for (size_t i = 0; i < paths.count; ++i)
    {
        FSEventStreamEventFlags flags       = eventFlags[i];
        NSString                *path       = [paths[i] stringByStandardizingPath];

        BOOL rootChanged = (flags & kFSEventStreamEventFlagRootChanged) != 0;
        BOOL needRescan = (flags & kFSEventStreamEventFlagMustScanSubDirs) != 0;

        if (rootChanged || needRescan)
        {
            DDLogVerbose(@"Watched path changed: %@", path);
            
            [self _handleProjectPathChange:path];
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
        

        BOOL inodeMetaModified  = (flags & kFSEventStreamEventFlagItemInodeMetaMod) != 0;
        BOOL isFile             = (flags & kFSEventStreamEventFlagItemIsFile)       != 0;
        BOOL isSymlink          = (flags & kFSEventStreamEventFlagItemIsSymlink)    != 0;
        BOOL isDir              = (flags & kFSEventStreamEventFlagItemIsDir)        != 0;
        BOOL renamed            = (flags & kFSEventStreamEventFlagItemRenamed)      != 0;
        BOOL modified           = (flags & kFSEventStreamEventFlagItemModified)     != 0;
        BOOL created            = (flags & kFSEventStreamEventFlagItemCreated)      != 0;
        BOOL removed            = (flags & kFSEventStreamEventFlagItemRemoved)      != 0;
        
        if (isDir)
        {
            if (created && [path isEqualToString:self.cappuccinoProject.projectPath.stringByResolvingSymlinksInPath])
                return;
            
            if ((renamed || created || removed) &&
                ![XCCCappuccinoProject shouldIgnoreDirectoryNamed:path.lastPathComponent] &&
                ![XCCCappuccinoProject pathMatchesIgnoredPaths:path cappuccinoProjectIgnoredPathPredicates:self.cappuccinoProject.ignoredPathPredicates])
            {
                DDLogVerbose(@"Renamed directory: %@", path);
                
                [renamedDirectories addObject:path];
            }
            
            continue;
        }
        else if ((isFile || isSymlink) &&
                 (created || modified || renamed || removed || inodeMetaModified) &&
                 [XCCCappuccinoProject isSourceFile:path cappuccinoProject:self.cappuccinoProject])
        {
            DDLogVerbose(@"FSEvent accepted: %@ (%@)", path, [XCCFSEventLogUtils dumpFSEventFlags:flags]);

            if ([fm fileExistsAtPath:path])
            {
                [modifiedPaths addObject:path];
            }
            else if ([XCCCappuccinoProject isXibFile:path])
            {
                // If a xib is deleted, delete its cib. There is no need to update when a xib is deleted,
                // it is inside a folder in Xcode, which updates automatically.
                
                if (![fm fileExistsAtPath:path])
                {
                    NSString *cibPath = [path.stringByDeletingPathExtension stringByAppendingPathExtension:@"cib"];
                    
                    if ([fm fileExistsAtPath:cibPath])
                        [fm removeItemAtPath:cibPath error:nil];
                    
                    continue;
                }
            }
            
            needUpdate = YES;
        }
        else if ((isFile || isSymlink) && (renamed || removed) && !(modified || created) && [XCCCappuccinoProject isCibFile:path])
        {
            DDLogVerbose(@"FSEvent accepted: %@ (%@)", path, [XCCFSEventLogUtils dumpFSEventFlags:flags]);
            
            // If a cib is deleted, mark its xib as needing update so the cib is regenerated
            NSString *xibPath = [path.stringByDeletingPathExtension stringByAppendingPathExtension:@"xib"];
            
            if ([fm fileExistsAtPath:xibPath])
            {
                [modifiedPaths addObject:xibPath];
                needUpdate = YES;
            }
        }
        else if ((isFile || isSymlink) &&
                 (created || modified || renamed || removed || inodeMetaModified) &&
                 [XCCCappuccinoProject isXCCIgnoreFile:path cappuccinoProject:self.cappuccinoProject])
        {
            DDLogVerbose(@"FSEvent accepted: %@ (%@)", path, [XCCFSEventLogUtils dumpFSEventFlags:flags]);

            [self.cappuccinoProject reloadXcodeCappIgnoreFile];
        }
    }
    
    // If directories were renamed, we take the easy way out and reset the project
    if (renamedDirectories.count)
        [self _updateXcodeSupportFilesWithRenamedDirectories:renamedDirectories];
    else if (needUpdate)
        [self _updateXcodeSupportFilesWithModifiedPaths:modifiedPaths];
}

- (void)_handleProjectPathChange:(NSString *)path
{
    NSRunAlertPanel(self.cappuccinoProject.nickname, @"The project directory changed. This project will be removed", @"OK", nil, nil, nil);

    [self.mainXcodeCappController unmanageCappuccinoProjectController:self];
}


#pragma mark - Third Party Application Management

- (NSString *)_managingApplicationIdenfierForFilePath:(NSString *)filePath
{
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSString *app, *type;
    
    BOOL success = [workspace getInfoForFile:filePath application:&app type:&type];
    
    return success ? app : nil;
}

- (void)launchEditorForPath:(NSString*)path line:(NSInteger)line
{
    NSString *applicationIdentifier = [self _managingApplicationIdenfierForFilePath:path];

    [self launchEditorForPath:path line:line applicationIdentifier:applicationIdentifier];
}

- (void)launchEditorForPath:(NSString*)path line:(NSInteger)line applicationIdentifier:(NSString *)applicationIdentifier
{
    if (!applicationIdentifier)
        return;
    
    NSFileManager       *fm             = [NSFileManager defaultManager];
    NSWorkspace         *workspace      = [NSWorkspace sharedWorkspace];
    NSBundle            *bundle         = [NSBundle bundleWithPath:applicationIdentifier];
    NSString            *identifier     = bundle.bundleIdentifier;
    NSString            *executablePath = nil;
    XCCLineSpecifier    lineSpecifier   = kLineSpecifierNone;
    
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
        if ([fm isExecutableFileAtPath:@"/usr/bin/aquamacs"])
            executablePath = @"/usr/bin/aquamacs";
        else if ([fm isExecutableFileAtPath:@"/usr/local/bin/aquamacs"])
            executablePath = @"/usr/local/bin/aquamacs";
    }
    else if ([identifier isEqualToString:@"com.apple.dt.Xcode"])
    {
        executablePath = [[bundle bundlePath] stringByAppendingPathComponent:@"Contents/Developer/usr/bin/xed"];
    }
    
    if (!executablePath || ![fm isExecutableFileAtPath:executablePath])
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
    
    [self->taskLauncher runTaskWithCommand:executablePath arguments:args returnType:kTaskReturnTypeNone];
}


#pragma mark - NSUserNotificationCenter Utilities

- (void)_notifyUserWithOperationError:(XCCOperationError*)anOperationError
{
    NSUserNotification *note = [NSUserNotification new];
    note.title = [[anOperationError.fileName stringByReplacingOccurrencesOfString:self.cappuccinoProject.projectPath withString:@""] substringFromIndex:1];
    note.informativeText = anOperationError.description;
    note.actionButtonTitle = @"Show";
    note.otherButtonTitle = @"Close";
    note.userInfo = @{@"cappuccinoProjectPath" : self.cappuccinoProject.projectPath, @"sourcePath": anOperationError.fileName};
        
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:note];
}


#pragma mark - Public Utilities

- (void)reinitializeProjectFromSettings
{
    DDLogVerbose(@"Saving Cappuccino configuration project %@", self.cappuccinoProject.projectPath);
    
    [self _cancelAllProjectRelatedOperations];
    [self.cappuccinoProject saveSettings];

    int previousStatus = self.cappuccinoProject.status;
    [self _stopListeningToProject];
    [self _reinitializeTaskLauncher];

    if (!self->taskLauncher.isValid)
        return;

    if (previousStatus == XCCCappuccinoProjectStatusListening)
        [self _startListeningToProject];

    DDLogVerbose(@"Cappuccino configuration project %@ has been saved", self.cappuccinoProject.projectPath);
}

- (void)applicationIsClosing
{
    [self _stopFSEventStream];
}

- (void)cleanUpBeforeDeletion
{
    [self cancelAllOperations:self];
    [self _stopListeningToOperationsNotifications];
    [self _stopListeningToProject];
    [self _removeXcodeProject];
    [self _removeXcodeSupportDirectory];

    [self.mainXcodeCappController.operationsViewController reload];
    [self.mainXcodeCappController.errorsViewController reload];
}


#pragma mark - Actions

- (IBAction)cancelAllOperations:(id)aSender
{
    [self _cancelAllProjectRelatedOperations];
    [self.mainXcodeCappController.operationsViewController reload];
}

- (IBAction)resetProject:(id)aSender
{
    [self _stopListeningToProject];
    [self _removeXcodeSupportDirectory];
    [self _removeXcodeProject];
    [self _reinitializeProjectController];
    [self _startListeningToProject];
}

- (IBAction)openProjectInXcode:(id)aSender
{
    BOOL            isDirectory;
    BOOL            isOpened    = YES;
    NSFileManager   *fm         = [NSFileManager defaultManager];
    BOOL            exists      = [fm fileExistsAtPath:self.cappuccinoProject.XcodeProjectPath isDirectory:&isDirectory];
    
    if (exists && isDirectory)
    {
        DDLogVerbose(@"Opening Xcode project at: %@", self.cappuccinoProject.XcodeProjectPath);
        
        isOpened = [[NSWorkspace sharedWorkspace] openFile:self.cappuccinoProject.XcodeProjectPath];
    }
    
    if (!exists || !isDirectory || !isOpened)
    {
        NSString *text;
        
        if (!isOpened)
            text = @"The project exists, but failed to open.";
        else
            text = [NSString stringWithFormat:@"%@ %@.", self.cappuccinoProject.XcodeProjectPath, !exists ? @"does not exist" : @"is not an Xcode project"];
        
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        NSInteger response = NSRunAlertPanel(@"The project could not be opened.", @"%@\n\nWould you like to regenerate the project?", @"Yes", @"No", nil, text);
        
        if (response == NSAlertFirstButtonReturn)
            [self resetProject:self];
    }
}

- (IBAction)openProjectInFinder:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:self.cappuccinoProject.projectPath];
}

- (IBAction)openProjectInEditor:(id)sender
{
    NSFileManager   *fm         = [NSFileManager defaultManager];
    NSArray         *contents   = [fm contentsOfDirectoryAtPath:self.cappuccinoProject.projectPath error:nil];
    NSString        *firstObjjFile;
    
    for (NSString *file in contents)
    {
        if ([[file pathExtension] isEqualToString:@"j"])
        {
            firstObjjFile = file;
            break;
        }
    }
    
    if (!firstObjjFile)
        return;
    
    NSString *applicationIdentifier = [self _managingApplicationIdenfierForFilePath:[self.cappuccinoProject.projectPath stringByAppendingPathComponent:firstObjjFile]];
    
    if (!applicationIdentifier)
        return;
    
    [self launchEditorForPath:self.cappuccinoProject.projectPath line:0 applicationIdentifier:applicationIdentifier];
}

- (IBAction)openProjectInTerminal:(id)sender;
{
    NSString *s = [NSString stringWithFormat:@"tell application \"Terminal\"\n do script \"cd %@; clear\" \n activate\n end tell", self.cappuccinoProject.projectPath];
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:s];
    [script executeAndReturnError:nil];
}

- (IBAction)switchProjectListeningStatus:(id)sender
{
    if (self.cappuccinoProject.status == XCCCappuccinoProjectStatusStopped)
        [self _startListeningToProject];
    else
        [self _stopListeningToProject];
}

@end


