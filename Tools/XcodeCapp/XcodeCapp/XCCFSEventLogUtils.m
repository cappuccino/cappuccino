//
//  LogUtils.m
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/8/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import "XCCFSEventLogUtils.h"

@implementation XCCFSEventLogUtils

+ (NSString *)dumpFSEventFlags:(FSEventStreamEventFlags)flags
{
    BOOL created = (flags & kFSEventStreamEventFlagItemCreated) != 0;
    BOOL removed = (flags & kFSEventStreamEventFlagItemRemoved) != 0;
    BOOL inodeMetaModified = (flags & kFSEventStreamEventFlagItemInodeMetaMod) != 0;
    BOOL renamed = (flags & kFSEventStreamEventFlagItemRenamed) != 0;
    BOOL modified = (flags & kFSEventStreamEventFlagItemModified) != 0;
    BOOL finderInfoModified = (flags & kFSEventStreamEventFlagItemFinderInfoMod) != 0;
    BOOL changedOwner = (flags & kFSEventStreamEventFlagItemChangeOwner) != 0;
    BOOL xattrModified = (flags & kFSEventStreamEventFlagItemXattrMod) != 0;
    BOOL isFile = (flags & kFSEventStreamEventFlagItemIsFile) != 0;
    BOOL isDir = (flags & kFSEventStreamEventFlagItemIsDir) != 0;
    BOOL isSymlink = (flags & kFSEventStreamEventFlagItemIsSymlink) != 0;
    
    NSMutableArray *flagNames = [@[] mutableCopy];
    
    if (created)
        [flagNames addObject:@"created"];
    
    if (removed)
        [flagNames addObject:@"removed"];
    
    if (inodeMetaModified)
        [flagNames addObject:@"inode"];
    
    if (renamed)
        [flagNames addObject:@"renamed"];
    
    if (modified)
        [flagNames addObject:@"modified"];
    
    if (finderInfoModified)
        [flagNames addObject:@"Finder info"];
    
    if (changedOwner)
        [flagNames addObject:@"owner"];
    
    if (xattrModified)
        [flagNames addObject:@"xattr"];
    
    if (isFile)
        [flagNames addObject:@"file"];
    
    if (isDir)
        [flagNames addObject:@"dir"];
    
    if (isSymlink)
        [flagNames addObject:@"symlink"];
    
    return [flagNames componentsJoinedByString:@", "];
}

@end
