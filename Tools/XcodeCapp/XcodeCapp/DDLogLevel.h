//
//  DDLogLevel.h
//  XcodeCapp
//
//  Created by Aparajita on 4/29/13.
//  Copyright (c) 2013 Cappuccino Project. All rights reserved.
//

#import <Foundation/Foundation.h>

extern int ddLogLevel;

@interface DDLogLevel : NSObject

+ (void)setLogLevel:(int)logLevel;

@end
