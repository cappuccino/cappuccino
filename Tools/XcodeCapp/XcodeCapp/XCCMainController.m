//
//  MainWindowController.m
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/20/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import "NSMutableArray+moveIndexes.h"
#import "XCCMainController.h"
#import "XCCCappuccinoProject.h"
#import "XCCCappuccinoProjectController.h"
#import "XCCCappuccinoProjectControllerDataView.h"
#import "XCCUserDefaults.h"
#import "XCCOperationsViewController.h"
#import "XCCErrorsViewController.h"
#import "XCCSettingsViewController.h"
#import "XCCWelcomeView.h"


@implementation XCCMainController

#pragma mark - Initialization

- (void)windowDidLoad
{
    [self showWindow:self];

    self->welcomeViewMask.mainXcodeCappController = self;
    [self->welcomeViewMask showLoading:YES];
    [self _showWelcomeView:YES];
    [self _showMaskingView:YES];

    NSTabViewItem *itemConfiguration = [[NSTabViewItem alloc] initWithIdentifier:@"configuration"];
    [itemConfiguration setView:self.settingsViewController.view];
    [self->tabViewProject addTabViewItem:itemConfiguration];
    
    NSTabViewItem *itemErrors = [[NSTabViewItem alloc] initWithIdentifier:@"errors"];
    [itemErrors setView:self.errorsViewController.view];
    [self->tabViewProject addTabViewItem:itemErrors];
    
    NSTabViewItem *itemOperations = [[NSTabViewItem alloc] initWithIdentifier:@"operations"];
    [itemOperations setView:self.operationsViewController.view];
    [self->tabViewProject addTabViewItem:itemOperations];
    

    [self _setTextColor:[NSColor controlTextColor] forButton:self->buttonSelectConfigurationTab];
    [self _setTextColor:[NSColor controlTextColor] forButton:self->buttonSelectErrorsTab];
    [self _setTextColor:[NSColor controlTextColor] forButton:self->buttonSelectOperationsTab];


    [self updateSelectedTab:self->buttonSelectConfigurationTab];
    
    [self->projectTableView registerForDraggedTypes:@[@"projects", NSFilenamesPboardType]];
    [self->projectTableView setAllowsEmptySelection:YES];

    [self->welcomeViewMask showLoading:NO];
    
    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;

    [self _restoreManagedProjects];
    [self _restoreLastSelectedProject];
}

- (void)_setTextColor:(NSColor *)color forButton:(NSButton *)button
{
    NSMutableParagraphStyle *paragraphStyle= [NSMutableParagraphStyle new];
    [paragraphStyle setAlignment:NSCenterTextAlignment];

    NSDictionary *attrs = @{NSFontAttributeName: [NSFont systemFontOfSize:11],
                                 NSForegroundColorAttributeName: color,
                                 NSParagraphStyleAttributeName: paragraphStyle};

    button.attributedTitle = [[NSMutableAttributedString alloc] initWithString:button.title attributes:attrs];

}

#pragma mark - Private Utilities

- (void)_showMaskingView:(BOOL)shouldShow
{
    if (shouldShow)
    {
        if (self->maskingView.superview)
            return;
        
        self->projectViewContainer.hidden = YES;
        
        self->maskingView.frame = [[self->splitView subviews][1] bounds];
        [[self->splitView subviews][1] addSubview:self->maskingView positioned:NSWindowAbove relativeTo:nil];
    }
    else
    {
        if (!self->maskingView.superview)
            return;
        
        self->projectViewContainer.hidden = NO;
        
        [self->maskingView removeFromSuperview];
    }
}

- (void)_showWelcomeView:(BOOL)shouldShow
{
    if (shouldShow)
    {
        if (self->welcomeViewMask.superview)
            return;

        self->splitView.hidden = YES;
        
        self->welcomeViewMask.frame = [self->splitView.superview bounds];
        [self->splitView.superview addSubview:self->welcomeViewMask positioned:NSWindowAbove relativeTo:nil];
    }
    else
    {
        if (!self->welcomeViewMask.superview)
            return;

        self->splitView.hidden = NO;
        
        [self->welcomeViewMask removeFromSuperview];
    }
}

