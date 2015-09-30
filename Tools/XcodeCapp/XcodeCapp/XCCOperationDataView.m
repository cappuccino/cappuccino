//
//  OperationCellView.m
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/20/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import "XCCOperationDataView.h"
#import "XCCSourceProcessingOperation.h"

static NSColor * XCCOperationDataViewColorExecuting;
static NSColor * XCCOperationDataViewColorPending;
static NSColor * XCCOperationDataViewColorFinished;
static NSColor * XCCOperationDataViewColorCanceled;


@implementation XCCOperationDataView

+ (void)initialize
{
    XCCOperationDataViewColorExecuting  = [NSColor colorWithCalibratedRed:107.0/255.0 green:148.0/255.0 blue:236.0/255.0 alpha:1.0];
    XCCOperationDataViewColorPending    = [NSColor colorWithCalibratedRed:236.0/255.0 green:236.0/255.0 blue:236.0/255.0 alpha:1.0];
    XCCOperationDataViewColorFinished   = [NSColor colorWithCalibratedRed:179.0/255.0 green:214.0/255.0 blue:69.0/255.0 alpha:1.0];
    XCCOperationDataViewColorCanceled   = [NSColor colorWithCalibratedRed:253.0/255.0 green:125/255.0 blue:8.0/255.0 alpha:1.0];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    if (newWindow)
    {
        [self _updateDataView];
        [self.operation addObserver:self forKeyPath:@"operationName" options:NSKeyValueObservingOptionNew context:nil];
        [self.operation addObserver:self forKeyPath:@"operationDescription" options:NSKeyValueObservingOptionNew context:nil];
        [self.operation addObserver:self forKeyPath:@"isExecuting" options:NSKeyValueObservingOptionNew context:nil];
    }
    else
    {
        [self.operation removeObserver:self forKeyPath:@"operationName"];
        [self.operation removeObserver:self forKeyPath:@"operationDescription"];
        [self.operation removeObserver:self forKeyPath:@"isExecuting"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(XCCSourceProcessingOperation *)operation change:(NSDictionary *)change context:(void *)context
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _updateDataView];
    });
}

- (void)_updateDataView
{
    self->fieldName.stringValue         = self.operation.operationName;
    self->fieldDescription.stringValue  = self.operation.operationDescription;

    if (self.operation.isExecuting)
        self->boxStatus.fillColor = XCCOperationDataViewColorExecuting;
    else if (self.operation.isCancelled)
        self->boxStatus.fillColor = XCCOperationDataViewColorCanceled;
    else if (self.operation.isFinished)
        self->boxStatus.fillColor = XCCOperationDataViewColorFinished;
    else
        self->boxStatus.fillColor = XCCOperationDataViewColorPending;
}

@end


