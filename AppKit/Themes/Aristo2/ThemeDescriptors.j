/*
 * ThemeDescriptors.j
 * null
 *
 * Created by You on December 12, 2012
 * Copyright 2012, Your Company. All rights reserved.
 */

@import <BlendKit/BKThemeDescriptor.j>

var themedButtonValues = nil,
    themedTextFieldValues = nil,
    themedVerticalScrollerValues = nil,
    themedHorizontalScrollerValues = nil,
    themedSegmentedControlValues = nil,
    themedHorizontalSliderValues = nil,
    themedVerticalSliderValues = nil,
    themedCircularSliderValues = nil,
    themedButtonBarValues = nil,
    themedAlertValues = nil,
    themedWindowViewValues = nil;

@implementation Aristo2ThemeDescriptor : BKThemeDescriptor

+ (CPString)themeName
{
    return @"Aristo2";
}

+ (CPButton)makeButton
{
    return [[CPButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 25)];
}

+ (CPButton)button
{
    var button = [self makeButton],

        // RoundRect
        bezelColor = PatternColor(
            [
                ["button-bezel-left.png", 4.0, 25.0],
                ["button-bezel-center.png", 1.0, 25.0],
                ["button-bezel-right.png", 4.0, 25.0]
            ],
            PatternIsHorizontal),

        highlightedBezelColor = PatternColor(
            [
                ["button-bezel-highlighted-left.png", 4.0, 25.0],
                ["button-bezel-highlighted-center.png", 1.0, 25.0],
                ["button-bezel-highlighted-right.png", 4.0, 25.0]
            ],
            PatternIsHorizontal),

        disabledBezelColor = PatternColor(
            [
                ["button-bezel-disabled-left.png", 4.0, 25.0],
                ["button-bezel-disabled-center.png", 1.0, 25.0],
                ["button-bezel-disabled-right.png", 4.0, 25.0]
            ],
            PatternIsHorizontal),

        defaultBezelColor = PatternColor(
            [
                ["default-button-bezel-left.png", 4.0, 25.0],
                ["default-button-bezel-center.png", 1.0, 25.0],
                ["default-button-bezel-right.png", 4.0, 25.0]
            ],
            PatternIsHorizontal),

        defaultHighlightedBezelColor = PatternColor(
            [
                ["default-button-bezel-highlighted-left.png", 4.0, 25.0],
                ["default-button-bezel-highlighted-center.png", 1.0, 25.0],
                ["default-button-bezel-highlighted-right.png", 4.0, 25.0]
            ],
            PatternIsHorizontal),

        defaultDisabledBezelColor = PatternColor(
            [
                ["default-button-bezel-disabled-left.png", 4.0, 25.0],
                ["default-button-bezel-disabled-center.png", 1.0, 25.0],
                ["default-button-bezel-disabled-right.png", 4.0, 25.0]
            ],
            PatternIsHorizontal),

            // Rounded
            roundedBezelColor = PatternColor(
                [
                    ["button-bezel-rounded-left.png", 12.0, 25.0],
                    ["button-bezel-rounded-center.png", 1.0, 25.0],
                    ["button-bezel-rounded-right.png", 12.0, 25.0]
                ],
                PatternIsHorizontal),

            roundedHighlightedBezelColor = PatternColor(
                [
                    ["button-bezel-rounded-highlighted-left.png", 12.0, 25.0],
                    ["button-bezel-rounded-highlighted-center.png", 1.0, 25.0],
                    ["button-bezel-rounded-highlighted-right.png", 12.0, 25.0]
                ],
                PatternIsHorizontal),

            roundedDisabledBezelColor = PatternColor(
                [
                    ["button-bezel-rounded-disabled-left.png", 12.0, 25.0],
                    ["button-bezel-rounded-disabled-center.png", 1.0, 25.0],
                    ["button-bezel-rounded-disabled-right.png", 12.0, 25.0]
                ],
                PatternIsHorizontal),

            defaultRoundedBezelColor = PatternColor(
                [
                    ["default-button-bezel-rounded-left.png", 12.0, 25.0],
                    ["default-button-bezel-rounded-center.png", 1.0, 25.0],
                    ["default-button-bezel-rounded-right.png", 12.0, 25.0]
                ],
                PatternIsHorizontal),

            defaultRoundedHighlightedBezelColor = PatternColor(
                [
                    ["default-button-bezel-rounded-highlighted-left.png", 12.0, 25.0],
                    ["default-button-bezel-rounded-highlighted-center.png", 1.0, 25.0],
                    ["default-button-bezel-rounded-highlighted-right.png", 12.0, 25.0]
                ],
                PatternIsHorizontal),

            defaultRoundedDisabledBezelColor = PatternColor(
                [
                    ["default-button-bezel-rounded-disabled-left.png", 12.0, 25.0],
                    ["default-button-bezel-rounded-disabled-center.png", 1.0, 25.0],
                    ["default-button-bezel-rounded-disabled-right.png", 12.0, 25.0]
                ],
                PatternIsHorizontal),

        defaultTextColor = [CPColor colorWithCalibratedRed:38.0 / 255.0 green:38.0 / 255.0 blue:38.0 / 255.0 alpha:1.0],
        defaultDisabledTextColor = [CPColor colorWithCalibratedRed:38.0 / 255.0 green:38.0 / 255.0 blue:38.0 / 255.0 alpha:0.2];

    themedButtonValues =
        [
            [@"font",               [CPFont boldSystemFontOfSize:12.0], CPThemeStateBordered],
            [@"text-color",         [CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0]],
            [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:1.0 alpha:0.3], CPThemeStateBordered],
            [@"text-color",         [CPColor whiteColor], CPThemeStateBordered | CPThemeStateDefault],
            [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:0.0 alpha:0.2], CPThemeStateBordered | CPThemeStateDefault],
            [@"text-shadow-offset", CGSizeMake(0.0, 1.0), CPThemeStateBordered],
            [@"line-break-mode",    CPLineBreakByTruncatingTail],
            [@"bezel-color",        bezelColor,                     CPThemeStateBordered],
            [@"bezel-color",        highlightedBezelColor,          CPThemeStateBordered | CPThemeStateHighlighted],
            [@"bezel-color",        disabledBezelColor,             CPThemeStateBordered | CPThemeStateDisabled],
            [@"bezel-color",        defaultBezelColor,              CPThemeStateBordered | CPThemeStateDefault],
            [@"bezel-color",        defaultHighlightedBezelColor,   CPThemeStateBordered | CPThemeStateHighlighted | CPThemeStateDefault],
            [@"bezel-color",        defaultDisabledBezelColor,      CPThemeStateBordered | CPThemeStateDefault | CPThemeStateDisabled],
            [@"content-inset",      CGInsetMake(0.0, 7.0, 0.0, 7.0), CPThemeStateBordered],

            [@"bezel-color",        roundedBezelColor,                      CPThemeStateBordered | CPButtonStateBezelStyleRounded],
            [@"bezel-color",        roundedHighlightedBezelColor,           CPThemeStateBordered | CPThemeStateHighlighted | CPButtonStateBezelStyleRounded],
            [@"bezel-color",        roundedDisabledBezelColor,              CPThemeStateBordered | CPThemeStateDisabled | CPButtonStateBezelStyleRounded],
            [@"bezel-color",        defaultRoundedBezelColor,               CPThemeStateBordered | CPThemeStateDefault | CPButtonStateBezelStyleRounded],
            [@"bezel-color",        defaultRoundedHighlightedBezelColor,    CPThemeStateBordered | CPThemeStateHighlighted | CPThemeStateDefault | CPButtonStateBezelStyleRounded],
            [@"bezel-color",        defaultRoundedDisabledBezelColor,       CPThemeStateBordered | CPThemeStateDefault | CPThemeStateDisabled | CPButtonStateBezelStyleRounded],
            [@"content-inset",      CGInsetMake(0.0, 10.0, 0.0, 10.0),      CPThemeStateBordered | CPButtonStateBezelStyleRounded],

            [@"text-color",         [CPColor colorWithCalibratedWhite:0.6 alpha:1.0],   CPThemeStateDisabled],

            [@"text-color",         defaultTextColor,               CPThemeStateDefault],
            [@"text-color",         defaultDisabledTextColor,       CPThemeStateDefault | CPThemeStateDisabled],

            [@"min-size",           CGSizeMake(0.0, CPButtonDefaultHeight)],
            [@"max-size",           CGSizeMake(-1.0, CPButtonDefaultHeight)],

            [@"image-offset",       CPButtonImageOffset]
        ];

    [self registerThemeValues:themedButtonValues forView:button];

    return button;
}

+ (CPButton)themedStandardButton
{
    var button = [self button];

    [button setTitle:@"Cancel"];

    return button;
}

+ (CPButton)themedDefaultButton
{
    var button = [self button];

    [button setTitle:@"OK"];
    [button setThemeState:CPThemeStateDefault];

    return button;
}

+ (CPButton)themedRoundedButton
{
    var button = [self button];

    [button setTitle:@"Save"];
    [button setThemeState:CPButtonStateBezelStyleRounded];

    return button;
}

+ (CPButton)themedDefaultRoundedButton
{
    var button = [self button];

    [button setTitle:@"OK"];
    [button setThemeState:CPButtonStateBezelStyleRounded | CPThemeStateDefault];

    return button;
}

+ (CPPopUpButton)themedPopUpButton
{
    var button = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 25.0) pullsDown:NO],
        color = PatternColor(
            [
                ["popup-bezel-left.png", 3.0, 25.0],
                ["popup-bezel-center.png", 1.0, 25.0],
                ["popup-bezel-right.png", 24.0, 25.0]
            ],
            PatternIsHorizontal),

        disabledColor = PatternColor(
            [
                ["popup-bezel-disabled-left.png", 3.0, 25.0],
                ["popup-bezel-disabled-center.png", 1.0, 25.0],
                ["popup-bezel-disabled-right.png", 24.0, 25.0]
            ],
            PatternIsHorizontal),

        themeValues =
        [
            [@"bezel-color",        color,          CPThemeStateBordered],
            [@"bezel-color",        disabledColor,  CPThemeStateBordered | CPThemeStateDisabled],

            [@"content-inset",      CGInsetMake(0, 21.0 + 5.0, 0, 5.0), CPThemeStateBordered],
            [@"font",               [CPFont boldSystemFontOfSize:12.0]],
            [@"text-color",         [CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0]],
            [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0]],

            [@"text-color",         [CPColor colorWithCalibratedWhite:0.6 alpha:1.0],           CPThemeStateBordered | CPThemeStateDisabled],
            [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:0.6], CPThemeStateBordered | CPThemeStateDisabled],

            [@"min-size",           CGSizeMake(32.0, 25.0)],
            [@"max-size",           CGSizeMake(-1.0, 25.0)]
        ];

    [self registerThemeValues:themeValues forView:button];

    [button setTitle:@"Pop Up"];
    [button addItemWithTitle:@"item"];

    return button;
}

+ (CPPopUpButton)themedPullDownMenu
{
    var button = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 25.0) pullsDown:YES],
        color = PatternColor(
            [
                ["popup-bezel-left.png", 3.0, 25.0],
                ["popup-bezel-center.png", 1.0, 25.0],
                ["popup-bezel-right-pullsdown.png", 24.0, 25.0]
            ],
            PatternIsHorizontal),

        disabledColor = PatternColor(
            [
                ["popup-bezel-disabled-left.png", 3.0, 25.0],
                ["popup-bezel-disabled-center.png", 1.0, 25.0],
                ["popup-bezel-disabled-right-pullsdown.png", 24.0, 25.0]
            ],
            PatternIsHorizontal),

        themeValues =
        [
            [@"bezel-color",        color,          CPPopUpButtonStatePullsDown | CPThemeStateBordered],
            [@"bezel-color",        disabledColor,  CPPopUpButtonStatePullsDown | CPThemeStateBordered | CPThemeStateDisabled],

            [@"content-inset",      CGInsetMake(0, 27.0 + 5.0, 0, 5.0), CPThemeStateBordered],
            [@"font",               [CPFont boldSystemFontOfSize:12.0]],
            [@"text-color",         [CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0]],
            [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0]],

            [@"text-color",         [CPColor colorWithCalibratedWhite:0.6 alpha:1.0],           CPThemeStateBordered | CPThemeStateDisabled],
            [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:0.6], CPThemeStateBordered | CPThemeStateDisabled],

            [@"min-size",           CGSizeMake(32.0, 25.0)],
            [@"max-size",           CGSizeMake(-1.0, 25.0)]
        ];

    [self registerThemeValues:themeValues forView:button];

    [button setTitle:@"Pull Down"];
    [button addItemWithTitle:@"item"];

    return button;
}

+ (CPScrollView)themedScrollView
{
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)];

    var borderColor = [CPColor colorWithWhite:0.0 alpha:0.2],
        bottomCornerColor = PatternColor(@"scrollview-bottom-corner-color.png", 15.0, 15.0);

    var themedScrollViewValues =
        [
            [@"border-color", borderColor],
            [@"bottom-corner-color", bottomCornerColor]
        ];

    [self registerThemeValues:themedScrollViewValues forView:scrollView];

    [scrollView setAutohidesScrollers:YES];
    [scrollView setBorderType:CPLineBorder];

    return scrollView;
}



+ (CPScroller)makeHorizontalScroller
{
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 273.0, 15.0)];

    [scroller setFloatValue:0.1];
    [scroller setKnobProportion:0.5];

    [scroller setStyle:CPScrollerStyleLegacy];

    return scroller;
}

+ (CPScroller)makeVerticalScroller
{
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 15.0, 273.0)];

    [scroller setFloatValue:1];
    [scroller setKnobProportion:0.1];

    [scroller setStyle:CPScrollerStyleLegacy];

    return scroller;
}

