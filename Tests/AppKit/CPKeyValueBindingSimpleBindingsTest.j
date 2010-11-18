
@import <AppKit/CPKeyValueBinding.j>

/*!
    Bindings tests exercising the functionality seen in the Cocoa example "SimpleBindingsAdoption".
*/
@implementation CPKeyValueBindingSimpleBindingsTest : OJTestCase
{
    CPTextField textField;
    CPSlider    slider;
    CPButton    button;

    Track       track @accessors;
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

    [self verifyVolume:0.7 method:"actions"];

    [slider setFloatValue:9.0];
    [slider simulateAction];

    [self verifyVolume:9 method:"actions"];

    [button performClick:self];

    [self verifyVolume:0 method:"actions"];
}

/*!
    Using bindings and an object controller.
*/
- (void)testSimpleBindings02
{
    var controller = [CPObjectController new];
    [controller bind:@"contentObject" toObject:self withKeyPath:@"track" options:nil];

    [textField bind:@"value" toObject:controller withKeyPath:@"selection.volume" options:nil];
    [slider bind:@"value" toObject:controller withKeyPath:@"selection.volume" options:nil];

    [button setTarget:self];
    [button setAction:@selector(muteTrack02:)];

    // Test the interaction.
    [textField setStringValue:@"0.7"];
    // Simulate user interaction. By default bindings update on action only.
    [textField simulateAction];

    [self verifyVolume:0.7 method:"bindings"];

    [slider setFloatValue:9.0];
    [slider simulateAction];

    [self verifyVolume:9 method:"bindings"];

    [button performClick:self];

    [self verifyVolume:0 method:"bindings"];
}

- (void)verifyVolume:(float)aVolume method:(CPString)aMethod
{
    [self assert:aVolume equals:[track volume] message:"volume should update through " + aMethod];
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

#pragma mark ----- actions used by implementation 02 -----

- (void)muteTrack02:(id)sender
{
    [track setVolume:0.0];

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
        // The Cocoa version does not need this explicit conversion but we do,
        // because otherwise bindings will turn this into a string when reading
        // from the text field. A side effect of loose typing.
        volume = parseFloat(aValue);
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