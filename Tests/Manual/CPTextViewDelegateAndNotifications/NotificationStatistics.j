/*
 * NotificationStatistics.j
 * CPTextViewDelegateAndNotifications
 *
 * Created by Martin Carlberg on December 22, 2017.
 * Copyright 2017, Oops AB All rights reserved.
 */

@import <Foundation/CPObject.j>

@implementation NotificationStatistics : CPObject {
    CPString name @accessors;
    CPUInteger order @accessors;
    CPUInteger count @accessors;
}

+ (id)notificationStatisticsWithName:(CPString)aName
{
    return [[NotificationStatistics alloc] initWithName:aName];
}

- (id)initWithName:(CPString)aName
{
    self = [super init];
    if (self) {
        [self setName: aName];
        [self setOrder:0];
        [self setCount:0];
    }
    return self;
}

@end
