//
//  main.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 5/24/09.
//  Copyright 280 North, Inc. 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Application.h"

int interactive = 0;

int main(int argc, char *argv[])
{
    if (argc > 1 && strcmp(argv[1], "-i") == 0) {
        interactive = 1;
    }

    [Application sharedApplication];

    return NSApplicationMain(argc,  (const char **) argv);
}
