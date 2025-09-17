/*
 * AppController.j
 * CPButtonImageTest
 *
 * Created by Aparajita Fishman on August 31, 2010.
 */

@import <Foundation/CPObject.j>

CPLogRegister(CPLogConsole);


@implementation AppController : CPObject
{
    CPWindow                theWindow;

    @outlet CPButton        button;
    @outlet CPButton        imageButton;
    @outlet CPButton        imageDisabledButton;
    @outlet CPButton        pushInButton;
    @outlet CPButton        pushOnOffButton;
    @outlet CPButton        toggleButton;
    @outlet CPButton        momentaryChangeButton;
    @outlet CPCheckBox      checkbox;
    @outlet CPCheckBox      multiCheckbox;
    @outlet CPRadio         radio1;
    @outlet CPRadio         radio2;
    @outlet CPPopUpButton   positionMenu;
    @outlet CPButton        monkeyButton;
    @outlet CPCheckBox      monkeyCheckbox;

    @outlet CPTextField     clickCount;
    @outlet CPTextField     monkeyLabel;
    @outlet CPTextField     monkeyCheckboxLabel;

    CPArray buttons;
    CPArray checksAndRadios;
}

- (void)awakeFromCib
{
    [imageButton setImage:[[CPTheme defaultTheme] valueForAttributeWithName:@"button-image-action" forClass:[CPButtonBar class]]];
    [imageDisabledButton setImage:[[CPTheme defaultTheme] valueForAttributeWithName:@"button-image-action" forClass:[CPButtonBar class]]];

    [self _setImagePosition:CPImageLeft];
    [positionMenu selectItemAtIndex:CPImageLeft];
    [self _setupButtons];
}

- (void)_setupButtons
{
    buttons = [button, imageButton, imageDisabledButton];
    checksAndRadios = [checkbox, multiCheckbox, radio1, radio2];

    var checkboxHeight = [checkbox frameSize].height,
        radioHeight = [radio1 frameSize].height;

    [buttons makeObjectsPerformSelector:@selector(sizeToFit)];
    [checksAndRadios makeObjectsPerformSelector:@selector(sizeToFit)];

    [checkbox setFrameSize:CGSizeMake([checkbox frameSize].width, checkboxHeight)];
    [multiCheckbox setFrameSize:CGSizeMake([multiCheckbox frameSize].width, checkboxHeight)];

    [radio1 setFrameSize:CGSizeMake([radio1 frameSize].width, radioHeight)];
    [radio2 setFrameSize:CGSizeMake([radio2 frameSize].width, radioHeight)];

    [[radio1 radioGroup] setTarget:self];
    [[radio1 radioGroup] setAction:@selector(radioGroupClicked:)];
    [multiCheckbox setState:CPMixedState];

    [pushInButton setAlternateTitle:@"Should Not See Me"];
    [toggleButton setAlternateTitle:@"Alternate Title For Toggle"];
    [momentaryChangeButton setAlternateTitle:@"Changed!"];

    [monkeyButton setAlternateTitle:@"Alternate title"];
    var path = [[CPBundle bundleForClass:[CPView class]] pathForResource:@"action_button.png"];
    [monkeyButton setAlternateImage:[[CPImage alloc] initWithContentsOfFile:path size:CGSizeMake(22.0, 14.0)]]
    [monkeyButton setHighlightsBy:CPNoCellMask];
    [monkeyButton setShowsStateBy:CPNoCellMask];

    [monkeyCheckbox setAlternateTitle:@"Alternate title"];
    [monkeyCheckbox setHighlightsBy:CPNoCellMask];
    [monkeyCheckbox setShowsStateBy:CPNoCellMask];

    CPLog(@"%@", [monkeyButton alternateTitle]);
}

- (void)setImagePosition:(id)sender
{
    [self _setImagePosition:[sender indexOfSelectedItem]];
}

- (void)_setImagePosition:(unsigned)position
{
    [buttons makeObjectsPerformSelector:@selector(setImagePosition:) withObject:position];
    [checksAndRadios makeObjectsPerformSelector:@selector(setImagePosition:) withObject:position];

    var alignment;

    switch (position)
    {
        case CPImageOnly:
            return;

        case CPNoImage:
        case CPImageAbove:
        case CPImageBelow:
        case CPImageOverlaps:
            alignment = CPCenterTextAlignment;
            break;

        case CPImageLeft:
            alignment = CPLeftTextAlignment;
            break;

        case CPImageRight:
            alignment = CPRightTextAlignment;
            break;
    }

    [checksAndRadios makeObjectsPerformSelector:@selector(setAlignment:) withObject:alignment];
}

- (IBAction)countClick:(id)sender
{
    var previousCount = [clickCount integerValue];
    [clickCount setIntegerValue:(previousCount + 1)];
}

- (IBAction)switchSelectedRadio:(id)aSender
{
    if ([radio2 state] == CPOffState)
        [radio2 setState:CPOnState];
    else
        [radio1 setState:CPOnState];
}

- (IBAction)radioGroupClicked:(id)aSender
{
    CPLog.info("Radio group action sent!");
}

- (IBAction)setMonkeyButtonHighlightedBy:(id)aSender
{
    if ([aSender state] == CPOnState)
    {
        [monkeyButton setHighlightsBy:[monkeyButton highlightsBy] | [aSender tag]];
        [monkeyCheckbox setHighlightsBy:[monkeyCheckbox highlightsBy] | [aSender tag]];
    }
    else
    {
        [monkeyButton setHighlightsBy:[monkeyButton highlightsBy] ^ [aSender tag]];
        [monkeyCheckbox setHighlightsBy:[monkeyCheckbox highlightsBy] ^ [aSender tag]];
    }
}

- (IBAction)setMonkeyButtonShowsStateBy:(id)aSender
{
    if ([aSender state] == CPOnState)
    {
        [monkeyButton setShowsStateBy:[monkeyButton showsStateBy] | [aSender tag]];
        [monkeyCheckbox setShowsStateBy:[monkeyCheckbox showsStateBy] | [aSender tag]];
    }
    else
    {
        [monkeyButton setShowsStateBy:[monkeyButton showsStateBy] ^ [aSender tag]];
        [monkeyCheckbox setShowsStateBy:[monkeyCheckbox showsStateBy] ^ [aSender tag]];
    }
}

- (IBAction)monkeyClick:(id)aSender
{
    [monkeyLabel setStringValue:[CPString stringWithFormat:@"State: %d", [monkeyButton state]]];
    [monkeyCheckboxLabel setStringValue:[CPString stringWithFormat:@"State: %d", [monkeyCheckbox state]]];
}

@end

@implementation BezelView : CPView

- (void)drawRect:(CGRect)dirtyRect
{
    var sides = [CPMinYEdge, CPMaxYEdge, CPMinXEdge, CPMaxXEdge],
        grays = [0.75, 1.0, 0.75, 1.0];

    CPDrawTiledRects(dirtyRect, dirtyRect, sides, grays);
}

@end