+ (CPScroller)themedVerticalScroller
{
    var scroller = [self makeVerticalScroller],
        trackColor = PatternColor(
            [
                ["scroller-vertical-track-top.png", 9.0, 4.0],
                ["scroller-vertical-track-center.png", 9.0, 1.0],
                ["scroller-vertical-track-bottom.png", 9.0, 4.0]
            ],
            PatternIsVertical),

        trackColorLight = PatternColor(
            [
                ["scroller-vertical-track-light-top.png", 9.0, 4.0],
                ["scroller-vertical-track-light-center.png", 9.0, 1.0],
                ["scroller-vertical-track-light-bottom.png", 9.0, 4.0]
            ],
            PatternIsVertical),

        trackColorDark = PatternColor(
            [
                ["scroller-vertical-track-dark-top.png", 9.0, 4.0],
                ["scroller-vertical-track-dark-center.png", 9.0, 1.0],
                ["scroller-vertical-track-dark-bottom.png", 9.0, 4.0]
            ],
            PatternIsVertical),

        trackColorLegacy        = PatternColor("scroller-legacy-vertical-track-center.png", 14.0, 1.0),
        incrementColorLegacy    = PatternColor("scroller-legacy-vertical-track-bottom.png", 14.0, 11.0),
        decrementColorLegacy    = PatternColor("scroller-legacy-vertical-track-top.png", 14.0, 11.0),

        knobColor = PatternColor(
            [
                ["scroller-vertical-knob-top.png", 9.0, 4.0],
                ["scroller-vertical-knob-center.png", 9.0, 1.0],
                ["scroller-vertical-knob-bottom.png", 9.0, 4.0]
            ],
            PatternIsVertical),

        knobColorLight = PatternColor(
            [
                ["scroller-vertical-knob-light-top.png", 9.0, 4.0],
                ["scroller-vertical-knob-light-center.png", 9.0, 1.0],
                ["scroller-vertical-knob-light-bottom.png", 9.0, 4.0]
            ],
            PatternIsVertical),

        knobColorDark = PatternColor(
            [
                ["scroller-vertical-knob-dark-top.png", 9.0, 4.0],
                ["scroller-vertical-knob-dark-center.png", 9.0, 1.0],
                ["scroller-vertical-knob-dark-bottom.png", 9.0, 4.0]
            ],
            PatternIsVertical),

        knobColorLegacy = PatternColor(
            [
                ["scroller-legacy-vertical-knob-top.png", 14.0, 3.0],
                ["scroller-legacy-vertical-knob-center.png", 14.0, 1.0],
                ["scroller-legacy-vertical-knob-bottom.png", 14.0, 3.0]
            ],
            PatternIsVertical);


    themedVerticalScrollerValues =
        [
            // Common
            [@"minimum-knob-length",    21.0,                               CPThemeStateVertical],

            // Overlay
            [@"scroller-width",         9.0,                                CPThemeStateVertical],
            [@"knob-inset",             CGInsetMake(2.0, 0.0, 0.0, 0.0),    CPThemeStateVertical],
            [@"track-inset",            CGInsetMake(2.0, 0.0, 2.0, 0.0),   CPThemeStateVertical],
            [@"track-border-overlay",   12.0,                                CPThemeStateVertical],
            [@"knob-slot-color",        [CPNull null],                      CPThemeStateVertical],
            [@"knob-slot-color",        trackColor,                         CPThemeStateVertical | CPThemeStateSelected],
            [@"knob-slot-color",        trackColorLight,                    CPThemeStateVertical | CPThemeStateSelected | CPThemeStateScrollerKnobLight],
            [@"knob-slot-color",        trackColorDark,                     CPThemeStateVertical | CPThemeStateSelected | CPThemeStateScrollerKnobDark],
            [@"knob-color",             knobColor,                          CPThemeStateVertical],
            [@"knob-color",             knobColorLight,                     CPThemeStateVertical | CPThemeStateScrollerKnobLight],
            [@"knob-color",             knobColorDark,                      CPThemeStateVertical | CPThemeStateScrollerKnobDark],
            [@"increment-line-color",   [CPNull null],                      CPThemeStateVertical],
            [@"decrement-line-color",   [CPNull null],                      CPThemeStateVertical],
            [@"decrement-line-size",    CPSizeMakeZero(),                   CPThemeStateVertical],
            [@"increment-line-size",    CPSizeMakeZero(),                   CPThemeStateVertical],

            // Legacy
            [@"scroller-width",         14.0,                               CPThemeStateVertical | CPThemeStateScrollViewLegacy],
            [@"knob-inset",             CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateVertical | CPThemeStateScrollViewLegacy],
            [@"track-inset",            CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateVertical | CPThemeStateScrollViewLegacy],
            [@"track-border-overlay",   0.0,                                CPThemeStateVertical | CPThemeStateScrollViewLegacy],
            [@"knob-slot-color",        trackColorLegacy,                   CPThemeStateVertical | CPThemeStateScrollViewLegacy],
            [@"knob-slot-color",        trackColorLegacy,                   CPThemeStateVertical | CPThemeStateScrollViewLegacy | CPThemeStateSelected],
            [@"knob-slot-color",        trackColorLegacy,                   CPThemeStateVertical | CPThemeStateScrollViewLegacy | CPThemeStateSelected | CPThemeStateScrollerKnobLight],
            [@"knob-slot-color",        trackColorLegacy,                   CPThemeStateVertical | CPThemeStateScrollViewLegacy | CPThemeStateSelected | CPThemeStateScrollerKnobDark],
            [@"knob-slot-color",        trackColorLegacy,                   CPThemeStateVertical | CPThemeStateScrollViewLegacy | CPThemeStateScrollerKnobDark],
            [@"knob-slot-color",        trackColorLegacy,                   CPThemeStateVertical | CPThemeStateScrollViewLegacy | CPThemeStateScrollerKnobLight],
            [@"knob-color",             knobColorLegacy,                    CPThemeStateVertical | CPThemeStateScrollViewLegacy],
            [@"knob-color",             knobColorLegacy,                    CPThemeStateVertical | CPThemeStateScrollViewLegacy | CPThemeStateScrollerKnobLight],
            [@"knob-color",             knobColorLegacy,                    CPThemeStateVertical | CPThemeStateScrollViewLegacy | CPThemeStateScrollerKnobDark],
            [@"increment-line-color",   incrementColorLegacy,               CPThemeStateVertical | CPThemeStateScrollViewLegacy],
            [@"decrement-line-color",   decrementColorLegacy,               CPThemeStateVertical | CPThemeStateScrollViewLegacy],
            [@"decrement-line-size",    CPSizeMake(14.0, 11.0),             CPThemeStateVertical | CPThemeStateScrollViewLegacy],
            [@"increment-line-size",    CPSizeMake(14.0, 11.0),             CPThemeStateVertical | CPThemeStateScrollViewLegacy]
        ];

    [self registerThemeValues:themedVerticalScrollerValues forView:scroller];

    return scroller;
}


+ (CPScroller)themedHorizontalScroller
{
    var scroller = [self makeHorizontalScroller],
        trackColor = PatternColor(
            [
                ["scroller-horizontal-track-left.png", 4.0, 9.0],
                ["scroller-horizontal-track-center.png", 1.0, 9.0],
                ["scroller-horizontal-track-right.png", 4.0, 9.0]
            ],
            PatternIsHorizontal),

        trackColorLight = PatternColor(
            [
                ["scroller-horizontal-track-light-left.png", 4.0, 9.0],
                ["scroller-horizontal-track-light-center.png", 1.0, 9.0],
                ["scroller-horizontal-track-light-right.png", 4.0, 9.0]
            ],
            PatternIsHorizontal),

        trackColorDark = PatternColor(
            [
                ["scroller-horizontal-track-dark-left.png", 4.0, 9.0],
                ["scroller-horizontal-track-dark-center.png", 1.0, 9.0],
                ["scroller-horizontal-track-dark-right.png", 4.0, 9.0]
            ],
            PatternIsHorizontal),

        trackColorLegacy = PatternColor("scroller-legacy-horizontal-track-center.png", 1.0, 14.0),
        incrementColorLegacy = PatternColor("scroller-legacy-horizontal-track-right.png", 11.0, 14.0),
        decrementColorLegacy = PatternColor("scroller-legacy-horizontal-track-left.png", 11.0, 14.0),

        knobColor = PatternColor(
            [
                ["scroller-horizontal-knob-left.png", 4.0, 9.0],
                ["scroller-horizontal-knob-center.png", 1.0, 9.0],
                ["scroller-horizontal-knob-right.png", 4.0, 9.0]
            ],
            PatternIsHorizontal),

        knobColorLight = PatternColor(
            [
                ["scroller-horizontal-knob-light-left.png", 4.0, 9.0],
                ["scroller-horizontal-knob-light-center.png", 1.0, 9.0],
                ["scroller-horizontal-knob-light-right.png", 4.0, 9.0]
            ],
            PatternIsHorizontal),

        knobColorDark = PatternColor(
            [
                ["scroller-horizontal-knob-dark-left.png", 4.0, 9.0],
                ["scroller-horizontal-knob-dark-center.png", 1.0, 9.0],
                ["scroller-horizontal-knob-dark-right.png", 4.0, 9.0]
            ],
            PatternIsHorizontal),

        knobColorLegacy = PatternColor(
            [
                ["scroller-legacy-horizontal-knob-left.png", 3.0, 14.0],
                ["scroller-legacy-horizontal-knob-center.png", 1.0, 14.0],
                ["scroller-legacy-horizontal-knob-right.png", 3.0, 14.0]
            ],
            PatternIsHorizontal);

    themedHorizontalScrollerValues =
        [
            // Common
            [@"minimum-knob-length",    21.0],

            // Overlay
            [@"scroller-width",         9.0],
            [@"knob-inset",             CGInsetMake(0.0, 0.0, 0.0, 2.0)],
            [@"track-inset",            CGInsetMake(0.0, 2.0, 0.0, 2.0)],
            [@"track-border-overlay",   12.0],
            [@"knob-slot-color",        [CPNull null]],
            [@"knob-slot-color",        trackColor,                         CPThemeStateSelected],
            [@"knob-slot-color",        trackColorLight,                    CPThemeStateSelected | CPThemeStateScrollerKnobLight],
            [@"knob-slot-color",        trackColorDark,                     CPThemeStateSelected | CPThemeStateScrollerKnobDark],
            [@"knob-color",             knobColor],
            [@"knob-color",             knobColorLight,                     CPThemeStateScrollerKnobLight],
            [@"knob-color",             knobColorDark,                      CPThemeStateScrollerKnobDark],
            [@"decrement-line-size",    CPSizeMakeZero()],
            [@"increment-line-size",    CPSizeMakeZero()],

            // Legacy
            [@"scroller-width",         14.0,                               CPThemeStateScrollViewLegacy],
            [@"knob-inset",             CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateScrollViewLegacy],
            [@"track-inset",            CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateScrollViewLegacy],
            [@"track-border-overlay",   0.0,                                CPThemeStateScrollViewLegacy],
            [@"knob-slot-color",        trackColorLegacy,                   CPThemeStateScrollViewLegacy],
            [@"knob-slot-color",        trackColorLegacy,                   CPThemeStateScrollViewLegacy | CPThemeStateSelected],
            [@"knob-slot-color",        trackColorLegacy,                   CPThemeStateScrollViewLegacy | CPThemeStateScrollerKnobLight],
            [@"knob-slot-color",        trackColorLegacy,                   CPThemeStateScrollViewLegacy | CPThemeStateScrollerKnobDark],
            [@"knob-color",             knobColorLegacy,                    CPThemeStateScrollViewLegacy],
            [@"knob-color",             knobColorLegacy,                    CPThemeStateScrollViewLegacy | CPThemeStateScrollerKnobLight],
            [@"knob-color",             knobColorLegacy,                    CPThemeStateScrollViewLegacy | CPThemeStateScrollerKnobDark],
            [@"increment-line-color",   incrementColorLegacy,               CPThemeStateScrollViewLegacy],
            [@"decrement-line-color",   decrementColorLegacy,               CPThemeStateScrollViewLegacy],
            [@"decrement-line-size",    CPSizeMake(11.0, 14.0),             CPThemeStateScrollViewLegacy],
            [@"increment-line-size",    CPSizeMake(11.0, 14.0),             CPThemeStateScrollViewLegacy]
        ];

    [self registerThemeValues:themedHorizontalScrollerValues forView:scroller];

    return scroller;
}

