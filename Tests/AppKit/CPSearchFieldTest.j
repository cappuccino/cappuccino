@import <AppKit/AppKit.j>

/*
    Under ojtest the theme of a search field provides no button images, and the button rect
    methods fall back to a zero size, so the buttons have empty frames. This subclass gives the
    buttons the rects that Aristo3 computes for a field 200 points wide with its 16-point images.
*/
@implementation _CursorAreaTestSearchField : CPSearchField

- (CGRect)searchButtonRectForBounds:(CGRect)aRect
{
    return CGRectMake(2.0, 2.0, 16.0, 16.0);
}

- (CGRect)cancelButtonRectForBounds:(CGRect)aRect
{
    return CGRectMake(CGRectGetWidth(aRect) - 24.0, 2.0, 16.0, 16.0);
}

@end

@implementation CPSearchFieldTest : OJTestCase
{
    CPSearchField _searchField;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    _searchField = [[CPSearchField alloc] initWithFrame:CGRectMakeZero()];
}

- (void)testMakeCPSearchFieldInstance
{
    [self assertNotNull:_searchField];
}

- (void)testRecentSearchesStartsEmpty
{
    [self assertTrue:[[_searchField recentSearches] count] == 0 message:@"After instance creation we shouldn't have any recent searches."];
}

- (void)testSetRecentSearches
{
    var searches = ["foo", "bar", "baz"];
    [_searchField setRecentSearches:searches]
    [self assertTrue:[[_searchField recentSearches] count] == 3 message:@"After setRecentSearches array doesn't include results"];
}

// MARK: Cursor areas

/*
    A search field owns a cursor area for each visible button and an I-beam cursor area for
    its text. The text area must not overlap a button area: the pointer over a button must
    find one area only.
*/
- (CPSearchField)searchFieldWithText:(CPString)aString
{
    var searchField = [[_CursorAreaTestSearchField alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 22.0)];

    /*
        A search field creates its buttons only when a DOM is available, which is not the case
        under ojtest, so the test gives the field its buttons.
    */
    [searchField setSearchButton:[[CPButton alloc] initWithFrame:CGRectMakeZero()]];
    [searchField resetSearchButton];
    [searchField setCancelButton:[[CPButton alloc] initWithFrame:CGRectMakeZero()]];
    [searchField resetCancelButton];

    [searchField setStringValue:aString];
    [searchField layoutSubviews];

    return searchField;
}

- (CPTrackingArea)textAreaOf:(CPSearchField)aSearchField
{
    return [[aSearchField trackingAreas] objectAtIndex:[[aSearchField trackingAreas] indexOfObjectPassingTest:function(anArea)
    {
        return ![[anArea userInfo] objectForKey:@"isButton"];
    }]];
}

- (CPArray)buttonAreasOf:(CPSearchField)aSearchField
{
    var areas = [aSearchField trackingAreas],
        buttonAreas = [];

    for (var i = 0; i < [areas count]; i++)
        if ([[areas[i] userInfo] objectForKey:@"isButton"])
            buttonAreas.push(areas[i]);

    return buttonAreas;
}

- (void)assertTextAreaOf:(CPSearchField)aSearchField overlapsNoneOf:(CPArray)buttonAreas
{
    var textRect = [[self textAreaOf:aSearchField] rect];

    [self assertTrue:CGRectGetWidth(textRect) > 0 message:@"the text area is empty"];

    for (var i = 0; i < [buttonAreas count]; i++)
    {
        var buttonRect = [buttonAreas[i] rect];

        [self assertTrue:CGRectGetWidth(buttonRect) > 0 message:@"button area " + i + " is empty"];
        [self assertFalse:CGRectIntersectsRect(textRect, buttonRect)
                  message:@"the text area " + CPStringFromRect(textRect) + " overlaps button area " + CPStringFromRect(buttonRect)];
    }
}

- (void)testTheTextAreaDoesNotOverlapTheSearchButtonArea
{
    var searchField = [self searchFieldWithText:@""],
        buttonAreas = [self buttonAreasOf:searchField];

    [self assert:1 equals:[buttonAreas count] message:@"an empty field has a search button area only"];
    [self assertTextAreaOf:searchField overlapsNoneOf:buttonAreas];
}

- (void)testTheTextAreaDoesNotOverlapEitherButtonAreaWhenTheFieldHoldsText
{
    var searchField = [self searchFieldWithText:@"text"],
        buttonAreas = [self buttonAreasOf:searchField];

    [self assert:2 equals:[buttonAreas count] message:@"a field with text has a search button area and a cancel button area"];
    [self assertTextAreaOf:searchField overlapsNoneOf:buttonAreas];
}

/*
    -menu answers the search menu, which opens from the search button. A right click shows the
    text field's context menu instead.
*/
- (void)testARightClickShowsTheTextFieldMenuNotTheSearchMenu
{
    var template = [[CPMenu alloc] initWithTitle:@"Search"];

    [template addItemWithTitle:@"Option" action:nil keyEquivalent:@""];
    [_searchField setSearchMenuTemplate:template];

    var menu = [_searchField menuForEvent:nil];

    [self assertNotNull:menu message:@"the search field has a context menu"];
    [self assert:[@"Cut", @"Copy", @"", @"Select All"] equals:[[menu itemArray] valueForKey:@"title"]];
}

