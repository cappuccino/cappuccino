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

@end
