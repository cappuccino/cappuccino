
@import <AppKit/AppKit.j>

/*!
    Bindings tests exercising the functionality seen in the Cocoa example "SimpleBindingsAdoption".
*/
@implementation CPKeyValueBindingSimpleBindingsTest : OJTestCase
{
    CPTextField         textField @accessors;
    CPSlider            slider @accessors;
    CPButton            button @accessors;

    Track               track @accessors;

    CPWindow            theWindow @accessors;
    CPObjectController  objectController @accessors;
}

- (void)setUp
{
    // CPApp must be initialised or action sending will not work.
    [CPApplication sharedApplication];

    track = [Track new];
    [track setVolume:5.0];
}

- (void)createControls
{
    textField = [CPTextField textFieldWithStringValue:@"" placeholder:@"" width:100];
    slider = [[CPSlider alloc] initWithFrame:CGRectMakeZero()];
    button = [CPButton buttonWithTitle:@"Mute"];
}

/*!
    Base case without bindings.
*/
- (void)testSimpleBindings01
{
    [self createControls];

    [textField setTarget:self];
    [textField setAction:@selector(updateVolumeFrom:)];

    [slider setTarget:self];
    [slider setAction:@selector(updateVolumeFrom:)];

    [button setTarget:self];
    [button setAction:@selector(muteTrack01:)];

    // Test the interaction.
    [textField setStringValue:@"0.7"];
    // Simulate user interaction to fire action.
    [textField performClick:self];

    [self verifyVolume:0.7 method:"actions"];

    [slider setFloatValue:9.0];
    [slider performClick:self];

    [self verifyVolume:9 method:"actions"];

    [button performClick:self];

    [self verifyVolume:0 method:"actions"];
}

/*!
    Using bindings and an object controller.
*/
- (void)testSimpleBindings02
{
    [self createControls];

    objectController = [CPObjectController new];
    [objectController bind:@"contentObject" toObject:self withKeyPath:@"track" options:nil];

    [textField bind:@"value" toObject:objectController withKeyPath:@"selection.volume" options:nil];
    [slider bind:@"value" toObject:objectController withKeyPath:@"selection.volume" options:nil];

    [button setTarget:self];
    [button setAction:@selector(muteTrack:)];

    // Test the interaction.
    [textField setStringValue:@"0.7"];
    // Simulate user interaction. By default bindings update on action only.
    [textField performClick:self];

    [self verifyVolume:0.7 method:"bindings"];

    [slider setFloatValue:9.0];
    [slider performClick:self];

    [self verifyVolume:9 method:"bindings"];

    [button performClick:self];

    [self verifyVolume:0 method:"bindings"];
}

/*!
    Using bindings and a controller set up in a cib (e.g. using Interface Builder).
*/
- (void)testSimpleBindings03
{
    // Note: this cib will connect 'objectController'. This is only for debugging purposes,
    // this code should run with or without that connection.
    var cib = [CPBundle loadCibFile:[[CPBundle bundleForClass:CPKeyValueBindingSimpleBindingsTest] pathForResource:"SimpleBindingsAdoption_03.cib"] externalNameTable:@{ CPCibOwner: self }];

    // Test the interaction.
    [textField setStringValue:@"0.7"];
    // Simulate user interaction. By default bindings update on action only.
    [textField performClick:self];

    [self verifyVolume:0.7 method:"bindings"];

    [slider setFloatValue:9.0];
    [slider performClick:self];

    [self verifyVolume:9 method:"bindings"];

    [button performClick:self];

    [self verifyVolume:0 method:"bindings"];

    // Test if CPNullPlaceholderBindingOption is correctly decoded
    var bindingInfo = [textField infoForBinding:@"value"],
        nullPlaceHolder = [[bindingInfo objectForKey:CPOptionsKey] objectForKey:CPNullPlaceholderBindingOption];
    [self assert:@"Nothing" equals:nullPlaceHolder];
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
    var newVolume = [sender floatValue];
    [track setVolume:newVolume];
    [self updateUserInterface];
}

- (void)updateUserInterface
{
    [slider setFloatValue:[track volume]];
    [textField setFloatValue:[track volume]];
}

- (void)muteTrack01:(id)sender
{
    [track setVolume:0.0];
    [self updateUserInterface];
}

#pragma mark ----- actions used by implementation 02 and 03 -----

- (void)muteTrack:(id)sender
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
