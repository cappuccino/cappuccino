@import <AppKit/AppKit.j>

[CPApplication sharedApplication];

@implementation CPTokenFieldTest : OJTestCase
{
    CPWindow                _theWindow;
    CPTokenField            _tokenField;
    TestDelegateTokenField  _delegate;

}

- (void)setUp
{
    _theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 1024.0, 768.0)
                                            styleMask:CPWindowNotSizable];

    _tokenField = [CPTokenField new];
    _delegate = [TestDelegateTokenField new];

    [_tokenField setDelegate:_delegate];

    [[_theWindow contentView] addSubview:_tokenField];
}

- (void)tearDown
{

}

#pragma mark -
#pragma mark Test creation

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


#pragma mark -
#pragma mark Test objectValue and stringValue

/*!
    This is totally different than cocoa
*/
- (void)testSetObjectValueWithString
{
    [_tokenField setObjectValue:@"Alexandre"];
    [self assert:[_tokenField stringValue] equals:""];
}

- (void)testObjectValueWithArrayOfStrings
{
    [_tokenField setObjectValue:[@"Alexandre", @"Antoine"]];
    [self assert:[_tokenField objectValue] equals:[@"Alexandre",@"Antoine"]];
}

- (void)testStringValueWithArrayOfStrings
{
    [_tokenField setObjectValue:[@"Alexandre", @"Antoine"]];
    [self assert:[_tokenField stringValue] equals:@"Alexandre,Antoine"];
}


#pragma mark -
#pragma mark Delegate methods

- (void)testDelegateDisplayStringForRepresentedObject
{
    [_tokenField setObjectValue:[@"Alexandre", @"Antoine"]];
    [self assert:[_delegate representedObjects] equals:[@"Alexandre", @"Antoine"]];
}

// - (void)testDelegateHasMenuForRepresentedObject
// {
//     [_tokenField setObjectValue:[@"Alexandre", @"Antoine"]];
//
//     [_tokenField performKeyEquivalent:[CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:0
//         timestamp:0 windowNumber:[_theWindow windowNumber] context:nil
//         characters:"c" charactersIgnoringModifiers:"c" isARepeat:NO keyCode:99]];
//
//     [self assert:[_delegate numberOfCallOfDelegateHasMenuForRepresentedObject] equals:1];
// }

@end

@implementation TestDelegateTokenField : CPObject <CPTokenFieldDelegate>
{
    int     _numberOfCallOfDelegateHasMenuForRepresentedObject  @accessors(property=numberOfCallOfDelegateHasMenuForRepresentedObject);
    CPArray _representedObjects                                 @accessors(property=representedObjects);
}

- (id)init
{
    if (self = [super init])
    {
        _representedObjects = [];
        _numberOfCallOfDelegateHasMenuForRepresentedObject = 0;
    }

    return self;
}

// - (BOOL)tokenField:(CPTokenField)tokenField hasMenuForRepresentedObject:(id)representedObject
// {
//     CPLog.error(@"hasMenuForRepresentedObject")
//
//     return YES;
// }
//
// - (CPMenu)tokenField:(CPTokenField)tokenField menuForRepresentedObject:(id)representedObject
// {
//     CPLog.error(@"menuForRepresentedObject")
//
//     var menu = [CPMenu new];
//     [menu addItem:[[CPMenuItem alloc] initWithTitle:[CPString stringWithFormat:@"Menu item %s", representedObject] action:nil keyEquivalent:nil]];
//
//     return menu;
// }


// - (CPArray)tokenField:(CPTokenField)tokenField completionsForSubstring:(CPString)substring indexOfToken:(CPInteger)tokenIndex indexOfSelectedItem:(CPInteger)selectedIndex
// {
//     CPLog.error(@"completionsForSubstring")
// }
//
// - (CPArray)tokenField:(CPTokenField)tokenField shouldAddObjects:(CPArray)tokens atIndex:(CPUInteger)index
// {
//     CPLog.error(@"shouldAddObjects")
// }


- (CPString)tokenField:(CPTokenField)tokenField displayStringForRepresentedObject:(id)representedObject
{
    [_representedObjects addObject:representedObject];
    return representedObject;
}

// - (id)tokenField:(CPTokenField)tokenField representedObjectForEditingString:(CPString)editingString
// {
//     CPLog.error(@"representedObjectForEditingString")
// }

@end
