//
//  XcodeProjectCloser.m
//  XcodeCapp
//
//  Created by Aparajita on 5/12/13.
//  Copyright (c) 2013 Cappuccino Project. All rights reserved.
//

#import "XcodeProjectCloser.h"


// Used to close the Xcode project if it is open.
static const char *kCloseXcodeProjectScript =
    "tell application \"Xcode\"\n"
        "set docs to (document of every window)\n"
        "repeat with doc in docs\n"
            "if class of doc is workspace document then\n"
                "set docPath to path of doc\n"
                "if docPath begins with \"%@\" then\n"
                    "close doc\n"
                    "return\n"
                "end if\n"
            "end if\n"
        "end repeat\n"
    "end tell";


@implementation XcodeProjectCloser

+ (void)closeXcodeProjectForProject:(NSString *)projectPath
{    
    NSString    *format     = @(kCloseXcodeProjectScript);
    NSString    *source     = [NSString stringWithFormat:format, projectPath];
    NSString    *arguments  = [NSString stringWithFormat:@"-e %@", source];
    NSTask      *task       = [[NSTask alloc] init];
    
    [task setLaunchPath:@"/usr/bin/osascript"];
    [task setArguments:[NSArray arrayWithObjects:arguments, nil]];
    [task launch];
    
    NSLog(@"Osascript launched for the project %@", projectPath);
}

@end
