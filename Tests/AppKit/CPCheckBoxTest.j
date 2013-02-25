@import <AppKit/CPCheckBox.j>

[CPApplication sharedApplication]

@implementation CPCheckBoxTest : OJTestCase
{
}

/*!
    Verify that CPCheckBox placeholders work, both explicit and default ones.
*/
- (void)testPlaceholders
{
    var control = [[CPCheckBox alloc] initWithFrame:CGRectMakeZero()];
    [control setAllowsMixedState:YES];

    var content =
        [
            CPOffState,
            CPOnState
        ],
        arrayController = [[CPArrayController alloc] initWithContent:content];

    // First test defaults.
    [control bind:CPValueBinding toObject:arrayController withKeyPath:@"selection.self" options:nil];

    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 2)]];
    [self assert:CPMixedState equals:[control objectValue] message:"default CPMultipleValuesPlaceholderBindingOption placeholder should be 'mixed'"];

    [arrayController setSelectionIndexes:[CPIndexSet indexSet]];
    [self assert:CPOffState equals:[control objectValue] message:"default CPNoSelectionMarker placeholder should be 'off'"];

    // There seems to be no obvious way to trigger a CPNullMarker here. Setting an index outside of the allowed range
    // results in a no selection marker. In Cocoa, adding a [CPNull null] to the content array just results in it being
    // converted (oddly) to CPOnState when in mixed state and an exception when not. The placeholder doesn't play in.
    //[arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndex:2]];
    //[self assert:CPOffState equals:[control objectValue] message:"default CPNullMarker placeholder should be 'off'"];

    // And just to verify things are making sense.
    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndex:0]];
    [self assert:CPOffState equals:[control objectValue] message:"content 0 is off"];
    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndex:1]];
    [self assert:CPOnState equals:[control objectValue] message:"content 1 is on"];

    [control unbind:CPValueBinding];

    // Set up a new binding with explicit placeholders, different from the default ones.
    var options = @{
            CPMultipleValuesPlaceholderBindingOption: CPOffState,
            CPNoSelectionPlaceholderBindingOption: CPOnState,
            CPNotApplicablePlaceholderBindingOption: CPOnState,
            CPNullPlaceholderBindingOption: CPMixedState,
        };

    [control bind:CPValueBinding toObject:arrayController withKeyPath:@"selection.self" options:options];

    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, 2)]];
    [self assert:CPOffState equals:[control objectValue] message:"explicit CPMultipleValuesPlaceholderBindingOption placeholder should be 'off'"];

    [arrayController setSelectionIndexes:[CPIndexSet indexSet]];
    [self assert:CPOnState equals:[control objectValue] message:"explicit CPNoSelectionMarker placeholder should be 'on'"];

    // See note above on how a CPNullPlaceholder is never really triggered for a checkbox.
    //[arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndex:2]];
    //[self assert:CPMixedState equals:[control objectValue] message:"explicit CPNullMarker placeholder should be 'mixed'"];

    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndex:0]];
    [self assert:CPOffState equals:[control objectValue] message:"content 0 is off"];
    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndex:1]];
    [self assert:CPOnState equals:[control objectValue] message:"content 1 is on"];
}

- (void)testTransformValueBinding
{
    var control = [[CPCheckBox alloc] initWithFrame:CGRectMakeZero()];

    var content =
        [
            @{ @"state": YES },
            @{ @"state": NO }
        ],
        arrayController = [[CPArrayController alloc] initWithContent:content];

    // First test defaults.
    [control bind:CPValueBinding toObject:arrayController withKeyPath:@"selection.state" options:@{ CPValueTransformerNameBindingOption: @"CPNegateBoolean" }];

    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndex:0]];
    [self assert:CPOffState equals:[control objectValue] message:"content[0] is negated"]
    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndex:1]];
    [self assert:CPOnState equals:[control objectValue] message:"content[1] is negated"]

    [control performClick:nil];
    [self assert:CPOffState equals:[control objectValue] message:"value was changed"]
    [self assert:YES equals:[content[1] valueForKey:@"state"] message:"content[1] was negated after change"]
}

@end

