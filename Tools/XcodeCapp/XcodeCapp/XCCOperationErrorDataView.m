//
//  OperationErrorCellView.m
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/21/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import "XCCOperationErrorDataView.h"
#import "XCCOperationError.h"

@implementation XCCOperationErrorDataView

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    if (!newWindow)
        return;
    
    if (self.errorOperation.message)
        self->fieldMessage.stringValue = self.errorOperation.message;
    else
        self->fieldMessage.stringValue = @"No message";
    
    if (self.errorOperation.lineNumber)
        self->fieldLineNumber.stringValue = self.errorOperation.lineNumber;
    else
        self->fieldLineNumber.stringValue = @"0";
    
    switch (self.errorOperation.errorType)
    {
        case XCCCappLintOperationErrorType:
        case XCCNib2CibOperationErrorType:
            [self->imageViewType setImage:[NSImage imageNamed:@"NSStatusPartiallyAvailable"]];
            break;
        
        default:
            [self->imageViewType setImage:[NSImage imageNamed:@"NSStatusUnavailable"]];
    }
}

@end