- (void)_restoreLastSelectedProject
{
    DDLogVerbose(@"Start : selecting last selected project");
    
    NSString        *lastSelectedProjectPath = [[NSUserDefaults standardUserDefaults] valueForKey:XCCUserDefaultsSelectedProjectPath];
    
    [self _selectCappuccinoProjectControllerWithPath:lastSelectedProjectPath];
    
    DDLogVerbose(@"Stop : selecting last selected project");
}

- (void)_selectCappuccinoProjectControllerWithPath:(NSString*)aCappuccinoProjectPath
{
    NSInteger       indexToSelect            = 0;
    
    if ([aCappuccinoProjectPath length])
    {
        for (XCCCappuccinoProjectController *controller in self.cappuccinoProjectControllers)
        {
            if ([controller.cappuccinoProject.projectPath isEqualToString:aCappuccinoProjectPath])
            {
                indexToSelect = [self.cappuccinoProjectControllers indexOfObject:controller];
                break;
            }
        }
        
        [self->projectTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:indexToSelect] byExtendingSelection:NO];
    }
}

- (void)_restoreManagedProjects
{
    DDLogVerbose(@"restore managed projects");
    self.cappuccinoProjectControllers = [@[] mutableCopy];
    
    NSArray         *projectHistory  = [[NSUserDefaults standardUserDefaults] arrayForKey:XCCUserDefaultsManagedProjects];
    NSFileManager   *fm              = [NSFileManager defaultManager];
    NSMutableArray  *missingProjects = [@[] mutableCopy];
    
    for (NSString *path in projectHistory)
    {
        DDLogVerbose(@"Checking previously managed project at path: %@", path);
        if (![fm fileExistsAtPath:path isDirectory:nil])
        {
            [missingProjects addObject:path];
            DDLogVerbose(@"Not found: project at path: %@", path);
            continue;
        }
        
        XCCCappuccinoProjectController *cappuccinoProjectController = [[XCCCappuccinoProjectController alloc] initWithPath:path controller:self];
        [self.cappuccinoProjectControllers addObject:cappuccinoProjectController];
    }
    
    [self _reloadProjectsList];
    
    if (missingProjects.count)
    {
        NSRunAlertPanel(@"Missing Projects",
                        @"Some managed projects could not be found and have been removed:\n\n"
                        @"%@\n\n",
                        @"OK",
                        nil,
                        nil,
                        [missingProjects componentsJoinedByString:@", "]);
    }

    [self _saveManagedProjectsToUserDefaults];

    for (XCCCappuccinoProjectController *controller in self.cappuccinoProjectControllers)
    {
        if (controller.cappuccinoProject.previousSavedStatus)
            [controller switchProjectListeningStatus:self];
    }

    DDLogVerbose(@"managed projects restored");
}

- (void)_saveSelectedProject
{
    NSString *path = self.currentCappuccinoProjectController.cappuccinoProject.projectPath;

    if (!path)
        path = @"";

    [[NSUserDefaults standardUserDefaults] setObject:path forKey:XCCUserDefaultsSelectedProjectPath];
}

- (void)_saveManagedProjectsToUserDefaults
{
    NSMutableArray *historyProjectPaths = [@[] mutableCopy];

    for (XCCCappuccinoProjectController *controller in self.cappuccinoProjectControllers)
        [historyProjectPaths addObject:controller.cappuccinoProject.projectPath];

    [[NSUserDefaults standardUserDefaults] setObject:historyProjectPaths forKey:XCCUserDefaultsManagedProjects];
}

- (void)_reloadProjectsList
{
    [self->projectTableView reloadData];

    if (self.cappuccinoProjectControllers.count == 0)
        [self _showWelcomeView:YES];
    else
        [self _showWelcomeView:NO];
    
}


