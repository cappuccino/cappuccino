/*
 * This file is a part of program xcodecapp-cocoa
 * Copyright (C) 2011  Antoine Mercadal (primalmotion@archipelproject.org)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <Foundation/Foundation.h>
#import "PRHEmptyGrowlDelegate.h"
#import "FSEventCallback.h"

extern NSString * const XCCDidPopulateProjectNotification;
extern NSString * const XCCConversionStartNotification;
extern NSString * const XCCConversionStopNotification;
extern NSString * const XCCListeningStartNotification;


@interface TNXCodeCapp : NSObject
{
    FSEventStreamRef                stream;
    NSFileManager                   *fm;
    NSMutableArray                  *errorList;
    NSMutableArray                  *ignoredFilePaths;
    NSNumber                        *lastEventId;
    NSString                        *currentProjectName;
    NSString                        *parserPath;
    NSString                        *XCodeSupportPBXPath;
    NSString                        *XCodeSupportProjectName;
    NSString                        *XCodeTemplatePBXPath;
    NSString                        *profilePath;
    NSURL                           *currentProjectURL;
    NSURL                           *XCodeSupportFolder;
    NSURL                           *XCodeSupportProject;
    NSURL                           *XCodeSupportProjectSources;
    PRHEmptyGrowlDelegate           *growlDelegateRef;
    NSObject                        *delegate;
}

@property (retain) NSObject* delegate;
@property (retain) NSMutableArray* errorList;
@property (retain) NSURL* XCodeSupportProject;
@property (retain) NSURL* currentProjectURL;
@property (retain) NSString* currentProjectName;

- (BOOL)isObjJFile:(NSString*)path;
- (void)computeIgnoredPaths;
- (BOOL)isPathMatchingIgnoredPaths:(NSString*)aPath;
- (BOOL)isXIBFile:(NSString *)path;
- (BOOL)isXCCIgnoreFile:(NSString *)path;
- (BOOL)prepareXCodeSupportProject;
- (NSURL*)shadowURLForSourceURL:(NSURL*)aSourceURL;
- (void)handleFileModification:(NSString*)fullPath notify:(BOOL)shouldNotify;
- (void)handleFileRemoval:(NSString*)fullPath;
- (void)initializeEventStreamWithPath:(NSString*)aPath;
- (void)stopEventStream;
- (void)updateLastEventId:(uint64_t)eventId;
- (void)listenProjectAtPath:(NSString *)path;
- (void)clear;
- (void)start;


@end
