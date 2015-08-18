//
//  OperationErrorHeaderCellView.m
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/22/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import "XCCOperationErrorHeaderDataView.h"


@implementation XCCOperationErrorHeaderDataView

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    if (!newWindow)
        return;
    
    if (self.fileName)
        self->fieldName.stringValue = self.fileName;
    else
        self->fieldName.stringValue = @"No name";
}
@end
