//
//  Path.h
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/20/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XCCPath : NSObject

@property NSString *name;

- (instancetype)initWithName:(NSString*)aName NS_DESIGNATED_INITIALIZER;

@end
