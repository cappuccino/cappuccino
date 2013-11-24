/*
 * AppController.j
 * issue1593
 *
 * Created by You on July 9, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet CPTableView tableView;
    @outlet CPArrayController arrayController;

    CPArray content @accessors;
}

- (void)awakeFromCib
{
    var keys = [[tableView tableColumns] valueForKey:@"identifier"];
    [self setContent:[
                        [CPDictionary dictionaryWithObjects:[YES, NO, @"NO"] forKeys:keys],
                        [CPDictionary dictionaryWithObjects:[NO, YES, @"YES"] forKeys:keys]
                     ]];

    [self _selectSegment:0];
    [theWindow setFullPlatformWindow:YES];
}

- (IBAction)selectSegment:(id)sender
{
    [self _selectSegment:[sender selectedSegment]];
}

- (void)_selectSegment:(CPInteger)anIndex
{
    var EnumerateColumns;

    if (anIndex == 0)
    {
        EnumerateColumns = function(column, idx)
        {
            [column bind:CPValueBinding toObject:arrayController withKeyPath:(@"arrangedObjects." + [column identifier]) options:nil];
        };

        [tableView setDataSource:nil];
    }
    else
    {
        EnumerateColumns = function(column, idx)
        {
            [column unbind:CPValueBinding];
        };

        [tableView setDataSource:self];
    }

    [[tableView tableColumns] enumerateObjectsUsingBlock:EnumerateColumns];
}

- (IBAction)logContent:(id)sender
{
    CPLogConsole([content description]);
}

- (int)numberOfRowsInTableView:(id)aTableView
{
    return [content count];
}

- (id)tableView:(id)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRow
{
    return [[content objectAtIndex:aRow] objectForKey:[aTableColumn identifier]];
}

- (void)tableView:(CPTableView)aTableView setObjectValue:(id)aValue forTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRow
{
    [[content objectAtIndex:aRow] setObject:aValue forKey:[aTableColumn identifier]];
}

@end
