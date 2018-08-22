//
//  XCCSettingsViewController.h
//  XcodeCapp
//
//  Created by Antoine Mercadal on 6/4/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class XCCCappuccinoProjectController;


@interface XCCSettingsViewController : NSViewController  <NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet    NSTableView     *tableViewBinaryPaths;
    IBOutlet    NSButton        *checkBoxProcessNib2Cib;
    IBOutlet    NSButton        *checkBoxProcessObjj;
    IBOutlet    NSButton        *checkBoxProcessObjj2Skeleton;
    IBOutlet    NSButton        *checkBoxProcessCappLint;
    IBOutlet    NSTextField     *fieldObjjIncludePath;
    IBOutlet    NSTextField     *fieldXcodeCappIgnoreContent;

    BOOL                        isObserving;
}

@property XCCCappuccinoProjectController *cappuccinoProjectController;

- (void)reload;

@end
