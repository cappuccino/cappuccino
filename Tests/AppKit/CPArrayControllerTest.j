
@import <AppKit/CPArrayController.j>
@import <AppKit/CPTextField.j>

@implementation CPArrayControllerTest : OJTestCase
{
    CPArrayController   _arrayController @accessors(property=arrayController);
    CPArray             _contentArray @accessors(property=contentArray);

    CPArray             observations;
}

- (CPArray)makeTestArray
{
    return [[Employee employeeWithName:@"Francisco" department:[Department departmentWithName:@"Cappuccino"]],
        [Employee employeeWithName:@"Ross" department:[Department departmentWithName:@"Cappuccino"]],
        [Employee employeeWithName:@"Tom" department:[Department departmentWithName:@"CommonJS"]]];
}

- (void)initControllerWithSimpleArray
{
    // Copy the array to allow the original to be reused.
    _arrayController = [[CPArrayController alloc] initWithContent:[[self contentArray] copy]];
}

- (void)initControllerWithContentBinding
{
    _arrayController = [CPArrayController new];
    // The itemsArray keypath is implemented through KVC methods pointing to _contentArray.
    [_arrayController bind:@"contentArray" toObject:self withKeyPath:@"itemsArray" options:nil];
}

- (void)setUp
{
    _contentArray = [self makeTestArray];
    [self initControllerWithSimpleArray]
}

- (void)testInitWithContent
{
    [self assert:[self contentArray] equals:[[self arrayController] contentArray]];
    [self assert:[_CPObservableArray class] equals:[[[self arrayController] arrangedObjects] class] message:"arranged objects should be observable"];
}