+ (CPTextField)themedStandardTextField
{
    var textfield = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 29.0)],

        bezelColor = PatternColor(
            [
                ["textfield-bezel-square-0.png", 3.0, 4.0],
                ["textfield-bezel-square-1.png", 1.0, 4.0],
                ["textfield-bezel-square-2.png", 3.0, 4.0],
                ["textfield-bezel-square-3.png", 3.0, 1.0],
                ["textfield-bezel-square-4.png", 1.0, 1.0],
                ["textfield-bezel-square-5.png", 3.0, 1.0],
                ["textfield-bezel-square-6.png", 3.0, 4.0],
                ["textfield-bezel-square-7.png", 1.0, 4.0],
                ["textfield-bezel-square-8.png", 3.0, 4.0]
            ]),

        bezelFocusedColor = PatternColor(
            [
                ["textfield-bezel-square-focused-0.png", 7.0, 7.0],
                ["textfield-bezel-square-focused-1.png", 1.0, 7.0],
                ["textfield-bezel-square-focused-2.png", 7.0, 7.0],
                ["textfield-bezel-square-focused-3.png", 7.0, 1.0],
                ["textfield-bezel-square-focused-4.png", 1.0, 1.0],
                ["textfield-bezel-square-focused-5.png", 7.0, 1.0],
                ["textfield-bezel-square-focused-6.png", 7.0, 7.0],
                ["textfield-bezel-square-focused-7.png", 1.0, 7.0],
                ["textfield-bezel-square-focused-8.png", 7.0, 7.0]
            ]),

        bezelDisabledColor = PatternColor(
            [
                ["textfield-bezel-square-disabled-0.png", 3.0, 4.0],
                ["textfield-bezel-square-disabled-1.png", 1.0, 4.0],
                ["textfield-bezel-square-disabled-2.png", 3.0, 4.0],
                ["textfield-bezel-square-disabled-3.png", 3.0, 1.0],
                ["textfield-bezel-square-disabled-4.png", 1.0, 1.0],
                ["textfield-bezel-square-disabled-5.png", 3.0, 1.0],
                ["textfield-bezel-square-disabled-6.png", 3.0, 4.0],
                ["textfield-bezel-square-disabled-7.png", 1.0, 4.0],
                ["textfield-bezel-square-disabled-8.png", 3.0, 4.0]
            ]),

        placeholderColor = [CPColor colorWithCalibratedRed:189.0 / 255.0 green:199.0 / 255.0 blue:211.0 / 255.0 alpha:1.0];

    // Global for reuse by CPTokenField.
    themedTextFieldValues =
    [
        [@"vertical-alignment", CPTopVerticalTextAlignment,         CPThemeStateBezeled],
        [@"bezel-color",        bezelColor,                         CPThemeStateBezeled],
        [@"bezel-color",        bezelFocusedColor,                  CPThemeStateBezeled | CPThemeStateEditing],
        [@"bezel-color",        bezelDisabledColor,                 CPThemeStateBezeled | CPThemeStateDisabled],
        [@"font",               [CPFont systemFontOfSize:12.0],     CPThemeStateBezeled],

        [@"content-inset",      CGInsetMake(8.0, 7.0, 5.0, 8.0),    CPThemeStateBezeled],
        [@"content-inset",      CGInsetMake(8.0, 7.0, 5.0, 8.0),    CPThemeStateBezeled | CPThemeStateEditing],
        [@"bezel-inset",        CGInsetMake(3.0, 4.0, 3.0, 4.0),    CPThemeStateBezeled],
        [@"bezel-inset",        CGInsetMake(1.0, 1.0, 1.0, 1.0),    CPThemeStateBezeled | CPThemeStateEditing],

        [@"text-color",         placeholderColor,                   CPTextFieldStatePlaceholder],

        [@"line-break-mode",    CPLineBreakByTruncatingTail,        CPThemeStateTableDataView],
        [@"vertical-alignment", CPCenterVerticalTextAlignment,      CPThemeStateTableDataView],
        [@"content-inset",      CGInsetMake(0.0, 0.0, 0.0, 5.0),    CPThemeStateTableDataView],

        [@"text-color",         [CPColor colorWithCalibratedWhite:51.0 / 255.0 alpha:1.0], CPThemeStateTableDataView],
        [@"text-color",         [CPColor whiteColor],                CPThemeStateTableDataView | CPThemeStateSelectedTableDataView],
        [@"font",               [CPFont boldSystemFontOfSize:12.0],  CPThemeStateTableDataView | CPThemeStateSelectedTableDataView],
        [@"text-color",         [CPColor blackColor],                CPThemeStateTableDataView | CPThemeStateEditing],
        [@"content-inset",      CGInsetMake(7.0, 7.0, 5.0, 8.0),     CPThemeStateTableDataView | CPThemeStateEditing],
        [@"font",               [CPFont systemFontOfSize:12.0],      CPThemeStateTableDataView | CPThemeStateEditing],
        [@"bezel-inset",        CGInsetMake(-2.0, -2.0, -2.0, -2.0), CPThemeStateTableDataView | CPThemeStateEditing],

        [@"text-color",         [CPColor colorWithCalibratedWhite:125.0 / 255.0 alpha:1.0], CPThemeStateTableDataView | CPThemeStateGroupRow],
        [@"text-color",         [CPColor colorWithCalibratedWhite:1.0 alpha:1.0], CPThemeStateTableDataView | CPThemeStateGroupRow | CPThemeStateSelectedTableDataView],
        [@"text-shadow-color",  [CPColor whiteColor],                CPThemeStateTableDataView | CPThemeStateGroupRow],
        [@"text-shadow-offset",  CGSizeMake(0,1),                    CPThemeStateTableDataView | CPThemeStateGroupRow],
        [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:0.0 alpha:0.6],                CPThemeStateTableDataView | CPThemeStateGroupRow | CPThemeStateSelectedTableDataView],
        [@"font",               [CPFont boldSystemFontOfSize:12.0],  CPThemeStateTableDataView | CPThemeStateGroupRow]
    ];

    [self registerThemeValues:themedTextFieldValues forView:textfield];

    [textfield setBezeled:YES];

    [textfield setPlaceholderString:"placeholder"];
    [textfield setStringValue:""];
    [textfield setEditable:YES];

    return textfield;
}

+ (CPTextField)themedRoundedTextField
{
    var textfield = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 29.0)],
        bezelColor = PatternColor(
            [
                ["textfield-bezel-rounded-left.png", 8.0, 23.0],
                ["textfield-bezel-rounded-center.png", 1.0, 23.0],
                ["textfield-bezel-rounded-right.png", 8.0, 23.0]
            ],
            PatternIsHorizontal),

        bezelFocusedColor = PatternColor(
            [
                ["textfield-bezel-rounded-focused-left.png", 12.0, 29.0],
                ["textfield-bezel-rounded-focused-center.png", 1.0, 29.0],
                ["textfield-bezel-rounded-focused-right.png", 12.0, 29.0]
            ],
            PatternIsHorizontal),

        placeholderColor = [CPColor colorWithCalibratedRed:189.0 / 255.0 green:199.0 / 255.0 blue:211.0 / 255.0 alpha:1.0];

    // Global for reuse by CPSearchField
    themedRoundedTextFieldValues =
        [
            [@"bezel-color",    bezelColor,                         CPTextFieldStateRounded | CPThemeStateBezeled],
            [@"bezel-color",    bezelFocusedColor,                  CPTextFieldStateRounded | CPThemeStateBezeled | CPThemeStateEditing],
            [@"font",           [CPFont systemFontOfSize:12.0]],

            [@"content-inset",  CGInsetMake(8.0, 14.0, 6.0, 14.0),  CPTextFieldStateRounded | CPThemeStateBezeled],
            [@"content-inset",  CGInsetMake(8.0, 14.0, 6.0, 14.0),  CPTextFieldStateRounded | CPThemeStateBezeled | CPThemeStateEditing],

            [@"bezel-inset",    CGInsetMake(4.0, 4.0, 2.0, 4.0),    CPTextFieldStateRounded | CPThemeStateBezeled],
            [@"bezel-inset",    CGInsetMake(1.0, 1.0, 1.0, 1.0),    CPTextFieldStateRounded | CPThemeStateBezeled | CPThemeStateEditing],

            [@"text-color",     placeholderColor,       CPTextFieldStateRounded | CPTextFieldStatePlaceholder],

            [@"min-size",       CGSizeMake(0.0, 29.0),  CPTextFieldStateRounded | CPThemeStateBezeled],
            [@"max-size",       CGSizeMake(-1.0, 29.0), CPTextFieldStateRounded | CPThemeStateBezeled]
        ];

    [self registerThemeValues:themedRoundedTextFieldValues forView:textfield];

    [textfield setBezeled:YES];
    [textfield setBezelStyle:CPTextFieldRoundedBezel];

    [textfield setPlaceholderString:"placeholder"];
    [textfield setStringValue:""];
    [textfield setEditable:YES];

    return textfield;
}

+ (CPSearchField)themedSearchField
{
    var searchField = [[CPSearchField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 29.0)],

        imageSearch = PatternImage("search-field-search.png", 25.0, 22.0),
        imageFind = PatternImage("search-field-find.png", 25.0, 22.0),
        imageCancel = PatternImage("search-field-cancel.png", 22.0, 22.0),
        imageCancelPressed = PatternImage("search-field-cancel-pressed.png", 22.0, 22.0),

        overrides = [
            [@"image-search", imageSearch],
            [@"image-find", imageFind],
            [@"image-cancel", imageCancel],
            [@"image-cancel-pressed", imageCancelPressed]
        ];

    [self registerThemeValues:overrides forView:searchField inherit:themedRoundedTextFieldValues];

    return searchField;
}

+ (CPTokenField)themedTokenField
{
    var tokenfield = [[CPTokenField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 29.0)];

        overrides =
        [
            [@"bezel-inset", CGInsetMakeZero()],
            [@"bezel-inset", CGInsetMake(3.0, 4.0, 3.0, 4.0),    CPThemeStateBezeled],
            [@"bezel-inset", CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateBezeled | CPThemeStateEditing],

            [@"editor-inset", CGInsetMake(3.0, 0.0, 0.0, 0.0)],

            // Non-bezeled token field with tokens
            [@"content-inset", CGInsetMake(6.0, 8.0, 4.0, 8.0)],

            // Non-bezeled token field with no tokens
            [@"content-inset", CGInsetMake(7.0, 8.0, 6.0, 8.0), CPTextFieldStatePlaceholder],

            // Bezeled token field with tokens
            [@"content-inset", CGInsetMake(5.0, 8.0, 4.0, 8.0), CPThemeStateBezeled],

            // Bezeled token field with no tokens
            [@"content-inset", CGInsetMake(10.0, 8.0, 7.0, 8.0), CPThemeStateBezeled | CPTextFieldStatePlaceholder],
        ];

    [self registerThemeValues:overrides forView:tokenfield inherit:themedTextFieldValues];

    return tokenfield;
}

+ (_CPTokenFieldToken)themedTokenFieldToken
{
    var token = [[_CPTokenFieldToken alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 19.0)],

        bezelColor = PatternColor(
            [
                ["token-left.png", 11.0, 19.0],
                ["token-center.png", 1.0, 19.0],
                ["token-right.png", 11.0, 19.0]
            ],
            PatternIsHorizontal),

        bezelHighlightedColor = PatternColor(
            [
                ["token-highlighted-left.png", 11.0, 19.0],
                ["token-highlighted-center.png", 1.0, 19.0],
                ["token-highlighted-right.png", 11.0, 19.0]
            ],
            PatternIsHorizontal),

        textColor = [CPColor colorWithRed:41.0 / 255.0 green:51.0 / 255.0 blue:64.0 / 255.0 alpha:1.0],
        textHighlightedColor = [CPColor whiteColor],

        themeValues =
        [
            [@"bezel-color",    bezelColor,                         CPThemeStateBezeled],
            [@"bezel-color",    bezelHighlightedColor,              CPThemeStateBezeled | CPThemeStateHighlighted],

            [@"text-color",     textColor],
            [@"text-color",     textHighlightedColor,               CPThemeStateHighlighted],

            [@"bezel-inset",    CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateBezeled],
            [@"content-inset",  CGInsetMake(1.0, 24.0, 2.0, 16.0),  CPThemeStateBezeled],

            // Minimum height == maximum height since tokens are fixed height.
            [@"min-size",       CGSizeMake(0.0, 19.0)],
            [@"max-size",       CGSizeMake(-1.0, 19.0)],

            [@"vertical-alignment", CPCenterTextAlignment],
        ];

    [self registerThemeValues:themeValues forView:token];

    return token;
}

+ (_CPTokenFieldTokenCloseButton)themedTokenFieldTokenCloseButton
{
    var button = [[_CPTokenFieldTokenCloseButton alloc] initWithFrame:CGRectMake(0, 0, 9, 9)],

        bezelColor = PatternColor("token-close.png", 8.0, 8.0),
        bezelHighlightedColor = PatternColor("token-close-highlighted.png", 8.0, 8.0),

        themeValues =
        [
            [@"bezel-color",    bezelColor,                         CPThemeStateBordered],
            [@"bezel-color",    bezelHighlightedColor,              CPThemeStateBordered | CPThemeStateHighlighted],

            [@"min-size",       CGSizeMake(8.0, 8.0)],
            [@"max-size",       CGSizeMake(8.0, 8.0)],

            [@"bezel-inset",    CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateBordered],
            [@"bezel-inset",    CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateBordered | CPThemeStateHighlighted],

            [@"offset",         CGPointMake(18, 6),                 CPThemeStateBordered]
        ];

    [self registerThemeValues:themeValues forView:button];

    return button;
}

+ (CPComboBox)themedComboBox
{
    var combo = [[CPComboBox alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 31.0)];

    var bezelColor = PatternColor(
            [
                ["combobox-bezel-left.png", 4.0, 25.0],
                ["combobox-bezel-center.png", 1.0, 25.0],
                ["combobox-bezel-right.png", 24.0, 25.0]
            ],
            PatternIsHorizontal),

        bezelFocusedColor = PatternColor(
            [
                ["combobox-bezel-focused-left.png", 9.0, 31.0],
                ["combobox-bezel-focused-center.png", 1.0, 31.0],
                ["combobox-bezel-focused-right.png", 27.0, 31.0]
            ],
            PatternIsHorizontal),

        bezelDisabledColor = PatternColor(
            [
                ["combobox-bezel-disabled-left.png", 4.0, 25.0],
                ["combobox-bezel-disabled-center.png", 1.0, 25.0],
                ["combobox-bezel-disabled-right.png", 24.0, 25.0]
            ],
            PatternIsHorizontal),

        bezelNoBorderColor = PatternColor(
            [
                ["combobox-bezel-no-border-left.png", 6.0, 29.0],
                ["combobox-bezel-no-border-center.png", 1.0, 29.0],
                ["combobox-bezel-no-border-right.png", 24.0, 29.0]
            ],
            PatternIsHorizontal),

        bezelNoBorderFocusedColor = PatternColor(
            [
                ["combobox-bezel-no-border-focused-left.png", 6.0, 29.0],
                ["combobox-bezel-no-border-focused-center.png", 1.0, 29.0],
                ["combobox-bezel-no-border-focused-right.png", 24.0, 29.0]
            ],
            PatternIsHorizontal),

        bezelNoBorderDisabledColor = PatternColor(
            [
                ["combobox-bezel-no-border-disabled-left.png", 6.0, 29.0],
                ["combobox-bezel-no-border-disabled-center.png", 1.0, 29.0],
                ["combobox-bezel-no-border-disabled-right.png", 24.0, 29.0]
            ],
            PatternIsHorizontal),

        overrides =
        [
            [@"bezel-color",        bezelColor,                     CPThemeStateBezeled | CPComboBoxStateButtonBordered],
            [@"bezel-color",        bezelFocusedColor,              CPThemeStateBezeled | CPComboBoxStateButtonBordered | CPThemeStateEditing],
            [@"bezel-color",        bezelDisabledColor,             CPThemeStateBezeled | CPComboBoxStateButtonBordered | CPThemeStateDisabled],

            [@"bezel-color",        bezelNoBorderColor,             CPThemeStateBezeled],
            [@"bezel-color",        bezelNoBorderFocusedColor,      CPThemeStateBezeled | CPThemeStateEditing],
            [@"bezel-color",        bezelNoBorderDisabledColor,     CPThemeStateBezeled | CPThemeStateDisabled],

            [@"border-inset",       CGInsetMake(3.0, 3.0, 3.0, 3.0),    CPThemeStateBezeled],

            [@"bezel-inset",        CGInsetMake(0.0, 1.0, 1.0, 1.0),    CPThemeStateBezeled | CPThemeStateEditing],

            // The right border inset has to make room for the focus ring and popup button
            [@"content-inset",      CGInsetMake(8.0, 26.0, 7.0, 8.0),    CPThemeStateBezeled | CPComboBoxStateButtonBordered],
            [@"content-inset",      CGInsetMake(8.0, 24.0, 7.0, 8.0),    CPThemeStateBezeled],
            [@"content-inset",      CGInsetMake(8.0, 24.0, 7.0, 8.0),    CPThemeStateBezeled | CPThemeStateEditing],

            [@"popup-button-size",  CGSizeMake(21.0, 23.0), CPThemeStateBezeled | CPComboBoxStateButtonBordered],
            [@"popup-button-size",  CGSizeMake(17.0, 23.0), CPThemeStateBezeled],

            // Because combo box uses a three-part bezel, the height is fixed
            [@"min-size",           CGSizeMake(0, 29.0)],
            [@"max-size",           CGSizeMake(-1, 29.0)]
        ];

    [self registerThemeValues:overrides forView:combo inherit:themedTextFieldValues];

    return combo;
}

