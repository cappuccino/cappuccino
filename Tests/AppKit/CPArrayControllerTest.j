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

    _arrayController = [[CPArrayController alloc] initWithContent:[self contentArray]];
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
// - (void)testSelectNext
// {
//     var arrayController = [self arrayController],
//         arrangedObjects = [arrayController arrangedObjects],
//         startIndex = 0,
//         selectionIndexes = [CPIndexSet indexSetWithIndex:startIndex];
// 
//     [arrayController setSelectionIndexes:selectionIndexes];
//     [arrayController selectNext:self];
// 
//     [selectionIndexes shiftIndexesStartingAtIndex:startIndex by:1]
//     [self assert:selectionIndexes equals:[arrayController selectionIndexes]];
// 
//     // Test that the selection wraps around
//     startIndex = [arrangedObjects count] - 1;
//     selectionIndexes = [CPIndexSet indexSetWithIndex:startIndex];
// 
//     [arrayController setSelectionIndexes:selectionIndexes];
//     [arrayController selectNext:self];
// 
//     [self assert:[CPIndexSet indexSetWithIndex:0] equals:[arrayController selectionIndexes]];
// }

- (void)testContentBinding
{
    [[self arrayController] bind:@"contentArray" toObject:self withKeyPath:@"contentArray" options:0];

    [self assert:[[self arrayController] contentArray] equals:[self contentArray]];
    
    [[self mutableArrayValueForKey:@"contentArray"] addObject:@"4"];
    [self assert:[self contentArray] equals:[[self arrayController] contentArray]];

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