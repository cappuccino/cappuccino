//
//  CappuccinoProject.h
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/6/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XCCOperationError.h"

@class XCCTaskLauncher;

typedef NS_ENUM(NSInteger, XCCCappuccinoProjectStatus)
{
    XCCCappuccinoProjectStatusStopped,
    XCCCappuccinoProjectStatusListening
};


extern NSString * const XCCCompatibilityVersionKey;
extern NSString * const XCCCappuccinoProjectBinPathsKey;
extern NSString * const XCCCappuccinoProjectPreviousStatusKey;


@interface XCCCappuccinoProject : NSObject
{
    NSMutableDictionary             *settings;
}

@property NSString                      *supportPath;
@property NSString                      *projectPath;
@property NSString                      *name;
@property NSString                      *nickname;
@property NSString                      *XcodeProjectPath;
@property NSString                      *settingsPath;
@property NSString                      *XcodeCappIgnorePath;
@property NSNumber                      *lastEventID;
@property NSString                      *PBXModifierScriptPath;
@property NSMutableDictionary           *projectPathsForSourcePaths;
@property NSMutableArray                *ignoredPathPredicates;
@property NSString                      *version;
@property NSString                      *objjIncludePath;
@property NSMutableArray                *binaryPaths;
@property NSString                      *XcodeCappIgnoreContent;
@property BOOL                          processObjjWarnings;
@property BOOL                          processCappLint;
@property BOOL                          processObjj2ObjcSkeleton;
@property BOOL                          processNib2Cib;
@property XCCCappuccinoProjectStatus    status;
@property XCCCappuccinoProjectStatus    previousSavedStatus;


+ (BOOL)isObjjFile:(NSString *)path;
+ (BOOL)isXibFile:(NSString *)path;
+ (BOOL)isCibFile:(NSString *)path;
+ (BOOL)isHeaderFile:(NSString *)path;
+ (BOOL)isXCCIgnoreFile:(NSString *)path cappuccinoProject:(XCCCappuccinoProject*)aCappuccinoProject;
+ (BOOL)isSourceFile:(NSString *)path cappuccinoProject:(XCCCappuccinoProject*)aCappuccinoProject;
+ (BOOL)pathMatchesIgnoredPaths:(NSString*)aPath cappuccinoProjectIgnoredPathPredicates:(NSMutableArray*)cappuccinoProjectIgnoredPathPredicates;
+ (BOOL)shouldIgnoreDirectoryNamed:(NSString *)filename;
+ (void)watchSymlinkedDirectoriesAtPath:(NSString *)projectPath pathsToWatch:(NSMutableArray *)pathsToWatch cappuccinoProject:(XCCCappuccinoProject*)aCappuccinoProject;
+ (NSArray *)defaultBinaryPaths;
+ (NSArray *)parseIgnorePaths:(NSArray *)paths basePath:(NSString *)basePath;
+ (NSArray *)getPathsToWatchForCappuccinoProject:(XCCCappuccinoProject*)aCappuccinoProject;

- (instancetype)initWithPath:(NSString*)aPath;
- (void)reinitialize;
- (void)saveSettings;
- (void)reloadXcodeCappIgnoreFile;

- (NSString *)projectRelativePathForPath:(NSString *)path;
- (NSString *)shadowBasePathForProjectSourcePath:(NSString *)path;
- (NSString *)sourcePathForShadowPath:(NSString *)path;
- (NSString *)projectPathForSourcePath:(NSString *)path;
- (NSString *)flattenedXcodeSupportFileNameForPath:(NSString *)aPath;

@end
