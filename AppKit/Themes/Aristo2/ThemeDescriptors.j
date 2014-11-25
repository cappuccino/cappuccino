/*
 * ThemeDescriptors.j
 * AppKit
 *
 * Created by Antoine Mercadal
 * Copyright 2012 <primalmotion@archipelproject.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <Foundation/CPObject.j>
@import <Foundation/CPGeometry.j>
@import <AppKit/CPApplication.j>
@import <AppKit/CPBrowser.j>
@import <AppKit/CPButton.j>
@import <AppKit/CPButtonBar.j>
@import <AppKit/CPCheckBox.j>
@import <AppKit/CPComboBox.j>
@import <AppKit/CPColorWell.j>
@import <AppKit/CPDatePicker.j>
@import <AppKit/CPLevelIndicator.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPProgressIndicator.j>
@import <AppKit/CPRadio.j>
@import <AppKit/CPRuleEditor.j>
@import <AppKit/CPScroller.j>
@import <AppKit/CPScrollView.j>
@import <AppKit/CPSegmentedControl.j>
@import <AppKit/CPSlider.j>
@import <AppKit/CPSplitView.j>
@import <AppKit/CPStepper.j>
@import <AppKit/CPTableHeaderView.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPTokenField.j>
@import <AppKit/CPWindow.j>
@import <AppKit/CPAlert.j>
@import <AppKit/_CPToolTip.j>
@import <AppKit/CPPopover.j>

var themedButtonValues = nil,
    themedTextFieldValues = nil,
    themedVerticalScrollerValues = nil,
    themedHorizontalScrollerValues = nil,
    themedSegmentedControlValues = nil,
    themedHorizontalSliderValues = nil,
    themedVerticalSliderValues = nil,
    themedCircularSliderValues = nil,
    themedAlertValues = nil,
    themedWindowViewValues = nil,
    themedProgressIndicator = nil,
    themedIndeterminateProgressIndicator = nil,
    themedCheckBoxValues = nil,
    themedRadioButtonValues = nil,
    regularTextColor = [CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0],
    regularTextShadowColor = [CPColor colorWithCalibratedWhite:1.0 alpha:0.2],
    regularDisabledTextColor = [CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:0.6],
    regularDisabledTextShadowColor = [CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:0.6],

    defaultTextColor = [CPColor whiteColor],
    defaultTextShadowColor = [CPColor colorWithCalibratedWhite:0.0 alpha:0.3],
    defaultDisabledTextColor = regularDisabledTextColor,
    defaultDisabledTextShadowColor = regularDisabledTextShadowColor,

    placeholderColor = regularDisabledTextColor;

@implementation Aristo2ThemeDescriptor : BKThemeDescriptor

+ (CPString)themeName
{
    return @"Aristo2";
}

+ (CPArray)themeShowcaseExcludes
{
    return ["themedAlert",
            "themedMenuView",
            "themedMenuItemStandardView",
            "themedMenuItemMenuBarView",
            "themedToolbarView",
            "themedBorderlessBridgeWindowView",
            "themedWindowView",
            "themedBrowser",
            "themedRuleEditor",
            "themedTableDataView",
            "themedCornerview",
            "themedTokenFieldTokenCloseButton"];
}

+ (CPButton)makeButton
{
    return [[CPButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 25)];
}

+ (CPButton)button
{
    var button = [self makeButton],

        // RoundRect
        regularBezelColor = PatternColor(
            "{style}button-bezel{state}{position}.png",
            {
                styles: ["", "default"],
                states: ["", "highlighted", "disabled"],
                width: 4.0,
                height: 24.0,
                orientation: PatternIsHorizontal
            }),

        smallBezelColor = PatternColor(
            "{style}button-bezel{state}{position}.png",
            {
                styles: ["", "default"],
                states: ["", "highlighted", "disabled"],
                width: 3.0,
                height: 20.0,
                orientation: PatternIsHorizontal
            }),
        miniBezelColor = PatternColor(
            "{style}button-bezel{state}{position}.png",
            {
                styles: ["", "default"],
                states: ["", "highlighted", "disabled"],
                width: 3.0,
                height: 16.0,
                orientation: PatternIsHorizontal
            }),

        // Rounded
        roundedBezelColor = PatternColor(
            "{style}button-bezel-rounded{state}{position}.png",
            {
                styles: ["", "default"],
                states: ["", "highlighted", "disabled"],
                width: 12.0,
                height: 24.0,
                orientation: PatternIsHorizontal
            });

    // Global
    themedButtonValues =
        [
            [@"font",                   [CPFont boldSystemFontOfSize:12.0], CPThemeStateBordered],
            [@"text-color",             regularTextColor],
            [@"text-shadow-color",      regularTextShadowColor],
            [@"text-shadow-color",      regularTextShadowColor,             CPThemeStateBordered],
            [@"text-color",             regularDisabledTextColor,           CPThemeStateDisabled],

            [@"text-color",             defaultTextColor,                   [CPThemeStateBordered, CPThemeStateDefault]],
            [@"text-color",             defaultTextColor,                   CPThemeStateDefault],
            [@"text-shadow-color",      defaultTextShadowColor,             [CPThemeStateBordered, CPThemeStateDefault]],

            [@"text-color",             defaultDisabledTextColor,           [CPThemeStateDefault,   CPThemeStateDisabled]],
            [@"text-shadow-color",      defaultDisabledTextShadowColor,     [CPThemeStateDefault, CPThemeStateDisabled]],

            [@"text-shadow-offset",     CGSizeMake(0.0, 0.0),               [CPThemeStateDefault, CPThemeStateDisabled]],
            [@"text-shadow-offset",     CGSizeMake(0.0, 1.0),               CPThemeStateBordered],

            [@"line-break-mode",    CPLineBreakByTruncatingTail],

            // RoundRect CPThemeStateControlSizeRegular
            [@"bezel-color",
                regularBezelColor["@"]["@"],
                CPThemeStateBordered],
            [@"bezel-color",
                regularBezelColor["@"]["highlighted"],
                [CPThemeStateBordered, CPThemeStateHighlighted]],
            [@"bezel-color",
                regularBezelColor["@"]["disabled"],
                [CPThemeStateBordered, CPThemeStateDisabled]],
            [@"bezel-color",
                regularBezelColor["default"]["@"],
                [CPThemeStateBordered, CPThemeStateDefault]],
            [@"bezel-color",
                regularBezelColor["default"]["highlighted"],
                [CPThemeStateBordered, CPThemeStateHighlighted, CPThemeStateDefault]],
            [@"bezel-color",
                regularBezelColor["default"]["disabled"],
                [CPThemeStateBordered, CPThemeStateDefault, CPThemeStateDisabled]],

            [@"content-inset",              CGInsetMake(0.0, 7.0, 0.0, 7.0),    CPThemeStateBordered],
            [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 3.0, 0.0, 0.0),     CPThemeStateBordered],

            // RoundRect CPThemeStateControlSizeSmall
            [@"bezel-color",
                smallBezelColor["@"]["@"],
                [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
            [@"bezel-color",
                smallBezelColor["@"]["highlighted"],
                [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateHighlighted]],
            [@"bezel-color",
                smallBezelColor["@"]["disabled"],
                [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],
            [@"bezel-color",
                smallBezelColor["default"]["@"],
                [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDefault]],
            [@"bezel-color",
                smallBezelColor["default"]["highlighted"],
                [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateHighlighted, CPThemeStateDefault]],
            [@"bezel-color",
                smallBezelColor["default"]["disabled"],
                [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateDisabled]],

            [@"content-inset",              CGInsetMake(0.0, 5.0, 0.0, 5.0),    [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
            [@"nib2cib-adjustment-frame",   CGRectMake(-3.0, 6.0, 0.0, 0.0),    [CPThemeStateControlSizeSmall, CPThemeStateBordered]],

            // RoundRect CPThemeStateControlSizeMini
            [@"bezel-color",
                miniBezelColor["@"]["@"],
                [CPThemeStateControlSizeMini, CPThemeStateBordered]],
            [@"bezel-color",
                miniBezelColor["@"]["highlighted"],
                [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateHighlighted]],
            [@"bezel-color",
                miniBezelColor["@"]["disabled"],
                [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled]],
            [@"bezel-color",
                miniBezelColor["default"]["@"],
                [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDefault]],
            [@"bezel-color",
                miniBezelColor["default"]["highlighted"],
                [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateHighlighted, CPThemeStateDefault]],
            [@"bezel-color",
                miniBezelColor["default"]["disabled"],
                [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateDisabled]],

            [@"content-inset",              CGInsetMake(0.0, 2.0, 2.0, 2.0),    [CPThemeStateControlSizeMini, CPThemeStateBordered]],
            [@"nib2cib-adjustment-frame",   CGRectMake(0.0, 14.0, 0.0, 0.0),    [CPThemeStateControlSizeMini, CPThemeStateBordered]],

            // Rounded
            [@"bezel-color",
                roundedBezelColor["@"]["@"],
                [CPThemeStateBordered, CPButtonStateBezelStyleRounded]],
            [@"bezel-color",
                roundedBezelColor["@"]["highlighted"],
                [CPThemeStateBordered, CPThemeStateHighlighted, CPButtonStateBezelStyleRounded]],
            [@"bezel-color",
                roundedBezelColor["@"]["disabled"],
                [CPThemeStateBordered, CPThemeStateDisabled, CPButtonStateBezelStyleRounded]],
            [@"bezel-color",
                roundedBezelColor["default"]["@"],
                [CPThemeStateBordered, CPThemeStateDefault, CPButtonStateBezelStyleRounded]],
            [@"bezel-color",
                roundedBezelColor["default"]["highlighted"],
                [CPThemeStateBordered, CPThemeStateHighlighted, CPThemeStateDefault, CPButtonStateBezelStyleRounded]],
            [@"bezel-color",
                roundedBezelColor["default"]["disabled"],
                [CPThemeStateBordered, CPThemeStateDefault, CPThemeStateDisabled, CPButtonStateBezelStyleRounded]],

            [@"content-inset",  CGInsetMake(0.0, 10.0, 0.0, 10.0),              [CPThemeStateBordered, CPButtonStateBezelStyleRounded]],

            [@"min-size",       CGSizeMake(0.0, CPButtonDefaultHeight)],
            [@"max-size",       CGSizeMake(-1.0, CPButtonDefaultHeight)],
            [@"min-size",       CGSizeMake(0.0, 20.0),                          CPThemeStateControlSizeSmall],
            [@"max-size",       CGSizeMake(-1.0, 20.0),                         CPThemeStateControlSizeSmall],
            [@"min-size",       CGSizeMake(0.0, 16.0),                          CPThemeStateControlSizeMini],
            [@"max-size",       CGSizeMake(-1.0, 16.0),                         CPThemeStateControlSizeMini],

            [@"image-offset",   CPButtonImageOffset]
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
    [button setThemeState:[CPButtonStateBezelStyleRounded, CPThemeStateDefault]];

    return button;
}

+ (CPPopUpButton)themedPopUpButton
{
    var button = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 25.0) pullsDown:NO],
        regularColor = PatternColor(
            "popup-bezel{state}{position}.png",
            {
                states: ["", "disabled"],
                width: 3.0,
                height: 25.0,
                rightWidth: 24.0,
                orientation: PatternIsHorizontal
            }),

        smallColor = PatternColor(
            "popup-bezel{state}{position}.png",
            {
                states: ["", "disabled"],
                width: 3.0,
                height: 20.0,
                rightWidth: 19.0,
                orientation: PatternIsHorizontal
            }),

        miniColor = PatternColor(
            "popup-bezel{state}{position}.png",
            {
                states: ["", "disabled"],
                width: 3.0,
                height: 16.0,
                rightWidth: 15.0,
                orientation: PatternIsHorizontal
            }),

        themeValues =
        [
            // CPThemeStateControlSizeRegular
            [@"bezel-color",                regularColor["@"],                      CPThemeStateBordered],
            [@"bezel-color",                regularColor["disabled"],               [CPThemeStateBordered, CPThemeStateDisabled]],

            [@"content-inset",              CGInsetMake(0, 22.0 + 5.0, 0, 5.0),     CPThemeStateBordered],
            [@"font",                       [CPFont boldSystemFontOfSize:12.0]],
            [@"text-color",                 regularTextColor],
            [@"text-shadow-color",          regularTextShadowColor],

            [@"text-color",                 regularDisabledTextColor,               [CPThemeStateBordered, CPThemeStateDisabled]],
            [@"text-shadow-color",          regularDisabledTextShadowColor,         [CPThemeStateBordered, CPThemeStateDisabled]],

            [@"min-size",                   CGSizeMake(32.0, 25.0)],
            [@"max-size",                   CGSizeMake(-1.0, 25.0)],
            [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 1.0, -5.0, 0.0)],

            // CPThemeStateControlSizeSmall
            [@"bezel-color",                smallColor["@"],                        [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
            [@"bezel-color",                smallColor["disabled"],                 [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],

            [@"content-inset",              CGInsetMake(0, 17.0 + 4.0, 0, 4.0),     [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
            [@"font",                       [CPFont boldSystemFontOfSize:11.0]],

            [@"min-size",                   CGSizeMake(32.0, 20.0),                 CPThemeStateControlSizeSmall],
            [@"max-size",                   CGSizeMake(-1.0, 20.0),                 CPThemeStateControlSizeSmall],
            [@"nib2cib-adjustment-frame",   CGRectMake(3.0, 4.0, -6.0, 0.0),        CPThemeStateControlSizeSmall],

            // CPThemeStateControlSizeMini
            [@"bezel-color",                miniColor["@"],                         [CPThemeStateControlSizeMini, CPThemeStateBordered]],
            [@"bezel-color",                miniColor["disabled"],                  [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled]],

            [@"content-inset",              CGInsetMake(0, 15.0 + 4.0, 2.0, 4.0),   [CPThemeStateControlSizeMini, CPThemeStateBordered]],
            [@"font",                       [CPFont boldSystemFontOfSize:9.0]],

            [@"min-size",                   CGSizeMake(32.0, 16.0),                 CPThemeStateControlSizeMini],
            [@"max-size",                   CGSizeMake(-1.0, 16.0),                 CPThemeStateControlSizeMini],
            [@"nib2cib-adjustment-frame",   CGRectMake(1.0, 10.0, -3.0, 0.0),       CPThemeStateControlSizeMini]
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
            "pulldown-bezel{state}{position}.png",
            {
                states: ["", "disabled"],
                width: 3.0,
                height: 25.0,
                rightWidth: 24.0,
                orientation: PatternIsHorizontal
            }),

        themeValues =
        [
            [@"bezel-color", color["@"],        [CPPopUpButtonStatePullsDown, CPThemeStateBordered]],
            [@"bezel-color", color["disabled"], [CPPopUpButtonStatePullsDown, CPThemeStateBordered, CPThemeStateDisabled]],

            [@"content-inset",      CGInsetMake(0, 27.0 + 5.0, 0, 5.0), CPThemeStateBordered],
            [@"font",               [CPFont boldSystemFontOfSize:12.0]],
            [@"text-color",         regularTextColor],
            [@"text-shadow-color",  regularTextShadowColor],

            [@"text-color",         regularDisabledTextColor,       [CPThemeStateBordered, CPThemeStateDisabled]],
            [@"text-shadow-color",  regularDisabledTextShadowColor, [CPThemeStateBordered, CPThemeStateDisabled]],

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
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)],
        borderColor = [CPColor colorWithWhite:0.0 alpha:0.2],
        bottomCornerColor = PatternColor(@"scrollview-bottom-corner-color.png", 15.0, 15.0),
        themedScrollViewValues =
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
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 15.0)];

    [scroller setFloatValue:0.1];
    [scroller setKnobProportion:0.5];

    [scroller setStyle:CPScrollerStyleLegacy];

    return scroller;
}

+ (CPScroller)makeVerticalScroller
{
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 15.0, 100.0)];

    [scroller setFloatValue:1];
    [scroller setKnobProportion:0.1];

    [scroller setStyle:CPScrollerStyleLegacy];

    return scroller;
}

+ (CPScroller)themedVerticalScroller
{
    var scroller = [self makeVerticalScroller],
        trackColor = PatternColor(
            "scroller-vertical-track{style}{position}.png",
            {
                styles: ["", "light", "dark"],
                width: 9.0,
                height: 4.0,
                orientation: PatternIsVertical
            }),

        trackColorLegacy     = PatternColor("scroller-legacy-vertical-track-center.png", 14.0, 1.0),
        incrementColorLegacy = PatternColor("scroller-legacy-vertical-track-bottom.png", 14.0, 11.0),
        decrementColorLegacy = PatternColor("scroller-legacy-vertical-track-top.png", 14.0, 11.0),

        knobColor = PatternColor(
            "scroller-vertical-knob{style}{position}.png",
            {
                styles: ["", "light", "dark"],
                width: 9.0,
                height: 4.0,
                orientation: PatternIsVertical
            }),

        knobColorLegacy = PatternColor(
            "scroller-legacy-vertical-knob{position}.png",
            {
                width: 14.0,
                height: 3.0,
                orientation: PatternIsVertical
            });

    themedVerticalScrollerValues =
        [
            // Common
            [@"minimum-knob-length",    21.0,                               CPThemeStateVertical],

            // Overlay
            [@"scroller-width",         9.0,                                CPThemeStateVertical],
            [@"knob-inset",             CGInsetMake(2.0, 0.0, 0.0, 0.0),    CPThemeStateVertical],
            [@"track-inset",            CGInsetMake(2.0, 0.0, 2.0, 0.0),    CPThemeStateVertical],
            [@"track-border-overlay",   12.0,                               CPThemeStateVertical],
            [@"knob-slot-color",        [CPNull null],                      CPThemeStateVertical],
            [@"knob-slot-color",        trackColor["@"],                    [CPThemeStateVertical, CPThemeStateSelected]],
            [@"knob-slot-color",        trackColor["light"],                [CPThemeStateVertical, CPThemeStateSelected, CPThemeStateScrollerKnobLight]],
            [@"knob-slot-color",        trackColor["dark"],                 [CPThemeStateVertical, CPThemeStateSelected, CPThemeStateScrollerKnobDark]],
            [@"knob-color",             knobColor["@"],                     CPThemeStateVertical],
            [@"knob-color",             knobColor["light"],                 [CPThemeStateVertical, CPThemeStateScrollerKnobLight]],
            [@"knob-color",             knobColor["dark"],                  [CPThemeStateVertical, CPThemeStateScrollerKnobDark]],
            [@"increment-line-color",   [CPNull null],                      CPThemeStateVertical],
            [@"decrement-line-color",   [CPNull null],                      CPThemeStateVertical],
            [@"decrement-line-size",    CGSizeMakeZero(),                   CPThemeStateVertical],
            [@"increment-line-size",    CGSizeMakeZero(),                   CPThemeStateVertical],

            // Legacy
            [@"scroller-width",         14.0,                               [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
            [@"knob-inset",             CGInsetMake(0.0, 0.0, 0.0, 0.0),    [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
            [@"track-inset",            CGInsetMake(0.0, 0.0, 0.0, 0.0),    [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
            [@"track-border-overlay",   0.0,                                [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
            [@"knob-slot-color",        trackColorLegacy,                   [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
            [@"knob-slot-color",        trackColorLegacy,                   [CPThemeStateVertical, CPThemeStateScrollViewLegacy, CPThemeStateSelected]],
            [@"knob-slot-color",        trackColorLegacy,                   [CPThemeStateVertical, CPThemeStateScrollViewLegacy, CPThemeStateSelected, CPThemeStateScrollerKnobLight]],
            [@"knob-slot-color",        trackColorLegacy,                   [CPThemeStateVertical, CPThemeStateScrollViewLegacy, CPThemeStateSelected, CPThemeStateScrollerKnobDark]],
            [@"knob-slot-color",        trackColorLegacy,                   [CPThemeStateVertical, CPThemeStateScrollViewLegacy, CPThemeStateScrollerKnobDark]],
            [@"knob-slot-color",        trackColorLegacy,                   [CPThemeStateVertical, CPThemeStateScrollViewLegacy, CPThemeStateScrollerKnobLight]],
            [@"knob-color",             knobColorLegacy,                    [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
            [@"knob-color",             knobColorLegacy,                    [CPThemeStateVertical, CPThemeStateScrollViewLegacy, CPThemeStateScrollerKnobLight]],
            [@"knob-color",             knobColorLegacy,                    [CPThemeStateVertical, CPThemeStateScrollViewLegacy, CPThemeStateScrollerKnobDark]],
            [@"increment-line-color",   incrementColorLegacy,               [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
            [@"decrement-line-color",   decrementColorLegacy,               [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
            [@"decrement-line-size",    CGSizeMake(14.0, 11.0),             [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
            [@"increment-line-size",    CGSizeMake(14.0, 11.0),             [CPThemeStateVertical, CPThemeStateScrollViewLegacy]]
        ];

    [self registerThemeValues:themedVerticalScrollerValues forView:scroller];

    return scroller;
}

+ (CPScroller)themedHorizontalScroller
{
    var scroller = [self makeHorizontalScroller],
        trackColor = PatternColor(
            "scroller-horizontal-track{style}{position}.png",
            {
                styles: ["", "light", "dark"],
                width: 4.0,
                height: 9.0,
                orientation: PatternIsHorizontal
            }),

        trackColorLegacy = PatternColor("scroller-legacy-horizontal-track-center.png", 1.0, 14.0),
        incrementColorLegacy = PatternColor("scroller-legacy-horizontal-track-right.png", 11.0, 14.0),
        decrementColorLegacy = PatternColor("scroller-legacy-horizontal-track-left.png", 11.0, 14.0),

        knobColor = PatternColor(
            "scroller-horizontal-knob{style}{position}.png",
            {
                styles: ["", "light", "dark"],
                width: 4.0,
                height: 9.0,
                orientation: PatternIsHorizontal
            }),

        knobColorLegacy = PatternColor(
            "scroller-legacy-horizontal-knob{position}.png",
            {
                width: 3.0,
                height: 14.0,
                orientation: PatternIsHorizontal
            });

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
            [@"knob-slot-color",        trackColor["@"],                    CPThemeStateSelected],
            [@"knob-slot-color",        trackColor["light"],                [CPThemeStateSelected, CPThemeStateScrollerKnobLight]],
            [@"knob-slot-color",        trackColor["dark"],                 [CPThemeStateSelected, CPThemeStateScrollerKnobDark]],
            [@"knob-color",             knobColor["@"]],
            [@"knob-color",             knobColor["light"],                 CPThemeStateScrollerKnobLight],
            [@"knob-color",             knobColor["dark"],                  CPThemeStateScrollerKnobDark],
            [@"decrement-line-size",    CGSizeMakeZero()],
            [@"increment-line-size",    CGSizeMakeZero()],

            // Legacy
            [@"scroller-width",         14.0,                               CPThemeStateScrollViewLegacy],
            [@"knob-inset",             CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateScrollViewLegacy],
            [@"track-inset",            CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateScrollViewLegacy],
            [@"track-border-overlay",   0.0,                                CPThemeStateScrollViewLegacy],
            [@"knob-slot-color",        trackColorLegacy,                   CPThemeStateScrollViewLegacy],
            [@"knob-slot-color",        trackColorLegacy,                   [CPThemeStateScrollViewLegacy, CPThemeStateSelected]],
            [@"knob-slot-color",        trackColorLegacy,                   [CPThemeStateScrollViewLegacy, CPThemeStateScrollerKnobLight]],
            [@"knob-slot-color",        trackColorLegacy,                   [CPThemeStateScrollViewLegacy, CPThemeStateScrollerKnobDark]],
            [@"knob-color",             knobColorLegacy,                    CPThemeStateScrollViewLegacy],
            [@"knob-color",             knobColorLegacy,                    [CPThemeStateScrollViewLegacy, CPThemeStateScrollerKnobLight]],
            [@"knob-color",             knobColorLegacy,                    [CPThemeStateScrollViewLegacy, CPThemeStateScrollerKnobDark]],
            [@"increment-line-color",   incrementColorLegacy,               CPThemeStateScrollViewLegacy],
            [@"decrement-line-color",   decrementColorLegacy,               CPThemeStateScrollViewLegacy],
            [@"decrement-line-size",    CGSizeMake(11.0, 14.0),             CPThemeStateScrollViewLegacy],
            [@"increment-line-size",    CGSizeMake(11.0, 14.0),             CPThemeStateScrollViewLegacy]
        ];

    [self registerThemeValues:themedHorizontalScrollerValues forView:scroller];

    return scroller;
}

+ (CPTextField)themedStandardTextField
{
    var textfield = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 29.0)],

        bezelColor = PatternColor(
            "textfield-bezel-square{state}{position}.png",
            {
                states: ["", "disabled"],
                positions: "#",
                width: 4.0,
                height: 4.0
            }),

        bezelFocusedColor = PatternColor(
            "textfield-bezel-square-focused{position}.png",
            {
                positions: "#",
                width: 9.0,
                height: 9.0
            });

    // Global for reuse by CPTokenField.
    themedTextFieldValues =
    [
        // CPThemeStateControlSizeRegular
        [@"vertical-alignment", CPTopVerticalTextAlignment,                                 CPThemeStateBezeled],
        [@"bezel-color",        bezelColor["@"],                                            CPThemeStateBezeled],
        [@"bezel-color",        bezelFocusedColor,                                          [CPThemeStateBezeled, CPThemeStateEditing]],
        [@"bezel-color",        bezelColor["disabled"],                                     [CPThemeStateBezeled, CPThemeStateDisabled]],

        [@"font",               [CPFont systemFontOfSize:CPFontCurrentSystemSize],          CPThemeStateBezeled],

        [@"text-color",         regularDisabledTextColor,                                   [CPThemeStateBezeled, CPThemeStateDisabled]],
        [@"text-shadow-color",  regularDisabledTextShadowColor,                             [CPThemeStateBezeled, CPThemeStateDisabled]],

        [@"content-inset",      CGInsetMake(8.0, 7.0, 5.0, 10.0),                           CPThemeStateBezeled],
        [@"content-inset",      CGInsetMake(8.0, 7.0, 5.0, 10.0),                           [CPThemeStateBezeled, CPThemeStateEditing]],

        [@"bezel-inset",        CGInsetMake(3.0, 4.0, 3.0, 4.0),                            CPThemeStateBezeled],
        [@"bezel-inset",        CGInsetMake(0.0, 1.0, 0.0, 1.0),                            [CPThemeStateBezeled, CPThemeStateEditing]],

        [@"text-color",         placeholderColor,                                           CPTextFieldStatePlaceholder],

        [@"line-break-mode",    CPLineBreakByTruncatingTail,                                CPThemeStateTableDataView],
        [@"vertical-alignment", CPCenterVerticalTextAlignment,                              CPThemeStateTableDataView],
        [@"content-inset",      CGInsetMake(0.0, 0.0, 0.0, 5.0),                            CPThemeStateTableDataView],

        [@"text-color",         [CPColor colorWithCalibratedWhite:51.0 / 255.0 alpha:1.0],  CPThemeStateTableDataView],
        [@"text-color",         [CPColor whiteColor],                                       [CPThemeStateTableDataView, CPThemeStateSelectedDataView, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
        [@"font",               [CPFont systemFontOfSize:CPFontCurrentSystemSize],          [CPThemeStateTableDataView, CPThemeStateSelectedDataView]],
        [@"text-color",         [CPColor blackColor],                                       [CPThemeStateTableDataView, CPThemeStateEditing, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
        [@"text-color",         [CPColor blackColor],                                       [CPThemeStateTableDataView, CPThemeStateSelectedDataView, CPThemeStateEditable, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
        [@"content-inset",      CGInsetMake(7.0, 7.0, 5.0, 10.0),                           [CPThemeStateTableDataView, CPThemeStateEditable]],
        [@"font",               [CPFont systemFontOfSize:CPFontCurrentSystemSize],          [CPThemeStateTableDataView, CPThemeStateEditing]],
        [@"bezel-inset",        CGInsetMake(-2.0, -2.0, -2.0, -2.0),                        [CPThemeStateTableDataView, CPThemeStateEditing]],

        [@"text-color",         [CPColor colorWithCalibratedWhite:125.0 / 255.0 alpha:1.0], [CPThemeStateTableDataView, CPThemeStateGroupRow]],
        [@"text-color",         [CPColor whiteColor],                                       [CPThemeStateTableDataView, CPThemeStateGroupRow, CPThemeStateSelectedDataView, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
        [@"text-shadow-color",  [CPColor whiteColor],                                       [CPThemeStateTableDataView, CPThemeStateGroupRow]],
        [@"text-shadow-offset", CGSizeMake(0, 1),                                           [CPThemeStateTableDataView, CPThemeStateGroupRow]],
        [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:0.0 alpha:0.6],           [CPThemeStateTableDataView, CPThemeStateGroupRow, CPThemeStateSelectedDataView, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
        [@"font",               [CPFont boldSystemFontOfSize:CPFontCurrentSystemSize],      [CPThemeStateTableDataView, CPThemeStateGroupRow]],

        [@"min-size",                   CGSizeMake(-1.0, 29.0)],
        [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 0.0, -4.0, 0.0)],
        [@"nib2cib-adjustment-frame",   CGRectMake(-4.0, -3.0, 8.0, 0.0),                   CPThemeStateBezeled],

        // CPThemeStateControlSizeSmall
        [@"content-inset",              CGInsetMake(7.0, 7.0, 5.0, 8.0),                    [CPThemeStateControlSizeSmall, CPThemeStateBezeled]],
        [@"content-inset",              CGInsetMake(7.0, 7.0, 5.0, 8.0),                    [CPThemeStateControlSizeSmall, CPThemeStateBezeled, CPThemeStateEditing]],

        [@"min-size",                   CGSizeMake(-1.0, 25.0),                             CPThemeStateControlSizeSmall],
        [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 0.0, -4.0, 0.0),                    CPThemeStateControlSizeSmall],
        [@"nib2cib-adjustment-frame",   CGRectMake(-3.0, 4.0, 7.0, 7.0),                    [CPThemeStateControlSizeSmall, CPThemeStateBezeled]],

        // CPThemeStateControlSizeMini
        [@"content-inset",              CGInsetMake(6.0, 7.0, 5.0, 7.0),                    [CPThemeStateControlSizeMini, CPThemeStateBezeled]],
        [@"content-inset",              CGInsetMake(6.0, 7.0, 5.0, 7.0),                    [CPThemeStateControlSizeMini, CPThemeStateBezeled, CPThemeStateEditing]],
        [@"min-size",                   CGSizeMake(-1.0, 22.0),                             CPThemeStateControlSizeMini],
        [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 0.0, -4.0, 0.0),                    CPThemeStateControlSizeMini],
        [@"nib2cib-adjustment-frame",   CGRectMake(-4.0, 4.0, 8.0, 7.0),                    [CPThemeStateControlSizeMini, CPThemeStateBezeled]],
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
            "textfield-bezel-rounded{state}{position}.png",
            {
                states: ["", "disabled"],
                width: 8.0,
                height: 23.0,
                orientation: PatternIsHorizontal
            }),

        bezelFocusedColor = PatternColor(
            "textfield-bezel-rounded-focused{position}.png",
            {
                width: 13.0,
                height: 29.0,
                orientation: PatternIsHorizontal
            });

    // Global for reuse by CPSearchField
    themedRoundedTextFieldValues =
        [
            [@"bezel-color",
                bezelColor["@"],    [CPTextFieldStateRounded, CPThemeStateBezeled]],
            [@"bezel-color",
                bezelFocusedColor,  [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
            [@"bezel-color",
                bezelColor["disabled"], [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateDisabled]],

            [@"font",                       [CPFont systemFontOfSize:CPFontCurrentSystemSize]],

            [@"content-inset",              CGInsetMake(8.0, 14.0, 6.0, 14.0),                      [CPTextFieldStateRounded, CPThemeStateBezeled]],
            [@"content-inset",              CGInsetMake(8.0, 14.0, 6.0, 14.0),                      [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],

            [@"bezel-inset",                CGInsetMake(3.0, 4.0, 3.0, 4.0),                        [CPTextFieldStateRounded, CPThemeStateBezeled]],
            [@"bezel-inset",                CGInsetMake(0.0, 1.0, 0.0, 1.0),                        [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],

            [@"text-color",                 placeholderColor,                                       [CPTextFieldStateRounded, CPTextFieldStatePlaceholder]],
            [@"text-color",                 regularDisabledTextColor,                               [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateDisabled]],
            [@"text-shadow-color",          regularDisabledTextShadowColor,                         [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateDisabled]],

            [@"min-size",                   CGSizeMake(0.0, 29.0),                                  [CPTextFieldStateRounded, CPThemeStateBezeled]],
            [@"max-size",                   CGSizeMake(-1.0, 29.0),                                 [CPTextFieldStateRounded, CPThemeStateBezeled]],

            [@"min-size",                   CGSizeMake(0.0, 20.0),                                  [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],
            [@"max-size",                   CGSizeMake(-1.0, 20.0),                                 [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]]
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

        overrides =
        [
            [@"image-search", imageSearch],
            [@"image-find", imageFind],
            [@"image-cancel", imageCancel],
            [@"image-cancel-pressed", imageCancelPressed]
        ];

    [self registerThemeValues:overrides forView:searchField inherit:themedRoundedTextFieldValues];

    return searchField;
}

+ (CPDatePicker)themedDatePicker
{
    var datePicker = [[CPDatePicker alloc] initWithFrame:CGRectMake(40.0, 40.0, 170.0, 29.0)],

        bezelColor = PatternColor(
            "textfield-bezel-square{state}{position}.png",
            {
                states: ["", "disabled"],
                positions: "#",
                width: 4.0,
                height: 4.0
            }),

        bezelColorDatePickerTextField = PatternColor(
            [
                [@"datepicker-date-segment-0.png", 4.0, 18.0],
                [@"datepicker-date-segment-1.png", 1.0, 18.0],
                [@"datepicker-date-segment-2.png", 4.0, 18.0]
            ],  PatternIsHorizontal),

        themeValues =
        [
            [@"bezel-color",        bezelColor["@"],                                            CPThemeStateBezeled],
            [@"bezel-color",        bezelColor["disabled"],                                     [CPThemeStateBezeled, CPThemeStateDisabled]],

            [@"font",               [CPFont systemFontOfSize:CPFontCurrentSystemSize]],
            [@"text-color",         [CPColor colorWithWhite:0.2 alpha:0.5],                     CPThemeStateDisabled],

            [@"content-inset",      CGInsetMake(6.0, 0.0, 0.0, 3.0),                            CPThemeStateNormal],
            [@"content-inset",      CGInsetMake(3.0, 0.0, 0.0, 3.0),                            CPThemeStateBezeled],

            [@"bezel-inset",        CGInsetMake(3.0, 0.0, 3.0, 0.0),                            CPThemeStateBezeled],

            [@"datepicker-textfield-bezel-color", [CPColor clearColor],                         CPThemeStateNormal],
            [@"datepicker-textfield-bezel-color", bezelColorDatePickerTextField,                CPThemeStateSelected],
            [@"datepicker-textfield-bezel-color", [CPColor clearColor],                         [CPThemeStateNormal, CPThemeStateDisabled]],
            [@"datepicker-textfield-bezel-color", [CPColor clearColor],                         [CPThemeStateSelected, CPThemeStateDisabled]],

            [@"separator-content-inset", CGInsetMake(0.0, -2.0, 0.0, -1.0)],

            [@"content-inset-datepicker-textfield",  CGInsetMake(2.0, 2.0, 0.0, 1.0),           CPThemeStateNormal],
            [@"content-inset-datepicker-textfield-separator",CGInsetMake(2.0, 0.0, 0.0, 0.0),   CPThemeStateNormal],
            [@"content-inset-datepicker-textfield",  CGInsetMake(2.0, 2.0, 0.0, 1.0) ,          CPThemeStateSelected],
            [@"content-inset-datepicker-textfield-separator",CGInsetMake(2.0, 0.0, 0.0, 0.0),   CPThemeStateSelected],

            [@"min-size-datepicker-textfield", CGSizeMake(6.0, 18.0)],
            [@"date-hour-margin",   7.0],
            [@"stepper-margin",     5.0],

            [@"min-size",                   CGSizeMake(0, 29.0)],
            [@"max-size",                   CGSizeMake(-1.0, 29.0)],
            [@"nib2cib-adjustment-frame",   CGRectMake(0.0, 4.0, -3.0, 0.0)],

            // CPThemeStateControlSizeSmall
            [@"content-inset",              CGInsetMake(5.0, 0.0, 0.0, 3.0),                    [CPThemeStateControlSizeSmall, CPThemeStateNormal]],
            [@"content-inset",              CGInsetMake(2.0, 0.0, 0.0, 3.0),                    [CPThemeStateControlSizeSmall, CPThemeStateBezeled]],

            [@"min-size-datepicker-textfield", CGSizeMake(6.0, 16.0),                           CPThemeStateControlSizeSmall],
            [@"date-hour-margin",           5.0,                                                CPThemeStateControlSizeSmall],
            [@"stepper-margin",             3.0,                                                CPThemeStateControlSizeSmall],

            [@"min-size",                   CGSizeMake(0, 26.0),                                CPThemeStateControlSizeSmall],
            [@"max-size",                   CGSizeMake(-1.0, 26.0),                             CPThemeStateControlSizeSmall],
            [@"nib2cib-adjustment-frame",   CGRectMake(0.0, 6.0, -4.0, 0.0),                    CPThemeStateControlSizeSmall],

            // CPThemeStateControlSizeMini
            [@"content-inset",              CGInsetMake(3.0, 0.0, 0.0, 3.0),                    [CPThemeStateControlSizeMini, CPThemeStateNormal]],
            [@"content-inset",              CGInsetMake(1.0, 0.0, 0.0, 3.0),                    [CPThemeStateControlSizeMini, CPThemeStateBezeled]],

            [@"min-size-datepicker-textfield", CGSizeMake(6.0, 12.0),                           CPThemeStateControlSizeMini],
            [@"date-hour-margin",           2.0,                                                CPThemeStateControlSizeMini],
            [@"stepper-margin",             2.0,                                                CPThemeStateControlSizeMini],

            [@"min-size",                   CGSizeMake(0, 22.0),                                CPThemeStateControlSizeMini],
            [@"max-size",                   CGSizeMake(-1.0, 22.0),                             CPThemeStateControlSizeMini],
            [@"nib2cib-adjustment-frame",   CGRectMake(0.0, 9.0, -3.0, 0.0),                    CPThemeStateControlSizeMini]
        ];

    [datePicker setDatePickerStyle:CPTextFieldDatePickerStyle];
    [self registerThemeValues:themeValues forView:datePicker];

    return datePicker;
}

+ (CPDatePicker)themedDatePickerCalendar
{
    var datePicker = [[CPDatePicker alloc] initWithFrame:CGRectMake(40.0, 140.0, 276.0 ,148.0)],

        arrowImageLeft = PatternImage("datepicker-calendar-arrow-left.png", 7.0, 10.0),
        arrowImageRight = PatternImage("datepicker-calendar-arrow-right.png", 7.0, 10.0),
        circleImage = PatternImage("datepicker-circle-image.png", 9.0, 10.0),

        arrowImageLeftHighlighted = PatternImage("datepicker-calendar-arrow-left-highlighted.png", 7.0, 10.0),
        arrowImageRightHighlighted = PatternImage("datepicker-calendar-arrow-right-highlighted.png", 7.0, 10.0),
        circleImageHighlighted = PatternImage("datepicker-circle-image-highlighted.png", 9.0, 10.0),

        secondHandSize = CGSizeMake(89.0, 89.0),
        secondHandImage = PatternImage("datepicker-clock-second-hand.png", secondHandSize.width, secondHandSize.height),

        minuteHandSize = CGSizeMake(85.0, 85.0),
        minuteHandImage = PatternImage("datepicker-clock-minute-hand.png", minuteHandSize.width, minuteHandSize.height),

        hourHandSize = CGSizeMake(47.0, 47.0),
        hourHandImage   = PatternImage("datepicker-clock-hour-hand.png", hourHandSize.width, hourHandSize.height),

        middleHandSize = CGSizeMake(13.0, 13.0),
        middleHandImage = PatternImage("datepicker-clock-middle-hand.png", middleHandSize.width, middleHandSize.height),

        clockSize = CGSizeMake(122.0, 123.0),
        clockImageColor = PatternColor("datepicker-clock.png", clockSize.width, clockSize.height),

        secondHandImageDisabled = PatternImage("datepicker-clock-second-hand-disabled.png", secondHandSize.width, secondHandSize.height),
        minuteHandImageDisabled = PatternImage("datepicker-clock-minute-hand-disabled.png", minuteHandSize.width, minuteHandSize.height),
        hourHandImageDisabled   = PatternImage("datepicker-clock-hour-hand-disabled.png", hourHandSize.width, hourHandSize.height),
        middleHandImageDisabled = PatternImage("datepicker-clock-middle-hand-disabled.png", middleHandSize.width, middleHandSize.height),
        clockImageColorDisabled = PatternColor("datepicker-clock-disabled.png", clockSize.width, clockSize.height),

        themeValues =
        [
            [@"border-color", [CPColor colorWithCalibratedRed:217.0 / 255.0 green:217.0 / 255.0 blue:211.0 / 255.0 alpha:1.0],  CPThemeStateNormal],
            [@"border-color", [CPColor colorWithCalibratedRed:68.0 / 255.0 green:109.0 / 255.0 blue:198.0 / 255.0 alpha:1.0],   CPThemeStateSelected],
            [@"border-color", [CPColor colorWithCalibratedRed:217.0 / 255.0 green:217.0 / 255.0 blue:211.0 / 255.0 alpha:0.5],  [CPThemeStateNormal, CPThemeStateDisabled]],
            [@"border-color", [CPColor colorWithCalibratedRed:68.0 / 255.0 green:109.0 / 255.0 blue:198.0 / 255.0 alpha:0.5],   [CPThemeStateSelected, CPThemeStateDisabled]],

            [@"bezel-color-calendar", [CPColor whiteColor]],
            [@"bezel-color-calendar", [CPColor colorWithCalibratedRed:87.0 / 255.0 green:128.0 / 255.0 blue:216.0 / 255.0 alpha:1.0],   CPThemeStateSelected],
            [@"bezel-color-calendar", [CPColor colorWithCalibratedRed:87.0 / 255.0 green:128.0 / 255.0 blue:216.0 / 255.0 alpha:0.5],   [CPThemeStateSelected, CPThemeStateDisabled]],
            [@"bezel-color-clock",    clockImageColor],
            [@"bezel-color-clock",    clockImageColorDisabled,                                                                          CPThemeStateDisabled],

            [@"title-text-color",           [CPColor colorWithCalibratedRed:79.0 / 255.0 green:79.0 / 255.0 blue:79.0 / 255.0 alpha:1.0]],
            [@"title-text-shadow-color",    [CPColor whiteColor]],
            [@"title-text-shadow-offset",   CGSizeMake(0,1)],
            [@"title-font",                 [CPFont boldSystemFontOfSize:12.0]],

            [@"title-text-color",           [CPColor colorWithCalibratedRed:79.0 / 255.0 green:79.0 / 255.0 blue:79.0 / 255.0 alpha:0.5],       CPThemeStateDisabled],
            [@"title-text-shadow-color",    [CPColor whiteColor],                                                                               CPThemeStateDisabled],
            [@"title-text-shadow-offset",   CGSizeMake(0,1),                                                                                    CPThemeStateDisabled],
            [@"title-font",                 [CPFont boldSystemFontOfSize:12.0],                                                                 CPThemeStateDisabled],

            [@"weekday-text-color",         [CPColor colorWithCalibratedRed:79.0 / 255.0 green:79.0 / 255.0 blue:79.0 / 255.0 alpha:1.0]],
            [@"weekday-text-shadow-color",  [CPColor whiteColor]],
            [@"weekday-text-shadow-offset", CGSizeMake(0,1)],
            [@"weekday-font",               [CPFont systemFontOfSize:11.0]],

            [@"weekday-text-color",         [CPColor colorWithCalibratedRed:79.0 / 255.0 green:79.0 / 255.0 blue:79.0 / 255.0 alpha:0.5],       CPThemeStateDisabled],
            [@"weekday-text-shadow-color",  [CPColor whiteColor],                                                                               CPThemeStateDisabled],
            [@"weekday-text-shadow-offset", CGSizeMake(0,1),                                                                                    CPThemeStateDisabled],
            [@"weekday-font",               [CPFont systemFontOfSize:11.0],                                                                     CPThemeStateDisabled],

            [@"clock-text-color",           [CPColor colorWithCalibratedRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:1.0]],
            [@"clock-text-shadow-color",    [CPColor whiteColor]],
            [@"clock-text-shadow-offset",   CGSizeMake(0,1)],
            [@"clock-font",                 [CPFont systemFontOfSize:11.0]],

            [@"clock-text-color",           [CPColor colorWithCalibratedRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:0.5],    CPThemeStateDisabled],
            [@"clock-text-shadow-color",    [CPColor whiteColor],                                                                               CPThemeStateDisabled],
            [@"clock-text-shadow-offset",   CGSizeMake(0,1),                                                                                    CPThemeStateDisabled],
            [@"clock-font",                 [CPFont systemFontOfSize:11.0],                                                                     CPThemeStateDisabled],

            [@"tile-text-color",            [CPColor colorWithCalibratedRed:34.0 / 255.0 green:34.0 / 255.0 blue:34.0 / 255.0 alpha:1.0],       CPThemeStateNormal],
            [@"tile-text-shadow-color",     [CPColor whiteColor],                                                                               CPThemeStateNormal],
            [@"tile-text-shadow-offset",    CGSizeMake(0,1),                                                                                    CPThemeStateNormal],
            [@"tile-font",                  [CPFont systemFontOfSize:10.0],                                                                     CPThemeStateNormal],

            [@"tile-text-color",            [CPColor colorWithCalibratedRed:87.0 / 255.0 green:128.0 / 255.0 blue:216.0 / 255.0 alpha:1.0],     CPThemeStateHighlighted],
            [@"tile-text-shadow-color",     [CPColor whiteColor],                                                                               CPThemeStateHighlighted],
            [@"tile-text-shadow-offset",    CGSizeMake(0,1),                                                                                    CPThemeStateHighlighted],
            [@"tile-font",                  [CPFont systemFontOfSize:10.0],                                                                     CPThemeStateHighlighted],

            [@"tile-text-color",            [CPColor colorWithCalibratedRed:87.0 / 255.0 green:128.0 / 255.0 blue:216.0 / 255.0 alpha:0.5],     [CPThemeStateHighlighted, CPThemeStateDisabled]],
            [@"tile-text-shadow-color",     [CPColor whiteColor],                                                                               [CPThemeStateHighlighted, CPThemeStateDisabled]],
            [@"tile-text-shadow-offset",    CGSizeMake(0,1),                                                                                    [CPThemeStateHighlighted, CPThemeStateDisabled]],
            [@"tile-font",                  [CPFont systemFontOfSize:10.0],                                                                     [CPThemeStateHighlighted, CPThemeStateDisabled]],

            [@"tile-text-color",            [CPColor whiteColor],                                                                               [CPThemeStateHighlighted, CPThemeStateSelected]],
            [@"tile-text-shadow-color",     [CPColor colorWithCalibratedRed:0.0 / 255.0 green:0.0 / 255.0 blue:0.0 / 255.0 alpha:0.2],          [CPThemeStateHighlighted, CPThemeStateSelected]],
            [@"tile-text-shadow-offset",    CGSizeMake(0,1),                                                                                    [CPThemeStateHighlighted, CPThemeStateSelected]],
            [@"tile-font",                  [CPFont systemFontOfSize:10.0],                                                                     [CPThemeStateHighlighted, CPThemeStateSelected]],

            [@"tile-text-color",            [CPColor whiteColor],                                                                               CPThemeStateSelected],
            [@"tile-text-shadow-color",     [CPColor colorWithCalibratedRed:0.0 / 255.0 green:0.0 / 255.0 blue:0.0 / 255.0 alpha:0.2],          CPThemeStateSelected],
            [@"tile-text-shadow-offset",    CGSizeMake(0,1),                                                                                    CPThemeStateSelected],
            [@"tile-font",                  [CPFont systemFontOfSize:10.0],                                                                     CPThemeStateSelected],

            [@"tile-text-color",            [CPColor colorWithCalibratedRed:179.0 / 255.0 green:179.0 / 255.0 blue:179.0 / 255.0 alpha:1.0],    CPThemeStateDisabled],
            [@"tile-text-shadow-color",     [CPColor whiteColor],                                                                               CPThemeStateDisabled],
            [@"tile-text-shadow-offset",    CGSizeMake(0,1),                                                                                    CPThemeStateDisabled],
            [@"tile-font",                  [CPFont systemFontOfSize:10.0],                                                                     CPThemeStateDisabled],

            [@"tile-text-color",            [CPColor colorWithCalibratedRed:255.0 / 255.0 green:255.0 / 255.0 blue:255.0 / 255.0 alpha:0.5],    [CPThemeStateDisabled, CPThemeStateSelected, CPThemeStateHighlighted]],
            [@"tile-text-shadow-color",     [CPColor colorWithCalibratedRed:0.0 / 255.0 green:0.0 / 255.0 blue:0.0 / 255.0 alpha:0.2],          [CPThemeStateDisabled, CPThemeStateSelected, CPThemeStateHighlighted]],
            [@"tile-text-shadow-offset",    CGSizeMake(0,1),                                                                                    [CPThemeStateDisabled, CPThemeStateSelected, CPThemeStateHighlighted]],
            [@"tile-font",                  [CPFont systemFontOfSize:10.0],                                                                     [CPThemeStateDisabled, CPThemeStateSelected, CPThemeStateHighlighted]],

            [@"tile-text-color",            [CPColor colorWithCalibratedRed:255.0 / 255.0 green:255.0 / 255.0 blue:255.0 / 255.0 alpha:0.5],    [CPThemeStateDisabled, CPThemeStateSelected]],
            [@"tile-text-shadow-color",     [CPColor colorWithCalibratedRed:0.0 / 255.0 green:0.0 / 255.0 blue:0.0 / 255.0 alpha:0.2],          [CPThemeStateDisabled, CPThemeStateSelected]],
            [@"tile-text-shadow-offset",    CGSizeMake(0,1),                                                                                    [CPThemeStateDisabled, CPThemeStateSelected]],
            [@"tile-font",                  [CPFont systemFontOfSize:10.0],                                                                     [CPThemeStateDisabled, CPThemeStateSelected]],

            [@"arrow-image-left",               arrowImageLeft],
            [@"arrow-image-right",              arrowImageRight],
            [@"arrow-image-left-highlighted",   arrowImageLeftHighlighted],
            [@"arrow-image-right-highlighted",  arrowImageRightHighlighted],
            [@"circle-image",                   circleImage],
            [@"circle-image-highlighted",       circleImageHighlighted],
            [@"arrow-inset",                    CGInsetMake(9.0, 4.0, 0.0, 0.0)],

            [@"second-hand-image",  secondHandImage],
            [@"hour-hand-image",    hourHandImage],
            [@"middle-hand-image",  middleHandImage],
            [@"minute-hand-image",  minuteHandImage],

            [@"second-hand-image",  secondHandImageDisabled,    CPThemeStateDisabled],
            [@"hour-hand-image",    hourHandImageDisabled,      CPThemeStateDisabled],
            [@"middle-hand-image",  middleHandImageDisabled,    CPThemeStateDisabled],
            [@"minute-hand-image",  minuteHandImageDisabled,    CPThemeStateDisabled],

            [@"second-hand-size",   secondHandSize],
            [@"hour-hand-size",     hourHandSize],
            [@"middle-hand-size",   middleHandSize],
            [@"minute-hand-size",   minuteHandSize],

            [@"border-width",            1.0],
            [@"size-header",             CGSizeMake(141.0, 39.0)],
            [@"size-tile",               CGSizeMake(20.0, 18.0)],
            [@"size-clock",              clockSize],
            [@"size-calendar",           CGSizeMake(141.0, 109.0)],
            [@"min-size-calendar",       CGSizeMake(141.0, 148.0)],
            [@"max-size-calendar",       CGSizeMake(141.0, 148.0)]
        ];

    [datePicker setDatePickerStyle:CPClockAndCalendarDatePickerStyle];
    [datePicker setBackgroundColor:[CPColor whiteColor]];
    [self registerThemeValues:themeValues forView:datePicker];

    return datePicker;
}

+ (CPTokenField)themedTokenField
{
    var tokenfield = [[CPTokenField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 29.0)],

        overrides =
        [
            [@"bezel-inset", CGInsetMakeZero()],
            [@"bezel-inset", CGInsetMake(3.0, 4.0, 3.0, 4.0),    CPThemeStateBezeled],
            [@"bezel-inset", CGInsetMake(0.0, 0.0, 0.0, 0.0),    [CPThemeStateBezeled, CPThemeStateEditing]],

            [@"editor-inset", CGInsetMake(3.0, 0.0, 0.0, 0.0)],

            // Non-bezeled token field with tokens
            [@"content-inset", CGInsetMake(6.0, 8.0, 4.0, 8.0)],

            // Non-bezeled token field with no tokens
            [@"content-inset", CGInsetMake(7.0, 8.0, 6.0, 8.0), CPTextFieldStatePlaceholder],

            // Bezeled token field with tokens
            [@"content-inset", CGInsetMake(4.0, 8.0, 4.0, 8.0), CPThemeStateBezeled],

            // Bezeled token field with no tokens
            [@"content-inset", CGInsetMake(8.0, 8.0, 7.0, 8.0), [CPThemeStateBezeled, CPTextFieldStatePlaceholder]]
        ];

    [self registerThemeValues:overrides forView:tokenfield inherit:themedTextFieldValues];

    return tokenfield;
}

+ (_CPTokenFieldToken)themedTokenFieldToken
{
    var token = [[_CPTokenFieldToken alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 19.0)],

        bezelColor = PatternColor(
            "token{state}{position}.png",
            {
                states: ["", "highlighted", "disabled"],
                width: 11.0,
                height: 19.0,
                orientation: PatternIsHorizontal
            }),

        textColor = [CPColor colorWithRed:41.0 / 255.0 green:51.0 / 255.0 blue:64.0 / 255.0 alpha:1.0],
        textHighlightedColor = [CPColor whiteColor],
        textDisabledColor = [CPColor colorWithRed:41.0 / 255.0 green:51.0 / 255.0 blue:64.0 / 255.0 alpha:0.5],

        themeValues =
        [
            [@"bezel-color",    bezelColor["@"],                    CPThemeStateBezeled],
            [@"bezel-color",    bezelColor["highlighted"],          [CPThemeStateBezeled, CPThemeStateHighlighted]],
            [@"bezel-color",    bezelColor["disabled"],             [CPThemeStateBezeled, CPThemeStateDisabled]],

            [@"text-color",     textColor],
            [@"text-color",     textHighlightedColor,               CPThemeStateHighlighted],
            [@"text-color",     textDisabledColor,                  CPThemeStateDisabled],

            [@"bezel-inset",    CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateBezeled],
            [@"content-inset",  CGInsetMake(1.0, 20.0, 2.0, 20.0),  CPThemeStateBezeled],

            // Minimum height == maximum height since tokens are fixed height.
            [@"min-size",       CGSizeMake(0.0, 19.0)],
            [@"max-size",       CGSizeMake(-1.0, 19.0)],

            [@"vertical-alignment", CPCenterTextAlignment]
        ];

    [self registerThemeValues:themeValues forView:token];

    return token;
}

+ (_CPTokenFieldTokenDisclosureButton)themedTokenFieldDisclosureButton
{
    var button = [[_CPTokenFieldTokenDisclosureButton alloc] initWithFrame:CGRectMake(0, 0, 9, 9)],

        arrowImage = PatternColor("token-disclosure.png", 7.0, 6.0),
        arrowImageHiglighted = PatternColor("token-disclosure-highlighted.png", 7.0, 6.0),

        themeValues =
        [
            [@"content-inset",  CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateNormal],

            [@"bezel-color",    nil,                                CPThemeStateBordered],
            [@"bezel-color",    arrowImage,                         [CPThemeStateBordered, CPThemeStateHovered]],
            [@"bezel-color",    arrowImageHiglighted,               [CPThemeStateBordered, CPThemeStateHovered, CPThemeStateHighlighted]],

            [@"min-size",       CGSizeMake(7.0, 6.0)],
            [@"max-size",       CGSizeMake(7.0, 6.0)],

            [@"offset",         CGPointMake(16, 7)]
        ];

    [self registerThemeValues:themeValues forView:button];

    return button;
}

+ (_CPTokenFieldTokenCloseButton)themedTokenFieldTokenCloseButton
{
    var button = [[_CPTokenFieldTokenCloseButton alloc] initWithFrame:CGRectMake(0, 0, 9, 9)],

        bezelColor = PatternColor("token-close.png", 8.0, 8.0),
        bezelHighlightedColor = PatternColor("token-close-highlighted.png", 8.0, 8.0),

        themeValues =
        [
            [@"bezel-color",    bezelColor,                             [CPThemeStateBordered, CPThemeStateHovered]],
            [@"bezel-color",    [bezelColor colorWithAlphaComponent:0], [CPThemeStateBordered, CPThemeStateDisabled]],
            [@"bezel-color",    bezelHighlightedColor,                  [CPThemeStateBordered, CPThemeStateHighlighted]],

            [@"min-size",       CGSizeMake(8.0, 8.0)],
            [@"max-size",       CGSizeMake(8.0, 8.0)],

            [@"bezel-inset",    CGInsetMake(0.0, 0.0, 0.0, 0.0),        CPThemeStateBordered],
            [@"bezel-inset",    CGInsetMake(0.0, 0.0, 0.0, 0.0),        [CPThemeStateBordered, CPThemeStateHighlighted]],

            [@"offset",         CGPointMake(16, 6),                     CPThemeStateBordered]
        ];

    [self registerThemeValues:themeValues forView:button];

    return button;
}

+ (CPComboBox)themedComboBox
{
    var combo = [[CPComboBox alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 31.0)],

        regularBezelColor = PatternColor(
            "combobox-bezel{state}{position}.png",
            {
                states: ["", "disabled"],
                width: 4.0,
                height: 25.0,
                rightWidth: 24.0,
                orientation: PatternIsHorizontal
            }),

        regularBezelFocusedColor = PatternColor(
            "combobox-bezel-focused{position}.png",
            {
                width: 9.0,
                height: 31.0,
                rightWidth: 27.0,
                orientation: PatternIsHorizontal
            }),

        regularBezelNoBorderColor = PatternColor(
            "combobox-bezel-no-border{state}{position}.png",
            {
                states: ["", "disabled"],
                width: 4.0,
                height: 25.0,
                rightWidth: 25.0,
                orientation: PatternIsHorizontal
            }),

        regularBezelNoBorderFocusedColor = PatternColor(
            "combobox-bezel-no-border-focused{position}.png",
            {
                width: 9.0,
                height: 31.0,
                rightWidth: 27.0,
                orientation: PatternIsHorizontal
            }),

        smallBezelColor = PatternColor(
            "combobox-bezel{state}{position}.png",
            {
                states: ["", "disabled"],
                width: 4.0,
                height: 20.0,
                rightWidth: 19.0,
                orientation: PatternIsHorizontal
            }),

        smallBezelFocusedColor = PatternColor(
            "combobox-bezel-focused{position}.png",
            {
                width: 8.0,
                height: 26.0,
                rightWidth: 23.0,
                orientation: PatternIsHorizontal
            }),

        smallBezelNoBorderColor = PatternColor(
            "combobox-bezel-no-border{state}{position}.png",
            {
                states: ["", "disabled"],
                width: 4.0,
                height: 20.0,
                rightWidth: 19.0,
                orientation: PatternIsHorizontal
            }),

        smallBezelNoBorderFocusedColor = PatternColor(
            "combobox-bezel-no-border-focused{position}.png",
            {
                width: 8.0,
                height: 26.0,
                rightWidth: 23.0,
                orientation: PatternIsHorizontal
            }),

        miniBezelColor = PatternColor(
            "combobox-bezel{state}{position}.png",
            {
                states: ["", "disabled"],
                width: 4.0,
                height: 17.5,
                rightWidth: 17.0,
                orientation: PatternIsHorizontal
            }),

        miniBezelFocusedColor = PatternColor(
            "combobox-bezel-focused{position}.png",
            {
                width: 6.0,
                height: 22.0,
                rightWidth: 19.0,
                orientation: PatternIsHorizontal
            }),

        miniBezelNoBorderColor = PatternColor(
            "combobox-bezel-no-border{state}{position}.png",
            {
                states: ["", "disabled"],
                width: 4.0,
                height: 17.5,
                rightWidth: 17.0,
                orientation: PatternIsHorizontal
            }),

        miniBezelNoBorderFocusedColor = PatternColor(
            "combobox-bezel-no-border-focused{position}.png",
            {
                width: 6.0,
                height: 22.0,
                rightWidth: 19.0,
                orientation: PatternIsHorizontal
            }),

        overrides =
        [
            [@"bezel-color",        regularBezelColor["@"],                     [CPThemeStateBezeled, CPComboBoxStateButtonBordered]],
            [@"bezel-color",        regularBezelFocusedColor,                   [CPThemeStateBezeled, CPComboBoxStateButtonBordered, CPThemeStateEditing]],
            [@"bezel-color",        regularBezelColor["disabled"],              [CPThemeStateBezeled, CPComboBoxStateButtonBordered, CPThemeStateDisabled]],

            [@"bezel-color",        regularBezelNoBorderColor["@"],             CPThemeStateBezeled],
            [@"bezel-color",        regularBezelNoBorderFocusedColor,           [CPThemeStateBezeled, CPThemeStateEditing]],
            [@"bezel-color",        regularBezelNoBorderColor["disabled"],      [CPThemeStateBezeled, CPThemeStateDisabled]],

            [@"border-inset",       CGInsetMake(3.0, 3.0, 3.0, 3.0),            CPThemeStateBezeled],

            [@"bezel-inset",        CGInsetMake(0.0, 1.0, 0.0, 1.0),            [CPThemeStateBezeled, CPThemeStateEditing, CPComboBoxStateButtonBordered]],
            [@"bezel-inset",        CGInsetMake(3.0, 4.0, 3.0, 4.0),            [CPThemeStateBezeled, CPThemeStateDisabled, CPComboBoxStateButtonBordered]],

            [@"bezel-inset",        CGInsetMake(0.0, 4.0, 0.0, 1.0),            [CPThemeStateBezeled, CPThemeStateEditing]],
            [@"bezel-inset",        CGInsetMake(3.0, 5.0, 3.0, 4.0),            [CPThemeStateBezeled, CPThemeStateDisabled]],

            // The right border inset has to make room for the focus ring and popup button
            [@"content-inset",      CGInsetMake(9.0, 30.0, 7.0, 10.0),          [CPThemeStateBezeled, CPComboBoxStateButtonBordered]],
            [@"content-inset",      CGInsetMake(9.0, 30.0, 7.0, 10.0),          CPThemeStateBezeled],
            [@"content-inset",      CGInsetMake(9.0, 28.0, 7.0, 10.0),          [CPThemeStateBezeled, CPThemeStateEditing]],

            [@"popup-button-size",  CGSizeMake(21.0, 23.0),                     [CPThemeStateBezeled, CPComboBoxStateButtonBordered]],
            [@"popup-button-size",  CGSizeMake(17.0, 23.0),                     CPThemeStateBezeled],

            // Because combo box uses a three-part bezel, the height is fixed
            [@"min-size",           CGSizeMake(0, 31.0)],
            [@"max-size",           CGSizeMake(-1, 31.0)],
            [@"nib2cib-adjustment-frame",   CGRectMake(-4.0, 0.0, 5.0, 0.0)],

            [@"text-color",         regularDisabledTextColor,                   [CPThemeStateBordered, CPThemeStateDisabled]],
            [@"text-shadow-color",  regularDisabledTextShadowColor,             [CPThemeStateBordered, CPThemeStateDisabled]],

            // CPThemeStateControlSizeSmall
            [@"bezel-color",        smallBezelColor["@"],                       [CPThemeStateControlSizeSmall, CPThemeStateBezeled, CPComboBoxStateButtonBordered]],
            [@"bezel-color",        smallBezelFocusedColor,                     [CPThemeStateControlSizeSmall, CPThemeStateBezeled, CPComboBoxStateButtonBordered, CPThemeStateEditing]],
            [@"bezel-color",        smallBezelColor["disabled"],                [CPThemeStateControlSizeSmall, CPThemeStateBezeled, CPComboBoxStateButtonBordered, CPThemeStateDisabled]],

            [@"bezel-color",        smallBezelNoBorderColor["@"],               [CPThemeStateControlSizeSmall, CPThemeStateBezeled]],
            [@"bezel-color",        smallBezelNoBorderFocusedColor,             [CPThemeStateControlSizeSmall, CPThemeStateBezeled, CPThemeStateEditing]],
            [@"bezel-color",        smallBezelNoBorderColor["disabled"],        [CPThemeStateControlSizeSmall, CPThemeStateBezeled, CPThemeStateDisabled]],

            [@"min-size",           CGSizeMake(0, 26.0),                        CPThemeStateControlSizeSmall],
            [@"max-size",           CGSizeMake(-1, 26.0),                       CPThemeStateControlSizeSmall],
            [@"nib2cib-adjustment-frame",   CGRectMake(-4.0, -1.0, 5.0, 0.0),   CPThemeStateControlSizeSmall],

            // CPThemeStateControlSizeMini
            [@"bezel-color",        miniBezelColor["@"],                        [CPThemeStateControlSizeMini, CPThemeStateBezeled, CPComboBoxStateButtonBordered]],
            [@"bezel-color",        miniBezelFocusedColor,                      [CPThemeStateControlSizeMini, CPThemeStateBezeled, CPComboBoxStateButtonBordered, CPThemeStateEditing]],
            [@"bezel-color",        miniBezelColor["disabled"],                 [CPThemeStateControlSizeMini, CPThemeStateBezeled, CPComboBoxStateButtonBordered, CPThemeStateDisabled]],

            [@"bezel-color",        miniBezelNoBorderColor["@"],                [CPThemeStateControlSizeMini, CPThemeStateBezeled]],
            [@"bezel-color",        miniBezelNoBorderFocusedColor,              [CPThemeStateControlSizeMini, CPThemeStateBezeled, CPThemeStateEditing]],
            [@"bezel-color",        miniBezelNoBorderColor["disabled"],         [CPThemeStateControlSizeMini, CPThemeStateBezeled, CPThemeStateDisabled]],

            [@"min-size",           CGSizeMake(0, 22.0),                        CPThemeStateControlSizeMini],
            [@"max-size",           CGSizeMake(-1, 22.0),                       CPThemeStateControlSizeMini],
            [@"nib2cib-adjustment-frame",   CGRectMake(-4.0, -2.0, 6.0, 0.0),   CPThemeStateControlSizeMini],
        ];

    [self registerThemeValues:overrides forView:combo inherit:themedTextFieldValues];

    return combo;
}

+ (CPRadioButton)themedRadioButton
{
    var button = [CPRadio radioWithTitle:@"Radio button"],
        regularImageNormal = PatternImage("radio-image.png", 21.0, 21.0),
        regularImageSelected = PatternImage("radio-image-selected.png", 21.0, 21.0),
        regularImageSelectedHighlighted = PatternImage("radio-image-selected-highlighted.png", 21.0, 21.0),
        regularImageSelectedDisabled = PatternImage("radio-image-selected.png", 21.0, 21.0),
        regularImageDisabled = PatternImage("radio-image.png", 21.0, 21.0),
        regularImageHighlighted = PatternImage("radio-image-highlighted.png", 21.0, 21.0),

        smallImageNormal = PatternImage("radio-image.png", 20.0, 20.0),
        smallImageSelected = PatternImage("radio-image-selected.png", 20.0, 20.0),
        smallImageSelectedHighlighted = PatternImage("radio-image-selected-highlighted.png", 20.0, 20.0),
        smallImageSelectedDisabled = PatternImage("radio-image-selected.png", 20.0, 20.0),
        smallImageDisabled = PatternImage("radio-image.png", 20.0, 20.0),
        smallImageHighlighted = PatternImage("radio-image-highlighted.png", 20.0, 20.0),

        miniImageNormal = PatternImage("radio-image.png", 16.0, 16.0),
        miniImageSelected = PatternImage("radio-image-selected.png", 16.0, 16.0),
        miniImageSelectedHighlighted = PatternImage("radio-image-selected-highlighted.png", 16.0, 16.0),
        miniImageSelectedDisabled = PatternImage("radio-image-selected.png", 16.0, 16.0),
        miniImageDisabled = PatternImage("radio-image.png", 16.0, 16.0),
        miniImageHighlighted = PatternImage("radio-image-highlighted.png", 16.0, 16.0);

    // Global
    themedRadioButtonValues =
    [
        [@"alignment",                  CPLeftTextAlignment,                CPThemeStateNormal],
        [@"font",                       [CPFont systemFontOfSize:12.0],     CPThemeStateNormal],
        [@"content-inset",              CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateNormal],

        [@"image",                      regularImageNormal,                 CPThemeStateNormal],
        [@"image",                      regularImageSelected,               CPThemeStateSelected],
        [@"image",                      regularImageSelectedHighlighted,    [CPThemeStateSelected, CPThemeStateHighlighted]],
        [@"image",                      regularImageHighlighted,            CPThemeStateHighlighted],
        [@"image",                      regularImageDisabled,               CPThemeStateDisabled],
        [@"image",                      regularImageSelectedDisabled,       [CPThemeStateSelected, CPThemeStateDisabled]],
        [@"image-offset",               CPRadioImageOffset],

        [@"text-color",                 regularDisabledTextColor,           CPThemeStateDisabled],

        [@"min-size",                   CGSizeMake(21.0, 21.0)],
        [@"max-size",                   CGSizeMake(-1.0, -1.0)],
        [@"nib2cib-adjustment-frame",   CGRectMake(0.0, -2.0, 0.0, 0.0)],

        // CPThemeStateControlSizeSmall
        [@"image",                      smallImageNormal,                       [CPThemeStateControlSizeSmall, CPThemeStateNormal]],
        [@"image",                      smallImageSelected,                     [CPThemeStateControlSizeSmall, CPThemeStateSelected]],
        [@"image",                      smallImageSelectedHighlighted,          [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateHighlighted]],
        [@"image",                      smallImageHighlighted,                  [CPThemeStateControlSizeSmall, CPThemeStateHighlighted]],
        [@"image",                      smallImageDisabled,                     [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
        [@"image",                      smallImageSelectedDisabled,             [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateDisabled]],

        [@"min-size",                   CGSizeMake(0, 20.0),                    CPThemeStateControlSizeSmall],
        [@"max-size",                   CGSizeMake(-1, 20.0),                   CPThemeStateControlSizeSmall],
        [@"nib2cib-adjustment-frame",   CGRectMake(0.0, -3.0, 0.0, 0.0),        CPThemeStateControlSizeSmall],

        // CPThemeStateControlSizeMini
        [@"image",                      miniImageNormal,                        [CPThemeStateControlSizeMini, CPThemeStateNormal]],
        [@"image",                      miniImageSelected,                      [CPThemeStateControlSizeMini, CPThemeStateSelected]],
        [@"image",                      miniImageSelectedHighlighted,           [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateHighlighted]],
        [@"image",                      miniImageHighlighted,                   [CPThemeStateControlSizeMini, CPThemeStateHighlighted]],
        [@"image",                      miniImageDisabled,                      [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
        [@"image",                      miniImageSelectedDisabled,              [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateDisabled]],

        [@"min-size",                   CGSizeMake(0, 16.0),                    CPThemeStateControlSizeMini],
        [@"max-size",                   CGSizeMake(-1, 16.0),                   CPThemeStateControlSizeMini],
        [@"nib2cib-adjustment-frame",   CGRectMake(2.0, -3.0, 0.0, 0.0),        CPThemeStateControlSizeMini],
    ];

    [self registerThemeValues:themedRadioButtonValues forView:button];

    return button;
}

+ (CPCheckBox)themedCheckBoxButton
{
    var button = [CPCheckBox checkBoxWithTitle:@"Checkbox"],
        regularImageNormal = PatternImage("check-box-image.png", 21.0, 21.0),
        regularImageSelected = PatternImage("check-box-image-selected.png", 21.0, 21.0),
        regularImageSelectedHighlighted = PatternImage("check-box-image-selected-highlighted.png", 21.0, 21.0),
        regularImageSelectedDisabled = PatternImage("check-box-image-selected.png", 21.0, 21.0),
        regularImageDisabled = PatternImage("check-box-image.png", 21.0, 21.0),
        regularImageHighlighted = PatternImage("check-box-image-highlighted.png", 21.0, 21.0),

        smallImageNormal = PatternImage("check-box-image.png", 19.0, 19.0),
        smallImageSelected = PatternImage("check-box-image-selected.png", 19.0, 19.0),
        smallImageSelectedHighlighted = PatternImage("check-box-image-selected-highlighted.png", 19.0, 19.0),
        smallImageSelectedDisabled = PatternImage("check-box-image-selected.png", 19.0, 19.0),
        smallImageDisabled = PatternImage("check-box-image.png", 19.0, 19.0),
        smallImageHighlighted = PatternImage("check-box-image-highlighted.png", 19.0, 19.0),

        miniImageNormal = PatternImage("check-box-image.png", 16.0, 16.0),
        miniImageSelected = PatternImage("check-box-image-selected.png", 16.0, 16.0),
        miniImageSelectedHighlighted = PatternImage("check-box-image-selected-highlighted.png", 16.0, 16.0),
        miniImageSelectedDisabled = PatternImage("check-box-image-selected.png", 16.0, 16.0),
        miniImageDisabled = PatternImage("check-box-image.png", 16.0, 16.0),
        miniImageHighlighted = PatternImage("check-box-image-highlighted.png", 16.0, 16.0);

    // Global
    themedCheckBoxValues =
    [
        [@"alignment",                  CPLeftTextAlignment,                                CPThemeStateNormal],
        [@"content-inset",              CGInsetMakeZero(),                                  CPThemeStateNormal],

        [@"font",                       [CPFont systemFontOfSize:CPFontCurrentSystemSize],  CPThemeStateNormal],
        [@"text-color",                 regularDisabledTextColor,                           CPThemeStateDisabled],
        [@"image-offset",               CPCheckBoxImageOffset],

        // CPThemeStateControlSizeRegular

        [@"image",                      regularImageNormal,                                 CPThemeStateNormal],
        [@"image",                      regularImageSelected,                               CPThemeStateSelected],
        [@"image",                      regularImageSelectedHighlighted,                    [CPThemeStateSelected, CPThemeStateHighlighted]],
        [@"image",                      regularImageHighlighted,                            CPThemeStateHighlighted],
        [@"image",                      regularImageDisabled,                               CPThemeStateDisabled],
        [@"image",                      regularImageSelectedDisabled,                       [CPThemeStateSelected, CPThemeStateDisabled]],

        [@"min-size",                   CGSizeMake(21.0, 21.0)],
        [@"max-size",                   CGSizeMake(-1.0, -1.0)],
        [@"nib2cib-adjustment-frame",   CGRectMake(-1.0, 2.0, 10.0, 0.0)],

        // CPThemeStateControlSizeSmall
        [@"image",                      smallImageNormal,                                   [CPThemeStateControlSizeSmall, CPThemeStateNormal]],
        [@"image",                      smallImageSelected,                                 [CPThemeStateControlSizeSmall, CPThemeStateSelected]],
        [@"image",                      smallImageSelectedHighlighted,                      [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateHighlighted]],
        [@"image",                      smallImageHighlighted,                              [CPThemeStateControlSizeSmall, CPThemeStateHighlighted]],
        [@"image",                      smallImageDisabled,                                 [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
        [@"image",                      smallImageSelectedDisabled,                         [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateDisabled]],

        [@"min-size",                   CGSizeMake(19.0, 19.0),                             CPThemeStateControlSizeSmall],
        [@"max-size",                   CGSizeMake(-1.0, -1.0),                             CPThemeStateControlSizeSmall],
        [@"nib2cib-adjustment-frame",   CGRectMake(1.0, 1.0, 0.0, 0.0),                     CPThemeStateControlSizeSmall],

        // CPThemeStateControlSizeMini
        [@"image",                      miniImageNormal,                                    [CPThemeStateControlSizeMini, CPThemeStateNormal]],
        [@"image",                      miniImageSelected,                                  [CPThemeStateControlSizeMini, CPThemeStateSelected]],
        [@"image",                      miniImageSelectedHighlighted,                       [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateHighlighted]],
        [@"image",                      miniImageHighlighted,                               [CPThemeStateControlSizeMini, CPThemeStateHighlighted]],
        [@"image",                      miniImageDisabled,                                  [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
        [@"image",                      miniImageSelectedDisabled,                          [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateDisabled]],

        [@"min-size",                   CGSizeMake(16.0, 16.0),                             CPThemeStateControlSizeMini],
        [@"max-size",                   CGSizeMake(-1.0, -1.0),                             CPThemeStateControlSizeMini],
        [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 0.0, 0.0, 0.0),                     CPThemeStateControlSizeMini]
    ];

    [button setThemeState:CPThemeStateSelected];

    [self registerThemeValues:themedCheckBoxValues forView:button];

    return button;
}

+ (CPCheckBox)themedMixedCheckBoxButton
{
    var button = [self themedCheckBoxButton];

    [button setAllowsMixedState:YES];
    [button setState:CPMixedState];

    var mixedHighlightedImage = PatternImage("check-box-image-mixed-highlighted.png", 21.0, 21.0),
        mixedDisabledImage = PatternImage("check-box-image-mixed.png", 21.0, 21.0),
        mixedImage = PatternImage("check-box-image-mixed.png", 21.0, 21.0),

        themeValues =
        [
            [@"image",          mixedImage,             CPButtonStateMixed],
            [@"image",          mixedHighlightedImage,  [CPButtonStateMixed, CPThemeStateHighlighted]],
            [@"image",          mixedDisabledImage,     [CPButtonStateMixed, CPThemeStateDisabled]],
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
}

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

    var smallCenterBezelColor = PatternColor("segmented-control-bezel-center.png", 1.0, 20.0),
        smallDividerBezelColor = PatternColor("segmented-control-bezel-divider.png", 1.0, 20.0),
        smallCenterHighlightedBezelColor = PatternColor("segmented-control-bezel-highlighted-center.png", 1.0, 20.0),
        smallDividerHighlightedBezelColor = PatternColor("segmented-control-bezel-highlighted-divider.png", 1.0, 20.0),
        smallLeftHighlightedBezelColor = PatternColor("segmented-control-bezel-highlighted-left.png", 4.0, 20.0),
        smallRightHighlightedBezelColor = PatternColor("segmented-control-bezel-highlighted-right.png", 4.0, 20.0),
        smallInactiveCenterBezelColor = PatternColor("segmented-control-bezel-disabled-center.png", 1.0, 20.0),
        smallInactiveDividerBezelColor = PatternColor("segmented-control-bezel-disabled-divider.png", 1.0, 20.0),
        smallInactiveLeftBezelColor = PatternColor("segmented-control-bezel-disabled-left.png", 4.0, 20.0),
        smallInactiveRightBezelColor = PatternColor("segmented-control-bezel-disabled-right.png", 4.0, 20.0),
        smallInactiveHighlightedCenterBezelColor = PatternColor("segmented-control-bezel-highlighted-disabled-center.png", 1.0, 20.0),
        smallInactiveHighlightedDividerBezelColor = PatternColor("segmented-control-bezel-highlighted-disabled-divider.png", 1.0, 20.0),
        smallInactiveHighlightedLeftBezelColor = PatternColor("segmented-control-bezel-highlighted-disabled-left.png", 4.0, 20.0),
        smallInactiveHighlightedRightBezelColor = PatternColor("segmented-control-bezel-highlighted-disabled-right.png", 4.0, 20.0),
        smallLeftBezelColor = PatternColor("segmented-control-bezel-left.png", 4.0, 20.0),
        smallRightBezelColor = PatternColor("segmented-control-bezel-right.png", 4.0, 20.0),
        smallPushedCenterBezelColor = PatternColor("segmented-control-bezel-pushed-center.png", 1.0, 20.0),
        smallPushedLeftBezelColor = PatternColor("segmented-control-bezel-pushed-left.png", 4.0, 20.0),
        smallPushedRightBezelColor = PatternColor("segmented-control-bezel-pushed-right.png", 4.0, 20.0),
        smallPushedHighlightedCenterBezelColor = PatternColor("segmented-control-bezel-pushed-highlighted-center.png", 1.0, 20.0),
        smallPushedHighlightedLeftBezelColor = PatternColor("segmented-control-bezel-pushed-highlighted-left.png", 4.0, 20.0),
        smallPushedHighlightedRightBezelColor = PatternColor("segmented-control-bezel-pushed-highlighted-right.png", 4.0, 20.0);

    var miniCenterBezelColor = PatternColor("segmented-control-bezel-center.png", 1.0, 15.0),
        miniDividerBezelColor = PatternColor("segmented-control-bezel-divider.png", 1.0, 15.0),
        miniCenterHighlightedBezelColor = PatternColor("segmented-control-bezel-highlighted-center.png", 1.0, 15.0),
        miniDividerHighlightedBezelColor = PatternColor("segmented-control-bezel-highlighted-divider.png", 1.0, 15.0),
        miniLeftHighlightedBezelColor = PatternColor("segmented-control-bezel-highlighted-left.png", 4.0, 15.0),
        miniRightHighlightedBezelColor = PatternColor("segmented-control-bezel-highlighted-right.png", 4.0, 15.0),
        miniInactiveCenterBezelColor = PatternColor("segmented-control-bezel-disabled-center.png", 1.0, 15.0),
        miniInactiveDividerBezelColor = PatternColor("segmented-control-bezel-disabled-divider.png", 1.0, 15.0),
        miniInactiveLeftBezelColor = PatternColor("segmented-control-bezel-disabled-left.png", 4.0, 15.0),
        miniInactiveRightBezelColor = PatternColor("segmented-control-bezel-disabled-right.png", 4.0, 15.0),
        miniInactiveHighlightedCenterBezelColor = PatternColor("segmented-control-bezel-highlighted-disabled-center.png", 1.0, 15.0),
        miniInactiveHighlightedDividerBezelColor = PatternColor("segmented-control-bezel-highlighted-disabled-divider.png", 1.0, 15.0),
        miniInactiveHighlightedLeftBezelColor = PatternColor("segmented-control-bezel-highlighted-disabled-left.png", 4.0, 15.0),
        miniInactiveHighlightedRightBezelColor = PatternColor("segmented-control-bezel-highlighted-disabled-right.png", 4.0, 15.0),
        miniLeftBezelColor = PatternColor("segmented-control-bezel-left.png", 4.0, 15.0),
        miniRightBezelColor = PatternColor("segmented-control-bezel-right.png", 4.0, 15.0),
        miniPushedCenterBezelColor = PatternColor("segmented-control-bezel-pushed-center.png", 1.0, 15.0),
        miniPushedLeftBezelColor = PatternColor("segmented-control-bezel-pushed-left.png", 4.0, 15.0),
        miniPushedRightBezelColor = PatternColor("segmented-control-bezel-pushed-right.png", 4.0, 15.0),
        miniPushedHighlightedCenterBezelColor = PatternColor("segmented-control-bezel-pushed-highlighted-center.png", 1.0, 15.0),
        miniPushedHighlightedLeftBezelColor = PatternColor("segmented-control-bezel-pushed-highlighted-left.png", 4.0, 15.0),
        miniPushedHighlightedRightBezelColor = PatternColor("segmented-control-bezel-pushed-highlighted-right.png", 4.0, 15.0);

    themedSegmentedControlValues =
        [
            [@"center-segment-bezel-color",     centerBezelColor,                       CPThemeStateNormal],
            [@"center-segment-bezel-color",     inactiveCenterBezelColor,               CPThemeStateDisabled],
            [@"center-segment-bezel-color",     inactiveHighlightedCenterBezelColor,    [CPThemeStateSelected, CPThemeStateDisabled]],
            [@"center-segment-bezel-color",     centerHighlightedBezelColor,            CPThemeStateSelected],
            [@"center-segment-bezel-color",     pushedCenterBezelColor,                 CPThemeStateHighlighted],
            [@"center-segment-bezel-color",     pushedHighlightedCenterBezelColor,      [CPThemeStateHighlighted, CPThemeStateSelected]],

            [@"divider-bezel-color",            dividerBezelColor,                      CPThemeStateNormal],
            [@"divider-bezel-color",            inactiveDividerBezelColor,              CPThemeStateDisabled],
            [@"divider-bezel-color",            inactiveHighlightedDividerBezelColor,   [CPThemeStateSelected, CPThemeStateDisabled]],
            [@"divider-bezel-color",            dividerHighlightedBezelColor,           CPThemeStateSelected],

            [@"left-segment-bezel-color",       leftBezelColor,                         CPThemeStateNormal],
            [@"left-segment-bezel-color",       inactiveLeftBezelColor,                 CPThemeStateDisabled],
            [@"left-segment-bezel-color",       inactiveHighlightedLeftBezelColor,      [CPThemeStateSelected, CPThemeStateDisabled]],
            [@"left-segment-bezel-color",       leftHighlightedBezelColor,              CPThemeStateSelected],
            [@"left-segment-bezel-color",       pushedLeftBezelColor,                   CPThemeStateHighlighted],
            [@"left-segment-bezel-color",       pushedHighlightedLeftBezelColor,        [CPThemeStateHighlighted, CPThemeStateSelected]],

            [@"right-segment-bezel-color",      rightBezelColor,                        CPThemeStateNormal],
            [@"right-segment-bezel-color",      inactiveRightBezelColor,                CPThemeStateDisabled],
            [@"right-segment-bezel-color",      inactiveHighlightedRightBezelColor,     [CPThemeStateSelected, CPThemeStateDisabled]],
            [@"right-segment-bezel-color",      rightHighlightedBezelColor,             CPThemeStateSelected],
            [@"right-segment-bezel-color",      pushedRightBezelColor,                  CPThemeStateHighlighted],
            [@"right-segment-bezel-color",      pushedHighlightedRightBezelColor,       [CPThemeStateHighlighted, CPThemeStateSelected]],


            [@"center-segment-bezel-color",     smallCenterBezelColor,                       [CPThemeStateControlSizeSmall, CPThemeStateNormal]],
            [@"center-segment-bezel-color",     smallInactiveCenterBezelColor,               [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
            [@"center-segment-bezel-color",     smallInactiveHighlightedCenterBezelColor,    [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateDisabled]],
            [@"center-segment-bezel-color",     smallCenterHighlightedBezelColor,            [CPThemeStateControlSizeSmall, CPThemeStateSelected]],
            [@"center-segment-bezel-color",     smallPushedCenterBezelColor,                 [CPThemeStateControlSizeSmall, CPThemeStateHighlighted]],
            [@"center-segment-bezel-color",     smallPushedHighlightedCenterBezelColor,      [CPThemeStateControlSizeSmall, CPThemeStateHighlighted, CPThemeStateSelected]],

            [@"divider-bezel-color",            smallDividerBezelColor,                      [CPThemeStateControlSizeSmall, CPThemeStateNormal]],
            [@"divider-bezel-color",            smallInactiveDividerBezelColor,              [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
            [@"divider-bezel-color",            smallInactiveHighlightedDividerBezelColor,   [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateDisabled]],
            [@"divider-bezel-color",            smallDividerHighlightedBezelColor,           [CPThemeStateControlSizeSmall, CPThemeStateSelected]],

            [@"left-segment-bezel-color",       smallLeftBezelColor,                         [CPThemeStateControlSizeSmall, CPThemeStateNormal]],
            [@"left-segment-bezel-color",       smallInactiveLeftBezelColor,                 [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
            [@"left-segment-bezel-color",       smallInactiveHighlightedLeftBezelColor,      [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateDisabled]],
            [@"left-segment-bezel-color",       smallLeftHighlightedBezelColor,              [CPThemeStateControlSizeSmall, CPThemeStateSelected]],
            [@"left-segment-bezel-color",       smallPushedLeftBezelColor,                   [CPThemeStateControlSizeSmall, CPThemeStateHighlighted]],
            [@"left-segment-bezel-color",       smallPushedHighlightedLeftBezelColor,        [CPThemeStateControlSizeSmall, CPThemeStateHighlighted, CPThemeStateSelected]],

            [@"right-segment-bezel-color",      smallRightBezelColor,                        [CPThemeStateControlSizeSmall, CPThemeStateNormal]],
            [@"right-segment-bezel-color",      smallInactiveRightBezelColor,                [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
            [@"right-segment-bezel-color",      smallInactiveHighlightedRightBezelColor,     [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateDisabled]],
            [@"right-segment-bezel-color",      smallRightHighlightedBezelColor,             [CPThemeStateControlSizeSmall, CPThemeStateSelected]],
            [@"right-segment-bezel-color",      smallPushedRightBezelColor,                  [CPThemeStateControlSizeSmall, CPThemeStateHighlighted]],
            [@"right-segment-bezel-color",      smallPushedHighlightedRightBezelColor,       [CPThemeStateControlSizeSmall, CPThemeStateHighlighted, CPThemeStateSelected]],


            [@"center-segment-bezel-color",     miniCenterBezelColor,                       [CPThemeStateControlSizeMini, CPThemeStateNormal]],
            [@"center-segment-bezel-color",     miniInactiveCenterBezelColor,               [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
            [@"center-segment-bezel-color",     miniInactiveHighlightedCenterBezelColor,    [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateDisabled]],
            [@"center-segment-bezel-color",     miniCenterHighlightedBezelColor,            [CPThemeStateControlSizeMini, CPThemeStateSelected]],
            [@"center-segment-bezel-color",     miniPushedCenterBezelColor,                 [CPThemeStateControlSizeMini, CPThemeStateHighlighted]],
            [@"center-segment-bezel-color",     miniPushedHighlightedCenterBezelColor,      [CPThemeStateControlSizeMini, CPThemeStateHighlighted, CPThemeStateSelected]],

            [@"divider-bezel-color",            miniDividerBezelColor,                      [CPThemeStateControlSizeMini, CPThemeStateNormal]],
            [@"divider-bezel-color",            miniInactiveDividerBezelColor,              [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
            [@"divider-bezel-color",            miniInactiveHighlightedDividerBezelColor,   [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateDisabled]],
            [@"divider-bezel-color",            miniDividerHighlightedBezelColor,           [CPThemeStateControlSizeMini, CPThemeStateSelected]],

            [@"left-segment-bezel-color",       miniLeftBezelColor,                         [CPThemeStateControlSizeMini, CPThemeStateNormal]],
            [@"left-segment-bezel-color",       miniInactiveLeftBezelColor,                 [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
            [@"left-segment-bezel-color",       miniInactiveHighlightedLeftBezelColor,      [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateDisabled]],
            [@"left-segment-bezel-color",       miniLeftHighlightedBezelColor,              [CPThemeStateControlSizeMini, CPThemeStateSelected]],
            [@"left-segment-bezel-color",       miniPushedLeftBezelColor,                   [CPThemeStateControlSizeMini, CPThemeStateHighlighted]],
            [@"left-segment-bezel-color",       miniPushedHighlightedLeftBezelColor,        [CPThemeStateControlSizeMini, CPThemeStateHighlighted, CPThemeStateSelected]],

            [@"right-segment-bezel-color",      miniRightBezelColor,                        [CPThemeStateControlSizeMini, CPThemeStateNormal]],
            [@"right-segment-bezel-color",      miniInactiveRightBezelColor,                [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
            [@"right-segment-bezel-color",      miniInactiveHighlightedRightBezelColor,     [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateDisabled]],
            [@"right-segment-bezel-color",      miniRightHighlightedBezelColor,             [CPThemeStateControlSizeMini, CPThemeStateSelected]],
            [@"right-segment-bezel-color",      miniPushedRightBezelColor,                  [CPThemeStateControlSizeMini, CPThemeStateHighlighted]],
            [@"right-segment-bezel-color",      miniPushedHighlightedRightBezelColor,       [CPThemeStateControlSizeMini, CPThemeStateHighlighted, CPThemeStateSelected]],

            [@"content-inset",              CGInsetMake(0.0, 4.0, 0.0, 4.0),                    CPThemeStateNormal],
            [@"bezel-inset",                CGInsetMake(0.0, 0.0, 0.0, 0.0),                    CPThemeStateNormal],

            [@"min-size",                   CGSizeMake(-1.0, 25.0)],
            [@"max-size",                   CGSizeMake(-1.0, 25.0)],
            [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 2.0, -4.0, 1.0)],

            [@"min-size",                   CGSizeMake(-1.0, 20.0),                             CPThemeStateControlSizeSmall],
            [@"max-size",                   CGSizeMake(-1.0, 20.0),                             CPThemeStateControlSizeSmall],
            [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 0.0, -5.0, 0.0),                    CPThemeStateControlSizeSmall],

            [@"min-size",                   CGSizeMake(-1.0, 15.0),                             CPThemeStateControlSizeMini],
            [@"max-size",                   CGSizeMake(-1.0, 15.0),                             CPThemeStateControlSizeMini],
            [@"nib2cib-adjustment-frame",   CGRectMake(1.0, 0.0, -2.0, 0.0),                    CPThemeStateControlSizeMini],

            [@"font",               [CPFont boldSystemFontOfSize:12.0]],
            [@"text-color",         regularTextColor],
            [@"text-color",         regularDisabledTextColor,                           CPThemeStateDisabled],

            // The "default" button state is the same theme color as the "selected" segmented control state, so we can use
            // the same text theme values.
            [@"text-color",         defaultTextColor,                                   CPThemeStateSelected],
            [@"text-color",         defaultDisabledTextColor,                           [CPThemeStateDisabled, CPThemeStateSelected]],
            [@"text-shadow-color",  regularTextShadowColor],
            [@"text-shadow-color",  regularDisabledTextShadowColor,                     CPThemeStateDisabled],
            [@"text-shadow-color",  defaultDisabledTextShadowColor,                     [CPThemeStateDisabled, CPThemeStateSelected]],
            [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:0.0 alpha:0.2],   CPThemeStateSelected],
            [@"text-shadow-offset", CGSizeMake(0.0, 1.0)],
            [@"text-shadow-offset", CGSizeMake(0.0, 1.0),                               CPThemeStateSelected],
            [@"text-shadow-offset", CGSizeMake(0.0, 0.0),                               [CPThemeStateSelected, CPThemeStateDisabled]],
            [@"line-break-mode",    CPLineBreakByTruncatingTail],

            [@"divider-thickness",  1.0]
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
            "horizontal-track{state}{position}.png",
            {
                states: ["", "disabled"],
                width: 2.0,
                height: 5.0,
                orientation: PatternIsHorizontal
            }),

        knobColor =             PatternColor("knob.png", 21.0, 21.0),
        knobHighlightedColor =  PatternColor("knob-highlighted.png", 21.0, 21.0),
        knobDisabledColor =     PatternColor("knob-disabled.png", 20.0, 21.0);

    // Gobal
    themedHorizontalSliderValues =
    [
        [@"track-width", 5.0],
        [@"track-color", trackColor["@"]],
        [@"track-color", trackColor["disabled"], CPThemeStateDisabled],

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
            "vertical-track{position}.png",
            {
                width: 5.0,
                height: 3.0,
                orientation: PatternIsVertical
            }),

        trackDisabledColor = PatternColor(
            "vertical-track-disabled{position}.png",
            {
                width: 5.0,
                height: 6.0,
                bottomHeight: 4.0,
                orientation: PatternIsVertical
            }),

        knobColor =             PatternColor("knob.png", 21.0, 21.0),
        knobHighlightedColor =  PatternColor("knob-highlighted.png", 21.0, 21.0),
        knobDisabledColor =     PatternColor("knob-disabled.png", 21.0, 21.0);

    themedVerticalSliderValues =
    [
        [@"track-width", 5.0],
        [@"track-color", trackColor,            CPThemeStateVertical],
        [@"track-color", trackDisabledColor,    [CPThemeStateVertical, CPThemeStateDisabled]],

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
        [@"track-color", trackDisabledColor,    [CPThemeStateCircular, CPThemeStateDisabled]],

        [@"knob-size",  CGSizeMake(5.0, 5.0),   CPThemeStateCircular],
        [@"knob-color", knobColor,              CPThemeStateCircular],
        [@"knob-color", knobHighlightedColor,   [CPThemeStateCircular, CPThemeStateHighlighted]],
        [@"knob-color", knobDisabledColor,      [CPThemeStateCircular, CPThemeStateDisabled]]
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
            "buttonbar-button-bezel{state}{position}.png",
            {
                states: ["", "highlighted", "disabled"],
                width: 2.0,
                height: 25.0,
                orientation: PatternIsHorizontal
            }),

        buttonImagePlus = PatternImage("buttonbar-image-plus.png", 11.0, 12.0),
        buttonImageMinus = PatternImage("buttonbar-image-minus.png", 11.0, 4.0),
        buttonImageAction = PatternImage("buttonbar-image-action.png", 22.0, 14.0),

        themedButtonBarValues =
        [
            [@"bezel-color", color],

            [@"resize-control-size",    CGSizeMake(5.0, 10.0)],
            [@"resize-control-inset",   CGInsetMake(9.0, 4.0, 7.0, 4.0)],
            [@"resize-control-color",   resizeColor],

            [@"button-bezel-color",     buttonBezelColor["@"]],
            [@"button-bezel-color",     buttonBezelColor["highlighted"], CPThemeStateHighlighted],
            [@"button-bezel-color",     buttonBezelColor["disabled"],    CPThemeStateDisabled],
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
        highlighted = PatternColor("tableview-headerview-highlighted.png", 1.0, 25.0),
        pressed = PatternColor("tableview-headerview-pressed.png", 1.0, 25.0),
        normal = PatternColor("tableview-headerview.png", 1.0, 25.0),

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
            [@"background-color",   highlightedPressed, [CPThemeStateHighlighted, CPThemeStateSelected]]
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
        sourceListSelectionColor = @{
            CPSourceListGradient: CGGradientCreateWithColorComponents(
                CGColorSpaceCreateDeviceRGB(),
                [109.0 / 255.0, 150.0 / 255.0, 238.0 / 255.0, 1.0, 72.0 / 255.0, 113.0 / 255.0, 201.0 / 255.0, 1.0],
                [0, 1],
                2
            ),
            CPSourceListTopLineColor: [CPColor colorWithCalibratedRed:70.0 / 255.0 green:107.0 / 255.0 blue:215.0 / 255.0 alpha:1.0],
            CPSourceListBottomLineColor: [CPColor colorWithCalibratedRed:42.0 / 255.0 green:74.0 / 255.0 blue:177.0 / 255.0 alpha:1.0]
        },

        themedTableViewValues =
        [
            [@"alternating-row-colors",                 alternatingRowColors],
            [@"grid-color",                             gridColor],
            [@"highlighted-grid-color",                 [CPColor whiteColor]],
            [@"selection-color",                        selectionColor],
            [@"sourcelist-selection-color",             sourceListSelectionColor],
            [@"sort-image",                             sortImage],
            [@"sort-image-reversed",                    sortImageReversed],
            [@"image-generic-file",                     imageGenericFile],
            [@"default-row-height",                     25.0],

            [@"dropview-on-background-color",           [CPColor colorWithRed:72 / 255 green:134 / 255 blue:202 / 255 alpha:0.25]],
            [@"dropview-on-border-color",               [CPColor colorWithHexString:@"4886ca"]],
            [@"dropview-on-border-width",               3.0],
            [@"dropview-on-border-radius",              8.0],

            [@"dropview-on-selected-background-color",  [CPColor clearColor]],
            [@"dropview-on-selected-border-color",      [CPColor whiteColor]],
            [@"dropview-on-selected-border-width",      2.0],
            [@"dropview-on-selected-border-radius",     8.0],

            [@"dropview-above-border-color",            [CPColor colorWithHexString:@"4886ca"]],
            [@"dropview-above-border-width",            3.0],

            [@"dropview-above-selected-border-color",   [CPColor colorWithHexString:@"8BB6F0"]],
            [@"dropview-above-selected-border-width",   2.0],
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
        warningIcon = PatternImage("alert-warning.png", 48.0, 43.0);

    // Global
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
        [@"modal-window-button-margin-x",       -18.0],
        [@"modal-window-button-margin-y",       15.0],
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

        regularBezelUp = PatternColor(
            "stepper-bezel-big{state}-up{position}.png",
            {
                states: ["", "highlighted", "disabled"],
                width: 4.0,
                height: 13.0,
                centerWidth: 17.0,
                orientation: PatternIsHorizontal
            }),

        regularBezelDown = PatternColor(
            "stepper-bezel-big{state}-down{position}.png",
            {
                states: ["", "highlighted", "disabled"],
                width: 4.0,
                height: 12.0,
                centerWidth: 17.0,
                orientation: PatternIsHorizontal
            }),

        smallBezelUp = PatternColor(
            "stepper-bezel-big{state}-up{position}.png",
            {
                states: ["", "highlighted", "disabled"],
                width: 3.0,
                height: 11.0,
                centerWidth: 14.0,
                orientation: PatternIsHorizontal
            }),

        smallBezelDown = PatternColor(
            "stepper-bezel-big{state}-down{position}.png",
            {
                states: ["", "highlighted", "disabled"],
                width: 3.0,
                height: 10.0,
                centerWidth: 14.0,
                orientation: PatternIsHorizontal
            }),

        miniBezelUp = PatternColor(
            "stepper-bezel-big{state}-up{position}.png",
            {
                states: ["", "highlighted", "disabled"],
                width: 2.0,
                height: 8.0,
                centerWidth: 10.0,
                orientation: PatternIsHorizontal
            }),

        miniBezelDown = PatternColor(
            "stepper-bezel-big{state}-down{position}.png",
            {
                states: ["", "highlighted", "disabled"],
                width: 2.0,
                height: 7.0,
                centerWidth: 10.0,
                orientation: PatternIsHorizontal
            }),

        themeValues =
        [
            // CPThemeStateControlSizeRegular
            [@"bezel-color-up-button",      regularBezelUp["@"],               [CPThemeStateBordered]],
            [@"bezel-color-down-button",    regularBezelDown["@"],             [CPThemeStateBordered]],
            [@"bezel-color-up-button",      regularBezelUp["disabled"],        [CPThemeStateBordered, CPThemeStateDisabled]],
            [@"bezel-color-down-button",    regularBezelDown["disabled"],      [CPThemeStateBordered, CPThemeStateDisabled]],
            [@"bezel-color-up-button",      regularBezelUp["highlighted"],     [CPThemeStateBordered, CPThemeStateHighlighted]],
            [@"bezel-color-down-button",    regularBezelDown["highlighted"],   [CPThemeStateBordered, CPThemeStateHighlighted]],

            [@"up-button-size",             CGSizeMake(25.0, 13.0)],
            [@"down-button-size",           CGSizeMake(25.0, 12.0)],
            [@"nib2cib-adjustment-frame",   CGRectMake(3.0, -25.0, 0.0, 0.0)],

            // CPThemeStateControlSizeSmall
            [@"bezel-color-up-button",      smallBezelUp["@"],                  [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
            [@"bezel-color-down-button",    smallBezelDown["@"],                [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
            [@"bezel-color-up-button",      smallBezelUp["disabled"],           [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],
            [@"bezel-color-down-button",    smallBezelDown["disabled"],         [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],
            [@"bezel-color-up-button",      smallBezelUp["highlighted"],        [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateHighlighted]],
            [@"bezel-color-down-button",    smallBezelDown["highlighted"],      [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateHighlighted]],

            [@"up-button-size",             CGSizeMake(20.0, 11.0),             CPThemeStateControlSizeSmall],
            [@"down-button-size",           CGSizeMake(20.0, 10.0),             CPThemeStateControlSizeSmall],
            [@"nib2cib-adjustment-frame",   CGRectMake(3.0, -21.0, 0.0, 0.0),   CPThemeStateControlSizeSmall],

            // CPThemeStateControlSizeMini
            [@"bezel-color-up-button",      miniBezelUp["@"],                   [CPThemeStateControlSizeMini, CPThemeStateBordered]],
            [@"bezel-color-down-button",    miniBezelDown["@"],                 [CPThemeStateControlSizeMini, CPThemeStateBordered]],
            [@"bezel-color-up-button",      miniBezelUp["disabled"],            [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled]],
            [@"bezel-color-down-button",    miniBezelDown["disabled"],          [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled]],
            [@"bezel-color-up-button",      miniBezelUp["highlighted"],         [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateHighlighted]],
            [@"bezel-color-down-button",    miniBezelDown["highlighted"],       [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateHighlighted]],

            [@"up-button-size",             CGSizeMake(14.0, 8.0),              CPThemeStateControlSizeMini],
            [@"down-button-size",           CGSizeMake(14.0, 7.0),              CPThemeStateControlSizeMini],
            [@"nib2cib-adjustment-frame",   CGRectMake(3.0, -14.0, 0.0, 0.0),   CPThemeStateControlSizeMini],
        ];

    [self registerThemeValues:themeValues forView:stepper];

    return stepper;
}

+ (CPRuleEditor)themedRuleEditor
{
    var ruleEditor = [[CPRuleEditor alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 300.0)],
        backgroundColors = [[CPColor whiteColor], [CPColor colorWithRed:235 / 255 green:239 / 255 blue:252 / 255 alpha:1]],
        selectedActiveRowColor = [CPColor colorWithHexString:@"5f83b9"],
        selectedInactiveRowColor = [CPColor colorWithWhite:0.83 alpha:1],
        sliceTopBorderColor = [CPColor colorWithWhite:0.9 alpha:1.0],
        sliceBottomBorderColor = [CPColor colorWithWhite:0.729412 alpha:1.0],
        sliceLastBottomBorderColor = [CPColor colorWithWhite:0.6 alpha:1.0],
        buttonAddImage = PatternImage(@"rule-editor-button-add-image.png", 20.0, 20.0),
        buttonRemoveImage = PatternImage(@"rule-editor-button-remove-image.png", 20.0, 20.0),
        fontColor = [CPColor colorWithWhite:150 / 255 alpha:1],

        ruleEditorThemedValues =
        [
            [@"alternating-row-colors",         backgroundColors],
            [@"selected-color",                 selectedActiveRowColor,                 CPThemeStateNormal],
            [@"selected-color",                 selectedInactiveRowColor,               CPThemeStateDisabled],
            [@"slice-top-border-color",         sliceTopBorderColor],
            [@"slice-bottom-border-color",      sliceBottomBorderColor],
            [@"slice-last-bottom-border-color", sliceLastBottomBorderColor],
            [@"font",                           [CPFont systemFontOfSize:10.0]],
            [@"font-color",                     fontColor],
            [@"add-image",                      buttonAddImage,                         CPThemeStateNormal],
            [@"add-image",                      buttonAddImage,                         CPThemeStateHighlighted],
            [@"remove-image",                   buttonRemoveImage,                      CPThemeStateNormal],
            [@"remove-image",                   buttonRemoveImage,                      CPThemeStateHighlighted],
            [@"vertical-alignment",             CPCenterVerticalTextAlignment],
        ];

    [self registerThemeValues:ruleEditorThemedValues forView:ruleEditor];

    return ruleEditor;
}

+ (_CPToolTipWindowView)themedTooltip
{
    var toolTipView = [[_CPToolTipWindowView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 100.0) styleMask:_CPToolTipWindowMask],

        themeValues =
        [
            [@"stroke-color",       [CPColor colorWithHexString:@"B0B0B0"]],
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
            "colorwell-bezel{state}{position}.png",
            {
                states: ["", "highlighted", "disabled"],
                width: 3.0,
                height: 24.0,
                orientation: PatternIsHorizontal
            }),

        contentBorderColor = PatternColor(
            "colorwell-content-border{position}.png",
            {
                width: 1.0,
                height: 15.0,
                orientation: PatternIsHorizontal
            }),

        themedColorWellValues = [
                [@"bezel-color",            bezelColor["@"],                    CPThemeStateBordered],
                [@"content-inset",          CGInsetMake(5.0, 5.0, 5.0, 5.0),    CPThemeStateBordered],
                [@"content-border-inset",   CGInsetMake(5.0, 5.0, 4.0, 5.0),    CPThemeStateBordered],
                [@"content-border-color",   contentBorderColor,                 CPThemeStateBordered],

                [@"bezel-color",            bezelColor["highlighted"],          [CPThemeStateBordered, CPThemeStateHighlighted]],

                [@"bezel-color",            bezelColor["disabled"],             [CPThemeStateBordered, CPThemeStateDisabled]]
            ];

    [self registerThemeValues:themedColorWellValues forView:colorWell];

    return colorWell;
}

+ (CPProgressIndicator)themedBarProgressIndicator
{
    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 75, 20)];
    [progressBar setDoubleValue:30];

    var bezelColor = PatternColor(
            "progress-indicator-bezel-border{position}.png",
            {
                width: 1.0,
                height: 20.0,
                orientation: PatternIsHorizontal
            }),

        barColor = PatternColor(
            "progress-indicator-bar{position}.png",
            {
                width: 1.0,
                height: 20.0,
                orientation: PatternIsHorizontal
            });

    themedProgressIndicator =
    [
        [@"bezel-color", bezelColor],
        [@"bar-color", barColor],
        [@"default-height", 20]
    ];

    [self registerThemeValues:themedProgressIndicator forView:progressBar];

    return progressBar;
}

+ (CPProgressIndicator)themedIndeterminateBarProgressIndicator
{
    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 75, 20)];

    [progressBar setIndeterminate:YES];

    var bezelColor = PatternColor(
            "progress-indicator-bezel-border{position}.png",
            {
                width: 1.0,
                height: 20.0,
                orientation: PatternIsHorizontal
            }),

        barColor = PatternColor(
            "progress-indicator-indeterminate-bar{position}.png",
            {
                width: 1.0,
                height: 20.0,
                centerWidth: 20.0,
                orientation: PatternIsHorizontal
            });

    themedIndeterminateProgressIndicator =
    [
        [@"bezel-color", bezelColor],
        [@"indeterminate-bar-color", barColor],
        [@"default-height", 20]
    ];

    [self registerThemeValues:themedIndeterminateProgressIndicator forView:progressBar];

    return progressBar;
}

+ (CPProgressIndicator)themedSpinningProgressIndicator
{
    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
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
    var box = [[CPBox alloc] initWithFrame:CGRectMake(0, 0, 100, 100)],

        themeValues =
        [
            [@"background-color", [CPColor colorWithHexString:@"E4E4E4"]],
            [@"border-width", 1.0],
            [@"border-color", [CPColor colorWithHexString:@"B7B7B7"]],
            [@"corner-radius", 3.0],
            [@"inner-shadow-offset", CGSizeMakeZero()],
            [@"inner-shadow-color", [CPColor blackColor]],
            [@"inner-shadow-size", 6.0],
            [@"content-margin", CGSizeMakeZero()]
        ];

    [self registerThemeValues:themeValues forView:box];

    return box;
}

+ (CPLevelIndicator)themedLevelIndicator
{
    var levelIndicator = [[CPLevelIndicator alloc] initWithFrame:CGRectMake(0, 0, 100, 100)],

        bezelColor = PatternColor(
            "level-indicator-bezel{position}.png",
            {
                width: 3.0,
                height: 18.0,
                orientation: PatternIsHorizontal
            }),

        segmentColor = PatternColor(
            "level-indicator-segment{state}{position}.png",
            {
                states: ["empty", "normal", "warning", "critical"],
                width: 3.0,
                height: 17.0,
                orientation: PatternIsHorizontal
            }),

        themeValues =
        [
            [@"bezel-color",    bezelColor],
            [@"color-empty",    segmentColor["empty"]],
            [@"color-normal",   segmentColor["normal"]],
            [@"color-warning",  segmentColor["warning"]],
            [@"color-critical", segmentColor["critical"]],
            [@"spacing",        1.0]
        ];

    [self registerThemeValues:themeValues forView:levelIndicator];

    return levelIndicator;
}

+ (CPShadowView)themedShadowView
{
    var shadowView = [[CPShadowView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100, 100)],

        lightColor = PatternColor(
            "shadow-view-light{position}.png",
            {
                width: 9.0,
                height: 9.0,
                centerIsNil: YES
            }),

        heavyColor = PatternColor(
            "shadow-view-heavy{position}.png",
            {
                width: 17.0,
                height: 17.0,
                centerIsNil: YES
            }),

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
    var browser = [[CPBrowser alloc] initWithFrame:CGRectMake(0.0, 0.0, 100, 100.0)],

        imageResize = PatternImage(@"browser-image-resize-control.png", 15.0, 14.0),
        imageLeaf = PatternImage(@"browser-image-leaf.png", 9.0, 9.0),
        imageLeafPressed = PatternImage(@"browser-image-leaf-pressed.png", 9.0, 9.0),

        themedBrowser =
        [
            ["image-control-resize", imageResize],
            ["image-control-leaf", imageLeaf],
            ["image-control-leaf-pressed", imageLeafPressed]
        ];

    [self registerThemeValues:themedBrowser forView:browser];

    return browser;
}

+ (_CPModalWindowView)themedModalWindowView
{
    var modalWindowView = [[_CPModalWindowView alloc] initWithFrame:CGRectMake(0, 0, 200, 200) styleMask:_CPModalWindowView];

    var bezelColor = PatternColor(
            "window-popup{position}.png",
            {
                positions: "full",
                width: 10.0,
                height: 10.0,
                bottomHeight: 71.0
            }),

        themeValues =
        [
            [@"bezel-color", bezelColor]
        ];

    [self registerThemeValues:themeValues forView:modalWindowView];

    return modalWindowView;
}

+ (_CPWindowView)themedWindowView
{
    var windowView = [[_CPWindowView alloc] initWithFrame:CGRectMakeZero(0.0, 0.0, 200, 200)],

        sheetShadow = PatternColor(@"window-attached-sheet-shadow.png", 1, 8),
        resizeIndicator = PatternImage(@"window-resize-indicator.png", 12, 12),

        shadowColor = PatternColor(
            "window-shadow{position}.png",
            {
                positions: "#",
                width: 20.0,
                height: 19.0,
                rightWidth: 19.0,
                bottomHeight: 18.0
            });

    // Global
    themedWindowViewValues =
    [
        [@"shadow-inset",                   CGInsetMake(10.0, 19.0, 10.0, 20.0)],
        [@"shadow-distance",                5.0],
        [@"window-shadow-color",            shadowColor],
        [@"resize-indicator",               resizeIndicator],
        [@"attached-sheet-shadow-color",    sheetShadow],
        [@"shadow-height",                  8],
        [@"size-indicator",                 CGSizeMake(12, 12)]
    ];

    [self registerThemeValues:themedWindowViewValues forView:windowView];

    return windowView;
}

+ (_CPHUDWindowView)themedHUDWindowView
{
    var HUDWindowView = [[_CPHUDWindowView alloc] initWithFrame:CGRectMake(0, 0, 200, 200) styleMask:CPHUDBackgroundWindowMask | CPClosableWindowMask],
        HUDBezelColor = PatternColor(
            "HUD/window-bezel{position}.png",
            {
                positions: "full",
                width: 5.0,
                height: 5.0
            }),

        closeImage = PatternImage(@"HUD/window-close.png", 18.0, 18.0),

        closeActiveImage = PatternImage(@"HUD/window-close-active.png", 18.0, 18.0),

        themeValues =
        [
            [@"close-image-size",           CGSizeMake(18.0, 18.0)],
            [@"close-image-origin",         CGPointMake(6.0,4.0)],
            [@"close-image",                closeImage],
            [@"close-active-image",         closeActiveImage],
            [@"bezel-color",                HUDBezelColor],
            [@"title-font",                 [CPFont systemFontOfSize:14]],
            [@"title-text-color",           [CPColor colorWithWhite:255.0 / 255.0 alpha:1]],
            [@"title-text-color",           [CPColor colorWithWhite:255.0 / 255.0 alpha:1], CPThemeStateKeyWindow],
            [@"title-text-color",           [CPColor colorWithWhite:255.0 / 255.0 alpha:1], CPThemeStateMainWindow],
            [@"title-text-shadow-color",    [CPColor blackColor]],
            [@"title-text-shadow-offset",   CGSizeMake(0.0, 1.0)],
            [@"title-alignment",            CPCenterTextAlignment],
            [@"title-line-break-mode",      CPLineBreakByTruncatingTail],
            [@"title-vertical-alignment",   CPCenterVerticalTextAlignment],
            [@"title-bar-height",           26]
        ];

    [self registerThemeValues:themeValues forView:HUDWindowView inherit:themedWindowViewValues];

    [HUDWindowView setTitle:@"HUDWindow"];

    return HUDWindowView;
}

+ (_CPStandardWindowView)themedStandardWindowView
{
    var standardWindowView = [[_CPStandardWindowView alloc] initWithFrame:CGRectMake(0, 0, 200, 200) styleMask:CPClosableWindowMask],

        bezelHeadColor = PatternColor(
            "window-standard-head{state}{position}.png",
            {
                states: ["", "inactive"],
                width: 5.0,
                height: 31.0,
                orientation: PatternIsHorizontal
            }),

        /*solidColor = CustomDrawView(function(drawView) {
            var gradient = [[CPGradient alloc] initWithStartingColor:[CPColor colorWithCalibratedRed:0.902 green:0.902 blue:0.902 alpha:1] endingColor:[CPColor colorWithCalibratedRed:0.878 green:0.878 blue:0.878 alpha:1]];
            [gradient drawInRect:[drawView bounds] angle:90];
        }),*/

        solidColor = PatternColor(
            "window-standard-head-solid{position}.png",
            {
                positions: "full",
                width: 5.0,
                height: 1.0
            }),

        bezelSheetHeadColor = PatternColor(
            "window-standard-head-sheet-solid{position}.png",
            {
                positions: "full",
                width: 5.0,
                height: 1.0
            }),

        bezelColor = PatternColor(
            "window-standard{position}.png",
            {
                positions: "full",
                width: 5.0,
                height: 1.0,
                bottomHeight:5.0
            }),

        dividerColor = PatternColor(
            "window-standard-divider{position}.png",
            {
                width: 1.0,
                height: 1.0,
                orientation: PatternIsHorizontal
            }),

        closeButtonImage =                  PatternImage(@"window-standard-close-button.png", 16, 16),
        closeButtonImageInactive =          PatternImage(@"window-standard-close-button-inactive.png", 16, 16),
        closeButtonImageHighlighted =       PatternImage(@"window-standard-button-highlighted.png", 16, 16),
        unsavedButtonImage =                PatternImage(@"window-standard-button-unsaved.png", 16, 16),
        unsavedButtonImageInactive =        PatternImage(@"window-standard-button-unsaved-inactive.png", 16, 16),
        unsavedButtonImageHighlighted =     PatternImage(@"window-standard-close-button-unsaved-highlighted.png", 16, 16),
        minimizeButtonImage =               PatternImage(@"window-standard-minimize-button.png", 16, 16),
        minimizeButtonImageHighlighted =    PatternImage(@"window-standard-minimize-button-highlighted.png", 16, 16),

        resizeIndicator = PatternImage(@"window-resize-indicator.png", 12, 12),

        themeValues =
        [
            [@"gradient-height",            31.0],
            [@"bezel-head-color",           bezelHeadColor["inactive"], CPThemeStateNormal],
            [@"bezel-head-color",           bezelHeadColor["@"], CPThemeStateKeyWindow],
            [@"bezel-head-color",           bezelHeadColor["@"], CPThemeStateMainWindow],
            [@"bezel-head-sheet-color",     bezelSheetHeadColor],
            [@"solid-color",                solidColor],

            [@"title-font",                 [CPFont boldSystemFontOfSize:CPFontCurrentSystemSize]],
            [@"title-text-color",           [CPColor colorWithHexString:@"848484"]],
            [@"title-text-color",           [CPColor colorWithWhite:22.0 / 255.0 alpha:1], CPThemeStateKeyWindow],
            [@"title-text-color",           [CPColor colorWithWhite:22.0 / 255.0 alpha:1], CPThemeStateMainWindow],
            [@"title-text-shadow-color",    [CPColor whiteColor]],
            [@"title-text-shadow-offset",   CGSizeMake(0.0, 1.0)],
            [@"title-alignment",            CPCenterTextAlignment],
            // FIXME: Make this to CPLineBreakByTruncatingMiddle once it's implemented.
            [@"title-line-break-mode",      CPLineBreakByTruncatingTail],
            [@"title-vertical-alignment",   CPCenterVerticalTextAlignment],
            [@"title-bar-height",           31],

            [@"divider-color",              dividerColor],
            [@"body-color",                 bezelColor],
            [@"title-bar-height",           31],

            [@"unsaved-image-button",               unsavedButtonImage],
            [@"unsaved-image-highlighted-button",   unsavedButtonImageHighlighted],
            [@"close-image-button",                 closeButtonImageInactive, CPThemeStateNormal],
            [@"close-image-button",                 closeButtonImage, CPThemeStateKeyWindow],
            [@"close-image-button",                 closeButtonImage, CPThemeStateMainWindow],
            [@"close-image-highlighted-button",     closeButtonImageHighlighted],
            [@"minimize-image-button",              minimizeButtonImage],
            [@"minimize-image-highlighted-button",  minimizeButtonImageHighlighted],

            [@"close-image-size",               CGSizeMake(16.0, 16.0)],
            [@"close-image-origin",             CGPointMake(8.0, 10.0)],

            [@"resize-indicator",               resizeIndicator],
            [@"size-indicator",                 CGSizeMake(12, 12)]
        ];

    [self registerThemeValues:themeValues forView:standardWindowView inherit:themedWindowViewValues];

    return standardWindowView;
}

