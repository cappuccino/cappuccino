//
//  XCCAbstractOperation.m
//  XcodeCapp
//
//  Created by Antoine Mercadal on 6/2/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import "XCCAbstractOperation.h"


@implementation XCCAbstractOperation

- (instancetype)initWithCappuccinoProject:(XCCCappuccinoProject *)aCappuccinoProject taskLauncher:(XCCTaskLauncher*)aTaskLauncher
{
    if (self = [super init])
    {
        self.cappuccinoProject  = aCappuccinoProject;
        self->taskLauncher      = aTaskLauncher;
    }

    return self;
}

- (NSMutableDictionary *)operationInformations
{
    return [@{@"cappuccinoProject": self.cappuccinoProject} mutableCopy];
}

- (void)dispatchNotificationName:(NSString *)notificationName
{
    [self dispatchNotificationName:notificationName userInfo:[self operationInformations]];
}

- (void)dispatchNotificationName:(NSString *)notificationName userInfo:(id)userInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:userInfo];
    });
}


@end
