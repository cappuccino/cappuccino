//
//  XCCErrorsViewController.m
//  XcodeCapp
//
//  Created by Antoine Mercadal on 6/4/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import "XCCErrorsViewController.h"
#import "XCCCappuccinoProjectController.h"
#import "XCCCappuccinoProject.h"
#import "XCCOperationErrorDataView.h"
#import "XCCOperationErrorHeaderDataView.h"
#import "XCCMainController.h"
#import "XCCSourceProcessingOperation.h"

@implementation XCCErrorsViewController

#pragma mark - Initialization

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self->errorOutlineView setTarget:self];
    [self->errorOutlineView setDoubleAction:@selector(openErroredFileInEditor:)];
}


#pragma mark - Utilities

- (void)_showMaskingView:(BOOL)shouldShow
{
    if (shouldShow)
    {
        if (self->maskingView.superview)
            return;

        [self->errorOutlineView setHidden:YES];

        self->maskingView.frame = [self.view bounds];
        [self.view addSubview:self->maskingView];
    }
    else
    {
        if (!self->maskingView.superview)
            return;

        [self->errorOutlineView setHidden:NO];

        [self->maskingView removeFromSuperview];
    }
}

- (void)reload
{
    [self->errorOutlineView reloadData];
    [self->errorOutlineView expandItem:nil expandChildren:YES];

    [self _showMaskingView:!self.cappuccinoProjectController.errors.count];
}

- (void)selectItem:(id)anItem
{
    NSInteger indexOfItem = [self _indexOfItem:anItem];
    
    if (indexOfItem == NSNotFound)
        return;
    
    [self->errorOutlineView scrollRowToVisible:indexOfItem];
}

- (NSInteger)_indexOfItem:(id)anItem
{
    NSInteger index = 0;
    
    NSArray *keys = [self.cappuccinoProjectController.errors allKeys];
    
    for (int i = 0; i < [keys count]; i++)
    {
        NSString *key = [[self.cappuccinoProjectController.errors allKeys] objectAtIndex:i];
        
        if ([key isEqual:anItem])
            return index;
        
        index++;
        
        NSArray *operationErrors = [self.cappuccinoProjectController.errors objectForKey:key];
        
        for (int j = 0; j < [operationErrors count]; j++)
        {
            XCCOperationError *operationError = [operationErrors objectAtIndex:j];
            
            if ([operationError isEqual:anItem])
                return index;
            
            index++;
        }
    }
    
    return NSNotFound;
}

#pragma mark - Actions

- (IBAction)cleanProjectErrors:(id)aSender
{
    [self.cappuccinoProjectController removeAllOperationErrors];
    [self reload];
    [self.cappuccinoProjectController.mainXcodeCappController reloadTotalNumberOfErrors];
}

- (IBAction)openErroredFileInEditor:(NSView *)sender
{
    NSInteger   index       = (sender != self->errorOutlineView) ? [self->errorOutlineView rowForView:sender] : [self->errorOutlineView selectedRow];
    id          dataView    = [self->errorOutlineView viewAtColumn:0 row:index makeIfNecessary:NO];

    if (![dataView isKindOfClass:[XCCOperationErrorDataView class]])
        return;

    NSString *path = ((XCCOperationErrorDataView*)dataView).errorOperation.fileName;
    NSInteger line = ((XCCOperationErrorDataView*)dataView).errorOperation.lineNumber.intValue;

    [self.cappuccinoProjectController launchEditorForPath:path line:line];
}


#pragma mark - outlineView data source and delegate

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item)
        return self.cappuccinoProjectController.errors.allKeys.count;

    return ((NSArray *)self.cappuccinoProjectController.errors[item]).count;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return ![item isKindOfClass:[XCCOperationError class]];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item)
        return self.cappuccinoProjectController.errors.allKeys[index];

    return self.cappuccinoProjectController.errors[item][index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return item;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([item isKindOfClass:[XCCOperationError class]])
    {
        XCCOperationErrorDataView *dataView = [outlineView makeViewWithIdentifier:@"OperationErrorCell" owner:nil];

        dataView.errorOperation = item;
        [dataView.buttonOpenInEditor setTarget:self];
        [dataView.buttonOpenInEditor setAction:@selector(openErroredFileInEditor:)];

        return dataView;
    }
    else
    {
        XCCOperationErrorHeaderDataView *dataView = [outlineView makeViewWithIdentifier:@"OperationErrorHeaderCell" owner:nil];

        dataView.fileName = [[item stringByReplacingOccurrencesOfString:self.cappuccinoProjectController.cappuccinoProject.projectPath withString:@""] substringFromIndex:1];

        return dataView;
    }
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(XCCOperationError *)item
{
    if ([item isKindOfClass:[XCCOperationError class]])
    {
        CGRect frame = [item.message boundingRectWithSize:CGSizeMake([outlineView frame].size.width, CGFLOAT_MAX)
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:@{ NSFontAttributeName:[NSFont fontWithName:@"Menlo" size:11] }];

        return frame.size.height + 38.0;
    }

    else
        return 20.0;
}

@end
