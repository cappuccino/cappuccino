@import <AppKit/AppKit.j>

@implementation CPSearchFieldTest : OJTestCase
{
    CPSearchField _searchField;
}

- (void)setUp
{
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

@end