- (void)testInitWithoutContent
{
    _arrayController = [[CPArrayController alloc] init];
    [self assert:[] equals:[[self arrayController] contentArray]];
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

- (void)testInsertObjectAtArrangedObjectIndex_SimpleArray
{
    [self initControllerWithSimpleArray];
    [self _testInsertObjectAtArrangedObjectIndex];
}

- (void)testInsertObjectAtArrangedObjectIndex_ContentBinding
{
    [self initControllerWithContentBinding];
    [self _testInsertObjectAtArrangedObjectIndex];
}

- (void)_testInsertObjectAtArrangedObjectIndex
{
    var object = [Employee employeeWithName:@"Klaas Pieter" department:[Department departmentWithName:@"Theming"]],
        arrayController = [self arrayController];

    [arrayController setSortDescriptors:[[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    [arrayController insertObject:object atArrangedObjectIndex:1];

    [self assert:object equals:[[arrayController arrangedObjects] objectAtIndex:1]];
}

- (void)testAddObjectUpdatesArrangedObjectsWithoutSortDescriptors
{
    var arrayController = [[CPArrayController alloc] init];

    [arrayController addObject:@"content"];
    [self assert:[@"content"] equals:[arrayController content]];
    [self assert:[@"content"] equals:[arrayController arrangedObjects]];
}

- (void)testInsertObjectUpdatesArrangedObjectsWithoutSortDescriptors
{
    var arrayController = [[CPArrayController alloc] init];

    [arrayController insertObject:@"content" atArrangedObjectIndex:0];
    [self assert:[@"content"] equals:[arrayController content]];
    [self assert:[@"content"] equals:[arrayController arrangedObjects]];
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


/*!
    Verify that the arranged objects ordering is correct versus the content array when objects are added with addObject and no sort descriptors are set.

    (setContent: based version.)
*/
- (void)testAddObject_SimpleArray
{
    _contentArray = [];
    // Don't use a copy, use direct access for this particular test.
    _arrayController = [[CPArrayController alloc] initWithContent:_contentArray];
    [self _testAddObject];
}

/*!
    Verify that the arranged objects ordering is correct versus the content array when objects are added with addObject and no sort descriptors are set.

    (content binding based version.)
*/
- (void)testAddObject_ContentBinding
{
    _contentArray = [];
    [self initControllerWithContentBinding];
    [self _testAddObject];
}

- (void)_testAddObject
{
    [_arrayController addObject:[CPNumber numberWithInt:1]];
    [_arrayController addObject:[CPNumber numberWithInt:2]];

    [self assert:[CPNumber numberWithInt:1] equals:_contentArray[0]];
    [self assert:[CPNumber numberWithInt:2] equals:_contentArray[1]];

    [self assert:2 equals:[[_arrayController arrangedObjects] count]];
    [self assert:[CPNumber numberWithInt:1] equals:[_arrayController arrangedObjects][0] message:"arranged objects should be in the correct order"];
    [self assert:[CPNumber numberWithInt:2] equals:[_arrayController arrangedObjects][1] message:"arranged objects should be in the correct order"];

    [_arrayController rearrangeObjects];

    [self assert:[CPNumber numberWithInt:1] equals:[_arrayController arrangedObjects][0]];
    [self assert:[CPNumber numberWithInt:2] equals:[_arrayController arrangedObjects][1]];
}

- (void)testRemoveObjectsWithoutAvoidingEmptySelection_SimpleArray
{
    [self initControllerWithSimpleArray];
    [self _testRemoveObjectsWithoutAvoidingEmptySelection];
}

- (void)testRemoveObjectsWithoutAvoidingEmptySelection_ContentBinding
{
    [self initControllerWithContentBinding];
    [self _testRemoveObjectsWithoutAvoidingEmptySelection];
}

- (void)_testRemoveObjectsWithoutAvoidingEmptySelection
{
    var arrayController = [self arrayController];
    [arrayController setAvoidsEmptySelection:NO];
    [arrayController setPreservesSelection:NO];

    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(1, 2)]];
    [arrayController removeObjects:[arrayController selectedObjects]]

    [self assert:[CPIndexSet indexSet] equals:[arrayController selectionIndexes]
         message:@"selection should be empty if arraycontroller doesn't avoid empty selection"];
}

- (void)testRemoveObjectsWithPreservesSelection_SimpleArray
{
    [self initControllerWithSimpleArray];
    [self _testRemoveObjectsWithPreservesSelection];
}

- (void)testRemoveObjectsWithPreservesSelection_ContentBinding
{
    [self initControllerWithContentBinding];
    [self _testRemoveObjectsWithPreservesSelection];
}

- (void)_testRemoveObjectsWithPreservesSelection
{
    var arrayController = [self arrayController];
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

- (void)testRemoveObjectsWithoutSelection
{
    var arrayController = [self arrayController],
        objectsToRemove = [[[self arrayController] arrangedObjects] objectsAtIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(1, 2)]];

    // without any selection
    [arrayController setSelectedObjects:[]];

    // we should be able to remove arbitrary sets of objects
    [arrayController removeObjects:objectsToRemove];

    for (var i = 0; i < [objectsToRemove count]; i++)
        [self assertFalse:[[arrayController arrangedObjects] containsObject:[objectsToRemove objectAtIndex:i]] message:@"remove objects should no longer appear in arrangedObjects"];
}

- (void)testRemoveObject
{
    var arrayController = [self arrayController],
        objectToRemove = [[arrayController arrangedObjects] objectAtIndex:0];

    // without any selection
    [arrayController setSelectedObjects:[]];

    // we should be able to remove arbitrary objects
    [arrayController removeObject:objectToRemove];

    [self assertFalse:[[arrayController arrangedObjects] containsObject:objectToRemove] message:@"removed objects should no longer appear in arrangedObjects"];
}

- (void)testSelectionWhenObjectsDisappear
{
    // If the selected object disappears during a rearrange, the selection
    // should update appropriately, even if preserve selection is off.
    var arrayController = [self arrayController];
    [arrayController setPreservesSelection:NO];

    // Use a copy to make sure our original remains pristine.
    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 3)]];

    var newContent = [[self contentArray] copy];
    [newContent removeObjectAtIndex:2];

    [arrayController setContent:newContent];

    [self assert:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 2)] equals:[arrayController selectionIndexes] message:@"last object cannot be selected"];
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

