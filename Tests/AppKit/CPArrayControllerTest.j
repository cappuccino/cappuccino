@implementation CPArrayControllerTest : OJTestCase
{
    CPArrayController   _arrayController @accessors(property=arrayController);
    CPArray             _contentArray @accessors(property=contentArray);

    CPArray             observations;
}

- (void)setUp
{
    _contentArray = [];

    [_contentArray addObject:[Person personWithName:@"Francisco" age:21]];
    [_contentArray addObject:[Person personWithName:@"Ross" age:30]];
    [_contentArray addObject:[Person personWithName:@"Tom" age:15]];

    // Copy the array since we'll reuse the original array later. Also see issue #795.
    _arrayController = [[CPArrayController alloc] initWithContent:[[self contentArray] copy]];
}

- (void)testInitWithContent
{
    [self assert:[self contentArray] equals:[[self arrayController] contentArray]];
    [self assert:[_CPObservableArray class] equals:[[[self arrayController] arrangedObjects] class] message:"arranged objects should be observable"];
}

- (void)testSetContent
{
    otherContent = [@"5", @"6"];
    [[self arrayController] setContent:otherContent];

    // This has not been decided on yet. See Issue #795.
    // [self assertFalse:otherContent === [[self arrayController] contentArray] message:@"array controller should copy it's content"];
    [self assert:otherContent equals:[[self arrayController] contentArray]];
    [self assert:[_CPObservableArray class] equals:[[[self arrayController] arrangedObjects] class]];
}

- (void)testInsertObjectAtArrangedObjectIndex
{
    var object = [Person personWithName:@"Klaas Pieter" age:24],
        arrayController = [self arrayController];

    [arrayController setSortDescriptors:[[CPSortDescriptor sortDescriptorWithKey:@"age" ascending:YES]]];
    [arrayController insertObject:object atArrangedObjectIndex:1];

    [self assert:object equals:[[arrayController arrangedObjects] objectAtIndex:1]];
}

- (void)testSelectPrevious
{
    var arrayController = [self arrayController];

    // Selection index: 1
    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndex:1]];
    [self assertTrue:[arrayController canSelectPrevious] message:@"index > 0; canSelectPrevious should return YES"]

    [arrayController selectPrevious:self];
    [self assert:[CPIndexSet indexSetWithIndex:0] equals:[arrayController selectionIndexes]];

    // Selection index: 0
    [self assertFalse:[arrayController canSelectPrevious] message:@"index <= 0; canSelectPrevious should return NO"];

    [arrayController selectPrevious:self];
    [self assert:[CPIndexSet indexSetWithIndex:0] equals:[arrayController selectionIndexes]];
}

- (void)testSelectNext
{
    var arrayController = [self arrayController],
        count = [[arrayController arrangedObjects] count];

    // Selection index: count - 2
    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndex:count - 2]];
    [self assertTrue:[arrayController canSelectNext] message:@"index < (count - 1); canSelectNext should return YES"];

    [arrayController selectNext:self];
    [self assert:[CPIndexSet indexSetWithIndex:count - 1] equals:[arrayController selectionIndexes]];

    // Selection index: count - 1
    [self assertFalse:[arrayController canSelectNext] message:@"index >= (count - 1) canSelectNext should return NO"];

    [arrayController selectNext:self];
    [self assert:[CPIndexSet indexSetWithIndex:count - 1] equals:[arrayController selectionIndexes]];
}

