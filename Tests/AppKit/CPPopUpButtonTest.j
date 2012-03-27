
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPApplication.j>

@implementation CPPopUpButtonTest : OJTestCase
{
    CPPopUpButton button @accessors;
}

- (void)setUp
{
    button = [CPPopUpButton new];
}

- (void)testMenuSynchronization
{
    var popUpButton = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 28.0) pullsDown:NO];

    [self assert:CPNotFound equals:[popUpButton indexOfSelectedItem]];

    [popUpButton addItemWithTitle:@"one"];

    [self assert:0 equals:[popUpButton indexOfSelectedItem]];

    [popUpButton addItemWithTitle:@"two"];
    [popUpButton addItemWithTitle:@"three"];
    [popUpButton addItemWithTitle:@"four"];
    [popUpButton addItemWithTitle:@"five"];
    [popUpButton addItemWithTitle:@"six"];

    [self assert:0 equals:[popUpButton indexOfSelectedItem]];

    [popUpButton insertItemWithTitle:@"negative one" atIndex:0];

    [self assert:1 equals:[popUpButton indexOfSelectedItem]];

    var items = [
        [[CPMenuItem alloc] initWithTitle:@"negative five" action:nil keyEquivalent:@""],
        [[CPMenuItem alloc] initWithTitle:@"negative four" action:nil keyEquivalent:@""],
        [[CPMenuItem alloc] initWithTitle:@"negative three" action:nil keyEquivalent:@""],
        [[CPMenuItem alloc] initWithTitle:@"negative two" action:nil keyEquivalent:@""]
                ],
        indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 4)],
        mutableItemsArray = [[popUpButton menu] mutableArrayValueForKey:@"items"];

    [mutableItemsArray insertObjects:items atIndexes:indexes];

    [self assert:5 equals:[popUpButton indexOfSelectedItem]];

    [[popUpButton menu] removeItemAtIndex:5];

    [self assert:4 equals:[popUpButton indexOfSelectedItem]];

    [[popUpButton menu] removeItemAtIndex:0];

    [self assert:3 equals:[popUpButton indexOfSelectedItem]];

    [popUpButton selectItemAtIndex:1];

    indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(1, 3)];
    [mutableItemsArray removeObjectsAtIndexes:indexes];

    [self assert:0 equals:[popUpButton indexOfSelectedItem]];

    var pullDownButton = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 28.0) pullsDown:YES];

    [pullDownButton addItemWithTitle:@"First Item"];

    [self assert:YES equals:[[pullDownButton itemAtIndex:0] isHidden]];

    [pullDownButton addItemWithTitle:@"Second Item"];

    [self assert:YES equals:[[pullDownButton itemAtIndex:0] isHidden]];
    [self assert:NO equals:[[pullDownButton itemAtIndex:1] isHidden]];

    [pullDownButton removeItemAtIndex:0];

    [self assert:YES equals:[[pullDownButton itemAtIndex:0] isHidden]];

    [pullDownButton insertItemWithTitle:@"A Title" atIndex:0];

    [self assert:YES equals:[[pullDownButton itemAtIndex:0] isHidden]];
    [self assert:NO equals:[[pullDownButton itemAtIndex:1] isHidden]];
}

- (void)testMenuItemSynchronization
{
    var popUpButton = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 28.0) pullsDown:NO];

    [popUpButton addItemWithTitle:@"zero"];
    [popUpButton addItemWithTitle:@"one"];
    [popUpButton addItemWithTitle:@"two"];
    [popUpButton addItemWithTitle:@"three"];
    [popUpButton addItemWithTitle:@"four"];
    [popUpButton addItemWithTitle:@"five"];
    [popUpButton addItemWithTitle:@"six"];

    [self assert:@"zero" same:[popUpButton title]];

    [[popUpButton itemAtIndex:0] setTitle:@"new title"];

    [self assert:@"new title" same:[popUpButton title]];

    [popUpButton selectItemAtIndex:3];

    [self assert:@"three" same:[popUpButton title]];

    [[popUpButton itemAtIndex:3] setTitle:@"something else"];

    [self assert:@"something else" same:[popUpButton title]];

    [popUpButton selectItemAtIndex:6];

    [self assert:@"six" same:[popUpButton title]];

    [[popUpButton itemAtIndex:6] setTitle:@"another title"];

    [self assert:@"another title" same:[popUpButton title]];

    var popUpButton = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 28.0) pullsDown:YES];

    [popUpButton addItemWithTitle:@"zero"];
    [popUpButton addItemWithTitle:@"one"];
    [popUpButton addItemWithTitle:@"two"];
    [popUpButton addItemWithTitle:@"three"];
    [popUpButton addItemWithTitle:@"four"];
    [popUpButton addItemWithTitle:@"five"];
    [popUpButton addItemWithTitle:@"six"];

    [self assert:@"zero" same:[popUpButton title]];

    [[popUpButton itemAtIndex:0] setTitle:@"new title"];

    [self assert:@"new title" same:[popUpButton title]];

    [popUpButton selectItemAtIndex:3];

    [self assert:@"new title" same:[popUpButton title]];

    [[popUpButton itemAtIndex:3] setTitle:@"something else"];

    [self assert:@"new title" same:[popUpButton title]];

    [popUpButton selectItemAtIndex:6];

    [self assert:@"new title" same:[popUpButton title]];

    [[popUpButton itemAtIndex:6] setTitle:@"another title"];

    [self assert:@"new title" same:[popUpButton title]];
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

    [self assert:20 equals:[[button  selectedItem] tag]];

    [button selectItemAtIndex:1];
    // simulate selection by the user (this fails because we don't reverse set the value)
    // see the discussion for pull request 1018 for more details about the problem.
    // https://github.com/280north/cappuccino/pull/1018
    // [button sendAction:[button action] to:[button target]];
    //
    // [self assert:4990000 equals:[dict objectForKey:@"weight"]];
}

- (void)testItemWithTitle
{
    [self assert:nil equals:[[self button] itemWithTitle:@"I dont exist"]];

    [[self button] addItemWithTitle:@"one"];
    [[self button] addItemWithTitle:@"two"];
    [[self button] addItemWithTitle:@"three"];

    [self assert:0 equals:[[self button] indexOfItemWithTitle:@"one"]];
    [self assert:1 equals:[[self button] indexOfItemWithTitle:@"two"]];
    [self assert:2 equals:[[self button] indexOfItemWithTitle:@"three"]];
}

@end
