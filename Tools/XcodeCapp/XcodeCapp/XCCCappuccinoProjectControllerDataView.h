//
//  CappuccinoProjectCellView.h
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/11/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XCCCappuccinoProjectController.h"
#import "YRKSpinningProgressIndicator.h"

@interface XCCCappuccinoProjectControllerDataView : NSTableCellView
{
    IBOutlet NSBox                          *lineBottom;
    IBOutlet NSTextField                    *fieldNickname;
    IBOutlet NSTextField                    *fieldPath;
    IBOutlet NSButton                       *buttonSwitchStatus;
    IBOutlet NSButton                       *buttonOpenXcodeProject;
    IBOutlet NSButton                       *buttonResetProject;
    IBOutlet NSButton                       *buttonOpenInFinder;
    IBOutlet NSButton                       *buttonOpenInEditor;
    IBOutlet NSButton                       *buttonOpenInTerminal;
    IBOutlet NSBox                          *boxStatus;
    IBOutlet YRKSpinningProgressIndicator   *operationsProgressIndicator;
}

@property XCCCappuccinoProjectController    *controller;

@end