+ (_CPDocModalWindowView)themedDocModalWindowView
{
    var docModalWindowView = [[_CPDocModalWindowView alloc] initWithFrame:CGRectMake(0, 0, 200, 200) styleMask:nil],

        bezelColor = PatternColor(
            "window-standard{position}.png",
            {
                positions: "full",
                width: 5.0,
                height: 5.0
            }),

        themeValues =
        [
            [@"body-color", bezelColor]
        ];

    [self registerThemeValues:themeValues forView:docModalWindowView inherit:themedWindowViewValues];

    return docModalWindowView;
}

+ (_CPBorderlessBridgeWindowView)themedBorderlessBridgeWindowView
{
    var bordelessBridgeWindowView = [[_CPBorderlessBridgeWindowView alloc] initWithFrame:CGRectMake(0,0,0,0)],

        toolbarBackgroundColor = PatternColor(
            [
                nil,
                [@"toolbar-background-center.png", 1.0, 58.0],
                [@"toolbar-background-bottom.png", 1.0, 1.0]
            ],  PatternIsVertical),

        themeValues =
        [
            [@"toolbar-background-color", toolbarBackgroundColor]
        ];

    [self registerThemeValues:themeValues forView:bordelessBridgeWindowView inherit:themedWindowViewValues];

    return bordelessBridgeWindowView;
}

