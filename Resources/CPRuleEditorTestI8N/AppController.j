@import <Foundation/CPObject.j>
@import <AppKit/CPWindow.j>
@import <AppKit/CPRuleEditor.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPButton.j>
@import <AppKit/CPPopUpButton.j>
@import "RuleDelegate.j"

@implementation AppController : CPObject
{
    CPWindow        theWindow;
    CPRuleEditor    ruleEditor;
    CPTextField     predicateField;
    RuleDelegate    ruleDelegate;
    CPPopUpButton   langPopUp;

    CPDictionary    englishDict;
    CPDictionary    spanishDict;
    CPDictionary    germanDict;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(50, 50, 800, 520)
                                            styleMask:CPTitledWindowMask | CPClosableWindowMask | CPResizableWindowMask];
    [theWindow setTitle:@"CPRuleEditor Multi-Language Localization Demo"];
    [theWindow setFullPlatformWindow:YES];
    
    var contentView = [theWindow contentView];
    [contentView setBackgroundColor:[CPColor colorWithHexString:@"f3f4f5"]];

    var label = [CPTextField labelWithTitle:@"CPRuleEditor Sentence Localization & Positional Reordering:"];
    [label setFrame:CGRectMake(20, 20, 500, 24)];
    [label setFont:[CPFont boldSystemFontOfSize:14]];
    [contentView addSubview:label];

    // Language Selector Label
    var langLabel = [CPTextField labelWithTitle:@"Language:"];
    [langLabel setFrame:CGRectMake(530, 20, 80, 24)];
    [langLabel setFont:[CPFont boldSystemFontOfSize:12]];
    [langLabel setAlignment:CPRightTextAlignment];
    [contentView addSubview:langLabel];

    // Language Selector PopUpButton
    langPopUp = [[CPPopUpButton alloc] initWithFrame:CGRectMake(620, 16, 160, 24)];
    [langPopUp addItemWithTitle:@"Spanish"];
    [langPopUp addItemWithTitle:@"German"];
    [langPopUp addItemWithTitle:@"English"];
    [langPopUp setTarget:self];
    [langPopUp setAction:@selector(changeLanguage:)];
    [contentView addSubview:langPopUp];

    ruleDelegate = [[RuleDelegate alloc] init];

    // Create Rule Editor
    ruleEditor = [[CPRuleEditor alloc] initWithFrame:CGRectMake(20, 55, 760, 250)];
    [ruleEditor setAutoresizingMask:CPViewWidthSizable];
    [ruleEditor setDelegate:ruleDelegate];
    [ruleEditor setEditable:YES];
    [ruleEditor setNestingMode:CPRuleEditorNestingModeList];
    [ruleEditor setRowHeight:28];
    [ruleEditor setTarget:self];
    [ruleEditor setAction:@selector(ruleEditorAction:)];

    // Programmatic dictionaries setup
    englishDict = [CPDictionary dictionary]; // Identity fallback

    spanishDict = [CPDictionary dictionaryWithDictionary:@{
        @"%[firstName]@ %[is equal to]@ %@" : @"%1$[Nombre]@ y %3$@ %2$[son iguales]@",
        @"%[firstName]@ %[contains]@ %@"    : @"%1$[Nombre]@ %2$[contiene]@ %3$@",
        @"%[lastName]@ %[is equal to]@ %@"  : @"%1$[Apellido]@ y %3$@ %2$[son iguales]@",
        @"%[lastName]@ %[contains]@ %@"     : @"%1$[Apellido]@ %2$[contiene]@ %3$@",
        @"%[age]@ %[is equal to]@ %@"       : @"%1$[Edad]@ y %3$@ %2$[son iguales]@",
        @"%[age]@ is equal to %@"           : @"%1$[Edad]@ y %3$@ %2$[son iguales]@",
        @"Add row"                          : @"Añadir regla",
        @"Delete row"                       : @"Eliminar regla",
        @"Add compound row"                 : @"Añadir grupo de reglas"
    }];

    germanDict = [CPDictionary dictionaryWithDictionary:@{
        @"%[firstName]@ %[is equal to]@ %@" : @"%1$[Vorname]@ und %3$@ %2$[sind gleich]@",
        @"%[firstName]@ %[contains]@ %@"    : @"%1$[Vorname]@ %2$[enthält]@ %3$@",
        @"%[lastName]@ %[is equal to]@ %@"  : @"%1$[Nachname]@ und %3$@ %2$[sind gleich]@",
        @"%[lastName]@ %[contains]@ %@"     : @"%1$[Nachname]@ %2$[enthält]@ %3$@",
        @"%[age]@ %[is equal to]@ %@"       : @"%1$[Alter]@ und %3$@ %2$[sind gleich]@",
        @"%[age]@ is equal to %@"           : @"%1$[Alter]@ und %3$@ %2$[sind gleich]@",
        @"Add row"                          : @"Regel hinzufügen",
        @"Delete row"                       : @"Regel löschen",
        @"Add compound row"                 : @"Regelgruppe hinzufügen"
    }];

    // Initialize with Spanish by default
    [[ruleEditor standardLocalizer] setDictionary:spanishDict];

    [contentView addSubview:ruleEditor];

    // Populate initial rows
    [ruleEditor addRow:self];
    [ruleEditor addRow:self];
    [ruleEditor addRow:self];

    // Display Output Label
    var predLabel = [CPTextField labelWithTitle:@"Evaluated Predicate:"];
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

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ruleEditorRowsDidChange:)
                                                 name:CPRuleEditorRowsDidChangeNotification
                                               object:ruleEditor];

    [theWindow orderFront:self];
    [self ruleEditorAction:nil];
}

- (void)changeLanguage:(id)sender
{
    var selectedTitle = [sender titleOfSelectedItem],
        targetDict = englishDict;

    if ([selectedTitle isEqualToString:@"Spanish"])
    {
        targetDict = spanishDict;
    }
    else if ([selectedTitle isEqualToString:@"German"])
    {
        targetDict = germanDict;
    }

    [[ruleEditor standardLocalizer] setDictionary:targetDict];

    // Post notification to trigger localized redraw across editor slices
    [[CPNotificationCenter defaultCenter] postNotificationName:@"_CPRuleEditorLocalizerDidLoadNotification" object:[ruleEditor standardLocalizer]];
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

- (void)ruleEditorRowsDidChange:(CPNotification)note
{
    var predicate = [ruleEditor predicate];

    if (predicate)
    {
        [predicateField setStringValue:[predicate predicateFormat]];
    }
    else
    {
        [predicateField setStringValue:@"(Incomplete Predicate)"];
    }
}

@end
