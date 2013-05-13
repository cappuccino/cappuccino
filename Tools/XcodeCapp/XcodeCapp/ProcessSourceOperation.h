//
//  ProcessSourceOperation.h
//  XcodeCapp
//
//  Created by Aparajita on 4/27/13.
//  Copyright (c) 2013 Cappuccino Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XcodeCapp;


@interface ProcessSourceOperation : NSOperation

// sourcePath should be a path within the project (no resolved symlinks)
- (id)initWithXCC:(XcodeCapp *)xcc projectId:(NSNumber *)projectId sourcePath:(NSString *)sourcePath;

@end
