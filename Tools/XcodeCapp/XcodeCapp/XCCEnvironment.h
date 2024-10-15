//
//  XCCEnvironment.h
//  XcodeCapp
//
//  Created by David Richardson on 2024-08-26.
//  Copyright © 2024 cappuccino-project. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCCEnvironment : NSObject

// Main method to load the environment and retrieve toolchain paths
+ (NSDictionary<NSString *, NSString *> *)loadEnvironmentFromUserShell;

// Helper methods
+ (NSString *)findPython27ExecutableInPath:(NSArray<NSString *> *)pathComponents;
+ (NSString *)findExecutable:(NSString *)executableName inPath:(NSArray<NSString *> *)pathComponents;
+ (BOOL)isExecutableAtPath:(NSString *)path;
+ (NSString *)resolveToolchainPathForExecutables:(NSArray<NSString *> *)executables inPathComponents:(NSArray<NSString *> *)pathComponents;

@end

NS_ASSUME_NONNULL_END
