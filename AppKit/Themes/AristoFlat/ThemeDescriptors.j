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

var FlatColorBlack         = [CPColor colorWithHexString:@"6b6b6b"],
    FlatColorBlackDark     = [CPColor colorWithHexString:@"5e5959"],
    FlatColorBlackDarker   = [CPColor colorWithHexString:@"232022"],
    FlatColorBlackLight    = [CPColor colorWithHexString:@"777d7d"],
    FlatColorBlackLighter  = [CPColor colorWithHexString:@"91aeae"],
    FlatColorBlue          = [CPColor colorWithHexString:@"6b94ec"],
    FlatColorBlueDark      = [CPColor colorWithHexString:@"5a83de"],
    FlatColorBlueDarker    = [CPColor colorWithHexString:@"333333"],
    FlatColorBlueLight     = [CPColor colorWithHexString:@"7da3f7"],
    FlatColorBlueLighter   = [CPColor colorWithHexString:@"b3d0ff"],
    FlatColorBluePale      = [CPColor colorWithHexString:@"c7d9f9"],
    FlatColorGreenDark     = [CPColor colorWithHexString:@"36ab65"],
    FlatColorGreen         = [CPColor colorWithHexString:@"b3d645"],
    FlatColorGreenLight    = [CPColor colorWithHexString:@"e0fe83"],
    FlatColorGreenLighter  = [CPColor colorWithHexString:@"ffffcb"],
    FlatColorGrey          = [CPColor colorWithHexString:@"d9d9d9"],
    FlatColorGreyDark      = [CPColor colorWithHexString:@"ccc2c2"],
    FlatColorGreyDarker    = [CPColor colorWithHexString:@"333333"],
    FlatColorGreyLight     = [CPColor colorWithHexString:@"f2f2f2"],
    FlatColorGreyLighter   = [CPColor colorWithHexString:@"fcfcfc"],
    FlatColorOrange        = [CPColor colorWithHexString:@"f9b13d"],
    FlatColorOrangeLight   = [CPColor colorWithHexString:@"fec26a"],
    FlatColorOrangeLighter = [CPColor colorWithHexString:@"fed291"],
    FlatColorRed           = [CPColor colorWithHexString:@"f76159"],
    FlatColorWhite         = [CPColor colorWithHexString:@"ffffff"],
    FlatColorWindowBody    = [CPColor colorWithHexString:@"f5f5f5"],
    FlatColorYellow        = [CPColor colorWithHexString:@"eeda54"],
    FlatColorMauve         = [CPColor colorWithHexString:@"aa97f2"],
    FlatColor1             = [CPColor colorWithHexString:@"f77278"],
    FlatColor2             = [CPColor colorWithHexString:@"2d3f4e"];

var themedTextFieldValues          = nil,
    themedWindowViewValues         = nil,

    regularTextColor               = [CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0],
    regularTextShadowColor         = [CPColor colorWithCalibratedWhite:1.0 alpha:0.2],
    regularDisabledTextColor       = [CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:0.6],
    regularDisabledTextShadowColor = [CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:0.6],

    defaultTextColor               = [CPColor whiteColor],
    defaultTextShadowColor         = [CPColor colorWithCalibratedWhite:0.0 alpha:0.3],
    defaultDisabledTextColor       = regularDisabledTextColor,
    defaultDisabledTextShadowColor = regularDisabledTextShadowColor,

    placeholderColor               = regularDisabledTextColor;


@implementation AristoFlatThemeDescriptor : BKThemeDescriptor

+ (CPString)themeName
{
    return @"AristoFlat";
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
    return [[CPButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 21)];
}

