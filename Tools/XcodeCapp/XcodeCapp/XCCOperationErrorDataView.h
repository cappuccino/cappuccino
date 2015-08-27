//
//  OperationErrorCellView.h
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/21/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class XCCOperationError;

@interface XCCOperationErrorDataView : NSTableCellView
{
    IBOutlet NSTextField    *fieldMessage;
    IBOutlet NSTextField    *fieldLineNumber;
    IBOutlet NSTextField    *labelLineNumber;
    IBOutlet NSImageView    *imageViewType;
}

@property IBOutlet NSButton *buttonOpenInEditor;
@property XCCOperationError *errorOperation;

@end
