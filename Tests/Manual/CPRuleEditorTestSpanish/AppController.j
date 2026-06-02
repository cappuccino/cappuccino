@import <Foundation/CPObject.j>
@import <AppKit/CPWindow.j>
@import <AppKit/CPRuleEditor.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPButton.j>
@import "RuleDelegate.j"

@implementation AppController : CPObject
{
    CPWindow     theWindow;
    CPRuleEditor ruleEditor;
    CPTextField  predicateField;
    RuleDelegate ruleDelegate;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(50, 50, 800, 500)
                                            styleMask:CPTitledWindowMask | CPClosableWindowMask | CPResizableWindowMask];
    [theWindow setTitle:@"Spanish CPRuleEditor Whole-Sentence Localization Test"];
    [theWindow setFullPlatformWindow:YES];
    
    var contentView = [theWindow contentView];
    [contentView setBackgroundColor:[CPColor colorWithHexString:@"f3f4f5"]];

    var label = [CPTextField labelWithTitle:@"CPRuleEditor Sentence Localization & Positional Reordering:"];
    [label setFrame:CGRectMake(20, 20, 760, 24)];
    [label setFont:[CPFont boldSystemFontOfSize:14]];
    [contentView addSubview:label];

    ruleDelegate = [[RuleDelegate alloc] init];

    // Create Rule Editor
    ruleEditor = [[CPRuleEditor alloc] initWithFrame:CGRectMake(20, 55, 760, 250)];
    [ruleEditor setAutoresizingMask:CPViewWidthSizable];
    [ruleEditor setDelegate:ruleDelegate];
    [ruleEditor setEditable:YES];
    [ruleEditor setRowHeight:28];
    [ruleEditor setTarget:self];
    [ruleEditor setAction:@selector(ruleEditorAction:)];

    // Populate Spanish translations programmatically 
    var path = [[CPBundle mainBundle] pathForResource:@"Spanish.strings"];
    if (path)
    {
        [[ruleEditor standardLocalizer] loadContentOfURL:[CPURL URLWithString:path]];
    }

    [contentView addSubview:ruleEditor];

    // Populate default row
    [ruleEditor addRow:self];

    // Display Output Label
    var predLabel = [CPTextField labelWithTitle:@"CPRuleEditor Sentence Localization & Positional Reordering:"];
    [predLabel setFrame:CGRectMake(20, 320, 760, 20)];
    [predLabel setFont:[CPFont boldSystemFontOfSize:12]];
    [contentView addSubview:predLabel];

    // Predicate string value display
    predicateField = [[CPTextField alloc] initWithFrame:CGRectMake(20, 345, 760, 36)];
    [predicateField setAutoresizingMask:CPViewWidthSizable];
    [predicateField setBezeled:YES];
    [predicateField setEditable:NO];
    [predicateField setStringValue:@""];
    [predicateField setFont:[CPFont systemFontOfSize:13]];
    [contentView addSubview:predicateField];

    var addBtn = [CPButton buttonWithTitle:@"Añadir regla"];
    [addBtn setFrame:CGRectMake(20, 400, 120, 24)];
    [addBtn setTarget:ruleEditor];
    [addBtn setAction:@selector(addRow:)];
    [contentView addSubview:addBtn];

    [theWindow orderFront:self];
    [self ruleEditorAction:nil];
}

- (void)ruleEditorAction:(id)sender
{
    var predicate = [ruleEditor predicate];
    if (predicate)
    {
        [predicateField setStringValue:[predicate predicateFormat]];
    }
    else
    {
        [predicateField setStringValue:@"(No predicate evaluated)"];
    }
}

@end
