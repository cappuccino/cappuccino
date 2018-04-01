/*
 * ThemeDescriptors.j
 * AppKit
 *
 * Created by Didier Korthoudt
 * Copyright 2018 <didier.korthoudt@uliege.be>
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
@import <AppKit/CPColor.j>

@import "Aristo3Colors.j"


var themedButtonValues = nil,
    themedTextFieldValues = nil,
    themedRoundedTextFieldValues = nil,
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

@implementation Aristo3ThemeDescriptor : BKThemeDescriptor

+ (CPString)themeName
{
    return @"Aristo3";
}

+ (CPArray)themeShowcaseExcludes
{
    return [
            "themedAlert",
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
            "themedTokenFieldTokenCloseButton",
            "themedColor",
            "themedView"
            ];
}

+ (CPView)themedView
{
    var view = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

    [self registerThemeValues:[[@"css-based", YES]] forView:view];

    return view;
}

+ (CPColor)themedColor
{
    var color = [CPColor redColor],
    themedColorValues =
    [
     [@"alternate-selected-control-color",        [[CPColor alloc] _initWithRGBA:[0.22, 0.46, 0.84, 1.0]]],
     [@"secondary-selected-control-color",        [[CPColor alloc] _initWithRGBA:[0.83, 0.83, 0.83, 1.0]]],
     [@"selected-text-background-color",          [CPColor colorWithHexString:"99CCFF"]],
     [@"selected-text-inactive-background-color", [CPColor colorWithHexString:"CCCCCC"]]
     ];

    [self registerThemeValues:themedColorValues forObject:color];

    return color;
}

@end


@implementation Aristo3HUDThemeDescriptor : BKThemeDescriptor
{
}

+ (CPString)themeName
{
    return @"Aristo3-HUD";
}

+ (CPArray)themeShowcaseExcludes
{
    return ["alert"];
}

+ (CPColor)defaultShowcaseBackgroundColor
{
    return [CPColor blackColor];
}

@end


