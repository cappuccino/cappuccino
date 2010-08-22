@implementation CPArrayControllerTest : OJTestCase
{
    CPArrayController                           _arrayController @accessors(property=arrayController);
    CPArray                                     _contentArray @accessors(property=contentArray);
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
    [self assert:[_CPObservableArray class] equals:[[[self arrayController] arrangedObjects] class]];
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

@end

@implementation Person : CPObject
{
    CPString                    _name @accessors(property=name);
    int                         _age @accessors(property=age);
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
    return [CPString stringWithFormat:@"%@ : %@", [self name], [self age]];
}

@end