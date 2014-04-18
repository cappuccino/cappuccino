//
//  main.m
//  xcc
//
//  Created by Aparajita on 5/9/13.
//  Copyright (c) 2013 Cappuccino Project. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XcodeProjectCloser.h"


static void usage()
{
    fprintf(stderr, "Usage: xcc [options] [directory]\n"
            "\n"
            "Options:\n"
            "  --help   Show this help and exit\n"
            "  --reset  Resets Xcode support files before opening\n\n");
}

static bool handleOptions(NSMutableArray *options, NSString *path)
{
    NSFileManager *fm = [NSFileManager defaultManager];
            
    path = path.stringByStandardizingPath.stringByResolvingSymlinksInPath;
    
    while (options.count)
    {
        NSString *option = options.lastObject;
        [options removeLastObject];

        if ([options containsObject:option])
            return false;

        if ([option isEqualToString:@"--reset"])
        {
            if (!path)
                return false;

            NSString *xcodePath = [path stringByAppendingPathComponent:@".XcodeSupport"];
            [fm removeItemAtPath:xcodePath error:nil];

            NSString *projectName = [NSString stringWithFormat:@"%@.xcodeproj", path.lastPathComponent];
            xcodePath = [path stringByAppendingPathComponent:projectName];

            [XcodeProjectCloser closeXcodeProjectForProject:xcodePath];
            
            [fm removeItemAtPath:xcodePath error:nil];
            printf("Reset %s\n", path.UTF8String);
        }
        else
            return false;
    }

    return true;
}

static NSString* validatePath(NSString *path)
{
    // Use an NSURL to resolve paths that start with "."
    NSURL *url = [NSURL fileURLWithPath:path];
    path = url.path;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDirectory;
    BOOL exists = [fm fileExistsAtPath:path isDirectory:&isDirectory];

    if (exists && isDirectory)
        return path;
    else
    {
        if (!exists)
            fprintf(stderr, "The directory %s does not exist.\n", path.UTF8String);
        else
            fprintf(stderr, "%s is not a directory.\n", path.UTF8String);

        return nil;
    }
}


int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        NSArray *args = [[NSProcessInfo processInfo] arguments];
        BOOL validArgs = args.count == 1;
        NSString *path = nil;
        NSMutableArray *options = [NSMutableArray new];

        for (NSInteger i = 1; i < args.count; ++i)
        {
            NSString *arg = args[i];
            
            // Once we get a directory, no other arguments are valid
            if (path)
            {
                validArgs = NO;
                break;
            }

            if ([arg hasPrefix:@"-"])
            {
                [options addObject:arg];
            }
            else if (!path)
            {
                path = validatePath(arg);

                if (path)
                    validArgs = YES;
                else
                    return 1;
            }
            else
            {
                validArgs = NO;
                break;
            }
        }

        if (validArgs)
        {
            if (handleOptions(options, path))
            {
                NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"-b", @"org.cappuccino.xcodecapp", @"-g", nil];

                if (path)
                    [arguments addObject:path];
                
                NSTask *task = [[NSTask alloc] init];
                task.launchPath = @"/usr/bin/open";
                task.arguments = arguments;
                [task launch];
            }
            else
                usage();
        }
        else
            usage();
    }
    
    return 0;
}