- (void)testRemoveObjects
{
    var arrayController = [self arrayController];
    [arrayController setPreservesSelection:NO];

    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(1, 2)]];
    [arrayController removeObjects:[arrayController selectedObjects]]

    [self assert:[CPIndexSet indexSet] equals:[arrayController selectionIndexes]
         message:@"selection should be empty if arraycontroller doesn't preserve selection"];

    arrayController = [[CPArrayController alloc] initWithContent:[self contentArray]];
    [arrayController setPreservesSelection:YES];

    // Remove from middle
    var selectionIndexes = [CPIndexSet indexSetWithIndex:1];
    [arrayController setSelectionIndexes:selectionIndexes];
    [arrayController removeObjects:[arrayController selectedObjects]];
    [self assert:selectionIndexes equals:[arrayController selectionIndexes] message:@"selection should stay the same"];

    // Remove from end
    [arrayController removeObjects:[[[arrayController content] objectAtIndex:1]]];
    [self assert:[CPIndexSet indexSetWithIndex:0] equals:[arrayController selectionIndexes]
         message:@"last object removed; selection should shift to first available index"];

    // Remove from all
    [arrayController removeObjects:[[[arrayController content] objectAtIndex:0]]];
    [self assert:[CPIndexSet indexSet] equals:[arrayController selectionIndexes] message:@"no objects left, selection should disappear"];
}

- (void)testSelectionWhenObjectsDisappear
{
    // If the selected object disappeares during a rearrange, the selection
    // should update appropriately, even if preserve selection is off.
    var arrayController = [self arrayController];
    [arrayController setPreservesSelection:NO];

    // Use a copy to make sure our original remains pristine.
    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 3)]];

    var newContent = [[self contentArray] copy];
    [newContent removeObjectAtIndex:2];

    [arrayController setContent:newContent];

    [self assert:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 2)] equals:[arrayController selectionIndexes]
         message:@"last object cannot be selected"];
}

- (void)testContentBinding
{
    [[self arrayController] bind:@"contentArray" toObject:self withKeyPath:@"contentArray" options:0];

    [self assert:[[self arrayController] contentArray] equals:[self contentArray]];

    [[self mutableArrayValueForKey:@"contentArray"] addObject:@"4"];
    [self assert:[self contentArray] equals:[[self arrayController] contentArray]
         message:@"object 4 was added; contentArray should reflect this"];

    [[self arrayController] insertObject:@"2" atArrangedObjectIndex:1];
    [self assert:[[self arrayController] contentArray] equals:[self contentArray]];
}

- (CPArray)setupObservationFixture
{
    // objj_msgSend_decorate(objj_backtrace_decorator);

    var ac = [self arrayController];
    [ac setSelectionIndex:0];
    [ac setPreservesSelection:YES];
    var newContent = [_contentArray copy];
    [newContent removeObjectAtIndex:0];

    [ac addObserver:self forKeyPath:"content" options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew  context:nil];
    [ac addObserver:self forKeyPath:"selectionIndexes" options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew  context:nil];
    [ac addObserver:self forKeyPath:"selectedObjects" options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew  context:nil];
    [ac addObserver:self forKeyPath:"arrangedObjects" options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew  context:nil];

    observations = [];

    return newContent;
}

- (void)testObservationDuringSetContent
{
    /*
        There are two areas where CPArrayController can get into trouble with observation.

        The more serious one is that the before values when observing selectedObjects
        need to be correct and not affected by the new setContent: values.

        Second, the array controller should not send out more than one of each notification
        since repeated notifications for the same change can be a huge performance drain
        from such a central piece of code.
    */

    var ac = [self arrayController],
        newContent = [self setupObservationFixture];

    [ac setContent:newContent];

    [observations sortUsingFunction:function(a, b) { return [a.keyPath compare:b.keyPath] } context:nil];
    [self assert:4 equals:[observations count] message:"exactly 4 change notifications should be sent for new content"];

    // for (var i=0; i<observations.length; i++)
    //    CPLog.error(observations[i].keyPath);

    var observation = observations[0];
    [self assert:"arrangedObjects" equals:observation.keyPath];
    [self assert:_contentArray equals:observation.oldValue message:"old arranged content should be correct"];
    [self assert:newContent equals:observation.newValue message:"new arranged content should be correct"];

    observation = observations[1];
    [self assert:"content" equals:observation.keyPath];
    [self assert:_contentArray equals:observation.oldValue message:"old content should be correct"];
    [self assert:newContent equals:observation.newValue message:"new content should be correct"];

    observation = observations[2];
    [self assert:"selectedObjects" equals:observation.keyPath];
    [self assert:[_contentArray[0]] equals:observation.oldValue message:"old selected objects should be previous object at selected index"];
    [self assert:[] equals:observation.newValue message:"new selected objects should be nothing"];

    observation = observations[3];
    [self assert:"selectionIndexes" equals:observation.keyPath];
    [self assert:[CPIndexSet indexSetWithIndex:0] equals:observation.oldValue message:"old selected index should be 0"];
    [self assert:[CPIndexSet indexSet] equals:observation.newValue message:"new selected index should be nothing"];
}

