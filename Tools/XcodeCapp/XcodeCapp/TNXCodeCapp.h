/*
 * This file is a part of program XcodeCapp
 * Copyright (C) 2011  Antoine Mercadal (<primalmotion@archipelproject.org>)
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

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

enum XCCAPIMode {
    kXCCAPIModeAuto = 0,
    kXCCAPIModeFile,
    kXCCAPIModeFolder
};

extern NSString * const XCCDidPopulateProjectNotification;
extern NSString * const XCCConversionDidStartNotification;
extern NSString * const XCCConversionDidStopNotification;
extern NSString * const XCCListeningDidStartNotification;


@interface TNXcodeCapp : NSObject <NSTableViewDelegate, GrowlApplicationBridgeDelegate>

@property NSURL* XcodeSupportProjectURL;
@property NSString* currentProjectPath;
@property NSString* currentAPIMode;
@property BOOL supportsFileBasedListening;
@property BOOL reactToInodeModification;
@property BOOL isListening;
@property BOOL supportsFileLevelAPI;
@property BOOL isUsingFileLevelAPI;
@property BOOL isLoadingProject;
@property NSMutableArray* errorList;

@property (unsafe_unretained) IBOutlet NSTableView *errorTable;
@property (strong) IBOutlet NSPanel *errorsPanel;
@property (strong) IBOutlet NSArrayController *errorListController;

- (IBAction)openErrorsPanel:(id)sender;
- (IBAction)clearErrors:(id)sender;
- (IBAction)openErrorInEditor:(id)sender;
- (void)start;
- (void)stop;
- (void)listenToProjectAtPath:(NSString *)path;
- (void)updateLastEventId:(uint64_t)eventId;
- (BOOL)pathMatchesIgnoredPaths:(NSString*)aPath;
- (BOOL)isObjjFile:(NSString *)path;
- (BOOL)isXibFile:(NSString *)path;
- (BOOL)isXCCIgnoreFile:(NSString *)path;
- (void)tidyShadowedFiles;
- (void)handleFileModificationAtPath:(NSString*)path notify:(BOOL)shouldNotify;
- (void)handleFileRemovalAtPath:(NSString*)path;
- (void)updateUserDefaultsWithLastEventId;

@end

@interface TNXcodeCapp (SnowLeopard)

- (void)updateLastModificationDate:(NSDate *)date forPath:(NSString *)path;
- (NSDate *)lastModificationDateForPath:(NSString *)path;

@end