+ (CPRadioButton)themedRadioButton
{
    var button = [CPRadio radioWithTitle:@"Radio button"],

        imageNormal = PatternImage("radio-image.png", 21.0, 21.0),
        imageSelected = PatternImage("radio-image-selected.png", 21.0, 21.0),
        imageSelectedHighlighted = PatternImage("radio-image-selected-highlighted.png", 21.0, 21.0),
        imageSelectedDisabled = PatternImage("radio-image-selected-disabled.png", 21.0, 21.0),
        imageDisabled = PatternImage("radio-image-disabled.png", 21.0, 21.0),
        imageHighlighted = PatternImage("radio-image-highlighted.png", 21.0, 21.0),

        themeValues =
        [
            [@"alignment",      CPLeftTextAlignment,                CPThemeStateNormal],
            [@"font",           [CPFont systemFontOfSize:12.0],     CPThemeStateNormal],
            [@"content-inset",  CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateNormal],

            [@"image",          imageNormal,                        CPThemeStateNormal],
            [@"image",          imageSelected,                      CPThemeStateSelected],
            [@"image",          imageSelectedHighlighted,           CPThemeStateSelected | CPThemeStateHighlighted],
            [@"image",          imageHighlighted,                   CPThemeStateHighlighted],
            [@"image",          imageDisabled,                      CPThemeStateDisabled],
            [@"image",          imageSelectedDisabled,              CPThemeStateSelected | CPThemeStateDisabled],
            [@"image-offset",   CPRadioImageOffset],

            [@"text-color",     [CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0],  CPThemeStateDisabled],

            [@"min-size",       CGSizeMake(21.0, 21.0)],
            [@"max-size",       CGSizeMake(-1.0, -1.0)]
        ];

    [self registerThemeValues:themeValues forView:button];

    return button;
}

+ (CPCheckBox)themedCheckBoxButton
{
    var button = [CPCheckBox checkBoxWithTitle:@"Checkbox"],

        imageNormal = PatternImage("check-box-image.png", 21.0, 21.0),
        imageSelected = PatternImage("check-box-image-selected.png", 21.0, 21.0),
        imageSelectedHighlighted = PatternImage("check-box-image-selected-highlighted.png", 21.0, 21.0),
        imageSelectedDisabled = PatternImage("check-box-image-selected-disabled.png", 21.0, 21.0),
        imageDisabled = PatternImage("check-box-image-disabled.png", 21.0, 21.0),
        imageHighlighted = PatternImage("check-box-image-highlighted.png", 21.0, 21.0),

        themeValues =
        [
            [@"alignment",      CPLeftTextAlignment,                CPThemeStateNormal],
            [@"content-inset",  CGInsetMakeZero(),                  CPThemeStateNormal],

            [@"image",          imageNormal,                        CPThemeStateNormal],
            [@"image",          imageSelected,                      CPThemeStateSelected],
            [@"image",          imageSelectedHighlighted,           CPThemeStateSelected | CPThemeStateHighlighted],
            [@"image",          imageHighlighted,                   CPThemeStateHighlighted],
            [@"image",          imageDisabled,                      CPThemeStateDisabled],
            [@"image",          imageSelectedDisabled,              CPThemeStateSelected | CPThemeStateDisabled],
            [@"image-offset",   CPCheckBoxImageOffset],

            [@"font",           [CPFont systemFontOfSize:CPFontCurrentSystemSize], CPThemeStateNormal],
            [@"text-color",     [CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0],  CPThemeStateDisabled],

            [@"min-size",       CGSizeMake(21.0, 21.0)],
            [@"max-size",       CGSizeMake(-1.0, -1.0)]
        ];

    [button setThemeState:CPThemeStateSelected];

    [self registerThemeValues:themeValues forView:button];

    return button;
}

+ (CPCheckBox)themedMixedCheckBoxButton
{
    var button = [self themedCheckBoxButton];

    [button setAllowsMixedState:YES];
    [button setState:CPMixedState];

    var mixedHighlightedImage = PatternImage("check-box-image-mixed-highlighted.png", 21.0, 21.0),
        mixedDisabledImage = PatternImage("check-box-image-mixed-disabled.png", 21.0, 21.0),
        mixedImage = PatternImage("check-box-image-mixed.png", 21.0, 21.0),

        themeValues =
        [
            [@"image",          mixedImage,             CPButtonStateMixed],
            [@"image",          mixedHighlightedImage,  CPButtonStateMixed | CPThemeStateHighlighted],
            [@"image",          mixedDisabledImage,     CPButtonStateMixed | CPThemeStateDisabled],
            [@"image-offset",   CPCheckBoxImageOffset,  CPButtonStateMixed],
            [@"max-size",       CGSizeMake(-1.0, -1.0)]
        ];

    [self registerThemeValues:themeValues forView:button];

    return button;
}

+ (CPSegmentedControl)makeSegmentedControl
{
    var segmentedControl = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 25.0)];

    [segmentedControl setTrackingMode:CPSegmentSwitchTrackingSelectAny];
    [segmentedControl setSegmentCount:3];

    [segmentedControl setWidth:40.0 forSegment:0];
    [segmentedControl setLabel:@"foo" forSegment:0];
    [segmentedControl setTag:1 forSegment:0];

    [segmentedControl setWidth:60.0 forSegment:1];
    [segmentedControl setLabel:@"bar" forSegment:1];
    [segmentedControl setTag:2 forSegment:1];

    [segmentedControl setWidth:35.0 forSegment:2];
    [segmentedControl setLabel:@"1" forSegment:2];
    [segmentedControl setTag:3 forSegment:2];

    return segmentedControl;
};

+ (CPSegmentedControl)themedSegmentedControl
{
    var segmentedControl = [self makeSegmentedControl],

        centerBezelColor = PatternColor("segmented-control-bezel-center.png", 1.0, 25.0),
        dividerBezelColor = PatternColor("segmented-control-bezel-divider.png", 1.0, 25.0),
        centerHighlightedBezelColor = PatternColor("segmented-control-bezel-highlighted-center.png", 1.0, 25.0),
        dividerHighlightedBezelColor = PatternColor("segmented-control-bezel-highlighted-divider.png", 1.0, 25.0),
        leftHighlightedBezelColor = PatternColor("segmented-control-bezel-highlighted-left.png", 4.0, 25.0),
        rightHighlightedBezelColor = PatternColor("segmented-control-bezel-highlighted-right.png", 4.0, 25.0),
        inactiveCenterBezelColor = PatternColor("segmented-control-bezel-disabled-center.png", 1.0, 25.0),
        inactiveDividerBezelColor = PatternColor("segmented-control-bezel-disabled-divider.png", 1.0, 25.0),
        inactiveLeftBezelColor = PatternColor("segmented-control-bezel-disabled-left.png", 4.0, 25.0),
        inactiveRightBezelColor = PatternColor("segmented-control-bezel-disabled-right.png", 4.0, 25.0),
        inactiveHighlightedCenterBezelColor = PatternColor("segmented-control-bezel-highlighted-disabled-center.png", 1.0, 25.0),
        inactiveHighlightedDividerBezelColor = PatternColor("segmented-control-bezel-highlighted-disabled-divider.png", 1.0, 25.0),
        inactiveHighlightedLeftBezelColor = PatternColor("segmented-control-bezel-highlighted-disabled-left.png", 4.0, 25.0),
        inactiveHighlightedRightBezelColor = PatternColor("segmented-control-bezel-highlighted-disabled-right.png", 4.0, 25.0),
        leftBezelColor = PatternColor("segmented-control-bezel-left.png", 4.0, 25.0),
        rightBezelColor = PatternColor("segmented-control-bezel-right.png", 4.0, 25.0),
        pushedCenterBezelColor = PatternColor("segmented-control-bezel-pushed-center.png", 1.0, 25.0),
        pushedLeftBezelColor = PatternColor("segmented-control-bezel-pushed-left.png", 4.0, 25.0),
        pushedRightBezelColor = PatternColor("segmented-control-bezel-pushed-right.png", 4.0, 25.0),
        pushedHighlightedCenterBezelColor = PatternColor("segmented-control-bezel-pushed-highlighted-center.png", 1.0, 25.0),
        pushedHighlightedLeftBezelColor = PatternColor("segmented-control-bezel-pushed-highlighted-left.png", 4.0, 25.0),
        pushedHighlightedRightBezelColor = PatternColor("segmented-control-bezel-pushed-highlighted-right.png", 4.0, 25.0);

    themedSegmentedControlValues =
        [
            [@"center-segment-bezel-color",     centerBezelColor,                       CPThemeStateNormal],
            [@"center-segment-bezel-color",     inactiveCenterBezelColor,               CPThemeStateDisabled],
            [@"center-segment-bezel-color",     inactiveHighlightedCenterBezelColor,    CPThemeStateSelected | CPThemeStateDisabled],
            [@"center-segment-bezel-color",     centerHighlightedBezelColor,            CPThemeStateSelected],
            [@"center-segment-bezel-color",     pushedCenterBezelColor,                 CPThemeStateHighlighted],
            [@"center-segment-bezel-color",     pushedHighlightedCenterBezelColor,      CPThemeStateHighlighted | CPThemeStateSelected],

            [@"divider-bezel-color",            dividerBezelColor,                      CPThemeStateNormal],
            [@"divider-bezel-color",            inactiveDividerBezelColor,              CPThemeStateDisabled],
            [@"divider-bezel-color",            inactiveHighlightedDividerBezelColor,   CPThemeStateSelected | CPThemeStateDisabled],
            [@"divider-bezel-color",            dividerHighlightedBezelColor,           CPThemeStateSelected],

            [@"left-segment-bezel-color",       leftBezelColor,                         CPThemeStateNormal],
            [@"left-segment-bezel-color",       inactiveLeftBezelColor,                 CPThemeStateDisabled],
            [@"left-segment-bezel-color",       inactiveHighlightedLeftBezelColor,      CPThemeStateSelected | CPThemeStateDisabled],
            [@"left-segment-bezel-color",       leftHighlightedBezelColor,              CPThemeStateSelected],
            [@"left-segment-bezel-color",       pushedLeftBezelColor,                   CPThemeStateHighlighted],
            [@"left-segment-bezel-color",       pushedHighlightedLeftBezelColor,        CPThemeStateHighlighted | CPThemeStateSelected],

            [@"right-segment-bezel-color",      rightBezelColor,                        CPThemeStateNormal],
            [@"right-segment-bezel-color",      inactiveRightBezelColor,                CPThemeStateDisabled],
            [@"right-segment-bezel-color",      inactiveHighlightedRightBezelColor,     CPThemeStateSelected | CPThemeStateDisabled],
            [@"right-segment-bezel-color",      rightHighlightedBezelColor,             CPThemeStateSelected],
            [@"right-segment-bezel-color",      pushedRightBezelColor,                  CPThemeStateHighlighted],
            [@"right-segment-bezel-color",      pushedHighlightedRightBezelColor,       CPThemeStateHighlighted | CPThemeStateSelected],

            [@"content-inset",  CGInsetMake(0.0, 4.0, 0.0, 4.0), CPThemeStateNormal],
            [@"bezel-inset",    CGInsetMake(0.0, 0.0, 0.0, 0.0), CPThemeStateNormal],

            [@"font",               [CPFont boldSystemFontOfSize:12.0]],
            [@"text-color",         [CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0]],
            [@"text-color",         [CPColor colorWithCalibratedWhite:0.6 alpha:1.0], CPThemeStateDisabled],
            [@"text-color",         [CPColor colorWithCalibratedWhite:0.6 alpha:1.0], CPThemeStateDisabled | CPThemeStateSelected],
            [@"text-color",         [CPColor whiteColor], CPThemeStateSelected],
            [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0]],
            [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0], CPThemeStateDisabled],
            [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0], CPThemeStateDisabled | CPThemeStateSelected],
            [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:0.0 alpha:0.2], CPThemeStateSelected],
            [@"text-shadow-offset", CGSizeMake(0.0, 1.0)],
            [@"text-shadow-offset", CGSizeMake(0.0, 1.0), CPThemeStateSelected],
            [@"line-break-mode",    CPLineBreakByTruncatingTail],

            [@"divider-thickness",  1.0],
            [@"default-height",     25.0]
        ];

    [self registerThemeValues:themedSegmentedControlValues forView:segmentedControl];

    return segmentedControl;
}

