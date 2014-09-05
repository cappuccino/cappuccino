
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
    id                  FOO;

    CPArrayController   arrayController @accessors;
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

    [bindTesterB bind:@"stringValue" toObject:bindTesterA withKeyPath:@"stringValue" options:@{}];
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

    [bindTesterA setStringValue:[CPNull null]];
    [self assert:[CPNull null] equals:[bindTesterA stringValue] message:"A value reset (placeholder)"];
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
        tableColumn = [[CPTableColumn alloc] initWithIdentifier:"A Column"];

    arrayController = [CPArrayController new];

    [tableView addTableColumn:tableColumn];

    var content = [
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
    [tableColumn _prepareDataView:testView forRow:0];
    [self assert:'1' equals:testView.lastValue];
    [self assert:'objectValue' equals:testView.lastKey];

    [tableColumn _prepareDataView:testView forRow:1];
    [self assert:'3' equals:testView.lastValue];
    [self assert:'objectValue' equals:testView.lastKey];

    // Test that CPTableColumn is optimized to only read one value per row.
    [self assert:0 equals:[content[2] accesses] message:"row 2 used " + [content[2] accesses] + " accesses but was never prepared"];
    [self assert:1 equals:[content[0] accesses] message:"row 0 used " + [content[0] accesses] + " accesses to prepare"];
    [self assert:1 equals:[content[1] accesses] message:"row 1 used " + [content[1] accesses] + " accesses to prepare"];

    // Try the case where a key path is not used.
    content = ["plain", "old", "space crystals"];
    [tableColumn bind:@"value" toObject:arrayController withKeyPath:@"arrangedObjects" options:nil];
    [arrayController setContent:content];

    [tableColumn _prepareDataView:testView forRow:1];
    [self assert:'old' equals:testView.lastValue];
    [self assert:'objectValue' equals:testView.lastKey];
}

- (void)testTableColumnAutomaticBindings
{
    var tableView = [CPTableView new],
        tableColumn = [[CPTableColumn alloc] initWithIdentifier:"A Column"];
    arrayController = [CPArrayController new];

    [tableView addTableColumn:tableColumn];

    [tableColumn bind:@"value" toObject:arrayController withKeyPath:@"arrangedObjects.valueA" options:nil];

    [self assertTrue:[[tableView infoForBinding:"content"] valueForKey:CPObservedObjectKey] === arrayController message:"when a column of a table is bound to an array controller a 'content' binding should automatically be made to the array controller"];
    [self assertTrue:[[tableView infoForBinding:"selectionIndexes"] valueForKey:CPObservedObjectKey] === arrayController message:"when a column of a table is bound to an array controller a 'selectionIndexes' binding should automatically be made to the array controller"];

    // This should also work if the AC is referenced through a compound path.
    tableView = [CPTableView new];
    tableColumn = [[CPTableColumn alloc] initWithIdentifier:"A Column"];
    [tableView addTableColumn:tableColumn];

    [tableColumn bind:@"value" toObject:self withKeyPath:@"arrayController.arrangedObjects.valueA" options:nil];

    [self assertTrue:[[tableView infoForBinding:"content"] valueForKey:CPObservedObjectKey] === arrayController message:"automatic 'content' binding should work even with compound keypath for column binding"];
    [self assertTrue:[[tableView infoForBinding:"selectionIndexes"] valueForKey:CPObservedObjectKey] === arrayController message:"automatic 'selectionIndexes' binding should work even with compound keypath for column binding"];
}

- (void)testTextField
{
    var textField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    [textField setPlaceholderString:@"cheese"];

    // Establish a random binding.
    [textField bind:@"hidden" toObject:self withKeyPath:@"FOO" options:nil];
    [self assert:@"cheese" equals:[textField placeholderString] message:"placeholder should not be cleared when a binding is established"];

    var content = [
        [BindingTester testerWithCheese:@"yellow"],
        [BindingTester testerWithCheese:@"green"],
    ];
    arrayController = [[CPArrayController alloc] initWithContent:content];

    [arrayController setSelectionIndex:0];

    var options = [CPDictionary dictionaryWithObject:@"Multiple Values" forKey:CPMultipleValuesPlaceholderBindingOption];
    [textField bind:@"value" toObject:arrayController withKeyPath:@"selection.cheese" options:options];

    [self assert:@"yellow" equals:[textField stringValue] message:@"text field string value should be 'yellow'"];

    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 2)]];

    [self assert:@"" equals:[textField stringValue] message:@"text field string value should be cleared"];
    [self assert:@"Multiple Values" equals:[textField placeholderString] message:@"text field placeholder should be 'Multiple Values'"];

    [textField unbind:@"value"];
    // Cocoa doesn't do this
    // [self assert:@"cheese" equals:[textField placeholderString] message:@"text field placeholder should be reset"];

    [textField bind:@"value" toObject:arrayController withKeyPath:@"selection.cheese" options:options];

    [arrayController setSelectionIndex:0];
    [self assert:@"yellow" equals:[textField stringValue] message:"text field string value should be 'yellow'"];

    // Cocoa doesn't do this
    // [self assert:@"cheese" equals:[textField placeholderString] message:"text field placeholder should be restored"];

    textField = [[CPTextField alloc] init];
    [textField bind:@"value" toObject:arrayController withKeyPath:@"selection.cheese" options:options];
    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 2)]];
    [self assert:@"Multiple Values" equals:[textField placeholderString] message:@"text field placeholder should 'Multiple Values'"];

    // Cocoa doesn't do this
    // [arrayController setSelectionIndex:0];
    // [self assert:@"" equals:[textField placeholderString] message:@"empty text field placeholder should be restored"];

}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)aContext
{
    CPLog(@"here: " + aKeyPath + " value: " + [anObject valueForKey:aKeyPath]);
}