+ (_CPToolbarView)themedToolbarView
{
    var toolbarView = [[_CPToolbarView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 59.0)],

        toolbarExtraItemsImage = PatternImage(@"toolbar-view-extra-items-image.png", 10.0, 15.0),
        toolbarExtraItemsAlternateImage = PatternImage(@"toolbar-view-extra-items-alternate-image.png", 10.0, 15.0),
        toolbarSeparatorColor = PatternColor(
            "toolbar-item-separator{position}.png",
            {
                positions: "#",
                width: 2.0,
                height: 26.0,
                orientation: PatternIsVertical
            }),

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

        themeValues =
        [
            [@"horizontal-margin",                                      9.0],
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
            [@"menu-item-text-color",                                       [CPColor colorWithHexString:@"333333"]],
            [@"menu-item-text-shadow-color",                                [CPColor colorWithWhite:1.0 alpha:0.8]],
            [@"menu-item-default-off-state-image",                          nil],
            [@"menu-item-default-off-state-highlighted-image",              nil],
            [@"menu-item-default-on-state-image",                           menuItemDefaultOnStateImage],
            [@"menu-item-default-on-state-highlighted-image",               menuItemDefaultOnStateHighlightedImage],
            [@"menu-item-separator-color",                                  [CPColor colorWithHexString:@"DFDFDF"]],
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
        menuBarWindowBackgroundSelectedColor = PatternColor(@"menu-bar-window-background-selected.png", 1.0, 30.0),

        themeValues =
        [
            [@"menu-window-more-above-image",                       menuWindowMoreAboveImage],
            [@"menu-window-more-below-image",                       menuWindowMoreBelowImage],
            [@"menu-window-pop-up-background-style-color",          menuWindowPopUpBackgroundStyleColor],
            [@"menu-window-menu-bar-background-style-color",        menuWindowMenuBarBackgroundStyleColor],
            [@"menu-window-margin-inset",                           CGInsetMake(5.0, 1.0, 5.0, 1.0)],
            [@"menu-window-scroll-indicator-height",                16.0],

            [@"menu-bar-window-background-color",                   menuBarWindowBackgroundColor],
            [@"menu-bar-window-background-selected-color",          menuBarWindowBackgroundSelectedColor],
            [@"menu-bar-window-font",                               [CPFont boldSystemFontOfSize:[CPFont systemFontSize]]],
            [@"menu-bar-window-height",                             30.0],
            [@"menu-bar-window-margin",                             10.0],
            [@"menu-bar-window-left-margin",                        10.0],
            [@"menu-bar-window-right-margin",                       10.0],

            [@"menu-bar-text-color",                                [CPColor colorWithRed:0.051 green:0.2 blue:0.275 alpha:1.0]],
            [@"menu-bar-title-color",                               [CPColor colorWithRed:0.051 green:0.2 blue:0.275 alpha:1.0]],
            [@"menu-bar-text-shadow-color",                         [CPColor whiteColor]],
            [@"menu-bar-title-shadow-color",                        [CPColor whiteColor]],
            [@"menu-bar-highlight-color",                           menuBarWindowBackgroundSelectedColor],
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

+ (_CPPopoverWindowView)themedPopoverWindowView
{
    var popoverWindowView = [[_CPPopoverWindowView alloc] initWithFrame:CGRectMake(0, 0, 200, 200) styleMask:nil],

        gradient = CGGradientCreateWithColorComponents(
                         CGColorSpaceCreateDeviceRGB(),
                         [
                             (254.0 / 255), (254.0 / 255), (254.0 / 255), 0.93,
                             (241.0 / 255), (241.0 / 255), (241.0 / 255), 0.93
                         ],
                         [0, 1],
                         2
                     ),

        gradientHUD = CGGradientCreateWithColorComponents(
                        CGColorSpaceCreateDeviceRGB(),
                        [
                            (38.0 / 255), (38.0 / 255), (38.0 / 255), 0.93,
                            (18.0 / 255), (18.0 / 255), (18.0 / 255), 0.93
                        ],
                        [0, 1],
                        2),

        strokeColor = [CPColor colorWithHexString:@"B8B8B8"],
        strokeColorHUD = [CPColor colorWithHexString:@"222222"],

        themeValues =
        [
            [@"border-radius",              5.0],
            [@"stroke-width",               1.0],
            [@"shadow-size",                CGSizeMake(0, 6)],
            [@"shadow-blur",                15.0],
            [@"background-gradient",        gradient],
            [@"background-gradient-hud",    gradientHUD],
            [@"stroke-color",               strokeColor],
            [@"stroke-color-hud",           strokeColorHUD]
        ];

    [self registerThemeValues:themeValues forView:popoverWindowView];

    return popoverWindowView;
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
            [@"text-color",         [CPColor colorWithHexString:@"cdcdcd"]],
            [@"text-color",         [CPColor colorWithCalibratedWhite:1.0 alpha:0.6], CPThemeStateDisabled],
            [@"text-shadow-color",  [CPColor blackColor]],
            [@"text-shadow-color",  [CPColor blackColor], CPThemeStateDisabled],
            [@"text-shadow-offset", CGSizeMake(0, 1.0)]
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
            [@"suppression-button-text-color",  [CPColor whiteColor]]
        ];

    [self registerThemeValues:hudSpecificValues forView:alert inherit:themedAlertValues];

    return [alert themeView];
}

+ (CPProgressIndicator)themedBarProgressIndicator
{
    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 75, 16)];
    [progressBar setDoubleValue:30];

    [self registerThemeValues:nil forView:progressBar inherit:themedProgressIndicator];

    return progressBar;

}