+ (CPSlider)makeHorizontalSlider
{
    return [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, 24.0)];
}

+ (CPSlider)themedHorizontalSlider
{
    var slider = [self makeHorizontalSlider],

        trackColor = PatternColor(
        [
            ["horizontal-track-left.png", 2.0, 5.0],
            ["horizontal-track-center.png", 1.0, 5.0],
            ["horizontal-track-right.png", 2.0, 5.0]
        ],
        PatternIsHorizontal),

        trackDisabledColor = PatternColor(
        [
            ["horizontal-track-disabled-left.png", 4.0, 5.0],
            ["horizontal-track-disabled-center.png", 1.0, 5.0],
            ["horizontal-track-disabled-right.png", 4.0, 5.0]
        ],
        PatternIsHorizontal),

        knobColor =             PatternColor("knob.png", 21.0, 21.0),
        knobHighlightedColor =  PatternColor("knob-highlighted.png", 21.0, 21.0),
        knobDisabledColor =     PatternColor("knob-disabled.png", 20.0, 21.0);

    themedHorizontalSliderValues =
    [
        [@"track-width", 5.0],
        [@"track-color", trackColor],
        [@"track-color", trackDisabledColor, CPThemeStateDisabled],

        [@"knob-size",  CGSizeMake(21.0, 21.0)],
        [@"knob-color", knobColor],
        [@"knob-color", knobHighlightedColor,   CPThemeStateHighlighted],
        [@"knob-color", knobDisabledColor,      CPThemeStateDisabled]
    ];

    [self registerThemeValues:themedHorizontalSliderValues forView:slider];

    return slider;
}

+ (CPSlider)makeVerticalSlider
{
    return [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 24.0, 50.0)];
}

+ (CPSlider)themedVerticalSlider
{
    var slider = [self makeVerticalSlider],

        trackColor = PatternColor(
        [
            ["vertical-track-top.png", 5.0, 3.0],
            ["vertical-track-center.png", 5.0, 1.0],
            ["vertical-track-bottom.png", 5.0, 3.0]
        ],
        PatternIsVertical),

        trackDisabledColor = PatternColor(
        [
            ["vertical-track-disabled-top.png", 5.0, 6.0],
            ["vertical-track-disabled-center.png", 5.0, 1.0],
            ["vertical-track-disabled-bottom.png", 5.0, 4.0]
        ],
        PatternIsVertical),

        knobColor =             PatternColor("knob.png", 21.0, 21.0),
        knobHighlightedColor =  PatternColor("knob-highlighted.png", 21.0, 21.0),
        knobDisabledColor =     PatternColor("knob-disabled.png", 21.0, 21.0);

    themedVerticalSliderValues =
    [
        [@"track-width", 5.0],
        [@"track-color", trackColor,            CPThemeStateVertical],
        [@"track-color", trackDisabledColor,    CPThemeStateVertical | CPThemeStateDisabled],

        [@"knob-size",  CGSizeMake(21.0, 21.0)],
        [@"knob-color", knobColor],
        [@"knob-color", knobHighlightedColor,   CPThemeStateHighlighted],
        [@"knob-color", knobDisabledColor,      CPThemeStateDisabled]
    ];

    [self registerThemeValues:themedVerticalSliderValues forView:slider];

    return slider;
}

+ (CPSlider)makeCircularSlider
{
    var slider = [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 30.0, 30.0)];

    [slider setSliderType:CPCircularSlider];

    return slider;
}

+ (CPSlider)themedCircularSlider
{
    var slider = [self makeCircularSlider],

        trackColor = PatternColor("slider-circular-bezel.png", 30.0, 30.0),
        trackDisabledColor = PatternColor("slider-circular-disabled-bezel.png", 30.0, 30.0),
        knobColor = PatternColor("slider-circular-knob.png", 5.0, 5.0),
        knobDisabledColor = PatternColor("slider-circular-disabled-knob.png", 5.0, 5.0),
        knobHighlightedColor = knobColor;

    themedCircularSliderValues =
    [
        [@"track-color", trackColor,            CPThemeStateCircular],
        [@"track-color", trackDisabledColor,    CPThemeStateCircular | CPThemeStateDisabled],

        [@"knob-size",  CGSizeMake(5.0, 5.0),   CPThemeStateCircular],
        [@"knob-color", knobColor,              CPThemeStateCircular],
        [@"knob-color", knobHighlightedColor,   CPThemeStateCircular | CPThemeStateHighlighted],
        [@"knob-color", knobDisabledColor,      CPThemeStateCircular | CPThemeStateDisabled]
    ];

    [self registerThemeValues:themedCircularSliderValues forView:slider];

    return slider;
}

+ (CPButtonBar)makeButtonBar
{
    var buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 147.0, 26.0)];

    [buttonBar setHasResizeControl:YES];

    var popup = [CPButtonBar actionPopupButton];
    [popup addItemWithTitle:"Item 1"];
    [popup addItemWithTitle:"Item 2"];

    [buttonBar setButtons:[[CPButtonBar plusButton], [CPButtonBar minusButton], popup]];

    return buttonBar;
}

+ (CPButtonBar)themedButtonBar
{
    var buttonBar = [self makeButtonBar],

        color = PatternColor("buttonbar-bezel.png", 1.0, 26.0),
        resizeColor = PatternColor("buttonbar-resize-control.png", 5.0, 10.0),
        buttonBezelColor = PatternColor(
            [
                ["buttonbar-button-bezel-left.png", 2.0, 25.0],
                ["buttonbar-button-bezel-center.png", 1.0, 25.0],
                ["buttonbar-button-bezel-right.png", 2.0, 25.0]
            ],
            PatternIsHorizontal),

        buttonBezelHighlightedColor = PatternColor(
            [
                ["buttonbar-button-bezel-highlighted-left.png", 2.0, 25.0],
                ["buttonbar-button-bezel-highlighted-center.png", 1.0, 25.0],
                ["buttonbar-button-bezel-highlighted-right.png", 2.0, 25.0]
            ],
            PatternIsHorizontal),

        buttonBezelDisabledColor = PatternColor(
            [
                ["buttonbar-button-bezel-disabled-left.png", 2.0, 25.0],
                ["buttonbar-button-bezel-disabled-center.png", 1.0, 25.0],
                ["buttonbar-button-bezel-disabled-right.png", 2.0, 25.0]
            ],
            PatternIsHorizontal),

        buttonImagePlus = PatternImage("buttonbar-image-plus.png", 11.0, 12.0),
        buttonImageMinus = PatternImage("buttonbar-image-minus.png", 11.0, 4.0),
        buttonImageAction = PatternImage("buttonbar-image-action.png", 22.0, 14.0),

        themedButtonBarValues =
        [
            [@"bezel-color", color],

            [@"resize-control-size",    CGSizeMake(5.0, 10.0)],
            [@"resize-control-inset",   CGInsetMake(9.0, 4.0, 7.0, 4.0)],
            [@"resize-control-color",   resizeColor],

            [@"button-bezel-color",     buttonBezelColor],
            [@"button-bezel-color",     buttonBezelHighlightedColor,    CPThemeStateHighlighted],
            [@"button-bezel-color",     buttonBezelDisabledColor,       CPThemeStateDisabled],
            [@"button-text-color",      [CPColor blackColor]],

            [@"button-image-plus",      buttonImagePlus],
            [@"button-image-minus",     buttonImageMinus],
            [@"button-image-action",    buttonImageAction]
        ];

    [self registerThemeValues:themedButtonBarValues forView:buttonBar];

    return buttonBar;
}

+ (_CPTableColumnHeaderView)makeColumnHeader
{
    var header = [[_CPTableColumnHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 25.0)];

    [header setStringValue:@"Table Header"];

    return header;
}

+ (_CPTableColumnHeaderView)themedColumnHeader
{
    var header = [self makeColumnHeader],
        highlightedPressed = PatternColor("tableview-headerview-highlighted-pressed.png", 1.0, 25.0),
        highlighted        = PatternColor("tableview-headerview-highlighted.png", 1.0, 25.0),
        pressed            = PatternColor("tableview-headerview-pressed.png", 1.0, 25.0),
        normal             = PatternColor("tableview-headerview.png", 1.0, 25.0),

        themedColumnHeaderValues =
        [
            [@"background-color",   normal],

            [@"text-inset",         CGInsetMake(0, 5, 0, 5)],
            [@"text-color",         [CPColor colorWithHexString:@"808080"]],
            [@"font",               [CPFont boldSystemFontOfSize:11.0]],
            [@"text-shadow-color",  [CPColor whiteColor]],
            [@"text-shadow-offset", CGSizeMake(0.0, 1.0)],
            [@"text-alignment",     CPLeftTextAlignment],
            [@"line-break-mode",    CPLineBreakByTruncatingTail],

            [@"background-color",   pressed,            CPThemeStateHighlighted],
            [@"background-color",   highlighted,        CPThemeStateSelected],
            [@"background-color",   highlightedPressed, CPThemeStateHighlighted | CPThemeStateSelected]
        ];

    [self registerThemeValues:themedColumnHeaderValues forView:header];

    return header;
}

+ (CPTableHeaderView)themedTableHeaderRow
{
    var header = [[CPTableHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 25.0)],
        normal = PatternColor("tableview-headerview.png", 1.0, 25.0),
        gridColor = [CPColor colorWithHexString:@"cccccc"];

    [header setValue:normal forThemeAttribute:@"background-color"];
    [header setValue:gridColor forThemeAttribute:@"divider-color"];

    return header;
}

+ (_CPCornerView)themedCornerview
{
    var scrollerWidth = [CPScroller scrollerWidth],
        corner = [[_CPCornerView alloc] initWithFrame:CGRectMake(0.0, 0.0, scrollerWidth, 25.0)],
        normal = PatternColor("tableview-headerview.png", 1.0, 25.0),
        dividerColor = [CPColor colorWithHexString:@"cccccc"];

    [corner setValue:normal forThemeAttribute:"background-color"];
    [corner setValue:dividerColor forThemeAttribute:"divider-color"];

    return corner;
}

+ (CPTableView)themedTableView
{
    // This is a bit more complicated than the rest because we actually set theme values for several different (table related) controls in this method

    var tableview = [[CPTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 150.0, 150.0)],

        sortImage = PatternImage("tableview-headerview-ascending.png", 9.0, 8.0),
        sortImageReversed = PatternImage("tableview-headerview-descending.png", 9.0, 8.0),
        imageGenericFile = PatternImage("tableview-image-generic-file.png", 64.0, 64.0),
        alternatingRowColors = [[CPColor whiteColor], [CPColor colorWithRed:245.0 / 255.0 green:249.0 / 255.0 blue:252.0 / 255.0 alpha:1.0]],
        gridColor = [CPColor colorWithHexString:@"dce0e2"],
        selectionColor = [CPColor colorWithHexString:@"5780d8"],
        sourceListSelectionColor = [CPDictionary dictionaryWithObjects: [CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [87.0 / 255.0, 128.0 / 210.0, 216.0 / 255.0, 1.0], [0], 1),
                                                                          [CPColor colorWithCalibratedRed:84.0 / 255.0 green:121.0 / 255.0 blue:200.0 / 255.0 alpha:1.0],
                                                                          [CPColor colorWithCalibratedRed:84.0 / 255.0 green:121.0 / 255.0 blue:200.0 / 255.0 alpha:1.0]
                                                                        ]
                                                               forKeys: [CPSourceListGradient, CPSourceListTopLineColor, CPSourceListBottomLineColor]],

        themedTableViewValues =
        [
            [@"alternating-row-colors",     alternatingRowColors],
            [@"grid-color",                 gridColor],
            [@"highlighted-grid-color",     [CPColor whiteColor]],
            [@"selection-color",            selectionColor],
            [@"sourcelist-selection-color", sourceListSelectionColor],
            [@"sort-image",                 sortImage],
            [@"sort-image-reversed",        sortImageReversed],
            [@"image-generic-file",         imageGenericFile],
            [@"default-row-height",         25.0],
        ];

    [tableview setUsesAlternatingRowBackgroundColors:YES];
    [self registerThemeValues:themedTableViewValues forView:tableview];

    return tableview;
}

+ (CPTextField)themedTableDataView
{
    var view = [self themedStandardTextField];

    [view setBezeled:NO];
    [view setEditable:NO];
    [view setThemeState:CPThemeStateTableDataView];

    return view;
}

+ (CPSplitView)themedSplitView
{
    var splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)],
        leftView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 75.0, 150.0)],
        rightView = [[CPView alloc] initWithFrame:CGRectMake(75.0, 0.0, 75.0, 150.0)],
        horizontalDividerColor = PatternImage("splitview-divider-horizontal.png", 5.0, 10.0),
        verticalDividerColor = PatternImage("splitview-divider-vertical.png", 10.0, 5.0);

    [splitView addSubview:leftView];
    [splitView addSubview:rightView];
    [splitView setIsPaneSplitter:YES];

    var themedSplitViewValues =
        [
            [@"divider-thickness", 1.0],
            [@"pane-divider-thickness", 10.0],
            [@"pane-divider-color", [CPColor colorWithRed:165.0 / 255.0 green:165.0 / 255.0 blue:165.0 / 255.0 alpha:1.0]],
            [@"horizontal-divider-color", horizontalDividerColor],
            [@"vertical-divider-color", verticalDividerColor]
        ];

    [self registerThemeValues:themedSplitViewValues forView:splitView];

    return splitView;
}

