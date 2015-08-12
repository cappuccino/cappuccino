//
//  TaskLauncher.h
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/6/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, XCCTaskReturnType)
{
    kTaskReturnTypeNone,
    kTaskReturnTypeStdOut,
    kTaskReturnTypeStdError,
    kTaskReturnTypeAny
};


@interface XCCTaskLauncher : NSObject

@property BOOL isValid;

@property NSMutableArray *binaryPaths;
@property NSMutableDictionary *environment;

@property NSArray *executables;
@property NSMutableDictionary *executablePaths;

- (instancetype)initWithEnvironmentPaths:(NSArray*)environementPaths NS_DESIGNATED_INITIALIZER;

- (NSTask*)taskWithCommand:(NSString *)aCommand arguments:(NSArray *)arguments;
- (NSTask*)taskWithCommand:(NSString *)aCommand arguments:(NSArray *)arguments currentDirectoryPath:(NSString*)aCurrentDirectoryPath;

- (NSDictionary *)runTaskWithCommand:(NSString *)aCommand arguments:(NSArray *)arguments returnType:(XCCTaskReturnType)returnType;
- (NSDictionary *)runTaskWithCommand:(NSString *)aCommand arguments:(NSArray *)arguments returnType:(XCCTaskReturnType)returnType currentDirectoryPath:(NSString*)aCurrentDirectoryPath;
- (NSDictionary*)runTask:(NSTask*)aTask returnType:(XCCTaskReturnType)returnType;
- (NSDictionary*)runJakeTaskWithArguments:(NSMutableArray*)arguments currentDirectoryPath:(NSString*)aCurrentDirectoryPath;

@end