- (void)testObservationDuringRearrange
{
    var ac = [self arrayController],
        newContent = [self setupObservationFixture],
        selection = [CPIndexSet indexSetWithIndex:0];

    [selection addIndex:1];
    // Francisco and Ross selected.
    [ac setSelectionIndexes:selection];

    observations = [];
    [ac setFilterPredicate:[CPPredicate predicateWithFormat:@"(name != %@)", "Francisco"]];

    [observations sortUsingFunction:function(a, b) { return [a.keyPath compare:b.keyPath] } context:nil];
    //for (var i=0; i<observations.length; i++)
    //    CPLog.error(observations[i].keyPath);
    [self assert:3 equals:[observations count] message:"exactly 3 change notifications should be sent for new filter"];

    var observation = observations[0];
    [self assert:"arrangedObjects" equals:observation.keyPath];
    [self assert:_contentArray equals:observation.oldValue message:"old arranged content should be correct"];
    [self assert:newContent equals:observation.newValue message:"new arranged content should be correct"];

    observation = observations[1];
    [self assert:"selectedObjects" equals:observation.keyPath];
    [self assert:[_contentArray[0], _contentArray[1]] equals:observation.oldValue message:"old selected objects should be previous object at selected index"];
    [self assert:[_contentArray[1]] equals:observation.newValue message:"new selected objects should be only non filtered ones"];

    observation = observations[2];
    [self assert:"selectionIndexes" equals:observation.keyPath];
    [self assert:selection equals:observation.oldValue message:"old selected index should be 0 and 1"];
    [self assert:[CPIndexSet indexSetWithIndex:0] equals:observation.newValue message:"new selected index should be 0"];
}

- (void)testObservationDuringSetSelectionIndexes
{
    var arrayController = [self arrayController],
        newContent = [self setupObservationFixture];

    var newSelection = [CPIndexSet indexSetWithIndex:2];
    [arrayController setSelectionIndexes:newSelection];

    [self assertNotNull:[arrayController selection] message:@"a selection was made, selection proxy should be defined"];
    [self assert:2 equals:[observations count] message:@"exactly 2 change notifications should be sent for new selection indexes"];
    [self assert:newSelection equals:[arrayController selectionIndexes] message:@"selection was not set properly"];
}

- (void)observeValueForKeyPath:keyPath
    ofObject:anActivity
    change:change
    context:context
{
    // CPLog.warn("observeValueForKeyPath:" + keyPath);
    // objj_backtrace_print(CPLog.error);

    [observations addObject:{
        keyPath: keyPath,
        oldValue: [change valueForKey:CPKeyValueChangeOldKey],
        newValue: [change valueForKey:CPKeyValueChangeNewKey]
    }];
}

@end

@implementation Person : CPObject
{
    CPString  _name @accessors(property=name);
    int       _age @accessors(property=age);
}

+ (id)personWithName:(CPString)aName age:(int)anAge
{
    return [[self alloc] initWithName:aName age:anAge];
}

- (id)initWithName:(CPString)aName age:(int)anAge
{
    if (self = [super init])
    {
        _name = aName;
        _age = anAge;
    }

    return self;
}

- (CPString)description
{
    return [CPString stringWithFormat:@"<Person %@ : %@>", [self name], [self age]];
}

@end