
@import <AppKit/CPKeyValueBinding.j>
@import <AppKit/CPTextField.j>

// FIXME These imports are needed to prevent the following two errors:
// error=ReferenceError: Can't find variable: CPTopVerticalTextAlignment
// error=ReferenceError: Can't find variable: CPImageLeft
// CPControl uses these but in ojtest runs the dependencies don't
// get imported for some reason.
@import <AppKit/CPButton.j>
@import <AppKit/_CPImageAndTextView.j>

@import <AppKit/CPClipView.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPArrayController.j>

@implementation CPKeyValueBindingTest : OJTestCase
{
    id      FOO;
}

- (void)testExposingBindings
{
    [BindingTester exposeBinding:@"foo"];
    [BindingTester exposeBinding:@"bar"];
    [CPObject exposeBinding:@"zoo"];

    [self assert:["foo", "bar", "zoo"] equals:[[BindingTester new] exposedBindings]];
}

- (void)testBindTo
{
    var binder = [BindingTester new];
    binder.cheese = "orange";

    [CPKeyValueBindingTest exposeBinding:@"FOO"];

    [self bind:"FOO" toObject:binder withKeyPath:"cheese" options:nil];

    [binder setCheese:@"banana"];

    [self assertTrue:[self valueForKey:@"FOO"]==="banana" message:"Bound value should have been updated to banana, was "+FOO];
}
/*
- (void)testControl
{
    FOO = "bingo";

    var binder = [BindingTester new];
    binder.cheese = "yellow";

    var control = [[CPTextField alloc] init];
    [control setStringValue:@"brown"];

    [CPControl exposeBinding:CPValueBinding];
    [[self class] exposeBinding:@"FOO"];

    //[control addObserver:self forKeyPath:CPValueBinding options:nil context:"testControl"];

    [control bind:CPValueBinding toObject:self withKeyPath:@"FOO" options:nil];
    [self bind:@"FOO" toObject:control withKeyPath:CPValueBinding options:nil];

    [control setStringValue:@"banana"];
    [control setStringValue:@"grapefruit"];

    [self setValue:@"BAR" forKey:@"FOO"];

    [self assertTrue: FOO == [control stringValue] message: "should be equal, were: "+FOO+"and: "+[control stringValue]];

    [control setStringValue:@"pina colada"];

    [self assertTrue: FOO == [control stringValue] message: "should be equal, were: "+FOO+"and: "+[control stringValue]];
}*/

- (void)testTableColumn
{
    var tableView = [CPTableView new],
        tableColumn = [[CPTableColumn alloc] initWithIdentifier:"A Column"],
        arrayController = [CPArrayController new];

    [tableView addTableColumn:tableColumn];

    content = [
        [AccessCounter counterWithValueA:"1" valueB:"2"],
        [AccessCounter counterWithValueA:"3" valueB:"4"],
        [AccessCounter counterWithValueA:"5" valueB:"6"],
    ];
    [arrayController setContent:content];

    [tableColumn bind:@"value" toObject:arrayController withKeyPath:@"arrangedObjects.valueA" options:nil];

    // Reset these if they were read during initialization.
    for(var i=0; i<[content count];i++)
        [content[i] setAccesses:0];
    var testView = [DataViewTester new];
    [tableColumn prepareDataView:testView forRow:0];
    [self assert:'1' equals:testView.lastValue];
    [self assert:'value' equals:testView.lastKey];

    [tableColumn prepareDataView:testView forRow:1];
    [self assert:'3' equals:testView.lastValue];
    [self assert:'value' equals:testView.lastKey];

    // Test that CPTableColumn is optimized to only read one value per row.
    [self assert:0 equals:[content[2] accesses] message:"row 2 used "+[content[2] accesses]+" accesses but was never prepared"];
    [self assert:1 equals:[content[0] accesses] message:"row 0 used "+[content[0] accesses]+" accesses to prepare"];
    [self assert:1 equals:[content[1] accesses] message:"row 1 used "+[content[1] accesses]+" accesses to prepare"];

    // Try the case where a key path is not used.
    content = ["plain", "old", "space crystals"];
    [tableColumn bind:@"value" toObject:arrayController withKeyPath:@"arrangedObjects" options:nil];
    [arrayController setContent:content];

    [tableColumn prepareDataView:testView forRow:1];
    [self assert:'old' equals:testView.lastValue];
    [self assert:'value' equals:testView.lastKey];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)aContext
{
    CPLog(@"here: "+aKeyPath+" value: "+[anObject valueForKey:aKeyPath]);
}

@end

@implementation BindingTester : CPObject
{
    id cheese;
}

- (void)setCheese:(id)aCheese
{
    cheese = aCheese;
}

- (id)cheese
{
    return cheese;
}

@end

@implementation DataViewTester : CPObject
{
    id lastValue;
    id lastKey;
}

- (void)setValue:value forKey:aKey
{
    lastValue = value;
    lastKey = aKey;
}
@end

@implementation AccessCounter : CPObject
{
    id          valueA @accessors;
    id          valueB @accessors;
    CPNumber    accesses @accessors;
}

+ (AccessCounter) counterWithValueA:aValue valueB:anotherValue
{
    r = [self new];
    [r setValueA:aValue];
    [r setValueB:anotherValue];
    return r;
}

- (id)valueA
{
    accesses++;
    return valueA;
}

- (id)valueB
{
    accesses++;
    return valueB;
}

@end
