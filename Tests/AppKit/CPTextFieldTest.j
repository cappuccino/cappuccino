@import <AppKit/CPTextField.j>


@implementation CPTextFieldTest : OJTestCase
{
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

/*!
    Detect regressions with JS object theme attribute encoding in subclasses.

    This test is not actually CPTextField specific at all. This just happens
    to be the first place the keyed archiving bug was discovered, and there is
    an additional, more specific, test in CPKeyedArchiverTest.
*/
- (void)testArchiveThemeAttributes
{
    var view = [[CPTextFieldSubclass alloc] initWithFrame:CGRectMakeZero()],
        decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:view]];

    [self assert:[view valueForThemeAttribute:@"content-inset"].top equals:2 message:@"content-inset should initialise correctly"];
    [self assert:[view valueForThemeAttribute:@"content-inset"].top equals:[decoded valueForThemeAttribute:@"content-inset"].top message:@"content-inset should unarchive correctly"];
}

- (void)testFormatters
{
    var control = [[CPTextField alloc] initWithFrame:CGRectMakeZero()],
        numberFormatter = [[CPNumberFormatter alloc] init];

    [numberFormatter setNumberStyle:CPNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:3];
    [numberFormatter setGeneratesDecimalNumbers:NO];

    [control setFormatter:numberFormatter];
    [control setStringValue:@"12.3456"];
    [self assertTrue:[[control objectValue] isKindOfClass:CPNumber] message:@"object should be a number"];
    // Note that the control stores the value with a different precision than the maximum fraction
    // digits of the number formatter. It's a little surprising but this makes the implementation easier
    // and Cocoa does it too.
    [self assert:[CPNumber numberWithFloat:12.3456] equals:[control objectValue]];
    [self assert:"12.346" equals:[control stringValue]];

    [control setFloatValue:45.3456];
    [self assertTrue:"45.346" === [control stringValue]];

    [control setFormatter:nil];
    [control setStringValue:@"12"];
    [self assert:@"12" equals:[control objectValue]];
}

/*
    The shared input element takes the field's text colour when it moves into the field, which
    can happen outside layout, where the drawing appearance is the application's. The colour
    resolves in the field's appearance. The field holds text: an empty field holds the
    placeholder state, which takes the placeholder's colour.
*/
- (void)testTheInputElementTextColorResolvesInTheFieldAppearance
{
    var field = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 24.0)];

    [field setStringValue:@"Text"];
    [field setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameDarkAqua]];
    [field setTextColor:[[CPTextFieldTestDynamicColor alloc] _initDynamicColor]];

    [self assert:CPAppearanceNameAqua equals:[[CPAppearance currentDrawingAppearance] name]];
    [self assert:[[CPColor whiteColor] cssString] equals:[field _inputElementTextColorCSSString]];
}

// MARK: Context menu

/*
    Returns the titles of a menu's items, with "-" for a separator.
*/
- (CPArray)titlesOfMenu:(CPMenu)aMenu
{
    return [[aMenu itemArray] valueForKey:@"title"].map(function(aTitle, anIndex)
    {
        return [[aMenu itemAtIndex:anIndex] isSeparatorItem] ? @"-" : aTitle;
    });
}

- (void)testTheDefaultMenuHasCutCopyAndSelectAllButNoPaste
{
    [self assert:[@"Cut", @"Copy", @"-", @"Select All"] equals:[self titlesOfMenu:[CPTextField defaultMenu]]];
}

/*
    An editable field shows the default menu, aimed at itself. Under ojtest the browser's
    Clipboard API is missing, so Cut and Copy are disabled; Select All does not need it.
*/
- (void)testAnEditableFieldShowsTheDefaultMenu
{
    var field = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 24.0)];

    [field setEditable:YES];

    var menu = [field menuForEvent:nil];

    [self assert:[@"Cut", @"Copy", @"-", @"Select All"] equals:[self titlesOfMenu:menu]];
    [self assert:field same:[[menu itemAtIndex:3] target] message:@"the items are aimed at the field"];
    [self assertFalse:[[menu itemAtIndex:0] isEnabled] message:@"Cut needs the Clipboard API"];
    [self assertFalse:[[menu itemAtIndex:1] isEnabled] message:@"Copy needs the Clipboard API"];
    [self assertTrue:[[menu itemAtIndex:3] isEnabled] message:@"Select All is enabled"];
}

- (void)testASelectableFieldShowsTheDefaultMenu
{
    var field = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 24.0)];

    [field setEditable:NO];
    [field setSelectable:YES];

    [self assertNotNull:[field menuForEvent:nil]];
}

- (void)testALabelOrADisabledFieldShowsNoMenu
{
    var label = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 24.0)],
        disabledField = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 24.0)];

    [label setEditable:NO];
    [label setSelectable:NO];
    [disabledField setEditable:YES];
    [disabledField setEnabled:NO];

    [self assertNull:[label menuForEvent:nil] message:@"a label has no menu"];
    [self assertNull:[disabledField menuForEvent:nil] message:@"a disabled field has no menu"];
}

- (void)testAMenuSetByTheApplicationComesFirst
{
    var field = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 24.0)],
        menu = [[CPMenu alloc] initWithTitle:@"Application"];

    [field setEditable:YES];
    [field setMenu:menu];

    [self assert:menu same:[field menuForEvent:nil]];
}

/*
    A data view of a table view leaves the right click to the table view, which shows its own
    menu.
*/
- (void)testATableDataViewShowsNoMenuOfItsOwn
{
    var field = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 24.0)];

    [field setEditable:YES];
    [field setThemeState:CPThemeStateTableDataView];

    [self assertNull:[field menuForEvent:nil]];
}

@end

/*
    A colour that is white in a dark appearance and black in every other.
*/
@implementation CPTextFieldTestDynamicColor : _CPDynamicColor

- (CPColor)_valueInAppearance:(CPAppearance)anAppearance
{
    return [anAppearance name] === CPAppearanceNameDarkAqua ? [CPColor whiteColor] : [CPColor blackColor];
}

- (_CPDynamicColor)_dynamicCopy
{
    return [[CPTextFieldTestDynamicColor alloc] _initDynamicColor];
}

@end

@implementation CPTextFieldSubclass : CPTextField
{

}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setValue:CGInsetMake(2.0, 2.0, 2.0, 2.0) forThemeAttribute:"content-inset"];
    }
    return self;
}

@end
