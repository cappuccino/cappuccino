//
//  CappuccinoProjectController.h
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/7/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XCCAbstractOperation;
@class XCCCappuccinoProject;
@class XCCTaskLauncher;
@class XCCMainController;
@class XCCPPXOperation;
@class XCCSourcesFinderOperation;


@interface XCCCappuccinoProjectController : NSObject
{
    BOOL                        isListeningToOperationNotifications;
    XCCTaskLauncher             *taskLauncher;
    NSOperationQueue            *operationQueue;
    FSEventStreamRef            stream;
    NSMutableDictionary         *sourceProcessingOperations;
    XCCPPXOperation             *pendingPBXOperation;
    XCCSourcesFinderOperation   *currentFindSourceOperation;
}

@property CGFloat               operationsProgress;
@property NSInteger             numberOfErrors;
@property NSInteger             operationsTotal;
@property NSMutableDictionary   *errors;
@property NSInteger             operationsRemaining;
@property NSString              *operationsRemainingString;
@property NSString              *errorsCountString;
@property XCCCappuccinoProject  *cappuccinoProject;
@property XCCMainController     *mainXcodeCappController;

- (instancetype)initWithPath:(NSString*)aPath controller:(id)aController;
- (void)reinitializeProjectFromSettings;
- (void)applicationIsClosing;
- (void)cleanUpBeforeDeletion;
- (void)operationDidStart:(XCCAbstractOperation*)anOperation type:(NSString*)aType userInfo:(NSDictionary*)userInfo;
- (void)operationDidEnd:(XCCAbstractOperation*)anOperation type:(NSString*)aType userInfo:(NSDictionary*)userInfo;
- (void)launchEditorForPath:(NSString*)path line:(NSInteger)line;
- (void)removeAllOperationErrors;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *projectRelatedOperations;
;
- (IBAction)cancelAllOperations:(id)aSender;
- (IBAction)resetProject:(id)aSender;
- (IBAction)openProjectInXcode:(id)sender;
- (IBAction)openProjectInFinder:(id)sender;
- (IBAction)openProjectInEditor:(id)sender;
- (IBAction)openProjectInTerminal:(id)sender;
- (IBAction)switchProjectListeningStatus:(id)sender;

@end