#pragma mark - Public Utilities

- (void)manageCappuccinoProjectControllerForPath:(NSString *)path
{
    if ([[self.cappuccinoProjectControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"cappuccinoProject.projectPath == %@", path]] count])
    {
        NSRunAlertPanel(@"This project is already managed.", @"Please remove the other project or use the reset button.", @"OK", nil, nil, nil);
        return;
    }

    XCCCappuccinoProjectController *controller = [[XCCCappuccinoProjectController alloc] initWithPath:path controller:self];

    [self.cappuccinoProjectControllers addObject:controller];

    NSInteger index = [self.cappuccinoProjectControllers indexOfObject:controller];

    [self _reloadProjectsList];
    [self->projectTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [self->projectTableView scrollRowToVisible:index];

    [self _saveManagedProjectsToUserDefaults];

    [controller switchProjectListeningStatus:self];
}

- (void)unmanageCappuccinoProjectController:(XCCCappuccinoProjectController*)aController
{
    NSInteger selectedCappuccinoProject = [self.cappuccinoProjectControllers indexOfObject:aController];
    
    if (selectedCappuccinoProject == -1)
        return;
    
    [self->projectTableView deselectRow:selectedCappuccinoProject];
    [aController cleanUpBeforeDeletion];
    [self.cappuccinoProjectControllers removeObjectAtIndex:selectedCappuccinoProject];
    
    [self _reloadProjectsList];
    
    [self _saveManagedProjectsToUserDefaults];
}


- (void)notifyCappuccinoControllersApplicationIsClosing
{
    [self.cappuccinoProjectControllers makeObjectsPerformSelector:@selector(applicationIsClosing)];
}

- (void)reloadTotalNumberOfErrors
{
    int totalErrors = 0;

    for (XCCCappuccinoProjectController *controller in self.cappuccinoProjectControllers)
        totalErrors += controller.errors.count;

    [self willChangeValueForKey:@"totalNumberOfErrors"];
    self.totalNumberOfErrors = totalErrors;
    [self didChangeValueForKey:@"totalNumberOfErrors"];

    if (self.totalNumberOfErrors)
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:@(self.totalNumberOfErrors).description];
    else
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:nil];
}


#pragma mark - Actions

- (IBAction)cleanAllErrors:(id)aSender
{
    [self.cappuccinoProjectControllers makeObjectsPerformSelector:@selector(cleanProjectErrors:) withObject:self];
}

- (IBAction)addProject:(id)aSender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.title = @"Add a new Cappuccino Project to XcodeCapp";
    openPanel.canCreateDirectories = YES;
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = NO;

    if ([openPanel runModal] != NSFileHandlingPanelOKButton)
        return;
    
    NSString *projectPath = [[openPanel.URLs[0] path] stringByStandardizingPath];

    [self manageCappuccinoProjectControllerForPath:projectPath];
}

- (IBAction)removeProject:(id)aSender
{
    NSInteger selectedCappuccinoProject = [self->projectTableView selectedRow];
    
    if (selectedCappuccinoProject == -1)
        return;
    
    [self unmanageCappuccinoProjectController:(self.cappuccinoProjectControllers)[selectedCappuccinoProject]];
}

- (IBAction)updateSelectedTab:(NSButton *)sender
{
    self->buttonSelectConfigurationTab.state = NSOffState;
    self->buttonSelectErrorsTab.state = NSOffState;
    self->buttonSelectOperationsTab.state = NSOffState;

    [self _setTextColor:[NSColor controlTextColor] forButton:self->buttonSelectConfigurationTab];
    [self _setTextColor:[NSColor controlTextColor] forButton:self->buttonSelectErrorsTab];
    [self _setTextColor:[NSColor controlTextColor] forButton:self->buttonSelectOperationsTab];

    sender.state = NSOnState;
    [self _setTextColor:[NSColor colorWithCalibratedRed:107.0/255.0 green:148.0/255.0 blue:236.0/255.0 alpha:1.0] forButton:sender];

    if (sender == self->buttonSelectConfigurationTab)
        [self->tabViewProject selectTabViewItemAtIndex:0];
    if (sender == self->buttonSelectErrorsTab)
        [self->tabViewProject selectTabViewItemAtIndex:1];
    if (sender == self->buttonSelectOperationsTab)
        [self->tabViewProject selectTabViewItemAtIndex:2];
}


