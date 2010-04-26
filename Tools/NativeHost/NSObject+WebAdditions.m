//
//  NSObject+WebAdditions.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 11/16/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import "NSObject+WebAdditions.h"


@implementation NSObject (WebAdditions)

- (BOOL)webBoolValue
{
    return [self isKindOfClass:[NSNumber class]] && [(NSNumber *)self boolValue];
}

@end
