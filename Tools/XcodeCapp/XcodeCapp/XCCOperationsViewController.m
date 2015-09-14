//
//  XCCOperationsViewController.m
//  XcodeCapp
//
//  Created by Antoine Mercadal on 6/4/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import "XCCOperationsViewController.h"
#import "XCCCappuccinoProjectController.h"
#import "XCCCappuccinoProject.h"
#import "XCCOperationDataView.h"
#import "XCCSourcesFinderOperation.h"
#import "XCCSourceProcessingOperation.h"
#import "XCCPPXOperation.h"
#import "AppDelegate.h"

@implementation XCCOperationsViewController

@synthesize cappuccinoProjectController = _cappuccinoProjectController;

#pragma nark - Initialization

- (void)viewDidLoad
{
    [super viewDidLoad];

    self->operationQueue = [((AppDelegate *)[NSApp delegate]) mainOperationQueue];
}


#pragma nark - Utilities

- (void)_showMaskingView:(BOOL)shouldShow
{
    if (shouldShow)
    {
        if (self->maskingView.superview)
            return;

        [self->operationTableView setHidden:YES];

        self->maskingView.frame = [self.view bounds];
        [self.view addSubview:self->maskingView];
    }
    else
    {
        if (!self->maskingView.superview)
            return;

        [self->operationTableView setHidden:NO];

        [self->maskingView removeFromSuperview];
    }
}

- (void)reload
{
    [self->operationTableView reloadData];

    [self _showMaskingView:![self.cappuccinoProjectController projectRelatedOperations].count];
}


#pragma mark - actions

- (IBAction)cancelAllOperations:(id)sender
{
    [self.cappuccinoProjectController cancelAllOperations:sender];
    [self reload];
}


#pragma mark - tableView delegate and datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    // we create a snapshot at that moment, so if some operations are removed during the time between
    // the count and reloadData, we don't crash.
     self->operationsSnaphsot = [[[self.cappuccinoProjectController projectRelatedOperations] sortedArrayUsingComparator:^(NSOperation * op1, NSOperation * op2){

        if (op1.isCancelled)
            return NSOrderedDescending;

         if (op2.isCancelled)
             return NSOrderedAscending;

         if ([op1.dependencies containsObject:op2])
             return NSOrderedDescending;

         if ([op2.dependencies containsObject:op1])
             return NSOrderedAscending;

         if (op1.isExecuting && !op2.isExecuting)
            return NSOrderedAscending;

         if (!op1.isExecuting && op2.isExecuting)
            return NSOrderedDescending;



        return NSOrderedSame;
    }] copy];

    return self->operationsSnaphsot.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    XCCOperationDataView *dataView = [tableView makeViewWithIdentifier:@"OperationDataView" owner:nil];
    [dataView setOperation:self->operationsSnaphsot[row]];

    return dataView;
}

@end