+ (CPAlert)themedAlert
{
    var alert = [CPAlert new],
        buttonOffset = 10.0,
        defaultElementsMargin = 3.0,
        errorIcon = PatternImage("alert-error.png", 53.0, 46.0),
        helpIcon = PatternImage("alert-help.png", 24.0, 24.0),
        helpIconPressed = PatternImage("alert-help-pressed.png", 24.0, 24.0),
        helpLeftOffset = 15,
        imageOffset = CGPointMake(15, 18),
        informationIcon = PatternImage("alert-info.png", 53.0, 46.0),
        informativeFont = [CPFont systemFontOfSize:CPFontCurrentSystemSize],
        inset = CGInsetMake(15, 15, 15, 80),
        messageFont = [CPFont boldSystemFontOfSize:CPFontDefaultSystemFontSize + 1],
        size = CGSizeMake(400.0, 120.0),
        suppressionButtonXOffset = 2.0,
        suppressionButtonYOffset = 10.0,
        suppressionButtonFont = [CPFont systemFontOfSize:CPFontCurrentSystemSize],
        warningIcon = PatternImage("alert-warning.png", 53.0, 46.0);

    themedAlertValues =
    [
        [@"button-offset",                      buttonOffset],
        [@"content-inset",                      inset],
        [@"default-elements-margin",            defaultElementsMargin],
        [@"error-image",                        errorIcon],
        [@"help-image",                         helpIcon],
        [@"help-image-left-offset",             helpLeftOffset],
        [@"help-image-pressed",                 helpIconPressed],
        [@"image-offset",                       imageOffset],
        [@"information-image",                  informationIcon],
        [@"informative-text-alignment",         CPJustifiedTextAlignment],
        [@"informative-text-color",             [CPColor blackColor]],
        [@"informative-text-font",              informativeFont],
        [@"message-text-alignment",             CPJustifiedTextAlignment],
        [@"message-text-color",                 [CPColor blackColor]],
        [@"message-text-font",                  messageFont],
        [@"suppression-button-text-color",      [CPColor blackColor]],
        [@"suppression-button-text-font",       suppressionButtonFont],
        [@"size",                               size],
        [@"suppression-button-x-offset",        suppressionButtonXOffset],
        [@"suppression-button-y-offset",        suppressionButtonYOffset],
        [@"warning-image",                      warningIcon]
    ];

    [self registerThemeValues:themedAlertValues forView:alert];

    return [alert themeView];
}

+ (CPStepper)themedStepper
{
    var stepper = [CPStepper stepper],

        bezelUp = PatternColor(
            [
                ["stepper-bezel-big-up-left.png", 4.0, 13.0],
                ["stepper-bezel-big-up-center.png", 17.0, 13.0],
                ["stepper-bezel-big-up-right.png", 4.0, 13.0]
            ],
            PatternIsHorizontal),

        bezelDown = PatternColor(
            [
                ["stepper-bezel-big-down-left.png", 4.0, 12.0],
                ["stepper-bezel-big-down-center.png", 17.0, 12.0],
                ["stepper-bezel-big-down-right.png", 4.0, 12.0]
            ],
            PatternIsHorizontal),

        bezelUpDisabled = PatternColor(
            [
                ["stepper-bezel-big-disabled-up-left.png", 4.0, 13.0],
                ["stepper-bezel-big-disabled-up-center.png", 17.0, 13.0],
                ["stepper-bezel-big-disabled-up-right.png", 4.0, 13.0]
            ],
            PatternIsHorizontal),

        bezelDownDisabled = PatternColor(
            [
                ["stepper-bezel-big-disabled-down-left.png", 4.0, 12.0],
                ["stepper-bezel-big-disabled-down-center.png", 17.0, 12.0],
                ["stepper-bezel-big-disabled-down-right.png", 4.0, 12.0]
            ],
            PatternIsHorizontal),

        bezelUpHighlighted = PatternColor(
            [
                [@"stepper-bezel-big-highlighted-up-left.png", 4.0, 13.0],
                [@"stepper-bezel-big-highlighted-up-center.png", 17.0, 13.0],
                [@"stepper-bezel-big-highlighted-up-right.png", 4.0, 13.0]
            ],
            PatternIsHorizontal),

        bezelDownHighlighted = PatternColor(
            [
                [@"stepper-bezel-big-highlighted-down-left.png", 4.0, 12.0],
                [@"stepper-bezel-big-highlighted-down-center.png", 17.0, 12.0],
                [@"stepper-bezel-big-highlighted-down-right.png", 4.0, 12.0]
            ],
            PatternIsHorizontal),

        themeValues =
        [
            [@"bezel-color-up-button",      bezelUp,                        CPThemeStateBordered],
            [@"bezel-color-down-button",    bezelDown,                      CPThemeStateBordered],
            [@"bezel-color-up-button",      bezelUpDisabled,                CPThemeStateBordered | CPThemeStateDisabled],
            [@"bezel-color-down-button",    bezelDownDisabled,              CPThemeStateBordered | CPThemeStateDisabled],
            [@"bezel-color-up-button",      bezelUpHighlighted,             CPThemeStateBordered | CPThemeStateHighlighted],
            [@"bezel-color-down-button",    bezelDownHighlighted,           CPThemeStateBordered | CPThemeStateHighlighted],
            [@"min-size",                   CGSizeMake(25.0, 25.0)],
            [@"up-button-size",             CGSizeMake(25.0, 13.0)],
            [@"down-button-size",           CGSizeMake(25.0, 12.0)],
        ];

    [self registerThemeValues:themeValues forView:stepper];

    return stepper;
}

+ (CPRuleEditor)themedRuleEditor
{
    var ruleEditor = [[CPRuleEditor alloc] initWithFrame:CGRectMake(0, 0, 400, 300)],
        backgroundColors = [[CPColor whiteColor], [CPColor colorWithRed:235/255 green:239/255 blue:252/255 alpha:1]],
        selectedActiveRowColor = [CPColor colorWithHexString:@"5f83b9"],
        selectedInactiveRowColor = [CPColor colorWithWhite:0.83 alpha:1],
        sliceTopBorderColor = [CPColor colorWithWhite:0.9 alpha:1],
        sliceBottomBorderColor = [CPColor colorWithWhite:0.729412 alpha:1],
        sliceLastBottomBorderColor = [CPColor colorWithWhite:0.6 alpha:1],
        addImage = PatternImage(@"rule-editor-add.png", 8.0, 8.0),
        removeImage = PatternImage(@"rule-editor-remove.png", 8.0, 8.0),

        ruleEditorThemedValues =
        [
            [@"alternating-row-colors",         backgroundColors],
            [@"selected-color",                 selectedActiveRowColor, CPThemeStateNormal],
            [@"selected-color",                 selectedInactiveRowColor, CPThemeStateDisabled],
            [@"slice-top-border-color",         sliceTopBorderColor],
            [@"slice-bottom-border-color",      sliceBottomBorderColor],
            [@"slice-last-bottom-border-color", sliceLastBottomBorderColor],
            [@"font",                           [CPFont systemFontOfSize:10.0]],
            [@"add-image",                      addImage],
            [@"remove-image",                   removeImage]
        ];

    [self registerThemeValues:ruleEditorThemedValues forView:ruleEditor];

    return ruleEditor;
}

+ (_CPToolTipWindowView)themedTooltip
{
    var toolTipView = [[_CPToolTipWindowView alloc] initWithFrame:CPRectMake(0.0, 0.0, 200.0, 100.0) styleMask:_CPToolTipWindowMask],

        themeValues =
        [
            [@"stroke-color",       [CPColor colorWithHexString:@"E3E3E3"]],
            [@"stroke-width",       1.0],
            [@"border-radius",      2.0],
            [@"background-color",   [CPColor colorWithHexString:@"FFFFCA"]],
            [@"color",              [CPColor blackColor]]
        ];

    [self registerThemeValues:themeValues forView:toolTipView];

    return toolTipView;
}

+ (CPColorWell)themedColorWell
{
    // The CPColorPanel CPColorWell depends on requires CPApp.
    [CPApplication sharedApplication];

    var colorWell = [[CPColorWell alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 24.0)],

        bezelColor = PatternColor(
            [
                ["colorwell-bezel-left.png", 3.0, 24.0],
                ["colorwell-bezel-center.png", 1.0, 24.0],
                ["colorwell-bezel-right.png", 3.0, 24.0]
            ],
            PatternIsHorizontal),

        bezelHighlightedColor = PatternColor(
            [
                ["colorwell-bezel-highlighted-left.png", 3.0, 24.0],
                ["colorwell-bezel-highlighted-center.png", 1.0, 24.0],
                ["colorwell-bezel-highlighted-right.png", 3.0, 24.0]
            ],
            PatternIsHorizontal),

        bezelDisabledColor = PatternColor(
            [
                ["colorwell-bezel-disabled-left.png", 3.0, 24.0],
                ["colorwell-bezel-disabled-center.png", 1.0, 24.0],
                ["colorwell-bezel-disabled-right.png", 3.0, 24.0]
            ],
            PatternIsHorizontal),

        contentBorderColor = PatternColor(
            [
                ["colorwell-content-border-left.png", 1.0, 15.0],
                ["colorwell-content-border-center.png", 1.0, 15.0],
                ["colorwell-content-border-right.png", 1.0, 15.0]
            ],
            PatternIsHorizontal),

        themedColorWellValues = [
                [@"bezel-color",            bezelColor,                         CPThemeStateBordered],
                [@"content-inset",          CGInsetMake(5.0, 5.0, 5.0, 5.0),    CPThemeStateBordered],
                [@"content-border-inset",   CGInsetMake(5.0, 5.0, 4.0, 5.0),    CPThemeStateBordered],
                [@"content-border-color",   contentBorderColor,                 CPThemeStateBordered],

                [@"bezel-color",            bezelHighlightedColor,              CPThemeStateBordered | CPThemeStateHighlighted],

                [@"bezel-color",            bezelDisabledColor,                 CPThemeStateBordered | CPThemeStateDisabled],
            ];

    [self registerThemeValues:themedColorWellValues forView:colorWell];

    return colorWell;
}

+ (CPProgressIndicator)themedBarProgressIndicator
{
    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0,0,75,25)];
    [progressBar setDoubleValue:30];

    var bezelColor = PatternColor(
            [
                ["progress-indicator-bezel-border-bar-regular-left.png", 1.0, 25.0],
                ["progress-indicator-bezel-border-bar-regular-center.png", 1.0, 25.0],
                ["progress-indicator-bezel-border-bar-regular-right.png", 1.0, 25.0]
            ],
            PatternIsHorizontal),

        barColor = PatternColor(
            [
                ["progress-indicator-bar-bar-regular-left.png", 1.0, 25.0],
                ["progress-indicator-bar-bar-regular-center.png", 1.0, 25.0],
                ["progress-indicator-bar-bar-regular-right.png", 1.0, 25.0]
            ],
            PatternIsHorizontal),

        themeValues =
        [
            [@"bezel-color", bezelColor],
            [@"bar-color", barColor]
        ];

    [self registerThemeValues:themeValues forView:progressBar];

    return progressBar;
}

+ (CPProgressIndicator)themedIndeterminateBarProgressIndicator
{
    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0,0,75,25)];

    [progressBar setIndeterminate:YES];

    var bezelColor = PatternColor(
            [
                ["progress-indicator-bezel-border-bar-regular-left.png", 1.0, 25.0],
                ["progress-indicator-bezel-border-bar-regular-center.png", 1.0, 25.0],
                ["progress-indicator-bezel-border-bar-regular-right.png", 1.0, 25.0]
            ],
            PatternIsHorizontal),

        barColor = PatternColor(
            [
                ["progress-indicator-inderterminate-bar-bar-regular-left.png", 1.0, 25.0],
                ["progress-indicator-inderterminate-bar-bar-regular-center.png", 20.0, 25.0],
                ["progress-indicator-inderterminate-bar-bar-regular-right.png", 1.0, 25.0]
            ],
            PatternIsHorizontal),

        themeValues =
        [
            [@"bezel-color", bezelColor],
            [@"inderterminate-bar-color", barColor]
        ];

    [self registerThemeValues:themeValues forView:progressBar];

    return progressBar;
}

+ (CPProgressIndicator)themedSpinningProgressIndicator
{
    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0,0,64,64)];
    [progressBar setStyle:CPProgressIndicatorSpinningStyle];

    var spinningMini = PatternColor(@"progress-indicator-spinning-style-mini.gif", 16.0, 16.0),
        spinningSmall = PatternColor(@"progress-indicator-spinning-style-small.gif", 32.0, 32.0),
        spinningRegular = PatternColor(@"progress-indicator-spinning-style-regular.gif", 64.0, 64.0),

        themeValues =
        [
            [@"spinning-mini-gif", spinningMini],
            [@"spinning-small-gif", spinningSmall],
            [@"spinning-regular-gif", spinningRegular]
        ];

    [self registerThemeValues:themeValues forView:progressBar];

    return progressBar;
}

+ (CPBox)themedBox
{
    var box = [[CPBox alloc] initWithFrame:CGRectMake(0,0,100,100)],

        themeValues =
        [
            [@"background-color", [CPColor colorWithHexString:@"E4E4E4"]],
            [@"border-width", 1.0],
            [@"border-color", [CPColor colorWithHexString:@"B7B7B7"]],
            [@"corner-radius", 3.0],
            [@"inner-shadow-offset", CPSizeMakeZero()],
            [@"inner-shadow-color", [CPColor blackColor]],
            [@"inner-shadow-size", 6.0],
            [@"content-margin", CPSizeMakeZero()]
        ];

    [self registerThemeValues:themeValues forView:box];

    return box;
}

+ (CPLevelIndicator)themedLevelIndicator
{
    var levelIndicator = [[CPLevelIndicator alloc] initWithFrame:CGRectMake(0,0,100,100)],

        bezelColor = PatternColor(
        [
            [@"level-indicator-bezel-left.png", 3.0, 18.0],
            [@"level-indicator-bezel-center.png", 1.0, 18.0],
            [@"level-indicator-bezel-right.png", 3.0, 18.0]
        ]),

        emptyColor = PatternColor(
        [
            [@"level-indicator-segment-empty-left.png", 3.0, 17.0],
            [@"level-indicator-segment-empty-center.png", 1.0, 17.0],
            [@"level-indicator-segment-empty-right.png", 3.0, 17.0]
        ]),

        normalColor = PatternColor(
        [
            [@"level-indicator-segment-normal-left.png", 3.0, 17.0],
            [@"level-indicator-segment-normal-center.png", 1.0, 17.0],
            [@"level-indicator-segment-normal-right.png", 3.0, 17.0]
        ]),

        warningColor = PatternColor(
        [
            [@"level-indicator-segment-warning-left.png", 3.0, 17.0],
            [@"level-indicator-segment-warning-center.png", 1.0, 17.0],
            [@"level-indicator-segment-warning-right.png", 3.0, 17.0]
        ]),

        criticalColor = PatternColor(
        [
            [@"level-indicator-segment-critical-left.png", 3.0, 17.0],
            [@"level-indicator-segment-critical-center.png", 1.0, 17.0],
            [@"level-indicator-segment-critical-right.png", 3.0, 17.0]
        ]);


        themeValues =
        [
            [@"bezel-color",    bezelColor],
            [@"color-empty",    emptyColor],
            [@"color-normal",   normalColor],
            [@"color-warning",  warningColor],
            [@"color-critical", criticalColor],
            [@"spacing",        1.0]
        ];

    [self registerThemeValues:themeValues forView:levelIndicator];

    return levelIndicator;
}