+ (CPProgressIndicator)themedIndeterminateBarProgressIndicator
{
    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 75, 16)];
    [progressBar setIndeterminate:YES];

    [self registerThemeValues:nil forView:progressBar inherit:themedIndeterminateProgressIndicator];

    return progressBar;
}

+ (CPCheckBox)themedCheckBoxButton
{
    var button = [CPCheckBox checkBoxWithTitle:@"Checkbox"];

    [button setThemeState:CPThemeStateSelected];

    var imageNormal = PatternImage("HUD/check-box-image.png", 21.0, 21.0),
        imageSelected = PatternImage("HUD/check-box-image-selected.png", 21.0, 21.0),
        imageSelectedHighlighted = PatternImage("HUD/check-box-image-selected-highlighted.png", 21.0, 21.0),
        imageSelectedDisabled = PatternImage("HUD/check-box-image-selected.png", 21.0, 21.0),
        imageDisabled = PatternImage("HUD/check-box-image.png", 21.0, 21.0),
        imageHighlighted = PatternImage("HUD/check-box-image-highlighted.png", 21.0, 21.0),
        mixedHighlightedImage = PatternImage("HUD/check-box-image-mixed-highlighted.png", 21.0, 21.0),
        mixedDisabledImage = PatternImage("HUD/check-box-image-mixed.png", 21.0, 21.0),
        mixedImage = PatternImage("HUD/check-box-image-mixed.png", 21.0, 21.0),

        hudSpecific =
        [
            [@"image",          imageNormal,                        CPThemeStateNormal],
            [@"image",          imageSelected,                      CPThemeStateSelected],
            [@"image",          imageSelectedHighlighted,           [CPThemeStateSelected, CPThemeStateHighlighted]],
            [@"image",          imageHighlighted,                   CPThemeStateHighlighted],
            [@"image",          imageDisabled,                      CPThemeStateDisabled],
            [@"image",          imageSelectedDisabled,              [CPThemeStateSelected, CPThemeStateDisabled]],
            [@"image",          mixedImage,                         CPButtonStateMixed],
            [@"image",          mixedHighlightedImage,              [CPButtonStateMixed, CPThemeStateHighlighted]],
            [@"image",          mixedDisabledImage,                 [CPButtonStateMixed, CPThemeStateDisabled]]
        ];

    [self registerThemeValues:[self defaultThemeOverridesAddedTo:hudSpecific] forView:button inherit:themedCheckBoxValues];

    return button;
}

