
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPApplication.j>

@implementation CPPopUpButtonTest : OJTestCase
{
    CPPopUpButton button;
}

- (void)setUp
{
    button = [CPPopUpButton new];
}

- (void)testItemTitles
{
    [self assert:[] equals:[button itemTitles]];
    [button addItem:[[CPMenuItem alloc] initWithTitle:"Option A" action:nil keyEquivalent:nil]];
    [button addItem:[[CPMenuItem alloc] initWithTitle:"Option B" action:nil keyEquivalent:nil]];
    [self assert:["Option A", "Option B"] equals:[button itemTitles]];
}

- (void)testBindingSelectedTag
{
    var dict = [CPDictionary dictionary],
        item = nil;

    item = [[CPMenuItem alloc] initWithTitle:@"Mouse" action:nil keyEquivalent:nil];
    [item setTag:20];
    [button addItem:item];

    item = [[CPMenuItem alloc] initWithTitle:@"Elephant" action:nil keyEquivalent:nil];
    [item setTag:4990000];
    [button addItem:item];

    [dict setObject:20 forKey:@"weight"];

    [button bind:@"selectedTag"
        toObject:dict
     withKeyPath:@"weight"
         options:nil];

    [self assert:20 equals:[button _selectedTag]];

    [button selectItemAtIndex:1];
    // simulate selection by the user (this fails because we don't reverse set the value)
    // see the discussion for pull request 1018 for more details about the problem.
    // https://github.com/280north/cappuccino/pull/1018
    // [button sendAction:[button action] to:[button target]];
    //
    // [self assert:4990000 equals:[dict objectForKey:@"weight"]];
}

@end
