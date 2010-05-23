//
//  Server.h
//  NativeHost
//
//  Created by Francisco Tolmasky on 8/18/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Server : NSObject
{
    NSFileHandle    * outputFile;
    NSFileHandle    * errorFile;
    NSTask          * process;
}

- (BOOL)start;
- (void)stop;

@end