+ (CPShadowView)themedShadowView
{
    var shadowView = [[CPShadowView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 100.0)],

        lightColor = PatternColor(
            [
                [@"shadow-view-light-top-left.png", 9.0, 9.0],
                [@"shadow-view-light-top.png", 1.0, 9.0],
                [@"shadow-view-light-top-right.png", 9.0, 9.0],
                [@"shadow-view-light-left.png", 9.0, 1.0],
                nil,
                [@"shadow-view-light-right.png", 9.0, 1.0],
                [@"shadow-view-light-bottom-left.png", 9.0, 9.0],
                [@"shadow-view-light-bottom.png", 1.0, 9.0],
                [@"shadow-view-light-bottom-right.png", 9.0, 9.0]
            ]),

        heavyColor = PatternColor(
            [
                [@"shadow-view-heavy-top-left.png", 17.0, 17.0],
                [@"shadow-view-heavy-top.png", 1.0, 17.0],
                [@"shadow-view-heavy-top-right.png", 17.0, 17.0],
                [@"shadow-view-heavy-left.png", 17.0, 1.0],
                nil,
                [@"shadow-view-heavy-right.png", 17.0, 1.0],
                [@"shadow-view-heavy-bottom-left.png", 17.0, 17.0],
                [@"shadow-view-heavy-bottom.png", 1.0, 17.0],
                [@"shadow-view-heavy-bottom-right.png", 17.0, 17.0]
            ]),

        themedShadowViewValues =
            [
                [@"bezel-color",        lightColor,                         CPThemeStateShadowViewLight],
                [@"bezel-color",        heavyColor,                         CPThemeStateShadowViewHeavy],

                [@"content-inset",      CGInsetMake(3.0, 3.0, 5.0, 3.0),    CPThemeStateShadowViewLight],
                [@"content-inset",      CGInsetMake(5.0, 7.0, 5.0, 7.0),    CPThemeStateShadowViewHeavy]
            ];

        [self registerThemeValues:themedShadowViewValues forView:shadowView];

        return shadowView;
}

+ (CPBrowser)themedBrowser
{
    var browser = [[CPBrowser alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 100.0)],

        imageResize = PatternImage(@"browser-image-resize-control.png", 15.0, 14.0),
        imageLeaf = PatternImage(@"browser-image-leaf.png", 9.0, 9.0),
        imageLeafPressed = PatternImage(@"browser-image-leaf-pressed.png", 9.0, 9.0),

        themedBrowser = [
            ["image-control-resize", imageResize],
            ["image-control-leaf", imageLeaf],
            ["image-control-leaf-pressed", imageLeafPressed]
        ];

    [self registerThemeValues:themedBrowser forView:browser];

    return browser;
}

+ (_CPModalWindowView)themedModalWindowView
{
    var modalWindowView = [[_CPModalWindowView alloc] initWithFrame:CGRectMake(0,0,400,300) styleMask:_CPModalWindowView];

    var bezelColor = PatternColor(
        [
            ["window-popup-top-left.png", 10.0, 10.0],
            ["window-popup-top-center.png", 1.0, 10.0],
            ["window-popup-top-right.png", 10.0, 10.0],
            ["window-popup-center-left.png", 10.0, 1.0],
            ["window-popup-center-center.png", 1.0, 1.0],
            ["window-popup-center-right.png", 10.0, 1.0],
            ["window-popup-bottom-left.png", 10.0, 71.0],
            ["window-popup-bottom-center.png", 1.0, 71.0],
            ["window-popup-bottom-right.png", 10.0, 71.0]
        ]),

        themeValues =
        [
            [@"bezel-color", bezelColor]
        ];

    [self registerThemeValues:themeValues forView:modalWindowView];

    return modalWindowView;
}

+ (_CPWindowView)themedWindowView
{
    var windowView = [[_CPWindowView alloc] initWithFrame:CGRectMakeZero()],

    sheetShadow = PatternColor(@"window-attached-sheet-shadow.png", 9, 8),
    resizeIndicator = PatternImage(@"window-resize-indicator.png", 12, 12),

    shadowColor = PatternColor(
        [
            [@"window-shadow-0.png", 20.0, 19.0],
            [@"window-shadow-1.png", 1.0, 19.0],
            [@"window-shadow-2.png", 19.0, 19.0],
            [@"window-shadow-3.png", 20.0, 1.0],
            [@"window-shadow-4.png", 1.0, 1.0],
            [@"window-shadow-5.png", 19.0, 1.0],
            [@"window-shadow-6.png", 20.0, 18.0],
            [@"window-shadow-7.png", 1.0, 18.0],
            [@"window-shadow-8.png", 19.0, 18.0],
        ]);

    themedWindowViewValues =
        [
            [@"shadow-inset",                   CGInsetMake(10.0, 19.0, 10.0, 20.0)],
            [@"shadow-distance",                5.0],
            [@"window-shadow-color",            shadowColor],
            [@"resize-indicator",               resizeIndicator],
            [@"attached-sheet-shadow-color",    sheetShadow],
            [@"size-indicator",                 CGSizeMake(12, 12)]
        ];

    [self registerThemeValues:themedWindowViewValues forView:windowView];

    return windowView;
}

+ (_CPHUDWindowView)themedHUDWindowView
{
    var HUDWindowView = [[_CPHUDWindowView alloc] initWithFrame:CGRectMake(0,0,250,150) styleMask:CPHUDBackgroundWindowMask | CPClosableWindowMask];
    [HUDWindowView setTitle:@"HUDWindow"];

    var HUDBezelColor = PatternColor(
            [
                ["HUD/window-bezel-top-left.png", 5.0, 5.0],
                ["HUD/window-bezel-top-center.png", 1.0, 5.0],
                ["HUD/window-bezel-top-right.png", 5.0, 5.0],
                ["HUD/window-bezel-center-left.png", 5.0, 1.0],
                ["HUD/window-bezel-center-center.png", 1.0, 1.0],
                ["HUD/window-bezel-center-right.png", 5.0, 1.0],
                ["HUD/window-bezel-bottom-left.png", 5.0, 5.0],
                ["HUD/window-bezel-bottom-center.png", 1.0, 5.0],
                ["HUD/window-bezel-bottom-right.png", 5.0, 5.0]
            ]),

        closeImage = PatternImage(@"HUD/window-close.png", 18.0, 18.0),

        closeActiveImage = PatternImage(@"HUD/window-close-active.png", 18.0, 18.0),

        themeValues =
            [
                [@"close-image-size",           CPSizeMake(18.0, 18.0)],
                [@"close-image-origin",         CPPointMake(6.0,4.0)],
                [@"close-image",                closeImage],
                [@"close-active-image",         closeActiveImage],
                [@"bezel-color",                HUDBezelColor],
                [@"title-font",                 [CPFont systemFontOfSize:14]],
                [@"title-text-color",           [CPColor colorWithWhite:255.0 / 255.0 alpha:1]],
                [@"title-text-color",           [CPColor colorWithWhite:255.0 / 255.0 alpha:1], CPThemeStateKeyWindow],
                [@"title-text-shadow-color",    [CPColor blackColor]],
                [@"title-text-shadow-offset",   CGSizeMake(0.0, 1.0)],
                [@"title-alignment",            CPCenterTextAlignment],
                [@"title-line-break-mode",      CPLineBreakByTruncatingTail],
                [@"title-vertical-alignment",   CPCenterVerticalTextAlignment],
                [@"title-bar-height",           26],
            ];

    [self registerThemeValues:themeValues forView:HUDWindowView inherit:themedWindowViewValues];

    return HUDWindowView;
}

+ (_CPTexturedWindowHeadView)themedWindowHeadView
{
    var windowHeadView = [[_CPTexturedWindowHeadView alloc] initWithFrame:CGRectMake(0,0,120,32)],

        bezelColor = PatternColor(
        [
            [@"window-standard-head-left.png", 5.0, 31.0],
            [@"window-standard-head-center.png", 1.0, 31.0],
            [@"window-standard-head-right.png", 5.0, 31.0]
        ],  PatternIsHorizontal),

        solidColor = PatternColor(
            [
                [@"window-standard-head-solid-top-left.png", 5.0, 1.0],
                [@"window-standard-head-solid-top-center.png", 1.0, 1.0],
                [@"window-standard-head-solid-top-right.png", 5.0, 1.0],
                [@"window-standard-head-solid-center-left.png", 5.0, 1.0],
                [@"window-standard-head-solid-center-center.png", 1.0, 1.0],
                [@"window-standard-head-solid-center-right.png", 5.0, 1.0],
                [@"window-standard-head-solid-bottom-left.png", 5.0, 1.0],
                [@"window-standard-head-solid-bottom-center.png", 1.0, 1.0],
                [@"window-standard-head-solid-bottom-right.png", 5.0, 1.0]
            ]
        ),

        themeValues =
            [
                [@"gradient-height", 31.0],
                [@"bezel-color", bezelColor],
                [@"solid-color", solidColor]
            ];

    [self registerThemeValues:themeValues forView:windowHeadView];

    return windowHeadView;
}

+ (_CPStandardWindowView)themedStandardWindowView
{
    var standardWindowView = [[_CPStandardWindowView alloc] initWithFrame:CGRectMake(0,0,200,300) styleMask:CPClosableWindowMask],

        bezelColor = PatternColor(
        [
            [@"window-standard-top-left.png",5,5],
            [@"window-standard-top-center.png",1,5],
            [@"window-standard-top-right.png",5,5],
            [@"window-standard-center-left.png",5,1],
            [@"window-standard-center-center.png",1,1],
            [@"window-standard-center-right.png",5,1],
            [@"window-standard-bottom-left.png",5,5],
            [@"window-standard-bottom-center.png",1,5],
            [@"window-standard-bottom-right.png",5,5]
        ]),

        closeButtonImage =                  PatternImage(@"window-standard-close-button.png", 16, 16),
        closeButtonImageHighlighted =       PatternImage(@"window-standard-button-highlighted.png",16, 16),
        unsavedButtonImage =                PatternImage(@"window-standard-button-unsaved.png",16, 16),
        unsavedButtonImageHighlighted =     PatternImage(@"window-standard-close-button-unsaved-highlighted.png",16, 16),
        minimizeButtonImage =               PatternImage(@"window-standard-minimize-button.png",16, 16),
        minimizeButtonImageHighlighted =    PatternImage(@"window-standard-minimize-button-highlighted.png",16, 16),

        sheetShadow = PatternColor(@"window-attached-sheet-shadow.png", 9, 8),
        resizeIndicator = PatternImage(@"window-resize-indicator.png", 12, 12),

        themeValues =
            [
                [@"title-font",                 [CPFont boldSystemFontOfSize:CPFontCurrentSystemSize]],
                [@"title-text-color",           [CPColor colorWithWhite:22.0 / 255.0 alpha:0.75]],
                [@"title-text-color",           [CPColor colorWithWhite:22.0 / 255.0 alpha:1], CPThemeStateKeyWindow],
                [@"title-text-shadow-color",    [CPColor whiteColor]],
                [@"title-text-shadow-offset",   CGSizeMake(0.0, 1.0)],
                [@"title-alignment",            CPCenterTextAlignment],
                // FIXME: Make this to CPLineBreakByTruncatingMiddle once it's implemented.
                [@"title-line-break-mode",      CPLineBreakByTruncatingTail],
                [@"title-vertical-alignment",   CPCenterVerticalTextAlignment],
                [@"title-bar-height",           31],

                [@"divider-color",              [CPColor colorWithHexString:@"858585"]],
                [@"body-color",                 bezelColor],
                [@"title-bar-height",           31],

                [@"unsaved-image-button"                ,unsavedButtonImage],
                [@"unsaved-image-highlighted-button"    ,unsavedButtonImageHighlighted],
                [@"close-image-button"                  ,closeButtonImage],
                [@"close-image-highlighted-button"      ,closeButtonImageHighlighted],
                [@"minimize-image-button"               ,minimizeButtonImage],
                [@"minimize-image-highlighted-button"   ,minimizeButtonImageHighlighted],

                [@"close-image-size",                   CPSizeMake(16.0, 16.0)],
                [@"close-image-origin",                 CPPointMake(8.0, 10.0)],

                [@"resize-indicator",               resizeIndicator],
                [@"attached-sheet-shadow-color",    sheetShadow],
                [@"size-indicator",                 CGSizeMake(12, 12)]
            ];

    [self registerThemeValues:themeValues forView:standardWindowView inherit:themedWindowViewValues];

    return standardWindowView;
}

+ (_CPDocModalWindowView)themedDocModalWindowView
{
    var docModalWindowView = [[_CPDocModalWindowView alloc] initWithFrame:CGRectMake(0,0,200,300) styleMask:nil],

        bezelColor = PatternColor(
        [
            [@"window-standard-top-left.png",5,5],
            [@"window-standard-top-center.png",1,5],
            [@"window-standard-top-right.png",5,5],
            [@"window-standard-center-left.png",5,1],
            [@"window-standard-center-center.png",1,1],
            [@"window-standard-center-right.png",5,1],
            [@"window-standard-bottom-left.png",5,5],
            [@"window-standard-bottom-center.png",1,5],
            [@"window-standard-bottom-right.png",5,5]
        ]),

        sheetShadow = PatternColor(@"window-attached-sheet-shadow.png", 9, 8),

        themeValues =
            [
                [@"body-color",                     bezelColor],
                [@"height-shadow",                  8],
                [@"attached-sheet-shadow-color",    sheetShadow]
            ];

    [self registerThemeValues:themeValues forView:docModalWindowView inherit:themedWindowViewValues];

    return docModalWindowView;
}

