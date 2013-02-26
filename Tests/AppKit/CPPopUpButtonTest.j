
@import <AppKit/CPKeyValueBinding.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPApplication.j>

@implementation CPPopUpButtonTest : OJTestCase
{
    CPPopUpButton button @accessors;
    id objects @accessors;
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

    // Removing the selected item resets the selection to item 0.
    [self assert:0 equals:[popUpButton indexOfSelectedItem]];

    // Removing an item underneath the selected item moves the selection.
    [popUpButton selectItemAtIndex:4];
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
    var dict = @{},
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

- (void)testSimpleStringBindingArrayController
{
    var arrayController = [[CPArrayController alloc] init],
        objectController = [[CPObjectController alloc] init],
        testObject = [CPMutableDictionary dictionary],
        martin = @"Martin",
        malte = @"Malte",
        johan = @"Johan",
        menuObjects = [martin, malte, johan];

    [testObject setObject:@"I'm a testObject" forKey:@"Who am I"];
    [arrayController setContent:menuObjects];
    [objectController setContent:testObject];

    [button bind:CPContentBinding toObject:arrayController withKeyPath:@"arrangedObjects" options:nil];
    [button bind:CPSelectedObjectBinding toObject:objectController withKeyPath:@"selection.xxx" options:nil];

    [[self button] selectItemWithTitle:@"Martin"];
    [[self button] sendAction:@selector(actionTest:) to:self]; // This has to be done to trigger the reverse set of the binding
    [self assert:martin equals:[testObject objectForKey:@"xxx"]];
    [[self button] selectItemWithTitle:@"Malte"];
    [[self button] sendAction:@selector(actionTest:) to:self];
    [self assert:malte equals:[testObject objectForKey:@"xxx"]];
    [[self button] selectItemWithTitle:@"Johan"];
    [[self button] sendAction:@selector(actionTest:) to:self];
    [self assert:johan equals:[testObject objectForKey:@"xxx"]];

    [testObject setObject:martin forKey:@"xxx"];
    [self assert:0 equals:[[self button] indexOfSelectedItem]];
    [testObject setObject:malte forKey:@"xxx"];
    [self assert:1 equals:[[self button] indexOfSelectedItem]];
    [testObject setObject:johan forKey:@"xxx"];
    [self assert:2 equals:[[self button] indexOfSelectedItem]];
}

- (void)testSimpleStringBindingNullPlaceholderOption
{
    var arrayController = [[CPArrayController alloc] init],
        objectController = [[CPObjectController alloc] init],
        testObject = [CPMutableDictionary dictionary],
        martin = @"Martin",
        malte = @"Malte",
        johan = @"Johan",
        menuObjects = [martin, malte, johan],
        insertsNullPlaceholderOption = [CPDictionary dictionaryWithObjects:[YES, @"Null Placeholder"] forKeys:[CPInsertsNullPlaceholderBindingOption, CPNullPlaceholderBindingOption]];

    [testObject setObject:@"I'm a testObject" forKey:@"Who am I"];
    [arrayController setContent:menuObjects];
    [objectController setContent:testObject];

    [button bind:CPContentBinding toObject:arrayController withKeyPath:@"arrangedObjects" options:insertsNullPlaceholderOption];
    [button bind:CPSelectedObjectBinding toObject:objectController withKeyPath:@"selection.xxx" options:insertsNullPlaceholderOption];

    [[self button] selectItemWithTitle:@"Martin"];
    [[self button] sendAction:@selector(actionTest:) to:self]; // This has to be done to trigger the reverse set of the binding
    [self assert:martin equals:[testObject objectForKey:@"xxx"]];
    [[self button] selectItemWithTitle:@"Malte"];
    [[self button] sendAction:@selector(actionTest:) to:self];
    [self assert:malte equals:[testObject objectForKey:@"xxx"]];
    [[self button] selectItemWithTitle:@"Johan"];
    [[self button] sendAction:@selector(actionTest:) to:self];
    [self assert:johan equals:[testObject objectForKey:@"xxx"]];

    [[self button] selectItemWithTitle:@"Null Placeholder"];
    [[self button] sendAction:@selector(actionTest:) to:self];
    [self assertNull:[testObject objectForKey:@"xxx"]];

    [testObject setObject:martin forKey:@"xxx"];
    [self assert:1 equals:[[self button] indexOfSelectedItem]];
    [testObject setObject:malte forKey:@"xxx"];
    [self assert:2 equals:[[self button] indexOfSelectedItem]];
    [testObject setObject:johan forKey:@"xxx"];
    [self assert:3 equals:[[self button] indexOfSelectedItem]];

    [testObject removeObjectForKey:@"xxx"];
    [self assert:0 equals:[[self button] indexOfSelectedItem]];
}

- (void)testSimpleObjectBindingArrayController
{
    var arrayController = [[CPArrayController alloc] init],
        objectController = [[CPObjectController alloc] init],
        testObject = [CPMutableDictionary dictionary],
        martin = [CPDictionary dictionaryWithJSObject:{@"name": @"Martin"}],
        malte = [CPDictionary dictionaryWithJSObject:{@"name": @"Malte"}],
        johan = [CPDictionary dictionaryWithJSObject:{@"name": @"Johan"}],
        menuObjects = [martin, malte, johan];

    [testObject setObject:@"I'm a testObject" forKey:@"Who am I"];
    [arrayController setContent:menuObjects];
    [objectController setContent:testObject];

    [button bind:CPContentBinding toObject:arrayController withKeyPath:@"arrangedObjects" options:nil];
    [button bind:CPContentValuesBinding toObject:arrayController withKeyPath:@"arrangedObjects.name" options:nil];
    [button bind:CPSelectedObjectBinding toObject:objectController withKeyPath:@"selection.xxx" options:nil];

    [[self button] selectItemWithTitle:@"Martin"];
    [[self button] sendAction:@selector(actionTest:) to:self]; // This has to be done to trigger the reverse set of the binding
    [self assert:martin equals:[testObject objectForKey:@"xxx"]];
    [[self button] selectItemWithTitle:@"Malte"];
    [[self button] sendAction:@selector(actionTest:) to:self];
    [self assert:malte equals:[testObject objectForKey:@"xxx"]];
    [[self button] selectItemWithTitle:@"Johan"];
    [[self button] sendAction:@selector(actionTest:) to:self];
    [self assert:johan equals:[testObject objectForKey:@"xxx"]];

    [testObject setObject:martin forKey:@"xxx"];
    [self assert:0 equals:[[self button] indexOfSelectedItem]];
    [testObject setObject:malte forKey:@"xxx"];
    [self assert:1 equals:[[self button] indexOfSelectedItem]];
    [testObject setObject:johan forKey:@"xxx"];
    [self assert:2 equals:[[self button] indexOfSelectedItem]];
}

- (void)testObjectBindingNullPlaceholderOption
{
    var arrayController = [[CPArrayController alloc] init],
        martin = [CPDictionary dictionaryWithJSObject:{@"name": @"Martin"}],
        malte = [CPDictionary dictionaryWithJSObject:{@"name": @"Malte"}],
        johan = [CPDictionary dictionaryWithJSObject:{@"name": @"Johan"}],
        menuObjects = [martin, malte, johan],
        insertsNullPlaceholderOption = [CPDictionary dictionaryWithObjects:[YES, @"Null Placeholder"] forKeys:[CPInsertsNullPlaceholderBindingOption, CPNullPlaceholderBindingOption]];

    [arrayController setContent:menuObjects];
    [button bind:CPContentBinding toObject:arrayController withKeyPath:@"arrangedObjects" options:insertsNullPlaceholderOption];
    [button bind:CPContentValuesBinding toObject:arrayController withKeyPath:@"arrangedObjects.name" options:insertsNullPlaceholderOption];

    [self assert:4 equals:[[self button] numberOfItems]];
    [self assert:0 equals:[[self button] indexOfItemWithTitle:@"Null Placeholder"]];
    [self assert:1 equals:[[self button] indexOfItemWithTitle:@"Martin"]];
    [self assert:2 equals:[[self button] indexOfItemWithTitle:@"Malte"]];
    [self assert:3 equals:[[self button] indexOfItemWithTitle:@"Johan"]];

    [button unbind:CPContentValuesBinding];
    [button unbind:CPContentBinding];
    [button bind:CPContentValuesBinding toObject: arrayController withKeyPath:@"arrangedObjects.name" options:nil];
    [button bind:CPContentBinding toObject:arrayController withKeyPath:@"arrangedObjects" options:nil];

    [self assert:3 equals:[[self button] numberOfItems]];
    [self assert:0 equals:[[self button] indexOfItemWithTitle:@"Martin"]];
    [self assert:1 equals:[[self button] indexOfItemWithTitle:@"Malte"]];
    [self assert:2 equals:[[self button] indexOfItemWithTitle:@"Johan"]];
}

- (void)testSelectedObjectBindingArrayController
{
    var arrayController = [[CPArrayController alloc] init],
        objectController = [[CPObjectController alloc] init],
        testObject = [CPMutableDictionary dictionary],
        martin = [CPDictionary dictionaryWithJSObject:{@"name": @"Martin"}],
        malte = [CPDictionary dictionaryWithJSObject:{@"name": @"Malte"}],
        johan = [CPDictionary dictionaryWithJSObject:{@"name": @"Johan"}],
        menuObjects = [martin, malte, johan],
        insertsNullPlaceholderOption = [CPDictionary dictionaryWithObjects:[YES, @"Null Placeholder"] forKeys:[CPInsertsNullPlaceholderBindingOption, CPNullPlaceholderBindingOption]];

    [testObject setObject:@"I'm a testObject" forKey:@"Who am I"];
    [arrayController setContent:menuObjects];
    [objectController setContent:testObject];

    [button bind:CPContentBinding toObject:arrayController withKeyPath:@"arrangedObjects" options:insertsNullPlaceholderOption];
    [button bind:CPContentValuesBinding toObject:arrayController withKeyPath:@"arrangedObjects.name" options:insertsNullPlaceholderOption];
    [button bind:CPSelectedObjectBinding toObject:objectController withKeyPath:@"selection.xxx" options:nil];

    [self assert:4 equals:[[self button] numberOfItems]];
    [self assert:0 equals:[[self button] indexOfItemWithTitle:@"Null Placeholder"]];
    [self assert:1 equals:[[self button] indexOfItemWithTitle:@"Martin"]];
    [self assert:2 equals:[[self button] indexOfItemWithTitle:@"Malte"]];
    [self assert:3 equals:[[self button] indexOfItemWithTitle:@"Johan"]];

    [[self button] selectItemWithTitle:@"Martin"];
    [[self button] sendAction:@selector(actionTest:) to:self]; // This has to be done to trigger the reverse set of the binding
    [self assert:martin equals:[testObject objectForKey:@"xxx"]];
    [[self button] selectItemWithTitle:@"Malte"];
    [[self button] sendAction:@selector(actionTest:) to:self];
    [self assert:malte equals:[testObject objectForKey:@"xxx"]];
    [[self button] selectItemWithTitle:@"Johan"];
    [[self button] sendAction:@selector(actionTest:) to:self];
    [self assert:johan equals:[testObject objectForKey:@"xxx"]];

    [[self button] selectItemWithTitle:@"Null Placeholder"];
    [[self button] sendAction:@selector(actionTest:) to:self];
    [self assertNull:[testObject objectForKey:@"xxx"]];

    [testObject setObject:martin forKey:@"xxx"];
    [self assert:1 equals:[[self button] indexOfSelectedItem]];
    [testObject setObject:malte forKey:@"xxx"];
    [self assert:2 equals:[[self button] indexOfSelectedItem]];
    [testObject setObject:johan forKey:@"xxx"];
    [self assert:3 equals:[[self button] indexOfSelectedItem]];

    [testObject removeObjectForKey:@"xxx"];
    [self assert:0 equals:[[self button] indexOfSelectedItem]];
}

- (void)testContentValuesWithValueTransformer
{
    var arrayController = [[CPArrayController alloc] init],
        martin = [CPDictionary dictionaryWithJSObject:{@"name": @"Martin"}],
        malte = [CPDictionary dictionaryWithJSObject:{@"name": @"Malte"}],
        johan = [CPDictionary dictionaryWithJSObject:{@"name": @"Johan"}],
        menuObjects = [martin, malte, johan];

    [arrayController setContent:menuObjects];

    [button bind:CPContentBinding toObject:arrayController withKeyPath:@"arrangedObjects" options:nil];
    var options = @{};
    [options setObject:[ContentValuesTransformer new] forKey:CPValueTransformerBindingOption];
    [button bind:CPContentValuesBinding toObject:arrayController withKeyPath:@"arrangedObjects.name" options:options];

    [self assert:@"Transformed-Malte" equals:[[[self button] itemAtIndex:1] title]];
}

- (void)testSelectedIndexBindingWithInsertsNullOption
{
    var arrayController = [[CPArrayController alloc] init],
        testObject = [CPMutableDictionary dictionary],
        martin = @"Martin",
        malte = @"Malte",
        johan = @"Johan",
        menuObjects = [martin, malte, johan],
        insertsNullPlaceholderOption = [CPDictionary dictionaryWithObjects:[YES, @"Null Placeholder"] forKeys:[CPInsertsNullPlaceholderBindingOption, CPNullPlaceholderBindingOption]];

    [arrayController setContent:menuObjects];
    [button bind:CPContentBinding toObject:arrayController withKeyPath:@"arrangedObjects" options:insertsNullPlaceholderOption];
    [button bind:CPSelectedIndexBinding toObject:testObject withKeyPath:@"index" options:nil];

    [[self button] selectItemWithTitle:@"Martin"];
    [[self button] sendAction:@selector(actionTest:) to:self]; // This has to be done to trigger the reverse set of the binding
    [self assert:0 equals:[testObject objectForKey:@"index"]];
    [[self button] selectItemWithTitle:@"Malte"];
    [[self button] sendAction:@selector(actionTest:) to:self];
    [self assert:1 equals:[testObject objectForKey:@"index"]];
    [[self button] selectItemWithTitle:@"Johan"];
    [[self button] sendAction:@selector(actionTest:) to:self];
    [self assert:2 equals:[testObject objectForKey:@"index"]];

    [[self button] selectItemWithTitle:@"Null Placeholder"];
    [[self button] sendAction:@selector(actionTest:) to:self];
    [self assert:-1 equals:[testObject objectForKey:@"index"]];
}

- (void)actionTest:(id)sender
{
}

- (void)testRemoveItemAtIndex_
{
    button = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 28.0) pullsDown:NO];

    [self assert:CPNotFound equals:[button indexOfSelectedItem] message:"no item selected in empty pop up"];

    [button addItemWithTitle:@"one"];
    [button addItemWithTitle:@"two"];
    [button addItemWithTitle:@"three"];
    [button addItemWithTitle:@"four"];

    // Note this behaviour is different for pullsDown:YES.
    [self assert:0 equals:[button indexOfSelectedItem] message:"first item selected after items added"];

    [button selectItemAtIndex:3];

    [self assert:3 equals:[button indexOfSelectedItem] message:"last item selected"];

    [button removeItemAtIndex:3];
    [self assert:0 equals:[button indexOfSelectedItem] message:"first item selected after selected item deleted"];

    [button selectItemAtIndex:2];
    [button removeItemAtIndex:1];
    [self assert:1 equals:[button indexOfSelectedItem] message:"selection index reduced when a prior item is removed"];
}

@end


@implementation ContentValuesTransformer : CPValueTransformer
{
}

- (id)transformedValue:(id)aValue
{
    return "Transformed-" + aValue;
}

@end
