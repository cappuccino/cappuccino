@import <AppKit/AppKit.j>

@class TestDelegateTokenField

@implementation CPTokenFieldTest : OJTestCase
{
    CPWindow                _theWindow;
    CPTokenField            _tokenField;
    TestDelegateTokenField  _delegate;

}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

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

// MARK: -
// MARK: Test creation

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


// MARK: -
// MARK: Test objectValue and stringValue

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


// MARK: -
// MARK: Delegate methods

- (void)testDelegateDisplayStringForRepresentedObject
{
    [_tokenField setObjectValue:[@"Alexandre", @"Antoine"]];
    [self assert:[_delegate representedObjects] equals:[@"Alexandre", @"Antoine"]];
}

// MARK: -
// MARK: Appearance

/*
    The shared input element takes the token field's text colour when the field becomes first
    responder, outside layout, where the drawing appearance is the application's. The colour
    resolves in the field's appearance. The field holds a token: an empty field holds the
    placeholder state, which takes the placeholder's colour.
*/
- (void)testTheInputElementTextColorResolvesInTheFieldAppearance
{
    [_tokenField setObjectValue:[@"Alexandre"]];
    [_tokenField setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameDarkAqua]];
    [_tokenField setTextColor:[[CPTokenFieldTestDynamicColor alloc] _initDynamicColor]];

    [self assert:CPAppearanceNameAqua equals:[[CPAppearance currentDrawingAppearance] name]];
    [self assert:[[CPColor whiteColor] cssString] equals:[_tokenField _inputElementTextColorCSSString]];
}

@end

/*
    A colour that is white in a dark appearance and black in every other.
*/
@implementation CPTokenFieldTestDynamicColor : _CPDynamicColor

- (CPColor)_valueInAppearance:(CPAppearance)anAppearance
{
    return [anAppearance name] === CPAppearanceNameDarkAqua ? [CPColor whiteColor] : [CPColor blackColor];
}

- (_CPDynamicColor)_dynamicCopy
{
    return [[CPTokenFieldTestDynamicColor alloc] _initDynamicColor];
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
