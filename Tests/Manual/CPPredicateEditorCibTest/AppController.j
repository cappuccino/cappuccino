/*
 * AppController.j
 * CPPredicateEditorCibTest
 *
 * Created by cacaodev on November 25, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <AppKit/CPScrollView.j>
@import "Predicatetransformer.j"

@implementation AppController : CPObject
{
    CPWindow             window;
    CPPredicateEditor    predicateEditor;
    
    CPTableView     leftTable;
    CPTableView     rightTable;
    CPPopUpButton   rightExpressionsType;
    CPButton        addTemplate;
    CPBox           templateBox;

    CPMutableArray  operators;
    CPMutableArray  leftKeyPaths;
    CPMutableArray  rightConstants;
}

+ (void)initialize
{
    var transformer = [[PredicateTransformer alloc] init];
    [CPValueTransformer setValueTransformer:transformer forName:@"PredicateTransformer"];   
}

- (void)awakeFromCib
{
    operators = [CPMutableArray new];
    leftKeyPaths = [CPMutableArray new];
    rightConstants = [CPMutableArray new];

    [templateBox setCornerRadius:10];
    [self updateAddTemplateButton];

    [window setBackgroundColor:[CPColor colorWithHexString:@"f3f4f5"]];
    [window setFullBridge:YES];
}

- (IBAction)predicateEditorAction:(id)sender
{
    CPLogConsole(_cmd);
}

- (void)ruleEditorRowsDidChange:(CPNotification)notification
{
    CPLogConsole(_cmd);
}

// Templates maker
- (IBAction)updateOperators:(id)sender
{
    var op = [CPNumber numberWithInt:[sender tag]];
    if ([sender state] == CPOnState)
    {
        if (![operators containsObject:op])
            [operators addObject:op];

    }
    else if ([sender state] == CPOffState)
        [operators removeObject:op];

    [self updateAddTemplateButton];
}

- (IBAction)selectRightAttributeType:(id)sender
{
    [self updateAddTemplateButton];
}

- (IBAction)addLeftKeyPath:(id)sender
{
    [self addUniqueValue:@"keypath" toArray:leftKeyPaths];
    [leftTable reloadData];
    [self updateAddTemplateButton];
}

- (IBAction)addRightConstant:(id)sender
{
    if ([rightExpressionsType indexOfSelectedItem] != 2)
        return;

    [self addUniqueValue:@"constant" toArray:rightConstants];
    [rightTable reloadData];
    [self updateAddTemplateButton];
}

- (IBAction)addTemplate:(id)sender
{
    var template;

    var leftExpressions = [CPMutableArray array],
        count = [leftKeyPaths count];
    while (count--)
    {
        var exp = [CPExpression expressionForKeyPath:leftKeyPaths[count]];
        [leftExpressions insertObject:exp atIndex:0];
    }

    var type = [rightExpressionsType indexOfSelectedItem];
    if (type == 0)
        template = [[CPPredicateEditorRowTemplate alloc] initWithLeftExpressions:leftExpressions rightExpressionAttributeType:CPStringAttributeType modifier:0 operators:operators options:0];
    else if (type == 1)
        template = [[CPPredicateEditorRowTemplate alloc] initWithLeftExpressions:leftExpressions rightExpressionAttributeType:CPInteger16AttributeType modifier:0 operators:operators options:0];
    else if (type ==2)
    {
        var rightExpressions = [CPMutableArray array],
            count = [rightConstants count];
        while (count--)
        {
            var exp = [CPExpression expressionForConstantValue:rightConstants[count]];
            [rightExpressions insertObject:exp atIndex:0];
        }

        template = [[CPPredicateEditorRowTemplate alloc] initWithLeftExpressions:leftExpressions rightExpressions:rightExpressions modifier:0 operators:operators options:0];
    }

    var templates = [[predicateEditor rowTemplates] arrayByAddingObject:template];
    [predicateEditor setRowTemplates:templates];
    [self cleanAll];
}

- (void)cleanAll
{
    var subviews = [[templateBox contentView] subviews],
        count = [subviews count];
    while (count--)
    {
        var view = subviews[count];
        if ([view isKindOfClass:[CPCheckBox class]])
            [view setState:CPOffState];
    }

    [leftKeyPaths removeAllObjects];
    [operators removeAllObjects];
    [rightConstants removeAllObjects];

    [leftTable reloadData];
    [rightTable reloadData];
    [self updateAddTemplateButton];
}

- (void)updateAddTemplateButton
{
    var enabled = ([leftKeyPaths count] > 0 && [operators count] > 0 && ([rightExpressionsType indexOfSelectedItem] != 2 || [rightConstants count] > 0));
    [addTemplate setEnabled:enabled];
}

- (void)addUniqueValue:(CPString)value toArray:(CPMutableArray)array
{
    var i = 0,
        count = [array count];

    while (count--)
        if ([array[count] hasPrefix:value])
            i++;

    [array addObject:(i==0)?value:[CPString stringWithFormat:@"%@%d", value, i]];
}

- (CPArray)arrayForTable:(CPTableView)tableView
{
    return (tableView == leftTable) ? leftKeyPaths : rightConstants;
}

- (id)tableView:(CPTableView)tableView objectValueForTableColumn:(CPTableColumn)tableColumn row:(CPInteger)row
{
    return [[self arrayForTable:tableView] objectAtIndex:row];
}

- (void)tableView:(CPTableView)tableView setObjectValue:(id)object forTableColumn:(CPTableColumn)tableColumn row:(CPInteger)row
{
    [[self arrayForTable:tableView] replaceObjectAtIndex:row withObject:object];
}

- (int)numberOfRowsInTableView:(CPTableView)tableView
{
    return [[self arrayForTable:tableView] count];
}

@end