+ (CPCheckBox)themedMixedCheckBoxButton
{
    var button = [self themedCheckBoxButton];

    [button setAllowsMixedState:YES];
    [button setState:CPMixedState];

    [self registerThemeValues:[self defaultThemeOverridesAddedTo:nil] forView:button];

    return button;
}

+ (CPRadioButton)themedRadioButton
{
    var button = [CPRadio radioWithTitle:@"Radio button"],
        regularImageNormal = PatternImage("HUD/radio-image.png", 21.0, 21.0),
        regularImageSelected = PatternImage("HUD/radio-image-selected.png", 21.0, 21.0),
        regularImageSelectedHighlighted = PatternImage("HUD/radio-image-selected-highlighted.png", 21.0, 21.0),
        regularImageSelectedDisabled = PatternImage("HUD/radio-image-selected.png", 21.0, 21.0),
        regularImageDisabled = PatternImage("HUD/radio-image.png", 21.0, 21.0),
        regularImageHighlighted = PatternImage("HUD/radio-image-highlighted.png", 21.0, 21.0),

        smallImageNormal = PatternImage("HUD/radio-image.png", 20.0, 20.0),
        smallImageSelected = PatternImage("HUD/radio-image-selected.png", 20.0, 20.0),
        smallImageSelectedHighlighted = PatternImage("HUD/radio-image-selected-highlighted.png", 20.0, 20.0),
        smallImageSelectedDisabled = PatternImage("HUD/radio-image-selected.png", 20.0, 20.0),
        smallImageDisabled = PatternImage("HUD/radio-image.png", 20.0, 20.0),
        smallImageHighlighted = PatternImage("HUD/radio-image-highlighted.png", 20.0, 20.0),

        miniImageNormal = PatternImage("HUD/radio-image.png", 16.0, 16.0),
        miniImageSelected = PatternImage("HUD/radio-image-selected.png", 16.0, 16.0),
        miniImageSelectedHighlighted = PatternImage("HUD/radio-image-selected-highlighted.png", 16.0, 16.0),
        miniImageSelectedDisabled = PatternImage("HUD/radio-image-selected.png", 16.0, 16.0),
        miniImageDisabled = PatternImage("HUD/radio-image.png", 16.0, 16.0),
        miniImageHighlighted = PatternImage("HUD/radio-image-highlighted.png", 16.0, 16.0);

        hudSpecific =
        [
            [@"image",                      regularImageNormal,                 CPThemeStateNormal],
            [@"image",                      regularImageSelected,               CPThemeStateSelected],
            [@"image",                      regularImageSelectedHighlighted,    [CPThemeStateSelected, CPThemeStateHighlighted]],
            [@"image",                      regularImageHighlighted,            CPThemeStateHighlighted],
            [@"image",                      regularImageDisabled,               CPThemeStateDisabled],
            [@"image",                      regularImageSelectedDisabled,       [CPThemeStateSelected, CPThemeStateDisabled]],

            [@"min-size",                   CGSizeMake(21.0, 21.0)],
            [@"max-size",                   CGSizeMake(-1.0, -1.0)],
            [@"nib2cib-adjustment-frame",   CGRectMake(-5.0, 2.0, 0.0, 0.0)],

            // CPThemeStateControlSizeSmall
            [@"image",                      smallImageNormal,                   [CPThemeStateControlSizeSmall, CPThemeStateNormal]],
            [@"image",                      smallImageSelected,                 [CPThemeStateControlSizeSmall, CPThemeStateSelected]],
            [@"image",                      smallImageSelectedHighlighted,      [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateHighlighted]],
            [@"image",                      smallImageHighlighted,              [CPThemeStateControlSizeSmall, CPThemeStateHighlighted]],
            [@"image",                      smallImageDisabled,                 [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
            [@"image",                      smallImageSelectedDisabled,         [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateDisabled]],

            [@"min-size",                   CGSizeMake(0, 20.0),                CPThemeStateControlSizeSmall],
            [@"max-size",                   CGSizeMake(-1, 20.0),               CPThemeStateControlSizeSmall],
            [@"nib2cib-adjustment-frame",   CGRectMake(-2.0, 2.0, 15.0, 0.0),   CPThemeStateControlSizeSmall],

            // CPThemeStateControlSizeMini
            [@"image",                      miniImageNormal,                    [CPThemeStateControlSizeMini, CPThemeStateNormal]],
            [@"image",                      miniImageSelected,                  [CPThemeStateControlSizeMini, CPThemeStateSelected]],
            [@"image",                      miniImageSelectedHighlighted,       [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateHighlighted]],
            [@"image",                      miniImageHighlighted,               [CPThemeStateControlSizeMini, CPThemeStateHighlighted]],
            [@"image",                      miniImageDisabled,                  [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
            [@"image",                      miniImageSelectedDisabled,          [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateDisabled]],

            [@"min-size",                   CGSizeMake(0, 16.0),                CPThemeStateControlSizeMini],
            [@"max-size",                   CGSizeMake(-1, 16.0),               CPThemeStateControlSizeMini],
            [@"nib2cib-adjustment-frame",   CGRectMake(0.0, 2.0, 15.0, 0.0),    CPThemeStateControlSizeMini],
        ];

    [self registerThemeValues:[self defaultThemeOverridesAddedTo:hudSpecific] forView:button inherit:themedRadioButtonValues];
    return button;
}

@end
