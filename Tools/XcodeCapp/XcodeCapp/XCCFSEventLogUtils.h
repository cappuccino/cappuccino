//
//  LogUtils.h
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/8/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XCCFSEventLogUtils : NSObject

+ (NSString *)dumpFSEventFlags:(FSEventStreamEventFlags)flags;

@end
