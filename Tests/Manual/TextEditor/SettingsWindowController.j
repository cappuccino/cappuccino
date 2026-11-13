/*
 * SettingsWindowController.j
 * TextEditor
 *
 * Copyright (c) 2026 David Richardson
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

@import <AppKit/AppKit.j>

/*
    The Settings window chooses the application's appearance: Light, Dark or Auto, which
    follows the system. Each choice is a radio button with an image above it, a thumbnail of
    a window in that appearance. The three radio buttons share one superview, one target and
    one action, so AppKit makes them one radio group: choosing one turns the others off. A
    click on a thumbnail clicks its radio button.

    The choice is kept in the user defaults under SettingsAppearanceKey, as the index of the
    radio button, and applied at launch by +applySavedAppearance.
*/
var SettingsAppearanceKey   = @"TextEditorAppearance",
    SettingsAppearanceNames = [CPAppearanceNameAqua, CPAppearanceNameDarkAqua, nil],
    SettingsChoiceTitles    = [@"Light", @"Dark", @"Auto"],
    SettingsChoiceImages    = [@"AppearanceLight.svg", @"AppearanceDark.svg", @"AppearanceAuto.svg"],
    SettingsAutoChoice      = 2,
    SettingsChoiceWidth     = 90.0,
    SettingsImageSize       = CGSizeMake(64.0, 44.0);

@implementation SettingsWindowController : CPWindowController
{
    CPArray     _radios;
}

/*
    Applies the appearance kept in the user defaults. Without one, the application follows
    the system appearance. AppController calls this at launch, before any window shows.
*/
+ (void)applySavedAppearance
{
    [self _applyAppearanceOfChoice:[self _savedChoice]];
}

+ (int)_savedChoice
{
    var choice = [[CPUserDefaults standardUserDefaults] objectForKey:SettingsAppearanceKey];

    return choice == nil ? SettingsAutoChoice : choice;
}

/*
    Light and Dark set the application's appearance. Auto sets none, so the application
    takes the system appearance and follows it when it changes.
*/
+ (void)_applyAppearanceOfChoice:(int)aChoice
{
    var name = SettingsAppearanceNames[aChoice];

    [CPApp setAppearance:name ? [CPAppearance appearanceNamed:name] : nil];
}

- (id)init
{
    var width = 20.0 * 2 + SettingsChoiceWidth * SettingsChoiceTitles.length,
        panel = [[CPPanel alloc] initWithContentRect:CGRectMake(0.0, 0.0, width, 120.0) styleMask:CPTitledWindowMask | CPClosableWindowMask];

    if (self = [super initWithWindow:panel])
    {
        [panel setTitle:@"Settings"];

        var contentView = [panel contentView],
            savedChoice = [[self class] _savedChoice];

        _radios = [];

        for (var i = 0; i < SettingsChoiceTitles.length; i++)
        {
            var x = 20.0 + i * SettingsChoiceWidth,
                thumbnail = [[CPButton alloc] initWithFrame:CGRectMake(x + (SettingsChoiceWidth - SettingsImageSize.width) / 2, 16.0, SettingsImageSize.width, SettingsImageSize.height)],
                radio = [CPRadio radioWithTitle:SettingsChoiceTitles[i]];

            /*
                The thumbnail is a borderless button of its own, so another image needs no
                change of layout. An image on the radio button itself would take the place of
                its circle. Its tag names its radio button.
            */
            [thumbnail setBordered:NO];
            [thumbnail setImagePosition:CPImageOnly];
            [thumbnail setImageScaling:CPImageScaleProportionallyUpOrDown];
            [thumbnail setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:SettingsChoiceImages[i]] size:SettingsImageSize]];
            [thumbnail setTag:i];
            [thumbnail setTarget:self];
            [thumbnail setAction:@selector(thumbnailWasClicked:)];
            [contentView addSubview:thumbnail];

            [radio sizeToFit];
            [radio setFrameOrigin:CGPointMake(x + (SettingsChoiceWidth - CGRectGetWidth([radio frame])) / 2, 70.0)];
            [radio setTag:i];
            [radio setTarget:self];
            [radio setAction:@selector(appearanceDidChange:)];
            [radio setState:i === savedChoice ? CPOnState : CPOffState];
            [contentView addSubview:radio];

            _radios.push(radio);
        }

        [panel center];
    }

    return self;
}

/*
    The action of every thumbnail. Clicking the radio button of the same tag turns it on,
    turns the others off and sends the radio button's action.
*/
- (void)thumbnailWasClicked:(id)aSender
{
    [_radios[[aSender tag]] performClick:aSender];
}

/*
    The action of every radio button. The sender's tag is the index of the choice.
*/
- (void)appearanceDidChange:(id)aSender
{
    var choice = [aSender tag];

    [[CPUserDefaults standardUserDefaults] setObject:choice forKey:SettingsAppearanceKey];
    [[self class] _applyAppearanceOfChoice:choice];
}

@end
