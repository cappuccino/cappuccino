//
//  OperationErrorHeaderCellView.h
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/22/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XCCOperationError.h"


@interface XCCOperationErrorHeaderDataView : NSTableCellView
{
    IBOutlet NSTextField *fieldName;
}

@property NSString *fileName;

@end