- (void)testSuppressNotification
{
    var control = [[CPTextField alloc] init],
        anotherControl = [[CPTextField alloc] init];
    [control setStringValue:@"brown"];
    [control bind:CPValueBinding toObject:self withKeyPath:@"FOO" options:nil];
    [self setValue:@"green" forKeyPath:@"FOO"];
    [self assert:@"green" equals:[control stringValue] message:@"normal binding action"];

    var binding = [CPBinder getBinding:CPValueBinding forObject:control];
    [binding suppressSpecificNotificationFromObject:self keyPath:@"FOO"];
    [self setValue:@"orange" forKeyPath:@"FOO"];
    [self assert:@"green" equals:[control stringValue] message:@"binding update suppressed"];

    [binding unsuppressSpecificNotificationFromObject:anotherControl keyPath:@"FOO"];
    [self setValue:@"blue" forKeyPath:@"FOO"];
    [self assert:@"green" equals:[control stringValue] message:@"binding update still suppressed"];

    [binding unsuppressSpecificNotificationFromObject:self keyPath:@"FOO"];
    [self setValue:@"octarine" forKeyPath:@"FOO"];
    [self assert:@"octarine" equals:[control stringValue] message:@"binding update no longer suppressed"];
}

- (void)testReverseSetValueForDoesNotSetObjectValueOnSource
{
    var control = [[TextField alloc] init];
    [control setStringValue:@"brown"];

    var oc = [[CPObjectController alloc] initWithContent:[CPDictionary dictionaryWithObject:@"toto" forKey:@"foo"]];
    [oc setAutomaticallyPreparesContent:YES];

    [control bind:CPValueBinding toObject:oc withKeyPath:@"selection.foo" options:nil];

    [control setObjectValueSetterCount:0];
    // This will force a binding update -reverseSetValueFor:
    [control sendAction:nil to:nil];

    [self assert:0 equals:[control objectValueSetterCount] message:@"-setObjectValue should not be called"];
}

- (void)testMultipleBindingsToArrayControllerSelection
{
    var control1 = [[TextField alloc] init],
        control2 = [[TextField alloc] init],

        cheese1 = [BindingTester testerWithCheese:@"roblochon"],
        cheese2 = [BindingTester testerWithCheese:@"brie"],

        ac = [[CPArrayController alloc] initWithContent:@[cheese1, cheese2]],
        oc = [[CPObjectController alloc] init];

    // This tests fails only if multiple controls are bound BEFORE the object controller
    [control1 bind:CPValueBinding toObject:oc withKeyPath:@"selection.cheese" options:nil];
    [control2 bind:CPValueBinding toObject:oc withKeyPath:@"selection.cheese" options:nil];
    [oc bind:CPContentBinding toObject:ac withKeyPath:@"selection" options:nil];

    [ac setSelectionIndex:0];

    [self assert:@"roblochon" equals:[control1 objectValue] message:@"control1 objectValue is wrong"];
    [self assert:@"roblochon" equals:[control2 objectValue] message:@"control2 objectValue is wrong"];

    [ac setSelectionIndex:1];

    [self assert:@"brie" equals:[control1 objectValue] message:@"control1 objectValue is wrong"];
    [self assert:@"brie" equals:[control2 objectValue] message:@"control2 objectValue is wrong"];
}

@end

@implementation TextField : CPTextField
{
    CPInteger objectValueSetterCount @accessors;
}

- (void)setObjectValue:(id)aValue
{
    objectValueSetterCount++;
    [super setObjectValue:aValue];
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

- (void)setValue:(id)value forKey:(CPString)aKey
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
