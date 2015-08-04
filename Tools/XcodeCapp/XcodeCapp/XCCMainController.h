//
//  MainWindowController.h
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/20/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XCCCappuccinoProject;
@class XCCCappuccinoProjectController;
@class XCCOperationsViewController;
@class XCCErrorsViewController;
@class XCCSettingsViewController;
@class XCCWelcomeView;

@interface XCCMainController : NSWindowController <NSSplitViewDelegate, NSTableViewDataSource, NSTableViewDelegate, NSUserNotificationCenterDelegate>
{
    IBOutlet NSMenu                         *menuTableViewProject;
    IBOutlet NSBox                          *maskingView;
    IBOutlet NSSplitView                    *splitView;
    IBOutlet NSTableView                    *projectTableView;
    IBOutlet NSView                         *projectViewContainer;
    IBOutlet NSTabView                      *tabViewProject;
    IBOutlet NSButton                       *buttonSelectConfigurationTab;
    IBOutlet NSButton                       *buttonSelectErrorsTab;
    IBOutlet NSButton                       *buttonSelectOperationsTab;
    IBOutlet XCCWelcomeView                 *welcomeViewMask;
}

@property IBOutlet XCCSettingsViewController    *settingsViewController;
@property IBOutlet XCCOperationsViewController  *operationsViewController;
@property IBOutlet XCCErrorsViewController      *errorsViewController;
@property NSMutableArray                        *cappuccinoProjectControllers;
@property XCCCappuccinoProjectController        *currentCappuccinoProjectController;
@property int                                   totalNumberOfErrors;

- (void)manageCappuccinoProjectControllerForPath:(NSString *)aProjectPath;
- (void)unmanageCappuccinoProjectController:(XCCCappuccinoProjectController *)aController;
- (void)reloadTotalNumberOfErrors;
- (void)notifyCappuccinoControllersApplicationIsClosing;

- (IBAction)cleanAllErrors:(id)aSender;
- (IBAction)addProject:(id)aSender;
- (IBAction)removeProject:(id)aSender;
- (IBAction)updateSelectedTab:(id)aSender;

@end