/*
    A context menu set by the application comes first, as in a text field.
*/
- (void)testAContextMenuSetByTheApplicationComesFirst
{
    var menu = [[CPMenu alloc] initWithTitle:@"Application"];

    [_searchField setMenu:menu];

    [self assert:menu same:[_searchField menuForEvent:nil]];
}

// MARK: Search button placement

/*
    The theme gives the search button its image, its inset and the margin before the text; the
    field places the button. Under ojtest no theme is loaded, so each test field gets these
    measurements as its own theme values. -sizeWithFont: uses the DOM and gives a zero size in
    the terminal, so the tests compute the expected centred position with it too.
*/
- (CPSearchField)placementTestFieldOfWidth:(float)aWidth class:(Class)aClass
{
    var searchField = [[aClass alloc] initWithFrame:CGRectMake(0.0, 0.0, aWidth, 22.0)];

    [searchField setValue:[[CPImage alloc] initWithContentsOfFile:@"search.png" size:CGSizeMake(16.0, 16.0)] forThemeAttribute:@"image-search"];
    [searchField setValue:CGInsetMake(0.0, 0.0, 0.0, 5.0) forThemeAttribute:@"image-search-inset"];
    [searchField setValue:4 forThemeAttribute:@"search-right-margin"];

    return searchField;
}

- (float)centredSearchButtonXIn:(CPSearchField)aSearchField
{
    var placeholderWidth = [[aSearchField placeholderString] sizeWithFont:[aSearchField font]].width;

    return MAX(5.0, (CGRectGetWidth([aSearchField bounds]) - placeholderWidth) / 2 - 16.0 - 4.0);
}

- (float)searchButtonXIn:(CPSearchField)aSearchField
{
    return CGRectGetMinX([aSearchField searchButtonRectForBounds:[aSearchField bounds]]);
}

- (void)testASearchFieldCentersItsPlaceholderByDefault
{
    [self assertTrue:[_searchField centersPlaceholder]];
}

- (void)testAnEmptyFieldCentresTheSearchButtonWithThePlaceholder
{
    var searchField = [self placementTestFieldOfWidth:200.0 class:[CPSearchField class]];

    [self assert:[self centredSearchButtonXIn:searchField] equals:[self searchButtonXIn:searchField]];
    [self assertTrue:[self searchButtonXIn:searchField] > 5.0 message:@"the search button is not at its leading position"];
}

/*
    A placeholder wider than the field must not push the search button outside it.
*/
- (void)testANarrowFieldKeepsTheSearchButtonAtItsLeadingPosition
{
    var searchField = [self placementTestFieldOfWidth:30.0 class:[CPSearchField class]];

    [self assert:5.0 equals:[self searchButtonXIn:searchField]];
}

- (void)testAFieldWithAValueKeepsTheSearchButtonAtItsLeadingPosition
{
    var searchField = [self placementTestFieldOfWidth:200.0 class:[CPSearchField class]];

    [searchField setStringValue:@"text"];

    [self assert:5.0 equals:[self searchButtonXIn:searchField]];
}

- (void)testAnEditingFieldKeepsTheSearchButtonAtItsLeadingPosition
{
    var searchField = [self placementTestFieldOfWidth:200.0 class:[CPSearchField class]];

    [searchField setThemeState:CPThemeStateEditing];

    [self assert:5.0 equals:[self searchButtonXIn:searchField]];
}

- (void)testAFieldThatDoesNotCentreItsPlaceholderKeepsTheSearchButtonAtItsLeadingPosition
{
    var searchField = [self placementTestFieldOfWidth:200.0 class:[CPSearchField class]];

    [searchField setCentersPlaceholder:NO];

    [self assert:5.0 equals:[self searchButtonXIn:searchField]];
}

- (void)testAButtonBarSearchFieldDoesNotCentreItsPlaceholder
{
    var searchField = [[_CPButtonBarSearchField alloc] initWithPlaceholder:@"Search" minWidth:200.0 maxWidth:200.0];

    [self assertFalse:[searchField centersPlaceholder]];
}

- (void)testCentersPlaceholderIsArchived
{
    [_searchField setCentersPlaceholder:NO];

    var copy = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:_searchField]];

    [self assertFalse:[copy centersPlaceholder]];
}

/*
    A hidden search field, or one that does not hit test, must not take clicks meant for the
    views beneath it, as -[CPView hitTest:] does for any view.
*/
- (void)testAHiddenSearchFieldTakesNoHits
{
    var field = [[CPSearchField alloc] initWithFrame:CGRectMake(10, 10, 100, 22)],
        inside = CGPointMake(20, 20);

    [self assert:field same:[field hitTest:inside] message:@"a shown search field takes a hit in its frame"];

    [field setHidden:YES];
    [self assertNull:[field hitTest:inside] message:@"a hidden search field takes no hit"];

    [field setHidden:NO];
    [field setHitTests:NO];
    [self assertNull:[field hitTest:inside] message:@"a search field that does not hit test takes no hit"];
}

@end