+ (_CPBorderlessBridgeWindowView)themedBordelessBridgeWindowView
{
    var bordelessBridgeWindowView = [[_CPBorderlessBridgeWindowView alloc] initWithFrame:CGRectMake(0,0,0,0)],

        toolbarBackgroundColor = PatternColor(
        [
            nil,
            [@"toolbar-background-center.png", 1.0, 58.0],
            [@"toolbar-background-bottom.png", 1.0, 1.0]
        ],  PatternIsVertical)

        themeValues =
        [
            [@"toolbar-background-color", toolbarBackgroundColor]
        ];

    [self registerThemeValues:themeValues forView:bordelessBridgeWindowView inherit:themedWindowViewValues];

    return bordelessBridgeWindowView;
}

+ (_CPToolbarView)themedToolbarView
{
    var toolbarView = [[_CPToolbarView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 59.0)],

        toolbarExtraItemsImage = PatternImage(@"toolbar-view-extra-items-image.png", 10.0, 15.0),
        toolbarExtraItemsAlternateImage = PatternImage(@"toolbar-view-extra-items-alternate-image.png", 10.0, 15.0),
        toolbarSeparatorColor = PatternColor([
                [@"toolbar-item-separator-0.png", 2.0, 26.0],
                [@"toolbar-item-separator-1.png", 2.0, 1.0],
                [@"toolbar-item-separator-2.png", 2.0, 26.0]
            ], PatternIsVertical),

        themeValues =
        [
            [@"extra-item-extra-image",                 toolbarExtraItemsImage],
            [@"extra-item-extra-alternate-image",       toolbarExtraItemsAlternateImage],
            [@"item-margin",                            10.0],
            [@"extra-item-width",                       20.0],
            [@"content-inset",                          CGInsetMake(4.0, 4.0, 4.0, 10)],
            [@"regular-size-height",                    59.0],
            [@"small-size-height",                      46.0],
            [@"image-item-separator-color",             toolbarSeparatorColor],
            [@"image-item-separator-size",              CGRectMake(0.0, 0.0, 2.0, 32.0)]
        ];


    [self registerThemeValues:themeValues forView:toolbarView];

    return toolbarView;
}

+ (_CPMenuItemMenuBarView)themedMenuItemMenuBarView
{
    var menuItemMenuBarView = [[_CPMenuItemMenuBarView alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)],

        selectionColor = PatternColor(@"menu-bar-window-background-selected.png", 1.0, 28.0),

        themeValues =
        [
            [@"selection-color",                                        selectionColor],
            [@"submenu-indicator-color",                                [CPColor grayColor]],
            [@"menu-item-selection-color",                              [CPColor colorWithHexString:@"5C85D8"]],
            [@"menu-item-text-shadow-color",                            [CPColor colorWithCalibratedRed:26.0 / 255.0 green: 73.0 / 255.0 blue:109.0 / 255.0 alpha:1.0]],
            [@"horizontal-margin",                                      8.0],
            [@"submenu-indicator-margin",                               3.0],
            [@"vertical-margin",                                        4.0]
        ];

    [self registerThemeValues:themeValues forView:menuItemMenuBarView];

    return menuItemMenuBarView;
}

+ (_CPMenuItemStandardView)themedMenuItemStandardView
{
    var menuItemStandardView = [[_CPMenuItemStandardView alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)],

        menuItemDefaultOnStateImage = PatternImage(@"menu-item-on-state.png", 14.0, 14.0),
        menuItemDefaultOnStateHighlightedImage = PatternImage(@"menu-item-on-state-highlighted.png", 14.0, 14.0),

        themeValues =
        [
            [@"submenu-indicator-color",                                    [CPColor grayColor]],
            [@"menu-item-selection-color",                                  [CPColor colorWithHexString:@"5C85D8"]],
            [@"menu-item-text-shadow-color",                                [CPColor colorWithCalibratedRed:26.0 / 255.0 green: 73.0 / 255.0 blue:109.0 / 255.0 alpha:1.0]],
            [@"menu-item-default-off-state-image",                          nil],
            [@"menu-item-default-off-state-highlighted-image",              nil],
            [@"menu-item-default-on-state-image",                           menuItemDefaultOnStateImage],
            [@"menu-item-default-on-state-highlighted-image",               menuItemDefaultOnStateHighlightedImage],
            [@"menu-item-default-mixed-state-image",                        nil],
            [@"menu-item-default-mixed-state-highlighted-image",            nil],
            [@"left-margin",                                                3.0],
            [@"right-margin",                                               17.0],
            [@"state-column-width",                                         14.0],
            [@"indentation-width",                                          17.0],
            [@"vertical-margin",                                            4.0],
            [@"right-columns-margin",                                       30.0]
        ];

    [self registerThemeValues:themeValues forView:menuItemStandardView];

    return menuItemStandardView;
}

+ (_CPMenuView)themedMenuView
{
    var menuView = [[_CPMenuView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 100.0)],


        menuWindowMoreAboveImage = PatternImage(@"menu-window-more-above.png", 38.0, 18.0),
        menuWindowMoreBelowImage = PatternImage(@"menu-window-more-below.png", 38.0, 18.0),
        generalIconNew = PatternImage(@"menu-general-icon-new.png", 16.0, 16.0),
        generalIconNewHighlighted = PatternImage(@"menu-general-icon-new-highlighted.png", 16.0, 16.0),
        generalIconOpen = PatternImage(@"menu-general-icon-open.png", 16.0, 16.0),
        generalIconOpenHighlighted = PatternImage(@"menu-general-icon-open-highlighted.png", 16.0, 16.0),
        generalIconSave = PatternImage(@"menu-general-icon-save.png", 16.0, 16.0),
        generalIconSaveHighlighted = PatternImage(@"menu-general-icon-save-highlighted.png", 16.0, 16.0),

        menuWindowPopUpBackgroundStyleColor = PatternColor(
            [
                [@"menu-window-rounded-0.png", 7.0, 7.0],
                [@"menu-window-1.png", 1.0, 7.0],
                [@"menu-window-rounded-2.png", 7.0, 7.0],
                [@"menu-window-3.png", 7.0, 1.0],
                [@"menu-window-4.png", 1.0, 1.0],
                [@"menu-window-5.png", 7.0, 1.0],
                [@"menu-window-rounded-6.png", 7.0, 7.0],
                [@"menu-window-7.png", 1.0, 7.0],
                [@"menu-window-rounded-8.png", 7.0, 7.0]
            ]
        ),

        menuWindowMenuBarBackgroundStyleColor = PatternColor(
            [
                [@"menu-window-3.png", 7.0, 0.0],
                [@"menu-window-4.png", 1.0, 0.0],
                [@"menu-window-5.png", 7.0, 0.0],
                [@"menu-window-3.png", 7.0, 1.0],
                [@"menu-window-4.png", 1.0, 1.0],
                [@"menu-window-5.png", 7.0, 1.0],
                [@"menu-window-rounded-6.png", 7.0, 7.0],
                [@"menu-window-7.png", 1.0, 7.0],
                [@"menu-window-rounded-8.png", 7.0, 7.0]
            ]
        ),

        menuBarWindowBackgroundColor = PatternColor(@"menu-bar-window-background.png", 1.0, 30.0),

        themeValues =
        [
            [@"menu-window-more-above-image",                       menuWindowMoreAboveImage],
            [@"menu-window-more-below-image",                       menuWindowMoreBelowImage],
            [@"menu-window-pop-up-background-style-color",          menuWindowPopUpBackgroundStyleColor],
            [@"menu-window-menu-bar-background-style-color",        menuWindowMenuBarBackgroundStyleColor],
            [@"menu-window-margin-inset",                           CGInsetMake(5.0, 1.0, 5.0, 1.0)],
            [@"menu-window-scroll-indicator-height",                16.0],

            [@"menu-bar-window-background-color",                   menuBarWindowBackgroundColor],
            [@"menu-bar-window-font",                               [CPFont boldSystemFontOfSize:[CPFont systemFontSize]]],
            [@"menu-bar-window-height",                             30.0],
            [@"menu-bar-window-margin",                             10.0],
            [@"menu-bar-window-left-margin",                        10.0],
            [@"menu-bar-window-right-margin",                       10.0],

            [@"menu-bar-text-color",                                [CPColor colorWithRed:0.051 green:0.2 blue:0.275 alpha:1.0]],
            [@"menu-bar-title-color",                               [CPColor colorWithRed:0.051 green:0.2 blue:0.275 alpha:1.0]],
            [@"menu-bar-text-shadow-color",                         [CPColor whiteColor]],
            [@"menu-bar-title-shadow-color",                        [CPColor whiteColor]],
            [@"menu-bar-highlight-color",                           [CPColor colorWithCalibratedRed:94.0 / 255.0 green:130.0 / 255.0 blue:186.0 / 255.0 alpha:1.0]],
            [@"menu-bar-highlight-text-color",                      [CPColor whiteColor]],
            [@"menu-bar-highlight-text-shadow-color",               [CPColor blackColor]],
            [@"menu-bar-height",                                    30.0],
            [@"menu-bar-icon-image",                                nil],
            [@"menu-bar-icon-image-alpha-value",                    1.0],

            [@"menu-general-icon-new",                              generalIconNew],
            [@"menu-general-icon-new",                              generalIconNewHighlighted, CPThemeStateHighlighted],

            [@"menu-general-icon-save",                             generalIconSave],
            [@"menu-general-icon-save",                             generalIconSaveHighlighted, CPThemeStateHighlighted],

            [@"menu-general-icon-open",                             generalIconOpen],
            [@"menu-general-icon-open",                             generalIconOpenHighlighted, CPThemeStateHighlighted]
        ];


    [self registerThemeValues:themeValues forView:menuView];

    return menuView;
}

@end


@implementation Aristo2HUDThemeDescriptor : BKThemeDescriptor
{
}

+ (CPString)themeName
{
    return @"Aristo2-HUD";
}

+ (CPArray)themeShowcaseExcludes
{
    return ["alert"];
}

+ (CPColor)defaultShowcaseBackgroundColor
{
    return [CPColor blackColor];
}

+ (CPArray)defaultThemeOverridesAddedTo:(CPArray)themeValues
{
    var overrides = [CPArray arrayWithObjects:
            [@"text-color",         [CPColor whiteColor]],
            [@"text-color",         [CPColor colorWithCalibratedWhite:1.0 alpha:0.6], CPThemeStateDisabled],
            [@"text-shadow-color",  [CPColor blackColor]],
            [@"text-shadow-color",  [CPColor blackColor], CPThemeStateDisabled],
            [@"text-shadow-offset", CGSizeMake(-1.0, -1.0)]
        ];

    if (themeValues)
        [overrides addObjectsFromArray:themeValues];

    return overrides;
}

+ (CPPopUpButton)themedSegmentedControl
{
    var segmentedControl = [Aristo2ThemeDescriptor makeSegmentedControl];

    [self registerThemeValues:[self defaultThemeOverridesAddedTo:nil] forView:segmentedControl inherit:themedSegmentedControlValues];

    return segmentedControl;
}

+ (CPButton)button
{
    var button = [Aristo2ThemeDescriptor makeButton];

    [self registerThemeValues:[self defaultThemeOverridesAddedTo:nil] forView:button inherit:themedButtonValues];

    return button;
}

+ (CPButton)themedStandardButton
{
    var button = [self button];

    [button setTitle:@"Cancel"];

    return button;
}

+ (CPButton)themedDefaultButton
{
    var button = [self button];

    [button setTitle:@"OK"];
    [button setThemeState:CPThemeStateDefault];

    return button;
}

// + (CPScroller)themedVerticalScroller
// {
//     var scroller = [Aristo2ThemeDescriptor makeVerticalScroller],
//         overrides =
//         [
//             [@"knob-color", nil, CPThemeStateVertical | CPThemeStateDisabled]
//         ];
//
//     [self registerThemeValues:[self defaultThemeOverridesAddedTo:overrides] forView:scroller inherit:themedVerticalScrollerValues];
//
//     return scroller;
// }
//
// + (CPScroller)themedHorizontalScroller
// {
//     var scroller = [Aristo2ThemeDescriptor makeHorizontalScroller],
//         overrides =
//         [
//             [@"knob-color", nil, CPThemeStateDisabled]
//         ];
//
//     [self registerThemeValues:[self defaultThemeOverridesAddedTo:overrides] forView:scroller inherit:themedHorizontalScrollerValues];
//
//     return scroller;
// }

+ (CPSlider)themedHorizontalSlider
{
    var slider = [Aristo2ThemeDescriptor makeHorizontalSlider];

    [self registerThemeValues:[self defaultThemeOverridesAddedTo:nil] forView:slider inherit:themedHorizontalSliderValues];

    return slider;
}

+ (CPSlider)themedVerticalSlider
{
    var slider = [Aristo2ThemeDescriptor makeVerticalSlider];

    [self registerThemeValues:[self defaultThemeOverridesAddedTo:nil] forView:slider inherit:themedVerticalSliderValues];

    return slider;
}

+ (CPSlider)themedCircularSlider
{
    var slider = [Aristo2ThemeDescriptor makeCircularSlider];

    [self registerThemeValues:[self defaultThemeOverridesAddedTo:nil] forView:slider inherit:themedCircularSliderValues];

    return slider;
}

+ (CPAlert)themedAlert
{
    var alert = [CPAlert new],

        hudSpecificValues =
        [
            [@"message-text-color",             [CPColor whiteColor]],
            [@"informative-text-color",         [CPColor whiteColor]],
            [@"suppression-button-text-color",  [CPColor whiteColor]],
        ];

    [self registerThemeValues:hudSpecificValues forView:alert inherit:themedAlertValues];

    return [alert themeView];
}

@end
