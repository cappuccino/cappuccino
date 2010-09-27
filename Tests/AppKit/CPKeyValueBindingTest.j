
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

    [self assertTrue:[self valueForKey:@"FOO"] === "banana" message:"Bound value should have been updated to banana, was " + FOO];
}

- (void)testBindOptions
{

    var bindTesterA = [BindingTestWithBool new],
        bindTesterB = [BindingTestWithBool new];

    [bindTesterB bind:@"stringValue" toObject:bindTesterA withKeyPath:@"stringValue" options:[CPDictionary dictionary]];
    [self assert:nil equals:[bindTesterA stringValue] message:"initial A value unchanged"];
    [self assert:nil equals:[bindTesterB stringValue] message:"initial B value unchanged"];

    [bindTesterA setStringValue:@"My string"];
    [self assert:@"My string" equals:[bindTesterA stringValue] message:"A value set"];
    [self assert:@"My string" equals:[bindTesterB stringValue] message:"B value updated"];

    [bindTesterA setStringValue:nil];
    [self assert:nil equals:[bindTesterA stringValue] message:"A value reset"];
    [self assert:nil equals:[bindTesterB stringValue] message:"B value updated with nil"];

    [bindTesterA unbind:@"stringValue"];

    [bindTesterB bind:@"boolValue" toObject:bindTesterA withKeyPath:@"stringValue" options:[CPDictionary dictionaryWithObject:CPIsNotNilTransformerName forKey:CPValueTransformerNameBindingOption]];
    [bindTesterB setBoolValue:YES];
    [bindTesterA setStringValue:nil];
    [self assert:nil equals:[bindTesterA stringValue] message:"A value reset"];
    [self assert:NO equals:[bindTesterB boolValue] message:"B value updated"];

    [bindTesterB setBoolValue:NO];
    [bindTesterA setStringValue:@"My string"];
    [self assert:@"My string" equals:[bindTesterA stringValue] message:"A value updated"];
    [self assert:YES equals:[bindTesterB boolValue] message:"B value updated"];

    [bindTesterB setBoolValue:NO];
    [bindTesterA setStringValue:@""];
    [self assert:@"" equals:[bindTesterA stringValue] message:"A value updated"];
    [self assert:YES equals:[bindTesterB boolValue] message:"B value updated"];

    [bindTesterA unbind:@"boolValue"];

    [bindTesterB bind:@"boolValue" toObject:bindTesterA withKeyPath:@"stringValue" options:[CPDictionary dictionaryWithObject:CPIsNilTransformerName forKey:CPValueTransformerNameBindingOption]];
    [bindTesterB setBoolValue:NO];
    [bindTesterA setStringValue:nil];
    [self assert:nil equals:[bindTesterA stringValue] message:"A value reset"];
    [self assert:YES equals:[bindTesterB boolValue] message:"B value updated"];

    [bindTesterB setBoolValue:YES];
    [bindTesterA setStringValue:@"My string"];
    [self assert:@"My string" equals:[bindTesterA stringValue] message:"A value updated"];
    [self assert:NO equals:[bindTesterB boolValue] message:"B value updated"];

    [bindTesterB setBoolValue:YES];
    [bindTesterA setStringValue:@""];
    [self assert:@"" equals:[bindTesterA stringValue] message:"A value updated"];
    [self assert:NO equals:[bindTesterB boolValue] message:"B value updated"];

    [bindTesterA unbind:@"boolValue"];


    [bindTesterB bind:@"stringValue" toObject:bindTesterA withKeyPath:@"stringValue" options:[CPDictionary dictionaryWithObject:@"placeholder" forKey:CPNullPlaceholderBindingOption]];

    [bindTesterA setStringValue:@""];
    [self assert:@"" equals:[bindTesterA stringValue] message:"A value set (placeholder)"];
    [self assert:@"" equals:[bindTesterB stringValue] message:"B value updated (placeholder)"];

    [bindTesterA setStringValue:@"My string"];
    [self assert:@"My string" equals:[bindTesterA stringValue] message:"A value set (placeholder)"];
    [self assert:@"My string" equals:[bindTesterB stringValue] message:"B value updated (placeholder)"];

    [bindTesterA setStringValue:nil];
    [self assert:nil equals:[bindTesterA stringValue] message:"A value reset (placeholder)"];
    [self assert:@"placeholder" equals:[bindTesterB stringValue] message:"B value updated (placeholder)"];
}

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
    // Should this even work? It's a two way binding. Anyhow, it currently crashes
    // objj disrupting the other unit tests, so commenting it out for now.
    //[self bind:@"FOO" toObject:control withKeyPath:CPValueBinding options:nil];

    [control setStringValue:@"banana"];
    [control setStringValue:@"grapefruit"];

    [self setValue:@"BAR" forKey:@"FOO"];

    [self assert:FOO equals:[control stringValue]];

    [control setStringValue:@"pina colada"];

    //[self assert:FOO equals:[control stringValue]];
}

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
    for (var i = 0; i < [content count]; i++)
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

- (void)testTextField
{
    var textField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    [textField setPlaceholderString:@"cheese"];


    content = [
        [BindingTester testerWithCheese:@"yellow"],
        [BindingTester testerWithCheese:@"green"]
    ];
    arrayController = [[CPArrayController alloc] initWithContent:content];

    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 2)]];

    var options = [CPDictionary dictionaryWithJSObject:{CPMultipleValuesPlaceholderBindingOption:@"Multiple Values"}];
    [textField bind:@"value" toObject:arrayController withKeyPath:@"selection.cheese" options:options];

    [self assert:@"Multiple Values" equals:[textField placeholderString]];

    [arrayController setSelectionIndex:0];
    [self assert:@"cheese" equals:[textField placeholderString]];
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

+ (id)testerWithCheese:(id)aCheese
{
    var tester = [[self alloc] init];
    [tester setCheese:aCheese];
    return tester;
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

@implementation BindingTestWithBool : CPObject
{
    CPString    stringValue @accessors;
    BOOL        boolValue @accessors;
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

+ (AccessCounter)counterWithValueA:aValue valueB:anotherValue
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