- (void)testCompoundKeyPaths
{
    var departmentNameField = [[CPTextField alloc] init];
    [departmentNameField bind:@"value" toObject:[self arrayController] withKeyPath:@"selection.department.name" options:nil];

    // This should be 'No Selection'
    [self assert:@"" equals:[departmentNameField stringValue]];

    [[self arrayController] setSelectionIndexes:[CPIndexSet indexSetWithIndex:1]];
    [self assert:@"Cappuccino" equals:[departmentNameField stringValue]];

    [[self arrayController] setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 2)]];
    [self assert:@"Cappuccino" equals:[departmentNameField stringValue] message:@"key path values should be equal"];

    [[self arrayController] setValue:@"280North" forKeyPath:@"selection.department.name"];
    [self assert:@"280North" equals:[departmentNameField stringValue]];

    [[self arrayController] setSelectionIndexes:[CPIndexSet indexSetWithIndex:1]];

    [[self arrayController] valueForKeyPath:@"selection.department.name"];
    [[self arrayController] valueForKeyPath:@"selection.department.building"];
    [[self arrayController] valueForKeyPath:@"selection.department"];

    var employee = [[[self arrayController] selectedObjects] lastObject],
        department = [Department departmentWithName:@"Meh"];

    [department setBuilding:@"Building 1"];
    [employee setDepartment:department];

    [self assert:@"Meh" equals:[departmentNameField stringValue]];
    [self assert:department equals:[[self arrayController] valueForKeyPath:@"selection.department"]];
    [self assert:@"Building 1" equals:[[self arrayController] valueForKeyPath:@"selection.department.building"]];
}

- (void)testArrangedObjectsNotEmptyAfterSetContentWhenClearsFilterOnInsertionIsTrue
{
    var arrayController = [[CPArrayController alloc] init];
    [arrayController setFilterPredicate:nil];
    [arrayController setClearsFilterPredicateOnInsertion:YES];
    [arrayController setContent:[CPArray arrayWithObject:@"a"]];

    [self assertTrue:[[arrayController arrangedObjects] count] > 0];
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

/*!
    The code below makes the key "itemsArray" KVC compliant so that it can be used for testing
    array controllers bound to destinations with such setups.
*/
- (unsigned int)countOfItemsArray
{
    return [_contentArray count];
}

- (id)objectInItemsArrayAtIndex:(unsigned int)index
{
    return [_contentArray objectAtIndex:index];
}

- (void)insertObject:(id)anObject inItemsArrayAtIndex:(unsigned int)index
{
    [_contentArray insertObject:anObject atIndex:index];
}

- (void)removeObjectFromItemsArrayAtIndex:(unsigned int)index
{
    [_contentArray removeObjectAtIndex:index];
}

- (void)replaceObjectInItemsArrayAtIndex:(unsigned int)index withObject:(id)anObject
{
    [_contentArray replaceObjectAtIndex:index withObject:anObject];
}

@end

@implementation Employee : CPObject
{
    CPString            _name @accessors(property=name);
    Department          _department @accessors(property=department);
}

+ (id)employeeWithName:(CPString)theName department:(Department)theDepartment
{
    return [[self alloc] initWithName:theName department:theDepartment];
}

- (id)initWithName:(CPString)theName department:(Department)theDepartment
{
    if (self = [super init])
    {
        _name = theName;
        _department = theDepartment;
    }

    return self;
}

- (CPString)description
{
    return [CPString stringWithFormat:@"<Employee %@>", [self name]];
}

@end

@implementation Department : CPObject
{
    CPString                    _name @accessors(property=name);
    CPString                    _building @accessors(property=building);
}

+ (id)departmentWithName:(CPString)theName
{
    return [[self alloc] initWithName:theName];
}

- (id)initWithName:(CPString)theName
{
    if (self = [super init])
    {
        _name = theName;
    }

    return self;
}

@end