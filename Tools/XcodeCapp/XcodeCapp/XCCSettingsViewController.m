//
//  XCCSettingsViewController.m
//  XcodeCapp
//
//  Created by Antoine Mercadal on 6/4/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import "XCCSettingsViewController.h"
#import "XCCCappuccinoProjectController.h"
#import "XCCCappuccinoProject.h"
#import "XCCPath.h"

@implementation XCCSettingsViewController

@synthesize cappuccinoProjectController = _cappuccinoProjectController;


#pragma Initialization

- (void)viewDidLoad
{
    [super viewDidLoad];
}


#pragma Utilities

- (void)reload
{
    XCCCappuccinoProject * project = self.cappuccinoProjectController.cappuccinoProject;

    if (project)
    {
        [self->fieldXcodeCappIgnoreContent bind:NSValueBinding toObject:project withKeyPath:@"XcodeCappIgnoreContent" options:nil];
        [self->fieldObjjIncludePath bind:NSValueBinding toObject:project withKeyPath:@"objjIncludePath" options:nil];
        [self->checkBoxProcessObjj2Skeleton bind:NSValueBinding toObject:project withKeyPath:@"processObjj2ObjcSkeleton" options:nil];
        [self->checkBoxProcessNib2Cib bind:NSValueBinding toObject:project withKeyPath:@"processNib2Cib" options:nil];
        [self->checkBoxProcessObjj bind:NSValueBinding toObject:project withKeyPath:@"processObjjWarnings" options:nil];
        [self->checkBoxProcessCappLint bind:NSValueBinding toObject:project withKeyPath:@"processCappLint" options:nil];
    }
    else
    {
        [self->fieldXcodeCappIgnoreContent unbind:NSValueBinding];
        [self->fieldObjjIncludePath unbind:NSValueBinding];
        [self->checkBoxProcessObjj2Skeleton unbind:NSValueBinding];
        [self->checkBoxProcessNib2Cib unbind:NSValueBinding];
        [self->checkBoxProcessObjj unbind:NSValueBinding];
        [self->checkBoxProcessCappLint unbind:NSValueBinding];
    }

    [self->tableViewBinaryPaths reloadData];
}


#pragma mark - Custom Getters and Setters

- (void)setCappuccinoProjectController:(XCCCappuccinoProjectController *)cappuccinoProjectController
{
    if ([cappuccinoProjectController isEqualTo:_cappuccinoProjectController])
        return;

    [self _removeObservers];
    [self willChangeValueForKey:@"cappuccinoProjectController"];
    _cappuccinoProjectController = cappuccinoProjectController;
    [self didChangeValueForKey:@"cappuccinoProjectController"];
    [self _addObservers];
}

- (XCCCappuccinoProjectController*)cappuccinoProjectController
{
    return _cappuccinoProjectController;
}


#pragma mark - Observers

- (void)_addObservers
{
    if (self->isObserving)
        return;

    self->isObserving = YES;

    [self.cappuccinoProjectController addObserver:self forKeyPath:@"cappuccinoProject.nickname" options:NSKeyValueObservingOptionNew context:nil];
    [self.cappuccinoProjectController addObserver:self forKeyPath:@"cappuccinoProject.XcodeCappIgnoreContent" options:NSKeyValueObservingOptionNew context:nil];
    [self.cappuccinoProjectController addObserver:self forKeyPath:@"cappuccinoProject.processObjj2ObjcSkeleton" options:NSKeyValueObservingOptionNew context:nil];
    [self.cappuccinoProjectController addObserver:self forKeyPath:@"cappuccinoProject.processNib2Cib" options:NSKeyValueObservingOptionNew context:nil];
    [self.cappuccinoProjectController addObserver:self forKeyPath:@"cappuccinoProject.processObjjWarnings" options:NSKeyValueObservingOptionNew context:nil];
    [self.cappuccinoProjectController addObserver:self forKeyPath:@"cappuccinoProject.processCappLint" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)_removeObservers
{
    if (!self->isObserving)
        return;

    self->isObserving = NO;

    [self.cappuccinoProjectController removeObserver:self forKeyPath:@"cappuccinoProject.nickname"];
    [self.cappuccinoProjectController removeObserver:self forKeyPath:@"cappuccinoProject.XcodeCappIgnoreContent"];
    [self.cappuccinoProjectController removeObserver:self forKeyPath:@"cappuccinoProject.processObjj2ObjcSkeleton"];
    [self.cappuccinoProjectController removeObserver:self forKeyPath:@"cappuccinoProject.processNib2Cib"];
    [self.cappuccinoProjectController removeObserver:self forKeyPath:@"cappuccinoProject.processObjjWarnings"];
    [self.cappuccinoProjectController removeObserver:self forKeyPath:@"cappuccinoProject.processCappLint"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(XCCCappuccinoProjectController *)projectController change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"XcodeCappIgnoreContent"])
        [projectController reinitializeProjectFromSettings];
    else
        [projectController.cappuccinoProject saveSettings];
}


#pragma mark - Actions

- (IBAction)addBinaryPath:(id)sender
{
    [self.cappuccinoProjectController.cappuccinoProject.binaryPaths addObject:[XCCPath new]];
    [self->tableViewBinaryPaths reloadData];

    [self.cappuccinoProjectController reinitializeProjectFromSettings];
}

- (IBAction)removeSelectedBinaryPaths:(id)sender
{
    [self.cappuccinoProjectController.cappuccinoProject.binaryPaths removeObjectsAtIndexes:[self->tableViewBinaryPaths selectedRowIndexes]];
    [self->tableViewBinaryPaths reloadData];

    [self.cappuccinoProjectController reinitializeProjectFromSettings];
}


#pragma mark - tableView delegate and datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.cappuccinoProjectController.cappuccinoProject.binaryPaths.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return ((XCCPath *)(self.cappuccinoProjectController.cappuccinoProject.binaryPaths)[row]).name;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    ((XCCPath *)(self.cappuccinoProjectController.cappuccinoProject.binaryPaths)[row]).name = value;

    [self.cappuccinoProjectController reinitializeProjectFromSettings];
}

@end
