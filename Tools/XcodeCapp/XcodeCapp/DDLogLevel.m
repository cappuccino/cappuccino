//
//  DDLog.m
//  XcodeCapp
//
//  Created by Aparajita on 4/29/13.
//  Copyright (c) 2013 Cappuccino Project. All rights reserved.
//

#import "DDLogLevel.h"


int ddLogLevel = LOG_LEVEL_OFF;


@implementation DDLogLevel

+ (int)ddLogLevel
{
    return ddLogLevel;
}

+ (void)setLogLevel:(int)logLevel
{
    ddLogLevel = logLevel;
}

@end