+ (CPButton)button
{
    var button = [self makeButton],

        themedButtonValues =
        [
                [@"text-color",                 regularTextColor],
                [@"text-color",                 regularTextColor,                   CPThemeStateBordered],
                [@"text-color",                 regularDisabledTextColor,           [CPThemeStateDisabled, CPThemeStateDefault]],
                [@"text-color",                 FlatColorWhite,                     CPThemeStateDefault],
                [@"text-color",                 regularDisabledTextColor,           CPThemeStateDisabled],
                [@"line-break-mode",            CPLineBreakByTruncatingTail],

                [@"bezel-color",                FlatColorGrey,                    CPThemeStateBordered],
                [@"bezel-color",                FlatColorGreyDark,                [CPThemeStateBordered, CPThemeStateHighlighted]],
                [@"bezel-color",                FlatColorGreyLight,               [CPThemeStateBordered, CPThemeStateDisabled]],
                [@"bezel-color",                FlatColorBlue,                    [CPThemeStateBordered, CPThemeStateDefault]],
                [@"bezel-color",                FlatColorBlueDark,                [CPThemeStateBordered, CPThemeStateDefault, CPThemeStateHighlighted]],
                [@"bezel-color",                FlatColorGreyLight,               [CPThemeStateBordered, CPThemeStateDefault, CPThemeStateDisabled]],

                [@"content-inset",              CGInsetMake(0.0, 0.0, 1.0, 0.0),    CPThemeStateBordered],
                [@"image-offset",               CPButtonImageOffset],

                // normal
                [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 10.0, 0.0, 0.0),    CPThemeStateBordered],
                [@"min-size",                   CGSizeMake(-1, 21),                 CPThemeStateBordered],
                [@"max-size",                   CGSizeMake(-1, 21),                 CPThemeStateBordered],

                // small
                [@"nib2cib-adjustment-frame",   CGRectMake(-3.0, 9.0, 0.0, 0.0),    [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
                [@"min-size",                   CGSizeMake(0.0, 18.0),              CPThemeStateControlSizeSmall, CPThemeStateBordered],
                [@"max-size",                   CGSizeMake(-1.0, 18.0),             CPThemeStateControlSizeSmall, CPThemeStateBordered],
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
    [button setThemeStates:[CPButtonStateBezelStyleRounded, CPThemeStateDefault]];

    return button;
}

+ (CPPopUpButton)themedPopUpButton
{
    var button = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 21.0) pullsDown:NO],

        bezelColor = PatternColor([
            ["popupbutton-bezel-left.png", 1.0, 21.0],
            ["popupbutton-bezel-center.png", 1.0, 21.0],
            ["popupbutton-bezel-right.png", 18.0, 21.0],
        ], PatternIsHorizontal),

        smallBezelColor = PatternColor([
            ["popupbutton-bezel-left.png", 1.0, 18.0],
            ["popupbutton-bezel-center.png", 1.0, 18.0],
            ["popupbutton-bezel-right.png", 13.0, 18.0],
        ], PatternIsHorizontal),

        miniBezelColor = PatternColor([
            ["popupbutton-bezel-left.png", 1.0, 18.0],
            ["popupbutton-bezel-center.png", 1.0, 18.0],
            ["popupbutton-bezel-right.png", 13.0, 18.0],
        ], PatternIsHorizontal),


        themeValues =
        [
            // general
            [@"text-color",                 [CPColor blackColor]],
            [@"content-inset",              CGInsetMake(0, 21.0 + 5.0, 0, 5.0),     CPThemeStateBordered],
            [@"bezel-color",                FlatColorGreyLighter,                 [CPThemeStateBordered, CPThemeStateDisabled]],

            // regular
            [@"bezel-color",                bezelColor,                             CPThemeStateBordered],
            [@"max-size",                   CGSizeMake(-1.0, 21.0),                 CPThemeStateBordered],
            [@"min-size",                   CGSizeMake(32.0, 21.0),                 CPThemeStateBordered],
            [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 2.0, -5.0, 0.0),        CPThemeStateBordered],

            // small
            [@"bezel-color",                smallBezelColor,                        [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
            [@"bezel-color",                FlatColorGreyLighter,                 [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],
            [@"max-size",                   CGSizeMake(-1.0, 18.0),                 [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
            [@"min-size",                   CGSizeMake(32.0, 18.0),                 [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
            [@"nib2cib-adjustment-frame",   CGRectMake(3.0, 1.0, -6.0, 0.0),         [CPThemeStateControlSizeSmall, CPThemeStateBordered]],

            // mini
            [@"bezel-color",                miniBezelColor,                         [CPThemeStateControlSizeMini, CPThemeStateBordered]],
            [@"bezel-color",                FlatColorGreyLighter,                 [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled]],
            [@"max-size",                   CGSizeMake(-1.0, 14.0),                 [CPThemeStateControlSizeMini, CPThemeStateBordered]],
            [@"min-size",                   CGSizeMake(32.0, 14.0),                 [CPThemeStateControlSizeMini, CPThemeStateBordered]],
            [@"nib2cib-adjustment-frame",   CGRectMake(1.0, 0.0, -3.0, 0.0),       [CPThemeStateControlSizeMini, CPThemeStateBordered]],

        ];

    [self registerThemeValues:themeValues forView:button];

    [button setTitle:@"Pop Up"];
    [button addItemWithTitle:@"item"];

    return button;
}

+ (CPScrollView)themedScrollView
{
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)],
        borderColor = FlatColorGreyDark,
        themedScrollViewValues =
        [
            [@"border-color", borderColor],
            [@"bottom-corner-color", [CPNull null]]
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
        compos = [FlatColorGreyDark components],
        knobColorTranslucid = [CPColor colorWithCalibratedRed:compos[0] green:compos[1] blue:compos[2] alpha:0.6],

        themedVerticalScrollerValues =
        [
                // Common
                [@"minimum-knob-length",    21.0,                                           CPThemeStateVertical],
                [@"track-inset",            CGInsetMake(0.0, 0.0, 0.0, 0.0),                CPThemeStateVertical],
                [@"decrement-line-size",    CGSizeMakeZero(),                               CPThemeStateVertical],
                [@"increment-line-size",    CGSizeMakeZero(),                               CPThemeStateVertical],

                // Overlay
                [@"knob-color",             knobColorTranslucid,                            CPThemeStateVertical],
                [@"knob-color",             FlatColorGrey,                                [CPThemeStateVertical, CPThemeStateSelected]],
                [@"knob-inset",             CGInsetMake(0.0, 0.0, 0.0, 0.0),                CPThemeStateVertical],
                [@"knob-slot-color",        PatternColor("scroller-track-left.png", 9, 1),  [CPThemeStateVertical, CPThemeStateSelected]],
                [@"knob-slot-color",        [CPNull null],                                  CPThemeStateVertical],
                [@"scroller-width",         5.0,                                            CPThemeStateVertical],
                [@"track-border-overlay",   7.0,                                            CPThemeStateVertical],

                // Legacy
                [@"knob-color",             FlatColorGrey,                                [CPThemeStateVertical, CPThemeStateScrollViewLegacy, CPThemeStateSelected]],
                [@"knob-color",             FlatColorGrey,                                [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
                [@"knob-inset",             CGInsetMake(0.0, 1.0, 0.0, 2.0),                [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
                [@"knob-slot-color",        PatternColor("scroller-track-left.png", 9, 1),  [CPThemeStateVertical, CPThemeStateScrollViewLegacy, CPThemeStateSelected]],
                [@"knob-slot-color",        PatternColor("scroller-track-left.png", 9, 1),  [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
                [@"scroller-width",         9.0,                                            [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
                [@"track-border-overlay",   12.0,                                           [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
            ];

    [self registerThemeValues:themedVerticalScrollerValues forView:scroller];

    return scroller;
}

+ (CPScroller)themedHorizontalScroller
{
    var scroller = [self makeHorizontalScroller],
        compos = [FlatColorGreyDark components],
        knobColorTranslucid = [CPColor colorWithCalibratedRed:compos[0] green:compos[1] blue:compos[2] alpha:0.6],

        knobColorLegacy = PatternColor("scroller-legacy-horizontal-knob{position}.png", {width: 3.0, height: 14.0, orientation: PatternIsHorizontal}),

        themedHorizontalScrollerValues =
        [
                // Common
                [@"minimum-knob-length",    21.0],
                [@"track-inset",            CGInsetMake(0.0, 0.0, 0.0, 0.0)],
                [@"decrement-line-size",    CGSizeMakeZero()],
                [@"increment-line-size",    CGSizeMakeZero()],
                [@"knob-inset",             CGInsetMake(2.0, 0.0, 1.0, 0.0)],

                // Overlay
                [@"knob-color",             knobColorTranslucid],
                [@"knob-color",             FlatColorGrey,                                    CPThemeStateSelected],
                [@"knob-slot-color",        PatternColor("scroller-track-bottom.png", 1, 9),    CPThemeStateSelected],
                [@"knob-slot-color",        [CPNull null]],
                [@"scroller-width",         5.0],
                [@"track-border-overlay",   9.0],

                // Legacy
                [@"knob-color",             FlatColorGrey,                                    CPThemeStateScrollViewLegacy],
                [@"knob-color",             FlatColorGrey,                                    [CPThemeStateScrollViewLegacy, CPThemeStateSelected]],
                [@"knob-slot-color",        PatternColor("scroller-track-bottom.png", 1, 9),    CPThemeStateScrollViewLegacy],
                [@"knob-slot-color",        PatternColor("scroller-track-bottom.png", 1, 9),    [CPThemeStateScrollViewLegacy, CPThemeStateSelected]],
                [@"scroller-width",         9.0,                                                CPThemeStateScrollViewLegacy],
                [@"scroller-width",         9.0],
                [@"track-border-overlay",   12.0,                                               CPThemeStateScrollViewLegacy],
                [@"track-border-overlay",   12.0],

            ];

    [self registerThemeValues:themedHorizontalScrollerValues forView:scroller];

    return scroller;
}

+ (CPTextField)themedStandardTextField
{
    var textfield = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 29.0)],
        bezelColor = PatternColor([
            ["textfield-bezel-border.png", 1.0, 1.0],
            ["textfield-bezel-border.png", 1.0, 1.0],
            ["textfield-bezel-border.png", 1.0, 1.0],
            ["textfield-bezel-border.png", 1.0, 1.0],
            ["textfield-bezel-middle.png", 1.0, 1.0],
            ["textfield-bezel-border.png", 1.0, 1.0],
            ["textfield-bezel-border.png", 1.0, 1.0],
            ["textfield-bezel-border.png", 1.0, 1.0],
            ["textfield-bezel-border.png", 1.0, 1.0],
        ], PatternIsHorizontal),
        bezelColorEditing = PatternColor([
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
            ["textfield-bezel-middle.png", 1.0, 1.0],
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
        ], PatternIsHorizontal);


    // Global for reuse by CPTokenField.
    themedTextFieldValues =
    [
        // PlaceHolders
        [@"text-color",                 placeholderColor,                                       CPTextFieldStatePlaceholder],
        [@"text-color",                 FlatColorWhite,                                         CPThemeStateSelectedDataView],

        // Non bezeled normal
        [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 0.0, -4.0, 0.0),                        CPThemeStateNormal],

        // Non bezeled small
        [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 0.0, -4.0, 0.0),                        CPThemeStateControlSizeSmall],

        // Non bezeled mini
        [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 0.0, -4.0, 0.0),                        CPThemeStateControlSizeMini],

        // Bezeled Normal
        [@"bezel-color",                bezelColor,                                             CPThemeStateBezeled],
        [@"bezel-color",                bezelColorEditing,                                      [CPThemeStateBezeled, CPThemeStateEditing]],
        [@"bezel-color",                FlatColorWhite,                                         [CPThemeStateBezeled, CPThemeStateDisabled]],
        [@"content-inset",              CGInsetMake(8.0, 0.0, 0.0, 6.0),                        CPThemeStateBezeled],
        [@"nib2cib-adjustment-frame",   CGRectMake(0.0, 0.0, 0.0, 0.0),                         CPThemeStateBezeled],
        [@"text-color",                 [CPColor blackColor],                                   [CPThemeStateBezeled, CPThemeStateDisabled]],

        // Bezeled Small
        [@"content-inset",              CGInsetMake(4.0, 6.0, 4.0, 6.0),                        [CPThemeStateBezeled, CPThemeStateControlSizeSmall]],
        [@"min-size",                   CGSizeMake(-1.0, 18.0),                                 CPThemeStateControlSizeSmall],
        [@"nib2cib-adjustment-frame",   CGRectMake(0.0, 1.0, 0.0, 1.0),                         [CPThemeStateBezeled, CPThemeStateControlSizeSmall]],

        // Bezeled Mini
        [@"content-inset",              CGInsetMake(3.0, 6.0, 3.0, 6.0),                        [CPThemeStateBezeled, CPThemeStateControlSizeMini]],
        [@"nib2cib-adjustment-frame",   CGRectMake(0.0, 0.0, 0.0, 0.0),                         [CPThemeStateBezeled, CPThemeStateControlSizeMini]],
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
    var textfield = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 29.0)];

    // // Global for reuse by CPSearchField
    // themedRoundedTextFieldValues =
    //     [
    //         [@"bezel-color",        [CPColor colorWithHexString:@"FFFFFF"],         [CPTextFieldStateRounded, CPThemeStateBezeled]],
    //         [@"bezel-color",        [CPColor colorWithHexString:@"FFFFFF"],         [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
    //         [@"bezel-color",        [CPColor colorWithHexString:@"FFFFFF"],         [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateDisabled]],
    //         [@"font",               [CPFont systemFontOfSize:12.0]],
    //
    //         [@"content-inset",  CGInsetMake(8.0, 7.0, 5.0, 10.0),   [CPTextFieldStateRounded, CPThemeStateBezeled]],
    //         [@"content-inset",  CGInsetMake(8.0, 7.0, 5.0, 10.0),   [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
    //
    //         [@"bezel-inset",    CGInsetMake(3.0, 4.0, 3.0, 4.0),    [CPTextFieldStateRounded, CPThemeStateBezeled]],
    //         [@"bezel-inset",    CGInsetMake(3.0, 4.0, 3.0, 4.0),    [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
    //
    //         [@"text-color",         placeholderColor,               [CPTextFieldStateRounded, CPTextFieldStatePlaceholder]],
    //         [@"text-color",         regularDisabledTextColor,       [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateDisabled]],
    //         [@"text-shadow-color",  regularDisabledTextShadowColor, [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateDisabled]],
    //
    //         [@"min-size",       CGSizeMake(0.0, 29.0),  [CPTextFieldStateRounded, CPThemeStateBezeled]],
    //         [@"max-size",       CGSizeMake(-1.0, 29.0), [CPTextFieldStateRounded, CPThemeStateBezeled]]
    //     ];

    [self registerThemeValues:themedTextFieldValues forView:textfield];

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

        imageSearch = PatternImage("search-field-search.png", 20.0, 17.0),
        imageFind = PatternImage("search-field-find.png", 20.0, 17.0),
        imageCancel = PatternImage("search-field-cancel.png", 22.0, 22.0),
        imageCancelPressed = PatternImage("search-field-cancel-pressed.png", 22.0, 22.0),

        overrides =
        [
            [@"image-search", imageSearch],
            [@"image-find", imageFind],
            [@"image-cancel", imageCancel],
            [@"image-cancel-pressed", imageCancelPressed]
        ];

    [self registerThemeValues:overrides forView:searchField inherit:themedTextFieldValues];

    return searchField;
}

+ (CPDatePicker)themedDatePicker
{
    var datePicker = [[CPDatePicker alloc] initWithFrame:CGRectMake(40.0 ,40.0 ,170.0 ,29.0)],
        bezelColor = PatternColor([
            ["textfield-bezel-border.png", 1.0, 1.0],
            ["textfield-bezel-border.png", 1.0, 1.0],
            ["textfield-bezel-border.png", 1.0, 1.0],
            ["textfield-bezel-border.png", 1.0, 1.0],
            ["textfield-bezel-middle.png", 1.0, 1.0],
            ["textfield-bezel-border.png", 1.0, 1.0],
            ["textfield-bezel-border.png", 1.0, 1.0],
            ["textfield-bezel-border.png", 1.0, 1.0],
            ["textfield-bezel-border.png", 1.0, 1.0],
            ], PatternIsHorizontal),
        bezelColorEditing = PatternColor([
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
            ["textfield-bezel-middle.png", 1.0, 1.0],
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
            ["textfield-bezel-highlighted-border.png", 1.0, 1.0],
        ], PatternIsHorizontal),

        themeValues =
        [
            [@"bezel-color",                bezelColor,                                             CPThemeStateBezeled],
            [@"bezel-color",                bezelColorEditing,                                      [CPThemeStateBezeled, CPThemeStateEditing]],
            [@"bezel-color",                FlatColorWhite,                                         [CPThemeStateBezeled, CPThemeStateDisabled]],

            [@"font",               [CPFont systemFontOfSize:13.0]],
            [@"text-color",         [CPColor colorWithWhite:0.2 alpha:0.5], CPThemeStateDisabled],

            [@"content-inset",      CGInsetMake(6.0, 0.0, 0.0, 3.0),    CPThemeStateNormal],
            [@"content-inset",      CGInsetMake(3.0, 0.0, 0.0, 3.0),    CPThemeStateBezeled],
            [@"bezel-inset",        CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateBezeled],

            [@"datepicker-textfield-bezel-color", [CPColor clearColor],                     CPThemeStateNormal],
            [@"datepicker-textfield-bezel-color", [CPColor colorWithHexString:@"B4D5FE"],   CPThemeStateSelected],
            [@"datepicker-textfield-bezel-color", [CPColor clearColor],                     [CPThemeStateNormal, CPThemeStateDisabled]],
            [@"datepicker-textfield-bezel-color", [CPColor clearColor],                     [CPThemeStateSelected, CPThemeStateDisabled]],

            [@"min-size-datepicker-textfield", CGSizeMake(6.0, 18.0)],

            [@"separator-content-inset", CGInsetMake(0.0, -2.0, 0.0, -1.0)],

            [@"content-inset-datepicker-textfield",  CGInsetMake(3.0, 2.0, 0.0, 1.0),           CPThemeStateNormal],
            [@"content-inset-datepicker-textfield-separator",CGInsetMake(3.0, 0.0, 0.0, 0.0),   CPThemeStateNormal],
            [@"content-inset-datepicker-textfield",  CGInsetMake(3.0, 2.0, 0.0, 1.0) ,          CPThemeStateSelected],
            [@"content-inset-datepicker-textfield-separator",CGInsetMake(3.0, 0.0, 0.0, 0.0),   CPThemeStateSelected],

            [@"date-hour-margin", 7.0],
            [@"stepper-margin", 0.0],

            [@"min-size",       CGSizeMake(0.0, 29.0)],
            [@"max-size",       CGSizeMake(-1.0, 29.0)],

            // CPThemeStateControlSizeSmall
            [@"content-inset",      CGInsetMake(4.0, 0.0, 0.0, 1.0),                            [CPThemeStateControlSizeSmall, CPThemeStateNormal]],
            [@"content-inset",      CGInsetMake(0.0, 0.0, 0.0, 1.0),                            [CPThemeStateControlSizeSmall, CPThemeStateBezeled]],
            [@"min-size-datepicker-textfield", CGSizeMake(6.0, 16.0),                           CPThemeStateControlSizeSmall],
            [@"date-hour-margin", 5.0,                                                          CPThemeStateControlSizeSmall],
            [@"stepper-margin", 0.0,                                                            CPThemeStateControlSizeSmall],
            [@"min-size",       CGSizeMake(0, 24.0),                                            CPThemeStateControlSizeSmall],
            [@"max-size",       CGSizeMake(-1.0, 24.0),                                         CPThemeStateControlSizeSmall],
            [@"font",           [CPFont systemFontOfSize:11.0],                                 CPThemeStateControlSizeSmall],

            [@"nib2cib-adjustment-frame",   CGRectMake(0.0, 4.0, -3.0, 0.0)],
            [@"nib2cib-adjustment-frame",   CGRectMake(0.0, 6.0, -4.0, 0.0),                           CPThemeStateControlSizeSmall],
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
            [@"title-text-shadow-offset",   CGSizeMakeZero()],
            [@"title-font",                 [CPFont boldSystemFontOfSize:12.0]],

            [@"title-text-color",           [CPColor colorWithCalibratedRed:79.0 / 255.0 green:79.0 / 255.0 blue:79.0 / 255.0 alpha:0.5],       CPThemeStateDisabled],
            [@"title-text-shadow-color",    [CPColor whiteColor],                                                                               CPThemeStateDisabled],
            [@"title-text-shadow-offset",   CGSizeMakeZero(),                                                                                   CPThemeStateDisabled],
            [@"title-font",                 [CPFont boldSystemFontOfSize:12.0],                                                                 CPThemeStateDisabled],

            [@"weekday-text-color",         [CPColor colorWithCalibratedRed:79.0 / 255.0 green:79.0 / 255.0 blue:79.0 / 255.0 alpha:1.0]],
            [@"weekday-text-shadow-color",  [CPColor whiteColor]],
            [@"weekday-text-shadow-offset", CGSizeMakeZero()],
            [@"weekday-font",               [CPFont systemFontOfSize:11.0]],

            [@"weekday-text-color",         [CPColor colorWithCalibratedRed:79.0 / 255.0 green:79.0 / 255.0 blue:79.0 / 255.0 alpha:0.5],       CPThemeStateDisabled],
            [@"weekday-text-shadow-color",  [CPColor whiteColor],                                                                               CPThemeStateDisabled],
            [@"weekday-text-shadow-offset", CGSizeMakeZero(),                                                                                   CPThemeStateDisabled],
            [@"weekday-font",               [CPFont systemFontOfSize:11.0],                                                                     CPThemeStateDisabled],

            [@"clock-text-color",           [CPColor colorWithCalibratedRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:1.0]],
            [@"clock-text-shadow-color",    [CPColor whiteColor]],
            [@"clock-text-shadow-offset",   CGSizeMakeZero()],
            [@"clock-font",                 [CPFont systemFontOfSize:11.0]],

            [@"clock-text-color",           [CPColor colorWithCalibratedRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:0.5],    CPThemeStateDisabled],
            [@"clock-text-shadow-color",    [CPColor whiteColor],                                                                               CPThemeStateDisabled],
            [@"clock-text-shadow-offset",   CGSizeMakeZero(),                                                                                   CPThemeStateDisabled],
            [@"clock-font",                 [CPFont systemFontOfSize:11.0],                                                                     CPThemeStateDisabled],

            [@"tile-text-color",            [CPColor colorWithCalibratedRed:34.0 / 255.0 green:34.0 / 255.0 blue:34.0 / 255.0 alpha:1.0],       CPThemeStateNormal],
            [@"tile-text-shadow-color",     [CPColor whiteColor],                                                                               CPThemeStateNormal],
            [@"tile-text-shadow-offset",    CGSizeMakeZero(),                                                                                   CPThemeStateNormal],
            [@"tile-font",                  [CPFont systemFontOfSize:10.0],                                                                     CPThemeStateNormal],

            [@"tile-text-color",            [CPColor colorWithCalibratedRed:87.0 / 255.0 green:128.0 / 255.0 blue:216.0 / 255.0 alpha:1.0],     CPThemeStateHighlighted],
            [@"tile-text-shadow-color",     [CPColor whiteColor],                                                                               CPThemeStateHighlighted],
            [@"tile-text-shadow-offset",    CGSizeMakeZero(),                                                                                   CPThemeStateHighlighted],
            [@"tile-font",                  [CPFont systemFontOfSize:10.0],                                                                     CPThemeStateHighlighted],

            [@"tile-text-color",            [CPColor colorWithCalibratedRed:87.0 / 255.0 green:128.0 / 255.0 blue:216.0 / 255.0 alpha:0.5],     [CPThemeStateHighlighted, CPThemeStateDisabled]],
            [@"tile-text-shadow-color",     [CPColor whiteColor],                                                                               [CPThemeStateHighlighted, CPThemeStateDisabled]],
            [@"tile-text-shadow-offset",    CGSizeMakeZero(),                                                                                   [CPThemeStateHighlighted, CPThemeStateDisabled]],
            [@"tile-font",                  [CPFont systemFontOfSize:10.0],                                                                     [CPThemeStateHighlighted, CPThemeStateDisabled]],

            [@"tile-text-color",            [CPColor whiteColor],                                                                               [CPThemeStateHighlighted, CPThemeStateSelected]],
            [@"tile-text-shadow-color",     [CPColor colorWithCalibratedRed:0.0 / 255.0 green:0.0 / 255.0 blue:0.0 / 255.0 alpha:0.2],          [CPThemeStateHighlighted, CPThemeStateSelected]],
            [@"tile-text-shadow-offset",    CGSizeMakeZero(),                                                                                   [CPThemeStateHighlighted, CPThemeStateSelected]],
            [@"tile-font",                  [CPFont systemFontOfSize:10.0],                                                                     [CPThemeStateHighlighted, CPThemeStateSelected]],

            [@"tile-text-color",            [CPColor whiteColor],                                                                               CPThemeStateSelected],
            [@"tile-text-shadow-color",     [CPColor colorWithCalibratedRed:0.0 / 255.0 green:0.0 / 255.0 blue:0.0 / 255.0 alpha:0.2],          CPThemeStateSelected],
            [@"tile-text-shadow-offset",    CGSizeMakeZero(),                                                                                   CPThemeStateSelected],
            [@"tile-font",                  [CPFont systemFontOfSize:10.0],                                                                     CPThemeStateSelected],

            [@"tile-text-color",            [CPColor colorWithCalibratedRed:179.0 / 255.0 green:179.0 / 255.0 blue:179.0 / 255.0 alpha:1.0],    CPThemeStateDisabled],
            [@"tile-text-shadow-color",     [CPColor whiteColor],                                                                               CPThemeStateDisabled],
            [@"tile-text-shadow-offset",    CGSizeMakeZero(),                                                                                   CPThemeStateDisabled],
            [@"tile-font",                  [CPFont systemFontOfSize:10.0],                                                                     CPThemeStateDisabled],

            [@"tile-text-color",            [CPColor colorWithCalibratedRed:255.0 / 255.0 green:255.0 / 255.0 blue:255.0 / 255.0 alpha:0.5],    [CPThemeStateDisabled, CPThemeStateSelected, CPThemeStateHighlighted]],
            [@"tile-text-shadow-color",     [CPColor colorWithCalibratedRed:0.0 / 255.0 green:0.0 / 255.0 blue:0.0 / 255.0 alpha:0.2],          [CPThemeStateDisabled, CPThemeStateSelected, CPThemeStateHighlighted]],
            [@"tile-text-shadow-offset",    CGSizeMakeZero(),                                                                                   [CPThemeStateDisabled, CPThemeStateSelected, CPThemeStateHighlighted]],
            [@"tile-font",                  [CPFont systemFontOfSize:10.0],                                                                     [CPThemeStateDisabled, CPThemeStateSelected, CPThemeStateHighlighted]],

            [@"tile-text-color",            [CPColor colorWithCalibratedRed:255.0 / 255.0 green:255.0 / 255.0 blue:255.0 / 255.0 alpha:0.5],    [CPThemeStateDisabled, CPThemeStateSelected]],
            [@"tile-text-shadow-color",     [CPColor colorWithCalibratedRed:0.0 / 255.0 green:0.0 / 255.0 blue:0.0 / 255.0 alpha:0.2],          [CPThemeStateDisabled, CPThemeStateSelected]],
            [@"tile-text-shadow-offset",    CGSizeMakeZero(),                                                                                   [CPThemeStateDisabled, CPThemeStateSelected]],
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

+ (CPCheckBox)themedCheckBoxButton
{
    var button                        = [CPCheckBox checkBoxWithTitle:@"Checkbox"],
        imageNormal                   = PatternImage("check-box-image.png", 12.0, 12.0),
        imageSelected                 = PatternImage("check-box-image-selected.png", 12.0, 12.0),
        imageSelectedHighlighted      = PatternImage("check-box-image-selected-highlighted.png", 12.0, 12.0),
        imageHighlighted              = PatternImage("check-box-image-highlighted.png", 12.0, 12.0),

        smallImageNormal              = PatternImage("check-box-image.png", 10.0, 10.0),
        smallImageSelected            = PatternImage("check-box-image-selected.png", 10.0, 10.0),
        smallImageSelectedHighlighted = PatternImage("check-box-image-selected-highlighted.png", 10.0, 10.0),
        smallImageHighlighted         = PatternImage("check-box-image-highlighted.png", 10.0, 10.0),

        miniImageNormal              = PatternImage("check-box-image.png", 8.0, 8.0),
        miniImageSelected            = PatternImage("check-box-image-selected.png", 8.0, 8.0),
        miniImageSelectedHighlighted = PatternImage("check-box-image-selected-highlighted.png", 8.0, 8.0),
        miniImageHighlighted         = PatternImage("check-box-image-highlighted.png", 8.0, 8.0),

        themedCheckBoxValues =
        [
            [@"alignment",                  CPLeftTextAlignment,                CPThemeStateNormal],
            [@"content-inset",              CGInsetMakeZero(),                  CPThemeStateNormal],
            [@"image-offset",               CPCheckBoxImageOffset],
            [@"font",                       [CPFont systemFontOfSize:12.0]],
            [@"text-color",                 regularDisabledTextColor,           CPThemeStateDisabled],

            // regular
            [@"image",                      imageNormal,                        CPThemeStateNormal],
            [@"image",                      imageHighlighted,                   [CPThemeStateNormal, CPThemeStateHighlighted]],
            [@"image",                      imageSelected,                      CPThemeStateSelected],
            [@"image",                      imageSelectedHighlighted,           [CPThemeStateSelected, CPThemeStateHighlighted]],
            [@"image",                      imageNormal,                        CPThemeStateDisabled],
            [@"image",                      imageSelected,                      [CPThemeStateSelected, CPThemeStateDisabled]],
            [@"min-size",                   CGSizeMake(12.0, 12.0)],
            [@"max-size",                   CGSizeMake(-1.0, -1.0)],
            [@"nib2cib-adjustment-frame",   CGRectMake(2.0, -1.0, 0.0, 0.0)],

            // small
            [@"image",                      smallImageNormal,                   [CPThemeStateControlSizeSmall, CPThemeStateNormal]],
            [@"image",                      smallImageHighlighted,              [CPThemeStateControlSizeSmall, CPThemeStateNormal, CPThemeStateHighlighted]],
            [@"image",                      smallImageSelected,                 [CPThemeStateControlSizeSmall, CPThemeStateSelected]],
            [@"image",                      smallImageSelectedHighlighted,      [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateHighlighted]],
            [@"image",                      smallImageNormal,                   [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
            [@"image",                      smallImageSelected,                 [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateDisabled]],
            [@"min-size",                   CGSizeMake(10.0, 10.0),             CPThemeStateControlSizeSmall],
            [@"max-size",                   CGSizeMake(-1.0, -1.0),             CPThemeStateControlSizeSmall],
            [@"nib2cib-adjustment-frame",   CGRectMake(3.0, -2.0, 0.0, 0.0),     CPThemeStateControlSizeSmall],

            // mini
            [@"image",                      miniImageNormal,                    [CPThemeStateControlSizeMini, CPThemeStateNormal]],
            [@"image",                      miniImageHighlighted,               [CPThemeStateControlSizeMini, CPThemeStateNormal, CPThemeStateHighlighted]],
            [@"image",                      miniImageSelected,                  [CPThemeStateControlSizeMini, CPThemeStateSelected]],
            [@"image",                      miniImageSelectedHighlighted,       [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateHighlighted]],
            [@"image",                      miniImageNormal,                    [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
            [@"image",                      miniImageSelected,                  [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateDisabled]],
            [@"min-size",                   CGSizeMake(8.0, 8.0),               CPThemeStateControlSizeMini],
            [@"max-size",                   CGSizeMake(-1.0, -1.0),             CPThemeStateControlSizeMini],
            [@"nib2cib-adjustment-frame",   CGRectMake(4.0, -2.0, 0.0, 0.0),     CPThemeStateControlSizeMini],
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

    // var mixedHighlightedImage = PatternImage("check-box-image-mixed-highlighted.png", 21.0, 21.0),
    //     mixedDisabledImage = PatternImage("check-box-image-mixed.png", 21.0, 21.0),
    //     mixedImage = PatternImage("check-box-image-mixed.png", 21.0, 21.0),
    //
    //     themeValues =
    //     [
    //         [@"image",          mixedImage,             CPButtonStateMixed],
    //         [@"image",          mixedHighlightedImage,  CPButtonStateMixed | CPThemeStateHighlighted],
    //         [@"image",          mixedDisabledImage,     CPButtonStateMixed | CPThemeStateDisabled],
    //         [@"image-offset",   CPCheckBoxImageOffset,  CPButtonStateMixed],
    //         [@"max-size",       CGSizeMake(-1.0, -1.0)]
    //     ];
    //
    // [self registerThemeValues:themeValues forView:button];

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

        themedSegmentedControlValues =
        [
                [@"center-segment-bezel-color",     FlatColorGrey,       CPThemeStateNormal],
                [@"center-segment-bezel-color",     FlatColorGreyLight,  CPThemeStateDisabled],
                [@"center-segment-bezel-color",     FlatColorGreyDark,   [CPThemeStateSelected, CPThemeStateDisabled]],
                [@"center-segment-bezel-color",     FlatColorBlue,       CPThemeStateSelected],
                [@"center-segment-bezel-color",     FlatColorGreyDark,   CPThemeStateHighlighted],
                [@"center-segment-bezel-color",     FlatColorBlue,       [CPThemeStateHighlighted, CPThemeStateSelected]],
                [@"divider-bezel-color",            FlatColorGrey,       CPThemeStateNormal],
                [@"divider-bezel-color",            FlatColorGreyLight,  CPThemeStateDisabled],
                [@"divider-bezel-color",            FlatColorGreyDark,   [CPThemeStateSelected, CPThemeStateDisabled]],
                [@"divider-bezel-color",            FlatColorBlue,       CPThemeStateSelected],
                [@"left-segment-bezel-color",       FlatColorGrey,       CPThemeStateNormal],
                [@"left-segment-bezel-color",       FlatColorGreyLight,  CPThemeStateDisabled],
                [@"left-segment-bezel-color",       FlatColorGreyDark,   [CPThemeStateSelected, CPThemeStateDisabled]],
                [@"left-segment-bezel-color",       FlatColorBlue,       CPThemeStateSelected],
                [@"left-segment-bezel-color",       FlatColorGreyDark,   CPThemeStateHighlighted],
                [@"left-segment-bezel-color",       FlatColorBlue,       [CPThemeStateHighlighted, CPThemeStateSelected]],

                [@"right-segment-bezel-color",      FlatColorGrey,       CPThemeStateNormal],
                [@"right-segment-bezel-color",      FlatColorGreyLight,  CPThemeStateDisabled],
                [@"right-segment-bezel-color",      FlatColorGreyDark,   [CPThemeStateSelected, CPThemeStateDisabled]],
                [@"right-segment-bezel-color",      FlatColorBlue,       CPThemeStateSelected],
                [@"right-segment-bezel-color",      FlatColorGreyDark,   CPThemeStateHighlighted],
                [@"right-segment-bezel-color",      FlatColorBlue,       [CPThemeStateHighlighted, CPThemeStateSelected]],

                [@"content-inset",  CGInsetMake(0.0, 4.0, 0.0, 4.0), CPThemeStateNormal],
                [@"bezel-inset",    CGInsetMake(0.0, 0.0, 0.0, 0.0), CPThemeStateNormal],

                [@"min-size",                   CGSizeMake(-1.0, 24.0)],
                [@"max-size",                   CGSizeMake(-1.0, 24.0)],
                [@"nib2cib-adjustment-frame",   CGRectMake(1.0, 1.0, -3.0, 0.0)],

                [@"min-size",                   CGSizeMake(-1.0, 20.0),                             CPThemeStateControlSizeSmall],
                [@"max-size",                   CGSizeMake(-1.0, 20.0),                             CPThemeStateControlSizeSmall],
                [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 0.0, -4.0, 0.0),                    CPThemeStateControlSizeSmall],

                [@"min-size",                   CGSizeMake(-1.0, 15.0),                             CPThemeStateControlSizeMini],
                [@"max-size",                   CGSizeMake(-1.0, 15.0),                             CPThemeStateControlSizeMini],
                [@"nib2cib-adjustment-frame",   CGRectMake(1.0, 0.0, -2.0, 0.0),                    CPThemeStateControlSizeMini],

                [@"font",               [CPFont boldSystemFontOfSize:12.0]],
                [@"text-color",         regularTextColor],
                [@"text-color",         regularDisabledTextColor,   CPThemeStateDisabled],

                // The "default" button state is the same theme color as the "selected" segmented control state, so we can use
                // the same text theme values.
                [@"text-color",         defaultTextColor,           CPThemeStateSelected],
                [@"text-color",         defaultDisabledTextColor,   [CPThemeStateDisabled, CPThemeStateSelected]],
                [@"text-shadow-color",  regularTextShadowColor],
                [@"text-shadow-color",  regularDisabledTextShadowColor, CPThemeStateDisabled],
                [@"text-shadow-color",  defaultDisabledTextShadowColor, [CPThemeStateDisabled, CPThemeStateSelected]],
                [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:0.0 alpha:0.2], CPThemeStateSelected],
                [@"text-shadow-offset", CGSizeMakeZero()],
                [@"text-shadow-offset", CGSizeMakeZero(), CPThemeStateSelected],
                [@"text-shadow-offset", CGSizeMakeZero(), [CPThemeStateSelected, CPThemeStateDisabled]],
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

        themedHorizontalSliderValues =
        [
            [@"track-width", 5.0],
            [@"track-color", FlatColorGrey],
            [@"track-color", FlatColorGreyLight, CPThemeStateDisabled],

            [@"knob-size",  CGSizeMake(7.0, 7.0)],
            [@"knob-color", FlatColorBlue],
            [@"knob-color", FlatColorBlueDark,   CPThemeStateHighlighted],
            [@"knob-color", FlatColorBlueLight,      CPThemeStateDisabled]
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
    return [self themedHorizontalSlider];
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
        resizeColor = PatternColor("buttonbar-resize-control.png", 5.0, 10.0),
        buttonImagePlus = PatternImage("buttonbar-image-plus.png", 16.0, 16.0),
        buttonImageMinus = PatternImage("buttonbar-image-minus.png", 16.0, 16.0),
        buttonImageAction = PatternImage("buttonbar-image-action.png", 22.0, 14.0),

        themedButtonBarValues =
        [
            [@"bezel-color",            FlatColorWhite],

            [@"resize-control-size",    CGSizeMake(5.0, 10.0)],
            [@"resize-control-inset",   CGInsetMake(9.0, 4.0, 7.0, 4.0)],
            [@"resize-control-color",   resizeColor],

            [@"button-bezel-color",     [CPColor clearColor]],
            [@"button-bezel-color",     FlatColorGreyLight,  CPThemeStateHighlighted],
            [@"button-bezel-color",     [CPColor clearColor],      CPThemeStateDisabled],
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

        themedColumnHeaderValues =
        [
            [@"background-color",   FlatColorGreyLight],

            [@"text-inset",         CGInsetMake(0, 5, 0, 5)],
            [@"text-color",         [CPColor colorWithHexString:@"808080"]],
            [@"font",               [CPFont boldSystemFontOfSize:11.0]],
            [@"text-shadow-color",  [CPColor whiteColor]],
            [@"text-shadow-offset", CGSizeMakeZero()],
            [@"text-alignment",     CPLeftTextAlignment],
            [@"line-break-mode",    CPLineBreakByTruncatingTail],

            [@"background-color",   FlatColorGreyLight,      CPThemeStateHighlighted],
            [@"background-color",   FlatColorGreyLight,      CPThemeStateSelected],
            [@"background-color",   FlatColorGreyLight,      [CPThemeStateHighlighted, CPThemeStateSelected]]
        ];

    [self registerThemeValues:themedColumnHeaderValues forView:header];

    return header;
}

+ (CPTableHeaderView)themedTableHeaderRow
{
    var header = [[CPTableHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 25.0)];

    [header setValue:FlatColorGreyLight forThemeAttribute:@"background-color"];
    [header setValue:FlatColorGreyLight forThemeAttribute:@"divider-color"];

    return header;
}

+ (_CPCornerView)themedCornerview
{
    var scrollerWidth = [CPScroller scrollerWidth],
        corner = [[_CPCornerView alloc] initWithFrame:CGRectMake(0.0, 0.0, scrollerWidth, 25.0)];

    [corner setValue:FlatColorGreyLight forThemeAttribute:"background-color"];
    [corner setValue:FlatColorGreyLight forThemeAttribute:"divider-color"];

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
            [@"selection-color",                        FlatColorBlue],
            [@"sourcelist-selection-color",             sourceListSelectionColor],
            [@"sort-image",                             sortImage],
            [@"sort-image-reversed",                    sortImageReversed],
            [@"image-generic-file",                     imageGenericFile],
            [@"default-row-height",                     25.0],

            [@"dropview-on-background-color",           [CPColor colorWithRed:224 / 255 green:254 / 255 blue:131 / 255 alpha:0.25]],
            [@"dropview-on-border-color",               [CPColor colorWithHexString:@"E0FE83"]],
            [@"dropview-on-border-width",               2.0],
            [@"dropview-on-border-radius",              0.0],

            [@"dropview-on-selected-background-color",  [CPColor clearColor]],
            [@"dropview-on-selected-border-color",      [CPColor whiteColor]],
            [@"dropview-on-selected-border-width",      2.0],
            [@"dropview-on-selected-border-radius",     0.0],

            [@"dropview-above-border-color",            FlatColorBlueDark],
            [@"dropview-above-border-width",            4.0],

            [@"dropview-above-selected-border-color",   FlatColorBlueDark],
            [@"dropview-above-selected-border-width",   4.0],
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
            [@"pane-divider-color", FlatColorGreyLight],
            [@"horizontal-divider-color", horizontalDividerColor],
            [@"vertical-divider-color", verticalDividerColor]
        ];

    [self registerThemeValues:themedSplitViewValues forView:splitView];

    return splitView;
}

+ (CPStepper)themedStepper
{
    var stepper = [CPStepper stepper],
        bezelUp           = PatternColor(@"stepper-up-button.png", 25, 12),
        bezelDown         = PatternColor(@"stepper-down-button.png", 25, 11),
        bezelUpPressed    = PatternColor(@"stepper-up-button-pressed.png", 25, 12),
        bezelDownPressed  = PatternColor(@"stepper-down-button-pressed.png", 25, 12),
        bezelUpDisabled   = PatternColor(@"stepper-up-button-disabled.png", 25, 11),
        bezelDownDisabled = PatternColor(@"stepper-down-button-disabled.png", 25, 11),

        smallBezelUp           = PatternColor(@"stepper-up-button.png", 20, 10),
        smallBezelDown         = PatternColor(@"stepper-down-button.png", 20, 8),
        smallBezelUpPressed    = PatternColor(@"stepper-up-button-pressed.png", 20, 10),
        smallBezelDownPressed  = PatternColor(@"stepper-down-button-pressed.png", 20, 8),
        smallBezelUpDisabled   = PatternColor(@"stepper-up-button-disabled.png", 20, 10),
        smallBezelDownDisabled = PatternColor(@"stepper-down-button-disabled.png", 20, 8),

        themeValues =
        [
            // regular
            [@"bezel-color-down-button",    bezelDown,                          CPThemeStateBordered],
            [@"bezel-color-down-button",    bezelDownDisabled,                  [CPThemeStateBordered, CPThemeStateDisabled]],
            [@"bezel-color-down-button",    bezelDownPressed,                   [CPThemeStateBordered, CPThemeStateHighlighted]],
            [@"bezel-color-up-button",      bezelUp,                            CPThemeStateBordered],
            [@"bezel-color-up-button",      bezelUpDisabled,                    [CPThemeStateBordered, CPThemeStateDisabled]],
            [@"bezel-color-up-button",      bezelUpPressed,                     [CPThemeStateBordered, CPThemeStateHighlighted]],
            [@"down-button-size",           CGSizeMake(25.0, 11.0)],
            [@"up-button-size",             CGSizeMake(25.0, 12.0)],
            [@"nib2cib-adjustment-frame",   CGRectMake(2.0, -25.0, 0.0, 0.0)],

            // small
            [@"bezel-color-down-button",    smallBezelDown,                     [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
            [@"bezel-color-down-button",    smallBezelDownDisabled,             [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],
            [@"bezel-color-down-button",    smallBezelDownPressed,              [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateHighlighted]],
            [@"bezel-color-up-button",      smallBezelUp,                       [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
            [@"bezel-color-up-button",      smallBezelUpDisabled,               [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],
            [@"bezel-color-up-button",      smallBezelUpPressed,                [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateHighlighted]],
            [@"down-button-size",           CGSizeMake(20.0, 8.0),              CPThemeStateControlSizeSmall],
            [@"up-button-size",             CGSizeMake(20.0, 10.0),             CPThemeStateControlSizeSmall],
            [@"nib2cib-adjustment-frame",   CGRectMake(2.0, -21.0, 0.0, 0.0),    CPThemeStateControlSizeSmall],
        ];

    [self registerThemeValues:themeValues forView:stepper];

    return stepper;
}

+ (CPRuleEditor)themedRuleEditor
{
    var ruleEditor                  = [[CPRuleEditor alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 300.0)],
        backgroundColors           = [FlatColorWhite, FlatColorWhite],
        selectedActiveRowColor     = FlatColorWhite,
        selectedInactiveRowColor   = FlatColorWhite,
        sliceTopBorderColor        = FlatColorGreyLighter,
        sliceBottomBorderColor     = FlatColorGreyLighter,
        sliceLastBottomBorderColor = FlatColorWhite,
        addImage                   = PatternImage(@"rule-editor-add.png", 16.0, 16.0),
        removeImage                = PatternImage(@"rule-editor-remove.png", 16.0, 16.0),

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
            [@"remove-image",                   removeImage],
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
            [@"stroke-color",       FlatColorGreyDark],
            [@"stroke-width",       1.0],
            [@"border-radius",      0.0],
            [@"background-color",   FlatColorGreyLight],
            [@"color",              [CPColor blackColor]]
        ];

    [self registerThemeValues:themeValues forView:toolTipView];

    return toolTipView;
}

+ (CPBox)themedBox
{
    var box = [[CPBox alloc] initWithFrame:CGRectMake(0, 0, 100, 100)],

        themeValues =
        [
            [@"background-color", FlatColorGreyLighter],
            [@"border-width", 1.0],
            [@"border-color", FlatColorGreyLight],
            [@"corner-radius", 3.0],
            [@"inner-shadow-offset", CGSizeMakeZero()],
            [@"inner-shadow-color", nil],
            [@"inner-shadow-size", 6.0],
            [@"content-margin", CGSizeMakeZero()]
        ];

    [self registerThemeValues:themeValues forView:box];

    return box;
}

+ (CPShadowView)themedShadowView
{
    var shadowView = [[CPShadowView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100, 100)],

        themedShadowViewValues =
        [
            [@"content-inset",      CGInsetMake(3.0, 3.0, 5.0, 3.0),    CPThemeStateShadowViewLight],
            [@"content-inset",      CGInsetMake(5.0, 7.0, 5.0, 7.0),    CPThemeStateShadowViewHeavy]
        ];

    [self registerThemeValues:themedShadowViewValues forView:shadowView];

    return shadowView;
}

+ (_CPModalWindowView)themedModalWindowView
{
    var modalWindowView = [[_CPModalWindowView alloc] initWithFrame:CGRectMake(0, 0, 200, 200) styleMask:_CPModalWindowView],

        themeValues =
        [
            [@"bezel-color", FlatColorWindowBody]
        ];

    [self registerThemeValues:themeValues forView:modalWindowView];

    return modalWindowView;
}

+ (_CPWindowView)themedWindowView
{
    var windowView = [[_CPWindowView alloc] initWithFrame:CGRectMakeZero(0.0, 0.0, 200, 200)],
        sheetShadow = PatternColor(@"window-attached-sheet-shadow.png", 1, 8),
        resizeIndicator = PatternImage(@"window-resize-indicator.png", 12, 12);

    // Global
    themedWindowViewValues =
    [
        [@"shadow-inset",                   CGInsetMake(10.0, 19.0, 10.0, 20.0)],
        [@"shadow-distance",                5.0],
        [@"window-shadow-color",            nil],
        [@"resize-indicator",               resizeIndicator],
        [@"attached-sheet-shadow-color",    sheetShadow],
        [@"shadow-height",                  8],
        [@"size-indicator",                 CGSizeMake(12, 12)]
    ];

    [self registerThemeValues:themedWindowViewValues forView:windowView];

    return windowView;
}

+ (_CPStandardWindowView)themedStandardWindowView
{
    var standardWindowView = [[_CPStandardWindowView alloc] initWithFrame:CGRectMake(0, 0, 200, 200) styleMask:CPClosableWindowMask],

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
            [@"bezel-head-color",           FlatColorWindowBody, CPThemeStateNormal],
            [@"bezel-head-color",           FlatColorWindowBody, CPThemeStateKeyWindow],
            [@"bezel-head-color",           FlatColorWindowBody, CPThemeStateMainWindow],
            [@"bezel-head-sheet-color",     FlatColorWindowBody],
            [@"solid-color",                FlatColorWindowBody],

            [@"title-font",                 [CPFont systemFontOfSize:CPFontCurrentSystemSize]],
            [@"title-text-color",           FlatColorGrey],
            [@"title-text-color",           FlatColorBlue, CPThemeStateKeyWindow],
            [@"title-text-color",           FlatColorBlue, CPThemeStateMainWindow],
            [@"title-text-shadow-color",    [CPColor whiteColor]],
            [@"title-text-shadow-offset",   CGSizeMakeZero()],
            [@"title-alignment",            CPCenterTextAlignment],

            // FIXME: Make this to CPLineBreakByTruncatingMiddle once it's implemented.
            [@"title-line-break-mode",      CPLineBreakByTruncatingTail],
            [@"title-vertical-alignment",   CPCenterVerticalTextAlignment],
            [@"title-bar-height",           31],

            [@"divider-color",              FlatColorGreyLighter],
            [@"body-color",                 FlatColorWindowBody],
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

        themeValues =
        [
            [@"body-color", FlatColorWindowBody],
            [@"shadow-height", 0]
        ];

    [self registerThemeValues:themeValues forView:docModalWindowView inherit:themedWindowViewValues];

    return docModalWindowView;
}

+ (_CPBorderlessBridgeWindowView)themedBorderlessBridgeWindowView
{
    var bordelessBridgeWindowView = [[_CPBorderlessBridgeWindowView alloc] initWithFrame:CGRectMake(0,0,0,0)],

        themeValues =
        [
            [@"toolbar-background-color", FlatColorGreyLight]
        ];

    [self registerThemeValues:themeValues forView:bordelessBridgeWindowView inherit:themedWindowViewValues];

    return bordelessBridgeWindowView;
}

+ (_CPToolbarView)themedToolbarView
{
    var toolbarView = [[_CPToolbarView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 59.0)],

        toolbarExtraItemsImage = PatternImage(@"toolbar-view-extra-items-image.png", 10.0, 15.0),
        toolbarExtraItemsAlternateImage = PatternImage(@"toolbar-view-extra-items-alternate-image.png", 10.0, 15.0),

        themeValues =
        [
            [@"extra-item-extra-image",                 toolbarExtraItemsImage],
            [@"extra-item-extra-alternate-image",       toolbarExtraItemsAlternateImage],
            [@"item-margin",                            10.0],
            [@"extra-item-width",                       20.0],
            [@"content-inset",                          CGInsetMake(4.0, 4.0, 4.0, 10)],
            [@"regular-size-height",                    59.0],
            [@"small-size-height",                      46.0],
            [@"image-item-separator-color",             FlatColorGreyDark],
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
            [@"menu-item-selection-color",                                  FlatColorBlue],
            [@"menu-item-text-color",                                       [CPColor colorWithHexString:@"333333"]],
            [@"menu-item-text-shadow-color",                                nil],
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

        backgroundColor = bezelColor = PatternColor([
            ["menu-backgroundcolor-border.png", 1.0, 1.0],
            ["menu-backgroundcolor-border.png", 1.0, 1.0],
            ["menu-backgroundcolor-border.png", 1.0, 1.0],
            ["menu-backgroundcolor-border.png", 1.0, 1.0],
            ["menu-backgroundcolor-middle.png", 1.0, 1.0],
            ["menu-backgroundcolor-border.png", 1.0, 1.0],
            ["menu-backgroundcolor-border.png", 1.0, 1.0],
            ["menu-backgroundcolor-border.png", 1.0, 1.0],
            ["menu-backgroundcolor-border.png", 1.0, 1.0],
        ], PatternIsHorizontal),

        themeValues =
        [
            [@"menu-window-more-above-image",                       menuWindowMoreAboveImage],
            [@"menu-window-more-below-image",                       menuWindowMoreBelowImage],
            [@"menu-window-pop-up-background-style-color",          backgroundColor],
            [@"menu-window-menu-bar-background-style-color",        backgroundColor],
            [@"menu-window-margin-inset",                           CGInsetMake(1, 1, 1, 1)],
            [@"menu-window-scroll-indicator-height",                16.0],

            [@"menu-bar-window-background-color",                   FlatColorGreyLight],
            [@"menu-bar-window-background-selected-color",          FlatColorBlue],
            [@"menu-bar-window-font",                               [CPFont systemFontOfSize:[CPFont systemFontSize]]],
            [@"menu-bar-window-height",                             30.0],
            [@"menu-bar-window-margin",                             10.0],
            [@"menu-bar-window-left-margin",                        10.0],
            [@"menu-bar-window-right-margin",                       10.0],

            [@"menu-bar-text-color",                                [CPColor colorWithRed:0.051 green:0.2 blue:0.275 alpha:1.0]],
            [@"menu-bar-title-color",                               [CPColor colorWithRed:0.051 green:0.2 blue:0.275 alpha:1.0]],
            [@"menu-bar-text-shadow-color",                         [CPColor whiteColor]],
            [@"menu-bar-title-shadow-color",                        [CPColor whiteColor]],
            [@"menu-bar-highlight-color",                           FlatColorBlue],
            [@"menu-bar-highlight-text-color",                      [CPColor whiteColor]],
            [@"menu-bar-highlight-text-shadow-color",               [CPColor blackColor]],
            [@"menu-bar-height",                                    30.0],
            [@"menu-bar-icon-image",                                nil],
            [@"menu-bar-icon-image-alpha-value",                    1.0]
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
                            1, 1, 1, 1,
                            1, 1, 1, 1
                         ],
                         [0, 1],
                         2
                     ),

        gradientHUD = CGGradientCreateWithColorComponents(
                        CGColorSpaceCreateDeviceRGB(),
                        [
                            (18.0 / 255), (18.0 / 255), (18.0 / 255), 1,
                            (18.0 / 255), (18.0 / 255), (18.0 / 255), 1
                        ],
                        [0, 1],
                        2),

        strokeColor = FlatColorGrey,
        strokeColorHUD = [CPColor colorWithHexString:@"222222"],

        themeValues =
        [
            [@"border-radius",              6.0],
            [@"stroke-width",               1.0],
            [@"background-gradient",        gradient],
            [@"background-gradient-hud",    gradientHUD],
            [@"stroke-color",               strokeColor],
            [@"stroke-color-hud",           strokeColorHUD]
        ];

    [self registerThemeValues:themeValues forView:popoverWindowView];

    return popoverWindowView;
}

+ (CPAlert)themedAlert
{
    var alert = [CPAlert new],
        buttonOffset             = 5.0,
        defaultElementsMargin    = 3.0,
        errorIcon                = PatternImage("alert-error.png", 32.0, 32.0),
        imageOffset              = CGPointMake(15, 18),
        informationIcon          = PatternImage("alert-info.png", 32.0, 32.0),
        informativeFont          = [CPFont systemFontOfSize:CPFontCurrentSystemSize],
        inset                    = CGInsetMake(15, 15, 15, 62),
        messageFont              = [CPFont boldSystemFontOfSize:CPFontDefaultSystemFontSize + 1],
        size                     = CGSizeMake(400.0, 100.0),
        suppressionButtonXOffset = 2.0,
        suppressionButtonYOffset = 10.0,
        suppressionButtonFont    = [CPFont systemFontOfSize:CPFontCurrentSystemSize],
        warningIcon              = PatternImage("alert-warning.png", 32.0, 32.0),

        themedAlertValues =
        [
            [@"button-offset",                      buttonOffset],
            [@"content-inset",                      inset],
            [@"default-elements-margin",            defaultElementsMargin],
            [@"error-image",                        errorIcon],
            [@"image-offset",                       imageOffset],
            [@"information-image",                  informationIcon],
            [@"informative-text-alignment",         CPJustifiedTextAlignment],
            [@"informative-text-color",             [CPColor blackColor]],
            [@"informative-text-font",              informativeFont],
            [@"message-text-alignment",             CPJustifiedTextAlignment],
            [@"message-text-color",                 [CPColor blackColor]],
            [@"message-text-font",                  messageFont],
            [@"modal-window-button-margin-x",       -16.0],
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

+ (CPProgressIndicator)themedBarProgressIndicator
{
    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 75, 12)];
    [progressBar setDoubleValue:30];

    var themedProgressIndicator = [
        [@"bezel-color", FlatColorGrey],
        [@"bar-color", FlatColorBlue],
        [@"default-height", 12]];

    [self registerThemeValues:themedProgressIndicator forView:progressBar];

    return progressBar;
}

+ (CPComboBox)themedComboBox
{
    var combo = [[CPComboBox alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 29.0)],

        bezelColor = PatternColor([
            ["combobox-bezel-left.png", 1.0, 21.0],
            ["combobox-bezel-center.png", 1.0, 21.0],
            ["combobox-bezel-right.png", 18.0, 21.0],
        ], PatternIsHorizontal),

        bezelColorEditing = PatternColor([
            ["combobox-bezel-editing-left.png", 1.0, 21.0],
            ["combobox-bezel-editing-center.png", 1.0, 21.0],
            ["combobox-bezel-editing-right.png", 18.0, 21.0],
        ], PatternIsHorizontal),

        smallBezelColor = PatternColor([
            ["combobox-bezel-left.png", 1.0, 18.0],
            ["combobox-bezel-center.png", 1.0, 18.0],
            ["combobox-bezel-right.png", 13.0, 18.0],
        ], PatternIsHorizontal),

        smallBezelColorEditing = PatternColor([
            ["combobox-bezel-editing-left.png", 1.0, 18.0],
            ["combobox-bezel-editing-center.png", 1.0, 18.0],
            ["combobox-bezel-editing-right.png", 13.0, 18.0],
        ], PatternIsHorizontal),

        overrides =
        [
            [@"border-inset", CGInsetMakeZero(),                                    CPThemeStateBezeled],

            // Normal
            [@"bezel-color",                bezelColor,                             CPThemeStateBezeled],
            [@"bezel-color",                bezelColorEditing,                      [CPThemeStateBezeled, CPThemeStateEditing]],
            [@"bezel-color",                bezelColor,                             [CPThemeStateBezeled, CPThemeStateDisabled]],

            [@"content-inset",              CGInsetMake(4.0, 21.0, 0.0, 6.0),      CPThemeStateBezeled],
            [@"nib2cib-adjustment-frame",   CGRectMake(0.0, -2.0, -3.0, -4.0)],

            // CPThemeStateControlSizeSmall
            [@"bezel-color",                smallBezelColor,                     [CPThemeStateControlSizeSmall, CPThemeStateBezeled]],
            [@"bezel-color",                smallBezelColorEditing,              [CPThemeStateControlSizeSmall, CPThemeStateBezeled, CPThemeStateEditing]],
            [@"bezel-color",                smallBezelColor,                     [CPThemeStateControlSizeSmall, CPThemeStateBezeled, CPThemeStateDisabled]],
            [@"min-size",                   CGSizeMake(-1.0, 19.0),              [CPThemeStateControlSizeSmall, CPThemeStateBezeled]],
            [@"content-inset",              CGInsetMake(4.0, 16.0, 4.0, 6.0),    [CPThemeStateControlSizeSmall, CPThemeStateBezeled]],
            [@"nib2cib-adjustment-frame",   CGRectMake(0.0, 1.0, -3.0, 0.0),     CPThemeStateControlSizeSmall],
        ];

    [self registerThemeValues:overrides forView:combo inherit:themedTextFieldValues];

    return combo;
}

+ (CPTokenField)themedTokenField
{
    var tokenfield = [[CPTokenField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 29.0)],

        overrides =
        [
            [@"content-inset", CGInsetMake(2.0, 0.0, 0.0, 6.0)],
            [@"editor-inset", CGInsetMake(1.0, 0.0, 0.0, 0.0)],
        ];

    [self registerThemeValues:overrides forView:tokenfield inherit:themedTextFieldValues];

    return tokenfield;
}

+ (_CPTokenFieldToken)themedTokenFieldToken
{
    var token = [[_CPTokenFieldToken alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 19.0)],

        bezelColor = FlatColorBlue,

        themeValues =
        [
            [@"bezel-color",    FlatColorBlue,                    CPThemeStateBezeled],
            [@"bezel-color",    FlatColorBlueLight,               [CPThemeStateBezeled, CPThemeStateHighlighted]],
            [@"bezel-color",    FlatColorGrey,                    [CPThemeStateBezeled, CPThemeStateDisabled]],

            [@"text-color",     FlatColorWhite],
            [@"text-color",     FlatColorWhite,                   CPThemeStateHighlighted],
            [@"text-color",     FlatColorBlack,                   CPThemeStateDisabled],

            [@"bezel-inset",    CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateBezeled],
            [@"content-inset",  CGInsetMake(1.0, 8.0, 1.0, 8.0),  CPThemeStateBezeled],

            // Minimum height == maximum height since tokens are fixed height.
            [@"min-size",       CGSizeMake(0.0, 16.0)],
            [@"max-size",       CGSizeMake(-1.0, 16.0)],

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

+ (CPProgressIndicator)themedCircularProgressIndicator
{
    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [progressBar setStyle:CPProgressIndicatorSpinningStyle];
    [progressBar setIndeterminate:NO];

    var themeValues =
        [
            [@"circular-border-color", FlatColorBlue],
            [@"circular-border-size", 1],
            [@"circular-color", FlatColorBlue]
        ];

    [self registerThemeValues:themeValues forView:progressBar];

    return progressBar;
}
@end
