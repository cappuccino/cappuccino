//
//  FindSourceFilesOperation.m
//  XcodeCapp
//
//  Created by Aparajita on 4/27/13.
//  Copyright (c) 2013 Cappuccino Project. All rights reserved.
//

#import "FindSourceFilesOperation.h"
#import "ProcessSourceOperation.h"
#import "XcodeCapp.h"

NSString * const XCCNeedSourceToProjectPathMappingNotification = @"XCCNeedSourceToProjectPathMappingNotification";


@interface FindSourceFilesOperation ()

@property XcodeCapp *xcc;
@property NSNumber *projectId;
@property NSString *projectPathToSearch;
@property NSString *projectPath;

@end


@implementation FindSourceFilesOperation

- (id)initWithXCC:(XcodeCapp *)xcc projectId:(NSNumber *)projectId path:(NSString *)path
{
    self = [super init];

    if (self)
    {
        self.xcc = xcc;
        self.projectId = projectId;
        self.projectPathToSearch = path;
        self.projectPath = xcc.projectPath;
    }

    return self;
}

- (void)main
{
    [self findSourceFilesAtProjectPath:self.projectPathToSearch];
}

- (void)findSourceFilesAtProjectPath:(NSString *)aProjectPath
{
    if (self.isCancelled)
        return;

    DDLogVerbose(@"-->findSourceFiles: %@", aProjectPath);
    
    NSError *error = NULL;
    NSString *projectPath = [self.projectPath stringByAppendingPathComponent:aProjectPath];
    NSFileManager *fm = [NSFileManager defaultManager];

    NSArray *urls = [fm contentsOfDirectoryAtURL:[NSURL fileURLWithPath:projectPath.stringByResolvingSymlinksInPath]
                      includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLIsSymbolicLinkKey]
                                         options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                           error:&error];

    if (!urls)
        return;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    for (NSURL *url in urls)
    {
        if (self.isCancelled)
            return;
        
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
            if ([self.xcc shouldIgnoreDirectoryNamed:filename])
            {
                DDLogVerbose(@"ignored symlinked directory: %@", projectRelativePath);
                continue;
            }

            // If the resolved path is not within the project directory and is not ignored, add a mapping to it
            // so we can map the resolved path back to the project directory later.
            if (isSymlink.boolValue == YES)
            {
                NSString *fullProjectPath = [self.projectPath stringByAppendingPathComponent:projectRelativePath];

                if (![realPath hasPrefix:fullProjectPath] && ![self.xcc pathMatchesIgnoredPaths:fullProjectPath])
                {
                    DDLogVerbose(@"symlinked directory: %@ -> %@", projectRelativePath, realPath);

                    NSDictionary *info =
                          @{
                                @"projectId":self.projectId,
                                @"sourcePath":realPath,
                                @"projectPath":fullProjectPath
                           };

                    if (self.isCancelled)
                        return;

                    [center postNotificationName:XCCNeedSourceToProjectPathMappingNotification object:self userInfo:info];
                }
                else
                    DDLogVerbose(@"ignored symlinked directory: %@", projectRelativePath);
            }

            [self findSourceFilesAtProjectPath:projectRelativePath];
            continue;
        }

        if (self.isCancelled)
            return;
        
        if ([self.xcc pathMatchesIgnoredPaths:realPath])
            continue;

        NSString *projectSourcePath = [self.projectPath stringByAppendingPathComponent:projectRelativePath];

        if ([self.xcc isObjjFile:filename] || [self.xcc isXibFile:filename])
        {
            NSString *processedPath;

            if ([self.xcc isObjjFile:filename])
                processedPath = [[self.xcc shadowBasePathForProjectSourcePath:projectSourcePath] stringByAppendingPathExtension:@"h"];
            else
                processedPath = [projectSourcePath.stringByDeletingPathExtension stringByAppendingPathExtension:@"cib"];

            if (![fm fileExistsAtPath:processedPath])
                [self createProcessingOperationForProjectSourcePath:projectSourcePath];
        }
    }

    DDLogVerbose(@"<--findSourceFiles: %@", aProjectPath);
}

- (void)createProcessingOperationForProjectSourcePath:(NSString *)projectSourcePath
{
    if (self.isCancelled)
        return;

    ProcessSourceOperation *op = [[ProcessSourceOperation alloc] initWithXCC:self.xcc
                                                                   projectId:self.projectId
                                                                  sourcePath:projectSourcePath];
    [[NSOperationQueue currentQueue] addOperation:op];
}

@end
