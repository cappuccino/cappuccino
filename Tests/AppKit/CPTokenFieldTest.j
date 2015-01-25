@import <AppKit/AppKit.j>

@class TestDelegateTokenField

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
    [self assert:[_tokenField objectValue] equals:[@"Alexandre", @"Antoine"]];
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

@end

@implementation TestDelegateTokenField : CPObject <CPTokenFieldDelegate>
{
    CPArray _representedObjects @accessors(property=representedObjects);
}

- (id)init
{
    if (self = [super init])
    {
        _representedObjects = [];
    }

    return self;
}

- (CPString)tokenField:(CPTokenField)tokenField displayStringForRepresentedObject:(id)representedObject
{
    [_representedObjects addObject:representedObject];
    return representedObject;
}

@end