#pragma mark - NSUserNotificationCenter delegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    [center removeDeliveredNotification:notification];
    
    [self _selectCappuccinoProjectControllerWithPath:userInfo[@"cappuccinoProjectPath"]];
    [self updateSelectedTab:self->buttonSelectErrorsTab];
    [self.errorsViewController selectItem:userInfo[@"sourcePath"]];
}


#pragma mark - SplitView delegate

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    return 300.0;
}

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    return 350.0;
}

- (void)splitView:(NSSplitView *)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
    [aSplitView adjustSubviews];

    [aSplitView setPosition:((NSView *)splitView.subviews.firstObject).frame.size.width ofDividerAtIndex:0];
}

#pragma mark - TableView DataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [self.cappuccinoProjectControllers count];
}

#pragma mark - TableView Delegates

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    XCCCappuccinoProjectControllerDataView  *dataView                    = [tableView makeViewWithIdentifier:@"MainCell" owner:nil];
    XCCCappuccinoProjectController          *cappuccinoProjectController = (self.cappuccinoProjectControllers)[row];
    
    dataView.controller = cappuccinoProjectController;
    
    return dataView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger selectedIndex = [self->projectTableView selectedRow];

    self.currentCappuccinoProjectController                     = (selectedIndex == -1) ? nil : (self.cappuccinoProjectControllers)[selectedIndex];

    self.operationsViewController.cappuccinoProjectController   = self.currentCappuccinoProjectController;
    self.errorsViewController.cappuccinoProjectController       = self.currentCappuccinoProjectController;
    self.settingsViewController.cappuccinoProjectController     = self.currentCappuccinoProjectController;

    [self.operationsViewController reload];
    [self.errorsViewController reload];
    [self.settingsViewController reload];

    [self _showMaskingView:(selectedIndex == -1)];

    [self _saveSelectedProject];

}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowsIndexes toPasteboard:(NSPasteboard*)pasteboard
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowsIndexes];
    [pasteboard declareTypes:@[@"projects"] owner:self];
    [pasteboard setData:data forType:@"projects"];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard *pboard = [info draggingPasteboard];
    
    if ([pboard.types containsObject:(NSString *)NSFilenamesPboardType])
    {
        NSArray *draggedFiles = [pboard propertyListForType:(NSString *)NSFilenamesPboardType];
        
        for (NSString *file in draggedFiles)
        {
            BOOL isDir;
            [[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDir];

            if (!isDir)
                return NSDragOperationNone;
        }
        
        return NSDragOperationCopy;
    }
    else if ([pboard.types containsObject:@"projects"])
    {
        if (operation == NSTableViewDropOn)
            return NSDragOperationNone;
        
        return NSDragOperationMove;
    }
    else
    {
        return NSDragOperationNone;
    }
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard *pboard = [info draggingPasteboard];
    
    if ([pboard.types containsObject:(NSString *)NSFilenamesPboardType])
    {
        NSArray *draggedFolders = [pboard propertyListForType:(NSString *)NSFilenamesPboardType];
        
        for (NSString *folder in draggedFolders)
            [self manageCappuccinoProjectControllerForPath:folder];

        return YES;
    }
    else if ([pboard.types containsObject:@"projects"])
    {
        NSData      *rowData    = [pboard dataForType:@"projects"];
        NSIndexSet  *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];

        [self.cappuccinoProjectControllers moveIndexes:rowIndexes toIndex:row];
        [self _reloadProjectsList];
        [self _saveManagedProjectsToUserDefaults];
        
        return YES;
    }
    else
    {
        return NO;
    }
}

@end