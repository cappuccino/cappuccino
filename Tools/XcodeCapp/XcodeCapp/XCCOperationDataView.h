//
//  OperationCellView.h
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/20/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class XCCSourceProcessingOperation;

@interface XCCOperationDataView : NSTableCellView
{
    IBOutlet NSBox                      *boxStatus;
    IBOutlet NSTextField                *fieldName;
    IBOutlet NSTextField                *fieldDescription;
    
}

@property XCCSourceProcessingOperation  *operation;

@end
