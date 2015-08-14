/*
 * AppController.j
 * CPVisualEffectViewTest
 *
 * Created by You on August 13, 2015.
 * Copyright 2015, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@implementation AppController : CPObject
{
    @outlet CPWindow window;

    @outlet CPVisualEffectView FXView1;
    @outlet CPVisualEffectView FXView2;
    @outlet CPVisualEffectView FXView3;
    @outlet CPVisualEffectView FXView4;
    @outlet CPVisualEffectView FXView5;
    @outlet CPVisualEffectView FXView6;

    @outlet CPTextField field1;
    @outlet CPTextField field2;
    @outlet CPTextField field3;
    @outlet CPTextField field4;
    @outlet CPTextField field5;
    @outlet CPTextField field6;

    @outlet CPButton button1;
    @outlet CPButton button2;
    @outlet CPButton button3;
    @outlet CPButton button4;
    @outlet CPButton button5;
    @outlet CPButton button6;

}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
}

- (void)awakeFromCib
{
    var fields = [field1, field2, field3, field4, field5, field6];

    for (var i = [fields count] - 1; i >= 0; i--)
        [fields[i] setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateAppearanceVibrantDark];

    var buttons = [button1, button2, button3, button4, button5, button6];

    for (var i = [buttons count] - 1; i >= 0; i--)
    {
        [buttons[i] setValue:[CPColor colorWithHexString:@"f3f3f3"] forThemeAttribute:@"bezel-color" inState:CPThemeStateAppearanceVibrantLight];
        [buttons[i] setValue:[CPColor colorWithHexString:@"333333"] forThemeAttribute:@"text-color" inState:CPThemeStateAppearanceVibrantLight];
        [buttons[i] setValue:[CPColor clearColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateAppearanceVibrantLight];

        [buttons[i] setValue:[CPColor colorWithHexString:@"333333"] forThemeAttribute:@"bezel-color" inState:CPThemeStateAppearanceVibrantDark];
        [buttons[i] setValue:[CPColor colorWithHexString:@"999"] forThemeAttribute:@"text-color" inState:CPThemeStateAppearanceVibrantDark];
        [buttons[i] setValue:[CPColor clearColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateAppearanceVibrantDark];
    }
}

- (IBAction)switch:(id)aSender
{
    var dark = [CPAppearance appearanceNamed:CPAppearanceNameVibrantDark],
        light = [CPAppearance appearanceNamed:CPAppearanceNameVibrantLight],
        appearance = ([[aSender effectiveAppearance] isEqual:dark]) ? light : dark;

    [[aSender superview] setAppearance:appearance];
}

@end
