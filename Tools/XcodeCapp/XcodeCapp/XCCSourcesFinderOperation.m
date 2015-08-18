//
//  FindSourceFilesOperation.m
//  XcodeCapp
//
//  Created by Aparajita on 4/27/13.
//  Copyright (c) 2013 Cappuccino Project. All rights reserved.
//

#import "XCCSourcesFinderOperation.h"
#import "XCCSourceProcessingOperation.h"
#import "XCCTaskLauncher.h"

NSString * const XCCSourcesFinderOperationDidStartNotification = @"XCCSourcesFinderOperationDidStartNotification";
NSString * const XCCSourcesFinderOperationDidEndNotification = @"XCCSourcesFinderOperationDidEndNotification";
NSString * const XCCNeedSourceToProjectPathMappingNotification = @"XCCNeedSourceToProjectPathMappingNotification";


@implementation XCCSourcesFinderOperation


#pragma mark - Initialization

- (instancetype)initWithCappuccinoProject:(XCCCappuccinoProject *)aCappuccinoProject taskLauncher:(XCCTaskLauncher*)aTaskLauncher sourcePath:(NSString *)sourcePath
{
    if (self = [super initWithCappuccinoProject:aCappuccinoProject taskLauncher:aTaskLauncher])
    {
        self.operationName = @"Searching for Objective-J files";
        self.operationDescription = self.cappuccinoProject.name;
        self->searchPath = sourcePath;
    }
    
    return self;
}


#pragma mark - Utilities

- (NSArray *)_findSourceFilesAtProjectPath:(NSString *)aProjectPath
{
    NSError         *error          = NULL;
    NSString        *projectPath    = [self.cappuccinoProject.projectPath stringByAppendingPathComponent:aProjectPath];
    NSFileManager   *fm             = [NSFileManager defaultManager];
    NSMutableArray  *sourcePaths    = [@[] mutableCopy];
    
    NSArray *urls = [fm contentsOfDirectoryAtURL:[NSURL fileURLWithPath:projectPath.stringByResolvingSymlinksInPath]
                      includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLIsSymbolicLinkKey]
                                         options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                           error:&error];

    if (!urls)
        return [@[] mutableCopy];

    for (NSURL *url in urls)
    {
        NSString    *filename               = url.lastPathComponent;
        NSString    *projectRelativePath    = [aProjectPath stringByAppendingPathComponent:filename];
        NSString    *realPath               = url.path;
        NSURL       *resolvedURL            = url;
        NSNumber    *isDirectory;
        NSNumber    *isSymlink;

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
            if ([XCCCappuccinoProject shouldIgnoreDirectoryNamed:filename])
            {
                DDLogVerbose(@"%@: ignored symlinked directory: %@", self.cappuccinoProject.name, projectRelativePath);
                continue;
            }

            // If the resolved path is not within the project directory and is not ignored, add a mapping to it
            // so we can map the resolved path back to the project directory later.
            if (isSymlink.boolValue == YES)
            {
                NSString *fullProjectPath = [self.cappuccinoProject.projectPath stringByAppendingPathComponent:projectRelativePath];

                if (![realPath hasPrefix:fullProjectPath] && ![XCCCappuccinoProject pathMatchesIgnoredPaths:fullProjectPath cappuccinoProjectIgnoredPathPredicates:self.cappuccinoProject.ignoredPathPredicates])
                {
                    DDLogVerbose(@"%@: symlinked directory: %@ -> %@", self.cappuccinoProject.name, projectRelativePath, realPath);

                    NSMutableDictionary *info   = [self operationInformations];
                    info[@"sourcePath"]         = realPath;
                    info[@"projectPath"]        = fullProjectPath;

                    [self dispatchNotificationName:XCCNeedSourceToProjectPathMappingNotification userInfo:info];
                }
                else
                    DDLogVerbose(@"%@: ignored symlinked directory: %@", self.cappuccinoProject.name, projectRelativePath);
            }

            DDLogVerbose(@"%@: found directory. checking for source files: %@", self.cappuccinoProject.name, filename);

            [sourcePaths addObjectsFromArray:[self _findSourceFilesAtProjectPath:projectRelativePath]];
            continue;
        }

        if ([XCCCappuccinoProject pathMatchesIgnoredPaths:realPath cappuccinoProjectIgnoredPathPredicates:self.cappuccinoProject.ignoredPathPredicates])
            continue;

        NSString *projectSourcePath = [self.cappuccinoProject.projectPath stringByAppendingPathComponent:projectRelativePath];

        if ([XCCCappuccinoProject isObjjFile:filename] || [XCCCappuccinoProject isXibFile:filename])
        {
            DDLogVerbose(@"%@: found source file: %@", self.cappuccinoProject.name, filename);

            NSString *processedPath;

            if ([XCCCappuccinoProject isObjjFile:filename])
                processedPath = [[self.cappuccinoProject shadowBasePathForProjectSourcePath:projectSourcePath] stringByAppendingPathExtension:@"h"];
            else
                processedPath = [projectSourcePath.stringByDeletingPathExtension stringByAppendingPathExtension:@"cib"];

            if (![fm fileExistsAtPath:processedPath])
                [sourcePaths addObject:projectSourcePath];
        }
    }

    return sourcePaths;
}


#pragma mark - NSOperation API

- (void)main
{
    DDLogVerbose(@"Finding source files started");
    
    NSArray *sourcesPaths;

    [self dispatchNotificationName:XCCSourcesFinderOperationDidStartNotification userInfo:@{@"cappuccinoProject": self.cappuccinoProject, @"sourcePaths" : @[]}];

    @try
    {
        sourcesPaths = [self _findSourceFilesAtProjectPath:self->searchPath];
    }
    @catch (NSException *exception)
    {
        DDLogVerbose(@"Finding source files failed: %@", exception);
    }
    @finally
    {
        __block XCCSourcesFinderOperation *weakOperation = self;
        __block NSArray * weakSourcesPaths = sourcesPaths;
        
        self.completionBlock = ^{
            [weakOperation dispatchNotificationName:XCCSourcesFinderOperationDidEndNotification userInfo:@{@"cappuccinoProject": weakOperation.cappuccinoProject, @"sourcePaths" : weakSourcesPaths}];
        };
    }
    
    DDLogVerbose(@"Finding source files ended");
}

@end
