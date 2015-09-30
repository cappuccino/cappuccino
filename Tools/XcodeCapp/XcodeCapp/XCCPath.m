//
//  Path.m
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/20/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import "XCCPath.h"

@implementation XCCPath

- (instancetype)initWithName:(NSString*)aName
{
    if (self = [super init])
        self.name = aName;
    
    return self;
}

- (instancetype)init
{
    return [self initWithName:@"~/bin"];
}

@end
