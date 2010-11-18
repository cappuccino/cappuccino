
@import <AppKit/CPKeyValueBinding.j>

/*!
    Bindings tests exercising the functionality seen in the Cocoa example "SimpleBindingsAdoption".
*/
@implementation CPKeyValueBindingSimpleBindingsTest : OJTestCase
{
    CPTextField textField;
    CPSlider    slider;
    CPButton    button;

    Track       track;
}

- (void)setUp
{
    // CPApp must be initialised or action sending will not work.
    [CPApplication sharedApplication];

    textField = [CPTextField textFieldWithStringValue:@"" placeholder:@"" width:100];
    slider = [[CPSlider alloc] initWithFrame:CGRectMakeZero()];
    button = [CPButton buttonWithTitle:@"Mute"];

    track = [Track new];
    [track setVolume:5.0];
}

/*!
    Base case without bindings.
*/
- (void)testSimpleBindings01
{
    [textField setTarget:self];
    [textField setAction:@selector(updateVolumeFrom:)];

    [slider setTarget:self];
    [slider setAction:@selector(updateVolumeFrom:)];

    [button setTarget:self];
    [button setAction:@selector(muteTrack:)];

    // Test the interaction.
    [textField setStringValue:@"0.7"];
    // Simulate user interaction to fire action.
    [textField simulateAction];

    [self assert:0.7 equals:[track volume] message:"volume should update through actions"];
    [self assert:[track volume] equals:[textField floatValue]];
    [self assert:[track volume] equals:[slider floatValue]];

    [slider setFloatValue:9.0];
    [slider simulateAction];

    [self assert:9 equals:[track volume] message:"volume should update through actions"];
    [self assert:[track volume] equals:[textField floatValue]];
    [self assert:[track volume] equals:[slider floatValue]];

    [button performClick:self];

    [self assert:0 equals:[track volume] message:"volume should update through actions"];
    [self assert:[track volume] equals:[textField floatValue]];
    [self assert:[track volume] equals:[slider floatValue]];
}

#pragma mark ----- actions used by implementation 01 -----

- (void)updateVolumeFrom:(id)sender
{
	newVolume = [sender floatValue];
	[track setVolume:newVolume];
	[self updateUserInterface];
}

- (void)updateUserInterface
{
	[slider setFloatValue:[track volume]];
	[textField setFloatValue:[track volume]];
}

- (void)muteTrack:(id)sender
{
	[track setVolume:0.0];
	[self updateUserInterface];
}

@end

@implementation Track : CPObject
{
	float       volume @accessors;
	CPString    title @accessors;
}

- (void)setVolume:(float)aValue
{
    if (volume != aValue)
	{
        volume = aValue;
    }
}

- (void)setTitle:(CPString)newTitle
{
    if (title != newTitle)
	{
	    title = [newTitle copy];
    }
}

@end

@implementation CPControl (Simulation)

- (void)simulateAction
{
    [self sendAction:[self action] to:[self target]];
}

@end