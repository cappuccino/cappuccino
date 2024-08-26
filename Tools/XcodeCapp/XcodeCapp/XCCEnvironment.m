//
//  XCCEnvironment.m
//  XcodeCapp
//
//  Created by David Richardson on 2024-08-26.
//  Copyright © 2024 cappuccino-project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XCCEnvironment.h"

@implementation XCCEnvironment

// Load the logged-in user's shell environment.
// Extract the PATH value from the environment
// and search path components, from left to right,
// to determine absolute paths for required Cappuccino toolchain components.
// Return the user environment as an NSDictionary,
// with toolchain components added - each using their name as a key and absolute path as a value.
+ (NSDictionary<NSString *, NSString *> *)loadEnvironmentFromUserShell
{
    // Determine the user's login shell
    NSString *userShell = [[[NSProcessInfo processInfo] environment] objectForKey:@"SHELL"];

    if (!userShell)
    {
        NSLog(@"Could not determine the user's shell.");
        return @{};
    }

    // Construct the command to retrieve the environment variables
    NSArray *args = @[@"--login", @"-c", @"env"];
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:userShell];
    [task setArguments:args];

    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    NSFileHandle *file = [pipe fileHandleForReading];

    [task launch];
    [task waitUntilExit];

    NSData *data = [file readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    NSMutableDictionary<NSString *, NSString *> *userEnvironment = [NSMutableDictionary dictionary];
    NSArray<NSString *> *lines = [output componentsSeparatedByString:@"\n"];

    for (NSString *line in lines)
    {
        NSArray<NSString *> *components = [line componentsSeparatedByString:@"="];
        if (components.count == 2)
        {
            NSString *key = components[0];
            NSString *value = components[1];
            userEnvironment[key] = value;
        }
    }

    // Get the PATH from the environment
    NSString *path = userEnvironment[@"PATH"];
    if (!path)
    {
        NSLog(@"PATH not found in the environment.");
        return @{};
    }

    NSArray<NSString *> *pathComponents = [path componentsSeparatedByString:@":"];

    // Toolchain binaries to locate
    NSArray<NSString *> *toolchainBinaries = @[@"objj", @"nib2cib", @"objj2objcskeleton"];

    // Dictionary to hold the paths to each toolchain binary
    NSMutableDictionary<NSString *, NSString *> *toolchainPaths = [NSMutableDictionary dictionary];

    // Find the Python 2.7 executable
    NSString *pythonPath = [self findPython27ExecutableInPath:pathComponents];
    if (pythonPath)
    {
        toolchainPaths[@"python"] = pythonPath;
    }

    // Find the touch utility (hardcoded path for safety)
    NSString *touchPath = @"/usr/bin/touch";
    if ([self isExecutableAtPath:touchPath])
    {
        toolchainPaths[@"touch"] = touchPath;
    }

    // Resolve paths for Cappuccino toolchain components
    // Prepend likely locations to the path components
    NSString *userHomeDirectory = [NSString stringWithFormat:@"%@/.npm/bin", [userEnvironment objectForKey:@"HOME"]];
    NSArray<NSString *> *preferredToolchainPaths = @[userHomeDirectory];
    NSMutableArray<NSString *> *toolchainSearchPaths = [preferredToolchainPaths mutableCopy];
    [toolchainSearchPaths addObjectsFromArray:pathComponents]; // Append the original PATH components
    NSString *resolvedToolchainPath = [self resolveToolchainPathForExecutables:toolchainBinaries inPathComponents:toolchainSearchPaths];
    if (resolvedToolchainPath)
    {
        for (NSString *binary in toolchainBinaries)
        {
            NSString *binaryPath = [resolvedToolchainPath stringByAppendingPathComponent:binary];
            toolchainPaths[binary] = binaryPath;
        }
    }

    // Return a dictionary of toolchain paths and the user environment settings
    [toolchainPaths addEntriesFromDictionary:userEnvironment];
    return [toolchainPaths copy];
}

#pragma mark - Helper methods

+ (NSString *)findPython27ExecutableInPath:(NSArray<NSString *> *)pathComponents
{
    // Prepend likely locations to the path components
    // The prepended paths may already be in the combined path,
    // but this allows early termination for improved performance.
    NSArray<NSString *> *preferredPaths = @[@"/usr/local/bin", @"/opt/local/bin"];
    NSMutableArray<NSString *> *searchPaths = [preferredPaths mutableCopy];
    [searchPaths addObjectsFromArray:pathComponents]; // Append the original PATH components

    // Iterate over the search paths
    for (NSString *path in searchPaths)
    {
        NSString *pythonPath = [path stringByAppendingPathComponent:@"python"];
        if ([self isExecutableAtPath:pythonPath])
        {
            NSString *pythonVersionString = [self pythonVersionAtPath:pythonPath];
            if ([pythonVersionString hasPrefix:@"2.7."])
            {
                return pythonPath;
            }
        }
    }
    return nil;
}

+ (NSString *)findExecutable:(NSString *)executableName inPath:(NSArray<NSString *> *)pathComponents
{
    for (NSString *path in pathComponents)
    {
        NSString *executablePath = [path stringByAppendingPathComponent:executableName];
        if ([self isExecutableAtPath:executablePath])
        {
            return executablePath;
        }
    }
    return nil;
}

+ (BOOL)isExecutableAtPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExecutable = [fileManager isExecutableFileAtPath:path];
    return isExecutable;
}

+ (NSString *)resolveToolchainPathForExecutables:(NSArray<NSString *> *)executables inPathComponents:(NSArray<NSString *> *)pathComponents
{
    for (NSString *path in pathComponents)
    {
        NSLog(@"Testing path: %@", path);
        BOOL allFound = YES;
        for (NSString *binary in executables)
        {
            NSString *binaryPath = [path stringByAppendingPathComponent:binary];
            if (![self isExecutableAtPath:binaryPath])
            {
                allFound = NO;
                break;
            }
        }
        if (allFound)
        {
            return path;
        }
    }
    return nil;
}

+ (NSString *)pythonVersionAtPath:(NSString *)pythonPath
{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = pythonPath;
    task.arguments = @[@"--version"];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe; // Some versions of Python might output the version to stderr

    NSFileHandle *fileHandle = [pipe fileHandleForReading];

    [task launch];
    [task waitUntilExit];

    NSData *data = [fileHandle readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    // Python may output the version with a leading "Python " prefix, so we need to extract the version part.
    NSString *version = [output stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // The expected format is "Python X.Y.Z", so we need to remove the "Python " prefix.
    if ([version hasPrefix:@"Python 2.7"])
    {
        version = [version substringFromIndex:7];
    }

    return version;
}

@end
