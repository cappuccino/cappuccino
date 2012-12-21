@import <AppKit/CPTokenField.j>

[CPApplication sharedApplication];

@implementation CPTokenFieldTest : OJTestCase
{
}

- (void)testArchiving
{
    var tokenField = [CPTokenField new];
    [tokenField setCompletionDelay:5.0];
    [tokenField setTokenizingCharacterSet:[CPCharacterSet characterSetWithCharactersInString:@","]];

    var archived = [CPKeyedArchiver archivedDataWithRootObject:tokenField],
        unarchived = [CPKeyedUnarchiver unarchiveObjectWithData:archived];

    [self assert:[unarchived completionDelay] equals:5.0];
    [self assert:[unarchived tokenizingCharacterSet] equals:[CPCharacterSet characterSetWithCharactersInString:@","]];
}

- (void)testCreate
{
    var aWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 1024.0, 768.0) styleMask:CPWindowNotSizable],
        tokenField = [[CPTokenField alloc] initWithFrame:CGRectMake(10, 10, 100, 28)];

    // This shouldn't crash.
    [[aWindow contentView] addSubview:tokenField];
}

- (void)testCloseParentWindow
{
    var aWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 1024.0, 768.0) styleMask:CPTitledWindowMask],
        tokenField = [[CPTokenField alloc] initWithFrame:CGRectMake(10, 10, 100, 28)];

    [[aWindow contentView] addSubview:tokenField];
    [tokenField setEnabled:YES];
    [tokenField setEditable:YES];

    [aWindow makeKeyAndOrderFront:nil];

    // Start autocomplete.
    var tokenDelegate = [TokenFieldDelegate new];
    [tokenDelegate setCompletions:[@"Tokyo", @"Toronto", @"Gothenburg", @"London"]];
    [tokenField setDelegate:tokenDelegate];

    [tokenField setStringValue:@"To"];
    // Start autocomplete programmatically.
    [aWindow makeFirstResponder:tokenField];
    [[tokenField _autocompleteMenu] _showCompletions:nil];

    // Verify we're now autocompleting.
    [self assertTrue:[[tokenField _autocompleteMenu]._menuWindow isVisible] message:@"autocomplete visible"];

    [aWindow close];
    [self assertFalse:[[tokenField _autocompleteMenu]._menuWindow isVisible] message:@"autocomplete not visible when token field window closes"];
}

@end

@implementation TokenFieldDelegate : CPObject
{
    CPArray completions @accessors;
}

- (CPArray)tokenField:(CPTokenField)aTokenField completionsForSubstring:(CPString)substring indexOfToken:(int)tokenIndex indexOfSelectedItem:(int)selectedIndex
{
    var r = [];

    if (!substring)
        return completions;

    for (var i = 0; i < completions.length; i++)
        if (completions[i].toLowerCase().indexOf(completions.toLowerCase()) == 0)
            r.push(completions[i]);

    return r;
}

@end
