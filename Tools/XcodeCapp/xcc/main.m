//
//  main.m
//  xcc
//
//  Created by Aparajita on 5/9/13.
//  Copyright (c) 2013 Cappuccino Project. All rights reserved.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        BOOL validArgs = argc == 1;
        NSMutableArray *arguments = [[NSMutableArray alloc] initWithObjects:@"-b", @"org.cappuccino.xcodecapp", @"-g", nil];

        if (argc > 1)
        {
            const char *arg = argv[1];

            if (arg[0] == '-')
            {
                printf("Usage: xcc [--help | directory]\n");
            }
            else
            {
                NSString *path = [[NSString stringWithUTF8String:arg] stringByStandardizingPath];
                NSFileManager *fm = [NSFileManager defaultManager];
                BOOL isDirectory;
                BOOL exists = [fm fileExistsAtPath:path isDirectory:&isDirectory];

                if (!exists)
                    fprintf(stderr, "%s: no such file or directory\n", arg);
                else if (!isDirectory)
                    fprintf(stderr, "%s is not a directory\n", arg);
                else
                {
                    validArgs = YES;
                    [arguments addObject:path];
                }
            }
        }

        if (validArgs)
        {
            NSTask *task = [[NSTask alloc] init];
            task.launchPath = @"/usr/bin/open";
            task.arguments = arguments;
            [task launch];
        }
    }
    
    return 0;
}

