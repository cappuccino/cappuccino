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


// +------------------------------------------------------------------------+
// | IMPORTANT REMARK: This is a work in progress.                          |
// |                   Please don't be affraid, it will be cleaned up ASAP. |
// +------------------------------------------------------------------------+

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
@import <AppKit/CPTabView.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPTokenField.j>
@import <AppKit/CPWindow.j>
@import <AppKit/CPAlert.j>
@import <AppKit/_CPToolTip.j>
@import <AppKit/CPPopover.j>
@import <AppKit/CPColor.j>
@import <AppKit/CPFont.j>
@import <AppKit/CPImage.j>

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
            "themedView",
            "themedFont"
            ];
}

+ (CPView)themedView
{
    var view = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)],
        dynamicSet = @{
                       @"A3CPColorActiveText":             A3CPColorActiveText,
                       @"A3CPColorInactiveText":           A3CPColorInactiveText,
                       @"A3CPColorDefaultText":            A3CPColorDefaultText,
                       @"A3CPColorActiveBorder":           A3CPColorActiveBorder,
                       @"A3ColorActiveBorder":             A3ColorActiveBorder,
                       @"A3CPColorInactiveBorder":         A3CPColorInactiveBorder,
                       @"A3ColorInactiveBorder":           A3ColorInactiveBorder,
                       @"A3ColorInactiveDarkBorder":       A3ColorInactiveDarkBorder,
                       @"A3ColorBorderLight":              A3ColorBorderLight,
                       @"A3ColorBorderMedium":             A3ColorBorderMedium,
                       @"A3ColorBorderDark":               A3ColorBorderDark,
                       @"A3ColorBorderBlue":               A3ColorBorderBlue,
                       @"A3CPColorBorderBlue":             A3CPColorBorderBlue,
                       @"A3ColorBorderBlueLight":          A3ColorBorderBlueLight,
                       @"A3ColorBorderBlueHighlighted":    A3ColorBorderBlueHighlighted,
                       @"A3ColorBackground":               A3ColorBackground,
                       @"A3ColorBackgroundInactive":       A3ColorBackgroundInactive,
                       @"A3ColorBackgroundHighlighted":    A3ColorBackgroundHighlighted,
                       @"A3ColorBackgroundWhite":          A3ColorBackgroundWhite,
                       @"A3ColorBackgroundDark":           A3ColorBackgroundDark,
                       @"A3ColorBorderRed":                A3ColorBorderRed,
                       @"A3ColorBorderRedLight":           A3ColorBorderRedLight,
                       @"A3ColorBorderRedHighlighted":     A3ColorBorderRedHighlighted,
                       @"A3ColorWindowHeadActive":         A3ColorWindowHeadActive,
                       @"A3ColorWindowHeadInactive":       A3ColorWindowHeadInactive,
                       @"A3ColorWindowButtonClose":        A3ColorWindowButtonClose,
                       @"A3ColorWindowButtonCloseDark":    A3ColorWindowButtonCloseDark,
                       @"A3ColorWindowButtonCloseLight":   A3ColorWindowButtonCloseLight,
                       @"A3ColorWindowButtonMin":          A3ColorWindowButtonMin,
                       @"A3ColorWindowButtonMinDark":      A3ColorWindowButtonMinDark,
                       @"A3ColorWindowButtonMinLight":     A3ColorWindowButtonMinLight,
                       @"A3ColorWindowButtonZoom":         A3ColorWindowButtonZoom,
                       @"A3ColorWindowButtonZoomDark":     A3ColorWindowButtonZoomDark,
                       @"A3ColorWindowButtonZoomLight":    A3ColorWindowButtonZoomLight,
                       @"A3ColorWindowBorder":             A3ColorWindowBorder,
                       @"A3ColorMenuLightBackground":      A3ColorMenuLightBackground,
                       @"A3ColorMenuBackground":           A3ColorMenuBackground,
                       @"A3ColorMenuCheckmark":            A3ColorMenuCheckmark,
                       @"A3ColorMenuBorder":               A3ColorMenuBorder,
                       @"A3ColorTextfieldActiveBorder":    A3ColorTextfieldActiveBorder,
                       @"A3ColorTextfieldInactiveBorder":  A3ColorTextfieldInactiveBorder,
                       @"A3CPColorTableAlternateRow":      A3CPColorTableAlternateRow,
                       @"A3CPColorTableDivider":           A3CPColorTableDivider,
                       @"A3ColorTableHeaderSeparator":     A3ColorTableHeaderSeparator,
                       @"A3ColorScrollerDark":             A3ColorScrollerDark
                       };

    [self registerThemeValues:[
                               [@"css-based", YES],
                               [@"dynamic-set", dynamicSet]
                               ]
                      forView:view];

    return view;
}

+ (CPFont)themedFont
{
    var font = [CPFont systemFontOfSize:12],
//        themeFontStyle = @"@font-face { font-family: 'SFNSText'; src: local('.SFNSText-Light'), url('Resources/fonts/SFNSText-Light.woff') format('woff'); font-weight: 300 }\n"
//                       + @"@font-face { font-family: 'SFNSText'; src: local('.SFNSText-Medium'), url('Resources/fonts/SFNSText-Medium.woff') format('woff'); font-weight: 500 }\n"
//                       + @"@font-face { font-family: 'SFNSDisplay'; src: local('.SFNSDisplay-Light'), url('Resources/fonts/SFNSDisplay-Light.woff') format('woff'); font-weight: 300 }\n"
//                       + @"@font-face { font-family: 'SFNSDisplay'; src: local('.SFNSDisplay-Medium'), url('Resources/fonts/SFNSDisplay-Medium.woff') format('woff'); font-weight: 500 }\n"
//                       + @"@font-face { font-family: 'SFNSText'; src: local('.SFNSText'), url('Resources/fonts/SFNSText-Regular.woff') format('woff'); font-weight: 400 }\n"
//                       + @"@font-face { font-family: 'SFNSText'; src: local('.SFNSText-Bold'), url('Resources/fonts/SFNSText-Bold.woff') format('woff'); font-weight: 600 }\n"
//                       + @"@font-face { font-family: 'SFNSDisplay'; src: local('.SFNSDisplay'), url('Resources/fonts/SFNSDisplay-Regular.woff') format('woff'); font-weight: 400 }\n"
//                       + @"@font-face { font-family: 'SFNSDisplay'; src: local('.SFNSDisplay-Bold'), url('Resources/fonts/SFNSDisplay-Bold.woff') format('woff'); font-weight: 600 }\n"
//                       + @"html, body, h1, p { text-rendering: optimizeLegibility; }\n"
//                       + @"@font-face {\n"
//                       + @"font-family: 'Material Icons';\n"
//                       + @"font-style: normal;\n"
//                       + @"font-weight: 400;\n"
//                       + @"src: url(Resources/fonts/MaterialIcons-Regular.eot); /* For IE6-8 */\n"
//                       + @"src: local('Material Icons'),\n"
//                       + @"local('MaterialIcons-Regular'),\n"
//                       + @"url(Resources/fonts/MaterialIcons-Regular.woff2) format('woff2'),\n"
//                       + @"url(Resources/fonts/MaterialIcons-Regular.woff) format('woff'),\n"
//                       + @"url(Resources/fonts/MaterialIcons-Regular.ttf) format('truetype');\n"
//                       + @"}\n"
//                       + @".material-icons {\n"
//                       + @"font-family: 'Material Icons';\n"
//                       + @"font-weight: normal;\n"
//                       + @"font-style: normal;\n"
//                       + @"font-size: 24px;\n"
//                       + @"display: inline-block;\n"
//                       + @"line-height: 1;\n"
//                       + @"text-transform: none;\n"
//                       + @"letter-spacing: normal;\n"
//                       + @"word-wrap: normal;\n"
//                       + @"white-space: nowrap;\n"
//                       + @"direction: ltr;\n"
//                       + @"-webkit-font-smoothing: antialiased;\n"
//                       + @"text-rendering: optimizeLegibility;\n"
//                       + @"-moz-osx-font-smoothing: grayscale;\n"
//                       + @"font-feature-settings: 'liga';\n"
//                       + @"}";

    themeFontStyle = @"@font-face { font-family: 'SFNSText'; src: local('.SFNSText-Light'), url('%%/fonts/SFNSText-Light.woff') format('woff'); font-weight: 300 }\n"
                   + @"@font-face { font-family: 'SFNSText'; src: local('.SFNSText-Medium'), url('%%/fonts/SFNSText-Medium.woff') format('woff'); font-weight: 500 }\n"
                   + @"@font-face { font-family: 'SFNSDisplay'; src: local('.SFNSDisplay-Light'), url('%%/fonts/SFNSDisplay-Light.woff') format('woff'); font-weight: 300 }\n"
                   + @"@font-face { font-family: 'SFNSDisplay'; src: local('.SFNSDisplay-Medium'), url('%%/fonts/SFNSDisplay-Medium.woff') format('woff'); font-weight: 500 }\n"
                   + @"@font-face { font-family: 'SFNSText'; src: local('.SFNSText'), url('%%/fonts/SFNSText-Regular.woff') format('woff'); font-weight: 400 }\n"
                   + @"@font-face { font-family: 'SFNSText'; src: local('.SFNSText-Bold'), url('%%/fonts/SFNSText-Bold.woff') format('woff'); font-weight: 600 }\n"
                   + @"@font-face { font-family: 'SFNSDisplay'; src: local('.SFNSDisplay'), url('%%/fonts/SFNSDisplay-Regular.woff') format('woff'); font-weight: 400 }\n"
                   + @"@font-face { font-family: 'SFNSDisplay'; src: local('.SFNSDisplay-Bold'), url('%%/fonts/SFNSDisplay-Bold.woff') format('woff'); font-weight: 600 }\n"
                   + @"html, body, h1, p { text-rendering: optimizeLegibility; }\n"
                   + @"@font-face {\n"
                   + @"font-family: 'Material Icons';\n"
                   + @"font-style: normal;\n"
                   + @"font-weight: 400;\n"
                   + @"src: url(%%/fonts/MaterialIcons-Regular.eot); /* For IE6-8 */\n"
                   + @"src: local('Material Icons'),\n"
                   + @"local('MaterialIcons-Regular'),\n"
                   + @"url(%%/fonts/MaterialIcons-Regular.woff2) format('woff2'),\n"
                   + @"url(%%/fonts/MaterialIcons-Regular.woff) format('woff'),\n"
                   + @"url(%%/fonts/MaterialIcons-Regular.ttf) format('truetype');\n"
                   + @"}\n";

    //    + @".material-icons {\n"
//    + @"font-family: 'Material Icons';\n"
//    + @"font-weight: normal;\n"
//    + @"font-style: normal;\n"
//    + @"font-size: 24px;\n"
//    + @"display: inline-block;\n"
//    + @"line-height: 1;\n"
//    + @"text-transform: none;\n"
//    + @"letter-spacing: normal;\n"
//    + @"word-wrap: normal;\n"
//    + @"white-space: nowrap;\n"
//    + @"direction: ltr;\n"
//    + @"-webkit-font-smoothing: antialiased;\n"
//    + @"text-rendering: optimizeLegibility;\n"
//    + @"-moz-osx-font-smoothing: grayscale;\n"
//    + @"font-feature-settings: 'liga';\n"
//    + @"}";

    [self registerThemeValues:[
                               [@"system-font-face", @"SFNSText, Helvetica Neue"],
                               [@"system-font-size-regular", 13],
                               [@"system-font-size-small", 11],
                               [@"system-font-size-mini", 9],
                               [@"system-font-style", themeFontStyle]
                               ]
                      forObject:font];

    return font;
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

+ (CPButton)makeButton
{
    return [[CPButton alloc] initWithFrame:CGRectMake(0, 0, 100, 21)];
}

+ (CPButton)button
{
    var button = [self makeButton],

    // IB Style : Push (CPButtonStateBezelStyleRounded) - Bordered
    buttonCssColor = [CPColor colorWithCSSDictionary:@{
                                                       @"background-color": A3ColorBackgroundWhite,
                                                       @"border-color": A3ColorActiveBorder,
                                                       @"border-style": @"solid",
                                                       @"border-width": @"1px",
                                                       @"border-radius": @"3px",
                                                       @"box-sizing": @"border-box"
                                                       }],

    disabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorLightBackground,
                                                               @"border-color": A3ColorBackgroundBlack14,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }],

    highlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": A3ColorBorderBlueHighlighted,
                                                                  @"border-color": A3ColorBorderBlueHighlighted,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"3px",
                                                                  @"box-sizing": @"border-box"
                                                                  }],

    selectedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBorderBlue,
                                                               @"border-color": A3ColorBorderBlueHighlighted,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }],

    // FIXME: test is here
    defaultButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": @"A3ColorBorderBlue",
                                                              @"border-color": @"A3ColorBorderBlue",
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"3px",
                                                              @"box-sizing": @"border-box"
                                                              }],

    defaultHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                         @"background-color": A3ColorBorderBlueHighlighted,
                                                                         @"border-color": A3ColorBorderBlueHighlighted,
                                                                         @"border-style": @"solid",
                                                                         @"border-width": @"1px",
                                                                         @"border-radius": @"3px",
                                                                         @"box-sizing": @"border-box"
                                                                         }],

    // IB Style : Square (CPShadowlessSquareBezelStyle) - Bordered
    squareButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorSquareButtonBackground,
                                                             @"border-color": A3ColorActiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"0px",
                                                             @"box-sizing": @"border-box"
                                                             }],

    squareDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                     @"background-color": A3ColorLightBackground,
                                                                     @"border-color": A3ColorInactiveBorder,
                                                                     @"border-style": @"solid",
                                                                     @"border-width": @"1px",
                                                                     @"border-radius": @"0px",
                                                                     @"box-sizing": @"border-box"
                                                                     }],

    squareHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                        @"background-color": A3ColorButtonBackgroundHighlighted,
                                                                        @"border-color": A3ColorActiveBorder,
                                                                        @"border-style": @"solid",
                                                                        @"border-width": @"1px",
                                                                        @"border-radius": @"0px",
                                                                        @"box-sizing": @"border-box"
                                                                        }],

    // IB Style : Gradient (CPSmallSquareBezelStyle) - Bordered
    gradientButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorSquareButtonBackground,
                                                               @"border-color": A3ColorActiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"0px",
                                                               @"box-sizing": @"border-box"
                                                               }],

    gradientDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"background-color": A3ColorBackground50,
                                                                       @"border-color": A3ColorInactiveBorder,
                                                                       @"border-style": @"solid",
                                                                       @"border-width": @"1px",
                                                                       @"border-radius": @"0px",
                                                                       @"box-sizing": @"border-box"
                                                                       }],

    gradientHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                          @"background-color": A3ColorButtonBackgroundHighlighted,
                                                                          @"border-color": A3ColorActiveBorder,
                                                                          @"border-style": @"solid",
                                                                          @"border-width": @"1px",
                                                                          @"border-radius": @"0px",
                                                                          @"box-sizing": @"border-box"
                                                                          }],

    // IB Style : Textured rounded (CPButtonStateBezelStyleTexturedRounded) - Bordered
    trButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                         @"background-color": A3ColorBackgroundWhite, // A3ColorBackground90,
                                                         @"border-color": A3ColorActiveBorder,
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"border-radius": @"3px",
                                                         @"box-sizing": @"border-box"
                                                         }],

    trDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorLightBackground, // A3ColorBackground50,
                                                                 @"border-color": A3ColorBackgroundBlack14,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"3px",
                                                                 @"box-sizing": @"border-box"
                                                                 }],

    trHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorBackgroundHighlighted, // A3ColorButtonBackgroundHighlighted80,
                                                                    @"border-color": A3ColorActiveBorder,
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"border-radius": @"3px",
                                                                    @"box-sizing": @"border-box"
                                                                    }],

    // IB Style : Round rect (CPButtonStateBezelStyleRoundRect) - Bordered
    rrButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                         @"background-color": A3ColorTransparent,
                                                         @"border-color": A3ColorActiveBorder,
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"border-radius": @"5px",
                                                         @"box-sizing": @"border-box"
                                                         }],

    rrDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorTransparent,
                                                                 @"border-color": A3ColorInactiveBorder,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"5px",
                                                                 @"box-sizing": @"border-box"
                                                                 }],

    rrHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorBackgroundDark35,
                                                                    @"border-color": A3ColorActiveBorder,
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"border-radius": @"5px",
                                                                    @"box-sizing": @"border-box"
                                                                    }],

    // IB Style : Recessed (CPButtonStateBezelStyleRecessed) - Bordered
    recessedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorTransparent,
                                                               @"border-style": @"none",
                                                               @"border-radius": @"5px",
                                                               @"box-sizing": @"border-box"
                                                               }],

    recessedDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"background-color": A3ColorTransparent,
                                                                       @"border-style": @"none",
                                                                       @"border-radius": @"5px",
                                                                       @"box-sizing": @"border-box"
                                                                       }],

    recessedHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                          @"background-color": A3ColorBackgroundBlack50,
                                                                          @"border-style": @"none",
                                                                          @"border-radius": @"5px",
                                                                          @"box-sizing": @"border-box"
                                                                          }],

    recessedHoveredButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                      @"background-color": A3ColorBackgroundBlack20,
                                                                      @"border-style": @"none",
                                                                      @"border-radius": @"5px",
                                                                      @"box-sizing": @"border-box"
                                                                      }],

    recessedSelectedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"background-color": A3ColorBackgroundBlack35,
                                                                       @"border-style": @"none",
                                                                       @"border-radius": @"5px",
                                                                       @"box-sizing": @"border-box"
                                                                       }],

    // IB Style : Inline (CPButtonStateBezelStyleInline) - Bordered
    inlineButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundBlack20,
                                                             @"border-style": @"none",
//                                                             @"border-style": @"solid",
//                                                             @"border-width": @"1px",
//                                                             @"border-top-color": A3ColorActiveBorder,
//                                                             @"border-bottom-color": A3ColorLightBackground,
                                                             @"border-radius": @"8px",
                                                             @"box-sizing": @"border-box"
                                                             }],

    inlineDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                     @"background-color": A3ColorButtonBackgroundHighlighted50,
                                                                     @"border-style": @"none",
                                                                     @"border-radius": @"8px",
                                                                     @"box-sizing": @"border-box"
                                                                     }],

    inlineHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                        @"background-color": A3ColorBackgroundBlack50,
                                                                        @"border-style": @"none",
                                                                        @"border-radius": @"8px",
                                                                        @"box-sizing": @"border-box"
                                                                        }],

    // IB Style : Bevel (CPButtonStateBezelStyleRegularSquare) - Bordered
    bevelButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": A3ColorBackgroundWhite,
                                                            @"border-color": A3ColorActiveBorder,
                                                            @"border-style": @"solid",
                                                            @"border-width": @"1px",
                                                            @"border-radius": @"3px",
                                                            @"box-sizing": @"border-box"
                                                            }],

    bevelDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorLightBackground,
                                                                    @"border-color": A3ColorBackgroundBlack14,
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"border-radius": @"3px",
                                                                    @"box-sizing": @"border-box"
                                                                    }],

    bevelHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"background-color": A3ColorBackground,
                                                                       @"border-color": A3ColorActiveBorder,
                                                                       @"border-style": @"solid",
                                                                       @"border-width": @"1px",
                                                                       @"border-radius": @"3px",
                                                                       @"box-sizing": @"border-box"
                                                                       }],

    // IB Style : Textured (CPButtonStateBezelStyleTextured) - Bordered
    texturedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackground90,
                                                               @"border-color": A3ColorActiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }],

    texturedDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"background-color": A3ColorBackground50, 
                                                                       @"border-color": A3ColorBackgroundBlack14,
                                                                       @"border-style": @"solid",
                                                                       @"border-width": @"1px",
                                                                       @"border-radius": @"3px",
                                                                       @"box-sizing": @"border-box"
                                                                       }],

    texturedHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                          @"background-color": A3ColorButtonBackgroundHighlighted80,
                                                                          @"border-color": A3ColorActiveBorder,
                                                                          @"border-style": @"solid",
                                                                          @"border-width": @"1px",
                                                                          @"border-radius": @"3px",
                                                                          @"box-sizing": @"border-box"
                                                                          }],

    // All styles - unbordered

    unborderedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorTransparent,
//                                                                 @"border-color": A3ColorTransparent,
//                                                                 @"border-style": @"solid",
//                                                                 @"border-width": @"1px",
                                                                 @"box-sizing": @"border-box"
                                                                 }],

    unborderedHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                            @"background-color": A3ColorBackground,
//                                                                            @"border-color": A3ColorBackground,
//                                                                            @"border-style": @"solid",
//                                                                            @"border-width": @"1px",
                                                                            @"box-sizing": @"border-box"
                                                                            }],

    // Disclosure triangle

    disclosureImage = [CPImage imageWithCSSDictionary:@{
                                                        @"box-sizing": @"border-box",
                                                        @"width": @"0px",
                                                        @"height": @"0px",
                                                        @"border-top": @"5px solid transparent",
                                                        @"border-left": @"9px solid " + A3ColorDisclosure,
                                                        @"border-bottom": @"5px solid transparent",
                                                        @"transform": @"translateY(0%) rotate(0deg)",
                                                        @"transform-origin" : @"bottom left",
                                                        @"transition-duration": @"0.35s",
                                                        @"transition-property": @"transform"
                                                        }
                                                 size:CGSizeMake(10, 10)],

    disclosureDisabledImage = [CPImage imageWithCSSDictionary:@{
                                                                @"box-sizing": @"border-box",
                                                                @"width": @"0px",
                                                                @"height": @"0px",
                                                                @"border-top": @"5px solid transparent",
                                                                @"border-left": @"9px solid " + A3ColorDisclosureDisabled,
                                                                @"border-bottom": @"5px solid transparent",
                                                                @"transition-duration": @"0.35s",
                                                                @"transition-property": @"transform"
                                                                }
                                                         size:CGSizeMake(10, 10)],

    disclosureHighlightedImage = [CPImage imageWithCSSDictionary:@{
                                                                   @"box-sizing": @"border-box",
                                                                   @"width": @"0px",
                                                                   @"height": @"0px",
                                                                   @"border-top": @"5px solid transparent",
                                                                   @"border-left": @"9px solid " + A3ColorDisclosurePushed,
                                                                   @"border-bottom": @"5px solid transparent",
                                                                   @"transition-duration": @"0.35s",
                                                                   @"transition-property": @"transform"
                                                                   }
                                                            size:CGSizeMake(10, 10)],

    disclosureDownImage = [CPImage imageWithCSSDictionary:@{
                                                            @"box-sizing": @"border-box",
                                                            @"width": @"0px",
                                                            @"height": @"0px",
                                                            @"border-top": @"5px solid transparent",
                                                            @"border-left": @"9px solid " + A3ColorDisclosure,
                                                            @"border-bottom": @"5px solid transparent",
                                                            @"transform": @"translateY(-90%) rotate(90deg)",
                                                            @"transform-origin" : @"bottom left",
                                                            @"transition-duration": @"0.35s",
                                                            @"transition-property": @"transform"
                                                            }
                                                     size:CGSizeMake(10, 10)],

    disclosureDisabledDownImage = [CPImage imageWithCSSDictionary:@{
                                                                    @"box-sizing": @"border-box",
                                                                    @"width": @"0px",
                                                                    @"height": @"0px",
                                                                    @"border-top": @"5px solid transparent",
                                                                    @"border-left": @"9px solid " + A3ColorDisclosureDisabled,
                                                                    @"border-bottom": @"5px solid transparent",
                                                                    @"transform": @"translateY(-90%) rotate(90deg)",
                                                                    @"transform-origin" : @"bottom left",
                                                                    @"transition-duration": @"0.35s",
                                                                    @"transition-property": @"transform"
                                                                    }
                                                             size:CGSizeMake(10, 10)],

    disclosureHighlightedDownImage = [CPImage imageWithCSSDictionary:@{
                                                                       @"box-sizing": @"border-box",
                                                                       @"width": @"0px",
                                                                       @"height": @"0px",
                                                                       @"border-top": @"5px solid transparent",
                                                                       @"border-left": @"9px solid " + A3ColorDisclosurePushed,
                                                                       @"border-bottom": @"5px solid transparent",
                                                                       @"transform": @"translateY(-90%) rotate(90deg)",
                                                                       @"transform-origin" : @"bottom left",
                                                                       @"transition-duration": @"0.35s",
                                                                       @"transition-property": @"transform"
                                                                       }
                                                                size:CGSizeMake(10, 10)],

    // Disclosure rounded

    disclosureRoundedCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": A3ColorBackgroundWhite,
                                                                  @"border-color": A3ColorActiveBorder,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"5px",
                                                                  @"box-sizing": @"border-box"
                                                                  }],

    disclosureRoundedDisabledCssColor = [CPColor colorWithCSSDictionary:@{
                                                                          @"background-color": A3ColorBackgroundInactive,
                                                                          @"border-color": A3ColorInactiveBorder,
                                                                          @"border-style": @"solid",
                                                                          @"border-width": @"1px",
                                                                          @"border-radius": @"5px",
                                                                          @"box-sizing": @"border-box"
                                                                          }],

    disclosureRoundedHighlightedCssColor = [CPColor colorWithCSSDictionary:@{
                                                                             @"background-color": A3ColorBackgroundInactive,
                                                                             @"border-color": A3ColorActiveBorder,
                                                                             @"border-style": @"solid",
                                                                             @"border-width": @"1px",
                                                                             @"border-radius": @"5px",
                                                                             @"box-sizing": @"border-box"
                                                                             }],

    disclosureOffImage = [CPImage imageWithCSSDictionary:@{
                                                           @"background-image": @"url(%%packed.png)",
                                                           @"background-position": @"-24px -48px",
                                                           @"background-repeat": @"no-repeat",
                                                           @"background-size": @"100px 400px",
                                                           @"transform": "rotate(0deg)"
//                                                           @"transition-duration": @"0.35s",
//                                                           @"transition-property": @"transform"
                                                           }
                                        beforeDictionary:nil
                                         afterDictionary:nil
                                                    size:CGSizeMake(7, 4)],

    disclosureOnImage = [CPImage imageWithCSSDictionary:@{
                                                          @"background-image": @"url(%%packed.png)",
                                                          @"background-position": @"-24px -48px",
                                                          @"background-repeat": @"no-repeat",
                                                          @"background-size": @"100px 400px",
                                                          @"transform": "rotate(180deg)"
//                                                          @"transition-duration": @"0.35s",
//                                                          @"transition-property": @"transform"
                                                          }
                                       beforeDictionary:nil
                                        afterDictionary:nil
                                                   size:CGSizeMake(7, 4)],

    totoTemp = nil;

    // Global
    themedButtonValues =
    [
     [@"direct-nib2cib-adjustment",     YES], // Don't let nib2cib "play" with buttons
     [@"invert-image",                  NO],  // By default, don't invert the image (works only with material icon images)
     [@"invert-image-on-push",          NO],  // By default, don't invert the image when the button is pushed (works only with material icon images)
     [@"line-break-mode",               CPLineBreakByTruncatingTail],
     [@"vertical-alignment",            CPCenterVerticalTextAlignment],

     [@"text-color",                    @"A3CPColorActiveText"], // FIXME: test is here also
     [@"text-color",                    A3CPColorInactiveText,                  CPThemeStateDisabled],

     [@"text-color",                    A3CPColorDefaultText,                   [CPThemeStateBordered, CPThemeStateDefault, CPThemeStateKeyWindow]],
     [@"text-color",                    A3CPColorActiveText,                    [CPThemeStateBordered, CPThemeStateDefault]],

     [@"text-color",                    A3CPColorDefaultText,                   CPThemeStateDefault],
     [@"text-color",                    A3CPColorInactiveText,                  [CPThemeStateDefault,  CPThemeStateDisabled]],

     [@"text-color",                    A3CPColorDefaultText,                   [CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"text-color",                    A3CPColorActiveText,                    [CPThemeStateBordered, CPThemeStateSelected]],
     [@"text-color",                    A3CPColorDefaultText,                   [CPThemeStateBordered, CPThemeStateHighlighted, CPThemeStateSelected]],


     // Unbordered

     [@"bezel-color",                   unborderedButtonCssColor],
     [@"bezel-color",                   unborderedButtonCssColor,               [CPThemeStateDisabled]],
     [@"bezel-color",                   unborderedHighlightedButtonCssColor,    [CPThemeStateHighlighted]],

     // Push unbordered

     [@"image-color",                   A3CPColorBlack50,                       CPButtonStateBezelStyleRounded],
     [@"image-color",                   A3CPColorBlack85,                       [CPButtonStateBezelStyleRounded, CPThemeStateHighlighted]],
     [@"image-color",                   A3CPColorBlack25,                       [CPButtonStateBezelStyleRounded, CPThemeStateDisabled]],
     [@"image-offset",                  1.0,                                    CPButtonStateBezelStyleRounded],

     // Recessed unbordered

     [@"bezel-color",                   unborderedHighlightedButtonCssColor,    [CPButtonStateBezelStyleRecessed]],
     [@"bezel-color",                   unborderedHighlightedButtonCssColor,    [CPButtonStateBezelStyleRecessed, CPThemeStateDisabled]],
     [@"bezel-color",                   unborderedHighlightedButtonCssColor,    [CPButtonStateBezelStyleRecessed, CPThemeStateHighlighted]],

     // Square unbordered

     [@"image-color",                   A3CPColorBlack50,                       CPButtonStateBezelStyleShadowlessSquare],
     [@"image-color",                   A3CPColorBlack85,                       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateHighlighted]],
     [@"image-color",                   A3CPColorBlack25,                       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateDisabled]],
     [@"image-offset",                  1.0,                                    CPButtonStateBezelStyleShadowlessSquare],

     // Gradient unbordered

     [@"image-color",                   A3CPColorBlack50,                       CPButtonStateBezelStyleSmallSquare],
     [@"image-color",                   A3CPColorBlack85,                       [CPButtonStateBezelStyleSmallSquare, CPThemeStateHighlighted]],
     [@"image-color",                   A3CPColorBlack25,                       [CPButtonStateBezelStyleSmallSquare, CPThemeStateDisabled]],
     [@"image-offset",                  1.0,                                    CPButtonStateBezelStyleSmallSquare],

     // IB Style : Push (CPButtonStateBezelStyleRounded) - Bordered
     [@"bezel-color",                   buttonCssColor,                         [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"bezel-color",                   disabledButtonCssColor,                 [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   highlightedButtonCssColor,              [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color",                   highlightedButtonCssColor,              [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateHighlighted, CPThemeStateSelected]],
     [@"bezel-color",                   selectedButtonCssColor,                 [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateSelected]],

     [@"bezel-color",                   defaultButtonCssColor,                  [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateKeyWindow]],
     [@"bezel-color",                   defaultHighlightedButtonCssColor,       [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"text-color",                    A3CPColorActiveTextHighlighted,         [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"text-color",                    A3CPColorInactiveText,                  [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"text-color",                    A3CPColorActiveTextHighlighted,         [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateKeyWindow]],
     [@"text-color",                    A3CPColorActiveTextHighlighted,         [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateHighlighted]],
     [@"text-color",                    A3CPColorInactiveText,                  [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateDisabled]],

     // Without this, unbordered image color values would be used
     [@"image-color",                   @"FollowTextColor",                     [CPButtonStateBezelStyleRounded, CPThemeStateBordered]], // FIXME: si pas ok, redéfinir les couleurs avec couleurs texte
//     [@"image-color",                   A3CPColorActiveText,                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
//     [@"image-color",                   A3CPColorActiveTextHighlighted,         [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateHighlighted]],
//     [@"image-color",                   A3CPColorInactiveText,                  [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDisabled]],
//     [@"image-color",                   A3CPColorActiveTextHighlighted,         [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateKeyWindow]],
//     [@"image-color",                   A3CPColorActiveTextHighlighted,         [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateHighlighted]],
//     [@"image-color",                   A3CPColorInactiveText,                  [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateDisabled]],
//     [@"invert-image-on-push",          YES,                                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(1.0, 7.0, 1.0, 7.0),       [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"image-offset",                  1.0,                                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(6.0, -18.0, -12.0, -11.0),   [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 21.0),                  [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, 21.0),                 [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(1.0, 7.0, 1.0, 7.0),       [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"image-offset",                  1.0,                                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(5.0, -16.0, -10.0, -10.0),   [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 18.0),                  [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, 18.0),                 [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(1.0, 10.0, 1.0, 10.0),     [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"image-offset",                  1.0,                                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(1.0, -2.0, -2.0, -1.0),      [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 15.0),                  [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, 15.0),                 [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // IB Style : Square (CPShadowlessSquareBezelStyle) - Bordered
     [@"bezel-color",                   squareButtonCssColor,                   [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered]],
     [@"bezel-color",                   squareDisabledButtonCssColor,           [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   squareHighlightedButtonCssColor,        [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"image-color",                   A3CPColorBlack85,                       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered]],
     [@"image-color",                   A3CPColorBlack85,                       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"image-color",                   A3CPColorBlack25,                       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"image-offset",                  2.0,                                    [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(2.0, 2.0, 2.0, 2.0),       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, 0.0, 0.0),         [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 0.0),                  [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, -1.0),                 [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(2.0, 2.0, 2.0, 2.0),       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, 0.0, 0.0),         [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 0.0),                  [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, -1.0),                 [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(2.0, 2.0, 2.0, 2.0),       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, 0.0, 0.0),         [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 0.0),                  [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, -1.0),                 [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // IB Style : Gradient (CPSmallSquareBezelStyle) - Bordered
     [@"bezel-color",                   gradientButtonCssColor,                 [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered]],
     [@"bezel-color",                   gradientDisabledButtonCssColor,         [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   gradientHighlightedButtonCssColor,      [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"image-color",                   A3CPColorBlack85,                       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered]],
     [@"image-color",                   A3CPColorBlack85,                       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"image-color",                   A3CPColorBlack25,                       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"image-offset",                  2.0,                                    [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(2.0, 2.0, 2.0, 2.0),       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -1.0, 0.0, -2.0),       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 0.0),                  [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, -1.0),                 [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(2.0, 2.0, 2.0, 2.0),       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -1.0, 0.0, -2.0),       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 0.0),                  [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, -1.0),                 [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(2.0, 2.0, 2.0, 2.0),       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -1.0, 0.0, -2.0),       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 0.0),                  [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, -1.0),                 [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // IB Style : Textured rounded (CPButtonStateBezelStyleTexturedRounded) - Bordered
     [@"bezel-color",                   trButtonCssColor,                       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered]],
     [@"bezel-color",                   trDisabledButtonCssColor,               [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   trHighlightedButtonCssColor,            [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorActiveText65,                  [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered]],
     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"text-color",                    A3CPColorInactiveText,                  [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateDisabled]],
//     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"content-inset",                 CGInsetMake(1.0, 7.0, 1.0, 7.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered]],
//     [@"content-inset",                 CGInsetMake(-1.0, 7.0, 0.0, 7.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered]],
//     [@"content-inset",                 CGInsetMake(-3.0, 8.0, 0.0, 6.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -5.0, 0.0, -3.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 22.0),                  [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, 22.0),                 [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(1.0, 7.0, 1.0, 7.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
//     [@"content-inset",                 CGInsetMake(-2.0, 7.0, 0.0, 7.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
//     [@"content-inset",                 CGInsetMake(-3.0, 8.0, 0.0, 6.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 18.0),                  [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, 18.0),                 [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(1.0, 5.0, 1.0, 5.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
//     [@"content-inset",                 CGInsetMake(-1.0, 5.0, 0.0, 5.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
//     [@"content-inset",                 CGInsetMake(-3.0, 8.0, 0.0, 6.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 15.0),                  [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, 15.0),                 [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // IB Style : Round rect (CPButtonStateBezelStyleRoundRect) - Bordered
     [@"bezel-color",                   rrButtonCssColor,                       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered]],
     [@"bezel-color",                   rrDisabledButtonCssColor,               [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   rrHighlightedButtonCssColor,            [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"content-inset",                 CGInsetMake(1.0, 7.0, 1.0, 7.0),        [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered]],
//     [@"content-inset",                 CGInsetMake(-2.0, 7.0, 0.0, 7.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered]],
//     [@"content-inset",                 CGInsetMake(-3.0, 6.0, 0.0, 4.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 18.0),                  [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, 18.0),                 [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(1.0, 7.0, 1.0, 7.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
//     [@"content-inset",                 CGInsetMake(-2.0, 6.0, 0.0, 6.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
//     [@"content-inset",                 CGInsetMake(-3.0, 6.0, 0.0, 4.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 16.0),                  [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, 16.0),                 [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(1.0, 7.0, 1.0, 7.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeMini]],
//     [@"content-inset",                 CGInsetMake(0.0, 6.0, 0.0, 6.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeMini]],
//     [@"content-inset",                 CGInsetMake(-4.0, 6.0, 0.0, 4.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -5.0, 0.0, -3.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 14.0),                  [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, 14.0),                 [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // IB Style : Recessed (CPButtonStateBezelStyleRecessed) - Bordered
     [@"bezel-color",                   recessedButtonCssColor,                 [CPButtonStateBezelStyleRecessed, CPThemeStateBordered]],
     [@"bezel-color",                   recessedDisabledButtonCssColor,         [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   recessedDisabledButtonCssColor,         [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateHovered]],
     [@"bezel-color",                   recessedHighlightedButtonCssColor,      [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color",                   recessedHoveredButtonCssColor,          [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateHovered]],
     [@"bezel-color",                   recessedSelectedButtonCssColor,         [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateSelected]],
     [@"bezel-color",                   recessedDisabledButtonCssColor,         [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateSelected, CPThemeStateDisabled]],
     [@"bezel-color",                   recessedDisabledButtonCssColor,         [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateSelected, CPThemeStateDisabled, CPThemeStateHovered]],
     [@"bezel-color",                   recessedHighlightedButtonCssColor,      [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateSelected, CPThemeStateHighlighted]],
     [@"bezel-color",                   recessedHoveredButtonCssColor,          [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateSelected, CPThemeStateHovered]],

     [@"text-color",                    A3CPColorActiveText65,                  [CPButtonStateBezelStyleRecessed, CPThemeStateBordered]],
     [@"text-color",                    A3CPColorDefaultText,                   [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"text-color",                    A3CPColorDefaultText,                   [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateHovered]],
     [@"text-color",                    A3CPColorDefaultText,                   [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateSelected]],
     [@"text-color",                    A3CPColorInactiveText,                  [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"text-color",                    A3CPColorInactiveWhiteText,             [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateSelected]],
     [@"text-color",                    A3CPColorInactiveWhiteText,             [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateHighlighted]],

     [@"content-inset",                 CGInsetMake(1.0, 6.0, 1.0, 4.0),        [CPButtonStateBezelStyleRecessed, CPThemeStateBordered]],
//     [@"content-inset",                 CGInsetMake(-2.0, 6.0, 0.0, 4.0),       [CPButtonStateBezelStyleRecessed, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleRecessed, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 18.0),                  [CPButtonStateBezelStyleRecessed, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, 18.0),                 [CPButtonStateBezelStyleRecessed, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(1.0, 6.0, 1.0, 4.0),        [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
//     [@"content-inset",                 CGInsetMake(-2.0, 6.0, 0.0, 4.0),       [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 16.0),                  [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, 16.0),                 [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(1.0, 6.0, 1.0, 4.0),        [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeMini]],
//     [@"content-inset",                 CGInsetMake(-1.0, 6.0, 0.0, 4.0),       [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -5.0, 0.0, -3.0),       [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 14.0),                  [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, 14.0),                 [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // IB Style : Inline (CPButtonStateBezelStyleInline) - Bordered
     [@"bezel-color",                   inlineButtonCssColor,                   [CPButtonStateBezelStyleInline, CPThemeStateBordered]],
     [@"bezel-color",                   inlineDisabledButtonCssColor,           [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   inlineHighlightedButtonCssColor,        [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorDefaultText,                   [CPButtonStateBezelStyleInline, CPThemeStateBordered]],
     [@"text-color",                    A3CPColorInactiveText,                  [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"text-color",                    A3CPColorDefaultText,                   [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateHighlighted]],

//     [@"invert-image",                  YES,                                    [CPButtonStateBezelStyleInline, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(1.0, 2.0, 1.0, 2.0),        [CPButtonStateBezelStyleInline, CPThemeStateBordered]],
//     [@"content-inset",                 CGInsetMake(-2.0, 6.0, 0.0, 4.0),       [CPButtonStateBezelStyleInline, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleInline, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 16.0),                  [CPButtonStateBezelStyleInline, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, 16.0),                 [CPButtonStateBezelStyleInline, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(1.0, 2.0, 1.0, 2.0),        [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
//     [@"content-inset",                 CGInsetMake(-2.0, 6.0, 0.0, 4.0),       [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 16.0),                  [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, 16.0),                 [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(1.0, 2.0, 1.0, 2.0),        [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeMini]],
//     [@"content-inset",                 CGInsetMake(-2.0, 6.0, 0.0, 4.0),       [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 16.0),                  [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, 16.0),                 [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // IB Style : Bevel (CPButtonStateBezelStyleRegularSquare) - Bordered
     [@"bezel-color",                   bevelButtonCssColor,                    [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered]],
     [@"bezel-color",                   bevelDisabledButtonCssColor,            [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   bevelHighlightedButtonCssColor,         [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"content-inset",                 CGInsetMake(-3.0, 8.0, 0.0, 6.0),       [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(2.0, -8.0, -4.0, -5.0),      [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 21.0),                  [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, 21.0),                 [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(-3.0, 8.0, 0.0, 6.0),       [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(2.0, -8.0, -4.0, -5.0),      [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 21.0),                  [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, 21.0),                 [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(-3.0, 8.0, 0.0, 6.0),       [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(2.0, -8.0, -4.0, -5.0),      [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 21.0),                  [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, 21.0),                 [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // IB Style : Textured (CPButtonStateBezelStyleTextured) - Bordered
     [@"bezel-color",                   texturedButtonCssColor,                 [CPButtonStateBezelStyleTextured, CPThemeStateBordered]],
     [@"bezel-color",                   texturedDisabledButtonCssColor,         [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   texturedHighlightedButtonCssColor,      [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"content-inset",                 CGInsetMake(-3.0, 8.0, 0.0, 6.0),       [CPButtonStateBezelStyleTextured, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -5.0, 0.0, -3.0),       [CPButtonStateBezelStyleTextured, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 20.0),                  [CPButtonStateBezelStyleTextured, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, 20.0),                 [CPButtonStateBezelStyleTextured, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(-3.0, 8.0, 0.0, 6.0),       [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 18.0),                  [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, 18.0),                 [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(-3.0, 8.0, 0.0, 6.0),       [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 15.0),                  [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, 15.0),                 [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // IB Style : Disclosure triangle (CPButtonStateBezelStyleDisclosure) - Bordered
     [@"image",                         disclosureImage,                        [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered]],
     [@"image",                         disclosureDisabledImage,                [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"image",                         disclosureHighlightedImage,             [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"image",                         disclosureDownImage,                    [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered, CPThemeStateSelected]],
     [@"image",                         disclosureHighlightedDownImage,         [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered, CPThemeStateSelected, CPThemeStateHighlighted]],
     [@"image",                         disclosureDisabledDownImage,            [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered, CPThemeStateSelected, CPThemeStateDisabled]],

     [@"image-offset",                  0.0,                                    [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered]],
     [@"image-position",                CPImageOnly,                            [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(0.0, 0.0, 0.0, 2.0),        [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(3.0, -3.0, 0.0, 0.0),        [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(13.0, 13.0),                 [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(13.0, 13.0),                 [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered]],

     // IB Style : Disclosure rounded (CPButtonStateBezelStyleRoundedDisclosure) - Bordered
     [@"bezel-color",                   disclosureRoundedCssColor,              [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],
     [@"bezel-color",                   disclosureRoundedDisabledCssColor,      [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   disclosureRoundedHighlightedCssColor,   [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"image",                         disclosureOffImage,                     [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],
     [@"image",                         disclosureOnImage,                      [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateSelected]],

     [@"image-offset",                  0.0,                                    [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],
     [@"image-position",                CPImageOnly,                            [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(1.0, 0.0, 0.0, 0.0),        [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],
     [@"content-inset",                 CGInsetMake(0.0, 0.0, 0.0, 0.0),        [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateSelected]],

     [@"nib2cib-adjustment-frame",      CGRectMake(4.0, -8.0, -8.0, -5.0),      [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(21.0, 21.0),                 [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(21.0, 21.0),                 [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(0.0, 0.0, 0.0, 0.0),        [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(3.0, -8.0, -6.0, -5.0),      [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(19.0, 18.0),                 [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(19.0, 18.0),                 [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(0.0, 0.0, 0.0, 0.0),        [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, -2.0, -1.0),      [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(15.0, 15.0),                 [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(15.0, 15.0),                 [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeMini]],


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

//+ (CPButton)themedDefaultButton
//{
//    var button = [self button];
//
//    [button setTitle:@"OK"];
//    [button setThemeState:CPThemeStateDefault];
//
//    return button;
//}
//
//+ (CPButton)themedRoundedButton
//{
//    var button = [self button];
//
//    [button setTitle:@"Save"];
//    [button setThemeState:CPButtonStateBezelStyleRounded];
//
//    return button;
//}
//
//+ (CPButton)themedDefaultRoundedButton
//{
//    var button = [self button];
//
//    [button setTitle:@"OK"];
//    [button setThemeStates:[CPButtonStateBezelStyleRounded, CPThemeStateDefault]];
//
//    return button;
//}

#pragma mark -

+ (CPPopUpButton)themedPopUpButton
{
    var button = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 21.0) pullsDown:NO],

    // Bordered, IB style "Push" (CPRoundedBezelStyle)

    // Regular size
    buttonCssColor = [CPColor colorWithCSSDictionary:@{
                                                       @"background-color": A3ColorBackgroundWhite,
                                                       @"border-color": A3ColorActiveBorder,
                                                       @"border-style": @"solid",
                                                       @"border-width": @"1px",
                                                       @"border-radius": @"3px",
                                                       @"box-sizing": @"border-box"
                                                       }
                                    beforeDictionary:@{
                                                       @"background-color": @"rgb(225,225,225)",
                                                       @"bottom": @"3px",
                                                       @"content": @"''",
                                                       @"position": @"absolute",
                                                       @"right": @"17px",
//                                                       @"right": @"21px",
                                                       @"top": @"3px",
                                                       @"width": @"1px"
                                                       }
                                     afterDictionary:@{
                                                       @"content": @"''",
                                                       @"right": @"5px",
//                                                       @"right": @"7px",
                                                       @"top": @"50%",
                                                       @"bottom": @"50%",
                                                       @"margin": @"-6px 0px 0px 0px",
                                                       @"position": @"absolute",
                                                       @"height": @"11px",
                                                       @"width": @"7px",
                                                       @"background-image": @"url(%%packed.png)",
                                                       @"background-position": @"0px -64px",
                                                       @"background-repeat": @"no-repeat",
                                                       @"background-size": @"100px 400px"
                                                       }],

    notKeyButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"border-color": A3ColorActiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"3px",
                                                             @"box-sizing": @"border-box"
                                                             }
                                          beforeDictionary:@{
                                                             @"background-color": @"rgb(225,225,225)",
                                                             @"bottom": @"3px",
                                                             @"content": @"''",
                                                             @"position": @"absolute",
                                                             @"right": @"17px",
                                                             @"top": @"3px",
                                                             @"width": @"1px"
                                                             }
                                           afterDictionary:@{
                                                             @"content": @"''",
                                                             @"right": @"5px",
                                                             @"top": @"50%",
                                                             @"bottom": @"50%",
                                                             @"margin": @"-6px 0px 0px 0px",
                                                             @"position": @"absolute",
                                                             @"height": @"11px",
                                                             @"width": @"7px",
                                                             @"background-image": @"url(%%packed.png)",
                                                             @"background-position": @"-8px -64px",
                                                             @"background-repeat": @"no-repeat",
                                                             @"background-size": @"100px 400px"
                                                             }],

    disabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackgroundInactive,
                                                               @"border-color": A3ColorInactiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }
                                            beforeDictionary:nil
                                             afterDictionary:@{
                                                               @"content": @"''",
                                                               @"right": @"5px",
                                                               @"top": @"50%",
                                                               @"bottom": @"50%",
                                                               @"margin": @"-6px 0px 0px 0px",
                                                               @"position": @"absolute",
                                                               @"height": @"11px",
                                                               @"width": @"7px",
                                                               @"background-image": @"url(%%packed.png)",
                                                               @"background-position": @"-16px -64px",
                                                               @"background-repeat": @"no-repeat",
                                                               @"background-size": @"100px 400px"
                                                               }],

    highlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"border-color": A3ColorBorderDark,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"3px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"background-color": A3ColorBackgroundHighlighted
                                                                  }],

    // Small size
    smallButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": A3ColorBackgroundWhite,
                                                            @"border-color": A3ColorActiveBorder,
                                                            @"border-style": @"solid",
                                                            @"border-width": @"1px",
                                                            @"border-radius": @"3px",
                                                            @"box-sizing": @"border-box"
                                                            }
                                         beforeDictionary:@{
                                                            @"background-color": @"rgb(225,225,225)",
                                                            @"bottom": @"3px",
                                                            @"content": @"''",
                                                            @"position": @"absolute",
                                                            @"right": @"15px",
                                                            @"top": @"3px",
                                                            @"width": @"1px"
                                                            }
                                          afterDictionary:@{
                                                            @"content": @"''",
                                                            @"right": @"4px",
                                                            @"top": @"50%",
                                                            @"bottom": @"50%",
                                                            @"margin": @"-5px 0px 0px 0px",
                                                            @"position": @"absolute",
                                                            @"height": @"10px",
                                                            @"width": @"7px",
                                                            @"background-image": @"url(%%packed.png)",
                                                            @"background-position": @"0px -80px",
                                                            @"background-repeat": @"no-repeat",
                                                            @"background-size": @"100px 400px"
                                                            }],

    smallNotKeyButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": A3ColorBackgroundWhite,
                                                                  @"border-color": A3ColorActiveBorder,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"3px",
                                                                  @"box-sizing": @"border-box"
                                                                  }
                                               beforeDictionary:@{
                                                                  @"background-color": @"rgb(225,225,225)",
                                                                  @"bottom": @"3px",
                                                                  @"content": @"''",
                                                                  @"position": @"absolute",
                                                                  @"right": @"15px",
                                                                  @"top": @"3px",
                                                                  @"width": @"1px"
                                                                  }
                                                afterDictionary:@{
                                                                  @"content": @"''",
                                                                  @"right": @"4px",
                                                                  @"top": @"50%",
                                                                  @"bottom": @"50%",
                                                                  @"margin": @"-5px 0px 0px 0px",
                                                                  @"position": @"absolute",
                                                                  @"height": @"10px",
                                                                  @"width": @"7px",
                                                                  @"background-image": @"url(%%packed.png)",
                                                                  @"background-position": @"-8px -80px",
                                                                  @"background-repeat": @"no-repeat",
                                                                  @"background-size": @"100px 400px"
                                                                  }],

    smallDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorBackgroundInactive,
                                                                    @"border-color": A3ColorInactiveBorder,
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"border-radius": @"3px",
                                                                    @"box-sizing": @"border-box"
                                                                    }
                                                 beforeDictionary:nil
                                                  afterDictionary:@{
                                                                    @"content": @"''",
                                                                    @"right": @"4px",
                                                                    @"top": @"50%",
                                                                    @"bottom": @"50%",
                                                                    @"margin": @"-5px 0px 0px 0px",
                                                                    @"position": @"absolute",
                                                                    @"height": @"10px",
                                                                    @"width": @"7px",
                                                                    @"background-image": @"url(%%packed.png)",
                                                                    @"background-position": @"-16px -80px",
                                                                    @"background-repeat": @"no-repeat",
                                                                    @"background-size": @"100px 400px"
                                                                    }],

    smallHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"border-color": A3ColorBorderDark,
                                                                       @"border-style": @"solid",
                                                                       @"border-width": @"1px",
                                                                       @"border-radius": @"3px",
                                                                       @"box-sizing": @"border-box",
                                                                       @"background-color": A3ColorBackgroundHighlighted
                                                                       }],

    // Mini size
    miniButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"border-color": A3ColorActiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"3px",
                                                           @"box-sizing": @"border-box"
                                                           }
                                        beforeDictionary:@{
                                                           @"background-color": @"rgb(225,225,225)",
                                                           @"bottom": @"2px",
                                                           @"content": @"''",
                                                           @"position": @"absolute",
                                                           @"right": @"12px",
                                                           @"top": @"2px",
                                                           @"width": @"1px"
                                                           }
                                         afterDictionary:@{
                                                           @"content": @"''",
                                                           @"right": @"3px",
                                                           @"top": @"50%",
                                                           @"bottom": @"50%",
                                                           @"margin": @"-5px 0px 0px 0px",
                                                           @"position": @"absolute",
                                                           @"height": @"9px",
                                                           @"width": @"6px",
                                                           @"background-image": @"url(%%packed.png)",
                                                           @"background-position": @"0px -96px",
                                                           @"background-repeat": @"no-repeat",
                                                           @"background-size": @"100px 400px"
                                                           }],

    miniNotKeyButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBackgroundWhite,
                                                                 @"border-color": A3ColorActiveBorder,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"3px",
                                                                 @"box-sizing": @"border-box"
                                                                 }
                                              beforeDictionary:@{
                                                                 @"background-color": @"rgb(225,225,225)",
                                                                 @"bottom": @"2px",
                                                                 @"content": @"''",
                                                                 @"position": @"absolute",
                                                                 @"right": @"12px",
                                                                 @"top": @"2px",
                                                                 @"width": @"1px"
                                                                 }
                                               afterDictionary:@{
                                                                 @"content": @"''",
                                                                 @"right": @"3px",
                                                                 @"top": @"50%",
                                                                 @"bottom": @"50%",
                                                                 @"margin": @"-5px 0px 0px 0px",
                                                                 @"position": @"absolute",
                                                                 @"height": @"9px",
                                                                 @"width": @"6px",
                                                                 @"background-image": @"url(%%packed.png)",
                                                                 @"background-position": @"-8px -96px",
                                                                 @"background-repeat": @"no-repeat",
                                                                 @"background-size": @"100px 400px"
                                                                 }],

    miniDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                   @"background-color": A3ColorBackgroundInactive,
                                                                   @"border-color": A3ColorInactiveBorder,
                                                                   @"border-style": @"solid",
                                                                   @"border-width": @"1px",
                                                                   @"border-radius": @"3px",
                                                                   @"box-sizing": @"border-box"
                                                                   }
                                                beforeDictionary:nil
                                                 afterDictionary:@{
                                                                   @"content": @"''",
                                                                   @"right": @"3px",
                                                                   @"top": @"50%",
                                                                   @"bottom": @"50%",
                                                                   @"margin": @"-5px 0px 0px 0px",
                                                                   @"position": @"absolute",
                                                                   @"height": @"9px",
                                                                   @"width": @"6px",
                                                                   @"background-image": @"url(%%packed.png)",
                                                                   @"background-position": @"-16px -96px",
                                                                   @"background-repeat": @"no-repeat",
                                                                   @"background-size": @"100px 400px"
                                                                   }],

    miniHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                      @"border-color": A3ColorBorderDark,
                                                                      @"border-style": @"solid",
                                                                      @"border-width": @"1px",
                                                                      @"border-radius": @"3px",
                                                                      @"box-sizing": @"border-box",
                                                                      @"background-color": A3ColorBackgroundHighlighted
                                                                      }],

    // Not bordered, IB style "Bevel" (CPRegularSquareBezelStyle)

    // Regular size
    nbButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                         @"background-color": A3ColorTransparent,
                                                         @"border-color": A3ColorTransparent,
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"border-radius": @"3px",
                                                         @"box-sizing": @"border-box"
                                                         }
                                      beforeDictionary:nil
                                       afterDictionary:@{
                                                         @"content": @"''",
                                                         @"right": @"1px",
                                                         @"top": @"50%",
                                                         @"bottom": @"50%",
                                                         @"margin": @"-5px 0px 0px 0px",
                                                         @"position": @"absolute",
                                                         @"height": @"11px",
                                                         @"width": @"7px",
                                                         @"background-image": @"url(%%packed.png)",
                                                         @"background-position": @"-8px -64px",
                                                         @"background-repeat": @"no-repeat",
                                                         @"background-size": @"100px 400px"
                                                         }],

    nbDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorTransparent,
                                                                 @"border-color": A3ColorTransparent,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"3px",
                                                                 @"box-sizing": @"border-box"
                                                                 }
                                              beforeDictionary:nil
                                               afterDictionary:@{
                                                                 @"content": @"''",
                                                                 @"right": @"1px",
                                                                 @"top": @"50%",
                                                                 @"bottom": @"50%",
                                                                 @"margin": @"-5px 0px 0px 0px",
                                                                 @"position": @"absolute",
                                                                 @"height": @"11px",
                                                                 @"width": @"7px",
                                                                 @"background-image": @"url(%%packed.png)",
                                                                 @"background-position": @"-16px -64px",
                                                                 @"background-repeat": @"no-repeat",
                                                                 @"background-size": @"100px 400px"
                                                                 }],

    nbHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"border-color": A3ColorTransparent,
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"border-radius": @"3px",
                                                                    @"box-sizing": @"border-box",
                                                                    @"background-color": A3ColorTransparent
                                                                    }],

    // Small size
    nbSmallButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": A3ColorTransparent,
                                                              @"border-color": A3ColorTransparent,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"3px",
                                                              @"box-sizing": @"border-box"
                                                              }
                                           beforeDictionary:nil
                                            afterDictionary:@{
                                                              @"content": @"''",
                                                              @"right": @"1px",
                                                              @"top": @"50%",
                                                              @"bottom": @"50%",
                                                              @"margin": @"-5px 0px 0px 0px",
                                                              @"position": @"absolute",
                                                              @"height": @"10px",
                                                              @"width": @"7px",
                                                              @"background-image": @"url(%%packed.png)",
                                                              @"background-position": @"-8px -80px",
                                                              @"background-repeat": @"no-repeat",
                                                              @"background-size": @"100px 400px"
                                                              }],

    nbSmallDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                      @"background-color": A3ColorTransparent,
                                                                      @"border-color": A3ColorTransparent,
                                                                      @"border-style": @"solid",
                                                                      @"border-width": @"1px",
                                                                      @"border-radius": @"3px",
                                                                      @"box-sizing": @"border-box"
                                                                      }
                                                   beforeDictionary:nil
                                                    afterDictionary:@{
                                                                      @"content": @"''",
                                                                      @"right": @"1px",
                                                                      @"top": @"50%",
                                                                      @"bottom": @"50%",
                                                                      @"margin": @"-5px 0px 0px 0px",
                                                                      @"position": @"absolute",
                                                                      @"height": @"10px",
                                                                      @"width": @"7px",
                                                                      @"background-image": @"url(%%packed.png)",
                                                                      @"background-position": @"-16px -80px",
                                                                      @"background-repeat": @"no-repeat",
                                                                      @"background-size": @"100px 400px"
                                                                      }],

    nbSmallHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                         @"border-color": A3ColorTransparent,
                                                                         @"border-style": @"solid",
                                                                         @"border-width": @"1px",
                                                                         @"border-radius": @"3px",
                                                                         @"box-sizing": @"border-box",
                                                                         @"background-color": A3ColorTransparent
                                                                         }],

    // Mini size
    nbMiniButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorTransparent,
                                                             @"border-color": A3ColorTransparent,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"3px",
                                                             @"box-sizing": @"border-box"
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             @"content": @"''",
                                                             @"right": @"1px",
                                                             @"top": @"50%",
                                                             @"bottom": @"50%",
                                                             @"margin": @"-5px 0px 0px 0px",
                                                             @"position": @"absolute",
                                                             @"height": @"9px",
                                                             @"width": @"6px",
                                                             @"background-image": @"url(%%packed.png)",
                                                             @"background-position": @"-8px -96px",
                                                             @"background-repeat": @"no-repeat",
                                                             @"background-size": @"100px 400px"
                                                             }],

    nbMiniDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                     @"background-color": A3ColorTransparent,
                                                                     @"border-color": A3ColorTransparent,
                                                                     @"border-style": @"solid",
                                                                     @"border-width": @"1px",
                                                                     @"border-radius": @"3px",
                                                                     @"box-sizing": @"border-box"
                                                                     }
                                                  beforeDictionary:nil
                                                   afterDictionary:@{
                                                                     @"content": @"''",
                                                                     @"right": @"1px",
                                                                     @"top": @"50%",
                                                                     @"bottom": @"50%",
                                                                     @"margin": @"-5px 0px 0px 0px",
                                                                     @"position": @"absolute",
                                                                     @"height": @"9px",
                                                                     @"width": @"6px",
                                                                     @"background-image": @"url(%%packed.png)",
                                                                     @"background-position": @"-16px -96px",
                                                                     @"background-repeat": @"no-repeat",
                                                                     @"background-size": @"100px 400px"
                                                                     }],

    nbMiniHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                        @"border-color": A3ColorTransparent,
                                                                        @"border-style": @"solid",
                                                                        @"border-width": @"1px",
                                                                        @"border-radius": @"3px",
                                                                        @"box-sizing": @"border-box",
                                                                        @"background-color": A3ColorTransparent
                                                                        }],

    themeValues =
    [
     [@"direct-nib2cib-adjustment",  YES],
     [@"text-color",                 A3CPColorActiveText],
     [@"text-color",                 A3CPColorInactiveText,                     [CPThemeStateDisabled]],
     [@"menu-offset",               CGSizeMake(-2, 1)],

     // Bordered, IB style "Push" (CPRoundedBezelStyle)

     // Regular size
     [@"bezel-color",                buttonCssColor,                            [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateKeyWindow]],
     [@"bezel-color",                notKeyButtonCssColor,                      [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"bezel-color",                highlightedButtonCssColor,                 [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color",                disabledButtonCssColor,                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                disabledButtonCssColor,                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"content-inset",              CGInsetMake(1.0, 19.0, 1.0, 9.0),          [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
//     [@"content-inset",              CGInsetMake(-2.0, 19.0, 0, 9.0),           [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
//     [@"content-inset",              CGInsetMake(-3.0, 22.0 + 5.0, 0, 8.0),     [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"min-size",                   CGSizeMake(32.0, 21.0),                    [CPButtonStateBezelStyleRounded]],
     [@"max-size",                   CGSizeMake(-1.0, 21.0),                    [CPButtonStateBezelStyleRounded]],
     [@"nib2cib-adjustment-frame",   CGRectMake(2.0, -8.0, -5.0, -5.0),         [CPButtonStateBezelStyleRounded]],

     // Small size
     [@"bezel-color",                smallButtonCssColor,                       [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateKeyWindow]],
     [@"bezel-color",                smallNotKeyButtonCssColor,                 [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"bezel-color",                smallHighlightedButtonCssColor,            [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color",                smallDisabledButtonCssColor,               [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                smallDisabledButtonCssColor,               [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"content-inset",              CGInsetMake(1.0, 17.0, 1.00, 8.0),         [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
//     [@"content-inset",              CGInsetMake(-2.0, 17.0, 0, 8.0),           [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"min-size",                   CGSizeMake(32.0, 18.0),                    [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall]],
     [@"max-size",                   CGSizeMake(-1.0, 18.0),                    [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",   CGRectMake(3.0, -7.0, -6.0, -4.0),         [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall]],

     // Mini size
     [@"bezel-color",                miniButtonCssColor,                        [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateKeyWindow]],
     [@"bezel-color",                miniNotKeyButtonCssColor,                  [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"bezel-color",                miniHighlightedButtonCssColor,             [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color",                miniDisabledButtonCssColor,                [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                miniDisabledButtonCssColor,                [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"content-inset",              CGInsetMake(1.0, 14.0, 1.0, 10.0),         [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],
//     [@"content-inset",              CGInsetMake(-1.0, 14.0, 0, 10.0),          [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"min-size",                   CGSizeMake(32.0, 15.0),                    [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini]],
     [@"max-size",                   CGSizeMake(-1.0, 15.0),                    [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",   CGRectMake(1.0, -0.0, -3.0, -0.0),         [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini]],

     // Not bordered, IB style "Bevel" (CPRegularSquareBezelStyle)

     // Regular size
     [@"bezel-color",                nbButtonCssColor,                          [CPButtonStateBezelStyleRegularSquare, CPThemeStateKeyWindow]],
     [@"bezel-color",                nbButtonCssColor,                          [CPButtonStateBezelStyleRegularSquare]],
     [@"bezel-color",                nbHighlightedButtonCssColor,               [CPButtonStateBezelStyleRegularSquare, CPThemeStateHighlighted]],
     [@"bezel-color",                nbDisabledButtonCssColor,                  [CPButtonStateBezelStyleRegularSquare, CPThemeStateDisabled]],
     [@"bezel-color",                nbDisabledButtonCssColor,                  [CPButtonStateBezelStyleRegularSquare, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"content-inset",              CGInsetMake(-3.0, 13, 0, 2.0),             [CPButtonStateBezelStyleRegularSquare]], // was (-3.0, 22.0 + 5.0, 0, 8.0)
     [@"min-size",                   CGSizeMake(32.0, 21.0),                    [CPButtonStateBezelStyleRegularSquare]],
     [@"max-size",                   CGSizeMake(-1.0, 21.0),                    [CPButtonStateBezelStyleRegularSquare]],
     [@"nib2cib-adjustment-frame",   CGRectMake(0.0, -0.0, -0.0, -0.0),         [CPButtonStateBezelStyleRegularSquare]],

     // Small size
     [@"bezel-color",                nbSmallButtonCssColor,                     [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall, CPThemeStateKeyWindow]],
     [@"bezel-color",                nbSmallButtonCssColor,                     [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall]],
     [@"bezel-color",                nbSmallHighlightedButtonCssColor,          [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall, CPThemeStateHighlighted]],
     [@"bezel-color",                nbSmallDisabledButtonCssColor,             [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
     [@"bezel-color",                nbSmallDisabledButtonCssColor,             [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"content-inset",              CGInsetMake(-3.0, 13, 0, 2.0),             [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall]],
     [@"min-size",                   CGSizeMake(32.0, 18.0),                    [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall]],
     [@"max-size",                   CGSizeMake(-1.0, 18.0),                    [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",   CGRectMake(0.0, -0.0, -0.0, -0.0),         [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall]],

     // Mini size
     [@"bezel-color",                nbMiniButtonCssColor,                      [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini, CPThemeStateKeyWindow]],
     [@"bezel-color",                nbMiniButtonCssColor,                      [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini]],
     [@"bezel-color",                nbMiniHighlightedButtonCssColor,           [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini, CPThemeStateHighlighted]],
     [@"bezel-color",                nbMiniDisabledButtonCssColor,              [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini, CPThemeStateDisabled]],
     [@"bezel-color",                nbMiniDisabledButtonCssColor,              [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"content-inset",              CGInsetMake(-3.0, 13, 0, 2.0),             [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini]],
     [@"min-size",                   CGSizeMake(32.0, 16.0),                    [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini]],
     [@"max-size",                   CGSizeMake(-1.0, 16.0),                    [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",   CGRectMake(0.0, -0.0, -0.0, -0.0),         [CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini]]

     ];

    [self registerThemeValues:themeValues forView:button];

    [button setTitle:@"Pop Up"];
    [button addItemWithTitle:@"item"];

    return button;
}

+ (CPPopUpButton)themedPullDownMenu
{
    var button = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 21.0) pullsDown:YES],

    // Bordered, IB style "Push" (CPRoundedBezelStyle)

    // Regular size
    buttonCssColor = [CPColor colorWithCSSDictionary:@{
                                                       @"background-color": A3ColorBackgroundWhite,
                                                       @"border-color": A3ColorActiveBorder,
                                                       @"border-style": @"solid",
                                                       @"border-width": @"1px",
                                                       @"border-radius": @"3px",
                                                       @"box-sizing": @"border-box"
                                                       }
                                    beforeDictionary:@{
                                                       @"background-color": @"rgb(225,225,225)",
                                                       @"bottom": @"3px",
                                                       @"content": @"''",
                                                       @"position": @"absolute",
                                                       @"right": @"17px",
                                                       @"top": @"3px",
                                                       @"width": @"1px"
                                                       }
                                     afterDictionary:@{
                                                       @"content": @"''",
                                                       @"right": @"5px",
                                                       @"top": @"50%",
                                                       @"bottom": @"50%",
                                                       @"margin": @"-2px 0px 0px 0px",
                                                       @"position": @"absolute",
                                                       @"height": @"4px",
                                                       @"width": @"7px",
                                                       @"background-image": @"url(%%packed.png)",
                                                       @"background-position": @"-0px -48px",
                                                       @"background-repeat": @"no-repeat",
                                                       @"background-size": @"100px 400px"
                                                       }],

    notKeyButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"border-color": A3ColorActiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"3px",
                                                             @"box-sizing": @"border-box"
                                                             }
                                          beforeDictionary:@{
                                                             @"background-color": @"rgb(225,225,225)",
                                                             @"bottom": @"3px",
                                                             @"content": @"''",
                                                             @"position": @"absolute",
                                                             @"right": @"17px",
                                                             @"top": @"3px",
                                                             @"width": @"1px"
                                                             }
                                           afterDictionary:@{
                                                             @"content": @"''",
                                                             @"right": @"5px",
                                                             @"top": @"50%",
                                                             @"bottom": @"50%",
                                                             @"margin": @"-2px 0px 0px 0px",
                                                             @"position": @"absolute",
                                                             @"height": @"4px",
                                                             @"width": @"7px",
                                                             @"background-image": @"url(%%packed.png)",
                                                             @"background-position": @"-8px -48px",
                                                             @"background-repeat": @"no-repeat",
                                                             @"background-size": @"100px 400px"
                                                             }],

    disabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackgroundInactive,
                                                               @"border-color": A3ColorInactiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }
                                            beforeDictionary:nil
                                             afterDictionary:@{
                                                               @"content": @"''",
                                                               @"right": @"5px",
                                                               @"top": @"50%",
                                                               @"bottom": @"50%",
                                                               @"margin": @"-2px 0px 0px 0px",
                                                               @"position": @"absolute",
                                                               @"height": @"4px",
                                                               @"width": @"7px",
                                                               @"background-image": @"url(%%packed.png)",
                                                               @"background-position": @"-16px -48px",
                                                               @"background-repeat": @"no-repeat",
                                                               @"background-size": @"100px 400px"
                                                               }],

    highlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"border-color": A3ColorBorderDark,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"3px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"background-color": A3ColorBackgroundInactive
                                                                  }
                                               beforeDictionary:@{
                                                                  @"background-color": @"rgb(225,225,225)",
                                                                  @"bottom": @"3px",
                                                                  @"content": @"''",
                                                                  @"position": @"absolute",
                                                                  @"right": @"17px",
                                                                  @"top": @"3px",
                                                                  @"width": @"1px"
                                                                  }
                                                afterDictionary:@{
                                                                  @"content": @"''",
                                                                  @"right": @"5px",
                                                                  @"top": @"50%",
                                                                  @"bottom": @"50%",
                                                                  @"margin": @"-2px 0px 0px 0px",
                                                                  @"position": @"absolute",
                                                                  @"height": @"4px",
                                                                  @"width": @"7px",
                                                                  @"background-image": @"url(%%packed.png)",
                                                                  @"background-position": @"-24px -48px",
                                                                  @"background-repeat": @"no-repeat",
                                                                  @"background-size": @"100px 400px"
                                                                  }],

    // Small size
    smallButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": A3ColorBackgroundWhite,
                                                            @"border-color": A3ColorActiveBorder,
                                                            @"border-style": @"solid",
                                                            @"border-width": @"1px",
                                                            @"border-radius": @"3px",
                                                            @"box-sizing": @"border-box"
                                                            }
                                         beforeDictionary:@{
                                                            @"background-color": @"rgb(225,225,225)",
                                                            @"bottom": @"3px",
                                                            @"content": @"''",
                                                            @"position": @"absolute",
                                                            @"right": @"15px",
                                                            @"top": @"3px",
                                                            @"width": @"1px"
                                                            }
                                          afterDictionary:@{
                                                            @"content": @"''",
                                                            @"right": @"4px",
                                                            @"top": @"50%",
                                                            @"bottom": @"50%",
                                                            @"margin": @"-2px 0px 0px 0px",
                                                            @"position": @"absolute",
                                                            @"height": @"4px",
                                                            @"width": @"7px",
                                                            @"background-image": @"url(%%packed.png)",
                                                            @"background-position": @"-0px -48px",
                                                            @"background-repeat": @"no-repeat",
                                                            @"background-size": @"100px 400px"
                                                            }],

    smallNotKeyButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": A3ColorBackgroundWhite,
                                                                  @"border-color": A3ColorActiveBorder,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"3px",
                                                                  @"box-sizing": @"border-box"
                                                                  }
                                               beforeDictionary:@{
                                                                  @"background-color": @"rgb(225,225,225)",
                                                                  @"bottom": @"3px",
                                                                  @"content": @"''",
                                                                  @"position": @"absolute",
                                                                  @"right": @"15px",
                                                                  @"top": @"3px",
                                                                  @"width": @"1px"
                                                                  }
                                                afterDictionary:@{
                                                                  @"content": @"''",
                                                                  @"right": @"4px",
                                                                  @"top": @"50%",
                                                                  @"bottom": @"50%",
                                                                  @"margin": @"-2px 0px 0px 0px",
                                                                  @"position": @"absolute",
                                                                  @"height": @"4px",
                                                                  @"width": @"7px",
                                                                  @"background-image": @"url(%%packed.png)",
                                                                  @"background-position": @"-8px -48px",
                                                                  @"background-repeat": @"no-repeat",
                                                                  @"background-size": @"100px 400px"
                                                                  }],

    smallDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorBackgroundInactive,
                                                                    @"border-color": A3ColorInactiveBorder,
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"border-radius": @"3px",
                                                                    @"box-sizing": @"border-box"
                                                                    }
                                                 beforeDictionary:nil
                                                  afterDictionary:@{
                                                                    @"content": @"''",
                                                                    @"right": @"4px",
                                                                    @"top": @"50%",
                                                                    @"bottom": @"50%",
                                                                    @"margin": @"-2px 0px 0px 0px",
                                                                    @"position": @"absolute",
                                                                    @"height": @"4px",
                                                                    @"width": @"7px",
                                                                    @"background-image": @"url(%%packed.png)",
                                                                    @"background-position": @"-16px -48px",
                                                                    @"background-repeat": @"no-repeat",
                                                                    @"background-size": @"100px 400px"
                                                                    }],

    smallHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"border-color": A3ColorBorderDark,
                                                                       @"border-style": @"solid",
                                                                       @"border-width": @"1px",
                                                                       @"border-radius": @"3px",
                                                                       @"box-sizing": @"border-box",
                                                                       @"background-color": A3ColorBackgroundInactive
                                                                       }
                                                    beforeDictionary:@{
                                                                       @"background-color": @"rgb(225,225,225)",
                                                                       @"bottom": @"3px",
                                                                       @"content": @"''",
                                                                       @"position": @"absolute",
                                                                       @"right": @"15px",
                                                                       @"top": @"3px",
                                                                       @"width": @"1px"
                                                                       }
                                                     afterDictionary:@{
                                                                       @"content": @"''",
                                                                       @"right": @"4px",
                                                                       @"top": @"50%",
                                                                       @"bottom": @"50%",
                                                                       @"margin": @"-2px 0px 0px 0px",
                                                                       @"position": @"absolute",
                                                                       @"height": @"4px",
                                                                       @"width": @"7px",
                                                                       @"background-image": @"url(%%packed.png)",
                                                                       @"background-position": @"-24px -48px",
                                                                       @"background-repeat": @"no-repeat",
                                                                       @"background-size": @"100px 400px"
                                                                       }],

    // Mini size
    miniButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"border-color": A3ColorActiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"3px",
                                                           @"box-sizing": @"border-box"
                                                           }
                                        beforeDictionary:@{
                                                           @"background-color": @"rgb(225,225,225)",
                                                           @"bottom": @"2px",
                                                           @"content": @"''",
                                                           @"position": @"absolute",
                                                           @"right": @"13px",
                                                           @"top": @"2px",
                                                           @"width": @"1px"
                                                           }
                                         afterDictionary:@{
                                                           @"content": @"''",
                                                           @"right": @"3px",
                                                           @"top": @"50%",
                                                           @"bottom": @"50%",
                                                           @"margin": @"-2px 0px 0px 0px",
                                                           @"position": @"absolute",
                                                           @"height": @"4px",
                                                           @"width": @"7px",
                                                           @"background-image": @"url(%%packed.png)",
                                                           @"background-position": @"-0px -48px",
                                                           @"background-repeat": @"no-repeat",
                                                           @"background-size": @"100px 400px"
                                                           }],

    miniNotKeyButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBackgroundWhite,
                                                                 @"border-color": A3ColorActiveBorder,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"3px",
                                                                 @"box-sizing": @"border-box"
                                                                 }
                                              beforeDictionary:@{
                                                                 @"background-color": @"rgb(225,225,225)",
                                                                 @"bottom": @"2px",
                                                                 @"content": @"''",
                                                                 @"position": @"absolute",
                                                                 @"right": @"13px",
                                                                 @"top": @"2px",
                                                                 @"width": @"1px"
                                                                 }
                                               afterDictionary:@{
                                                                 @"content": @"''",
                                                                 @"right": @"3px",
                                                                 @"top": @"50%",
                                                                 @"bottom": @"50%",
                                                                 @"margin": @"-2px 0px 0px 0px",
                                                                 @"position": @"absolute",
                                                                 @"height": @"4px",
                                                                 @"width": @"7px",
                                                                 @"background-image": @"url(%%packed.png)",
                                                                 @"background-position": @"-8px -48px",
                                                                 @"background-repeat": @"no-repeat",
                                                                 @"background-size": @"100px 400px"
                                                                 }],

    miniDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                   @"background-color": A3ColorBackgroundInactive,
                                                                   @"border-color": A3ColorInactiveBorder,
                                                                   @"border-style": @"solid",
                                                                   @"border-width": @"1px",
                                                                   @"border-radius": @"3px",
                                                                   @"box-sizing": @"border-box"
                                                                   }
                                                beforeDictionary:nil
                                                 afterDictionary:@{
                                                                   @"content": @"''",
                                                                   @"right": @"3px",
                                                                   @"top": @"50%",
                                                                   @"bottom": @"50%",
                                                                   @"margin": @"-2px 0px 0px 0px",
                                                                   @"position": @"absolute",
                                                                   @"height": @"4px",
                                                                   @"width": @"7px",
                                                                   @"background-image": @"url(%%packed.png)",
                                                                   @"background-position": @"-16px -48px",
                                                                   @"background-repeat": @"no-repeat",
                                                                   @"background-size": @"100px 400px"
                                                                   }],

    miniHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                      @"border-color": A3ColorBorderDark,
                                                                      @"border-style": @"solid",
                                                                      @"border-width": @"1px",
                                                                      @"border-radius": @"3px",
                                                                      @"box-sizing": @"border-box",
                                                                      @"background-color": A3ColorBackgroundInactive
                                                                      }
                                                   beforeDictionary:@{
                                                                      @"background-color": @"rgb(225,225,225)",
                                                                      @"bottom": @"2px",
                                                                      @"content": @"''",
                                                                      @"position": @"absolute",
                                                                      @"right": @"13px",
                                                                      @"top": @"2px",
                                                                      @"width": @"1px"
                                                                      }
                                                    afterDictionary:@{
                                                                      @"content": @"''",
                                                                      @"right": @"3px",
                                                                      @"top": @"50%",
                                                                      @"bottom": @"50%",
                                                                      @"margin": @"-2px 0px 0px 0px",
                                                                      @"position": @"absolute",
                                                                      @"height": @"4px",
                                                                      @"width": @"7px",
                                                                      @"background-image": @"url(%%packed.png)",
                                                                      @"background-position": @"-24px -48px",
                                                                      @"background-repeat": @"no-repeat",
                                                                      @"background-size": @"100px 400px"
                                                                      }],

    // Not bordered, IB style "Bevel" (CPRegularSquareBezelStyle)

    // Regular size
    nbButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                         @"background-color": A3ColorTransparent,
                                                         @"border-color": A3ColorTransparent,
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"border-radius": @"3px",
                                                         @"box-sizing": @"border-box"
                                                         }
                                      beforeDictionary:nil
                                       afterDictionary:@{
                                                         @"content": @"''",
                                                         @"right": @"3px",
                                                         @"top": @"50%",
                                                         @"bottom": @"50%",
                                                         @"margin": @"-3px 0px 0px 0px",
                                                         @"position": @"absolute",
                                                         @"height": @"4px",
                                                         @"width": @"7px",
                                                         @"background-image": @"url(%%packed.png)",
                                                         @"background-position": @"-8px -48px",
                                                         @"background-repeat": @"no-repeat",
                                                         @"background-size": @"100px 400px"
                                                         }],

    nbDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorTransparent,
                                                                 @"border-color": A3ColorTransparent,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"3px",
                                                                 @"box-sizing": @"border-box"
                                                                 }
                                              beforeDictionary:nil
                                               afterDictionary:@{
                                                                 @"content": @"''",
                                                                 @"right": @"3px",
                                                                 @"top": @"50%",
                                                                 @"bottom": @"50%",
                                                                 @"margin": @"-3px 0px 0px 0px",
                                                                 @"position": @"absolute",
                                                                 @"height": @"4px",
                                                                 @"width": @"7px",
                                                                 @"background-image": @"url(%%packed.png)",
                                                                 @"background-position": @"-16px -48px",
                                                                 @"background-repeat": @"no-repeat",
                                                                 @"background-size": @"100px 400px"
                                                                 }],

    nbHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorTransparent,
                                                                    @"border-color": A3ColorTransparent,
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"border-radius": @"3px",
                                                                    @"box-sizing": @"border-box"
                                                                    }
                                                 beforeDictionary:nil
                                                  afterDictionary:@{
                                                                    @"content": @"''",
                                                                    @"right": @"3px",
                                                                    @"top": @"50%",
                                                                    @"bottom": @"50%",
                                                                    @"margin": @"-3px 0px 0px 0px",
                                                                    @"position": @"absolute",
                                                                    @"height": @"4px",
                                                                    @"width": @"7px",
                                                                    @"background-image": @"url(%%packed.png)",
                                                                    @"background-position": @"-24px -48px",
                                                                    @"background-repeat": @"no-repeat",
                                                                    @"background-size": @"100px 400px"
                                                                    }],

    // Small size
    smallNbButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": A3ColorTransparent,
                                                              @"border-color": A3ColorTransparent,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"3px",
                                                              @"box-sizing": @"border-box"
                                                              }
                                           beforeDictionary:nil
                                            afterDictionary:@{
                                                              @"content": @"''",
                                                              @"right": @"3px",
                                                              @"top": @"50%",
                                                              @"bottom": @"50%",
                                                              @"margin": @"-2px 0px 0px 0px",
                                                              @"position": @"absolute",
                                                              @"height": @"4px",
                                                              @"width": @"7px",
                                                              @"background-image": @"url(%%packed.png)",
                                                              @"background-position": @"-8px -48px",
                                                              @"background-repeat": @"no-repeat",
                                                              @"background-size": @"100px 400px"
                                                              }],

    smallNbDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                      @"background-color": A3ColorTransparent,
                                                                      @"border-color": A3ColorTransparent,
                                                                      @"border-style": @"solid",
                                                                      @"border-width": @"1px",
                                                                      @"border-radius": @"3px",
                                                                      @"box-sizing": @"border-box"
                                                                      }
                                                   beforeDictionary:nil
                                                    afterDictionary:@{
                                                                      @"content": @"''",
                                                                      @"right": @"3px",
                                                                      @"top": @"50%",
                                                                      @"bottom": @"50%",
                                                                      @"margin": @"-2px 0px 0px 0px",
                                                                      @"position": @"absolute",
                                                                      @"height": @"4px",
                                                                      @"width": @"7px",
                                                                      @"background-image": @"url(%%packed.png)",
                                                                      @"background-position": @"-16px -48px",
                                                                      @"background-repeat": @"no-repeat",
                                                                      @"background-size": @"100px 400px"
                                                                      }],

    smallNbHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                         @"background-color": A3ColorTransparent,
                                                                         @"border-color": A3ColorTransparent,
                                                                         @"border-style": @"solid",
                                                                         @"border-width": @"1px",
                                                                         @"border-radius": @"3px",
                                                                         @"box-sizing": @"border-box"
                                                                         }
                                                      beforeDictionary:nil
                                                       afterDictionary:@{
                                                                         @"content": @"''",
                                                                         @"right": @"3px",
                                                                         @"top": @"50%",
                                                                         @"bottom": @"50%",
                                                                         @"margin": @"-2px 0px 0px 0px",
                                                                         @"position": @"absolute",
                                                                         @"height": @"4px",
                                                                         @"width": @"7px",
                                                                         @"background-image": @"url(%%packed.png)",
                                                                         @"background-position": @"-24px -48px",
                                                                         @"background-repeat": @"no-repeat",
                                                                         @"background-size": @"100px 400px"
                                                                         }],

    // Mini size
    miniNbButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorTransparent,
                                                             @"border-color": A3ColorTransparent,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"3px",
                                                             @"box-sizing": @"border-box"
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             @"content": @"''",
                                                             @"right": @"3px",
                                                             @"top": @"50%",
                                                             @"bottom": @"50%",
                                                             @"margin": @"-3px 0px 0px 0px",
                                                             @"position": @"absolute",
                                                             @"height": @"4px",
                                                             @"width": @"7px",
                                                             @"background-image": @"url(%%packed.png)",
                                                             @"background-position": @"-8px -48px",
                                                             @"background-repeat": @"no-repeat",
                                                             @"background-size": @"100px 400px"
                                                             }],

    miniNbDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                     @"background-color": A3ColorTransparent,
                                                                     @"border-color": A3ColorTransparent,
                                                                     @"border-style": @"solid",
                                                                     @"border-width": @"1px",
                                                                     @"border-radius": @"3px",
                                                                     @"box-sizing": @"border-box"
                                                                     }
                                                  beforeDictionary:nil
                                                   afterDictionary:@{
                                                                     @"content": @"''",
                                                                     @"right": @"3px",
                                                                     @"top": @"50%",
                                                                     @"bottom": @"50%",
                                                                     @"margin": @"-3px 0px 0px 0px",
                                                                     @"position": @"absolute",
                                                                     @"height": @"4px",
                                                                     @"width": @"7px",
                                                                     @"background-image": @"url(%%packed.png)",
                                                                     @"background-position": @"-16px -48px",
                                                                     @"background-repeat": @"no-repeat",
                                                                     @"background-size": @"100px 400px"
                                                                     }],

    miniNbHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                        @"background-color": A3ColorTransparent,
                                                                        @"border-color": A3ColorTransparent,
                                                                        @"border-style": @"solid",
                                                                        @"border-width": @"1px",
                                                                        @"border-radius": @"3px",
                                                                        @"box-sizing": @"border-box"
                                                                        }
                                                     beforeDictionary:nil
                                                      afterDictionary:@{
                                                                        @"content": @"''",
                                                                        @"right": @"3px",
                                                                        @"top": @"50%",
                                                                        @"bottom": @"50%",
                                                                        @"margin": @"-3px 0px 0px 0px",
                                                                        @"position": @"absolute",
                                                                        @"height": @"4px",
                                                                        @"width": @"7px",
                                                                        @"background-image": @"url(%%packed.png)",
                                                                        @"background-position": @"-24px -48px",
                                                                        @"background-repeat": @"no-repeat",
                                                                        @"background-size": @"100px 400px"
                                                                        }],

    themeValues =
    [
     [@"direct-nib2cib-adjustment", YES,                                    CPPopUpButtonStatePullsDown],
     [@"menu-offset",               CGSizeMake(0, -1),                      CPPopUpButtonStatePullsDown],
     [@"text-color",                A3CPColorActiveText,                    CPPopUpButtonStatePullsDown],
     [@"text-color",                A3CPColorInactiveText,                  [CPPopUpButtonStatePullsDown, CPThemeStateDisabled]],

     // Bordered, IB style "Push" (CPRoundedBezelStyle)

     // Regular size
     [@"bezel-color",               buttonCssColor,                         [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateKeyWindow]],
     [@"bezel-color",               notKeyButtonCssColor,                   [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"bezel-color",               highlightedButtonCssColor,              [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateKeyWindow, CPThemeStateHighlighted]],
     [@"bezel-color",               disabledButtonCssColor,                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",               disabledButtonCssColor,                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"nib2cib-adjustment-frame",  CGRectMake(3.0, -8.0, -6.0, -5.0),      [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"content-inset",             CGInsetMake(1.0, 19.0, 1.0, 9.0),       [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
//     [@"content-inset",             CGInsetMake(-2.0, 19.0, 0, 9.0),        [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"min-size",                  CGSizeMake(32.0, 21.0),                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered]],

     // Small size
     [@"bezel-color",               smallButtonCssColor,                    [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateKeyWindow]],
     [@"bezel-color",               smallNotKeyButtonCssColor,              [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"bezel-color",               smallHighlightedButtonCssColor,         [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateKeyWindow, CPThemeStateHighlighted]],
     [@"bezel-color",               smallDisabledButtonCssColor,            [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",               smallDisabledButtonCssColor,            [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"nib2cib-adjustment-frame",  CGRectMake(3.0, -7.0, -6.0, -4.0),      [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"content-inset",             CGInsetMake(1.0, 17.0, 1.0, 8.0),       [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
//     [@"content-inset",             CGInsetMake(-2.0, 17.0, 0, 8.0),        [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"min-size",                  CGSizeMake(32.0, 18.0),                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],

     // Mini size
     [@"bezel-color",               miniButtonCssColor,                     [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateKeyWindow]],
     [@"bezel-color",               miniNotKeyButtonCssColor,               [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"bezel-color",               miniHighlightedButtonCssColor,          [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateKeyWindow, CPThemeStateHighlighted]],
     [@"bezel-color",               miniDisabledButtonCssColor,             [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",               miniDisabledButtonCssColor,             [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"nib2cib-adjustment-frame",  CGRectMake(0.0, -0.0, -1.0, -0.0),      [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"content-inset",             CGInsetMake(1.0, 15.0, 1.0, 10.0),      [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],
//     [@"content-inset",             CGInsetMake(-1.0, 15.0, 0, 10.0),       [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"min-size",                  CGSizeMake(32.0, 15.0),                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],

     // Not bordered, IB style "Bevel" (CPRegularSquareBezelStyle)

     // Regular size
     [@"bezel-color",               nbButtonCssColor,                       [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateKeyWindow]],
     [@"bezel-color",               nbButtonCssColor,                       [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare]],
     [@"bezel-color",               nbHighlightedButtonCssColor,            [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateKeyWindow, CPThemeStateHighlighted]],
     [@"bezel-color",               nbDisabledButtonCssColor,               [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateDisabled]],
     [@"bezel-color",               nbDisabledButtonCssColor,               [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"nib2cib-adjustment-frame",  CGRectMake(0.0, 0.0, 0.0, 0.0),         [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare]],
     [@"content-inset",             CGInsetMake(-3.0, 13, 0, 2.0),          [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare]],
     [@"min-size",                  CGSizeMake(32.0, 21.0),                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare]],

     // Small size
     [@"bezel-color",               smallNbButtonCssColor,                  [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall, CPThemeStateKeyWindow]],
     [@"bezel-color",               smallNbButtonCssColor,                  [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall]],
     [@"bezel-color",               smallNbHighlightedButtonCssColor,       [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall, CPThemeStateKeyWindow, CPThemeStateHighlighted]],
     [@"bezel-color",               smallNbDisabledButtonCssColor,          [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
     [@"bezel-color",               smallNbDisabledButtonCssColor,          [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"nib2cib-adjustment-frame",  CGRectMake(0.0, 0.0, 0.0, 0.0),         [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall]],
     [@"content-inset",             CGInsetMake(-3.0, 13, 0, 2.0),          [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall]],
     [@"min-size",                  CGSizeMake(32.0, 18.0),                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall]],

     // Mini size
     [@"bezel-color",               miniNbButtonCssColor,                   [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini, CPThemeStateKeyWindow]],
     [@"bezel-color",               miniNbButtonCssColor,                   [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini]],
     [@"bezel-color",               miniNbHighlightedButtonCssColor,        [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini, CPThemeStateKeyWindow, CPThemeStateHighlighted]],
     [@"bezel-color",               miniNbDisabledButtonCssColor,           [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini, CPThemeStateDisabled]],
     [@"bezel-color",               miniNbDisabledButtonCssColor,           [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"nib2cib-adjustment-frame",  CGRectMake(0.0, 0.0, 0.0, 0.0),         [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini]],
     [@"content-inset",             CGInsetMake(-3.0, 13, 0, 2.0),          [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini]],
     [@"min-size",                  CGSizeMake(32.0, 16.0),                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini]]

     ];

    [self registerThemeValues:themeValues forView:button];

    [button setTitle:@"Pull Down"];
    [button addItemWithTitle:@"item"];

    return button;
}

#pragma mark -

+ (CPScrollView)themedScrollView
{
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)],
        borderColor = /*[CPColor colorWithWhite:0.0 alpha:0.2]*/[CPColor redColor],
//    bottomCornerColor = PatternColor(@"scrollview-bottom-corner-color.png", 15.0, 15.0),

        bottomCornerColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": A3ColorScrollerBackground
                                                              }],
    bezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"background-color": A3ColorBackgroundWhite,
                                                      @"border-color": A3ColorTextfieldActiveBorder,
                                                      @"border-style": @"solid",
                                                      @"border-width": @"1px",
                                                      @"border-radius": @"0px",
                                                      @"box-sizing": @"border-box",
                                                      @"transition-duration": @"0.35s, 0.35s",
                                                      @"transition-property": @"box-shadow, border"
                                                      }],

    bezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"border-color": @"A3ColorBorderBlue",
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"0px",
                                                             @"box-sizing": @"border-box",
                                                             @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
                                                             @"transition-duration": @"0.35s, 0.35s",
                                                             @"transition-property": @"box-shadow, border"
                                                             }],

    themedScrollViewValues =
    [
     // FIXME: ajouter les backgrounds pour no-border, line-border et groove-border
     [@"background-color-no-border",        bezelCssColor],
     [@"background-color-no-border",        bezelFocusedCssColor,       [CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
     [@"background-color-line-border",      bezelCssColor],
     [@"background-color-line-border",      bezelFocusedCssColor,       [CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
     [@"background-color-bezel-border",     bezelCssColor],
     [@"background-color-bezel-border",     bezelFocusedCssColor,       [CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
     [@"background-color-groove-border",    bezelCssColor],
     [@"background-color-groove-border",    bezelFocusedCssColor,       [CPThemeStateFirstResponder, CPThemeStateKeyWindow]],

     [@"content-inset-no-border",       CGInsetMakeZero()],
     [@"content-inset-line-border",     CGInsetMake(0,2,2,0)],
     [@"content-inset-bezel-border",    CGInsetMake(0,2,2,0)],
     [@"content-inset-groove-border",   CGInsetMake(0,2,2,0)],

     [@"bottom-corner-color", bottomCornerColor]
     ];

    [self registerThemeValues:themedScrollViewValues forView:scrollView];

    [scrollView setAutohidesScrollers:YES];
    [scrollView setBorderType:CPLineBorder];

    return scrollView;
}

+ (CPScroller)makeHorizontalScroller
{
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 15.0)];

    [scroller setFloatValue:0.1];
    [scroller setKnobProportion:0.5];

    [scroller setStyle:CPScrollerStyleOverlay];

    return scroller;
}

+ (CPScroller)makeVerticalScroller
{
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 15.0, 200.0)];

    [scroller setFloatValue:1];
    [scroller setKnobProportion:0.1];

    [scroller setStyle:CPScrollerStyleLegacy];

    return scroller;
}

+ (CPScroller)themedVerticalScroller
{
    var scroller = [self makeVerticalScroller],

    knobCssColor = [CPColor colorWithCSSDictionary:@{
                                                     @"background-color": A3ColorScrollerDark,
                                                     @"border-style": @"none",
                                                     @"border-radius": @"4px",
                                                     @"box-sizing": @"border-box"
                                                     }],

    lightKnobCssColor = [CPColor colorWithCSSDictionary:@{
                                                          @"background-color": A3ColorScrollerLight,
                                                          @"border-color": A3ColorInactiveBorder,
                                                          @"border-style": @"solid",
                                                          @"border-width": @"1px",
                                                          @"border-radius": @"4px",
                                                          @"box-sizing": @"border-box"
                                                          }],

    knobCssColorLegacy = [CPColor colorWithCSSDictionary:@{
                                                           @"background-color": A3ColorScrollerLegacy,
                                                           @"border-style": @"none",
                                                           @"border-radius": @"4px",
                                                           @"box-sizing": @"border-box",
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"background-color"
                                                           }],

    knobCssColorLegacyOver = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorScrollerDark,
                                                               @"border-style": @"none",
                                                               @"border-radius": @"4px",
                                                               @"box-sizing": @"border-box",
                                                               @"transition-duration": @"0.35s",
                                                               @"transition-property": @"background-color"
                                                               }],

    trackCssColorLegacy = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": A3ColorScrollerBackground,
                                                            @"border-left-style": @"solid",
                                                            @"border-left-color": A3ColorScrollerBorder,
                                                            @"border-left-width": @"1px"
                                                            }],

    themedVerticalScrollerValues =
    [
     // Common
     [@"minimum-knob-length",    21.0,                               CPThemeStateVertical],

     // Overlay
     [@"scroller-width",         7.0,                                CPThemeStateVertical],
     [@"knob-inset",             CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateVertical],
     [@"track-inset",            CGInsetMake(2.0, 0.0, 2.0, 0.0),    CPThemeStateVertical],
     [@"track-border-overlay",   9.0,                                CPThemeStateVertical],
     [@"knob-slot-color",        [CPNull null],                      CPThemeStateVertical],
     [@"knob-color",             knobCssColor,                       CPThemeStateVertical],
     [@"knob-color",             lightKnobCssColor,                  [CPThemeStateVertical, CPThemeStateScrollerKnobLight]],
     [@"knob-color",             knobCssColor,                       [CPThemeStateVertical, CPThemeStateScrollerKnobDark]],
     [@"decrement-line-size",    CGSizeMakeZero(),                   CPThemeStateVertical],
     [@"increment-line-size",    CGSizeMakeZero(),                   CPThemeStateVertical],

     // Legacy
     [@"scroller-width",         15.0,                               [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
     [@"knob-inset",             CGInsetMake(3.0, 3.0, 3.0, 4.0),    [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
     [@"track-inset",            CGInsetMake(0.0, 0.0, 0.0, 0.0),    [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
     [@"track-border-overlay",   0.0,                                [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
     [@"knob-slot-color",        trackCssColorLegacy,                   [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
     [@"knob-color",             knobCssColorLegacy,                    [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
     [@"knob-color",             knobCssColorLegacyOver,                    [CPThemeStateVertical, CPThemeStateScrollViewLegacy, CPThemeStateSelected]],
     [@"decrement-line-size",    CGSizeMakeZero(),             [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
     [@"increment-line-size",    CGSizeMakeZero(),             [CPThemeStateVertical, CPThemeStateScrollViewLegacy]]
     ];

    [self registerThemeValues:themedVerticalScrollerValues forView:scroller];

    return scroller;
}

+ (CPScroller)themedHorizontalScroller
{
    var scroller = [self makeHorizontalScroller],

    knobCssColor = [CPColor colorWithCSSDictionary:@{
                                                     @"background-color": A3ColorScrollerDark,
                                                     @"border-style": @"none",
                                                     @"border-radius": @"4px",
                                                     @"box-sizing": @"border-box"
                                                     }],

    lightKnobCssColor = [CPColor colorWithCSSDictionary:@{
                                                          @"background-color": A3ColorScrollerLight,
                                                          @"border-color": A3ColorInactiveBorder,
                                                          @"border-style": @"solid",
                                                          @"border-width": @"1px",
                                                          @"border-radius": @"4px",
                                                          @"box-sizing": @"border-box"
                                                          }],

    knobCssColorLegacy = [CPColor colorWithCSSDictionary:@{
                                                           @"background-color": A3ColorScrollerLegacy,
                                                           @"border-style": @"none",
                                                           @"border-radius": @"4px",
                                                           @"box-sizing": @"border-box",
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"background-color"
                                                           }],

    knobCssColorLegacyOver = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorScrollerDark,
                                                               @"border-style": @"none",
                                                               @"border-radius": @"4px",
                                                               @"box-sizing": @"border-box",
                                                               @"transition-duration": @"0.35s",
                                                               @"transition-property": @"background-color"
                                                               }],

    trackCssColorLegacy = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": A3ColorScrollerBackground,
                                                            @"border-top-style": @"solid",
                                                            @"border-top-color": A3ColorScrollerBorder,
                                                            @"border-top-width": @"1px"
                                                            }],

    themedHorizontalScrollerValues =
    [
     // Common
     [@"minimum-knob-length",    21.0],

     // Overlay
     [@"scroller-width",         7.0],
     [@"knob-inset",             CGInsetMake(0.0, 0.0, 0.0, 0.0)],
     [@"track-inset",            CGInsetMake(0.0, 2.0, 0.0, 2.0)],
     [@"track-border-overlay",   9.0],
     [@"knob-slot-color",        [CPNull null]],
     [@"knob-color",             knobCssColor],
     [@"knob-color",             lightKnobCssColor,                       CPThemeStateScrollerKnobLight],
     [@"knob-color",             knobCssColor,                       CPThemeStateScrollerKnobDark],
     [@"decrement-line-size",    CGSizeMakeZero()],
     [@"increment-line-size",    CGSizeMakeZero()],

     // Legacy
     [@"scroller-width",         15.0,                               CPThemeStateScrollViewLegacy],
     [@"knob-inset",             CGInsetMake(4.0, 3.0, 3.0, 3.0),    CPThemeStateScrollViewLegacy],
     [@"track-inset",            CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateScrollViewLegacy],
     [@"track-border-overlay",   0.0,                                CPThemeStateScrollViewLegacy],
     [@"knob-slot-color",        trackCssColorLegacy,                   CPThemeStateScrollViewLegacy],
     [@"knob-color",             knobCssColorLegacy,                    CPThemeStateScrollViewLegacy],
     [@"knob-color",             knobCssColorLegacyOver,                    [CPThemeStateScrollViewLegacy, CPThemeStateSelected]],
     [@"decrement-line-size",    CGSizeMakeZero(),             CPThemeStateScrollViewLegacy],
     [@"increment-line-size",    CGSizeMakeZero(),             CPThemeStateScrollViewLegacy]
     ];

    [self registerThemeValues:themedHorizontalScrollerValues forView:scroller];

    return scroller;
}

#pragma mark -

+ (CPTextField)themedStandardTextField
{
    var textfield = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 22.0)],

    bezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"background-color": A3ColorBackgroundWhite,
                                                      @"border-color": A3ColorTextfieldActiveBorder,
                                                      @"border-style": @"solid",
                                                      @"border-width": @"1px",
                                                      @"border-radius": @"0px",
                                                      @"box-sizing": @"border-box",
                                                      @"transition-duration": @"0.35s, 0.35s",
                                                      @"transition-property": @"box-shadow, border"
                                                      }],

    bezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"border-color": @"A3ColorBorderBlue",
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"0px",
                                                             @"box-sizing": @"border-box",
                                                             @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
                                                             @"transition-duration": @"0.35s, 0.35s",
                                                             @"transition-property": @"box-shadow, border"
                                                             }],

    bezelDisabledCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": A3ColorBackgroundWhite,
                                                              @"border-color": A3ColorTextfieldInactiveBorder,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"0px",
                                                              @"box-sizing": @"border-box",
                                                              @"transition-duration": @"0.35s, 0.35s",
                                                              @"transition-property": @"box-shadow, border"
                                                              }];

    tableCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"border-style": @"none",
                                                      @"box-sizing": @"border-box",
                                                      @"transition-duration": @"0.35s, 0.35s",
                                                      @"transition-property": @"box-shadow, border"
                                                      }],

    tableFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"border-style": @"none",
                                                             @"box-sizing": @"border-box",
                                                             @"transition-duration": @"0.35s, 0.35s",
                                                             @"transition-property": @"box-shadow, border"
                                                             }],

//    tableFocusedCssColor = [CPColor colorWithCSSDictionary:@{
//                                                             @"background-color": A3ColorBackgroundWhite,
//                                                             @"border-color": @"A3ColorBorderBlue",
//                                                             @"border-style": @"solid",
//                                                             @"border-width": @"1px",
//                                                             @"border-radius": @"0px",
//                                                             @"box-sizing": @"border-box",
//                                                             @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
//                                                             @"transition-duration": @"0.35s, 0.35s",
//                                                             @"transition-property": @"box-shadow, border"
//                                                             }],

    unborderedBezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                                @"border-color": A3ColorTransparent,
                                                                @"border-style": @"solid",
                                                                @"border-width": @"0px",
                                                                @"border-radius": @"0px",
                                                                @"box-sizing": @"border-box",
                                                                @"transition-duration": @"0.35s, 0.35s",
                                                                @"transition-property": @"box-shadow, border-color"
                                                                }],

    unborderedBezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"border-color": @"A3ColorBorderBlue",
                                                                       @"border-style": @"solid",
                                                                       @"border-width": @"1px",
                                                                       @"border-radius": @"0px",
                                                                       @"box-sizing": @"border-box",
                                                                       @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
                                                                       @"transition-duration": @"0.35s, 0.35s",
                                                                       @"transition-property": @"box-shadow, border-color"
                                                                       }],

    borderedBezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"border-color": A3ColorNotKeyDarkBorder,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"0px",
                                                              @"box-sizing": @"border-box",
                                                              @"transition-duration": @"0.35s, 0.35s",
                                                              @"transition-property": @"box-shadow, border-color"
                                                              }],

    borderedBezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                                     @"border-color": @"A3ColorBorderBlue",
                                                                     @"border-style": @"solid",
                                                                     @"border-width": @"1px",
                                                                     @"border-radius": @"0px",
                                                                     @"box-sizing": @"border-box",
                                                                     @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
                                                                     @"transition-duration": @"0.35s, 0.35s",
                                                                     @"transition-property": @"box-shadow, border-color"
                                                                     }],

    // Global for reuse by CPTokenField.
    themedTextFieldValues =
    [
     // CPThemeStateControlSizeRegular
     [@"vertical-alignment",    CPTopVerticalTextAlignment,                                 CPThemeStateBezeled],

     [@"bezel-color",           bezelCssColor,                                              CPThemeStateBezeled],
     [@"bezel-color",           bezelFocusedCssColor,                                       [CPThemeStateBezeled, CPThemeStateEditing]],
     [@"bezel-color",           bezelDisabledCssColor,                                      [CPThemeStateBezeled, CPThemeStateDisabled]], // FIXME: here !
     [@"bezel-color",           unborderedBezelCssColor,                                    CPThemeStateNormal],
     [@"bezel-color",           unborderedBezelFocusedCssColor,                             CPThemeStateEditing],
     [@"bezel-color",           borderedBezelCssColor,                                      CPThemeStateBordered],
     [@"bezel-color",           borderedBezelFocusedCssColor,                               [CPThemeStateBordered, CPThemeStateEditing]],

     [@"text-color",            A3CPColorActiveText],
     [@"text-color",            A3CPColorInactiveText,                                      [CPThemeStateBezeled, CPThemeStateDisabled]],
     [@"text-shadow-color",     nil],
     [@"text-shadow-offset",    CGSizeMakeZero()],

     [@"content-inset",      CGInsetMake(1.0, 0.0, 0.0, 0.0)],                           // For labels
     [@"content-inset",      CGInsetMake(0.0, 1.0, 1.0, -1.0),                           CPThemeStateEditing], // For labels
     [@"content-inset",      CGInsetMake(3.0, 5.0, 3.0, 3.0),                            CPThemeStateBezeled], // was 3.0, 5.0, 3.0, 4.0 (2.0, 5.0, 4.0, 4.0)
     [@"content-inset",      CGInsetMake(3.0, 5.0, 3.0, 3.0),                            [CPThemeStateBezeled, CPThemeStateEditing]],
     [@"content-inset",      CGInsetMake(3.0, 5.0, 3.0, 3.0),                            CPThemeStateBordered], // was 3.0, 5.0, 3.0, 4.0 (2.0, 5.0, 4.0, 4.0)
     [@"content-inset",      CGInsetMake(3.0, 5.0, 3.0, 3.0),                            [CPThemeStateBordered, CPThemeStateEditing]],

     [@"bezel-inset",        CGInsetMake(2.0, 5.0, 4.0, 4.0),                            CPThemeStateBezeled],
     [@"bezel-inset",        CGInsetMake(0.0, 1.0, 0.0, 1.0),                            [CPThemeStateBezeled, CPThemeStateEditing]],

     [@"text-color",         A3CPColorInactiveText,                                        CPTextFieldStatePlaceholder],

     [@"background-inset",      CGInsetMake(1.0, 3.0, 3.0, 1.0),                        CPThemeStateBezeled],
     [@"background-inset",      CGInsetMake(0.0, 0.0, 0.0, 0.0),                        CPThemeStateNormal],

     // TableDataView

     [@"line-break-mode",    CPLineBreakByTruncatingTail,                                CPThemeStateTableDataView],
     [@"vertical-alignment", CPCenterVerticalTextAlignment,                              CPThemeStateTableDataView],
     [@"content-inset",      CGInsetMake(0.0, 0.0, 0.0, 5.0),                            CPThemeStateTableDataView],
     [@"content-inset",      CGInsetMake(0.0, 0.0, 0.0, 5.0),                            [CPThemeStateTableDataView, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"content-inset",      CGInsetMake(0.0, 0.0, 0.0, 5.0),                            [CPThemeStateTableDataView, CPThemeStateBezeled]],

     [@"bezel-color",        tableCssColor,                                              CPThemeStateTableDataView],
     [@"bezel-color",        tableFocusedCssColor,                                       [CPThemeStateTableDataView, CPThemeStateEditing]],

     [@"font",               [CPFont systemFontOfSize:CPFontCurrentSystemSize],          CPThemeStateTableDataView],
//     [@"font",               [CPFont systemFontOfSize:CPFontCurrentSystemSize],          [CPThemeStateTableDataView, CPThemeStateSelectedDataView]],
//     [@"font",               [CPFont systemFontOfSize:CPFontCurrentSystemSize],          [CPThemeStateTableDataView, CPThemeStateEditing]],

     [@"text-color",         A3CPColorActiveText,                 CPThemeStateTableDataView], // Normal
     [@"text-color",         A3CPColorActiveText,                  [CPThemeStateTableDataView, CPThemeStateSelectedDataView]], // Row selected but not active
     [@"text-color",         A3CPColorDefaultText,                                       [CPThemeStateTableDataView, CPThemeStateSelectedDataView, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],  // Row selected and active



//     [@"text-color",         [CPColor greenColor]/*A3CPColorActiveText*/,                  [CPThemeStateTableDataView, CPThemeStateSelectedDataView, CPThemeStateFirstResponder, CPThemeStateKeyWindow, CPThemeStateHovered, CPThemeStateControlSizeRegular]],
//     [@"text-color",         [CPColor blueColor]/*A3CPColorActiveText*/,                 [CPThemeStateEditing]],
//     [@"text-color",         [CPColor blueColor]/*A3CPColorActiveText*/,                 [CPThemeStateTableDataView, CPThemeStateEditing]],
// pas utile     [@"text-color",         [CPColor redColor],                                         [CPThemeStateTableDataView, CPThemeStateSelectedDataView, CPThemeStateEditable, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],

     [@"content-inset",      CGInsetMake(0.0, 0.0, 0.0, 0.0),                           [CPThemeStateTableDataView, CPThemeStateEditable]],
// WAS     [@"content-inset",      CGInsetMake(7.0, 7.0, 5.0, 10.0),                           [CPThemeStateTableDataView, CPThemeStateEditable]],
     [@"bezel-inset",        CGInsetMake(0.0, 1.0, 0.0, 5.0),                        [CPThemeStateTableDataView, CPThemeStateEditable, CPThemeStateEditing]],
     [@"bezel-inset",        CGInsetMake(0.0, 1.0, 0.0, 5.0),                            [CPThemeStateTableDataView, CPThemeStateEditable]],
//     [@"bezel-inset",        CGInsetMake(-2.0, -2.0, -2.0, -2.0),                        [CPThemeStateTableDataView, CPThemeStateEditable, CPThemeStateEditing]],
//     [@"bezel-inset",        CGInsetMake(1.0, 1.0, 1.0, 1.0),                            [CPThemeStateTableDataView, CPThemeStateEditable]],

     [@"text-color",         [CPColor colorWithCalibratedWhite:125.0 / 255.0 alpha:1.0], [CPThemeStateTableDataView, CPThemeStateGroupRow]],
     [@"text-color",         [CPColor whiteColor],                                       [CPThemeStateTableDataView, CPThemeStateGroupRow, CPThemeStateSelectedDataView, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
     [@"text-shadow-color",  [CPColor whiteColor],                                       [CPThemeStateTableDataView, CPThemeStateGroupRow]],
     [@"text-shadow-offset", CGSizeMake(0, 1),                                           [CPThemeStateTableDataView, CPThemeStateGroupRow]],
     [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:0.0 alpha:0.6],           [CPThemeStateTableDataView, CPThemeStateGroupRow, CPThemeStateSelectedDataView, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
     [@"font",               [CPFont boldSystemFontOfSize:CPFontCurrentSystemSize],      [CPThemeStateTableDataView, CPThemeStateGroupRow]],

     [@"min-size",                   CGSizeMake(-1.0, 22.0)], // was 29
     [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 0.0, -4.0, 0.0)],      // For labels
     [@"nib2cib-adjustment-frame",   CGRectMake(0.0, 0.0, 0.0, 0.0),                   CPThemeStateBezeled],  // for bordered fields, frame = alignment

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
     [@"nib2cib-adjustment-frame",   CGRectMake(-4.0, 4.0, 8.0, 7.0),                    [CPThemeStateControlSizeMini, CPThemeStateBezeled]]
     ];

    [self registerThemeValues:themedTextFieldValues forView:textfield];

    [textfield setBezeled:YES];

    [textfield setPlaceholderString:"Placeholder"];
    [textfield setStringValue:""];
    [textfield setEditable:YES];

    return textfield;
}

+ (CPTextField)themedRoundedTextField
{
    var textfield = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 22.0)],

    bezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"background-color": A3ColorBackgroundWhite,
                                                      @"border-color": A3ColorTextfieldActiveBorder,
                                                      @"border-style": @"solid",
                                                      @"border-width": @"1px",
                                                      @"border-radius": @"5px",
                                                      @"box-sizing": @"border-box",
                                                      @"transition-duration": @"0.35s, 0.35s",
                                                      @"transition-property": @"box-shadow, border"
                                                      }],

    bezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"border-color": @"A3ColorBorderBlue",
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"5px",
                                                             @"box-sizing": @"border-box",
                                                             @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
                                                             @"transition-duration": @"0.35s, 0.35s",
                                                             @"transition-property": @"box-shadow, border"
                                                             }],

    bezelDisabledCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": A3ColorBackgroundWhite,
                                                              @"border-color": A3ColorTextfieldInactiveBorder,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"5px",
                                                              @"box-sizing": @"border-box",
                                                              @"transition-duration": @"0.35s, 0.35s",
                                                              @"transition-property": @"box-shadow, border"
                                                              }];

    // Global for reuse by CPSearchField
    themedRoundedTextFieldValues =
    [
     [@"vertical-alignment",        CPTopVerticalTextAlignment,     [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-color",               bezelCssColor,                  [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-color",               bezelFocusedCssColor,           [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"bezel-color",               bezelDisabledCssColor,          [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateDisabled]],

//     [@"font",                      [CPFont systemFontOfSize:CPFontCurrentSystemSize],      CPTextFieldStateRounded],
     [@"text-color",                A3CPColorActiveText,                                      CPTextFieldStateRounded],

     [@"content-inset",             CGInsetMake(2.0, 11.0, 4.0, 11.0),                        [CPTextFieldStateRounded, CPThemeStateBezeled]], // was 3.0, 11.0, 3.0, 11.0
     [@"content-inset",             CGInsetMake(2.0, 11.0, 4.0, 11.0),                        [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],

     [@"bezel-inset",               CGInsetMake(2.0, 11.0, 4.0, 11.0),                        [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-inset",               CGInsetMake(0.0, 1.0, 0.0, 1.0),                        [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],

     [@"text-color",                 A3CPColorInactiveText,                                    [CPTextFieldStateRounded, CPTextFieldStatePlaceholder]],
     [@"text-color",                 A3CPColorInactiveText,                                    [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateDisabled]],
//     [@"text-shadow-color",          regularDisabledTextShadowColor,                         [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateDisabled]],

     [@"min-size",                   CGSizeMake(-1.0, 22.0),                                  [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"max-size",                   CGSizeMake(-1.0, 22.0),                                 [CPTextFieldStateRounded, CPThemeStateBezeled]],
//     [@"nib2cib-adjustment-frame",   CGRectMake(-4.0, 7.0, 8.0, 10.0),                       [CPTextFieldStateRounded, CPThemeStateBezeled]],

     // CPThemeStateControlSizeSmall
     [@"content-inset",              CGInsetMake(7.0, 6.0, 4.0, 6.0),                        [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-inset",                CGInsetMake(2.0, 4.0, 2.0, 4.0),                        [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-inset",                CGInsetMake(0.0, 1.0, 0.0, 1.0),                        [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"min-size",                   CGSizeMake(-1.0, 19.0),                                 [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"max-size",                   CGSizeMake(-1.0, 19.0),                                 [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],
//     [@"nib2cib-adjustment-frame",   CGRectMake(-4.0, 7.0, 8.0, 9.0),                        [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],

     // CPThemeStateControlSizeMini
     [@"content-inset",              CGInsetMake(7.0, 6.0, 4.0, 6.0),                        [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-inset",                CGInsetMake(2.0, 4.0, 2.0, 4.0),                        [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-inset",                CGInsetMake(0.0, 1.0, 0.0, 1.0),                        [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"min-size",                   CGSizeMake(-1.0, 17.0),                                 [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"max-size",                   CGSizeMake(-1.0, 17.0),                                 [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],
//     [@"nib2cib-adjustment-frame",   CGRectMake(-4.0, 2.0, 8.0, 4.0),                        [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]]
     ];

    [self registerThemeValues:themedRoundedTextFieldValues forView:textfield];

    [textfield setBezeled:YES];
    [textfield setBezelStyle:CPTextFieldRoundedBezel];

    [textfield setPlaceholderString:"Placeholder"];
    [textfield setStringValue:""];
    [textfield setEditable:YES];

    return textfield;
}

+ (CPSearchField)themedSearchField
{
    var searchField = [[CPSearchField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 22.0)], // small: 19, mini: 17 - cancel/loupe 16/13/11

    // Regular (16x16)
    imageSearch = [CPImage imageWithCSSDictionary:@{
                                                    @"background-image": @"url(%%packed.png)",
                                                    @"background-position": @"-16px -32px",    // -32px -64px
                                                    @"background-repeat": @"no-repeat",
                                                    @"background-size": @"100px 400px"       // 200px 800px
                                                    }
                                             size:CGSizeMake(16,16)],

    imageFind = [CPImage imageWithCSSDictionary:@{
                                                  @"background-image": @"url(%%packed.png)",
                                                  @"background-position": @"-16px -0px",    // -32px -0px
                                                  @"background-repeat": @"no-repeat",
                                                  @"background-size": @"100px 400px"       // 200px 800px
                                                  }
                                           size:CGSizeMake(16,16)],

    imageCancel = [CPImage imageWithCSSDictionary:@{
                                                    @"background-image": @"url(%%packed.png)",
                                                    @"background-position": @"-0px -0px",    // -0px -0px
                                                    @"background-repeat": @"no-repeat",
                                                    @"background-size": @"100px 400px"       // 200px 800px
                                                    }
                                             size:CGSizeMake(16,16)],

    imageSearchLight = [CPImage imageWithCSSDictionary:@{
                                                         @"background-image": @"url(%%packed.png)",
                                                         @"background-position": @"-16px -16px",    // -32px -32px
                                                         @"background-repeat": @"no-repeat",
                                                         @"background-size": @"100px 400px"       // 200px 800px
                                                         }
                                                  size:CGSizeMake(16,16)],

    imageFindLight = [CPImage imageWithCSSDictionary:@{
                                                       @"background-image": @"url(%%packed.png)",
                                                       @"background-position": @"-32px -0px",    // -64px -0px
                                                       @"background-repeat": @"no-repeat",
                                                       @"background-size": @"100px 400px"       // 200px 800px
                                                       }
                                                size:CGSizeMake(16,16)],

    // Small (13x13)
    imageSearchSmall = [CPImage imageWithCSSDictionary:@{
                                                         @"background-image": @"url(%%packed.png)",
                                                         @"background-position": @"-48px -16px",    // -96px -32px
                                                         @"background-repeat": @"no-repeat",
                                                         @"background-size": @"100px 400px"       // 200px 800px
                                                         }
                                                  size:CGSizeMake(13,13)],

    imageFindSmall = [CPImage imageWithCSSDictionary:@{
                                                       @"background-image": @"url(%%packed.png)",
                                                       @"background-position": @"-48px -48px",    // -96px -96px
                                                       @"background-repeat": @"no-repeat",
                                                       @"background-size": @"100px 400px"       // 200px 800px
                                                       }
                                                size:CGSizeMake(13,13)],

    imageCancelSmall = [CPImage imageWithCSSDictionary:@{
                                                         @"background-image": @"url(%%packed.png)",
                                                         @"background-position": @"-48px -0px",    // -96px -0px
                                                         @"background-repeat": @"no-repeat",
                                                         @"background-size": @"100px 400px"       // 200px 800px
                                                         }
                                                  size:CGSizeMake(13,13)],

    imageSearchLightSmall = [CPImage imageWithCSSDictionary:@{
                                                              @"background-image": @"url(%%packed.png)",
                                                              @"background-position": @"-48px -32px",    // -96px -64px
                                                              @"background-repeat": @"no-repeat",
                                                              @"background-size": @"100px 400px"       // 200px 800px
                                                              }
                                                       size:CGSizeMake(13,13)],

    imageFindLightSmall = [CPImage imageWithCSSDictionary:@{
                                                            @"background-image": @"url(%%packed.png)",
                                                            @"background-position": @"-48px -64px",    // -96px -128px
                                                            @"background-repeat": @"no-repeat",
                                                            @"background-size": @"100px 400px"       // 200px 800px
                                                            }
                                                     size:CGSizeMake(13,13)],

    // Mini (11x11)
    imageSearchMini = [CPImage imageWithCSSDictionary:@{
                                                        @"background-image": @"url(%%packed.png)",
                                                        @"background-position": @"-64px -16px",    // -128px -32px
                                                        @"background-repeat": @"no-repeat",
                                                        @"background-size": @"100px 400px"       // 200px 800px
                                                        }
                                                 size:CGSizeMake(11,11)],

    imageFindMini = [CPImage imageWithCSSDictionary:@{
                                                      @"background-image": @"url(%%packed.png)",
                                                      @"background-position": @"-64px -48px",    // -128px -96px
                                                      @"background-repeat": @"no-repeat",
                                                      @"background-size": @"100px 400px"       // 200px 800px
                                                      }
                                               size:CGSizeMake(11,11)],

    imageCancelMini = [CPImage imageWithCSSDictionary:@{
                                                        @"background-image": @"url(%%packed.png)",
                                                        @"background-position": @"-64px -0px",    // -128px -0px
                                                        @"background-repeat": @"no-repeat",
                                                        @"background-size": @"100px 400px"       // 200px 800px
                                                        }
                                                 size:CGSizeMake(11,11)],

    imageSearchLightMini = [CPImage imageWithCSSDictionary:@{
                                                             @"background-image": @"url(%%packed.png)",
                                                             @"background-position": @"-64px -32px",    // -128px -64px
                                                             @"background-repeat": @"no-repeat",
                                                             @"background-size": @"100px 400px"       // 200px 800px
                                                             }
                                                      size:CGSizeMake(11,11)],

    imageFindLightMini = [CPImage imageWithCSSDictionary:@{
                                                           @"background-image": @"url(%%packed.png)",
                                                           @"background-position": @"-64px -64px",    // -128px -128px
                                                           @"background-repeat": @"no-repeat",
                                                           @"background-size": @"100px 400px"       // 200px 800px
                                                           }
                                                    size:CGSizeMake(11,11)],

    calcRectFunctionNotEditing = "" + function(s, rect) {

        var size        = [[s _potentialCurrentValueForThemeAttribute:@"image-search"] size],
            inset       = [s _potentialCurrentValueForThemeAttribute:@"image-search-inset"],
            margin      = [s _potentialCurrentValueForThemeAttribute:@"search-right-margin"],
            value       = [s objectValue],
            placeholder = [s placeholderString],
            hasValue    = ([value length] > 0),
            text        = hasValue ? value : placeholder,
            labelSize   = [text sizeWithFont:[s _potentialCurrentValueForThemeAttribute:@"font"]];

        if (hasValue || (placeholder === @" "))
            return CGRectMake(inset.left - inset.right, inset.top - inset.bottom + (CGRectGetHeight(rect) - size.height) / 2, size.width, size.height);
        else
            return CGRectMake((rect.size.width - labelSize.width) / 2 - size.width - margin, inset.top - inset.bottom + (rect.size.height - size.height) / 2, size.width, size.height);
    },

    calcRectFunctionEditing = "" + function(s, rect) {

        var size = [[s _potentialCurrentValueForThemeAttribute:@"image-search"] size] || CGSizeMakeZero(),
            inset = [s _potentialCurrentValueForThemeAttribute:@"image-search-inset"];

        return CGRectMake(inset.left - inset.right, inset.top - inset.bottom + (CGRectGetHeight(rect) - size.height) / 2, size.width, size.height);
    },

    animateLayoutFunction = "" + function(s) {

        // Search for the CPImageAndTextView subview of mine

        for (var i = 0, subviews = [s subviews], nb = [subviews count], textView = nil; (!textView && (i < nb)); i++)
            if ([subviews[i] isKindOfClass:_CPImageAndTextView])
                textView = subviews[i];

        // Animate change

        [CPAnimationContext beginGrouping];

        var context = [CPAnimationContext currentContext];

        [context setDuration:0.2];
        [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [context setCompletionHandler:function() { [s themedLayoutFunctionCompletionHandler]; }];

        [[[s searchButton] animator] setFrame:[s searchButtonRectForBounds:[s bounds]]];
        [[textView animator]         setFrame:[s contentRectForBounds:[s bounds]]];

        [CPAnimationContext endGrouping];
    },

    overrides =
    [
     // Regular
     [@"image-search-inset",        CGInsetMake(-1, 0, 0, 2)], // was 0, 5, 0, 5
     [@"image-cancel-inset",        CGInsetMake(-1, 5, 0, 0)],
     [@"image-search",              imageSearch],
     [@"image-find",                imageSearch], // In Cocoa, special find image is shown only while editing
     [@"image-search",              imageSearch,                    CPThemeStateEditing],
     [@"image-find",                imageFind,                      CPThemeStateEditing],
     [@"image-search",              imageSearchLight,               CPThemeStateDisabled],
     [@"image-find",                imageSearchLight,               CPThemeStateDisabled],
     [@"image-cancel",              imageCancel],
     [@"image-cancel-pressed",      imageCancel], // In Cocoa, there's no pressed visual state
     [@"search-right-margin",       4],
     [@"vertical-alignment",        CPCenterVerticalTextAlignment],

     // Small
     [@"image-search-inset",        CGInsetMake(-1, -1, 0, 2),      CPThemeStateControlSizeSmall], // was 0, 5, 0, 5
     [@"image-cancel-inset",        CGInsetMake(-1, 5, 0, -1),      CPThemeStateControlSizeSmall],
     [@"image-search",              imageSearchSmall,               CPThemeStateControlSizeSmall],
     [@"image-find",                imageSearchSmall,               CPThemeStateControlSizeSmall], // In Cocoa, special find image is shown only while editing
     [@"image-search",              imageSearchSmall,               [CPThemeStateControlSizeSmall, CPThemeStateEditing]],
     [@"image-find",                imageFindSmall,                 [CPThemeStateControlSizeSmall, CPThemeStateEditing]],
     [@"image-search",              imageSearchLightSmall,          [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
     [@"image-find",                imageSearchLightSmall,          [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
     [@"image-cancel",              imageCancelSmall,               CPThemeStateControlSizeSmall],
     [@"image-cancel-pressed",      imageCancelSmall,               CPThemeStateControlSizeSmall], // In Cocoa, there's no pressed visual state
     [@"search-right-margin",       6,                              CPThemeStateControlSizeSmall],

     // Mini
     [@"image-search-inset",        CGInsetMake(-1, -2, 0, 2),      CPThemeStateControlSizeMini], // was 0, 5, 0, 5
     [@"image-cancel-inset",        CGInsetMake(-1, 5, 0, -2),      CPThemeStateControlSizeMini],
     [@"image-search",              imageSearchMini,                CPThemeStateControlSizeMini],
     [@"image-find",                imageSearchMini,                CPThemeStateControlSizeMini], // In Cocoa, special find image is shown only while editing
     [@"image-search",              imageSearchMini,                [CPThemeStateControlSizeMini, CPThemeStateEditing]],
     [@"image-find",                imageFindMini,                  [CPThemeStateControlSizeMini, CPThemeStateEditing]],
     [@"image-search",              imageSearchLightMini,           [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
     [@"image-find",                imageSearchLightMini,           [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
     [@"image-cancel",              imageCancelMini,                CPThemeStateControlSizeMini],
     [@"image-cancel-pressed",      imageCancelMini,                CPThemeStateControlSizeMini], // In Cocoa, there's no pressed visual state
     [@"search-right-margin",       8,                              CPThemeStateControlSizeMini],

     // FIXME: utile ?
     // Overide
     [@"content-inset",             CGInsetMake(2, 11, 4, 11),      [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"content-inset",             CGInsetMake(2, 11, 4, 11),      [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"bezel-inset",               CGInsetMake(2, 11, 4, 11),      [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"min-size",                  CGSizeMake(0, 22.0),            [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"max-size",                  CGSizeMake(-1, 22.0),           [CPTextFieldStateRounded, CPThemeStateBezeled]],

     [@"content-inset",             CGInsetMake(2, 11, 4, 11),      [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"content-inset",             CGInsetMake(2, 11, 4, 11),      [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"min-size",                  CGSizeMake(0, 19.0),            [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"max-size",                  CGSizeMake(-1, 19.0),           [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],

     [@"content-inset",             CGInsetMake(-1, 11, 1, 11),     [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"content-inset",             CGInsetMake(-1, 11, 1, 11),     [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"min-size",                  CGSizeMake(0, 17.0),            [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"max-size",                  CGSizeMake(-1, 17.0),           [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],

     // Animation
     [@"search-button-rect-function",  calcRectFunctionNotEditing,  [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"search-button-rect-function",  calcRectFunctionEditing,     [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"layout-function",              animateLayoutFunction],

     // Menu
     [@"search-menu-offset",        CGPointMake(1, 0)]
     ];

    [self registerThemeValues:overrides forView:searchField inherit:themedRoundedTextFieldValues];

    return searchField;
}

#pragma mark -
#pragma mark Date Pickers

+ (CPDatePicker)themedDatePicker
{
    var datePicker = [[CPDatePicker alloc] initWithFrame:CGRectMake(40.0, 40.0, 170.0, 29.0)],

    bezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"border-color": A3ColorTextfieldActiveBorder,
                                                      @"border-style": @"solid",
                                                      @"border-width": @"1px",
                                                      @"border-radius": @"0px",
                                                      @"box-sizing": @"border-box",
                                                      @"transition-duration": @"0.35s, 0.35s",
                                                      @"transition-property": @"box-shadow, border"
                                                      }],

    bezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"border-color": @"A3ColorBorderBlue",
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"0px",
                                                             @"box-sizing": @"border-box",
                                                             @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
                                                             @"transition-duration": @"0.35s, 0.35s",
                                                             @"transition-property": @"box-shadow, border"
                                                             }],

    bezelDisabledCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"border-color": A3ColorTextfieldInactiveBorder,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"0px",
                                                              @"box-sizing": @"border-box",
                                                              @"transition-duration": @"0.35s, 0.35s",
                                                              @"transition-property": @"box-shadow, border"
                                                              }];

    themeValues =
    [
     [@"bezel-color",                   bezelCssColor,                              [CPThemeStateBezeled, CPThemeStateBordered]],
     [@"bezel-color",                   bezelFocusedCssColor,                       [CPThemeStateBezeled, CPThemeStateBordered, CPThemeStateEditing, CPThemeStateKeyWindow]],
     [@"bezel-color",                   bezelDisabledCssColor,                      [CPThemeStateBezeled, CPThemeStateBordered, CPThemeStateDisabled]],

     [@"uses-focus-ring",               YES],

     [@"text-color",                    A3CPColorActiveText],
     [@"text-color",                    A3CPColorInactiveText,                      [CPThemeStateBezeled, CPThemeStateDisabled]],

     // REMARK: We use a special theme state (CPThemeStateComposedControl) if there is a stepper
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            CPThemeStateNormal],
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            CPThemeStateComposedControl],
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            [CPThemeStateComposedControl, CPThemeStateEditing]],

     [@"bezel-inset",                   CGInsetMakeZero()],

     [@"separator-content-inset",       CGInsetMake(0.0, -3.0, 0.0, -1.0)],
     [@"time-separator-content-inset",  CGInsetMake(0.0, -3.0, 0.0, 0.0)],

     [@"date-hour-margin",              3.0],
     [@"hour-ampm-margin",              3.0],
     [@"stepper-margin",                3.0],
     [@"stepper-margin",                3.0,                                        CPThemeStateEditing],

     // min/max size is different for textfield+stepper (CPThemeStateComposedControl) and no stepper (CPThemeStateNormal)
     [@"min-size",                      CGSizeMake(0, 23.0),                        CPThemeStateComposedControl],
     [@"max-size",                      CGSizeMake(-1.0, 23.0),                     CPThemeStateComposedControl],

     [@"min-size",                      CGSizeMake(0, 22.0),                        CPThemeStateNormal],
     [@"max-size",                      CGSizeMake(-1.0, 22.0),                     CPThemeStateNormal],

     // nib2cib-adjustment-frame is different for textfield+stepper (CPThemeStateComposedControl) and no stepper (CPThemeStateNormal)
//     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -4.0, -3.0, -4.0),          CPThemeStateComposedControl],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, -3.0, 0.0),             CPThemeStateComposedControl],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, 0.0, 0.0),             CPThemeStateNormal],

     // CPThemeStateControlSizeSmall
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            CPThemeStateControlSizeSmall],
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            [CPThemeStateControlSizeSmall, CPThemeStateComposedControl]],
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            [CPThemeStateControlSizeSmall, CPThemeStateComposedControl, CPThemeStateEditing]],

     [@"date-hour-margin",              5.0,                                        CPThemeStateControlSizeSmall],
     [@"hour-ampm-margin",              2.0,                                        CPThemeStateControlSizeSmall],
     [@"stepper-margin",                2.0,                                        CPThemeStateControlSizeSmall],
     [@"stepper-margin",                2.0,                                        [CPThemeStateControlSizeSmall, CPThemeStateEditing]],

     // min/max size is different for textfield+stepper (CPThemeStateComposedControl) and no stepper (CPThemeStateNormal)
     [@"min-size",                      CGSizeMake(0, 20.0),                        [CPThemeStateControlSizeSmall, CPThemeStateComposedControl]],
     [@"max-size",                      CGSizeMake(-1.0, 20.0),                     [CPThemeStateControlSizeSmall, CPThemeStateComposedControl]],

     [@"min-size",                      CGSizeMake(0, 19.0),                        CPThemeStateControlSizeSmall],
     [@"max-size",                      CGSizeMake(-1.0, 19.0),                     CPThemeStateControlSizeSmall],

     // nib2cib-adjustment-frame is different for textfield+stepper (CPThemeStateComposedControl) and no stepper (CPThemeStateNormal)
//     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, -2.0, -2.0),          [CPThemeStateControlSizeSmall, CPThemeStateComposedControl]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, -2.0, 0.0),            [CPThemeStateControlSizeSmall, CPThemeStateComposedControl]],
//     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 1.0, 2.0, 0.0),             CPThemeStateControlSizeSmall],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, 0.0, 0.0),             CPThemeStateControlSizeSmall],

     // CPThemeStateControlSizeMini
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            CPThemeStateControlSizeMini],
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            [CPThemeStateControlSizeMini, CPThemeStateComposedControl]],
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            [CPThemeStateControlSizeMini, CPThemeStateComposedControl, CPThemeStateEditing]],

     [@"date-hour-margin",              0.0,                                        CPThemeStateControlSizeMini],
     [@"hour-ampm-margin",              1.0,                                        CPThemeStateControlSizeMini],
     [@"stepper-margin",                2.0,                                        CPThemeStateControlSizeMini],
     [@"stepper-margin",                2.0,                                        [CPThemeStateControlSizeMini, CPThemeStateEditing]],

     // min/max size is different for textfield+stepper (CPThemeStateComposedControl) and no stepper (CPThemeStateNormal)
     [@"min-size",                      CGSizeMake(0, 17.0),                        [CPThemeStateControlSizeMini, CPThemeStateComposedControl]],
     [@"max-size",                      CGSizeMake(-1.0, 17.0),                     [CPThemeStateControlSizeMini, CPThemeStateComposedControl]],

     [@"min-size",                      CGSizeMake(0, 17.0),                        CPThemeStateControlSizeMini],
     [@"max-size",                      CGSizeMake(-1.0, 17.0),                     CPThemeStateControlSizeMini],

     // nib2cib-adjustment-frame is different for textfield+stepper (CPThemeStateComposedControl) and no stepper (CPThemeStateNormal)
//     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, -2.0, 0.0),            [CPThemeStateControlSizeMini, CPThemeStateComposedControl]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, -2.0, 0.0),            [CPThemeStateControlSizeMini, CPThemeStateComposedControl]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, 0.0, 0.0),             CPThemeStateControlSizeMini]
//     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, 2.0, 0.0),             CPThemeStateControlSizeMini]
     ];

    [datePicker setDatePickerStyle:CPTextFieldDatePickerStyle];
    [self registerThemeValues:themeValues forView:datePicker];

    return datePicker;
}

+ (CPDatePicker)themedDatePickerCalendar
{
    var datePicker = [[CPDatePicker alloc] initWithFrame:CGRectMake(40.0, 140.0, 276.0 ,148.0)],

    arrowImageLeft = [CPImage imageWithCSSDictionary:@{}
                                    beforeDictionary:@{}
                                     afterDictionary:@{
                                                       @"width": @"0px",
                                                       @"height": @"0px",
                                                       @"border-top": @"4px solid transparent",
                                                       @"border-right": @"6px solid " + A3ColorCalendarButtons,
                                                       @"border-bottom": @"4px solid transparent",
                                                       @"content": @"''",
                                                       @"position": @"absolute",
                                                       @"z-index": @"300",
                                                       @"top": @"0px",
                                                       @"left": @"0px"
                                                       }
                                                size:CGSizeMake(6, 8)],

    arrowImageRight = [CPImage imageWithCSSDictionary:@{}
                                     beforeDictionary:@{}
                                      afterDictionary:@{
                                                        @"width": @"0px",
                                                        @"height": @"0px",
                                                        @"border-top": @"4px solid transparent",
                                                        @"border-left": @"6px solid " + A3ColorCalendarButtons,
                                                        @"border-bottom": @"4px solid transparent",
                                                        @"content": @"''",
                                                        @"position": @"absolute",
                                                        @"z-index": @"300",
                                                        @"top": @"0px",
                                                        @"left": @"0px"
                                                        }
                                                 size:CGSizeMake(6, 8)],

    circleImage = [CPImage imageWithCSSDictionary:@{
                                                    @"background": A3ColorCalendarButtons,
                                                    @"border-radius": @"50%"
                                                    }
                                             size:CGSizeMake(8, 8)],

    arrowImageLeftHighlighted = [CPImage imageWithCSSDictionary:@{}
                                               beforeDictionary:@{}
                                                afterDictionary:@{
                                                                  @"width": @"0px",
                                                                  @"height": @"0px",
                                                                  @"border-top": @"4px solid transparent",
                                                                  @"border-right": @"6px solid " + A3ColorCalendarHighlightedButtons,
                                                                  @"border-bottom": @"4px solid transparent",
                                                                  @"content": @"''",
                                                                  @"position": @"absolute",
                                                                  @"z-index": @"300",
                                                                  @"top": @"0px",
                                                                  @"left": @"0px"
                                                                  }
                                                           size:CGSizeMake(6, 8)],

    arrowImageRightHighlighted = [CPImage imageWithCSSDictionary:@{}
                                                beforeDictionary:@{}
                                                 afterDictionary:@{
                                                                   @"width": @"0px",
                                                                   @"height": @"0px",
                                                                   @"border-top": @"4px solid transparent",
                                                                   @"border-left": @"6px solid " + A3ColorCalendarHighlightedButtons,
                                                                   @"border-bottom": @"4px solid transparent",
                                                                   @"content": @"''",
                                                                   @"position": @"absolute",
                                                                   @"z-index": @"300",
                                                                   @"top": @"0px",
                                                                   @"left": @"0px"
                                                                   }
                                                            size:CGSizeMake(6, 8)],

    circleImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                               @"background": A3ColorCalendarHighlightedButtons,
                                                               @"border-radius": @"50%"
                                                               }
                                                        size:CGSizeMake(8, 8)],

    secondHandSize = CGSizeMake(4.0, 84.0),
    secondHandImage = PatternImage("datepicker-clock-second-hand.png", secondHandSize.width, secondHandSize.height),

    minuteHandSize = CGSizeMake(4.0, 84.0),
    minuteHandImage = PatternImage("datepicker-clock-minute-hand.png", minuteHandSize.width, minuteHandSize.height),

    hourHandSize = CGSizeMake(4.0, 50.0),
    hourHandImage   = PatternImage("datepicker-clock-hour-hand.png", hourHandSize.width, hourHandSize.height),

    middleHandSize = CGSizeMake(8.0, 8.0),
    middleHandImage = PatternImage("datepicker-clock-middle-hand.png", middleHandSize.width, middleHandSize.height),

    clockSize = CGSizeMake(120, 120),
    clockImageColor = [CPColor colorWithCSSDictionary:@{
                                                        @"background": @"rgb(255,255,255)",
                                                        @"border-radius": @"50%",
                                                        @"border-color": @"rgba(0,0,0,0)",
                                                        @"border-style": @"solid",
                                                        @"border-width": @"1px",
                                                        @"box-sizing": @"border-box"
                                                        }],

    borderedClockImageColor = [CPColor colorWithCSSDictionary:@{
                                                                @"background": @"rgb(255,255,255)",
                                                                @"border-radius": @"50%",
                                                                @"border-color": A3ColorActiveBorder,
                                                                @"border-style": @"solid",
                                                                @"border-width": @"1px",
                                                                @"box-sizing": @"border-box"
                                                                }],

    disabledClockImageColor = [CPColor colorWithCSSDictionary:@{
                                                                @"background": A3ColorBackgroundInactive,
                                                                @"border-radius": @"50%",
                                                                @"border-color": @"rgba(0,0,0,0)",
                                                                @"border-style": @"solid",
                                                                @"border-width": @"1px",
                                                                @"box-sizing": @"border-box"
                                                                }],

    disabledBorderedClockImageColor = [CPColor colorWithCSSDictionary:@{
                                                                        @"background": A3ColorBackgroundInactive,
                                                                        @"border-radius": @"50%",
                                                                        @"border-color": A3ColorInactiveBorder,
                                                                        @"border-style": @"solid",
                                                                        @"border-width": @"1px",
                                                                        @"box-sizing": @"border-box"
                                                                        }],

    secondHandImageDisabled = PatternImage("datepicker-clock-second-hand-disabled.png", secondHandSize.width, secondHandSize.height),
    minuteHandImageDisabled = PatternImage("datepicker-clock-minute-hand-disabled.png", minuteHandSize.width, minuteHandSize.height),
    hourHandImageDisabled   = PatternImage("datepicker-clock-hour-hand-disabled.png", hourHandSize.width, hourHandSize.height),
    middleHandImageDisabled = PatternImage("datepicker-clock-middle-hand-disabled.png", middleHandSize.width, middleHandSize.height),

    unborderedBezelColor = [CPColor colorWithCSSDictionary:@{}],

    borderedBezelColor = [CPColor colorWithCSSDictionary:@{
                                                           @"border-color": A3ColorCalendarDark,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"box-sizing": @"border-box"
                                                           }],

    disabledBorderedBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                   @"border-color": A3ColorInactiveBorder,
                                                                   @"border-style": @"solid",
                                                                   @"border-width": @"1px",
                                                                   @"box-sizing": @"border-box"
                                                                   }],

    tileBezelColor = [CPColor colorWithCSSDictionary:@{}],

    selectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorCalendarActive,
                                                               @"border-radius": @"3px"
                                                               }],

    leftSelectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                   @"background-color": A3ColorCalendarActive,
                                                                   @"border-top-left-radius": @"3px",
                                                                   @"border-bottom-left-radius": @"3px",
                                                                   @"box-sizing": @"border-box"
                                                                   }],

    middleSelectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                     @"background-color": A3ColorCalendarActive
                                                                     }],

    rightSelectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorCalendarActive,
                                                                    @"border-top-right-radius": @"3px",
                                                                    @"border-bottom-right-radius": @"3px"
                                                                    }],

    disabledSelectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"background-color": A3ColorCalendarActiveNotKey,
                                                                       @"border-radius": @"3px"
                                                                       }],

    disabledLeftSelectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                           @"background-color": A3ColorCalendarActiveNotKey,
                                                                           @"border-top-left-radius": @"3px",
                                                                           @"border-bottom-left-radius": @"3px",
                                                                           @"box-sizing": @"border-box"
                                                                           }],

    disabledMiddleSelectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                             @"background-color": A3ColorCalendarActiveNotKey
                                                                             }],

    disabledRightSelectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                            @"background-color": A3ColorCalendarActiveNotKey,
                                                                            @"border-top-right-radius": @"3px",
                                                                            @"border-bottom-right-radius": @"3px"
                                                                            }],

    themeValues =
    [
     [@"bezel-color",                   unborderedBezelColor,                                   CPThemeStateAlternateState],
     [@"bezel-color",                   borderedBezelColor,                                     [CPThemeStateAlternateState, CPThemeStateBordered]],
     [@"bezel-color",                   unborderedBezelColor,                                   [CPThemeStateAlternateState, CPThemeStateDisabled]],
     [@"bezel-color",                   disabledBorderedBezelColor,                             [CPThemeStateAlternateState, CPThemeStateBordered, CPThemeStateDisabled]],

     [@"uses-focus-ring",               NO,                                                     CPThemeStateAlternateState],

     [@"separator-color",               A3CPColorCalendarDark],
     [@"separator-margin-width",        3],
     [@"separator-height",              1],

     [@"bezel-color-calendar",          tileBezelColor],
     [@"bezel-color-calendar",          disabledSelectedTileBezelColor,                         CPThemeStateSelected],
     [@"bezel-color-calendar-left",     disabledLeftSelectedTileBezelColor,                     CPThemeStateSelected],
     [@"bezel-color-calendar-middle",   disabledMiddleSelectedTileBezelColor,                   CPThemeStateSelected],
     [@"bezel-color-calendar-right",    disabledRightSelectedTileBezelColor,                    CPThemeStateSelected],
     [@"bezel-color-calendar",          selectedTileBezelColor,                                 [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"bezel-color-calendar-left",     leftSelectedTileBezelColor,                             [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"bezel-color-calendar-middle",   middleSelectedTileBezelColor,                           [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"bezel-color-calendar-right",    rightSelectedTileBezelColor,                            [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"bezel-color-calendar",          disabledSelectedTileBezelColor,                         [CPThemeStateSelected, CPThemeStateDisabled]],
     [@"bezel-color-calendar-left",     disabledLeftSelectedTileBezelColor,                     [CPThemeStateSelected, CPThemeStateDisabled]],
     [@"bezel-color-calendar-middle",   disabledMiddleSelectedTileBezelColor,                   [CPThemeStateSelected, CPThemeStateDisabled]],
     [@"bezel-color-calendar-right",    disabledRightSelectedTileBezelColor,                    [CPThemeStateSelected, CPThemeStateDisabled]],

     [@"bezel-color-clock",             clockImageColor,                                        CPThemeStateAlternateState],
     [@"bezel-color-clock",             borderedClockImageColor,                                [CPThemeStateAlternateState, CPThemeStateBordered]],
     [@"bezel-color-clock",             disabledClockImageColor,                                [CPThemeStateAlternateState, CPThemeStateDisabled]],
     [@"bezel-color-clock",             disabledBorderedClockImageColor,                        [CPThemeStateAlternateState, CPThemeStateDisabled, CPThemeStateBordered]],

     [@"title-text-color",           A3CPColorCalendarTitle],
     [@"title-font",                 [CPFont boldSystemFontOfSize:12.0]],

     [@"title-text-color",           [CPColor colorWithCalibratedRed:79.0 / 255.0 green:79.0 / 255.0 blue:79.0 / 255.0 alpha:0.5],       CPThemeStateDisabled],
     [@"title-font",                 [CPFont boldSystemFontOfSize:12.0],                                                                 CPThemeStateDisabled],

     [@"weekday-text-color",         A3CPColorCalendarDark],
     [@"weekday-font",               [CPFont boldSystemFontOfSize:11.0]],

     [@"clock-text-color",           [CPColor colorWithCalibratedRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:1.0]],
     [@"clock-font",                 [CPFont systemFontOfSize:11.0]],

     [@"clock-text-color",           [CPColor colorWithCalibratedRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:0.5],    CPThemeStateDisabled],
     [@"clock-font",                 [CPFont systemFontOfSize:11.0],                                                                     CPThemeStateDisabled],

     [@"clock-second-hand-over",            YES],
     [@"clock-draws-hours",                 YES],
     [@"clock-hours-font",                  [CPFont systemFontOfSize:11.0]],
     [@"clock-hours-font",                  [CPFont systemFontOfSize:11.0],                         CPThemeStateDisabled],
     [@"clock-hours-text-color",            A3CPColorActiveText],
     [@"clock-hours-text-color",            A3CPColorInactiveText,                                  CPThemeStateDisabled],
     [@"clock-hours-radius",                50],

     [@"arrow-image-left",                  arrowImageLeft],
     [@"arrow-image-right",                 arrowImageRight],
     [@"arrow-image-left-highlighted",      arrowImageLeftHighlighted],
     [@"arrow-image-right-highlighted",     arrowImageRightHighlighted],
     [@"circle-image",                      circleImage],
     [@"circle-image-highlighted",          circleImageHighlighted],
     [@"arrow-inset",                       CGInsetMake(7.0, 5.0, 0.0, 3.0)],
     [@"previous-button-size",              CGSizeMake(6, 8)],
     [@"current-button-size",               CGSizeMake(6, 6)],
     [@"next-button-size",                  CGSizeMake(6, 8)],

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

     [@"border-width",            0.0], // 1
     [@"size-header",             CGSizeMake(138.0, 37.0)], // 141,39
     [@"size-tile",               CGSizeMake(18.57, 16.0)], // 20,18
     [@"tile-margin",               CGSizeMake(0, 1)],
     [@"size-clock",              clockSize],
     [@"size-calendar",           CGSizeMake(138.0, 111.0)],
     [@"calendar-clock-margin",     18],
     [@"min-size-calendar",       CGSizeMake(138.0, 148.0)],
     [@"max-size-calendar",       CGSizeMake(138.0, 148.0)],
     [@"title-inset",               CGInsetMake(2, 0, 0, 3)],
     [@"day-label-inset",           CGInsetMake(22, 0, 0, 4)],
     [@"tile-inset",                CGInsetMake(1, 0, 0, 4)],

     [@"nib2cib-adjustment-frame",              CGRectMake(0.0, 0.0, 0.0, 0.0),        CPThemeStateAlternateState],
     [@"clock-only-nib2cib-adjustment-frame",   CGRectMake(1.0, -2.0, -2.0, -3.0)]
     ];

    [datePicker setDatePickerStyle:CPClockAndCalendarDatePickerStyle];
    [datePicker setBackgroundColor:[CPColor whiteColor]];
    [self registerThemeValues:themeValues forView:datePicker];

    return datePicker;
}

+ (_CPDatePickerDayViewTextField)themedDatePickerDayViewTextField
{
    var textField = [[_CPDatePickerDayViewTextField alloc] initWithFrame:CGRectMakeZero()],

    themeValues =
    [
     // CPThemeStateDisabled    = out of range tiles
     // CPThemeStateHighlighted = current day
     // CPThemeStateSelected    = selection
     [@"text-color",            A3CPColorCalendarTile],
     [@"text-color",            A3CPColorCalendarTile,              CPThemeStateHighlighted],
     [@"text-color",            A3CPColorCalendarCurrentDayTile,    [CPThemeStateHighlighted, CPThemeStateKeyWindow]],
     [@"text-color",            A3CPColorCalendarOutOfRangeTile,    CPThemeStateDisabled],
     [@"text-color",            A3CPColorCalendarOutOfRangeTile,    [CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"text-color",            A3CPColorCalendarTile,              CPThemeStateSelected],
     [@"text-color",            A3CPColorCalendarSelectedTile,      [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"text-color",            A3CPColorCalendarTile,              [CPThemeStateSelected, CPThemeStateDisabled]],
     [@"text-color",            A3CPColorCalendarTile,              [CPThemeStateSelected, CPThemeStateDisabled, CPThemeStateKeyWindow]],

     [@"font",                  [CPFont systemFontOfSize:10.0]],
     [@"font",                  [CPFont boldSystemFontOfSize:10.0], CPThemeStateHighlighted],

     [@"alignment",             CPRightTextAlignment],
     [@"content-inset",         CGInsetMake(0, 2, 0, 0)],
    ];

    [self registerThemeValues:themeValues forView:textField];

    return textField;
}

+ (_CPDatePickerElementTextField)themedDatePickerElementTextField
{
    var textField = [[_CPDatePickerElementTextField alloc] initWithFrame:CGRectMakeZero()],

    bezelColorDatePickerTextField = [CPColor colorWithCSSDictionary:@{
                                                                      @"background-color": [[CPColor clearColor] cssString],
                                                                      @"border-style": @"solid",
                                                                      @"border-width": @"0px",
                                                                      @"border-radius": @"3px",
                                                                      @"box-sizing": @"border-box"
                                                                      }],

    selectedBezelColorDatePickerTextField = [CPColor colorWithCSSDictionary:@{
                                                                              @"background-color": [[CPColor selectedTextBackgroundColor] cssString],
                                                                              @"border-style": @"solid",
                                                                              @"border-width": @"0px",
                                                                              @"border-radius": @"3px",
                                                                              @"box-sizing": @"border-box"
                                                                              }],

    themeValues =
    [
     [@"content-inset",     CGInsetMake(2.0, 1.0, 0.0, -1.0)],
     [@"content-inset",     CGInsetMake(1.0, 1.0, 0.0, -1.0),                           CPThemeStateControlSizeSmall],
     [@"content-inset",     CGInsetMake(1.0, 1.0, 0.0, -1.0),                           CPThemeStateControlSizeMini],
     [@"bezel-color",       bezelColorDatePickerTextField],
     [@"bezel-color",       selectedBezelColorDatePickerTextField,                      [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"min-size",          CGSizeMake(6.0, -1)],
     [@"font",              [CPFont systemFontForControlSize:CPRegularControlSize]],
     [@"font",              [CPFont systemFontForControlSize:CPSmallControlSize],       CPThemeStateControlSizeSmall],
     [@"font",              [CPFont systemFontForControlSize:CPMiniControlSize],        CPThemeStateControlSizeMini],
     [@"text-color",        A3CPColorActiveText],
     [@"text-color",        A3CPColorInactiveText,                                      CPThemeStateDisabled]
     ];

    [self registerThemeValues:themeValues forView:textField];

    return textField;
}

+ (_CPDatePickerElementSeparator)themedDatePickerElementSeparator
{
    var textField = [[_CPDatePickerElementSeparator alloc] initWithFrame:CGRectMakeZero()],

    themeValues =
    [
     [@"content-inset",     CGInsetMake(2.0, 1.0, 0.0, -1.0)],
     [@"content-inset",     CGInsetMake(1.0, 1.0, 0.0, -1.0),                           CPThemeStateControlSizeSmall],
     [@"content-inset",     CGInsetMake(1.0, 1.0, 0.0, -1.0),                           CPThemeStateControlSizeMini],
     [@"min-size",          CGSizeMake(6.0, -1)],
     [@"font",              [CPFont systemFontForControlSize:CPRegularControlSize]],
     [@"font",              [CPFont systemFontForControlSize:CPSmallControlSize],       CPThemeStateControlSizeSmall],
     [@"font",              [CPFont systemFontForControlSize:CPMiniControlSize],        CPThemeStateControlSizeMini],
     [@"text-color",        A3CPColorActiveText],
     [@"text-color",        A3CPColorInactiveText,                                      CPThemeStateDisabled]
     ];

    [self registerThemeValues:themeValues forView:textField];

    return textField;
}

#pragma mark -

+ (CPTokenField)themedTokenField
{
    var tokenfield = [[CPTokenField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 22.0)],

    overrides =
    [
     [@"bezel-inset", CGInsetMakeZero()],
     [@"bezel-inset", CGInsetMake(2.0, 5.0, 4.0, 4.0),    CPThemeStateBezeled],
     [@"bezel-inset", CGInsetMake(0.0, 1.0, 0.0, 1.0),    [CPThemeStateBezeled, CPThemeStateEditing]],

     [@"editor-inset", CGInsetMake(0.0, 0.0, 0.0, 0.0)], // FIXME: ???  was 3

     // Non-bezeled token field with tokens
     [@"content-inset", CGInsetMake(6.0, 8.0, 4.0, 8.0)], // FIXME: ???

     // Non-bezeled token field with no tokens
     [@"content-inset", CGInsetMake(7.0, 8.0, 6.0, 8.0), CPTextFieldStatePlaceholder], // FIXME: ???

     // Bezeled token field with tokens
     [@"content-inset", CGInsetMake(3.0, 5.0, 3.0, 3.0), CPThemeStateBezeled], //(2.0, 5.0, 4.0, 4.0)

     // Bezeled token field with no tokens
     [@"content-inset", CGInsetMake(3.0, 5.0, 3.0, 3.0), [CPThemeStateBezeled, CPTextFieldStatePlaceholder]] // (2.0, 5.0, 4.0, 4.0)
     ];

    [self registerThemeValues:overrides forView:tokenfield inherit:themedTextFieldValues];

    return tokenfield;
}

+ (_CPTokenFieldToken)themedTokenFieldToken
{
    var token = [[_CPTokenFieldToken alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 19.0)],

    bezelColorHighlighted = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": @"A3ColorBorderBlue",
                                                              @"border-color": @"A3ColorBorderBlue",
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"3px",
                                                              @"box-sizing": @"border-box"
                                                              }],

    bezelColor = [CPColor colorWithCSSDictionary:@{
                                                   @"background-color": A3ColorBorderBlueLight,
                                                   @"border-color": A3ColorBorderBlueLight,
                                                   @"border-style": @"solid",
                                                   @"border-width": @"1px",
                                                   @"border-radius": @"3px",
                                                   @"box-sizing": @"border-box"
                                                   }],

    themeValues =
    [
     [@"bezel-color",    bezelColor,                    CPThemeStateBezeled],
     [@"bezel-color",    bezelColorHighlighted,          [CPThemeStateBezeled, CPThemeStateHighlighted]],
     [@"bezel-color",    bezelColor,             [CPThemeStateBezeled, CPThemeStateDisabled]], // FIXME: prévoir un disabled

     [@"text-color",     A3CPColorActiveText],
     [@"text-color",     A3CPColorDefaultText,               CPThemeStateHighlighted],
     [@"text-color",     A3CPColorInactiveText,                  CPThemeStateDisabled],

     [@"bezel-inset",    CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateBezeled],
     [@"content-inset",  CGInsetMake(0.0, 16.0, 0.0, 16.0),  CPThemeStateBezeled], // (-1.0, 16.0, 1.0, 16.0)

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
                                          rightWidth: 21.0,
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

     [@"bezel-inset",        CGInsetMake(1.0, 2.0, 1.0, 2.0),            [CPThemeStateBezeled, CPThemeStateEditing, CPComboBoxStateButtonBordered, CPThemeStateControlSizeSmall]],
     [@"content-inset",      CGInsetMake(7.0, 28.0, 7.0, 8.0),           [CPThemeStateBezeled, CPComboBoxStateButtonBordered, CPThemeStateControlSizeSmall]],
     [@"content-inset",      CGInsetMake(7.0, 28.0, 7.0, 8.0),           [CPThemeStateBezeled, CPThemeStateControlSizeSmall]],

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

     [@"bezel-inset",        CGInsetMake(1.0, 2.0, 1.0, 2.0),            [CPThemeStateBezeled, CPThemeStateEditing, CPComboBoxStateButtonBordered, CPThemeStateControlSizeMini]],
     [@"content-inset",      CGInsetMake(7.0, 26.0, 7.0, 8.0),           [CPThemeStateBezeled, CPComboBoxStateButtonBordered, CPThemeStateControlSizeMini]],
     [@"content-inset",      CGInsetMake(7.0, 26.0, 7.0, 8.0),           [CPThemeStateBezeled, CPThemeStateControlSizeMini]],

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

    regularImageNormal = [CPImage imageWithCSSDictionary:@{
                                                           @"border-color": A3ColorActiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"50%",
                                                           @"box-sizing": @"border-box",
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"all",
                                                           @"transition-timing-function": @"ease"
                                                           }
                                                    size:CGSizeMake(16,16)],

    regularImageDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveDarkBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackground,
                                                             @"transition-duration": @"0.35s",
                                                             @"transition-property": @"all",
                                                             @"transition-timing-function": @"ease"
                                                             }
                                                      size:CGSizeMake(16,16)],

    regularImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                @"border-color": A3ColorBorderDark,
                                                                @"border-style": @"solid",
                                                                @"border-width": @"2px",
                                                                @"border-radius": @"50%",
                                                                @"box-sizing": @"border-box",
                                                                @"background-color": A3ColorBackgroundHighlighted,
                                                                @"transition-duration": @"0.35s",
                                                                @"transition-property": @"all",
                                                                @"transition-timing-function": @"ease"
                                                                }
                                                         size:CGSizeMake(16,16)],

    regularImageSelected = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": @"A3ColorBorderBlue",
                                                             @"border-style": @"solid",
                                                             @"border-width": @"2px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"transition-duration": @"0.35s",
                                                             @"transition-property": @"all",
                                                             @"transition-timing-function": @"ease"
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             @"background-color": @"A3ColorBorderBlue",
                                                             @"width": @"6px",
                                                             @"height": @"6px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"border-style": @"none",
                                                             @"content": @"''",
                                                             @"left": @"3px", // 5
                                                             @"top": @"3px", // 6
                                                             @"position": @"absolute",
                                                             @"z-index": @"300",
                                                             @"transition-duration": @"0.5s",
                                                             @"transition-property": @"all",
                                                             @"transition-timing-function": @"ease"
                                                             }
                                                      size:CGSizeMake(16,16)],

    regularImageSelectedDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveDarkBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"2px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackground,
                                                             @"transition-duration": @"0.35s",
                                                             @"transition-property": @"all",
                                                             @"transition-timing-function": @"ease"
                                                             }
                                                  beforeDictionary:nil
                                                   afterDictionary:@{
                                                                     @"background-color": A3ColorInactiveDarkBorder,
                                                                     @"width": @"6px",
                                                                     @"height": @"6px",
                                                                     @"border-radius": @"50%",
                                                                     @"box-sizing": @"border-box",
                                                                     @"border-style": @"none",
                                                                     @"content": @"''",
                                                                     @"left": @"3px", // 5
                                                                     @"top": @"3px", // 6
                                                                     @"position": @"absolute",
                                                                     @"z-index": @"300",
                                                                     @"transition-duration": @"0.5s",
                                                                     @"transition-property": @"all",
                                                                     @"transition-timing-function": @"ease"
                                                                     }
                                                      size:CGSizeMake(16,16)],

    regularImageSelectedHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                        @"border-color": @"A3ColorBorderBlue",
                                                                        @"border-style": @"solid",
                                                                        @"border-width": @"2px",
                                                                        @"border-radius": @"50%",
                                                                        @"box-sizing": @"border-box",
                                                                        @"background-color": A3ColorBackgroundHighlighted,
                                                                        @"transition-duration": @"0.35s",
                                                                        @"transition-property": @"all",
                                                                        @"transition-timing-function": @"ease"
                                                                        }
                                                     beforeDictionary:nil
                                                      afterDictionary:@{
                                                                        @"background-color": @"A3ColorBorderBlue",
                                                                        @"width": @"6px",
                                                                        @"height": @"6px",
                                                                        @"border-radius": @"50%",
                                                                        @"box-sizing": @"border-box",
                                                                        @"border-style": @"none",
                                                                        @"content": @"''",
                                                                        @"left": @"3px", // 5
                                                                        @"top": @"3px", // 6
                                                                        @"position": @"absolute",
                                                                        @"z-index": @"300",
                                                                        @"transition-duration": @"0.5s",
                                                                        @"transition-property": @"all",
                                                                        @"transition-timing-function": @"ease"
                                                                        }
                                                                 size:CGSizeMake(16,16)],

    regularImageSelectedNotKey = [CPImage imageWithCSSDictionary:@{
                                                                   @"border-color": A3ColorInactiveDarkBorder,
                                                                   @"border-style": @"solid",
                                                                   @"border-width": @"1px",
                                                                   @"border-radius": @"50%",
                                                                   @"box-sizing": @"border-box",
                                                                   @"background-color": A3ColorBackgroundWhite,
                                                                   @"transition-duration": @"0.35s",
                                                                   @"transition-property": @"all",
                                                                   @"transition-timing-function": @"ease"
                                                                   }
                                                beforeDictionary:nil
                                                 afterDictionary:@{
                                                                   @"background-color": A3ColorNotKeyDarkBorder,
                                                                   @"width": @"6px",
                                                                   @"height": @"6px",
                                                                   @"border-radius": @"50%",
                                                                   @"box-sizing": @"border-box",
                                                                   @"border-style": @"none",
                                                                   @"content": @"''",
                                                                   @"left": @"4px", // 5
                                                                   @"top": @"4px", // 6
                                                                   @"position": @"absolute",
                                                                   @"z-index": @"300",
                                                                   @"transition-duration": @"0.5s",
                                                                   @"transition-property": @"all",
                                                                   @"transition-timing-function": @"ease"
                                                                   }
                                                            size:CGSizeMake(16,16)],

    // Small

    smallImageNormal = [CPImage imageWithCSSDictionary:@{
                                                         @"border-color": A3ColorActiveBorder,
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"border-radius": @"50%",
                                                         @"box-sizing": @"border-box",
                                                         @"background-color": A3ColorBackgroundWhite,
                                                         @"transition-duration": @"0.35s",
                                                         @"transition-property": @"all",
                                                         @"transition-timing-function": @"ease"
                                                         }
                                                  size:CGSizeMake(14,14)],

    smallImageDisabled = [CPImage imageWithCSSDictionary:@{
                                                           @"border-color": A3ColorInactiveDarkBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"50%",
                                                           @"box-sizing": @"border-box",
                                                           @"background-color": A3ColorBackground,
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"all",
                                                           @"transition-timing-function": @"ease"
                                                           }
                                                    size:CGSizeMake(14,14)],

    smallImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                              @"border-color": A3ColorBorderDark,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"2px",
                                                              @"border-radius": @"50%",
                                                              @"box-sizing": @"border-box",
                                                              @"background-color": A3ColorBackgroundHighlighted,
                                                              @"transition-duration": @"0.35s",
                                                              @"transition-property": @"all",
                                                              @"transition-timing-function": @"ease"
                                                              }
                                                       size:CGSizeMake(14,14)],

    smallImageSelected = [CPImage imageWithCSSDictionary:@{
                                                           @"border-color": @"A3ColorBorderBlue",
                                                           @"border-style": @"solid",
                                                           @"border-width": @"2px",
                                                           @"border-radius": @"50%",
                                                           @"box-sizing": @"border-box",
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"all",
                                                           @"transition-timing-function": @"ease"
                                                           }
                                        beforeDictionary:nil
                                         afterDictionary:@{
                                                           @"background-color": @"A3ColorBorderBlue",
                                                           @"width": @"6px",
                                                           @"height": @"6px",
                                                           @"border-radius": @"50%",
                                                           @"box-sizing": @"border-box",
                                                           @"border-style": @"none",
                                                           @"content": @"''",
                                                           @"left": @"2px", // 5
                                                           @"top": @"2px", // 6
                                                           @"position": @"absolute",
                                                           @"z-index": @"300",
                                                           @"transition-duration": @"0.5s",
                                                           @"transition-property": @"all",
                                                           @"transition-timing-function": @"ease"
                                                           }
                                                    size:CGSizeMake(14,14)],

    smallImageSelectedDisabled = [CPImage imageWithCSSDictionary:@{
                                                                   @"border-color": A3ColorInactiveDarkBorder,
                                                                   @"border-style": @"solid",
                                                                   @"border-width": @"2px",
                                                                   @"border-radius": @"50%",
                                                                   @"box-sizing": @"border-box",
                                                                   @"background-color": A3ColorBackground,
                                                                   @"transition-duration": @"0.35s",
                                                                   @"transition-property": @"all",
                                                                   @"transition-timing-function": @"ease"
                                                                   }
                                                beforeDictionary:nil
                                                 afterDictionary:@{
                                                                   @"background-color": A3ColorInactiveDarkBorder,
                                                                   @"width": @"6px",
                                                                   @"height": @"6px",
                                                                   @"border-radius": @"50%",
                                                                   @"box-sizing": @"border-box",
                                                                   @"border-style": @"none",
                                                                   @"content": @"''",
                                                                   @"left": @"2px", // 5
                                                                   @"top": @"2px", // 6
                                                                   @"position": @"absolute",
                                                                   @"z-index": @"300",
                                                                   @"transition-duration": @"0.5s",
                                                                   @"transition-property": @"all",
                                                                   @"transition-timing-function": @"ease"
                                                                   }
                                                            size:CGSizeMake(14,14)],

    smallImageSelectedHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                      @"border-color": @"A3ColorBorderBlue",
                                                                      @"border-style": @"solid",
                                                                      @"border-width": @"2px",
                                                                      @"border-radius": @"50%",
                                                                      @"box-sizing": @"border-box",
                                                                      @"background-color": A3ColorBackgroundHighlighted,
                                                                      @"transition-duration": @"0.35s",
                                                                      @"transition-property": @"all",
                                                                      @"transition-timing-function": @"ease"
                                                                      }
                                                   beforeDictionary:nil
                                                    afterDictionary:@{
                                                                      @"background-color": @"A3ColorBorderBlue",
                                                                      @"width": @"6px",
                                                                      @"height": @"6px",
                                                                      @"border-radius": @"50%",
                                                                      @"box-sizing": @"border-box",
                                                                      @"border-style": @"none",
                                                                      @"content": @"''",
                                                                      @"left": @"2px", // 5
                                                                      @"top": @"2px", // 6
                                                                      @"position": @"absolute",
                                                                      @"z-index": @"300",
                                                                      @"transition-duration": @"0.5s",
                                                                      @"transition-property": @"all",
                                                                      @"transition-timing-function": @"ease"
                                                                      }
                                                               size:CGSizeMake(14,14)],

    smallImageSelectedNotKey = [CPImage imageWithCSSDictionary:@{
                                                                 @"border-color": A3ColorInactiveDarkBorder,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"50%",
                                                                 @"box-sizing": @"border-box",
                                                                 @"background-color": A3ColorBackgroundWhite,
                                                                 @"transition-duration": @"0.35s",
                                                                 @"transition-property": @"all",
                                                                 @"transition-timing-function": @"ease"
                                                                 }
                                              beforeDictionary:nil
                                               afterDictionary:@{
                                                                 @"background-color": A3ColorNotKeyDarkBorder,
                                                                 @"width": @"6px",
                                                                 @"height": @"6px",
                                                                 @"border-radius": @"50%",
                                                                 @"box-sizing": @"border-box",
                                                                 @"border-style": @"none",
                                                                 @"content": @"''",
                                                                 @"left": @"3px", // 5
                                                                 @"top": @"3px", // 6
                                                                 @"position": @"absolute",
                                                                 @"z-index": @"300",
                                                                 @"transition-duration": @"0.5s",
                                                                 @"transition-property": @"all",
                                                                 @"transition-timing-function": @"ease"
                                                                 }
                                                          size:CGSizeMake(14,14)],

    // Mini

    miniImageNormal = [CPImage imageWithCSSDictionary:@{
                                                        @"border-color": A3ColorActiveBorder,
                                                        @"border-style": @"solid",
                                                        @"border-width": @"1px",
                                                        @"border-radius": @"50%",
                                                        @"box-sizing": @"border-box",
                                                        @"background-color": A3ColorBackgroundWhite,
                                                        @"transition-duration": @"0.35s",
                                                        @"transition-property": @"all",
                                                        @"transition-timing-function": @"ease"
                                                        }
                                                 size:CGSizeMake(12,12)],

    miniImageDisabled = [CPImage imageWithCSSDictionary:@{
                                                          @"border-color": A3ColorInactiveDarkBorder,
                                                          @"border-style": @"solid",
                                                          @"border-width": @"1px",
                                                          @"border-radius": @"50%",
                                                          @"box-sizing": @"border-box",
                                                          @"background-color": A3ColorBackground,
                                                          @"transition-duration": @"0.35s",
                                                          @"transition-property": @"all",
                                                          @"transition-timing-function": @"ease"
                                                          }
                                                   size:CGSizeMake(12,12)],

    miniImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorBorderDark,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"2px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundHighlighted,
                                                             @"transition-duration": @"0.35s",
                                                             @"transition-property": @"all",
                                                             @"transition-timing-function": @"ease"
                                                             }
                                                      size:CGSizeMake(12,12)],

    miniImageSelected = [CPImage imageWithCSSDictionary:@{
                                                          @"border-color": @"A3ColorBorderBlue",
                                                          @"border-style": @"solid",
                                                          @"border-width": @"2px",
                                                          @"border-radius": @"50%",
                                                          @"box-sizing": @"border-box",
                                                          @"background-color": A3ColorBackgroundWhite,
                                                          @"transition-duration": @"0.35s",
                                                          @"transition-property": @"all",
                                                          @"transition-timing-function": @"ease"
                                                          }
                                       beforeDictionary:nil
                                        afterDictionary:@{
                                                          @"background-color": @"A3ColorBorderBlue",
                                                          @"width": @"4px",
                                                          @"height": @"4px",
                                                          @"border-radius": @"50%",
                                                          @"box-sizing": @"border-box",
                                                          @"border-style": @"none",
                                                          @"content": @"''",
                                                          @"left": @"2px", // 5
                                                          @"top": @"2px", // 6
                                                          @"position": @"absolute",
                                                          @"z-index": @"300",
                                                          @"transition-duration": @"0.5s",
                                                          @"transition-property": @"all",
                                                          @"transition-timing-function": @"ease"
                                                          }
                                                   size:CGSizeMake(12,12)],

    miniImageSelectedDisabled = [CPImage imageWithCSSDictionary:@{
                                                                  @"border-color": A3ColorInactiveDarkBorder,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"2px",
                                                                  @"border-radius": @"50%",
                                                                  @"box-sizing": @"border-box",
                                                                  @"background-color": A3ColorBackground,
                                                                  @"transition-duration": @"0.35s",
                                                                  @"transition-property": @"all",
                                                                  @"transition-timing-function": @"ease"
                                                                  }
                                               beforeDictionary:nil
                                                afterDictionary:@{
                                                                  @"background-color": A3ColorInactiveDarkBorder,
                                                                  @"width": @"4px",
                                                                  @"height": @"4px",
                                                                  @"border-radius": @"50%",
                                                                  @"box-sizing": @"border-box",
                                                                  @"border-style": @"none",
                                                                  @"content": @"''",
                                                                  @"left": @"2px", // 5
                                                                  @"top": @"2px", // 6
                                                                  @"position": @"absolute",
                                                                  @"z-index": @"300",
                                                                  @"transition-duration": @"0.5s",
                                                                  @"transition-property": @"all",
                                                                  @"transition-timing-function": @"ease"
                                                                  }
                                                           size:CGSizeMake(12,12)],

    miniImageSelectedHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                     @"border-color": @"A3ColorBorderBlue",
                                                                     @"border-style": @"solid",
                                                                     @"border-width": @"2px",
                                                                     @"border-radius": @"50%",
                                                                     @"box-sizing": @"border-box",
                                                                     @"background-color": A3ColorBackgroundHighlighted,
                                                                     @"transition-duration": @"0.35s",
                                                                     @"transition-property": @"all",
                                                                     @"transition-timing-function": @"ease"
                                                                     }
                                                  beforeDictionary:nil
                                                   afterDictionary:@{
                                                                     @"background-color": @"A3ColorBorderBlue",
                                                                     @"width": @"4px",
                                                                     @"height": @"4px",
                                                                     @"border-radius": @"50%",
                                                                     @"box-sizing": @"border-box",
                                                                     @"border-style": @"none",
                                                                     @"content": @"''",
                                                                     @"left": @"2px", // 5
                                                                     @"top": @"2px", // 6
                                                                     @"position": @"absolute",
                                                                     @"z-index": @"300",
                                                                     @"transition-duration": @"0.5s",
                                                                     @"transition-property": @"all",
                                                                     @"transition-timing-function": @"ease"
                                                                     }
                                                              size:CGSizeMake(12,12)],

    miniImageSelectedNotKey = [CPImage imageWithCSSDictionary:@{
                                                                @"border-color": A3ColorInactiveDarkBorder,
                                                                @"border-style": @"solid",
                                                                @"border-width": @"1px",
                                                                @"border-radius": @"50%",
                                                                @"box-sizing": @"border-box",
                                                                @"background-color": A3ColorBackgroundWhite,
                                                                @"transition-duration": @"0.35s",
                                                                @"transition-property": @"all",
                                                                @"transition-timing-function": @"ease"
                                                                }
                                             beforeDictionary:nil
                                              afterDictionary:@{
                                                                @"background-color": A3ColorNotKeyDarkBorder,
                                                                @"width": @"4px",
                                                                @"height": @"4px",
                                                                @"border-radius": @"50%",
                                                                @"box-sizing": @"border-box",
                                                                @"border-style": @"none",
                                                                @"content": @"''",
                                                                @"left": @"3px", // 5
                                                                @"top": @"3px", // 6
                                                                @"position": @"absolute",
                                                                @"z-index": @"300",
                                                                @"transition-duration": @"0.5s",
                                                                @"transition-property": @"all",
                                                                @"transition-timing-function": @"ease"
                                                                }
                                                         size:CGSizeMake(12,12)],


    // Global
    themedRadioButtonValues =
    [
     [@"alignment",                  CPLeftTextAlignment,                CPThemeStateNormal],
//     [@"font",                       [CPFont systemFontOfSize:12.0],     CPThemeStateNormal],
     [@"content-inset",              CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateNormal],
     [@"direct-nib2cib-adjustment",  YES],

     [@"text-color",                 A3CPColorActiveText,                  CPThemeStateNormal],
     [@"text-color",                 A3CPColorInactiveText,                CPThemeStateDisabled],

     //
     [@"image",                      regularImageNormal,                    CPThemeStateNormal],
     [@"image",                      regularImageSelectedNotKey,            CPThemeStateSelected],
     [@"image",                      regularImageSelected,                  [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"image",                      regularImageSelectedHighlighted,       [CPThemeStateSelected, CPThemeStateHighlighted]],
     [@"image",                      regularImageHighlighted,               CPThemeStateHighlighted],
     [@"image",                      regularImageDisabled,                  CPThemeStateDisabled],
     [@"image",                      regularImageSelectedDisabled,          [CPThemeStateSelected, CPThemeStateDisabled]],
     [@"image-offset",               3], // was CPRadioImageOffset

     [@"min-size",                   CGSizeMake(16, 16)],
     [@"max-size",                   CGSizeMake(-1.0, -1.0)],
     [@"nib2cib-adjustment-frame",   CGRectMake(1.0, -1.0, -1.0, -2.0)], // (2.0, 1.0, 0.0, 0.0)

     // CPThemeStateControlSizeSmall
     [@"image",                      smallImageNormal,                      CPThemeStateControlSizeSmall],
     [@"image",                      smallImageSelectedNotKey,              [CPThemeStateControlSizeSmall, CPThemeStateSelected]],
     [@"image",                      smallImageSelected,                    [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"image",                      smallImageSelectedHighlighted,         [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateHighlighted]],
     [@"image",                      smallImageHighlighted,                 [CPThemeStateControlSizeSmall, CPThemeStateHighlighted]],
     [@"image",                      smallImageDisabled,                    [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
     [@"image",                      smallImageSelectedDisabled,            [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateDisabled]],
     [@"image-offset",               4,                                     CPThemeStateControlSizeSmall], // was CPRadioImageOffset

     [@"min-size",                   CGSizeMake(14, 14),                    CPThemeStateControlSizeSmall],
     [@"max-size",                   CGSizeMake(-1, -1.0),                  CPThemeStateControlSizeSmall],
     [@"nib2cib-adjustment-frame",   CGRectMake(2.0, -3.0, -1.0, -6.0),       CPThemeStateControlSizeSmall],

     // CPThemeStateControlSizeMini
     [@"image",                      miniImageNormal,                       CPThemeStateControlSizeMini],
     [@"image",                      miniImageSelectedNotKey,               [CPThemeStateControlSizeMini, CPThemeStateSelected]],
     [@"image",                      miniImageSelected,                     [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"image",                      miniImageSelectedHighlighted,          [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateHighlighted]],
     [@"image",                      miniImageHighlighted,                  [CPThemeStateControlSizeMini, CPThemeStateHighlighted]],
     [@"image",                      miniImageDisabled,                     [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
     [@"image",                      miniImageSelectedDisabled,             [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateDisabled]],
     [@"image-offset",               2,                                     CPThemeStateControlSizeMini], // was CPRadioImageOffset

     [@"min-size",                   CGSizeMake(12, 12),                    CPThemeStateControlSizeMini],
     [@"max-size",                   CGSizeMake(-1, -1),                    CPThemeStateControlSizeMini],
     [@"nib2cib-adjustment-frame",   CGRectMake(3.0, -6.0, -5.0, -12.0),       CPThemeStateControlSizeMini],
     ];

    [self registerThemeValues:themedRadioButtonValues forView:button];

    return button;
}


+ (CPCheckBox)themedCheckBoxButton
{
    var button = [CPCheckBox checkBoxWithTitle:@"Checkbox"],

    regularImageNormal = [CPImage imageWithCSSDictionary:@{
                                                           @"border-color": A3ColorActiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"2px",
                                                           @"box-sizing": @"border-box",
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"transition-delay": @"0s",
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"all",
                                                           @"transition-timing-function": @"ease"
                                                           }
                                                    size:CGSizeMake(16,16)],

    regularImageSelected = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorActiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"transition-delay": @"0s",
                                                             @"transition-duration": @"0.35s",
                                                             @"transition-property": @"all",
                                                             @"transition-timing-function": @"ease"
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             @"border-color": @"A3ColorBorderBlue",
                                                             @"width": @"5px",
                                                             @"height": @"10px",
                                                             @"box-sizing": @"border-box",
                                                             @"border-style": @"solid",
                                                             @"content": @"''",
                                                             @"left": @"5px",
                                                             @"top": @"1px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300",
                                                             @"transition-delay": @"0s",
                                                             @"transition-duration": @"0.35s",
                                                             @"transition-property": @"all",
                                                             @"transition-timing-function": @"ease",
                                                             @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                             @"border-bottom-width": @"2px",
                                                             @"border-right-width": @"2px",
                                                             @"border-top-width": @"0px",
                                                             @"border-left-width": @"0px"
                                                             }
                                                      size:CGSizeMake(16,16)],

    regularImageSelectedHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                        @"border-color": A3ColorActiveBorder,
                                                                        @"border-style": @"solid",
                                                                        @"border-width": @"1px",
                                                                        @"border-radius": @"2px",
                                                                        @"box-sizing": @"border-box",
                                                                        @"background-color": A3ColorBackgroundHighlighted,
                                                                        @"transition-delay": @"0s",
                                                                        @"transition-duration": @"0.35s",
                                                                        @"transition-property": @"all",
                                                                        @"transition-timing-function": @"ease"
                                                                        }
                                                     beforeDictionary:nil
                                                      afterDictionary:@{
                                                                        @"border-color": @"A3ColorBorderBlue",
                                                                        @"width": @"5px",
                                                                        @"height": @"10px",
                                                                        @"box-sizing": @"border-box",
                                                                        @"border-style": @"solid",
                                                                        @"content": @"''",
                                                                        @"left": @"5px",
                                                                        @"top": @"1px",
                                                                        @"position": @"absolute",
                                                                        @"z-index": @"300",
                                                                        @"transition-delay": @"0s",
                                                                        @"transition-duration": @"0.35s",
                                                                        @"transition-property": @"all",
                                                                        @"transition-timing-function": @"ease",
                                                                        @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                                        @"border-bottom-width": @"2px",
                                                                        @"border-right-width": @"2px",
                                                                        @"border-top-width": @"0px",
                                                                        @"border-left-width": @"0px"
                                                                        }
                                                                 size:CGSizeMake(16,16)],

    regularImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                @"border-color": A3ColorBorderDark,
                                                                @"border-style": @"solid",
                                                                @"border-width": @"1px",
                                                                @"border-radius": @"2px",
                                                                @"box-sizing": @"border-box",
                                                                @"background-color": A3ColorBackgroundHighlighted,
                                                                @"transition-delay": @"0s",
                                                                @"transition-duration": @"0.35s",
                                                                @"transition-property": @"all",
                                                                @"transition-timing-function": @"ease"
                                                                }
                                                         size:CGSizeMake(16,16)],

    regularImageDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveDarkBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackground,
                                                             @"transition-delay": @"0s",
                                                             @"transition-duration": @"0.35s",
                                                             @"transition-property": @"all",
                                                             @"transition-timing-function": @"ease"
                                                             }
                                                      size:CGSizeMake(16,16)],

    regularImageSelectedDisabled = [CPImage imageWithCSSDictionary:@{
                                                                     @"border-color": A3ColorInactiveDarkBorder,
                                                                     @"border-style": @"solid",
                                                                     @"border-width": @"1px",
                                                                     @"border-radius": @"2px",
                                                                     @"box-sizing": @"border-box",
                                                                     @"background-color": A3ColorBackground,
                                                                     @"transition-delay": @"0s",
                                                                     @"transition-duration": @"0.35s",
                                                                     @"transition-property": @"all",
                                                                     @"transition-timing-function": @"ease"
                                                                     }
                                                  beforeDictionary:nil
                                                   afterDictionary:@{
                                                                     @"border-color": A3ColorInactiveDarkBorder,
                                                                     @"width": @"5px",
                                                                     @"height": @"10px",
                                                                     @"box-sizing": @"border-box",
                                                                     @"border-style": @"solid",
                                                                     @"content": @"''",
                                                                     @"left": @"5px",
                                                                     @"top": @"1px",
                                                                     @"position": @"absolute",
                                                                     @"z-index": @"300",
                                                                     @"transition-delay": @"0s",
                                                                     @"transition-duration": @"0.35s",
                                                                     @"transition-property": @"all",
                                                                     @"transition-timing-function": @"ease",
                                                                     @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                                     @"border-bottom-width": @"2px",
                                                                     @"border-right-width": @"2px",
                                                                     @"border-top-width": @"0px",
                                                                     @"border-left-width": @"0px"
                                                                     }
                                                              size:CGSizeMake(16,16)],

    regularImageSelectedNotKey = [CPImage imageWithCSSDictionary:@{
                                                                   @"border-color": A3ColorActiveBorder,
                                                                   @"border-style": @"solid",
                                                                   @"border-width": @"1px",
                                                                   @"border-radius": @"2px",
                                                                   @"box-sizing": @"border-box",
                                                                   @"background-color": A3ColorBackgroundWhite,
                                                                   @"transition-delay": @"0s",
                                                                   @"transition-duration": @"0.35s",
                                                                   @"transition-property": @"all",
                                                                   @"transition-timing-function": @"ease"
                                                                   }
                                                beforeDictionary:nil
                                                 afterDictionary:@{
                                                                   @"border-color": A3ColorNotKeyDarkBorder,
                                                                   @"width": @"5px",
                                                                   @"height": @"10px",
                                                                   @"box-sizing": @"border-box",
                                                                   @"border-style": @"solid",
                                                                   @"content": @"''",
                                                                   @"left": @"5px",
                                                                   @"top": @"1px",
                                                                   @"position": @"absolute",
                                                                   @"z-index": @"300",
                                                                   @"transition-delay": @"0s",
                                                                   @"transition-duration": @"0.35s",
                                                                   @"transition-property": @"all",
                                                                   @"transition-timing-function": @"ease",
                                                                   @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                                   @"border-bottom-width": @"2px",
                                                                   @"border-right-width": @"2px",
                                                                   @"border-top-width": @"0px",
                                                                   @"border-left-width": @"0px"
                                                                   }
                                                            size:CGSizeMake(16,16)],

    // Small size

    smallImageNormal = [CPImage imageWithCSSDictionary:@{
                                                         @"border-color": A3ColorActiveBorder,
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"border-radius": @"2px",
                                                         @"box-sizing": @"border-box",
                                                         @"background-color": A3ColorBackgroundWhite,
                                                         @"transition-delay": @"0s",
                                                         @"transition-duration": @"0.35s",
                                                         @"transition-property": @"all",
                                                         @"transition-timing-function": @"ease"
                                                         }
                                                  size:CGSizeMake(14,14)],

    smallImageSelected = [CPImage imageWithCSSDictionary:@{
                                                           @"border-color": A3ColorActiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"2px",
                                                           @"box-sizing": @"border-box",
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"transition-delay": @"0s",
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"all",
                                                           @"transition-timing-function": @"ease"
                                                           }
                                        beforeDictionary:nil
                                         afterDictionary:@{
                                                           @"border-color": @"A3ColorBorderBlue",
                                                           @"width": @"4px", // 5
                                                           @"height": @"8px", // 10
                                                           @"box-sizing": @"border-box",
                                                           @"border-style": @"solid",
                                                           @"content": @"''",
                                                           @"left": @"4px", // 5
                                                           @"top": @"1px",
                                                           @"position": @"absolute",
                                                           @"z-index": @"300",
                                                           @"transition-delay": @"0s",
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"all",
                                                           @"transition-timing-function": @"ease",
                                                           @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                           @"border-bottom-width": @"2px",
                                                           @"border-right-width": @"2px",
                                                           @"border-top-width": @"0px",
                                                           @"border-left-width": @"0px"
                                                           }
                                                    size:CGSizeMake(14,14)],

    smallImageSelectedHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                      @"border-color": A3ColorActiveBorder,
                                                                      @"border-style": @"solid",
                                                                      @"border-width": @"1px",
                                                                      @"border-radius": @"2px",
                                                                      @"box-sizing": @"border-box",
                                                                      @"background-color": A3ColorBackgroundHighlighted,
                                                                      @"transition-delay": @"0s",
                                                                      @"transition-duration": @"0.35s",
                                                                      @"transition-property": @"all",
                                                                      @"transition-timing-function": @"ease"
                                                                      }
                                                   beforeDictionary:nil
                                                    afterDictionary:@{
                                                                      @"border-color": @"A3ColorBorderBlue",
                                                                      @"width": @"4px",
                                                                      @"height": @"8px",
                                                                      @"box-sizing": @"border-box",
                                                                      @"border-style": @"solid",
                                                                      @"content": @"''",
                                                                      @"left": @"4px",
                                                                      @"top": @"1px",
                                                                      @"position": @"absolute",
                                                                      @"z-index": @"300",
                                                                      @"transition-delay": @"0s",
                                                                      @"transition-duration": @"0.35s",
                                                                      @"transition-property": @"all",
                                                                      @"transition-timing-function": @"ease",
                                                                      @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                                      @"border-bottom-width": @"2px",
                                                                      @"border-right-width": @"2px",
                                                                      @"border-top-width": @"0px",
                                                                      @"border-left-width": @"0px"
                                                                      }
                                                               size:CGSizeMake(14,14)],

    smallImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                              @"border-color": A3ColorBorderDark,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"2px",
                                                              @"box-sizing": @"border-box",
                                                              @"background-color": A3ColorBackgroundHighlighted,
                                                              @"transition-delay": @"0s",
                                                              @"transition-duration": @"0.35s",
                                                              @"transition-property": @"all",
                                                              @"transition-timing-function": @"ease"
                                                              }
                                                       size:CGSizeMake(14,14)],

    smallImageDisabled = [CPImage imageWithCSSDictionary:@{
                                                           @"border-color": A3ColorInactiveDarkBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"2px",
                                                           @"box-sizing": @"border-box",
                                                           @"background-color": A3ColorBackground,
                                                           @"transition-delay": @"0s",
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"all",
                                                           @"transition-timing-function": @"ease"
                                                           }
                                                    size:CGSizeMake(14,14)],

    smallImageSelectedDisabled = [CPImage imageWithCSSDictionary:@{
                                                                   @"border-color": A3ColorInactiveDarkBorder,
                                                                   @"border-style": @"solid",
                                                                   @"border-width": @"1px",
                                                                   @"border-radius": @"2px",
                                                                   @"box-sizing": @"border-box",
                                                                   @"background-color": A3ColorBackground,
                                                                   @"transition-delay": @"0s",
                                                                   @"transition-duration": @"0.35s",
                                                                   @"transition-property": @"all",
                                                                   @"transition-timing-function": @"ease"
                                                                   }
                                                beforeDictionary:nil
                                                 afterDictionary:@{
                                                                   @"border-color": A3ColorInactiveDarkBorder,
                                                                   @"width": @"4px",
                                                                   @"height": @"8px",
                                                                   @"box-sizing": @"border-box",
                                                                   @"border-style": @"solid",
                                                                   @"content": @"''",
                                                                   @"left": @"4px",
                                                                   @"top": @"1px",
                                                                   @"position": @"absolute",
                                                                   @"z-index": @"300",
                                                                   @"transition-delay": @"0s",
                                                                   @"transition-duration": @"0.35s",
                                                                   @"transition-property": @"all",
                                                                   @"transition-timing-function": @"ease",
                                                                   @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                                   @"border-bottom-width": @"2px",
                                                                   @"border-right-width": @"2px",
                                                                   @"border-top-width": @"0px",
                                                                   @"border-left-width": @"0px"
                                                                   }
                                                            size:CGSizeMake(14,14)],

    smallImageSelectedNotKey = [CPImage imageWithCSSDictionary:@{
                                                                 @"border-color": A3ColorActiveBorder,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"2px",
                                                                 @"box-sizing": @"border-box",
                                                                 @"background-color": A3ColorBackgroundWhite,
                                                                 @"transition-delay": @"0s",
                                                                 @"transition-duration": @"0.35s",
                                                                 @"transition-property": @"all",
                                                                 @"transition-timing-function": @"ease"
                                                                 }
                                              beforeDictionary:nil
                                               afterDictionary:@{
                                                                 @"border-color": A3ColorNotKeyDarkBorder,
                                                                 @"width": @"4px",
                                                                 @"height": @"8px",
                                                                 @"box-sizing": @"border-box",
                                                                 @"border-style": @"solid",
                                                                 @"content": @"''",
                                                                 @"left": @"4px",
                                                                 @"top": @"1px",
                                                                 @"position": @"absolute",
                                                                 @"z-index": @"300",
                                                                 @"transition-delay": @"0s",
                                                                 @"transition-duration": @"0.35s",
                                                                 @"transition-property": @"all",
                                                                 @"transition-timing-function": @"ease",
                                                                 @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                                 @"border-bottom-width": @"2px",
                                                                 @"border-right-width": @"2px",
                                                                 @"border-top-width": @"0px",
                                                                 @"border-left-width": @"0px"
                                                                 }
                                                          size:CGSizeMake(14,14)],

    // Mini size

    miniImageNormal = [CPImage imageWithCSSDictionary:@{
                                                        @"border-color": A3ColorActiveBorder,
                                                        @"border-style": @"solid",
                                                        @"border-width": @"1px",
                                                        @"border-radius": @"2px",
                                                        @"box-sizing": @"border-box",
                                                        @"background-color": A3ColorBackgroundWhite,
                                                        @"transition-delay": @"0s",
                                                        @"transition-duration": @"0.35s",
                                                        @"transition-property": @"all",
                                                        @"transition-timing-function": @"ease"
                                                        }
                                                 size:CGSizeMake(12,12)],

    miniImageSelected = [CPImage imageWithCSSDictionary:@{
                                                          @"border-color": A3ColorActiveBorder,
                                                          @"border-style": @"solid",
                                                          @"border-width": @"1px",
                                                          @"border-radius": @"2px",
                                                          @"box-sizing": @"border-box",
                                                          @"background-color": A3ColorBackgroundWhite,
                                                          @"transition-delay": @"0s",
                                                          @"transition-duration": @"0.35s",
                                                          @"transition-property": @"all",
                                                          @"transition-timing-function": @"ease"
                                                          }
                                       beforeDictionary:nil
                                        afterDictionary:@{
                                                          @"border-color": @"A3ColorBorderBlue",
                                                          @"width": @"4px",
                                                          @"height": @"7px",
                                                          @"box-sizing": @"border-box",
                                                          @"border-style": @"solid",
                                                          @"content": @"''",
                                                          @"left": @"3px",
                                                          @"top": @"1px",
                                                          @"position": @"absolute",
                                                          @"z-index": @"300",
                                                          @"transition-delay": @"0s",
                                                          @"transition-duration": @"0.35s",
                                                          @"transition-property": @"all",
                                                          @"transition-timing-function": @"ease",
                                                          @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                          @"border-bottom-width": @"2px",
                                                          @"border-right-width": @"2px",
                                                          @"border-top-width": @"0px",
                                                          @"border-left-width": @"0px"
                                                          }
                                                   size:CGSizeMake(12,12)],

    miniImageSelectedHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                     @"border-color": A3ColorActiveBorder,
                                                                     @"border-style": @"solid",
                                                                     @"border-width": @"1px",
                                                                     @"border-radius": @"2px",
                                                                     @"box-sizing": @"border-box",
                                                                     @"background-color": A3ColorBackgroundHighlighted,
                                                                     @"transition-delay": @"0s",
                                                                     @"transition-duration": @"0.35s",
                                                                     @"transition-property": @"all",
                                                                     @"transition-timing-function": @"ease"
                                                                     }
                                                  beforeDictionary:nil
                                                   afterDictionary:@{
                                                                     @"border-color": @"A3ColorBorderBlue",
                                                                     @"width": @"4px",
                                                                     @"height": @"7px",
                                                                     @"box-sizing": @"border-box",
                                                                     @"border-style": @"solid",
                                                                     @"content": @"''",
                                                                     @"left": @"3px",
                                                                     @"top": @"1px",
                                                                     @"position": @"absolute",
                                                                     @"z-index": @"300",
                                                                     @"transition-delay": @"0s",
                                                                     @"transition-duration": @"0.35s",
                                                                     @"transition-property": @"all",
                                                                     @"transition-timing-function": @"ease",
                                                                     @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                                     @"border-bottom-width": @"2px",
                                                                     @"border-right-width": @"2px",
                                                                     @"border-top-width": @"0px",
                                                                     @"border-left-width": @"0px"
                                                                     }
                                                              size:CGSizeMake(12,12)],

    miniImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorBorderDark,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundHighlighted,
                                                             @"transition-delay": @"0s",
                                                             @"transition-duration": @"0.35s",
                                                             @"transition-property": @"all",
                                                             @"transition-timing-function": @"ease"
                                                             }
                                                      size:CGSizeMake(12,12)],

    miniImageDisabled = [CPImage imageWithCSSDictionary:@{
                                                          @"border-color": A3ColorInactiveDarkBorder,
                                                          @"border-style": @"solid",
                                                          @"border-width": @"1px",
                                                          @"border-radius": @"2px",
                                                          @"box-sizing": @"border-box",
                                                          @"background-color": A3ColorBackground,
                                                          @"transition-delay": @"0s",
                                                          @"transition-duration": @"0.35s",
                                                          @"transition-property": @"all",
                                                          @"transition-timing-function": @"ease"
                                                          }
                                                   size:CGSizeMake(12,12)],

    miniImageSelectedDisabled = [CPImage imageWithCSSDictionary:@{
                                                                  @"border-color": A3ColorInactiveDarkBorder,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"2px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"background-color": A3ColorBackground,
                                                                  @"transition-delay": @"0s",
                                                                  @"transition-duration": @"0.35s",
                                                                  @"transition-property": @"all",
                                                                  @"transition-timing-function": @"ease"
                                                                  }
                                               beforeDictionary:nil
                                                afterDictionary:@{
                                                                  @"border-color": A3ColorInactiveDarkBorder,
                                                                  @"width": @"4px",
                                                                  @"height": @"7px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"border-style": @"solid",
                                                                  @"content": @"''",
                                                                  @"left": @"3px",
                                                                  @"top": @"1px",
                                                                  @"position": @"absolute",
                                                                  @"z-index": @"300",
                                                                  @"transition-delay": @"0s",
                                                                  @"transition-duration": @"0.35s",
                                                                  @"transition-property": @"all",
                                                                  @"transition-timing-function": @"ease",
                                                                  @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                                  @"border-bottom-width": @"2px",
                                                                  @"border-right-width": @"2px",
                                                                  @"border-top-width": @"0px",
                                                                  @"border-left-width": @"0px"
                                                                  }
                                                           size:CGSizeMake(12,12)],

    miniImageSelectedNotKey = [CPImage imageWithCSSDictionary:@{
                                                                @"border-color": A3ColorActiveBorder,
                                                                @"border-style": @"solid",
                                                                @"border-width": @"1px",
                                                                @"border-radius": @"2px",
                                                                @"box-sizing": @"border-box",
                                                                @"background-color": A3ColorBackgroundWhite,
                                                                @"transition-delay": @"0s",
                                                                @"transition-duration": @"0.35s",
                                                                @"transition-property": @"all",
                                                                @"transition-timing-function": @"ease"
                                                                }
                                             beforeDictionary:nil
                                              afterDictionary:@{
                                                                @"border-color": A3ColorNotKeyDarkBorder,
                                                                @"width": @"4px",
                                                                @"height": @"7px",
                                                                @"box-sizing": @"border-box",
                                                                @"border-style": @"solid",
                                                                @"content": @"''",
                                                                @"left": @"3px",
                                                                @"top": @"1px",
                                                                @"position": @"absolute",
                                                                @"z-index": @"300",
                                                                @"transition-delay": @"0s",
                                                                @"transition-duration": @"0.35s",
                                                                @"transition-property": @"all",
                                                                @"transition-timing-function": @"ease",
                                                                @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                                @"border-bottom-width": @"2px",
                                                                @"border-right-width": @"2px",
                                                                @"border-top-width": @"0px",
                                                                @"border-left-width": @"0px"
                                                                }
                                                         size:CGSizeMake(12,12)],

    // Global
    themedCheckBoxValues =
    [
     [@"alignment",                 CPLeftTextAlignment,                                        CPThemeStateNormal],
     [@"content-inset",             CGInsetMakeZero(),                                          CPThemeStateNormal],

//     [@"font",                      [CPFont systemFontOfSize:CPFontCurrentSystemSize],          CPThemeStateNormal],
     [@"text-color",                A3CPColorActiveText,                                        CPThemeStateNormal],
     [@"text-color",                A3CPColorInactiveText,                                      CPThemeStateDisabled],
     [@"text-color",                [CPColor colorWithCalibratedWhite:51.0 / 255.0 alpha:1.0],  CPThemeStateTableDataView],
     [@"text-color",                [CPColor whiteColor],                                       [CPThemeStateTableDataView, CPThemeStateSelectedDataView, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],

     // CPThemeStateControlSizeRegular

     [@"image",                     regularImageNormal,                                         CPThemeStateNormal],
     [@"image",                     regularImageSelected,                                       [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"image",                     regularImageSelectedNotKey,                                 CPThemeStateSelected],
     [@"image",                     regularImageSelectedHighlighted,                            [CPThemeStateSelected, CPThemeStateHighlighted]],
     [@"image",                     regularImageHighlighted,                                    CPThemeStateHighlighted],
     [@"image",                     regularImageDisabled,                                       CPThemeStateDisabled],
     [@"image",                     regularImageSelectedDisabled,                               [CPThemeStateSelected, CPThemeStateDisabled]],

     [@"min-size",                  CGSizeMake(16.0, 16.0)],
     [@"max-size",                  CGSizeMake(-1.0, -1.0)],
     [@"nib2cib-adjustment-frame",  CGRectMake(1.0, -1.0, -2.0, -2.0)], // (2.0, 1.0, 0.0, 0.0) - 2, -6, -4, -4
     [@"direct-nib2cib-adjustment", YES],
     [@"image-offset",              3],  // CPCheckBoxImageOffset

     // CPThemeStateControlSizeSmall
     [@"image",                     smallImageNormal,                                           CPThemeStateControlSizeSmall],
     [@"image",                     smallImageSelected,                                         [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"image",                     smallImageSelectedNotKey,                                   [CPThemeStateControlSizeSmall, CPThemeStateSelected]],
     [@"image",                     smallImageSelectedHighlighted,                              [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateHighlighted]],
     [@"image",                     smallImageHighlighted,                                      [CPThemeStateControlSizeSmall, CPThemeStateHighlighted]],
     [@"image",                     smallImageDisabled,                                         [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
     [@"image",                     smallImageSelectedDisabled,                                 [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateDisabled]],

     [@"min-size",                  CGSizeMake(14.0, 14.0),                                     CPThemeStateControlSizeSmall],
     [@"max-size",                  CGSizeMake(-1.0, -1.0),                                     CPThemeStateControlSizeSmall],
     [@"nib2cib-adjustment-frame",  CGRectMake(2.0, -3.0, -3.0, -6.0),                          CPThemeStateControlSizeSmall], // 3, -9, -5, -6
     [@"image-offset",              4,                                                          CPThemeStateControlSizeSmall],  // CPCheckBoxImageOffset

     // CPThemeStateControlSizeMini
     [@"image",                     miniImageNormal,                                            CPThemeStateControlSizeMini],
     [@"image",                     miniImageSelected,                                          [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"image",                     miniImageSelectedNotKey,                                    [CPThemeStateControlSizeMini, CPThemeStateSelected]],
     [@"image",                     miniImageSelectedHighlighted,                               [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateHighlighted]],
     [@"image",                     miniImageHighlighted,                                       [CPThemeStateControlSizeMini, CPThemeStateHighlighted]],
     [@"image",                     miniImageDisabled,                                          [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
     [@"image",                     miniImageSelectedDisabled,                                  [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateDisabled]],

     [@"min-size",                  CGSizeMake(12.0, 12.0),                                     CPThemeStateControlSizeMini],
     [@"max-size",                  CGSizeMake(-1.0, -1.0),                                     CPThemeStateControlSizeMini],
     [@"nib2cib-adjustment-frame",  CGRectMake(3.0, -4.0, -6.0, -10.0),                         CPThemeStateControlSizeMini], // 4, -11, -6, -8
     [@"image-offset",              2,                                                          CPThemeStateControlSizeMini]  // CPCheckBoxImageOffset
     ];

    [button setThemeState:CPThemeStateNormal];

    [self registerThemeValues:themedCheckBoxValues forView:button];

    return button;
}

+ (CPCheckBox)themedMixedCheckBoxButton
{
    var button = [self themedCheckBoxButton];

    [button setAllowsMixedState:YES];
    [button setState:CPMixedState];

    mixedHighlightedImage = [CPImage imageWithCSSDictionary:@{
                                                              @"border-color": A3ColorActiveBorder,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"2px",
                                                              @"box-sizing": @"border-box",
                                                              @"background-color": A3ColorBackgroundHighlighted,
                                                              @"transition-delay": @"0s",
                                                              @"transition-duration": @"0.35s",
                                                              @"transition-property": @"all",
                                                              @"transition-timing-function": @"ease"
                                                              }
                                           beforeDictionary:nil
                                            afterDictionary:@{
                                                              @"background-color": @"A3ColorBorderBlue",
                                                              @"width": @"8px",
                                                              @"height": @"2px",
                                                              @"box-sizing": @"border-box",
                                                              @"border-style": @"none",
                                                              @"content": @"''",
                                                              @"left": @"3px",
                                                              @"top": @"6px",
                                                              @"position": @"absolute",
                                                              @"z-index": @"300",
                                                              @"transition-delay": @"0s",
                                                              @"transition-duration": @"0.35s",
                                                              @"transition-property": @"all",
                                                              @"transition-timing-function": @"ease",
                                                              }
                                                       size:CGSizeMake(16,16)],

    mixedDisabledImage = [CPImage imageWithCSSDictionary:@{
                                                           @"border-color": A3ColorInactiveDarkBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"2px",
                                                           @"box-sizing": @"border-box",
                                                           @"background-color": A3ColorBackground,
                                                           @"transition-delay": @"0s",
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"all",
                                                           @"transition-timing-function": @"ease"
                                                           }
                                        beforeDictionary:nil
                                         afterDictionary:@{
                                                           @"background-color": A3ColorInactiveDarkBorder,
                                                           @"width": @"8px",
                                                           @"height": @"2px",
                                                           @"box-sizing": @"border-box",
                                                           @"border-style": @"none",
                                                           @"content": @"''",
                                                           @"left": @"3px",
                                                           @"top": @"6px",
                                                           @"position": @"absolute",
                                                           @"z-index": @"300",
                                                           @"transition-delay": @"0s",
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"all",
                                                           @"transition-timing-function": @"ease",
                                                           }
                                                    size:CGSizeMake(16,16)],

    mixedImage = [CPImage imageWithCSSDictionary:@{
                                                   @"border-color": A3ColorActiveBorder,
                                                   @"border-style": @"solid",
                                                   @"border-width": @"1px",
                                                   @"border-radius": @"2px",
                                                   @"box-sizing": @"border-box",
                                                   @"background-color": A3ColorBackgroundWhite,
                                                   @"transition-delay": @"0s",
                                                   @"transition-duration": @"0.35s",
                                                   @"transition-property": @"all",
                                                   @"transition-timing-function": @"ease"
                                                   }
                                beforeDictionary:nil
                                 afterDictionary:@{
                                                   @"background-color": @"A3ColorBorderBlue",
                                                   @"width": @"8px",
                                                   @"height": @"2px",
                                                   @"box-sizing": @"border-box",
                                                   @"border-style": @"none",
                                                   @"content": @"''",
                                                   @"left": @"3px",
                                                   @"top": @"6px",
                                                   @"position": @"absolute",
                                                   @"z-index": @"300",
                                                   @"transition-delay": @"0s",
                                                   @"transition-duration": @"0.35s",
                                                   @"transition-property": @"all",
                                                   @"transition-timing-function": @"ease",
                                                   }
                                            size:CGSizeMake(16,16)],

    mixedImageNotKey = [CPImage imageWithCSSDictionary:@{
                                                         @"border-color": A3ColorActiveBorder,
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"border-radius": @"2px",
                                                         @"box-sizing": @"border-box",
                                                         @"background-color": A3ColorBackgroundWhite,
                                                         @"transition-delay": @"0s",
                                                         @"transition-duration": @"0.35s",
                                                         @"transition-property": @"all",
                                                         @"transition-timing-function": @"ease"
                                                         }
                                      beforeDictionary:nil
                                       afterDictionary:@{
                                                         @"background-color": A3ColorNotKeyDarkBorder,
                                                         @"width": @"8px",
                                                         @"height": @"2px",
                                                         @"box-sizing": @"border-box",
                                                         @"border-style": @"none",
                                                         @"content": @"''",
                                                         @"left": @"3px",
                                                         @"top": @"6px",
                                                         @"position": @"absolute",
                                                         @"z-index": @"300",
                                                         @"transition-delay": @"0s",
                                                         @"transition-duration": @"0.35s",
                                                         @"transition-property": @"all",
                                                         @"transition-timing-function": @"ease",
                                                         }
                                                  size:CGSizeMake(16,16)],

    // Small

    smallMixedHighlightedImage = [CPImage imageWithCSSDictionary:@{
                                                                   @"border-color": A3ColorActiveBorder,
                                                                   @"border-style": @"solid",
                                                                   @"border-width": @"1px",
                                                                   @"border-radius": @"2px",
                                                                   @"box-sizing": @"border-box",
                                                                   @"background-color": A3ColorBackgroundHighlighted,
                                                                   @"transition-delay": @"0s",
                                                                   @"transition-duration": @"0.35s",
                                                                   @"transition-property": @"all",
                                                                   @"transition-timing-function": @"ease"
                                                                   }
                                                beforeDictionary:nil
                                                 afterDictionary:@{
                                                                   @"background-color": @"A3ColorBorderBlue",
                                                                   @"width": @"8px",
                                                                   @"height": @"2px",
                                                                   @"box-sizing": @"border-box",
                                                                   @"border-style": @"none",
                                                                   @"content": @"''",
                                                                   @"left": @"2px",
                                                                   @"top": @"5px",
                                                                   @"position": @"absolute",
                                                                   @"z-index": @"300",
                                                                   @"transition-delay": @"0s",
                                                                   @"transition-duration": @"0.35s",
                                                                   @"transition-property": @"all",
                                                                   @"transition-timing-function": @"ease",
                                                                   }
                                                            size:CGSizeMake(14,14)],

    smallMixedDisabledImage = [CPImage imageWithCSSDictionary:@{
                                                                @"border-color": A3ColorInactiveDarkBorder,
                                                                @"border-style": @"solid",
                                                                @"border-width": @"1px",
                                                                @"border-radius": @"2px",
                                                                @"box-sizing": @"border-box",
                                                                @"background-color": A3ColorBackground,
                                                                @"transition-delay": @"0s",
                                                                @"transition-duration": @"0.35s",
                                                                @"transition-property": @"all",
                                                                @"transition-timing-function": @"ease"
                                                                }
                                             beforeDictionary:nil
                                              afterDictionary:@{
                                                                @"background-color": A3ColorInactiveDarkBorder,
                                                                @"width": @"8px",
                                                                @"height": @"2px",
                                                                @"box-sizing": @"border-box",
                                                                @"border-style": @"none",
                                                                @"content": @"''",
                                                                @"left": @"2px",
                                                                @"top": @"5px",
                                                                @"position": @"absolute",
                                                                @"z-index": @"300",
                                                                @"transition-delay": @"0s",
                                                                @"transition-duration": @"0.35s",
                                                                @"transition-property": @"all",
                                                                @"transition-timing-function": @"ease",
                                                                }
                                                         size:CGSizeMake(14,14)],

    smallMixedImage = [CPImage imageWithCSSDictionary:@{
                                                        @"border-color": A3ColorActiveBorder,
                                                        @"border-style": @"solid",
                                                        @"border-width": @"1px",
                                                        @"border-radius": @"2px",
                                                        @"box-sizing": @"border-box",
                                                        @"background-color": A3ColorBackgroundWhite,
                                                        @"transition-delay": @"0s",
                                                        @"transition-duration": @"0.35s",
                                                        @"transition-property": @"all",
                                                        @"transition-timing-function": @"ease"
                                                        }
                                     beforeDictionary:nil
                                      afterDictionary:@{
                                                        @"background-color": @"A3ColorBorderBlue",
                                                        @"width": @"8px",
                                                        @"height": @"2px",
                                                        @"box-sizing": @"border-box",
                                                        @"border-style": @"none",
                                                        @"content": @"''",
                                                        @"left": @"2px",
                                                        @"top": @"5px",
                                                        @"position": @"absolute",
                                                        @"z-index": @"300",
                                                        @"transition-delay": @"0s",
                                                        @"transition-duration": @"0.35s",
                                                        @"transition-property": @"all",
                                                        @"transition-timing-function": @"ease",
                                                        }
                                                 size:CGSizeMake(14,14)],

    smallMixedImageNotKey = [CPImage imageWithCSSDictionary:@{
                                                              @"border-color": A3ColorActiveBorder,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"2px",
                                                              @"box-sizing": @"border-box",
                                                              @"background-color": A3ColorBackgroundWhite,
                                                              @"transition-delay": @"0s",
                                                              @"transition-duration": @"0.35s",
                                                              @"transition-property": @"all",
                                                              @"transition-timing-function": @"ease"
                                                              }
                                           beforeDictionary:nil
                                            afterDictionary:@{
                                                              @"background-color": A3ColorNotKeyDarkBorder,
                                                              @"width": @"8px",
                                                              @"height": @"2px",
                                                              @"box-sizing": @"border-box",
                                                              @"border-style": @"none",
                                                              @"content": @"''",
                                                              @"left": @"2px",
                                                              @"top": @"5px",
                                                              @"position": @"absolute",
                                                              @"z-index": @"300",
                                                              @"transition-delay": @"0s",
                                                              @"transition-duration": @"0.35s",
                                                              @"transition-property": @"all",
                                                              @"transition-timing-function": @"ease",
                                                              }
                                                       size:CGSizeMake(14,14)],

    // Mini

    miniMixedHighlightedImage = [CPImage imageWithCSSDictionary:@{
                                                                  @"border-color": A3ColorActiveBorder,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"2px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"background-color": A3ColorBackgroundHighlighted,
                                                                  @"transition-delay": @"0s",
                                                                  @"transition-duration": @"0.35s",
                                                                  @"transition-property": @"all",
                                                                  @"transition-timing-function": @"ease"
                                                                  }
                                               beforeDictionary:nil
                                                afterDictionary:@{
                                                                  @"background-color": @"A3ColorBorderBlue",
                                                                  @"width": @"6px",
                                                                  @"height": @"2px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"border-style": @"none",
                                                                  @"content": @"''",
                                                                  @"left": @"2px",
                                                                  @"top": @"4px",
                                                                  @"position": @"absolute",
                                                                  @"z-index": @"300",
                                                                  @"transition-delay": @"0s",
                                                                  @"transition-duration": @"0.35s",
                                                                  @"transition-property": @"all",
                                                                  @"transition-timing-function": @"ease",
                                                                  }
                                                           size:CGSizeMake(12,12)],

    miniMixedDisabledImage = [CPImage imageWithCSSDictionary:@{
                                                               @"border-color": A3ColorInactiveDarkBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"2px",
                                                               @"box-sizing": @"border-box",
                                                               @"background-color": A3ColorBackground,
                                                               @"transition-delay": @"0s",
                                                               @"transition-duration": @"0.35s",
                                                               @"transition-property": @"all",
                                                               @"transition-timing-function": @"ease"
                                                               }
                                            beforeDictionary:nil
                                             afterDictionary:@{
                                                               @"background-color": A3ColorInactiveDarkBorder,
                                                               @"width": @"6px",
                                                               @"height": @"2px",
                                                               @"box-sizing": @"border-box",
                                                               @"border-style": @"none",
                                                               @"content": @"''",
                                                               @"left": @"2px",
                                                               @"top": @"4px",
                                                               @"position": @"absolute",
                                                               @"z-index": @"300",
                                                               @"transition-delay": @"0s",
                                                               @"transition-duration": @"0.35s",
                                                               @"transition-property": @"all",
                                                               @"transition-timing-function": @"ease",
                                                               }
                                                        size:CGSizeMake(12,12)],

    miniMixedImage = [CPImage imageWithCSSDictionary:@{
                                                       @"border-color": A3ColorActiveBorder,
                                                       @"border-style": @"solid",
                                                       @"border-width": @"1px",
                                                       @"border-radius": @"2px",
                                                       @"box-sizing": @"border-box",
                                                       @"background-color": A3ColorBackgroundWhite,
                                                       @"transition-delay": @"0s",
                                                       @"transition-duration": @"0.35s",
                                                       @"transition-property": @"all",
                                                       @"transition-timing-function": @"ease"
                                                       }
                                    beforeDictionary:nil
                                     afterDictionary:@{
                                                       @"background-color": @"A3ColorBorderBlue",
                                                       @"width": @"6px",
                                                       @"height": @"2px",
                                                       @"box-sizing": @"border-box",
                                                       @"border-style": @"none",
                                                       @"content": @"''",
                                                       @"left": @"2px",
                                                       @"top": @"4px",
                                                       @"position": @"absolute",
                                                       @"z-index": @"300",
                                                       @"transition-delay": @"0s",
                                                       @"transition-duration": @"0.35s",
                                                       @"transition-property": @"all",
                                                       @"transition-timing-function": @"ease",
                                                       }
                                                size:CGSizeMake(12,12)],

    miniMixedImageNotKey = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorActiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"transition-delay": @"0s",
                                                             @"transition-duration": @"0.35s",
                                                             @"transition-property": @"all",
                                                             @"transition-timing-function": @"ease"
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             @"background-color": A3ColorNotKeyDarkBorder,
                                                             @"width": @"6px",
                                                             @"height": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"border-style": @"none",
                                                             @"content": @"''",
                                                             @"left": @"2px",
                                                             @"top": @"4px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300",
                                                             @"transition-delay": @"0s",
                                                             @"transition-duration": @"0.35s",
                                                             @"transition-property": @"all",
                                                             @"transition-timing-function": @"ease",
                                                             }
                                                      size:CGSizeMake(12,12)],

    themeValues =
    [
     [@"image",          mixedImage,                    [CPButtonStateMixed, CPThemeStateKeyWindow]],
     [@"image",          mixedImageNotKey,              CPButtonStateMixed],
     [@"image",          mixedHighlightedImage,         [CPButtonStateMixed, CPThemeStateHighlighted, CPThemeStateKeyWindow]],
     [@"image",          mixedDisabledImage,            [CPButtonStateMixed, CPThemeStateDisabled]],
     [@"image",          mixedDisabledImage,            [CPButtonStateMixed, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"image-offset",   3,                             CPButtonStateMixed], // was CPCheckBoxImageOffset

     // Small
     [@"image",          smallMixedImage,               [CPThemeStateControlSizeSmall, CPButtonStateMixed, CPThemeStateKeyWindow]],
     [@"image",          smallMixedImageNotKey,         [CPThemeStateControlSizeSmall, CPButtonStateMixed]],
     [@"image",          smallMixedHighlightedImage,    [CPThemeStateControlSizeSmall, CPButtonStateMixed, CPThemeStateHighlighted, CPThemeStateKeyWindow]],
     [@"image",          smallMixedDisabledImage,       [CPThemeStateControlSizeSmall, CPButtonStateMixed, CPThemeStateDisabled]],
     [@"image",          smallMixedDisabledImage,       [CPThemeStateControlSizeSmall, CPButtonStateMixed, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"image-offset",   4,                             [CPThemeStateControlSizeSmall, CPButtonStateMixed]], // was CPCheckBoxImageOffset

     // Mini
     [@"image",          miniMixedImage,                [CPThemeStateControlSizeMini, CPButtonStateMixed, CPThemeStateKeyWindow]],
     [@"image",          miniMixedImageNotKey,          [CPThemeStateControlSizeMini, CPButtonStateMixed]],
     [@"image",          miniMixedHighlightedImage,     [CPThemeStateControlSizeMini, CPButtonStateMixed, CPThemeStateHighlighted, CPThemeStateKeyWindow]],
     [@"image",          miniMixedDisabledImage,        [CPThemeStateControlSizeMini, CPButtonStateMixed, CPThemeStateDisabled]],
     [@"image",          miniMixedDisabledImage,        [CPThemeStateControlSizeMini, CPButtonStateMixed, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"image-offset",   2,                             [CPThemeStateControlSizeMini, CPButtonStateMixed]], // was CPCheckBoxImageOffset

     [@"max-size",       CGSizeMake(-1.0, -1.0)] // FIXME: Inutile ?
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

    // left
    leftBezelColor = [CPColor colorWithCSSDictionary:@{
                                                       @"display": @"table-cell",
                                                       @"background-color": A3ColorBackgroundWhite,
                                                       @"border-color": A3ColorBorderDark,
                                                       @"border-style": @"solid",
                                                       @"border-top-width": @"1px",
                                                       @"border-right-width": @"1px",
                                                       @"border-bottom-width": @"1px",
                                                       @"border-left-width": @"1px",
                                                       @"border-top-left-radius": @"3px",
                                                       @"border-bottom-left-radius": @"3px",
                                                       @"box-sizing": @"border-box"
                                                       }],

    inactiveLeftBezelColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackgroundInactive,
                                                               @"border-color": A3ColorBorderLight,
                                                               @"border-style": @"solid",
                                                               @"border-top-width": @"1px",
                                                               @"border-right-width": @"1px",
                                                               @"border-bottom-width": @"1px",
                                                               @"border-left-width": @"1px",
                                                               @"border-top-left-radius": @"3px",
                                                               @"border-bottom-left-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }],

    inactiveHighlightedLeftBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                          @"background-color": A3ColorBackgroundHighlighted,
                                                                          @"border-color": A3ColorBorderLight,
                                                                          @"border-style": @"solid",
                                                                          @"border-top-width": @"1px",
                                                                          @"border-right-width": @"1px",
                                                                          @"border-bottom-width": @"1px",
                                                                          @"border-left-width": @"1px",
                                                                          @"border-top-left-radius": @"3px",
                                                                          @"border-bottom-left-radius": @"3px",
                                                                          @"box-sizing": @"border-box"
                                                                          }],

    pushedLeftBezelColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundHighlighted,
                                                             @"border-color": A3ColorBorderDark,
                                                             @"border-style": @"solid",
                                                             @"border-top-width": @"1px",
                                                             @"border-right-width": @"1px",
                                                             @"border-bottom-width": @"1px",
                                                             @"border-left-width": @"1px",
                                                             @"border-top-left-radius": @"3px",
                                                             @"border-bottom-left-radius": @"3px",
                                                             @"box-sizing": @"border-box"
                                                             }],

    leftHighlightedBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": @"A3ColorBorderBlue",
                                                                  @"border-color": @"A3ColorBorderBlue",
                                                                  @"border-style": @"solid",
                                                                  @"border-top-width": @"1px",
                                                                  @"border-right-width": @"1px",
                                                                  @"border-bottom-width": @"1px",
                                                                  @"border-left-width": @"1px",
                                                                  @"border-top-left-radius": @"3px",
                                                                  @"border-bottom-left-radius": @"3px",
                                                                  @"box-sizing": @"border-box"
                                                                  }],

    pushedHighlightedLeftBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                        @"background-color": A3ColorBorderBlueHighlighted,
                                                                        @"border-color": A3ColorBorderBlueHighlighted,
                                                                        @"border-style": @"solid",
                                                                        @"border-top-width": @"1px",
                                                                        @"border-right-width": @"1px",
                                                                        @"border-bottom-width": @"1px",
                                                                        @"border-left-width": @"1px",
                                                                        @"border-top-left-radius": @"3px",
                                                                        @"border-bottom-left-radius": @"3px",
                                                                        @"box-sizing": @"border-box"
                                                                        }],

    // center
    centerBezelColor = [CPColor colorWithCSSDictionary:@{
                                                         @"display": @"table-cell",
                                                         @"background-color": A3ColorBackgroundWhite,
                                                         @"border-color": A3ColorBorderDark,
                                                         @"border-style": @"solid",
                                                         @"border-top-width": @"1px",
                                                         @"border-right-width": @"1px",
                                                         @"border-bottom-width": @"1px",
                                                         @"border-left-width": @"1px",
                                                         @"box-sizing": @"border-box"
                                                         }],

    inactiveCenterBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBackgroundInactive,
                                                                 @"border-color": A3ColorBorderLight,
                                                                 @"border-style": @"solid",
                                                                 @"border-top-width": @"1px",
                                                                 @"border-right-width": @"1px",
                                                                 @"border-bottom-width": @"1px",
                                                                 @"border-left-width": @"1px",
                                                                 @"box-sizing": @"border-box"
                                                                 }],

    inactiveHighlightedCenterBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                            @"background-color": A3ColorBackgroundHighlighted,
                                                                            @"border-color": A3ColorBorderLight,
                                                                            @"border-style": @"solid",
                                                                            @"border-top-width": @"1px",
                                                                            @"border-right-width": @"1px",
                                                                            @"border-bottom-width": @"1px",
                                                                            @"border-left-width": @"1px",
                                                                            @"box-sizing": @"border-box"
                                                                            }],

    pushedCenterBezelColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackgroundHighlighted,
                                                               @"border-color": A3ColorBorderDark,
                                                               @"border-style": @"solid",
                                                               @"border-top-width": @"1px",
                                                               @"border-right-width": @"1px",
                                                               @"border-bottom-width": @"1px",
                                                               @"border-left-width": @"1px",
                                                               @"box-sizing": @"border-box"
                                                               }],

    centerHighlightedBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": @"A3ColorBorderBlue",
                                                                    @"border-color": @"A3ColorBorderBlue",
                                                                    @"border-style": @"solid",
                                                                    @"border-top-width": @"1px",
                                                                    @"border-right-width": @"1px",
                                                                    @"border-bottom-width": @"1px",
                                                                    @"border-left-width": @"1px",
                                                                    @"box-sizing": @"border-box"
                                                                    }],

    pushedHighlightedCenterBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                          @"background-color": A3ColorBorderBlueHighlighted,
                                                                          @"border-color": A3ColorBorderBlueHighlighted,
                                                                          @"border-style": @"solid",
                                                                          @"border-top-width": @"1px",
                                                                          @"border-right-width": @"1px",
                                                                          @"border-bottom-width": @"1px",
                                                                          @"border-left-width": @"1px",
                                                                          @"box-sizing": @"border-box"
                                                                          }],

    // right
    rightBezelColor = [CPColor colorWithCSSDictionary:@{
                                                        @"display": @"table-cell",
                                                        @"background-color": A3ColorBackgroundWhite,
                                                        @"border-color": A3ColorBorderDark,
                                                        @"border-style": @"solid",
                                                        @"border-top-width": @"1px",
                                                        @"border-right-width": @"1px",
                                                        @"border-bottom-width": @"1px",
                                                        @"border-left-width": @"1px",
                                                        @"border-top-right-radius": @"3px",
                                                        @"border-bottom-right-radius": @"3px",
                                                        @"box-sizing": @"border-box"
                                                        }],

    inactiveRightBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                @"background-color": A3ColorBackgroundInactive,
                                                                @"border-color": A3ColorBorderLight,
                                                                @"border-style": @"solid",
                                                                @"border-top-width": @"1px",
                                                                @"border-right-width": @"1px",
                                                                @"border-bottom-width": @"1px",
                                                                @"border-left-width": @"1px",
                                                                @"border-top-right-radius": @"3px",
                                                                @"border-bottom-right-radius": @"3px",
                                                                @"box-sizing": @"border-box"
                                                                }],

    inactiveHighlightedRightBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                           @"background-color": A3ColorBackgroundHighlighted,
                                                                           @"border-color": A3ColorBorderLight,
                                                                           @"border-style": @"solid",
                                                                           @"border-top-width": @"1px",
                                                                           @"border-right-width": @"1px",
                                                                           @"border-bottom-width": @"1px",
                                                                           @"border-left-width": @"1px",
                                                                           @"border-top-right-radius": @"3px",
                                                                           @"border-bottom-right-radius": @"3px",
                                                                           @"box-sizing": @"border-box"
                                                                           }],

    pushedRightBezelColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": A3ColorBackgroundHighlighted,
                                                              @"border-color": A3ColorBorderDark,
                                                              @"border-style": @"solid",
                                                              @"border-top-width": @"1px",
                                                              @"border-right-width": @"1px",
                                                              @"border-bottom-width": @"1px",
                                                              @"border-left-width": @"1px",
                                                              @"border-top-right-radius": @"3px",
                                                              @"border-bottom-right-radius": @"3px",
                                                              @"box-sizing": @"border-box"
                                                              }],

    rightHighlightedBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                   @"background-color": @"A3ColorBorderBlue",
                                                                   @"border-color": @"A3ColorBorderBlue",
                                                                   @"border-style": @"solid",
                                                                   @"border-top-width": @"1px",
                                                                   @"border-right-width": @"1px",
                                                                   @"border-bottom-width": @"1px",
                                                                   @"border-left-width": @"1px",
                                                                   @"border-top-right-radius": @"3px",
                                                                   @"border-bottom-right-radius": @"3px",
                                                                   @"box-sizing": @"border-box"
                                                                   }],

    pushedHighlightedRightBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                         @"background-color": A3ColorBorderBlueHighlighted,
                                                                         @"border-color": A3ColorBorderBlueHighlighted,
                                                                         @"border-style": @"solid",
                                                                         @"border-top-width": @"1px",
                                                                         @"border-right-width": @"1px",
                                                                         @"border-bottom-width": @"1px",
                                                                         @"border-left-width": @"1px",
                                                                         @"border-top-right-radius": @"3px",
                                                                         @"border-bottom-right-radius": @"3px",
                                                                         @"box-sizing": @"border-box"
                                                                         }],

    smallCenterBezelColor = PatternColor("segmented-control-bezel-center.png", 1.0, 20.0),
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
    smallPushedHighlightedRightBezelColor = PatternColor("segmented-control-bezel-pushed-highlighted-right.png", 4.0, 20.0),

    miniCenterBezelColor = PatternColor("segmented-control-bezel-center.png", 1.0, 15.0),
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
     [@"center-segment-bezel-color",     centerHighlightedBezelColor,            [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"center-segment-bezel-color",     pushedCenterBezelColor,                 CPThemeStateSelected],
     [@"center-segment-bezel-color",     pushedCenterBezelColor,                 CPThemeStateHighlighted],
     [@"center-segment-bezel-color",     pushedHighlightedCenterBezelColor,      [CPThemeStateHighlighted, CPThemeStateSelected]],

//     [@"divider-bezel-color",            dividerBezelColor,                      CPThemeStateNormal],
//     [@"divider-bezel-color",            inactiveDividerBezelColor,              CPThemeStateDisabled],
//     [@"divider-bezel-color",            inactiveHighlightedDividerBezelColor,   [CPThemeStateSelected, CPThemeStateDisabled]],
//     [@"divider-bezel-color",            dividerHighlightedBezelColor,           CPThemeStateSelected],

     [@"left-segment-bezel-color",       leftBezelColor,                         CPThemeStateNormal],
     [@"left-segment-bezel-color",       inactiveLeftBezelColor,                 CPThemeStateDisabled],
     [@"left-segment-bezel-color",       inactiveHighlightedLeftBezelColor,      [CPThemeStateSelected, CPThemeStateDisabled]],
     [@"left-segment-bezel-color",       leftHighlightedBezelColor,              [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"left-segment-bezel-color",       pushedLeftBezelColor,                   CPThemeStateSelected],
     [@"left-segment-bezel-color",       pushedLeftBezelColor,                   CPThemeStateHighlighted],
     [@"left-segment-bezel-color",       pushedHighlightedLeftBezelColor,        [CPThemeStateHighlighted, CPThemeStateSelected]],

     [@"right-segment-bezel-color",      rightBezelColor,                        CPThemeStateNormal],
     [@"right-segment-bezel-color",      inactiveRightBezelColor,                CPThemeStateDisabled],
     [@"right-segment-bezel-color",      inactiveHighlightedRightBezelColor,     [CPThemeStateSelected, CPThemeStateDisabled]],
     [@"right-segment-bezel-color",      rightHighlightedBezelColor,             [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"right-segment-bezel-color",      pushedRightBezelColor,                  CPThemeStateSelected],
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

     [@"content-inset",              CGInsetMake(-2.0, 11.0, 0.0, 12.0)],    // was 0 4 0 4 avec CPThemeStateNormal - (-2.0, 12.0, 0.0, 11.0)
     [@"bezel-inset",                CGInsetMake(0.0, 0.0, 0.0, 0.0)],      // was CPThemeStateNormal

     [@"min-size",                   CGSizeMake(-1.0, 21.0)],
     [@"max-size",                   CGSizeMake(-1.0, 21.0)],
     [@"nib2cib-adjustment-frame",   CGRectMake(2.0, -2.0, -4.0, -3.0)],       // was CGRectMake(2.0, 2.0, -4.0, 1.0) - (0.0, 0.0, 0.0, 0.0)

     [@"min-size",                   CGSizeMake(-1.0, 20.0),                             CPThemeStateControlSizeSmall],
     [@"max-size",                   CGSizeMake(-1.0, 20.0),                             CPThemeStateControlSizeSmall],
     [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 0.0, -5.0, 0.0),                    CPThemeStateControlSizeSmall],

     [@"min-size",                   CGSizeMake(-1.0, 15.0),                             CPThemeStateControlSizeMini],
     [@"max-size",                   CGSizeMake(-1.0, 15.0),                             CPThemeStateControlSizeMini],
     [@"nib2cib-adjustment-frame",   CGRectMake(1.0, 0.0, -2.0, 0.0),                    CPThemeStateControlSizeMini],

     [@"font",               [CPFont systemFontOfSize:13.0]],
     [@"text-color",         A3CPColorActiveText],
     [@"text-color",         A3CPColorInactiveText,                           CPThemeStateDisabled],

     // The "default" button state is the same theme color as the "selected" segmented control state, so we can use
     // the same text theme values.
     [@"text-color",         A3CPColorDefaultText,                                   [CPThemeStateSelected, CPThemeStateKeyWindow]],
//     [@"text-color",         A3CPColorDefaultText,                           [CPThemeStateDisabled, CPThemeStateSelected]],
     [@"vertical-alignment",    CPCenterVerticalTextAlignment], // CPCenterVerticalTextAlignment
//     [@"text-shadow-color",  regularTextShadowColor],
//     [@"text-shadow-color",  regularDisabledTextShadowColor,                     CPThemeStateDisabled],
//     [@"text-shadow-color",  defaultDisabledTextShadowColor,                     [CPThemeStateDisabled, CPThemeStateSelected]],
//     [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:0.0 alpha:0.2],   CPThemeStateSelected],
//     [@"text-shadow-offset", CGSizeMake(0.0, 1.0)],
//     [@"text-shadow-offset", CGSizeMake(0.0, 1.0),                               CPThemeStateSelected],
//     [@"text-shadow-offset", CGSizeMake(0.0, 0.0),                               [CPThemeStateSelected, CPThemeStateDisabled]],
     [@"line-break-mode",    CPLineBreakByTruncatingTail],

     [@"divider-thickness",  1.0] // Used for leftmost and rightmost supplementary space in CSS themes
     ];

    [self registerThemeValues:themedSegmentedControlValues forView:segmentedControl];

    return segmentedControl;
}

#pragma mark -
#pragma mark Sliders

+ (CPSlider)makeHorizontalSlider
{
    return [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 19.0)];
}

+ (CPSlider)themedHorizontalSlider
{
    var slider = [self makeHorizontalSlider],

    knobCssColor = [CPColor colorWithCSSDictionary:@{
                                                     @"border-color": A3ColorActiveBorder,
                                                     @"border-style": @"solid",
                                                     @"border-width": @"1px",
                                                     @"border-radius": @"50%",
                                                     @"box-sizing": @"border-box",
                                                     @"background-color": A3ColorBackgroundWhite
                                                     }],

    disabledKnobCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"border-color": A3ColorBorderLight,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorSliderDisabledKnob
                                                             }],

    highlightedKnobCssColor = [CPColor colorWithCSSDictionary:@{
                                                                @"border-color": A3ColorBorderDark,
                                                                @"border-style": @"solid",
                                                                @"border-width": @"1px",
                                                                @"border-radius": @"50%",
                                                                @"box-sizing": @"border-box",
                                                                @"background-color": A3ColorBackground
                                                                }],

    trackCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"background-color": A3ColorActiveBorder
                                                      }],

    disabledTrackCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": A3ColorInactiveBorder
                                                              }],

    leftTrackCssColor = [CPColor colorWithCSSDictionary:@{
                                                          @"background-color": @"A3ColorBorderBlue"
                                                          }],

    leftDisabledTrackCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": A3ColorInactiveBorder
                                                                  }],

    leftTrackNotKeyCssColor = [CPColor colorWithCSSDictionary:@{
                                                                @"background-color": A3ColorSliderDisabledTrack
                                                                }],

    knobDownCssColor = [CPColor colorWithCSSDictionary:@{}
                                      beforeDictionary:@{
                                                         @"border-color": A3ColorActiveBorder,
                                                         @"border-style": @"solid",
                                                         @"border-top-width": @"1px",
                                                         @"border-left-width": @"1px",
                                                         @"border-right-width": @"1px",
                                                         @"border-bottom-width": @"0px",
                                                         @"border-top-left-radius": @"4px",
                                                         @"border-top-right-radius": @"4px",
                                                         @"box-sizing": @"border-box",
                                                         @"background-color": A3ColorBackgroundWhite,
                                                         @"width": @"15px",
                                                         @"height": @"11px",
                                                         @"left": @"0px",
                                                         @"top": @"0px",
                                                         @"position": @"absolute",
                                                         @"z-index": @"400",
                                                         @"content": @"''"
                                                         }
                                       afterDictionary:@{
                                                         @"border-color": A3ColorActiveBorder,
                                                         @"background-color": A3ColorBackgroundWhite,
                                                         @"width": @"11px",
                                                         @"height": @"11px",
                                                         @"box-sizing": @"border-box",
                                                         @"border-style": @"solid",
                                                         @"content": @"''",
                                                         @"left": @"2px",
                                                         @"top": @"6px",
                                                         @"position": @"absolute",
                                                         @"z-index": @"300",
                                                         @"transform": @"rotate(45deg)",
                                                         @"border-bottom-width": @"1px",
                                                         @"border-right-width": @"1px",
                                                         @"border-top-width": @"0px",
                                                         @"border-left-width": @"0px"
                                                         }],

    highlightedKnobDownCssColor = [CPColor colorWithCSSDictionary:@{}
                                                 beforeDictionary:@{
                                                                    @"border-color": A3ColorBorderDark,
                                                                    @"border-style": @"solid",
                                                                    @"border-top-width": @"1px",
                                                                    @"border-left-width": @"1px",
                                                                    @"border-right-width": @"1px",
                                                                    @"border-bottom-width": @"0px",
                                                                    @"border-top-left-radius": @"4px",
                                                                    @"border-top-right-radius": @"4px",
                                                                    @"box-sizing": @"border-box",
                                                                    @"background-color": A3ColorBackground,
                                                                    @"width": @"15px",
                                                                    @"height": @"11px",
                                                                    @"left": @"0px",
                                                                    @"top": @"0px",
                                                                    @"position": @"absolute",
                                                                    @"z-index": @"400",
                                                                    @"content": @"''"
                                                                    }
                                                  afterDictionary:@{
                                                                    @"border-color": A3ColorBorderDark,
                                                                    @"background-color": A3ColorBackground,
                                                                    @"width": @"11px",
                                                                    @"height": @"11px",
                                                                    @"box-sizing": @"border-box",
                                                                    @"border-style": @"solid",
                                                                    @"content": @"''",
                                                                    @"left": @"2px",
                                                                    @"top": @"6px",
                                                                    @"position": @"absolute",
                                                                    @"z-index": @"300",
                                                                    @"transform": @"rotate(45deg)",
                                                                    @"border-bottom-width": @"1px",
                                                                    @"border-right-width": @"1px",
                                                                    @"border-top-width": @"0px",
                                                                    @"border-left-width": @"0px"
                                                                    }],

    disabledKnobDownCssColor = [CPColor colorWithCSSDictionary:@{}
                                              beforeDictionary:@{
                                                                 @"border-color": A3ColorBorderLight,
                                                                 @"border-style": @"solid",
                                                                 @"border-top-width": @"1px",
                                                                 @"border-left-width": @"1px",
                                                                 @"border-right-width": @"1px",
                                                                 @"border-bottom-width": @"0px",
                                                                 @"border-top-left-radius": @"4px",
                                                                 @"border-top-right-radius": @"4px",
                                                                 @"box-sizing": @"border-box",
                                                                 @"background-color": A3ColorSliderDisabledKnob,
                                                                 @"width": @"15px",
                                                                 @"height": @"11px",
                                                                 @"left": @"0px",
                                                                 @"top": @"0px",
                                                                 @"position": @"absolute",
                                                                 @"z-index": @"400",
                                                                 @"content": @"''"
                                                                 }
                                               afterDictionary:@{
                                                                 @"border-color": A3ColorBorderLight,
                                                                 @"background-color": A3ColorSliderDisabledKnob,
                                                                 @"width": @"11px",
                                                                 @"height": @"11px",
                                                                 @"box-sizing": @"border-box",
                                                                 @"border-style": @"solid",
                                                                 @"content": @"''",
                                                                 @"left": @"2px",
                                                                 @"top": @"6px",
                                                                 @"position": @"absolute",
                                                                 @"z-index": @"300",
                                                                 @"transform": @"rotate(45deg)",
                                                                 @"border-bottom-width": @"1px",
                                                                 @"border-right-width": @"1px",
                                                                 @"border-top-width": @"0px",
                                                                 @"border-left-width": @"0px"
                                                                 }],

    knobUpCssColor = [CPColor colorWithCSSDictionary:@{}
                                    beforeDictionary:@{
                                                       @"border-color": A3ColorActiveBorder,
                                                       @"border-style": @"solid",
                                                       @"border-top-width": @"0px",
                                                       @"border-left-width": @"1px",
                                                       @"border-right-width": @"1px",
                                                       @"border-bottom-width": @"1px",
                                                       @"border-bottom-left-radius": @"4px",
                                                       @"border-bottom-right-radius": @"4px",
                                                       @"box-sizing": @"border-box",
                                                       @"background-color": A3ColorBackgroundWhite,
                                                       @"width": @"15px",
                                                       @"height": @"11px",
                                                       @"left": @"0px",
                                                       @"top": @"8px",
                                                       @"position": @"absolute",
                                                       @"z-index": @"400",
                                                       @"content": @"''"
                                                       }
                                     afterDictionary:@{
                                                       @"border-color": A3ColorActiveBorder,
                                                       @"background-color": A3ColorBackgroundWhite,
                                                       @"width": @"11px",
                                                       @"height": @"11px",
                                                       @"box-sizing": @"border-box",
                                                       @"border-style": @"solid",
                                                       @"content": @"''",
                                                       @"left": @"2px",
                                                       @"top": @"2px",
                                                       @"position": @"absolute",
                                                       @"z-index": @"300",
                                                       @"transform": @"rotate(45deg)",
                                                       @"border-bottom-width": @"0px",
                                                       @"border-right-width": @"0px",
                                                       @"border-top-width": @"1px",
                                                       @"border-left-width": @"1px"
                                                       }],

    highlightedKnobUpCssColor = [CPColor colorWithCSSDictionary:@{}
                                               beforeDictionary:@{
                                                                  @"border-color": A3ColorBorderDark,
                                                                  @"border-style": @"solid",
                                                                  @"border-top-width": @"0px",
                                                                  @"border-left-width": @"1px",
                                                                  @"border-right-width": @"1px",
                                                                  @"border-bottom-width": @"1px",
                                                                  @"border-bottom-left-radius": @"4px",
                                                                  @"border-bottom-right-radius": @"4px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"background-color": A3ColorBackground,
                                                                  @"width": @"15px",
                                                                  @"height": @"11px",
                                                                  @"left": @"0px",
                                                                  @"top": @"8px",
                                                                  @"position": @"absolute",
                                                                  @"z-index": @"400",
                                                                  @"content": @"''"
                                                                  }
                                                afterDictionary:@{
                                                                  @"border-color": A3ColorBorderDark,
                                                                  @"background-color": A3ColorBackground,
                                                                  @"width": @"11px",
                                                                  @"height": @"11px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"border-style": @"solid",
                                                                  @"content": @"''",
                                                                  @"left": @"2px",
                                                                  @"top": @"2px",
                                                                  @"position": @"absolute",
                                                                  @"z-index": @"300",
                                                                  @"transform": @"rotate(45deg)",
                                                                  @"border-bottom-width": @"0px",
                                                                  @"border-right-width": @"0px",
                                                                  @"border-top-width": @"1px",
                                                                  @"border-left-width": @"1px"
                                                                  }],

    disabledKnobUpCssColor = [CPColor colorWithCSSDictionary:@{}
                                            beforeDictionary:@{
                                                               @"border-color": A3ColorBorderLight,
                                                               @"border-style": @"solid",
                                                               @"border-top-width": @"0px",
                                                               @"border-left-width": @"1px",
                                                               @"border-right-width": @"1px",
                                                               @"border-bottom-width": @"1px",
                                                               @"border-bottom-left-radius": @"4px",
                                                               @"border-bottom-right-radius": @"4px",
                                                               @"box-sizing": @"border-box",
                                                               @"background-color": A3ColorSliderDisabledKnob,
                                                               @"width": @"15px",
                                                               @"height": @"11px",
                                                               @"left": @"0px",
                                                               @"top": @"8px",
                                                               @"position": @"absolute",
                                                               @"z-index": @"400",
                                                               @"content": @"''"
                                                               }
                                             afterDictionary:@{
                                                               @"border-color": A3ColorBorderLight,
                                                               @"background-color": A3ColorSliderDisabledKnob,
                                                               @"width": @"11px",
                                                               @"height": @"11px",
                                                               @"box-sizing": @"border-box",
                                                               @"border-style": @"solid",
                                                               @"content": @"''",
                                                               @"left": @"2px",
                                                               @"top": @"2px",
                                                               @"position": @"absolute",
                                                               @"z-index": @"300",
                                                               @"transform": @"rotate(45deg)",
                                                               @"border-bottom-width": @"0px",
                                                               @"border-right-width": @"0px",
                                                               @"border-top-width": @"1px",
                                                               @"border-left-width": @"1px"
                                                               }],

    // Gobal
    themedHorizontalSliderValues =
    [
     [@"track-width",                   3],
     [@"track-color",                   trackCssColor],
     [@"track-color",                   disabledTrackCssColor,                  CPThemeStateDisabled],

     // Omit those 3 lines if you want a only one color slider
     [@"left-track-color",              leftTrackCssColor,                      CPThemeStateKeyWindow],
     [@"left-track-color",              leftDisabledTrackCssColor,              CPThemeStateDisabled],
     [@"left-track-color",              leftTrackNotKeyCssColor,                CPThemeStateNormal],

     [@"knob-size",                     CGSizeMake(15, 15)],
     [@"knob-offset",                   0],
     [@"knob-color",                    knobCssColor],
     [@"knob-color",                    highlightedKnobCssColor,                CPThemeStateHighlighted],
     [@"knob-color",                    disabledKnobCssColor,                   CPThemeStateDisabled],

     [@"nib2cib-adjustment-frame",      CGRectMake(3.0, -2.0, -6.0, -4.0)], // (3.0, -2.0, -6.0, -4.0)
     [@"direct-nib2cib-adjustment",     YES],
     [@"ib-size",                       17],

     // Ticked slider
     // Same : track-width, track-color, direct-nib2cib-adjustment
     [@"knob-size",                     CGSizeMake(15, 19),                     CPThemeStateTickedSlider],
     [@"knob-offset",                   1,                                      [CPThemeStateTickedSlider, CPThemeStateBelowRightTickedSlider]],
     [@"knob-offset",                   -1,                                     [CPThemeStateTickedSlider, CPThemeStateAboveLeftTickedSlider]],

     [@"knob-color",                    knobDownCssColor,                       [CPThemeStateTickedSlider, CPThemeStateBelowRightTickedSlider]],
     [@"knob-color",                    highlightedKnobDownCssColor,            [CPThemeStateTickedSlider, CPThemeStateBelowRightTickedSlider, CPThemeStateHighlighted]],
     [@"knob-color",                    disabledKnobDownCssColor,               [CPThemeStateTickedSlider, CPThemeStateBelowRightTickedSlider, CPThemeStateDisabled]],

     [@"knob-color",                    knobUpCssColor,                         [CPThemeStateTickedSlider, CPThemeStateAboveLeftTickedSlider]],
     [@"knob-color",                    highlightedKnobUpCssColor,              [CPThemeStateTickedSlider, CPThemeStateAboveLeftTickedSlider, CPThemeStateHighlighted]],
     [@"knob-color",                    disabledKnobUpCssColor,                 [CPThemeStateTickedSlider, CPThemeStateAboveLeftTickedSlider, CPThemeStateDisabled]],

     [@"nib2cib-adjustment-frame",      CGRectMake(3.0, 0.0, -6.0, -2.0),       [CPThemeStateTickedSlider, CPThemeStateAboveLeftTickedSlider]],
     [@"nib2cib-adjustment-frame",      CGRectMake(3.0, -1.0, -6.0, -2.0),      [CPThemeStateTickedSlider, CPThemeStateBelowRightTickedSlider]],
     [@"ib-size",                       22,                                     [CPThemeStateTickedSlider, CPThemeStateAboveLeftTickedSlider]],
     [@"ib-size",                       21,                                     [CPThemeStateTickedSlider, CPThemeStateBelowRightTickedSlider]],
     [@"tick-mark-size",                CGSizeMake(1, 4),                       CPThemeStateTickedSlider],
     [@"tick-mark-margin",              1,                                      CPThemeStateTickedSlider],
     [@"top-margin",                    1,                                      CPThemeStateTickedSlider],
     [@"bottom-margin",                 1,                                      CPThemeStateTickedSlider],

     [@"tick-mark-color",               A3CPColorActiveBorder]
     ];

    [self registerThemeValues:themedHorizontalSliderValues forView:slider];

    return slider;
}

+ (CPSlider)makeVerticalSlider
{
    return [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 19.0, 100.0)];
}

+ (CPSlider)themedVerticalSlider
{
    var slider = [self makeVerticalSlider],

    knobCssColor = [CPColor colorWithCSSDictionary:@{
                                                     @"border-color": A3ColorActiveBorder,
                                                     @"border-style": @"solid",
                                                     @"border-width": @"1px",
                                                     @"border-radius": @"50%",
                                                     @"box-sizing": @"border-box",
                                                     @"background-color": A3ColorBackgroundWhite
                                                     }],

    disabledKnobCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"border-color": A3ColorBorderLight,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorSliderDisabledKnob
                                                             }],

    highlightedKnobCssColor = [CPColor colorWithCSSDictionary:@{
                                                                @"border-color": A3ColorBorderDark,
                                                                @"border-style": @"solid",
                                                                @"border-width": @"1px",
                                                                @"border-radius": @"50%",
                                                                @"box-sizing": @"border-box",
                                                                @"background-color": A3ColorBackground
                                                                }],

    trackCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"background-color": A3ColorActiveBorder
                                                      }],

    disabledTrackCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": A3ColorInactiveBorder
                                                              }],

    leftTrackCssColor = [CPColor colorWithCSSDictionary:@{
                                                          @"background-color": @"A3ColorBorderBlue" // was @"rgb(0,122,255)"
                                                          }],

    leftDisabledTrackCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": A3ColorInactiveBorder // was @"rgb(125,186,253)"
                                                                  }],

    leftTrackNotKeyCssColor = [CPColor colorWithCSSDictionary:@{
                                                                @"background-color": A3ColorSliderDisabledTrack
                                                                }],

    knobRightCssColor = [CPColor colorWithCSSDictionary:@{}
                                       beforeDictionary:@{
                                                          @"border-color": A3ColorActiveBorder,
                                                          @"border-style": @"solid",
                                                          @"border-top-width": @"1px",
                                                          @"border-left-width": @"1px",
                                                          @"border-right-width": @"0px",
                                                          @"border-bottom-width": @"1px",
                                                          @"border-top-left-radius": @"4px",
                                                          @"border-bottom-left-radius": @"4px",
                                                          @"box-sizing": @"border-box",
                                                          @"background-color": A3ColorBackgroundWhite,
                                                          @"width": @"11px",
                                                          @"height": @"15px",
                                                          @"left": @"0px",
                                                          @"top": @"0px",
                                                          @"position": @"absolute",
                                                          @"z-index": @"400",
                                                          @"content": @"''"
                                                          }
                                        afterDictionary:@{
                                                          @"border-color": A3ColorActiveBorder,
                                                          @"background-color": A3ColorBackgroundWhite,
                                                          @"width": @"11px",
                                                          @"height": @"11px",
                                                          @"box-sizing": @"border-box",
                                                          @"border-style": @"solid",
                                                          @"content": @"''",
                                                          @"left": @"6px",
                                                          @"top": @"2px",
                                                          @"position": @"absolute",
                                                          @"z-index": @"300",
                                                          @"transform": @"rotate(45deg)",
                                                          @"border-bottom-width": @"0px",
                                                          @"border-right-width": @"1px",
                                                          @"border-top-width": @"1px",
                                                          @"border-left-width": @"0px"
                                                          }],

    highlightedKnobRightCssColor = [CPColor colorWithCSSDictionary:@{}
                                                  beforeDictionary:@{
                                                                     @"border-color": A3ColorBorderDark,
                                                                     @"border-style": @"solid",
                                                                     @"border-top-width": @"1px",
                                                                     @"border-left-width": @"1px",
                                                                     @"border-right-width": @"0px",
                                                                     @"border-bottom-width": @"1px",
                                                                     @"border-top-left-radius": @"4px",
                                                                     @"border-bottom-left-radius": @"4px",
                                                                     @"box-sizing": @"border-box",
                                                                     @"background-color": A3ColorBackground,
                                                                     @"width": @"11px",
                                                                     @"height": @"15px",
                                                                     @"left": @"0px",
                                                                     @"top": @"0px",
                                                                     @"position": @"absolute",
                                                                     @"z-index": @"400",
                                                                     @"content": @"''"
                                                                     }
                                                   afterDictionary:@{
                                                                     @"border-color": A3ColorBorderDark,
                                                                     @"background-color": A3ColorBackground,
                                                                     @"width": @"11px",
                                                                     @"height": @"11px",
                                                                     @"box-sizing": @"border-box",
                                                                     @"border-style": @"solid",
                                                                     @"content": @"''",
                                                                     @"left": @"6px",
                                                                     @"top": @"2px",
                                                                     @"position": @"absolute",
                                                                     @"z-index": @"300",
                                                                     @"transform": @"rotate(45deg)",
                                                                     @"border-bottom-width": @"0px",
                                                                     @"border-right-width": @"1px",
                                                                     @"border-top-width": @"1px",
                                                                     @"border-left-width": @"0px"
                                                                     }],

    disabledKnobRightCssColor = [CPColor colorWithCSSDictionary:@{}
                                               beforeDictionary:@{
                                                                  @"border-color": A3ColorBorderLight,
                                                                  @"border-style": @"solid",
                                                                  @"border-top-width": @"1px",
                                                                  @"border-left-width": @"1px",
                                                                  @"border-right-width": @"0px",
                                                                  @"border-bottom-width": @"1px",
                                                                  @"border-top-left-radius": @"4px",
                                                                  @"border-bottom-left-radius": @"4px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"background-color": A3ColorSliderDisabledKnob,
                                                                  @"width": @"11px",
                                                                  @"height": @"15px",
                                                                  @"left": @"0px",
                                                                  @"top": @"0px",
                                                                  @"position": @"absolute",
                                                                  @"z-index": @"400",
                                                                  @"content": @"''"
                                                                  }
                                                afterDictionary:@{
                                                                  @"border-color": A3ColorBorderLight,
                                                                  @"background-color": A3ColorSliderDisabledKnob,
                                                                  @"width": @"11px",
                                                                  @"height": @"11px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"border-style": @"solid",
                                                                  @"content": @"''",
                                                                  @"left": @"6px",
                                                                  @"top": @"2px",
                                                                  @"position": @"absolute",
                                                                  @"z-index": @"300",
                                                                  @"transform": @"rotate(45deg)",
                                                                  @"border-bottom-width": @"0px",
                                                                  @"border-right-width": @"1px",
                                                                  @"border-top-width": @"1px",
                                                                  @"border-left-width": @"0px"
                                                                  }],

    knobLeftCssColor = [CPColor colorWithCSSDictionary:@{
                                                         }
                                      beforeDictionary:@{
                                                         @"border-color": A3ColorActiveBorder,
                                                         @"border-style": @"solid",
                                                         @"border-top-width": @"1px",
                                                         @"border-left-width": @"0px",
                                                         @"border-right-width": @"1px",
                                                         @"border-bottom-width": @"1px",
                                                         @"border-top-right-radius": @"4px",
                                                         @"border-bottom-right-radius": @"4px",
                                                         @"box-sizing": @"border-box",
                                                         @"background-color": A3ColorBackgroundWhite,
                                                         @"width": @"11px",
                                                         @"height": @"15px",
                                                         @"left": @"8px",
                                                         @"top": @"0px",
                                                         @"position": @"absolute",
                                                         @"z-index": @"400",
                                                         @"content": @"''"
                                                         }
                                       afterDictionary:@{
                                                         @"border-color": A3ColorActiveBorder,
                                                         @"background-color": A3ColorBackgroundWhite,
                                                         @"width": @"11px",
                                                         @"height": @"11px",
                                                         @"box-sizing": @"border-box",
                                                         @"border-style": @"solid",
                                                         @"content": @"''",
                                                         @"left": @"2px",
                                                         @"top": @"2px",
                                                         @"position": @"absolute",
                                                         @"z-index": @"300",
                                                         @"transform": @"rotate(45deg)",
                                                         @"border-bottom-width": @"1px",
                                                         @"border-right-width": @"0px",
                                                         @"border-top-width": @"0px",
                                                         @"border-left-width": @"1px"
                                                         }],

    highlightedKnobLeftCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    }
                                                 beforeDictionary:@{
                                                                    @"border-color": A3ColorBorderDark,
                                                                    @"border-style": @"solid",
                                                                    @"border-top-width": @"1px",
                                                                    @"border-left-width": @"0px",
                                                                    @"border-right-width": @"1px",
                                                                    @"border-bottom-width": @"1px",
                                                                    @"border-top-right-radius": @"4px",
                                                                    @"border-bottom-right-radius": @"4px",
                                                                    @"box-sizing": @"border-box",
                                                                    @"background-color": A3ColorBackground,
                                                                    @"width": @"11px",
                                                                    @"height": @"15px",
                                                                    @"left": @"8px",
                                                                    @"top": @"0px",
                                                                    @"position": @"absolute",
                                                                    @"z-index": @"400",
                                                                    @"content": @"''"
                                                                    }
                                                  afterDictionary:@{
                                                                    @"border-color": A3ColorBorderDark,
                                                                    @"background-color": A3ColorBackground,
                                                                    @"width": @"11px",
                                                                    @"height": @"11px",
                                                                    @"box-sizing": @"border-box",
                                                                    @"border-style": @"solid",
                                                                    @"content": @"''",
                                                                    @"left": @"2px",
                                                                    @"top": @"2px",
                                                                    @"position": @"absolute",
                                                                    @"z-index": @"300",
                                                                    @"transform": @"rotate(45deg)",
                                                                    @"border-bottom-width": @"1px",
                                                                    @"border-right-width": @"0px",
                                                                    @"border-top-width": @"0px",
                                                                    @"border-left-width": @"1px"
                                                                    }],

    disabledKnobLeftCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 }
                                              beforeDictionary:@{
                                                                 @"border-color": A3ColorBorderLight,
                                                                 @"border-style": @"solid",
                                                                 @"border-top-width": @"1px",
                                                                 @"border-left-width": @"0px",
                                                                 @"border-right-width": @"1px",
                                                                 @"border-bottom-width": @"1px",
                                                                 @"border-top-right-radius": @"4px",
                                                                 @"border-bottom-right-radius": @"4px",
                                                                 @"box-sizing": @"border-box",
                                                                 @"background-color": A3ColorSliderDisabledKnob,
                                                                 @"width": @"11px",
                                                                 @"height": @"15px",
                                                                 @"left": @"8px",
                                                                 @"top": @"0px",
                                                                 @"position": @"absolute",
                                                                 @"z-index": @"400",
                                                                 @"content": @"''"
                                                                 }
                                               afterDictionary:@{
                                                                 @"border-color": A3ColorBorderLight,
                                                                 @"background-color": A3ColorSliderDisabledKnob,
                                                                 @"width": @"11px",
                                                                 @"height": @"11px",
                                                                 @"box-sizing": @"border-box",
                                                                 @"border-style": @"solid",
                                                                 @"content": @"''",
                                                                 @"left": @"2px",
                                                                 @"top": @"2px",
                                                                 @"position": @"absolute",
                                                                 @"z-index": @"300",
                                                                 @"transform": @"rotate(45deg)",
                                                                 @"border-bottom-width": @"1px",
                                                                 @"border-right-width": @"0px",
                                                                 @"border-top-width": @"0px",
                                                                 @"border-left-width": @"1px"
                                                                 }],

    themedVerticalSliderValues =
    [
     [@"track-width", 3],
     [@"track-color", trackCssColor,            CPThemeStateVertical],
     [@"track-color", disabledTrackCssColor,    [CPThemeStateVertical, CPThemeStateDisabled]],

     // Omit those 3 lines if you want a only one color slider
     [@"left-track-color", leftTrackCssColor,           [CPThemeStateVertical, CPThemeStateKeyWindow]],
     [@"left-track-color", leftDisabledTrackCssColor,   [CPThemeStateVertical, CPThemeStateDisabled]],
     [@"left-track-color", leftDisabledTrackCssColor,   [CPThemeStateVertical, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"left-track-color", leftTrackNotKeyCssColor,     [CPThemeStateVertical, CPThemeStateNormal]],

     [@"knob-size",  CGSizeMake(15, 15),                                        CPThemeStateVertical],
     [@"knob-color", knobCssColor,                                              CPThemeStateVertical],
     [@"knob-color", highlightedKnobCssColor,                                   [CPThemeStateVertical, CPThemeStateHighlighted]],
     [@"knob-color", disabledKnobCssColor,                                      [CPThemeStateVertical, CPThemeStateDisabled]],

     [@"nib2cib-adjustment-frame",      CGRectMake(2.0, -3.0, -4.0, -6.0),      CPThemeStateVertical],  // (2.0, -2.0, -4.0, -4.0)
     [@"direct-nib2cib-adjustment",     YES,                                    CPThemeStateVertical],
     [@"ib-size",                       15,                                     CPThemeStateVertical],

     // Ticked slider
     // Same : track-width, track-color, direct-nib2cib-adjustment
     [@"knob-size",                     CGSizeMake(19, 15),                     [CPThemeStateVertical, CPThemeStateTickedSlider]],
     [@"knob-offset",                   2,                                      [CPThemeStateVertical, CPThemeStateTickedSlider, CPThemeStateBelowRightTickedSlider]],
     [@"knob-offset",                   -3,                                     [CPThemeStateVertical, CPThemeStateTickedSlider, CPThemeStateAboveLeftTickedSlider]],

     [@"knob-color",                    knobRightCssColor,                      [CPThemeStateVertical, CPThemeStateTickedSlider, CPThemeStateBelowRightTickedSlider]],
     [@"knob-color",                    highlightedKnobRightCssColor,           [CPThemeStateVertical, CPThemeStateTickedSlider, CPThemeStateBelowRightTickedSlider, CPThemeStateHighlighted]],
     [@"knob-color",                    disabledKnobRightCssColor,              [CPThemeStateVertical, CPThemeStateTickedSlider, CPThemeStateBelowRightTickedSlider, CPThemeStateDisabled]],

     [@"knob-color",                    knobLeftCssColor,                       [CPThemeStateVertical, CPThemeStateTickedSlider, CPThemeStateAboveLeftTickedSlider]],
     [@"knob-color",                    highlightedKnobLeftCssColor,            [CPThemeStateVertical, CPThemeStateTickedSlider, CPThemeStateAboveLeftTickedSlider, CPThemeStateHighlighted]],
     [@"knob-color",                    disabledKnobLeftCssColor,               [CPThemeStateVertical, CPThemeStateTickedSlider, CPThemeStateAboveLeftTickedSlider, CPThemeStateDisabled]],

     [@"nib2cib-adjustment-frame",      CGRectMake(1.0, -3.0, -3.0, -6.0),      [CPThemeStateVertical, CPThemeStateTickedSlider, CPThemeStateAboveLeftTickedSlider]],
     [@"nib2cib-adjustment-frame",      CGRectMake(-1.0, -3.0, -2.0, -6.0),     [CPThemeStateVertical, CPThemeStateTickedSlider, CPThemeStateBelowRightTickedSlider]],
     [@"ib-size",                       22,                                     [CPThemeStateVertical, CPThemeStateTickedSlider, CPThemeStateBelowRightTickedSlider]],
     [@"ib-size",                       21,                                     [CPThemeStateVertical, CPThemeStateTickedSlider, CPThemeStateAboveLeftTickedSlider]],
     [@"tick-mark-size",                CGSizeMake(4, 1),                       [CPThemeStateVertical, CPThemeStateTickedSlider]],
     [@"tick-mark-margin",              2,                                      [CPThemeStateVertical, CPThemeStateTickedSlider, CPThemeStateAboveLeftTickedSlider]],
     [@"tick-mark-margin",              1,                                      [CPThemeStateVertical, CPThemeStateTickedSlider, CPThemeStateBelowRightTickedSlider]],
     [@"top-margin",                    1,                                      [CPThemeStateVertical, CPThemeStateTickedSlider]],
     [@"bottom-margin",                 0,                                      [CPThemeStateVertical, CPThemeStateTickedSlider]],

//     [@"tick-mark-color",               A3CPColorActiveBorder]
     ];

    [self registerThemeValues:themedVerticalSliderValues forView:slider];

    return slider;
}

+ (CPSlider)makeCircularSlider
{
    var slider = [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 24.0, 24.0)];

    [slider setSliderType:CPCircularSlider];

    return slider;
}

+ (CPSlider)themedCircularSlider
{
    var slider = [self makeCircularSlider],

    knobCssColor = [CPColor colorWithCSSDictionary:@{
                                                     @"border-style": @"none",
                                                     @"border-radius": @"50%",
                                                     @"box-sizing": @"border-box",
                                                     @"background-color": A3ColorCircularSliderKnob //A3ColorBackgroundDark
                                                     }],

    disabledKnobCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"border-style": @"none",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorCircularSliderKnob //A3ColorBackgroundHighlighted
                                                             }],

    trackCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"border-color": A3ColorActiveBorder,
                                                      @"border-style": @"solid",
                                                      @"border-width": @"1px",
                                                      @"border-radius": @"50%",
                                                      @"box-sizing": @"border-box",
                                                      @"background-color": A3ColorBackgroundWhite
                                                      }],

    disabledTrackCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"border-color": A3ColorInactiveDarkBorder, //A3ColorActiveBorder,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"50%",
                                                              @"box-sizing": @"border-box",
                                                              @"background-color": A3ColorBackground
                                                              }],

    themedCircularSliderValues =
    [
     [@"track-color",                   trackCssColor,                          CPThemeStateCircular],
     [@"track-color",                   disabledTrackCssColor,                  [CPThemeStateCircular, CPThemeStateDisabled]],
     [@"track-color",                   trackCssColor,                          [CPThemeStateCircular, CPThemeStateHighlighted]], // was highlightedTrackCssColor

     [@"knob-size",                     CGSizeMake(4.0, 4.0),                   CPThemeStateCircular],
     [@"knob-offset",                   6.0,                                    CPThemeStateCircular],
     [@"knob-color",                    knobCssColor,                           CPThemeStateCircular],
     [@"knob-color",                    knobCssColor,                           [CPThemeStateCircular, CPThemeStateHighlighted]], // was highlightedKnobCssColor
     [@"knob-color",                    disabledKnobCssColor,                   [CPThemeStateCircular, CPThemeStateDisabled]],

     [@"nib2cib-adjustment-frame",      CGRectMake(2.0, -3.0, -4.0, -6.0),      CPThemeStateCircular],  // (2.0, -2.0, -4.0, -4.0)
     [@"direct-nib2cib-adjustment",     YES,                                    CPThemeStateCircular],
     [@"ib-size",                       24,                                     CPThemeStateCircular],

     // Ticked slider
     // Same : track-width, track-color, direct-nib2cib-adjustment
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, 0.0, 0.0),         [CPThemeStateCircular, CPThemeStateTickedSlider]],
     [@"ib-size",                       32,                                     [CPThemeStateCircular, CPThemeStateTickedSlider]],
     [@"knob-size",                     CGSizeMake(4.0, 4.0),                   [CPThemeStateCircular, CPThemeStateTickedSlider]],
     [@"tick-mark-size",                CGSizeMake(2, 2),                       [CPThemeStateCircular, CPThemeStateTickedSlider]],
     [@"tick-mark-margin",              4,                                      [CPThemeStateCircular, CPThemeStateTickedSlider]]

     ];

    [self registerThemeValues:themedCircularSliderValues forView:slider];

    return slider;
}

#pragma mark -
#pragma mark Button bars

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

    resizeCssColor = [CPColor colorWithCSSDictionary:@{
                                                       @"border-color": A3ColorSplitPaneDividerBorder,
                                                       @"border-style": @"solid",
                                                       @"border-width": @"0px 1px 0px 1px",
                                                       @"box-sizing": @"border-box",
                                                       @"background-color": A3ColorBackground
                                                       }
                                    beforeDictionary:nil
                                     afterDictionary:@{
                                                       @"border-color": A3ColorSplitPaneDividerBorder,
                                                       @"border-style": @"solid",
                                                       @"border-width": @"0px 1px 0px 1px",
                                                       @"box-sizing": @"border-box",
                                                       @"content": @"''",
                                                       @"position": @"absolute",
                                                       @"width": @"5px",
                                                       @"height": @"10px",
                                                       @"top": @"9px",
                                                       @"left": @"4px"
                                                       }],

    smoothResizeCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"border-color": A3ColorLightBackground, //A3ColorTransparent,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"0px 1px 0px 1px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorLightBackground, //A3ColorTransparent
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             @"border-color": A3ColorSplitPaneDividerBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"0px 1px 0px 1px",
                                                             @"box-sizing": @"border-box",
                                                             @"content": @"''",
                                                             @"position": @"absolute",
                                                             @"width": @"5px",
                                                             @"height": @"10px",
                                                             @"top": @"9px",
                                                             @"left": @"4px"
                                                             }],

    borderedBezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"border-color": A3ColorSplitPaneDividerBorder,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px 0px 0px 0px",
                                                              @"box-sizing": @"border-box",
                                                              @"background-color": A3ColorBackground
                                                              }],

    transparentBorderedBezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                                         @"border-color": A3ColorSplitPaneDividerBorder,
                                                                         @"border-style": @"solid",
                                                                         @"border-width": @"1px 0px 0px 0px",
                                                                         @"box-sizing": @"border-box",
                                                                         @"background-color": A3ColorLightBackground //A3ColorTransparent
                                                                         }],

    transparentUnborderedBezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                                           @"background-color": A3ColorLightBackground, //A3ColorTransparent,
                                                                           @"box-sizing": @"border-box",
                                                                           @"border-style": @"none"
                                                                           }],

    dividerCssColor = [CPColor colorWithCSSDictionary:@{
                                                        @"background-color": A3ColorSplitPaneDividerBorder
                                                        }],

    // !!! For sharpness problem, we don't double the resolution
    buttonImagePlus = [CPImage imageWithCSSDictionary:@{
                                                        @"background-image": @"url(%%packed.png)",
                                                        @"background-position": @"-168px -8px",    // -160px -0px
                                                        @"background-repeat": @"no-repeat",
                                                        @"background-size": @"200px 800px"       // 200px 800px
                                                        }
                                                 size:CGSizeMake(16,16)],

    // !!! For sharpness problem, we don't double the resolution
    buttonImageMinus = [CPImage imageWithCSSDictionary:@{
                                                         @"background-image": @"url(%%packed.png)",
                                                         @"background-position": @"-168px -40px",    // -160px -32px
                                                         @"background-repeat": @"no-repeat",
                                                         @"background-size": @"200px 800px"       // 200px 800px
                                                         }
                                                  size:CGSizeMake(16,16)],

    buttonImageAction = [CPImage imageWithCSSDictionary:@{
                                                          @"background-image": @"url(%%packed.png)",
                                                          @"background-position": @"-80px -32px",    // -160px -64px
                                                          @"background-repeat": @"no-repeat",
                                                          @"background-size": @"100px 400px"       // 200px 800px
                                                          }
                                                   size:CGSizeMake(16,16)],

    // !!! For sharpness problem, we don't double the resolution
    buttonImagePlusHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                   @"background-image": @"url(%%packed.png)",
                                                                   @"background-position": @"-168px -104px",    // -160px -0px
                                                                   @"background-repeat": @"no-repeat",
                                                                   @"background-size": @"200px 800px"       // 200px 800px
                                                                   }
                                                            size:CGSizeMake(16,16)],

    // !!! For sharpness problem, we don't double the resolution
    buttonImageMinusHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                    @"background-image": @"url(%%packed.png)",
                                                                    @"background-position": @"-168px -136px",    // -160px -32px
                                                                    @"background-repeat": @"no-repeat",
                                                                    @"background-size": @"200px 800px"       // 200px 800px
                                                                    }
                                                             size:CGSizeMake(16,16)],

    buttonImageActionHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                     @"background-image": @"url(%%packed.png)",
                                                                     @"background-position": @"-80px -80px",    // -160px -64px
                                                                     @"background-repeat": @"no-repeat",
                                                                     @"background-size": @"100px 400px"       // 200px 800px
                                                                     }
                                                              size:CGSizeMake(16,16)],



    themedButtonBarValues =
    [
     [@"bezel-color",               borderedBezelCssColor,              CPThemeStateBordered],                          // Draws separator & not transparent
     [@"bezel-color",               transparentBorderedBezelCssColor,   [CPThemeStateBordered, CPThemeStateDisabled]],  // Draws separator & transparent
     [@"bezel-color",               transparentUnborderedBezelCssColor, CPThemeStateDisabled],                          // Doesn't draw separator & transparent
     [@"bezel-color",               transparentUnborderedBezelCssColor, CPThemeStateNormal],                            // Doesn't draw separator & not transparent. Aristo3 doesn't support it
     [@"divider-color",             dividerCssColor],

     [@"resize-control-size",       CGSizeMake(15, 28)],
     [@"resize-control-inset",      CGInsetMake(0, -1, 0, -1)],
//     [@"resize-control-color",      resizeCssColor],
     [@"resize-control-color",      resizeCssColor,                     CPThemeStateBordered],                          // Draws separator & not transparent
     [@"resize-control-color",      resizeCssColor,                     [CPThemeStateBordered, CPThemeStateDisabled]],  // Draws separator & transparent
     [@"resize-control-color",      smoothResizeCssColor,               CPThemeStateDisabled],                          // Doesn't draw separator & transparent
     [@"resize-control-color",      resizeCssColor,                     CPThemeStateNormal],                            // Doesn't draw separator & not transparent. Aristo3 doesn't support it
     [@"auto-resize-control",       NO],

     // Default appearence
     [@"bordered-buttons",          NO],
     [@"draws-separator",           YES],
     [@"is-transparent",            NO],

     // Layout properties
     [@"button-vertical-offset",    0,                                  CPThemeStateBordered],                          // Draws separator & not transparent
     [@"button-vertical-offset",    0,                                  [CPThemeStateBordered, CPThemeStateDisabled]],  // Draws separator & transparent
     [@"button-vertical-offset",    1,                                  CPThemeStateDisabled],                          // Doesn't draw separator & transparent
     [@"button-vertical-offset",    1,                                  CPThemeStateNormal],                            // Doesn't draw separator & not transparent. Aristo3 doesn't support it

     [@"spacing-size",              CGSizeMake(6, 28)],
     [@"spacing-size",              CGSizeMake(0, 28),                  CPThemeStateBezeled], // This will be used only for bordered buttons

     [@"min-size",                  CGSizeMake(0, 29)],
     [@"max-size",                  CGSizeMake(-1, 29)],

     // WARNING : Those are also used as template images for buttons, etc.
     //           See Cib/_CPCibCustomResource.j and NSCustomResource.j (nib2cib)
     [@"button-image-plus",         [CPImage imageWithMaterialIconNamed:@"add"      size:CGSizeMake(16,16) color:[CPColor colorWithCSSString:@"rgba(0,0,0,0.85)"]]],
     [@"button-image-minus",        [CPImage imageWithMaterialIconNamed:@"remove"   size:CGSizeMake(16,16) color:[CPColor colorWithCSSString:@"rgba(0,0,0,0.85)"]]],
     [@"button-image-action",       [CPImage imageWithMaterialIconNamed:@"settings" size:CGSizeMake(16,16) color:[CPColor colorWithCSSString:@"rgba(0,0,0,0.85)"]]],

     [@"button-image-plus",         [CPImage imageWithMaterialIconNamed:@"add"      size:CGSizeMake(16,16) color:[CPColor colorWithCSSString:@"rgba(0,0,0,1.00)"]],     CPThemeStateHighlighted],
     [@"button-image-minus",        [CPImage imageWithMaterialIconNamed:@"remove"   size:CGSizeMake(16,16) color:[CPColor colorWithCSSString:@"rgba(0,0,0,1.00)"]],     CPThemeStateHighlighted],
     [@"button-image-action",       [CPImage imageWithMaterialIconNamed:@"settings" size:CGSizeMake(16,16) color:[CPColor colorWithCSSString:@"rgba(0,0,0,1.00)"]],     CPThemeStateHighlighted]
     ];

    [self registerThemeValues:themedButtonBarValues forView:buttonBar];

    return buttonBar;
}

+ (_CPButtonBarButton)themedButtonBarButton
{
    var button = [[_CPButtonBarButton alloc] initWithFrame:CGRectMake(0, 0, 34, 34)],

    buttonBezelColor = [CPColor colorWithCSSDictionary:@{
                                                         @"background-color": A3ColorTransparent
                                                         }],

    highlightedButtonBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorBackgroundDarkened
                                                                    }],

    themedButtonBarButtonValues =
    [
     [@"bezel-color",               buttonBezelColor],
     [@"bezel-color",               highlightedButtonBezelColor,                                        [CPThemeStateHighlighted, CPThemeStateBordered]],

     // Layout properties
     [@"min-size",                  CGSizeMake(18, 28)],
     [@"max-size",                  CGSizeMake(18, 28)],
     [@"min-size",                  CGSizeMake(34, 28),                                                 CPThemeStateBordered],
     [@"max-size",                  CGSizeMake(34, 28),                                                 CPThemeStateBordered],
     [@"highlights-by",             CPPushInCellMask | CPContentsCellMask,                              CPThemeStateNormal],
     [@"highlights-by",             CPContentsCellMask | CPChangeBackgroundCellMask | CPPushInCellMask, CPThemeStateBordered]
     ];

    [self registerThemeValues:themedButtonBarButtonValues forView:button];

    return button;
}

+ (_CPButtonBarSeparator)themedButtonBarSeparator
{
    var button = [[_CPButtonBarSeparator alloc] initWithFrame:CGRectMake(0, 0, 34, 34)],

    separatorCssImage = [CPImage imageWithCSSDictionary:@{
                                                          @"background-color": A3ColorTextfieldActiveBorder // A3ColorSplitPaneDividerBorder
                                                          }
                                                   size:CGSizeMake(1,14)],

    borderedSeparatorCssImage = [CPImage imageWithCSSDictionary:@{
                                                                  @"background-color": A3ColorTextfieldActiveBorder // A3ColorSplitPaneDividerBorder
                                                                  }
                                                           size:CGSizeMake(1,16)],

    themedButtonBarSeparatorValues =
    [
     [@"image",     separatorCssImage],
     [@"image",     borderedSeparatorCssImage,      CPThemeStateBordered], // When bordered, we have a taller separator
     ];

    [self registerThemeValues:themedButtonBarSeparatorValues forView:button];

    return button;
}

+ (_CPButtonBarSearchField)themedButtonBarSearchField
{
    var button = [[_CPButtonBarSearchField alloc] initWithFrame:CGRectMake(0, 0, 34, 34)],

    searchFieldBezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBackgroundLightlyDarkened,
                                                                 @"border-color": A3ColorTextfieldActiveBorder,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"5px",
                                                                 @"box-sizing": @"border-box",
                                                                 @"transition-duration": @"0.35s",
                                                                 @"transition-property": @"background-color"
                                                                 }],

    searchFieldBezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                                        @"background-color": A3ColorBackgroundWhite,
                                                                        @"border-color": A3ColorTextfieldActiveBorder,
                                                                        @"border-style": @"solid",
                                                                        @"border-width": @"1px",
                                                                        @"border-radius": @"5px",
                                                                        @"box-sizing": @"border-box",
                                                                        @"transition-duration": @"0.35s",
                                                                        @"transition-property": @"background-color"
                                                                        }],

    themedButtonBarSearchFieldValues =
    [
     [@"bezel-color",   searchFieldBezelCssColor,           [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-color",   searchFieldBezelFocusedCssColor,    [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"extra-spacing", 0],
     [@"extra-spacing", 4,                                  CPThemeStateBordered], // This will be used only for bordered buttons
     ];

    [self registerThemeValues:themedButtonBarSearchFieldValues forView:button inheritFrom:[self themedSearchField]];

    return button;
}

+ (_CPButtonBarPopUpButton)themedButtonBarPopUpButton
{
    var button = [[_CPButtonBarPopUpButton alloc] initWithFrame:CGRectMake(0, 0, 34, 34)],

    themedButtonBarPopUpButtonValues =
    [
     [@"content-inset",     CGInsetMake(-1.0, 12.0, 1.0, 2.0)],
     [@"menu-offset",       CGSizeMake(1, -5)],
     [@"min-size",          CGSizeMake(34, 28)],
     [@"max-size",          CGSizeMake(34, 28)]
     ];

    [self registerThemeValues:themedButtonBarPopUpButtonValues forView:button inheritFrom:[self themedPullDownMenu]];

    return button;
}

+ (_CPButtonBarAdaptativePopUpButton)themedButtonBarAdaptativePopUpButton
{
    var button = [[_CPButtonBarAdaptativePopUpButton alloc] initWithFrame:CGRectMakeZero()],

    themedButtonBarAdaptativePopUpButtonValues =
    [
     [@"extra-spacing", 0],
     [@"extra-spacing", 4,                  CPThemeStateBordered], // This will be used only for bordered buttons
     ];

    [self registerThemeValues:themedButtonBarAdaptativePopUpButtonValues forView:button inheritFrom:[self themedPopUpButton]]; // themedPullDownMenu

    return button;
}

+ (_CPButtonBarAdaptativePullDownButton)themedButtonBarAdaptativePullDownButton
{
    var button = [[_CPButtonBarAdaptativePullDownButton alloc] initWithFrame:CGRectMakeZero()],

    themedButtonBarAdaptativePullDownButtonValues =
    [
     [@"content-inset",     CGInsetMake(-4.0, 13, 0, 3.0)],
     [@"extra-spacing",     0],
     [@"extra-spacing",     4,                                  CPThemeStateBordered], // This will be used only for bordered buttons
     ];

    [self registerThemeValues:themedButtonBarAdaptativePullDownButtonValues forView:button inheritFrom:[self themedPullDownMenu]];

    return button;
}

+ (_CPButtonBarAdaptativeLabel)themedButtonBarAdaptativeLabel
{
    var button = [[_CPButtonBarAdaptativeLabel alloc] initWithTitle:@"Dummy"],

    themedButtonBarAdaptativeLabelValues =
    [
     [@"text-color",        A3CPColorActiveText],
     [@"content-inset",     CGInsetMake(0.0, 0.0, 0.0, 0.0)],
     [@"extra-spacing",     0],
     [@"extra-spacing",     4,                                  CPThemeStateBordered], // This will be used only for bordered buttons
     ];

    [self registerThemeValues:themedButtonBarAdaptativeLabelValues forView:button];

    return button;
}

+ (_CPButtonBarLabel)themedButtonBarLabel
{
    var button = [[_CPButtonBarLabel alloc] initWithTitle:@"Dummy"],

    themedButtonBarLabelValues =
    [
     [@"text-color",        A3CPColorActiveText],
     [@"content-inset",     CGInsetMake(0.0, 0.0, 0.0, 0.0)],
     [@"extra-spacing",     0],
     [@"extra-spacing",     4,                                  CPThemeStateBordered], // This will be used only for bordered buttons
     ];

    [self registerThemeValues:themedButtonBarLabelValues forView:button];

    return button;
}

#pragma mark -
#pragma mark Tables

+ (_CPTableColumnHeaderView)makeColumnHeader
{
    var header = [[_CPTableColumnHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 23.0)];

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

    // FIXME: HERE
    background = [CPColor colorWithCSSDictionary:@{
//                                                   @"background-color": A3ColorBackgroundWhite
                                                   }
                                beforeDictionary:nil
                                 afterDictionary:@{
                                                   @"background-color": A3ColorTableHeaderSeparator,
                                                   @"bottom": @"3px",
                                                   @"content": @"''",
                                                   @"position": @"absolute",
                                                   @"right": @"0px",
                                                   @"top": @"2px",
                                                   @"width": @"1px"
                                                   }],

    pressed = [CPColor colorWithCSSDictionary:@{
                                                @"background-color": A3ColorTableColumnHeaderPressed
                                                }
                             beforeDictionary:@{
                                                @"background-color": A3ColorTableDivider,
                                                @"bottom": @"0px",
                                                @"content": @"''",
                                                @"position": @"absolute",
                                                @"left": @"0px", // FIXME: Trouver mieux pour décaler la ligne sur la gauche
                                                @"top": @"0px",
                                                @"width": @"1px"
                                                }
                              afterDictionary:@{
                                                @"background-color": A3ColorTableDivider,
                                                @"bottom": @"0px",
                                                @"content": @"''",
                                                @"position": @"absolute",
                                                @"right": @"0px",
                                                @"top": @"0px",
                                                @"width": @"1px"
                                                }],

    ghost = [CPColor colorWithCSSDictionary:@{}
                           beforeDictionary:nil
                            afterDictionary:nil],

// A3ColorTableDivider
    themedColumnHeaderValues =
    [
     [@"background-color",      background],
     [@"background-color",      pressed,            CPThemeStateHighlighted],
     [@"background-color",      ghost,              CPThemeStateVertical],
     [@"dont-draw-separator",   YES],

     [@"text-inset",            CGInsetMake(-2, 5, 0, 6)],
     [@"text-color",            A3CPColorTableHeaderText],
     [@"text-color",            A3CPColorSelectedTableHeaderText,       CPThemeStateSelected],
     [@"font",                  [CPFont systemFontOfSize:11.0]],
     [@"text-alignment",        CPLeftTextAlignment],
     [@"line-break-mode",       CPLineBreakByTruncatingTail]
     ];

    [self registerThemeValues:themedColumnHeaderValues forView:header];

    return header;
}

+ (CPTableHeaderView)themedTableHeaderRow
{
    var header = [[CPTableHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 23.0)],

    background = [CPColor colorWithCSSDictionary:@{
                                                   @"background-color": A3ColorBackgroundWhite,
                                                   @"border-color": A3ColorTableDivider,
                                                   @"border-style": @"solid",
                                                   @"border-bottom-width": @"1px",
                                                   @"border-top-width": @"0px",
                                                   @"border-left-width": @"0px",
                                                   @"border-right-width": @"0px",
                                                   @"box-sizing": @"border-box"
                                                   }
                                beforeDictionary:nil
                                 afterDictionary:nil],

    animateSwapFunction = "" + function(s, aFromIndex, aToIndex, _columnDragClipView, _columnDragView) {

        var theTableView         = [s tableView],
            animatedColumn       = [[theTableView tableColumns] objectAtIndex:aToIndex],
            animatedHeader       = [animatedColumn headerView],
            animatedHeaderOrigin = [animatedHeader frameOrigin],

            destinationX,
            draggedHeader        = [[[theTableView tableColumns] objectAtIndex:aFromIndex] headerView],

            scrollView = [s enclosingScrollView],
            animatedView = [theTableView _animationViewForColumn:aToIndex],
            animatedOrigin = [animatedView frameOrigin];

        [_columnDragClipView addSubview:animatedView positioned:CPWindowBelow relativeTo:_columnDragView];

        [[animatedHeader subviews] makeObjectsPerformSelector:@selector(setHidden:) withObject:YES];
        [animatedHeader setThemeState:CPThemeStateVertical];

        if (aFromIndex < aToIndex)
            destinationX = CGRectGetMinX([theTableView rectOfColumn:aFromIndex]);
        else
            destinationX = animatedOrigin.x + CGRectGetWidth([theTableView rectOfColumn:aFromIndex]);

        [CPAnimationContext beginGrouping];

        var context = [CPAnimationContext currentContext];

        [context setDuration:0.15];
        [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [context setCompletionHandler:function() {

            [animatedView removeFromSuperview];

            [s _finalize_moveColumn:aFromIndex toColumn:aToIndex];

            [animatedHeader unsetThemeState:CPThemeStateVertical];
            [[animatedHeader subviews] makeObjectsPerformSelector:@selector(setHidden:) withObject:NO];

            if ([animatedView isSelected])
            {
                [animatedHeader setThemeState:CPThemeStateSelected];

                // We have to reselect the animated column
                [[theTableView selectedColumnIndexes] addIndex:aFromIndex];
            }

            // Reload animated column
            var columnVisRect  = CGRectIntersection([theTableView rectOfColumn:aFromIndex], [theTableView visibleRect]),
                rowsIndexes    = [CPIndexSet indexSetWithIndexesInRange:[theTableView rowsInRect:columnVisRect]],
                columnsIndexes = [CPIndexSet indexSetWithIndex:aFromIndex];

            [theTableView _loadDataViewsInRows:rowsIndexes columns:columnsIndexes];
            [theTableView _layoutViewsForRowIndexes:rowsIndexes columnIndexes:columnsIndexes];

            [theTableView._tableDrawView displayRect:columnVisRect];
        }];

        [[animatedView animator] setFrameOrigin:CGPointMake(destinationX, animatedOrigin.y)];

        [CPAnimationContext endGrouping];
    },

    animateReturnFunction = "" + function(s, aColumnIndex, _columnDragView) {

        var animatedColumn       = [[[s tableView] tableColumns] objectAtIndex:aColumnIndex],
            animatedHeader       = [animatedColumn headerView],
            animatedHeaderOrigin = [animatedHeader frameOrigin];

        [CPAnimationContext beginGrouping];

        var context = [CPAnimationContext currentContext];

        [context setDuration:0.15];
        [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [context setCompletionHandler:function() {

            [s _finalize_stopDraggingTableColumn:aColumnIndex];
        }];

        [[_columnDragView animator] setFrameOrigin:CGPointMake(animatedHeaderOrigin.x, 0)];

        [CPAnimationContext endGrouping];
    };

    [header setValue:background             forThemeAttribute:@"background-color"];
    [header setValue:animateSwapFunction    forThemeAttribute:@"swap-animation"];
    [header setValue:animateReturnFunction  forThemeAttribute:@"return-animation"];

    return header;
}

+ (_CPCornerView)themedCornerview
{
    var scrollerWidth = [CPScroller scrollerWidth],
        corner = [[_CPCornerView alloc] initWithFrame:CGRectMake(0.0, 0.0, scrollerWidth, 23.0)],

    background = [CPColor colorWithCSSDictionary:@{
                                                   @"background-color": A3ColorBackgroundWhite,
                                                   @"border-color": A3ColorTableDivider,
                                                   @"border-style": @"solid",
                                                   @"border-bottom-width": @"1px",
                                                   @"border-top-width": @"0px",
                                                   @"border-left-width": @"0px",
                                                   @"border-right-width": @"0px",
                                                   @"box-sizing": @"border-box"
                                                   }
                                beforeDictionary:nil
                                 afterDictionary:nil];

    [corner setValue:background  forThemeAttribute:"background-color"];

    return corner;
}

+ (CPTableView)themedTableView
{
    // This is a bit more complicated than the rest because we actually set theme values for several different (table related) controls in this method

    var tableview = [[CPTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 150.0, 150.0)],
        sortImage = PatternImage("tableview-headerview-ascending.png", 9.0, 8.0),
        sortImageReversed = PatternImage("tableview-headerview-descending.png", 9.0, 8.0),
        imageGenericFile = PatternImage("tableview-image-generic-file.png", 64.0, 64.0),
        alternatingRowColors = [A3CPColorTableRow, A3CPColorTableAlternateRow],
        gridColor = [CPColor colorWithHexString:@"dce0e2"],
//        selectionColor = [CPColor colorWithHexString:@"5780d8"],
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
     [@"alternating-row-colors",                 alternatingRowColors], // OK
     [@"grid-color",                             gridColor],
     [@"highlighted-grid-color",                 [CPColor whiteColor]],
     [@"selection-color",                        @"A3CPColorBorderBlue"],
     [@"unfocused-selection-color",              A3CPColorBorderBlueInactive], // NEW !
     [@"sourcelist-selection-color",             sourceListSelectionColor],
     [@"sort-image",                             sortImage],
     [@"sort-image-reversed",                    sortImageReversed],
     [@"image-generic-file",                     imageGenericFile],
     [@"default-row-height",                     17.0], // here
     [@"header-view-height",                     22], // à vérifier. En fait c'est 1+21+1

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

#pragma mark -

+ (CPSplitView)themedSplitView
{
    var splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)],
        leftView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 75.0, 150.0)],
        rightView = [[CPView alloc] initWithFrame:CGRectMake(75.0, 0.0, 75.0, 150.0)],
        horizontalDividerColor = PatternImage("splitview-divider-horizontal.png", 5.0, 10.0),
        verticalDividerColor = PatternImage("splitview-divider-vertical.png", 10.0, 5.0),

        thinDividerCssColor = [CPColor colorWithCSSDictionary:@{
                                                                @"background-color": A3ColorInactiveBorder
                                                                }
                                             beforeDictionary:nil
                                              afterDictionary:nil],

        thickDividerCssColor = [CPColor colorWithCSSDictionary:@{}
                                              beforeDictionary:nil
                                               afterDictionary:@{
                                                                 @"border-color": A3ColorInactiveBorder, // A3ColorInactiveDarkBorder,
                                                                 @"background-color": A3ColorInactiveBorder,
                                                                 @"width": @"6px",
                                                                 @"height": @"6px",
                                                                 @"box-sizing": @"border-box",
                                                                 @"border-style": @"solid",
                                                                 @"border-radius": @"50%",
                                                                 @"border-width": @"1px",
                                                                 @"content": @"''",
                                                                 @"left": @"0px",
                                                                 @"top": @"2px",
                                                                 @"right": @"0px",
                                                                 @"bottom": @"1px",
                                                                 @"margin": @"auto",
                                                                 @"position": @"absolute",
                                                                 @"z-index": @"300"
                                                                 }],

        verticalThickDividerCssColor = [CPColor colorWithCSSDictionary:@{}
                                                      beforeDictionary:nil
                                                       afterDictionary:@{
                                                                         @"border-color": A3ColorInactiveBorder, // A3ColorInactiveDarkBorder,
                                                                         @"background-color": A3ColorInactiveBorder,
                                                                         @"width": @"6px",
                                                                         @"height": @"6px",
                                                                         @"box-sizing": @"border-box",
                                                                         @"border-style": @"solid",
                                                                         @"border-radius": @"50%",
                                                                         @"border-width": @"1px",
                                                                         @"content": @"''",
                                                                         @"left": @"1px",
                                                                         @"top": @"0px",
                                                                         @"right": @"2px",
                                                                         @"bottom": @"0px",
                                                                         @"margin": @"auto",
                                                                         @"position": @"absolute",
                                                                         @"z-index": @"300"
                                                                         }],

    paneDividerCssColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": A3ColorSplitPaneDividerBackground,
                                                            @"border-color": A3ColorSplitPaneDividerBorder,
                                                            @"box-sizing": @"border-box",
                                                            @"border-style": @"solid",
                                                            @"border-top-width": @"1px",
                                                            @"border-left-width": @"0px",
                                                            @"border-right-width": @"0px",
                                                            @"border-bottom-width": @"1px"
                                                            }
                                         beforeDictionary:nil
                                          afterDictionary:@{
                                                            @"border-color": A3ColorInactiveBorder, // A3ColorInactiveDarkBorder,
                                                            @"background-color": A3ColorInactiveBorder,
                                                            @"width": @"6px",
                                                            @"height": @"6px",
                                                            @"box-sizing": @"border-box",
                                                            @"border-style": @"solid",
                                                            @"border-radius": @"50%",
                                                            @"border-width": @"1px",
                                                            @"content": @"''",
                                                            @"left": @"0px",
                                                            @"top": @"1px",
                                                            @"right": @"0px",
                                                            @"bottom": @"1px",
                                                            @"margin": @"auto",
                                                            @"position": @"absolute",
                                                            @"z-index": @"300"
                                                            }],

    verticalPaneDividerCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorSplitPaneDividerBackground,
                                                                    @"border-color": A3ColorSplitPaneDividerBorder,
                                                                    @"box-sizing": @"border-box",
                                                                    @"border-style": @"solid",
                                                                    @"border-top-width": @"0px",
                                                                    @"border-left-width": @"1px",
                                                                    @"border-right-width": @"1px",
                                                                    @"border-bottom-width": @"0px"
                                                                    }
                                                 beforeDictionary:nil
                                                  afterDictionary:@{
                                                                    @"border-color": A3ColorInactiveBorder, // A3ColorInactiveDarkBorder,
                                                                    @"background-color": A3ColorInactiveBorder,
                                                                    @"width": @"6px",
                                                                    @"height": @"6px",
                                                                    @"box-sizing": @"border-box",
                                                                    @"border-style": @"solid",
                                                                    @"border-radius": @"50%",
                                                                    @"border-width": @"1px",
                                                                    @"content": @"''",
                                                                    @"left": @"1px",
                                                                    @"top": @"0px",
                                                                    @"right": @"1px",
                                                                    @"bottom": @"0px",
                                                                    @"margin": @"auto",
                                                                    @"position": @"absolute",
                                                                    @"z-index": @"300"
                                                                    }];

// Remettre les 2 lignes suivantes
//    [splitView setDividerStyle:CPSplitViewDividerStyleThick];
//    [splitView setArrangesAllSubviews:YES];
//    [splitView addSubview:leftView];
//    [splitView addSubview:rightView];

    // CPThemeStateVertical

    var themedSplitViewValues =
    [
     [@"divider-thickness", 1.0],
     [@"pane-divider-thickness", 10.0],
     [@"pane-divider-color", [CPColor colorWithRed:255.0 / 255.0 green:165.0 / 255.0 blue:165.0 / 255.0 alpha:1.0]],
     [@"horizontal-divider-color", horizontalDividerColor],
     [@"vertical-divider-color", verticalDividerColor],

     [@"divider-thickness",         9,                              CPThemeStateSplitViewDividerStyleThick],
     [@"divider-thickness",         1,                              CPThemeStateSplitViewDividerStyleThin],
     [@"divider-thickness",         10,                             CPThemeStateSplitViewDividerStylePaneSplitter],

     [@"divider-color",             thickDividerCssColor,           CPThemeStateSplitViewDividerStyleThick],
     [@"divider-color",             verticalThickDividerCssColor,   [CPThemeStateSplitViewDividerStyleThick, CPThemeStateVertical]],
     [@"divider-color",             thinDividerCssColor,            CPThemeStateSplitViewDividerStyleThin],
     [@"divider-color",             paneDividerCssColor,            CPThemeStateSplitViewDividerStylePaneSplitter],
     [@"divider-color",             verticalPaneDividerCssColor,    [CPThemeStateSplitViewDividerStylePaneSplitter, CPThemeStateVertical]]
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

    // Regular size
    upCssColor = [CPColor colorWithCSSDictionary:@{
                                                       @"background-color": A3ColorBackgroundWhite,
                                                       @"border-color": A3ColorActiveBorder,
                                                       @"border-style": @"solid",
                                                       @"border-top-width": @"1px",
                                                       @"border-left-width": @"1px",
                                                       @"border-right-width": @"1px",
                                                       @"border-bottom-width": @"0px",
                                                       @"border-top-left-radius": @"6px",
                                                       @"border-top-right-radius": @"6px",
                                                       @"box-sizing": @"border-box"
                                                       }
                                beforeDictionary:@{}
                                 afterDictionary:@{
//                                                   @"border-color": A3ColorStepperArrow,
//                                                   @"width": @"5px",
//                                                   @"height": @"5px",
//                                                   @"box-sizing": @"border-box",
//                                                   @"border-style": @"solid",
//                                                   @"content": @"''",
//                                                   @"left": @"3px",
//                                                   @"top": @"5px",
//                                                   @"position": @"absolute",
//                                                   @"z-index": @"300",
//                                                   @"transform": @"rotate(45deg)",
//                                                   @"border-bottom-width": @"0px",
//                                                   @"border-right-width": @"0px",
//                                                   @"border-top-width": @"1px",
//                                                   @"border-left-width": @"1px"
                                                   @"width": @"13px",
                                                   @"height": @"11px",
                                                   @"top": @"-1px",
                                                   @"left": @"-1px",
                                                   @"content": @"'keyboard_arrow_up'",
                                                   @"color": A3ColorStepperArrow,
                                                   @"position": @"absolute",
                                                   @"z-index": @"300",
                                                   @"font-family": @"'Material Icons'",
                                                   @"font-weight": @"normal",
                                                   @"font-style": @"normal",
                                                   @"font-size": @"13px",
                                                   @"display": @"inline-block",
                                                   @"line-height": @"1",
                                                   @"text-transform": @"none",
                                                   @"letter-spacing": @"normal",
                                                   @"word-wrap": @"normal",
                                                   @"white-space": @"nowrap",
                                                   @"direction": @"ltr",
                                                   @"-webkit-font-smoothing": @"antialiased",
                                                   @"text-rendering": @"optimizeLegibility",
                                                   @"-moz-osx-font-smoothing": @"grayscale",
                                                   @"font-feature-settings": @"'liga'"
                                                   }],

    disabledUpCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackgroundInactive,
                                                               @"border-color": A3ColorInactiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-top-width": @"1px",
                                                               @"border-left-width": @"1px",
                                                               @"border-right-width": @"1px",
                                                               @"border-bottom-width": @"0px",
                                                               @"border-top-left-radius": @"6px",
                                                               @"border-top-right-radius": @"6px",
                                                               @"box-sizing": @"border-box"
                                                               }
                                        beforeDictionary:@{}
                                         afterDictionary:@{
//                                                           @"border-color": A3ColorInactiveDarkBorder,
//                                                           @"width": @"5px",
//                                                           @"height": @"5px",
//                                                           @"box-sizing": @"border-box",
//                                                           @"border-style": @"solid",
//                                                           @"content": @"''",
//                                                           @"left": @"3px",
//                                                           @"top": @"5px",
//                                                           @"position": @"absolute",
//                                                           @"z-index": @"300",
//                                                           @"transform": @"rotate(45deg)",
//                                                           @"border-bottom-width": @"0px",
//                                                           @"border-right-width": @"0px",
//                                                           @"border-top-width": @"1px",
//                                                           @"border-left-width": @"1px"
                                                           @"width": @"13px",
                                                           @"height": @"11px",
                                                           @"top": @"-1px",
                                                           @"left": @"-1px",
                                                           @"content": @"'keyboard_arrow_up'",
                                                           @"color": A3ColorInactiveDarkBorder,
                                                           @"position": @"absolute",
                                                           @"z-index": @"300",
                                                           @"font-family": @"'Material Icons'",
                                                           @"font-weight": @"normal",
                                                           @"font-style": @"normal",
                                                           @"font-size": @"13px",
                                                           @"display": @"inline-block",
                                                           @"line-height": @"1",
                                                           @"text-transform": @"none",
                                                           @"letter-spacing": @"normal",
                                                           @"word-wrap": @"normal",
                                                           @"white-space": @"nowrap",
                                                           @"direction": @"ltr",
                                                           @"-webkit-font-smoothing": @"antialiased",
                                                           @"text-rendering": @"optimizeLegibility",
                                                           @"-moz-osx-font-smoothing": @"grayscale",
                                                           @"font-feature-settings": @"'liga'"
                                                           }],

    highlightedUpCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": A3ColorBorderBlueHighlighted,
                                                                  @"border-color": A3ColorBorderBlueHighlighted,
                                                                  @"border-style": @"solid",
                                                                  @"border-top-width": @"1px",
                                                                  @"border-left-width": @"1px",
                                                                  @"border-right-width": @"1px",
                                                                  @"border-bottom-width": @"0px",
                                                                  @"border-top-left-radius": @"6px",
                                                                  @"border-top-right-radius": @"6px",
                                                                  @"box-sizing": @"border-box"
                                                                  }
                                           beforeDictionary:@{}
                                            afterDictionary:@{
//                                                              @"border-color": A3ColorHighlightedStepperArrow,
//                                                              @"width": @"5px",
//                                                              @"height": @"5px",
//                                                              @"box-sizing": @"border-box",
//                                                              @"border-style": @"solid",
//                                                              @"content": @"''",
//                                                              @"left": @"3px",
//                                                              @"top": @"5px",
//                                                              @"position": @"absolute",
//                                                              @"z-index": @"300",
//                                                              @"transform": @"rotate(45deg)",
//                                                              @"border-bottom-width": @"0px",
//                                                              @"border-right-width": @"0px",
//                                                              @"border-top-width": @"1px",
//                                                              @"border-left-width": @"1px"
                                                              @"width": @"13px",
                                                              @"height": @"11px",
                                                              @"top": @"-1px",
                                                              @"left": @"-1px",
                                                              @"content": @"'keyboard_arrow_up'",
                                                              @"color": A3ColorHighlightedStepperArrow,
                                                              @"position": @"absolute",
                                                              @"z-index": @"300",
                                                              @"font-family": @"'Material Icons'",
                                                              @"font-weight": @"normal",
                                                              @"font-style": @"normal",
                                                              @"font-size": @"13px",
                                                              @"display": @"inline-block",
                                                              @"line-height": @"1",
                                                              @"text-transform": @"none",
                                                              @"letter-spacing": @"normal",
                                                              @"word-wrap": @"normal",
                                                              @"white-space": @"nowrap",
                                                              @"direction": @"ltr",
                                                              @"-webkit-font-smoothing": @"antialiased",
                                                              @"text-rendering": @"optimizeLegibility",
                                                              @"-moz-osx-font-smoothing": @"grayscale",
                                                              @"font-feature-settings": @"'liga'"
                                                              }],

    downCssColor = [CPColor colorWithCSSDictionary:@{
                                                   @"background-color": A3ColorBackgroundWhite,
                                                   @"border-color": A3ColorActiveBorder,
                                                   @"border-style": @"solid",
                                                   @"border-top-width": @"0px",
                                                   @"border-left-width": @"1px",
                                                   @"border-right-width": @"1px",
                                                   @"border-bottom-width": @"1px",
                                                   @"border-bottom-left-radius": @"6px",
                                                   @"border-bottom-right-radius": @"6px",
                                                   @"box-sizing": @"border-box"
                                                   }
                                  beforeDictionary:@{}
                                   afterDictionary:@{
//                                                     @"border-color": A3ColorStepperArrow,
//                                                     @"width": @"5px",
//                                                     @"height": @"5px",
//                                                     @"box-sizing": @"border-box",
//                                                     @"border-style": @"solid",
//                                                     @"content": @"''",
//                                                     @"left": @"3px",
//                                                     @"top": @"0px",
//                                                     @"position": @"absolute",
//                                                     @"z-index": @"300",
//                                                     @"transform": @"rotate(45deg)",
//                                                     @"border-bottom-width": @"1px",
//                                                     @"border-right-width": @"1px",
//                                                     @"border-top-width": @"0px",
//                                                     @"border-left-width": @"0px"
                                                     @"width": @"13px",
                                                     @"height": @"11px",
                                                     @"top": @"-2px",
                                                     @"left": @"-1px",
                                                     @"content": @"'keyboard_arrow_down'",
                                                     @"color": A3ColorStepperArrow,
                                                     @"position": @"absolute",
                                                     @"z-index": @"300",
                                                     @"font-family": @"'Material Icons'",
                                                     @"font-weight": @"normal",
                                                     @"font-style": @"normal",
                                                     @"font-size": @"13px",
                                                     @"display": @"inline-block",
                                                     @"line-height": @"1",
                                                     @"text-transform": @"none",
                                                     @"letter-spacing": @"normal",
                                                     @"word-wrap": @"normal",
                                                     @"white-space": @"nowrap",
                                                     @"direction": @"ltr",
                                                     @"-webkit-font-smoothing": @"antialiased",
                                                     @"text-rendering": @"optimizeLegibility",
                                                     @"-moz-osx-font-smoothing": @"grayscale",
                                                     @"font-feature-settings": @"'liga'"
                                                     }],

    disabledDownCssColor = [CPColor colorWithCSSDictionary:@{
                                                           @"background-color": A3ColorBackgroundInactive,
                                                           @"border-color": A3ColorInactiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-top-width": @"0px",
                                                           @"border-left-width": @"1px",
                                                           @"border-right-width": @"1px",
                                                           @"border-bottom-width": @"1px",
                                                           @"border-bottom-left-radius": @"6px",
                                                           @"border-bottom-right-radius": @"6px",
                                                           @"box-sizing": @"border-box"
                                                           }
                                          beforeDictionary:@{}
                                           afterDictionary:@{
//                                                             @"border-color": A3ColorInactiveDarkBorder,
//                                                             @"width": @"5px",
//                                                             @"height": @"5px",
//                                                             @"box-sizing": @"border-box",
//                                                             @"border-style": @"solid",
//                                                             @"content": @"''",
//                                                             @"left": @"3px",
//                                                             @"top": @"0px",
//                                                             @"position": @"absolute",
//                                                             @"z-index": @"300",
//                                                             @"transform": @"rotate(45deg)",
//                                                             @"border-bottom-width": @"1px",
//                                                             @"border-right-width": @"1px",
//                                                             @"border-top-width": @"0px",
//                                                             @"border-left-width": @"0px"
                                                             @"width": @"13px",
                                                             @"height": @"11px",
                                                             @"top": @"-2px",
                                                             @"left": @"-1px",
                                                             @"content": @"'keyboard_arrow_down'",
                                                             @"color": A3ColorInactiveDarkBorder,
                                                             @"position": @"absolute",
                                                             @"z-index": @"300",
                                                             @"font-family": @"'Material Icons'",
                                                             @"font-weight": @"normal",
                                                             @"font-style": @"normal",
                                                             @"font-size": @"13px",
                                                             @"display": @"inline-block",
                                                             @"line-height": @"1",
                                                             @"text-transform": @"none",
                                                             @"letter-spacing": @"normal",
                                                             @"word-wrap": @"normal",
                                                             @"white-space": @"nowrap",
                                                             @"direction": @"ltr",
                                                             @"-webkit-font-smoothing": @"antialiased",
                                                             @"text-rendering": @"optimizeLegibility",
                                                             @"-moz-osx-font-smoothing": @"grayscale",
                                                             @"font-feature-settings": @"'liga'"
                                                             }],

    highlightedDownCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": A3ColorBorderBlueHighlighted,
                                                              @"border-color": A3ColorBorderBlueHighlighted,
                                                              @"border-style": @"solid",
                                                              @"border-top-width": @"0px",
                                                              @"border-left-width": @"1px",
                                                              @"border-right-width": @"1px",
                                                              @"border-bottom-width": @"1px",
                                                              @"border-bottom-left-radius": @"6px",
                                                              @"border-bottom-right-radius": @"6px",
                                                              @"box-sizing": @"border-box"
                                                              }
                                             beforeDictionary:@{}
                                              afterDictionary:@{
//                                                                @"border-color": A3ColorHighlightedStepperArrow,
//                                                                @"width": @"5px",
//                                                                @"height": @"5px",
//                                                                @"box-sizing": @"border-box",
//                                                                @"border-style": @"solid",
//                                                                @"content": @"''",
//                                                                @"left": @"3px",
//                                                                @"top": @"0px",
//                                                                @"position": @"absolute",
//                                                                @"z-index": @"300",
//                                                                @"transform": @"rotate(45deg)",
//                                                                @"border-bottom-width": @"1px",
//                                                                @"border-right-width": @"1px",
//                                                                @"border-top-width": @"0px",
//                                                                @"border-left-width": @"0px"
                                                                @"width": @"13px",
                                                                @"height": @"11px",
                                                                @"top": @"-2px",
                                                                @"left": @"-1px",
                                                                @"content": @"'keyboard_arrow_down'",
                                                                @"color": A3ColorHighlightedStepperArrow,
                                                                @"position": @"absolute",
                                                                @"z-index": @"300",
                                                                @"font-family": @"'Material Icons'",
                                                                @"font-weight": @"normal",
                                                                @"font-style": @"normal",
                                                                @"font-size": @"13px",
                                                                @"display": @"inline-block",
                                                                @"line-height": @"1",
                                                                @"text-transform": @"none",
                                                                @"letter-spacing": @"normal",
                                                                @"word-wrap": @"normal",
                                                                @"white-space": @"nowrap",
                                                                @"direction": @"ltr",
                                                                @"-webkit-font-smoothing": @"antialiased",
                                                                @"text-rendering": @"optimizeLegibility",
                                                                @"-moz-osx-font-smoothing": @"grayscale",
                                                                @"font-feature-settings": @"'liga'"
                                                                }],

    // Small size
    smallUpCssColor = [CPColor colorWithCSSDictionary:@{
                                                        @"background-color": A3ColorBackgroundWhite,
                                                        @"border-color": A3ColorActiveBorder,
                                                        @"border-style": @"solid",
                                                        @"border-top-width": @"1px",
                                                        @"border-left-width": @"1px",
                                                        @"border-right-width": @"1px",
                                                        @"border-bottom-width": @"0px",
                                                        @"border-top-left-radius": @"6px",
                                                        @"border-top-right-radius": @"6px",
                                                        @"box-sizing": @"border-box"
                                                        }
                                     beforeDictionary:@{}
                                      afterDictionary:@{
//                                                        @"border-color": A3ColorStepperArrow,
//                                                        @"width": @"5px",
//                                                        @"height": @"5px",
//                                                        @"box-sizing": @"border-box",
//                                                        @"border-style": @"solid",
//                                                        @"content": @"''",
//                                                        @"left": @"2px",
//                                                        @"top": @"3px",
//                                                        @"position": @"absolute",
//                                                        @"z-index": @"300",
//                                                        @"transform": @"rotate(45deg)",
//                                                        @"border-bottom-width": @"0px",
//                                                        @"border-right-width": @"0px",
//                                                        @"border-top-width": @"1px",
//                                                        @"border-left-width": @"1px"
                                                        @"width": @"11px",
                                                        @"height": @"10px",
                                                        @"top": @"-1px",
                                                        @"left": @"-1px",
                                                        @"content": @"'keyboard_arrow_up'",
                                                        @"color": A3ColorStepperArrow,
                                                        @"position": @"absolute",
                                                        @"z-index": @"300",
                                                        @"font-family": @"'Material Icons'",
                                                        @"font-weight": @"normal",
                                                        @"font-style": @"normal",
                                                        @"font-size": @"11px",
                                                        @"display": @"inline-block",
                                                        @"line-height": @"1",
                                                        @"text-transform": @"none",
                                                        @"letter-spacing": @"normal",
                                                        @"word-wrap": @"normal",
                                                        @"white-space": @"nowrap",
                                                        @"direction": @"ltr",
                                                        @"-webkit-font-smoothing": @"antialiased",
                                                        @"text-rendering": @"optimizeLegibility",
                                                        @"-moz-osx-font-smoothing": @"grayscale",
                                                        @"font-feature-settings": @"'liga'"
                                                        }],

    smallDisabledUpCssColor = [CPColor colorWithCSSDictionary:@{
                                                                @"background-color": A3ColorBackgroundInactive,
                                                                @"border-color": A3ColorInactiveBorder,
                                                                @"border-style": @"solid",
                                                                @"border-top-width": @"1px",
                                                                @"border-left-width": @"1px",
                                                                @"border-right-width": @"1px",
                                                                @"border-bottom-width": @"0px",
                                                                @"border-top-left-radius": @"6px",
                                                                @"border-top-right-radius": @"6px",
                                                                @"box-sizing": @"border-box"
                                                                }
                                             beforeDictionary:@{}
                                              afterDictionary:@{
//                                                                @"border-color": A3ColorInactiveDarkBorder,
//                                                                @"width": @"5px",
//                                                                @"height": @"5px",
//                                                                @"box-sizing": @"border-box",
//                                                                @"border-style": @"solid",
//                                                                @"content": @"''",
//                                                                @"left": @"2px",
//                                                                @"top": @"3px",
//                                                                @"position": @"absolute",
//                                                                @"z-index": @"300",
//                                                                @"transform": @"rotate(45deg)",
//                                                                @"border-bottom-width": @"0px",
//                                                                @"border-right-width": @"0px",
//                                                                @"border-top-width": @"1px",
//                                                                @"border-left-width": @"1px"
                                                                @"width": @"11px",
                                                                @"height": @"10px",
                                                                @"top": @"-1px",
                                                                @"left": @"-1px",
                                                                @"content": @"'keyboard_arrow_up'",
                                                                @"color": A3ColorInactiveDarkBorder,
                                                                @"position": @"absolute",
                                                                @"z-index": @"300",
                                                                @"font-family": @"'Material Icons'",
                                                                @"font-weight": @"normal",
                                                                @"font-style": @"normal",
                                                                @"font-size": @"11px",
                                                                @"display": @"inline-block",
                                                                @"line-height": @"1",
                                                                @"text-transform": @"none",
                                                                @"letter-spacing": @"normal",
                                                                @"word-wrap": @"normal",
                                                                @"white-space": @"nowrap",
                                                                @"direction": @"ltr",
                                                                @"-webkit-font-smoothing": @"antialiased",
                                                                @"text-rendering": @"optimizeLegibility",
                                                                @"-moz-osx-font-smoothing": @"grayscale",
                                                                @"font-feature-settings": @"'liga'"
                                                                }],

    smallHighlightedUpCssColor = [CPColor colorWithCSSDictionary:@{
                                                                   @"background-color": A3ColorBorderBlueHighlighted,
                                                                   @"border-color": A3ColorBorderBlueHighlighted,
                                                                   @"border-style": @"solid",
                                                                   @"border-top-width": @"1px",
                                                                   @"border-left-width": @"1px",
                                                                   @"border-right-width": @"1px",
                                                                   @"border-bottom-width": @"0px",
                                                                   @"border-top-left-radius": @"6px",
                                                                   @"border-top-right-radius": @"6px",
                                                                   @"box-sizing": @"border-box"
                                                                   }
                                                beforeDictionary:@{}
                                                 afterDictionary:@{
//                                                                   @"border-color": A3ColorHighlightedStepperArrow,
//                                                                   @"width": @"5px",
//                                                                   @"height": @"5px",
//                                                                   @"box-sizing": @"border-box",
//                                                                   @"border-style": @"solid",
//                                                                   @"content": @"''",
//                                                                   @"left": @"2px",
//                                                                   @"top": @"3px",
//                                                                   @"position": @"absolute",
//                                                                   @"z-index": @"300",
//                                                                   @"transform": @"rotate(45deg)",
//                                                                   @"border-bottom-width": @"0px",
//                                                                   @"border-right-width": @"0px",
//                                                                   @"border-top-width": @"1px",
//                                                                   @"border-left-width": @"1px"
                                                                   @"width": @"11px",
                                                                   @"height": @"10px",
                                                                   @"top": @"-1px",
                                                                   @"left": @"-1px",
                                                                   @"content": @"'keyboard_arrow_up'",
                                                                   @"color": A3ColorHighlightedStepperArrow,
                                                                   @"position": @"absolute",
                                                                   @"z-index": @"300",
                                                                   @"font-family": @"'Material Icons'",
                                                                   @"font-weight": @"normal",
                                                                   @"font-style": @"normal",
                                                                   @"font-size": @"11px",
                                                                   @"display": @"inline-block",
                                                                   @"line-height": @"1",
                                                                   @"text-transform": @"none",
                                                                   @"letter-spacing": @"normal",
                                                                   @"word-wrap": @"normal",
                                                                   @"white-space": @"nowrap",
                                                                   @"direction": @"ltr",
                                                                   @"-webkit-font-smoothing": @"antialiased",
                                                                   @"text-rendering": @"optimizeLegibility",
                                                                   @"-moz-osx-font-smoothing": @"grayscale",
                                                                   @"font-feature-settings": @"'liga'"
                                                                   }],

    smallDownCssColor = [CPColor colorWithCSSDictionary:@{
                                                          @"background-color": A3ColorBackgroundWhite,
                                                          @"border-color": A3ColorActiveBorder,
                                                          @"border-style": @"solid",
                                                          @"border-top-width": @"0px",
                                                          @"border-left-width": @"1px",
                                                          @"border-right-width": @"1px",
                                                          @"border-bottom-width": @"1px",
                                                          @"border-bottom-left-radius": @"6px",
                                                          @"border-bottom-right-radius": @"6px",
                                                          @"box-sizing": @"border-box"
                                                          }
                                       beforeDictionary:@{}
                                        afterDictionary:@{
//                                                          @"border-color": A3ColorStepperArrow,
//                                                          @"width": @"5px",
//                                                          @"height": @"5px",
//                                                          @"box-sizing": @"border-box",
//                                                          @"border-style": @"solid",
//                                                          @"content": @"''",
//                                                          @"left": @"2px",
//                                                          @"top": @"0px",
//                                                          @"position": @"absolute",
//                                                          @"z-index": @"300",
//                                                          @"transform": @"rotate(45deg)",
//                                                          @"border-bottom-width": @"1px",
//                                                          @"border-right-width": @"1px",
//                                                          @"border-top-width": @"0px",
//                                                          @"border-left-width": @"0px"
                                                          @"width": @"11px",
                                                          @"height": @"10px",
                                                          @"top": @"-2px",
                                                          @"left": @"-1px",
                                                          @"content": @"'keyboard_arrow_down'",
                                                          @"color": A3ColorStepperArrow,
                                                          @"position": @"absolute",
                                                          @"z-index": @"300",
                                                          @"font-family": @"'Material Icons'",
                                                          @"font-weight": @"normal",
                                                          @"font-style": @"normal",
                                                          @"font-size": @"11px",
                                                          @"display": @"inline-block",
                                                          @"line-height": @"1",
                                                          @"text-transform": @"none",
                                                          @"letter-spacing": @"normal",
                                                          @"word-wrap": @"normal",
                                                          @"white-space": @"nowrap",
                                                          @"direction": @"ltr",
                                                          @"-webkit-font-smoothing": @"antialiased",
                                                          @"text-rendering": @"optimizeLegibility",
                                                          @"-moz-osx-font-smoothing": @"grayscale",
                                                          @"font-feature-settings": @"'liga'"
                                                          }],

    smallDisabledDownCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": A3ColorBackgroundInactive,
                                                                  @"border-color": A3ColorInactiveBorder,
                                                                  @"border-style": @"solid",
                                                                  @"border-top-width": @"0px",
                                                                  @"border-left-width": @"1px",
                                                                  @"border-right-width": @"1px",
                                                                  @"border-bottom-width": @"1px",
                                                                  @"border-bottom-left-radius": @"6px",
                                                                  @"border-bottom-right-radius": @"6px",
                                                                  @"box-sizing": @"border-box"
                                                                  }
                                               beforeDictionary:@{}
                                                afterDictionary:@{
//                                                                  @"border-color": A3ColorInactiveDarkBorder,
//                                                                  @"width": @"5px",
//                                                                  @"height": @"5px",
//                                                                  @"box-sizing": @"border-box",
//                                                                  @"border-style": @"solid",
//                                                                  @"content": @"''",
//                                                                  @"left": @"2px",
//                                                                  @"top": @"0px",
//                                                                  @"position": @"absolute",
//                                                                  @"z-index": @"300",
//                                                                  @"transform": @"rotate(45deg)",
//                                                                  @"border-bottom-width": @"1px",
//                                                                  @"border-right-width": @"1px",
//                                                                  @"border-top-width": @"0px",
//                                                                  @"border-left-width": @"0px"
                                                                  @"width": @"11px",
                                                                  @"height": @"10px",
                                                                  @"top": @"-2px",
                                                                  @"left": @"-1px",
                                                                  @"content": @"'keyboard_arrow_down'",
                                                                  @"color": A3ColorInactiveDarkBorder,
                                                                  @"position": @"absolute",
                                                                  @"z-index": @"300",
                                                                  @"font-family": @"'Material Icons'",
                                                                  @"font-weight": @"normal",
                                                                  @"font-style": @"normal",
                                                                  @"font-size": @"11px",
                                                                  @"display": @"inline-block",
                                                                  @"line-height": @"1",
                                                                  @"text-transform": @"none",
                                                                  @"letter-spacing": @"normal",
                                                                  @"word-wrap": @"normal",
                                                                  @"white-space": @"nowrap",
                                                                  @"direction": @"ltr",
                                                                  @"-webkit-font-smoothing": @"antialiased",
                                                                  @"text-rendering": @"optimizeLegibility",
                                                                  @"-moz-osx-font-smoothing": @"grayscale",
                                                                  @"font-feature-settings": @"'liga'"
                                                                  }],

    smallHighlightedDownCssColor = [CPColor colorWithCSSDictionary:@{
                                                                     @"background-color": A3ColorBorderBlueHighlighted,
                                                                     @"border-color": A3ColorBorderBlueHighlighted,
                                                                     @"border-style": @"solid",
                                                                     @"border-top-width": @"0px",
                                                                     @"border-left-width": @"1px",
                                                                     @"border-right-width": @"1px",
                                                                     @"border-bottom-width": @"1px",
                                                                     @"border-bottom-left-radius": @"6px",
                                                                     @"border-bottom-right-radius": @"6px",
                                                                     @"box-sizing": @"border-box"
                                                                     }
                                                  beforeDictionary:@{}
                                                   afterDictionary:@{
//                                                                     @"border-color": A3ColorHighlightedStepperArrow,
//                                                                     @"width": @"5px",
//                                                                     @"height": @"5px",
//                                                                     @"box-sizing": @"border-box",
//                                                                     @"border-style": @"solid",
//                                                                     @"content": @"''",
//                                                                     @"left": @"2px",
//                                                                     @"top": @"0px",
//                                                                     @"position": @"absolute",
//                                                                     @"z-index": @"300",
//                                                                     @"transform": @"rotate(45deg)",
//                                                                     @"border-bottom-width": @"1px",
//                                                                     @"border-right-width": @"1px",
//                                                                     @"border-top-width": @"0px",
//                                                                     @"border-left-width": @"0px"
                                                                     @"width": @"11px",
                                                                     @"height": @"10px",
                                                                     @"top": @"-2px",
                                                                     @"left": @"-1px",
                                                                     @"content": @"'keyboard_arrow_down'",
                                                                     @"color": A3ColorHighlightedStepperArrow,
                                                                     @"position": @"absolute",
                                                                     @"z-index": @"300",
                                                                     @"font-family": @"'Material Icons'",
                                                                     @"font-weight": @"normal",
                                                                     @"font-style": @"normal",
                                                                     @"font-size": @"11px",
                                                                     @"display": @"inline-block",
                                                                     @"line-height": @"1",
                                                                     @"text-transform": @"none",
                                                                     @"letter-spacing": @"normal",
                                                                     @"word-wrap": @"normal",
                                                                     @"white-space": @"nowrap",
                                                                     @"direction": @"ltr",
                                                                     @"-webkit-font-smoothing": @"antialiased",
                                                                     @"text-rendering": @"optimizeLegibility",
                                                                     @"-moz-osx-font-smoothing": @"grayscale",
                                                                     @"font-feature-settings": @"'liga'"
                                                                     }],

    // Mini size
    miniUpCssColor = [CPColor colorWithCSSDictionary:@{
                                                       @"background-color": A3ColorBackgroundWhite,
                                                       @"border-color": A3ColorActiveBorder,
                                                       @"border-style": @"solid",
                                                       @"border-top-width": @"1px",
                                                       @"border-left-width": @"1px",
                                                       @"border-right-width": @"1px",
                                                       @"border-bottom-width": @"0px",
                                                       @"border-top-left-radius": @"6px",
                                                       @"border-top-right-radius": @"6px",
                                                       @"box-sizing": @"border-box"
                                                       }
                                    beforeDictionary:@{}
                                     afterDictionary:@{
//                                                       @"border-color": A3ColorStepperArrow,
//                                                       @"width": @"3px",
//                                                       @"height": @"3px",
//                                                       @"box-sizing": @"border-box",
//                                                       @"border-style": @"solid",
//                                                       @"content": @"''",
//                                                       @"left": @"2px",
//                                                       @"top": @"3px",
//                                                       @"position": @"absolute",
//                                                       @"z-index": @"300",
//                                                       @"transform": @"rotate(45deg)",
//                                                       @"border-bottom-width": @"0px",
//                                                       @"border-right-width": @"0px",
//                                                       @"border-top-width": @"1px",
//                                                       @"border-left-width": @"1px"
                                                       @"width": @"9px",
                                                       @"height": @"8px",
                                                       @"top": @"-1px",
                                                       @"left": @"-1px",
                                                       @"content": @"'keyboard_arrow_up'",
                                                       @"color": A3ColorStepperArrow,
                                                       @"position": @"absolute",
                                                       @"z-index": @"300",
                                                       @"font-family": @"'Material Icons'",
                                                       @"font-weight": @"normal",
                                                       @"font-style": @"normal",
                                                       @"font-size": @"9px",
                                                       @"display": @"inline-block",
                                                       @"line-height": @"1",
                                                       @"text-transform": @"none",
                                                       @"letter-spacing": @"normal",
                                                       @"word-wrap": @"normal",
                                                       @"white-space": @"nowrap",
                                                       @"direction": @"ltr",
                                                       @"-webkit-font-smoothing": @"antialiased",
                                                       @"text-rendering": @"optimizeLegibility",
                                                       @"-moz-osx-font-smoothing": @"grayscale",
                                                       @"font-feature-settings": @"'liga'"
                                                       }],

    miniDisabledUpCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackgroundInactive,
                                                               @"border-color": A3ColorInactiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-top-width": @"1px",
                                                               @"border-left-width": @"1px",
                                                               @"border-right-width": @"1px",
                                                               @"border-bottom-width": @"0px",
                                                               @"border-top-left-radius": @"6px",
                                                               @"border-top-right-radius": @"6px",
                                                               @"box-sizing": @"border-box"
                                                               }
                                            beforeDictionary:@{}
                                             afterDictionary:@{
//                                                               @"border-color": A3ColorInactiveDarkBorder,
//                                                               @"width": @"3px",
//                                                               @"height": @"3px",
//                                                               @"box-sizing": @"border-box",
//                                                               @"border-style": @"solid",
//                                                               @"content": @"''",
//                                                               @"left": @"2px",
//                                                               @"top": @"3px",
//                                                               @"position": @"absolute",
//                                                               @"z-index": @"300",
//                                                               @"transform": @"rotate(45deg)",
//                                                               @"border-bottom-width": @"0px",
//                                                               @"border-right-width": @"0px",
//                                                               @"border-top-width": @"1px",
//                                                               @"border-left-width": @"1px"
                                                               @"width": @"9px",
                                                               @"height": @"8px",
                                                               @"top": @"-1px",
                                                               @"left": @"-1px",
                                                               @"content": @"'keyboard_arrow_up'",
                                                               @"color": A3ColorInactiveDarkBorder,
                                                               @"position": @"absolute",
                                                               @"z-index": @"300",
                                                               @"font-family": @"'Material Icons'",
                                                               @"font-weight": @"normal",
                                                               @"font-style": @"normal",
                                                               @"font-size": @"9px",
                                                               @"display": @"inline-block",
                                                               @"line-height": @"1",
                                                               @"text-transform": @"none",
                                                               @"letter-spacing": @"normal",
                                                               @"word-wrap": @"normal",
                                                               @"white-space": @"nowrap",
                                                               @"direction": @"ltr",
                                                               @"-webkit-font-smoothing": @"antialiased",
                                                               @"text-rendering": @"optimizeLegibility",
                                                               @"-moz-osx-font-smoothing": @"grayscale",
                                                               @"font-feature-settings": @"'liga'"
                                                               }],

    miniHighlightedUpCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": A3ColorBorderBlueHighlighted,
                                                                  @"border-color": A3ColorBorderBlueHighlighted,
                                                                  @"border-style": @"solid",
                                                                  @"border-top-width": @"1px",
                                                                  @"border-left-width": @"1px",
                                                                  @"border-right-width": @"1px",
                                                                  @"border-bottom-width": @"0px",
                                                                  @"border-top-left-radius": @"6px",
                                                                  @"border-top-right-radius": @"6px",
                                                                  @"box-sizing": @"border-box"
                                                                  }
                                               beforeDictionary:@{}
                                                afterDictionary:@{
//                                                                  @"border-color": A3ColorHighlightedStepperArrow,
//                                                                  @"width": @"3px",
//                                                                  @"height": @"3px",
//                                                                  @"box-sizing": @"border-box",
//                                                                  @"border-style": @"solid",
//                                                                  @"content": @"''",
//                                                                  @"left": @"2px",
//                                                                  @"top": @"3px",
//                                                                  @"position": @"absolute",
//                                                                  @"z-index": @"300",
//                                                                  @"transform": @"rotate(45deg)",
//                                                                  @"border-bottom-width": @"0px",
//                                                                  @"border-right-width": @"0px",
//                                                                  @"border-top-width": @"1px",
//                                                                  @"border-left-width": @"1px"
                                                                  @"width": @"9px",
                                                                  @"height": @"8px",
                                                                  @"top": @"-1px",
                                                                  @"left": @"-1px",
                                                                  @"content": @"'keyboard_arrow_up'",
                                                                  @"color": A3ColorHighlightedStepperArrow,
                                                                  @"position": @"absolute",
                                                                  @"z-index": @"300",
                                                                  @"font-family": @"'Material Icons'",
                                                                  @"font-weight": @"normal",
                                                                  @"font-style": @"normal",
                                                                  @"font-size": @"9px",
                                                                  @"display": @"inline-block",
                                                                  @"line-height": @"1",
                                                                  @"text-transform": @"none",
                                                                  @"letter-spacing": @"normal",
                                                                  @"word-wrap": @"normal",
                                                                  @"white-space": @"nowrap",
                                                                  @"direction": @"ltr",
                                                                  @"-webkit-font-smoothing": @"antialiased",
                                                                  @"text-rendering": @"optimizeLegibility",
                                                                  @"-moz-osx-font-smoothing": @"grayscale",
                                                                  @"font-feature-settings": @"'liga'"
                                                                  }],

    miniDownCssColor = [CPColor colorWithCSSDictionary:@{
                                                         @"background-color": A3ColorBackgroundWhite,
                                                         @"border-color": A3ColorActiveBorder,
                                                         @"border-style": @"solid",
                                                         @"border-top-width": @"0px",
                                                         @"border-left-width": @"1px",
                                                         @"border-right-width": @"1px",
                                                         @"border-bottom-width": @"1px",
                                                         @"border-bottom-left-radius": @"6px",
                                                         @"border-bottom-right-radius": @"6px",
                                                         @"box-sizing": @"border-box"
                                                         }
                                      beforeDictionary:@{}
                                       afterDictionary:@{
//                                                         @"border-color": A3ColorStepperArrow,
//                                                         @"width": @"3px",
//                                                         @"height": @"3px",
//                                                         @"box-sizing": @"border-box",
//                                                         @"border-style": @"solid",
//                                                         @"content": @"''",
//                                                         @"left": @"2px",
//                                                         @"top": @"0px",
//                                                         @"position": @"absolute",
//                                                         @"z-index": @"300",
//                                                         @"transform": @"rotate(45deg)",
//                                                         @"border-bottom-width": @"1px",
//                                                         @"border-right-width": @"1px",
//                                                         @"border-top-width": @"0px",
//                                                         @"border-left-width": @"0px"
                                                         @"width": @"9px",
                                                         @"height": @"8px",
                                                         @"top": @"-2px",
                                                         @"left": @"-1px",
                                                         @"content": @"'keyboard_arrow_down'",
                                                         @"color": A3ColorStepperArrow,
                                                         @"position": @"absolute",
                                                         @"z-index": @"300",
                                                         @"font-family": @"'Material Icons'",
                                                         @"font-weight": @"normal",
                                                         @"font-style": @"normal",
                                                         @"font-size": @"9px",
                                                         @"display": @"inline-block",
                                                         @"line-height": @"1",
                                                         @"text-transform": @"none",
                                                         @"letter-spacing": @"normal",
                                                         @"word-wrap": @"normal",
                                                         @"white-space": @"nowrap",
                                                         @"direction": @"ltr",
                                                         @"-webkit-font-smoothing": @"antialiased",
                                                         @"text-rendering": @"optimizeLegibility",
                                                         @"-moz-osx-font-smoothing": @"grayscale",
                                                         @"font-feature-settings": @"'liga'"
                                                         }],

    miniDisabledDownCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBackgroundInactive,
                                                                 @"border-color": A3ColorInactiveBorder,
                                                                 @"border-style": @"solid",
                                                                 @"border-top-width": @"0px",
                                                                 @"border-left-width": @"1px",
                                                                 @"border-right-width": @"1px",
                                                                 @"border-bottom-width": @"1px",
                                                                 @"border-bottom-left-radius": @"6px",
                                                                 @"border-bottom-right-radius": @"6px",
                                                                 @"box-sizing": @"border-box"
                                                                 }
                                              beforeDictionary:@{}
                                               afterDictionary:@{
//                                                                 @"border-color": A3ColorInactiveDarkBorder,
//                                                                 @"width": @"3px",
//                                                                 @"height": @"3px",
//                                                                 @"box-sizing": @"border-box",
//                                                                 @"border-style": @"solid",
//                                                                 @"content": @"''",
//                                                                 @"left": @"2px",
//                                                                 @"top": @"0px",
//                                                                 @"position": @"absolute",
//                                                                 @"z-index": @"300",
//                                                                 @"transform": @"rotate(45deg)",
//                                                                 @"border-bottom-width": @"1px",
//                                                                 @"border-right-width": @"1px",
//                                                                 @"border-top-width": @"0px",
//                                                                 @"border-left-width": @"0px"
                                                                 @"width": @"9px",
                                                                 @"height": @"8px",
                                                                 @"top": @"-2px",
                                                                 @"left": @"-1px",
                                                                 @"content": @"'keyboard_arrow_down'",
                                                                 @"color": A3ColorInactiveDarkBorder,
                                                                 @"position": @"absolute",
                                                                 @"z-index": @"300",
                                                                 @"font-family": @"'Material Icons'",
                                                                 @"font-weight": @"normal",
                                                                 @"font-style": @"normal",
                                                                 @"font-size": @"9px",
                                                                 @"display": @"inline-block",
                                                                 @"line-height": @"1",
                                                                 @"text-transform": @"none",
                                                                 @"letter-spacing": @"normal",
                                                                 @"word-wrap": @"normal",
                                                                 @"white-space": @"nowrap",
                                                                 @"direction": @"ltr",
                                                                 @"-webkit-font-smoothing": @"antialiased",
                                                                 @"text-rendering": @"optimizeLegibility",
                                                                 @"-moz-osx-font-smoothing": @"grayscale",
                                                                 @"font-feature-settings": @"'liga'"
                                                                 }],

    miniHighlightedDownCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorBorderBlueHighlighted,
                                                                    @"border-color": A3ColorBorderBlueHighlighted,
                                                                    @"border-style": @"solid",
                                                                    @"border-top-width": @"0px",
                                                                    @"border-left-width": @"1px",
                                                                    @"border-right-width": @"1px",
                                                                    @"border-bottom-width": @"1px",
                                                                    @"border-bottom-left-radius": @"6px",
                                                                    @"border-bottom-right-radius": @"6px",
                                                                    @"box-sizing": @"border-box"
                                                                    }
                                                 beforeDictionary:@{}
                                                  afterDictionary:@{
//                                                                    @"border-color": A3ColorHighlightedStepperArrow,
//                                                                    @"width": @"3px",
//                                                                    @"height": @"3px",
//                                                                    @"box-sizing": @"border-box",
//                                                                    @"border-style": @"solid",
//                                                                    @"content": @"''",
//                                                                    @"left": @"2px",
//                                                                    @"top": @"0px",
//                                                                    @"position": @"absolute",
//                                                                    @"z-index": @"300",
//                                                                    @"transform": @"rotate(45deg)",
//                                                                    @"border-bottom-width": @"1px",
//                                                                    @"border-right-width": @"1px",
//                                                                    @"border-top-width": @"0px",
//                                                                    @"border-left-width": @"0px"
                                                                    @"width": @"9px",
                                                                    @"height": @"8px",
                                                                    @"top": @"-2px",
                                                                    @"left": @"-1px",
                                                                    @"content": @"'keyboard_arrow_down'",
                                                                    @"color": A3ColorHighlightedStepperArrow,
                                                                    @"position": @"absolute",
                                                                    @"z-index": @"300",
                                                                    @"font-family": @"'Material Icons'",
                                                                    @"font-weight": @"normal",
                                                                    @"font-style": @"normal",
                                                                    @"font-size": @"9px",
                                                                    @"display": @"inline-block",
                                                                    @"line-height": @"1",
                                                                    @"text-transform": @"none",
                                                                    @"letter-spacing": @"normal",
                                                                    @"word-wrap": @"normal",
                                                                    @"white-space": @"nowrap",
                                                                    @"direction": @"ltr",
                                                                    @"-webkit-font-smoothing": @"antialiased",
                                                                    @"text-rendering": @"optimizeLegibility",
                                                                    @"-moz-osx-font-smoothing": @"grayscale",
                                                                    @"font-feature-settings": @"'liga'"
                                                                    }],

    themeValues =
    [
     [@"direct-nib2cib-adjustment",  YES],

     // CPThemeStateControlSizeRegular
     [@"bezel-color-up-button",      upCssColor,                            [CPThemeStateBordered]],
     [@"bezel-color-down-button",    downCssColor,                          [CPThemeStateBordered]],
     [@"bezel-color-up-button",      disabledUpCssColor,                    [CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color-down-button",    disabledDownCssColor,                  [CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color-up-button",      highlightedUpCssColor,                 [CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color-down-button",    highlightedDownCssColor,               [CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"up-button-size",             CGSizeMake(13.0, 11.0)],
     [@"down-button-size",           CGSizeMake(13.0, 11.0)],
     [@"nib2cib-adjustment-frame",   CGRectMake(3.0, -24.0, -6.0, -4.0)],

     // CPThemeStateControlSizeSmall
     [@"bezel-color-up-button",      smallUpCssColor,                       [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"bezel-color-down-button",    smallDownCssColor,                     [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"bezel-color-up-button",      smallDisabledUpCssColor,               [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color-down-button",    smallDisabledDownCssColor,             [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color-up-button",      smallHighlightedUpCssColor,            [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color-down-button",    smallHighlightedDownCssColor,          [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"up-button-size",             CGSizeMake(11.0, 10.0),                CPThemeStateControlSizeSmall],
     [@"down-button-size",           CGSizeMake(11.0, 9.0),                 CPThemeStateControlSizeSmall],
     [@"nib2cib-adjustment-frame",   CGRectMake(2.0, -21.0, -4.0, -3.0),    CPThemeStateControlSizeSmall],

     // CPThemeStateControlSizeMini
     [@"bezel-color-up-button",      miniUpCssColor,                        [CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"bezel-color-down-button",    miniDownCssColor,                      [CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"bezel-color-up-button",      miniDisabledUpCssColor,                [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color-down-button",    miniDisabledDownCssColor,              [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color-up-button",      miniHighlightedUpCssColor,             [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color-down-button",    miniHighlightedDownCssColor,           [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"up-button-size",             CGSizeMake(9.0, 8.0),                  CPThemeStateControlSizeMini],
     [@"down-button-size",           CGSizeMake(9.0, 7.0),                  CPThemeStateControlSizeMini],
     [@"nib2cib-adjustment-frame",   CGRectMake(2.0, -15.0, -4.0, 0.0),     CPThemeStateControlSizeMini],
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
    buttonAddHighlightedImage = PatternImage(@"rule-editor-button-add-highlighted-image.png", 20.0, 20.0),
    buttonRemoveHighlightedImage = PatternImage(@"rule-editor-button-remove-highlighted-image.png", 20.0, 20.0),
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
     [@"add-image",                      buttonAddHighlightedImage,              CPThemeStateHighlighted],
     [@"remove-image",                   buttonRemoveImage,                      CPThemeStateNormal],
     [@"remove-image",                   buttonRemoveHighlightedImage,           CPThemeStateHighlighted],
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

+ (CPProgressIndicator)themedCircularProgressIndicator
{
    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [progressBar setStyle:CPProgressIndicatorSpinningStyle];
    [progressBar setIndeterminate:NO];

    var themeValues =
    [
     [@"circular-border-color", [CPColor colorWithHexString:@"A0A0A0"]],
     [@"circular-border-size", 1],
     [@"circular-color", [CPColor colorWithHexString:@"5982DA"]]
     ];

    [self registerThemeValues:themeValues forView:progressBar];

    return progressBar;
}

+ (CPBox)themedBox
{
    var box = [[CPBox alloc] initWithFrame:CGRectMake(0, 0, 100, 100)],

    themeValues =
    [
     [@"background-color", [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": @"rgba(0,0,0,0.04)",
                                                             @"border-color": @"rgba(0,0,0,0.1)",
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"5px",
                                                             @"box-sizing": @"border-box"
                                                             }]],
     [@"border-color", [CPColor colorWithCSSDictionary:@{
                                                         @"background-color": @"rgba(0,0,0,0.1)"
                                                        }]],
//     [@"background-color", [CPColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.04]],
//     [@"background-color", [CPColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.04]],
     [@"border-width", 1.0],
//     [@"border-color", [CPColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.1]],
//     [@"corner-radius", 3.0],
//     [@"inner-shadow-offset", CGSizeMakeZero()],
//     [@"inner-shadow-color", nil],
//     [@"inner-shadow-size", 0.0],
     [@"content-margin", CGSizeMakeZero()],
     [@"title-font", [CPFont systemFontOfSize:11]],
     [@"title-left-offset", 10.0],
     [@"title-top-offset", -3.0],
     [@"title-color", A3CPColorActiveText],
     [@"nib2cib-adjustment-primary-frame",   CGRectMake(3, -4, -6, -6)], // (4, -3, -6, -6)
     [@"content-adjustment", CGRectMake(-1, -1, 2, 2)],
     [@"min-y-correction-no-title", 1],
     [@"min-y-correction-title", 2]
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

#pragma mark -
#pragma mark Windows

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

//    sheetShadow = PatternColor(@"window-attached-sheet-shadow.png", 1, 8), // FIXME: changer
    sheetShadow = [CPColor colorWithCSSDictionary:@{
                                                    @"background-color":    A3ColorBackground,
                                                    @"background-image":    @"linear-gradient(to bottom, rgba(216,216,216,1), rgba(216,216,216,0))"
                                                    }],

    resizeIndicator = PatternImage(@"window-resize-indicator.png", 12, 12), // FIXME: changer

    // Global
    themedWindowViewValues =
    [
     [@"shadow-inset",                   CGInsetMake(0, 0, 0, 0)],
     [@"shadow-distance",                5],
     [@"window-shadow-color",            @"0px 5px 10px 0px rgba(0, 0, 0, 0.25)"],
     [@"resize-indicator",               resizeIndicator],
     [@"attached-sheet-shadow-color",    sheetShadow,           CPThemeStateNormal],
     [@"shadow-height",                  5],
     [@"shadown-horizontal-offset",      2],
     [@"sheet-vertical-offset",          -1],
     [@"size-indicator",                 CGSizeMake(12, 12)],
     [@"border-top-left-radius",         @"0px"], // 6
     [@"border-top-right-radius",        @"0px"], // 6
     [@"border-bottom-left-radius",      @"7px"],
     [@"border-bottom-right-radius",     @"7px"]
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

    bezelHeadCssColor = [CPColor colorWithCSSDictionary:@{
                                                          @"background-color": A3ColorWindowHeadActive, // was A3ColorBackgroundHighlighted
                                                          @"border-top-color": A3ColorWindowBorder, // A3ColorBorderMedium,
                                                          @"border-top-style": @"solid",
                                                          @"border-top-width": @"1px",
                                                          @"border-left-color": A3ColorWindowBorder, // A3ColorBorderMedium,
                                                          @"border-left-style": @"solid",
                                                          @"border-left-width": @"1px",
                                                          @"border-right-color": A3ColorWindowBorder, // A3ColorBorderMedium,
                                                          @"border-right-style": @"solid",
                                                          @"border-right-width": @"1px",
                                                          @"border-top-left-radius": @"6px",
                                                          @"border-top-right-radius": @"6px",
                                                          @"border-bottom-left-radius": @"0px",
                                                          @"border-bottom-right-radius": @"0px",
                                                          @"box-sizing": @"border-box"
                                                          }],

    inactiveBezelHeadCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": A3ColorWindowHeadInactive, // was A3ColorBackground
                                                                  @"border-top-color": A3ColorWindowBorder, // A3ColorBorderMedium,
                                                                  @"border-top-style": @"solid",
                                                                  @"border-top-width": @"1px",
                                                                  @"border-left-color": A3ColorWindowBorder, // A3ColorBorderMedium,
                                                                  @"border-left-style": @"solid",
                                                                  @"border-left-width": @"1px",
                                                                  @"border-right-color": A3ColorWindowBorder, // A3ColorBorderMedium,
                                                                  @"border-right-style": @"solid",
                                                                  @"border-right-width": @"1px",
                                                                  @"border-top-left-radius": @"6px",
                                                                  @"border-top-right-radius": @"6px",
                                                                  @"border-bottom-left-radius": @"0px",
                                                                  @"border-bottom-right-radius": @"0px",
                                                                  @"box-sizing": @"border-box"
                                                                  }],

    solidCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"background-color": A3ColorBackgroundHighlighted
                                                      }],

    bezelSheetHeadColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": A3ColorBackground, //A3ColorWindowHeadActive, // was A3ColorBackgroundHighlighted
                                                            @"border-top-color": A3ColorWindowBorder, // A3ColorBorderMedium,
                                                            @"border-top-style": @"solid",
                                                            @"border-top-width": @"1px",
                                                            @"border-left-color": A3ColorWindowBorder, // A3ColorBorderMedium,
                                                            @"border-left-style": @"solid",
                                                            @"border-left-width": @"1px",
                                                            @"border-right-color": A3ColorWindowBorder, // A3ColorBorderMedium,
                                                            @"border-right-style": @"solid",
                                                            @"border-right-width": @"1px",
                                                            @"border-top-left-radius": @"0px",
                                                            @"border-top-right-radius": @"0px",
                                                            @"border-bottom-left-radius": @"0px",
                                                            @"border-bottom-right-radius": @"0px",
                                                            @"box-sizing": @"border-box"
                                                            }],

//    bezelSheetHeadColor = PatternColor(
//                                       "window-standard-head-sheet-solid{position}.png",
//                                       {
//                                       positions: "full",
//                                       width: 5.0,
//                                       height: 1.0
//                                       }),

    bezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"background-color": A3ColorBackground,
                                                      @"border-color": A3ColorWindowBorder, // A3ColorBorderMedium,
                                                      @"border-style": @"solid",
                                                      @"border-width": @"1px",
                                                      @"border-top-left-radius": @"0px",
                                                      @"border-top-right-radius": @"0px",
                                                      @"border-bottom-left-radius": @"7px",
                                                      @"border-bottom-right-radius": @"7px",
                                                      @"box-sizing": @"border-box"
                                                      }],

    dividerCssColor = [CPColor colorWithCSSDictionary:@{
                                                        @"background-color": A3ColorBorderMedium
                                                        }],

    shadowCssColor = [CPColor colorWithCSSDictionary:@{
                                                       @"text-shadow": @"2px 2px 2px rgba(0, 0, 0, 0.5)"
                                                       }],

    // Legacy buttons

    // --- Close button

    closeButtonImage = [CPImage imageWithCSSDictionary:@{
                                                         @"border-style": @"none",
                                                         @"border-radius": @"50%",
                                                         @"box-sizing": @"border-box",
                                                         @"background-color": A3ColorWindowButtonBackground
                                                         }
                                      beforeDictionary:@{
                                                         @"background-color": A3ColorWindowHeadActive,
                                                         @"width": @"2px",
                                                         @"height": @"8px",
                                                         @"box-sizing": @"border-box",
                                                         @"border-style": @"none",
                                                         @"content": @"''",
                                                         @"left": @"5px",
                                                         @"top": @"2px",
                                                         @"position": @"absolute",
                                                         @"z-index": @"300",
                                                         @"transform": @"rotate(-45deg)"
                                                         }
                                       afterDictionary:@{
                                                         @"background-color": A3ColorWindowHeadActive,
                                                         @"width": @"2px",
                                                         @"height": @"8px",
                                                         @"box-sizing": @"border-box",
                                                         @"border-style": @"none",
                                                         @"content": @"''",
                                                         @"left": @"5px",
                                                         @"top": @"2px",
                                                         @"position": @"absolute",
                                                         @"z-index": @"300",
                                                         @"transform": @"rotate(45deg)"
                                                         }
                                                  size:CGSizeMake(12,12)],

    closeButtonImageOver = [CPImage imageWithCSSDictionary:@{
                                                             @"border-style": @"none",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorWindowButtonBackground
                                                             }
                                          beforeDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"width": @"2px",
                                                             @"height": @"8px",
                                                             @"box-sizing": @"border-box",
                                                             @"border-style": @"none",
                                                             @"content": @"''",
                                                             @"left": @"5px",
                                                             @"top": @"2px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300",
                                                             @"transform": @"rotate(-45deg)"
                                                             }
                                           afterDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"width": @"2px",
                                                             @"height": @"8px",
                                                             @"box-sizing": @"border-box",
                                                             @"border-style": @"none",
                                                             @"content": @"''",
                                                             @"left": @"5px",
                                                             @"top": @"2px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300",
                                                             @"transform": @"rotate(45deg)"
                                                             }
                                                      size:CGSizeMake(12,12)],

    closeButtonImageInactive = [CPImage imageWithCSSDictionary:@{
                                                                 @"border-style": @"none",
                                                                 @"border-radius": @"50%",
                                                                 @"box-sizing": @"border-box",
                                                                 @"background-color": A3ColorWindowButtonBackgroundLight
                                                                 }
                                              beforeDictionary:@{
                                                                 @"background-color": A3ColorWindowHeadInactive,
                                                                 @"width": @"2px",
                                                                 @"height": @"8px",
                                                                 @"box-sizing": @"border-box",
                                                                 @"border-style": @"none",
                                                                 @"content": @"''",
                                                                 @"left": @"5px",
                                                                 @"top": @"2px",
                                                                 @"position": @"absolute",
                                                                 @"z-index": @"300",
                                                                 @"transform": @"rotate(-45deg)"
                                                                 }
                                               afterDictionary:@{
                                                                 @"background-color": A3ColorWindowHeadInactive,
                                                                 @"width": @"2px",
                                                                 @"height": @"8px",
                                                                 @"box-sizing": @"border-box",
                                                                 @"border-style": @"none",
                                                                 @"content": @"''",
                                                                 @"left": @"5px",
                                                                 @"top": @"2px",
                                                                 @"position": @"absolute",
                                                                 @"z-index": @"300",
                                                                 @"transform": @"rotate(45deg)"
                                                                 }
                                                          size:CGSizeMake(12,12)],

    closeButtonImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                    @"border-style": @"none",
                                                                    @"border-radius": @"50%",
                                                                    @"box-sizing": @"border-box",
                                                                    @"background-color": A3ColorWindowButtonBackgroundDark
                                                                    }
                                                 beforeDictionary:@{
                                                                    @"background-color": A3ColorWindowHeadInactive,
                                                                    @"width": @"2px",
                                                                    @"height": @"8px",
                                                                    @"box-sizing": @"border-box",
                                                                    @"border-style": @"none",
                                                                    @"content": @"''",
                                                                    @"left": @"5px",
                                                                    @"top": @"2px",
                                                                    @"position": @"absolute",
                                                                    @"z-index": @"300",
                                                                    @"transform": @"rotate(-45deg)"
                                                                    }
                                                  afterDictionary:@{
                                                                    @"background-color": A3ColorWindowHeadInactive,
                                                                    @"width": @"2px",
                                                                    @"height": @"8px",
                                                                    @"box-sizing": @"border-box",
                                                                    @"border-style": @"none",
                                                                    @"content": @"''",
                                                                    @"left": @"5px",
                                                                    @"top": @"2px",
                                                                    @"position": @"absolute",
                                                                    @"z-index": @"300",
                                                                    @"transform": @"rotate(45deg)"
                                                                    }
                                                             size:CGSizeMake(12,12)],

    // --- Unsaved close button

    unsavedCloseButtonImage = [CPImage imageWithCSSDictionary:@{
                                                                @"border-style": @"none",
                                                                @"border-radius": @"50%",
                                                                @"box-sizing": @"border-box",
                                                                @"background-color": A3ColorWindowButtonBackground
                                                                }
                                             beforeDictionary:@{
                                                                @"background-color": A3ColorWindowHeadActive,
                                                                @"border-radius": @"50%",
                                                                @"width": @"6px",
                                                                @"height": @"6px",
                                                                @"box-sizing": @"border-box",
                                                                @"border-style": @"none",
                                                                @"content": @"''",
                                                                @"left": @"3px",
                                                                @"top": @"3px",
                                                                @"position": @"absolute",
                                                                @"z-index": @"300"
                                                                }
                                              afterDictionary:nil
                                                         size:CGSizeMake(12,12)],

    unsavedCloseButtonImageOver = [CPImage imageWithCSSDictionary:@{
                                                                    @"border-style": @"none",
                                                                    @"border-radius": @"50%",
                                                                    @"box-sizing": @"border-box",
                                                                    @"background-color": A3ColorWindowButtonBackground
                                                                    }
                                                 beforeDictionary:@{
                                                                    @"background-color": A3ColorBackgroundWhite,
                                                                    @"border-radius": @"50%",
                                                                    @"width": @"6px",
                                                                    @"height": @"6px",
                                                                    @"box-sizing": @"border-box",
                                                                    @"border-style": @"none",
                                                                    @"content": @"''",
                                                                    @"left": @"3px",
                                                                    @"top": @"3px",
                                                                    @"position": @"absolute",
                                                                    @"z-index": @"300"
                                                                    }
                                                  afterDictionary:nil
                                                             size:CGSizeMake(12,12)],

    unsavedCloseButtonImageInactive = [CPImage imageWithCSSDictionary:@{
                                                                        @"border-style": @"none",
                                                                        @"border-radius": @"50%",
                                                                        @"box-sizing": @"border-box",
                                                                        @"background-color": A3ColorWindowButtonBackgroundLight
                                                                        }
                                                     beforeDictionary:@{
                                                                        @"background-color": A3ColorWindowHeadInactive,
                                                                        @"border-radius": @"50%",
                                                                        @"width": @"6px",
                                                                        @"height": @"6px",
                                                                        @"box-sizing": @"border-box",
                                                                        @"border-style": @"none",
                                                                        @"content": @"''",
                                                                        @"left": @"3px",
                                                                        @"top": @"3px",
                                                                        @"position": @"absolute",
                                                                        @"z-index": @"300"
                                                                        }
                                                      afterDictionary:nil
                                                                 size:CGSizeMake(12,12)],

    unsavedCloseButtonImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                           @"border-style": @"none",
                                                                           @"border-radius": @"50%",
                                                                           @"box-sizing": @"border-box",
                                                                           @"background-color": A3ColorWindowButtonBackgroundDark
                                                                           }
                                                        beforeDictionary:@{
                                                                           @"background-color": A3ColorWindowHeadInactive,
                                                                           @"border-radius": @"50%",
                                                                           @"width": @"6px",
                                                                           @"height": @"6px",
                                                                           @"box-sizing": @"border-box",
                                                                           @"border-style": @"none",
                                                                           @"content": @"''",
                                                                           @"left": @"3px",
                                                                           @"top": @"3px",
                                                                           @"position": @"absolute",
                                                                           @"z-index": @"300"
                                                                           }
                                                         afterDictionary:nil
                                                                    size:CGSizeMake(12,12)],

    // --- Minimize button

    minimizeButtonImage = [CPImage imageWithCSSDictionary:@{
                                                            @"border-style": @"none",
                                                            @"border-radius": @"50%",
                                                            @"box-sizing": @"border-box",
                                                            @"background-color": A3ColorWindowButtonBackground
                                                            }
                                         beforeDictionary:@{
                                                            @"background-color": A3ColorWindowHeadActive,
                                                            @"width": @"6px",
                                                            @"height": @"2px",
                                                            @"box-sizing": @"border-box",
                                                            @"border-style": @"none",
                                                            @"content": @"''",
                                                            @"left": @"3px",
                                                            @"top": @"5px",
                                                            @"position": @"absolute",
                                                            @"z-index": @"300"
                                                            }
                                          afterDictionary:@{
                                                            }
                                                     size:CGSizeMake(12,12)],

    minimizeButtonImageOver = [CPImage imageWithCSSDictionary:@{
                                                                @"border-style": @"none",
                                                                @"border-radius": @"50%",
                                                                @"box-sizing": @"border-box",
                                                                @"background-color": A3ColorWindowButtonBackground
                                                                }
                                             beforeDictionary:@{
                                                                @"background-color": A3ColorBackgroundWhite,
                                                                @"width": @"6px",
                                                                @"height": @"2px",
                                                                @"box-sizing": @"border-box",
                                                                @"border-style": @"none",
                                                                @"content": @"''",
                                                                @"left": @"3px",
                                                                @"top": @"5px",
                                                                @"position": @"absolute",
                                                                @"z-index": @"300"
                                                                }
                                              afterDictionary:@{
                                                                }
                                                         size:CGSizeMake(12,12)],

    minimizeButtonImageInactive = [CPImage imageWithCSSDictionary:@{
                                                                    @"border-style": @"none",
                                                                    @"border-radius": @"50%",
                                                                    @"box-sizing": @"border-box",
                                                                    @"background-color": A3ColorWindowButtonBackgroundLight
                                                                    }
                                                 beforeDictionary:@{
                                                                    @"background-color": A3ColorWindowHeadInactive,
                                                                    @"width": @"6px",
                                                                    @"height": @"2px",
                                                                    @"box-sizing": @"border-box",
                                                                    @"border-style": @"none",
                                                                    @"content": @"''",
                                                                    @"left": @"3px",
                                                                    @"top": @"5px",
                                                                    @"position": @"absolute",
                                                                    @"z-index": @"300"
                                                                    }
                                                  afterDictionary:@{
                                                                    }
                                                             size:CGSizeMake(12,12)],

    minimizeButtonImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                       @"border-style": @"none",
                                                                       @"border-radius": @"50%",
                                                                       @"box-sizing": @"border-box",
                                                                       @"background-color": A3ColorWindowButtonBackgroundDark
                                                                       }
                                                    beforeDictionary:@{
                                                                       @"background-color": A3ColorWindowHeadInactive,
                                                                       @"width": @"6px",
                                                                       @"height": @"2px",
                                                                       @"box-sizing": @"border-box",
                                                                       @"border-style": @"none",
                                                                       @"content": @"''",
                                                                       @"left": @"3px",
                                                                       @"top": @"5px",
                                                                       @"position": @"absolute",
                                                                       @"z-index": @"300"
                                                                       }
                                                     afterDictionary:@{
                                                                       }
                                                                size:CGSizeMake(12,12)],

    // --- Zoom button

    zoomButtonImage = [CPImage imageWithCSSDictionary:@{
                                                        @"border-style": @"none",
                                                        @"border-radius": @"50%",
                                                        @"box-sizing": @"border-box",
                                                        @"background-color": A3ColorWindowButtonBackground
                                                        }
                                     beforeDictionary:@{
                                                        @"background-color": A3ColorWindowHeadActive,
                                                        @"width": @"6px",
                                                        @"height": @"2px",
                                                        @"box-sizing": @"border-box",
                                                        @"border-style": @"none",
                                                        @"content": @"''",
                                                        @"left": @"3px",
                                                        @"top": @"5px",
                                                        @"position": @"absolute",
                                                        @"z-index": @"300"
                                                        }
                                      afterDictionary:@{
                                                        @"background-color": A3ColorWindowHeadActive,
                                                        @"width": @"2px",
                                                        @"height": @"6px",
                                                        @"box-sizing": @"border-box",
                                                        @"border-style": @"none",
                                                        @"content": @"''",
                                                        @"left": @"5px",
                                                        @"top": @"3px",
                                                        @"position": @"absolute",
                                                        @"z-index": @"300"
                                                        }
                                                 size:CGSizeMake(12,12)],

    zoomButtonImageOver = [CPImage imageWithCSSDictionary:@{
                                                            @"border-style": @"none",
                                                            @"border-radius": @"50%",
                                                            @"box-sizing": @"border-box",
                                                            @"background-color": A3ColorWindowButtonBackground
                                                            }
                                         beforeDictionary:@{
                                                            @"background-color": A3ColorBackgroundWhite, //A3ColorWindowButtonZoom, //A3ColorWindowHeadActive,
                                                            @"width": @"6px",
                                                            @"height": @"2px",
                                                            @"box-sizing": @"border-box",
                                                            @"border-style": @"none",
                                                            @"content": @"''",
                                                            @"left": @"3px",
                                                            @"top": @"5px",
                                                            @"position": @"absolute",
                                                            @"z-index": @"300"
                                                            }
                                          afterDictionary:@{
                                                            @"background-color": A3ColorBackgroundWhite, //A3ColorWindowButtonZoom, //A3ColorWindowHeadActive,
                                                            @"width": @"2px",
                                                            @"height": @"6px",
                                                            @"box-sizing": @"border-box",
                                                            @"border-style": @"none",
                                                            @"content": @"''",
                                                            @"left": @"5px",
                                                            @"top": @"3px",
                                                            @"position": @"absolute",
                                                            @"z-index": @"300"
                                                            }
                                                     size:CGSizeMake(12,12)],

    zoomButtonImageInactive = [CPImage imageWithCSSDictionary:@{
                                                                @"border-style": @"none",
                                                                @"border-radius": @"50%",
                                                                @"box-sizing": @"border-box",
                                                                @"background-color": A3ColorWindowButtonBackgroundLight
                                                                }
                                             beforeDictionary:@{
                                                                @"background-color": A3ColorWindowHeadInactive,
                                                                @"width": @"6px",
                                                                @"height": @"2px",
                                                                @"box-sizing": @"border-box",
                                                                @"border-style": @"none",
                                                                @"content": @"''",
                                                                @"left": @"3px",
                                                                @"top": @"5px",
                                                                @"position": @"absolute",
                                                                @"z-index": @"300"
                                                                }
                                              afterDictionary:@{
                                                                @"background-color": A3ColorWindowHeadInactive,
                                                                @"width": @"2px",
                                                                @"height": @"6px",
                                                                @"box-sizing": @"border-box",
                                                                @"border-style": @"none",
                                                                @"content": @"''",
                                                                @"left": @"5px",
                                                                @"top": @"3px",
                                                                @"position": @"absolute",
                                                                @"z-index": @"300"
                                                                }
                                                         size:CGSizeMake(12,12)],

    zoomButtonImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                   @"border-style": @"none",
                                                                   @"border-radius": @"50%",
                                                                   @"box-sizing": @"border-box",
                                                                   @"background-color": A3ColorWindowButtonBackgroundDark
                                                                   }
                                                beforeDictionary:@{
                                                                   @"background-color": A3ColorWindowHeadInactive,
                                                                   @"width": @"6px",
                                                                   @"height": @"2px",
                                                                   @"box-sizing": @"border-box",
                                                                   @"border-style": @"none",
                                                                   @"content": @"''",
                                                                   @"left": @"3px",
                                                                   @"top": @"5px",
                                                                   @"position": @"absolute",
                                                                   @"z-index": @"300"
                                                                   }
                                                 afterDictionary:@{
                                                                   @"background-color": A3ColorWindowHeadInactive,
                                                                   @"width": @"2px",
                                                                   @"height": @"6px",
                                                                   @"box-sizing": @"border-box",
                                                                   @"border-style": @"none",
                                                                   @"content": @"''",
                                                                   @"left": @"5px",
                                                                   @"top": @"3px",
                                                                   @"position": @"absolute",
                                                                   @"z-index": @"300"
                                                                   }
                                                            size:CGSizeMake(12,12)],

    // Windows buttons

    // --- Close button

    winCloseButtonImage = [CPImage imageWithCSSDictionary:@{}
                                         beforeDictionary:@{
                                                            @"background-color": A3ColorWindowButtonBackground,
                                                            @"width": @"1px",
                                                            @"height": @"11px",
                                                            @"box-sizing": @"border-box",
                                                            @"border-style": @"none",
                                                            @"content": @"''",
                                                            @"left": @"5px",
                                                            @"top": @"0px",
                                                            @"position": @"absolute",
                                                            @"z-index": @"300",
                                                            @"transform": @"rotate(-45deg)"
                                                            }
                                          afterDictionary:@{
                                                            @"background-color": A3ColorWindowButtonBackground,
                                                            @"width": @"1px",
                                                            @"height": @"11px",
                                                            @"box-sizing": @"border-box",
                                                            @"border-style": @"none",
                                                            @"content": @"''",
                                                            @"left": @"5px",
                                                            @"top": @"0px",
                                                            @"position": @"absolute",
                                                            @"z-index": @"300",
                                                            @"transform": @"rotate(45deg)"
                                                            }
                                                     size:CGSizeMake(12,12)],

    winCloseButtonImageOver = [CPImage imageWithCSSDictionary:@{}
                                             beforeDictionary:@{
                                                                @"background-color": A3ColorWindowButtonBackground,
                                                                @"width": @"1px",
                                                                @"height": @"11px",
                                                                @"box-sizing": @"border-box",
                                                                @"border-style": @"none",
                                                                @"content": @"''",
                                                                @"left": @"5px",
                                                                @"top": @"0px",
                                                                @"position": @"absolute",
                                                                @"z-index": @"300",
                                                                @"transform": @"rotate(-45deg)"
                                                                }
                                              afterDictionary:@{
                                                                @"background-color": A3ColorWindowButtonBackground,
                                                                @"width": @"1px",
                                                                @"height": @"11px",
                                                                @"box-sizing": @"border-box",
                                                                @"border-style": @"none",
                                                                @"content": @"''",
                                                                @"left": @"5px",
                                                                @"top": @"0px",
                                                                @"position": @"absolute",
                                                                @"z-index": @"300",
                                                                @"transform": @"rotate(45deg)"
                                                                }
                                                         size:CGSizeMake(12,12)],

    winCloseButtonImageInactive = [CPImage imageWithCSSDictionary:@{}
                                                 beforeDictionary:@{
                                                                    @"background-color": A3ColorWindowButtonBackgroundLight,
                                                                    @"width": @"1px",
                                                                    @"height": @"11px",
                                                                    @"box-sizing": @"border-box",
                                                                    @"border-style": @"none",
                                                                    @"content": @"''",
                                                                    @"left": @"5px",
                                                                    @"top": @"0px",
                                                                    @"position": @"absolute",
                                                                    @"z-index": @"300",
                                                                    @"transform": @"rotate(-45deg)"
                                                                    }
                                                  afterDictionary:@{
                                                                    @"background-color": A3ColorWindowButtonBackgroundLight,
                                                                    @"width": @"1px",
                                                                    @"height": @"11px",
                                                                    @"box-sizing": @"border-box",
                                                                    @"border-style": @"none",
                                                                    @"content": @"''",
                                                                    @"left": @"5px",
                                                                    @"top": @"0px",
                                                                    @"position": @"absolute",
                                                                    @"z-index": @"300",
                                                                    @"transform": @"rotate(45deg)"
                                                                    }
                                                             size:CGSizeMake(12,12)],

    winCloseButtonImageHighlighted = [CPImage imageWithCSSDictionary:@{}
                                                    beforeDictionary:@{
                                                                       @"background-color": A3ColorWindowButtonBackgroundDark,
                                                                       @"width": @"1px",
                                                                       @"height": @"11px",
                                                                       @"box-sizing": @"border-box",
                                                                       @"border-style": @"none",
                                                                       @"content": @"''",
                                                                       @"left": @"5px",
                                                                       @"top": @"0px",
                                                                       @"position": @"absolute",
                                                                       @"z-index": @"300",
                                                                       @"transform": @"rotate(-45deg)"
                                                                       }
                                                     afterDictionary:@{
                                                                       @"background-color": A3ColorWindowButtonBackgroundDark,
                                                                       @"width": @"1px",
                                                                       @"height": @"11px",
                                                                       @"box-sizing": @"border-box",
                                                                       @"border-style": @"none",
                                                                       @"content": @"''",
                                                                       @"left": @"5px",
                                                                       @"top": @"0px",
                                                                       @"position": @"absolute",
                                                                       @"z-index": @"300",
                                                                       @"transform": @"rotate(45deg)"
                                                                       }
                                                                size:CGSizeMake(12,12)],

    // --- Unsaved close button

    // Windows doesn't use unsaved close button, so we'll use normal close button

    // --- Minimize button

    winMinimizeButtonImage = [CPImage imageWithCSSDictionary:@{}
                                            beforeDictionary:@{
                                                               @"background-color": A3ColorWindowButtonBackground,
                                                               @"width": @"11px",
                                                               @"height": @"1px",
                                                               @"box-sizing": @"border-box",
                                                               @"border-style": @"none",
                                                               @"content": @"''",
                                                               @"left": @"0px",
                                                               @"top": @"5px",
                                                               @"position": @"absolute",
                                                               @"z-index": @"300"
                                                               }
                                             afterDictionary:nil
                                                        size:CGSizeMake(12,12)],

    winMinimizeButtonImageOver = [CPImage imageWithCSSDictionary:@{}
                                                beforeDictionary:@{
                                                                   @"background-color": A3ColorWindowButtonBackground,
                                                                   @"width": @"11px",
                                                                   @"height": @"1px",
                                                                   @"box-sizing": @"border-box",
                                                                   @"border-style": @"none",
                                                                   @"content": @"''",
                                                                   @"left": @"0px",
                                                                   @"top": @"5px",
                                                                   @"position": @"absolute",
                                                                   @"z-index": @"300"
                                                                   }
                                                 afterDictionary:nil
                                                            size:CGSizeMake(12,12)],

    winMinimizeButtonImageInactive = [CPImage imageWithCSSDictionary:@{}
                                                    beforeDictionary:@{
                                                                       @"background-color": A3ColorWindowButtonBackgroundLight,
                                                                       @"width": @"11px",
                                                                       @"height": @"1px",
                                                                       @"box-sizing": @"border-box",
                                                                       @"border-style": @"none",
                                                                       @"content": @"''",
                                                                       @"left": @"0px",
                                                                       @"top": @"5px",
                                                                       @"position": @"absolute",
                                                                       @"z-index": @"300"
                                                                       }
                                                     afterDictionary:nil
                                                                size:CGSizeMake(12,12)],

    winMinimizeButtonImageHighlighted = [CPImage imageWithCSSDictionary:@{}
                                                       beforeDictionary:@{
                                                                          @"background-color": A3ColorWindowButtonBackgroundDark,
                                                                          @"width": @"11px",
                                                                          @"height": @"1px",
                                                                          @"box-sizing": @"border-box",
                                                                          @"border-style": @"none",
                                                                          @"content": @"''",
                                                                          @"left": @"0px",
                                                                          @"top": @"5px",
                                                                          @"position": @"absolute",
                                                                          @"z-index": @"300"
                                                                          }
                                                        afterDictionary:nil
                                                                   size:CGSizeMake(12,12)],

    // --- Zoom button

    winZoomButtonImage = [CPImage imageWithCSSDictionary:@{}
                                        beforeDictionary:@{
                                                           @"border-color": A3ColorWindowButtonBackground,
                                                           @"width": @"11px",
                                                           @"height": @"11px",
                                                           @"box-sizing": @"border-box",
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"content": @"''",
                                                           @"left": @"0px",
                                                           @"top": @"0px",
                                                           @"position": @"absolute",
                                                           @"z-index": @"300"
                                                           }
                                         afterDictionary:nil
                                                    size:CGSizeMake(12,12)],

    winZoomButtonImageOver = [CPImage imageWithCSSDictionary:@{}
                                            beforeDictionary:@{
                                                               @"border-color": A3ColorWindowButtonBackground,
                                                               @"width": @"11px",
                                                               @"height": @"11px",
                                                               @"box-sizing": @"border-box",
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"content": @"''",
                                                               @"left": @"0px",
                                                               @"top": @"0px",
                                                               @"position": @"absolute",
                                                               @"z-index": @"300"
                                                               }
                                             afterDictionary:nil
                                                        size:CGSizeMake(12,12)],

    winZoomButtonImageInactive = [CPImage imageWithCSSDictionary:@{}
                                                beforeDictionary:@{
                                                                   @"border-color": A3ColorWindowButtonBackgroundLight,
                                                                   @"width": @"11px",
                                                                   @"height": @"11px",
                                                                   @"box-sizing": @"border-box",
                                                                   @"border-style": @"solid",
                                                                   @"border-width": @"1px",
                                                                   @"content": @"''",
                                                                   @"left": @"0px",
                                                                   @"top": @"0px",
                                                                   @"position": @"absolute",
                                                                   @"z-index": @"300"
                                                                   }
                                                 afterDictionary:nil
                                                            size:CGSizeMake(12,12)],

    winZoomButtonImageHighlighted = [CPImage imageWithCSSDictionary:@{}
                                                   beforeDictionary:@{
                                                                      @"border-color": A3ColorWindowButtonBackgroundDark,
                                                                      @"width": @"11px",
                                                                      @"height": @"11px",
                                                                      @"box-sizing": @"border-box",
                                                                      @"border-style": @"solid",
                                                                      @"border-width": @"1px",
                                                                      @"content": @"''",
                                                                      @"left": @"0px",
                                                                      @"top": @"0px",
                                                                      @"position": @"absolute",
                                                                      @"z-index": @"300"
                                                                      }
                                                    afterDictionary:nil
                                                               size:CGSizeMake(12,12)],

    resizeIndicator = PatternImage(@"window-resize-indicator.png", 12, 12),

    themeValues =
    [
     [@"gradient-height",            31.0],
     [@"bezel-head-color",           inactiveBezelHeadCssColor, CPThemeStateNormal],
     [@"bezel-head-color",           bezelHeadCssColor, CPThemeStateKeyWindow],
     [@"bezel-head-color",           bezelHeadCssColor, CPThemeStateMainWindow],
     [@"bezel-head-sheet-color",     [CPColor redColor]], //bezelSheetHeadColor],
     [@"solid-color",                solidCssColor],

     [@"title-font",                 [CPFont systemFontOfSize:CPFontCurrentSystemSize+1]], // [CPFont systemFontOfSize:CPFontCurrentSystemSize]],
     [@"title-text-color",           A3CPColorInactiveText],
     [@"title-text-color",           A3CPColorActiveText, CPThemeStateKeyWindow],
     [@"title-text-color",           A3CPColorActiveText, CPThemeStateMainWindow],
     [@"title-text-shadow-color",    nil],
     [@"title-text-shadow-offset",   CGSizeMakeZero()],
     [@"title-alignment",            CPCenterTextAlignment],
     // FIXME: Make this to CPLineBreakByTruncatingMiddle once it's implemented.
     [@"title-line-break-mode",      CPLineBreakByTruncatingTail],
     [@"title-vertical-alignment",   CPCenterVerticalTextAlignment],
//     [@"title-bar-height",           31],

     [@"divider-color",                         dividerCssColor],
     [@"body-color",                            bezelCssColor],
     [@"title-bar-height",                      31],
     [@"title-margin",                          4],
     [@"frame-outset",                          CGInsetMake(1, 1, 1, 1)],

     [@"close-image-button",                    closeButtonImageInactive,          CPThemeStateNormal],
     [@"close-image-button",                    closeButtonImage,                  CPThemeStateKeyWindow],
     [@"close-image-button",                    closeButtonImage,                  CPThemeStateMainWindow],
     [@"close-image-button",                    closeButtonImageOver,              CPThemeStateHovered],
     [@"close-image-highlighted-button",        closeButtonImageHighlighted],

     [@"unsaved-image-button",                  unsavedCloseButtonImageInactive,   CPThemeStateNormal],
     [@"unsaved-image-button",                  unsavedCloseButtonImage,           CPThemeStateKeyWindow],
     [@"unsaved-image-button",                  unsavedCloseButtonImage,           CPThemeStateMainWindow],
     [@"unsaved-image-button",                  unsavedCloseButtonImageOver,       CPThemeStateHovered],
     [@"unsaved-image-highlighted-button",      unsavedCloseButtonImageHighlighted],

     [@"minimize-image-button",                 minimizeButtonImageInactive,       CPThemeStateNormal],
     [@"minimize-image-button",                 minimizeButtonImage,               CPThemeStateKeyWindow],
     [@"minimize-image-button",                 minimizeButtonImage,               CPThemeStateMainWindow],
     [@"minimize-image-button",                 minimizeButtonImageOver,           CPThemeStateHovered],
     [@"minimize-image-highlighted-button",     minimizeButtonImageHighlighted],

     [@"zoom-image-button",                     zoomButtonImageInactive,           CPThemeStateNormal],
     [@"zoom-image-button",                     zoomButtonImage,                   CPThemeStateKeyWindow],
     [@"zoom-image-button",                     zoomButtonImage,                   CPThemeStateMainWindow],
     [@"zoom-image-button",                     zoomButtonImageOver,               CPThemeStateHovered],
     [@"zoom-image-highlighted-button",         zoomButtonImageHighlighted],

     [@"close-image-size",                      CGSizeMake(12.0, 12.0)],
     [@"close-image-origin",                    CGPointMake(10.0, 10.0)],
     [@"minimize-image-size",                   CGSizeMake(12.0, 12.0)],
     [@"minimize-image-origin",                 CGPointMake(30.0, 10.0)],
     [@"zoom-image-size",                       CGSizeMake(12.0, 12.0)],
     [@"zoom-image-origin",                     CGPointMake(50.0, 10.0)],

     [@"resize-indicator",                      resizeIndicator],
     [@"size-indicator",                        CGSizeMake(12, 12)],

     // For Windows platform (CPThemeStateWindowsPlatform)

     [@"close-image-button",                    winCloseButtonImageInactive,           [CPThemeStateWindowsPlatform, CPThemeStateNormal]],
     [@"close-image-button",                    winCloseButtonImage,                   [CPThemeStateWindowsPlatform, CPThemeStateKeyWindow]],
     [@"close-image-button",                    winCloseButtonImage,                   [CPThemeStateWindowsPlatform, CPThemeStateMainWindow]],
     [@"close-image-button",                    winCloseButtonImageOver,               [CPThemeStateWindowsPlatform, CPThemeStateHovered]],
     [@"close-image-highlighted-button",        winCloseButtonImageHighlighted,        CPThemeStateWindowsPlatform],

     [@"unsaved-image-button",                  winCloseButtonImageInactive,           [CPThemeStateWindowsPlatform, CPThemeStateNormal]],
     [@"unsaved-image-button",                  winCloseButtonImage,                   [CPThemeStateWindowsPlatform, CPThemeStateKeyWindow]],
     [@"unsaved-image-button",                  winCloseButtonImage,                   [CPThemeStateWindowsPlatform, CPThemeStateMainWindow]],
     [@"unsaved-image-button",                  winCloseButtonImageOver,               [CPThemeStateWindowsPlatform, CPThemeStateHovered]],
     [@"unsaved-image-highlighted-button",      winCloseButtonImageHighlighted,        CPThemeStateWindowsPlatform],

     [@"minimize-image-button",                 winMinimizeButtonImageInactive,        [CPThemeStateWindowsPlatform, CPThemeStateNormal]],
     [@"minimize-image-button",                 winMinimizeButtonImage,                [CPThemeStateWindowsPlatform, CPThemeStateKeyWindow]],
     [@"minimize-image-button",                 winMinimizeButtonImage,                [CPThemeStateWindowsPlatform, CPThemeStateMainWindow]],
     [@"minimize-image-button",                 winMinimizeButtonImageOver,            [CPThemeStateWindowsPlatform, CPThemeStateHovered]],
     [@"minimize-image-highlighted-button",     winMinimizeButtonImageHighlighted,     CPThemeStateWindowsPlatform],

     [@"zoom-image-button",                     winZoomButtonImageInactive,            [CPThemeStateWindowsPlatform, CPThemeStateNormal]],
     [@"zoom-image-button",                     winZoomButtonImage,                    [CPThemeStateWindowsPlatform, CPThemeStateKeyWindow]],
     [@"zoom-image-button",                     winZoomButtonImage,                    [CPThemeStateWindowsPlatform, CPThemeStateMainWindow]],
     [@"zoom-image-button",                     winZoomButtonImageOver,                [CPThemeStateWindowsPlatform, CPThemeStateHovered]],
     [@"zoom-image-highlighted-button",         winZoomButtonImageHighlighted,         CPThemeStateWindowsPlatform],

     [@"close-image-size",                      CGSizeMake(12.0, 12.0),                CPThemeStateWindowsPlatform],
     [@"close-image-origin",                    CGPointMake(-22.0, 10.0),              CPThemeStateWindowsPlatform],
     [@"minimize-image-size",                   CGSizeMake(12.0, 12.0),                CPThemeStateWindowsPlatform],
     [@"minimize-image-origin",                 CGPointMake(-62.0, 10.0),              CPThemeStateWindowsPlatform],
     [@"zoom-image-size",                       CGSizeMake(12.0, 12.0),                CPThemeStateWindowsPlatform],
     [@"zoom-image-origin",                     CGPointMake(-42.0, 10.0),              CPThemeStateWindowsPlatform],

     [@"resize-indicator",                      resizeIndicator,                       CPThemeStateWindowsPlatform],
     [@"size-indicator",                        CGSizeMake(12, 12),                    CPThemeStateWindowsPlatform]

     ];

//    [self registerThemeValues:themeValues forView:standardWindowView inherit:themedWindowViewValues];
    [self registerThemeValues:themeValues forView:standardWindowView inheritFrom:[self themedWindowView]];

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

#pragma mark -

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

#pragma mark -
#pragma mark Menus

+ (_CPMenuItemMenuBarView)themedMenuItemMenuBarView
{
    var menuItemMenuBarView = [[_CPMenuItemMenuBarView alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)],

    themeValues =
    [
     [@"horizontal-margin",             9.0],
     [@"submenu-indicator-margin",      3.0],
     [@"vertical-margin",               3.0] // was 4
     ];

    [self registerThemeValues:themeValues forView:menuItemMenuBarView];

    return menuItemMenuBarView;
}

+ (_CPMenuItemStandardView)themedMenuItemStandardView
{
    var menuItemStandardView = [[_CPMenuItemStandardView alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)],

    // Regular size
    menuItemDefaultOnStateImage = [CPImage imageWithCSSDictionary:nil
                                                 beforeDictionary:nil
                                                  afterDictionary:@{
                                                                    @"border-color": A3ColorMenuCheckmark,
                                                                    @"width": @"5px",
                                                                    @"height": @"10px",
                                                                    @"box-sizing": @"border-box",
                                                                    @"border-style": @"solid",
                                                                    @"content": @"''",
                                                                    @"left": @"4px",
                                                                    @"top": @"0px",
                                                                    @"position": @"absolute",
                                                                    @"z-index": @"300",
                                                                    @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                                    @"border-bottom-width": @"2px",
                                                                    @"border-right-width": @"2px",
                                                                    @"border-top-width": @"0px",
                                                                    @"border-left-width": @"0px"
                                                                    }
                                                             size:CGSizeMake(14,14)],

    menuItemDefaultOnStateHighlightedImage = [CPImage imageWithCSSDictionary:nil
                                                            beforeDictionary:nil
                                                             afterDictionary:@{
                                                                               @"border-color": A3ColorBackgroundWhite,
                                                                               @"width": @"5px",
                                                                               @"height": @"10px",
                                                                               @"box-sizing": @"border-box",
                                                                               @"border-style": @"solid",
                                                                               @"content": @"''",
                                                                               @"left": @"4px",
                                                                               @"top": @"0px",
                                                                               @"position": @"absolute",
                                                                               @"z-index": @"300",
                                                                               @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                                               @"border-bottom-width": @"2px",
                                                                               @"border-right-width": @"2px",
                                                                               @"border-top-width": @"0px",
                                                                               @"border-left-width": @"0px"
                                                                               }
                                                                        size:CGSizeMake(14,14)],

    menuItemDefaultMixedStateImage = [CPImage imageWithCSSDictionary:nil
                                                    beforeDictionary:nil
                                                     afterDictionary:@{
                                                                       @"background-color": A3ColorMenuCheckmark,
                                                                       @"width": @"6px",
                                                                       @"height": @"2px",
                                                                       @"box-sizing": @"border-box",
                                                                       @"content": @"''",
                                                                       @"left": @"3px",
                                                                       @"top": @"5px",
                                                                       @"position": @"absolute",
                                                                       @"z-index": @"300"
                                                                       }
                                                                size:CGSizeMake(14,14)],

    menuItemDefaultMixedStateHighlightedImage = [CPImage imageWithCSSDictionary:nil
                                                               beforeDictionary:nil
                                                                afterDictionary:@{
                                                                                  @"background-color": A3ColorBackgroundWhite,
                                                                                  @"width": @"6px",
                                                                                  @"height": @"2px",
                                                                                  @"box-sizing": @"border-box",
                                                                                  @"content": @"''",
                                                                                  @"left": @"3px",
                                                                                  @"top": @"5px",
                                                                                  @"position": @"absolute",
                                                                                  @"z-index": @"300"
                                                                                  }
                                                                           size:CGSizeMake(14,14)],

    submenuIndicatorImage = [CPImage imageWithCSSDictionary:@{
                                                              @"width": @"0px",
                                                              @"height": @"0px",
                                                              @"border-top": @"5px solid transparent",
                                                              @"border-left": @"8px solid " + A3ColorMenuCheckmark,
                                                              @"border-bottom": @"5px solid transparent"
                                                              }
                                           beforeDictionary:nil
                                            afterDictionary:nil
                                                       size:CGSizeMake(8, 10)],

    submenuIndicatorHighlightedImage = [CPImage imageWithCSSDictionary:@{
                                                                         @"width": @"0px",
                                                                         @"height": @"0px",
                                                                         @"border-top": @"5px solid transparent",
                                                                         @"border-left": @"8px solid " + A3ColorBackgroundWhite,
                                                                         @"border-bottom": @"5px solid transparent"
                                                                         }
                                                      beforeDictionary:nil
                                                       afterDictionary:nil
                                                                  size:CGSizeMake(8, 10)],

    // Small size
    smallMenuItemDefaultOnStateImage = [CPImage imageWithCSSDictionary:nil
                                                      beforeDictionary:nil
                                                       afterDictionary:@{
                                                                         @"border-color": A3ColorMenuCheckmark,
                                                                         @"width": @"5px",
                                                                         @"height": @"8px",
                                                                         @"box-sizing": @"border-box",
                                                                         @"border-style": @"solid",
                                                                         @"content": @"''",
                                                                         @"left": @"3px",
                                                                         @"top": @"1px",
                                                                         @"position": @"absolute",
                                                                         @"z-index": @"300",
                                                                         @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                                         @"border-bottom-width": @"2px",
                                                                         @"border-right-width": @"2px",
                                                                         @"border-top-width": @"0px",
                                                                         @"border-left-width": @"0px"
                                                                         }
                                                                  size:CGSizeMake(12,12)],

    smallMenuItemDefaultOnStateHighlightedImage = [CPImage imageWithCSSDictionary:nil
                                                                 beforeDictionary:nil
                                                                  afterDictionary:@{
                                                                                    @"border-color": A3ColorBackgroundWhite,
                                                                                    @"width": @"5px",
                                                                                    @"height": @"8px",
                                                                                    @"box-sizing": @"border-box",
                                                                                    @"border-style": @"solid",
                                                                                    @"content": @"''",
                                                                                    @"left": @"3px",
                                                                                    @"top": @"1px",
                                                                                    @"position": @"absolute",
                                                                                    @"z-index": @"300",
                                                                                    @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                                                    @"border-bottom-width": @"2px",
                                                                                    @"border-right-width": @"2px",
                                                                                    @"border-top-width": @"0px",
                                                                                    @"border-left-width": @"0px"
                                                                                    }
                                                                             size:CGSizeMake(12,12)],

    smallMenuItemDefaultMixedStateImage = [CPImage imageWithCSSDictionary:nil
                                                         beforeDictionary:nil
                                                          afterDictionary:@{
                                                                            @"background-color": A3ColorMenuCheckmark,
                                                                            @"width": @"6px",
                                                                            @"height": @"2px",
                                                                            @"box-sizing": @"border-box",
                                                                            @"content": @"''",
                                                                            @"left": @"2px",
                                                                            @"top": @"5px",
                                                                            @"position": @"absolute",
                                                                            @"z-index": @"300"
                                                                            }
                                                                     size:CGSizeMake(12,12)],

    smallMenuItemDefaultMixedStateHighlightedImage = [CPImage imageWithCSSDictionary:nil
                                                                    beforeDictionary:nil
                                                                     afterDictionary:@{
                                                                                       @"background-color": A3ColorBackgroundWhite,
                                                                                       @"width": @"6px",
                                                                                       @"height": @"2px",
                                                                                       @"box-sizing": @"border-box",
                                                                                       @"content": @"''",
                                                                                       @"left": @"2px",
                                                                                       @"top": @"5px",
                                                                                       @"position": @"absolute",
                                                                                       @"z-index": @"300"
                                                                                       }
                                                                                size:CGSizeMake(12,12)],

    smallSubmenuIndicatorImage = [CPImage imageWithCSSDictionary:@{
                                                                   @"width": @"0px",
                                                                   @"height": @"0px",
                                                                   @"border-top": @"5px solid transparent",
                                                                   @"border-left": @"8px solid " + A3ColorMenuCheckmark,
                                                                   @"border-bottom": @"5px solid transparent"
                                                                   }
                                                beforeDictionary:nil
                                                 afterDictionary:nil
                                                            size:CGSizeMake(8, 10)],

    smallSubmenuIndicatorHighlightedImage = [CPImage imageWithCSSDictionary:@{
                                                                              @"width": @"0px",
                                                                              @"height": @"0px",
                                                                              @"border-top": @"5px solid transparent",
                                                                              @"border-left": @"8px solid " + A3ColorBackgroundWhite,
                                                                              @"border-bottom": @"5px solid transparent"
                                                                              }
                                                           beforeDictionary:nil
                                                            afterDictionary:nil
                                                                       size:CGSizeMake(8, 10)],

    // Mini size
    miniMenuItemDefaultOnStateImage = [CPImage imageWithCSSDictionary:nil
                                                     beforeDictionary:nil
                                                      afterDictionary:@{
                                                                        @"border-color": A3ColorMenuCheckmark,
                                                                        @"width": @"4px",
                                                                        @"height": @"6px",
                                                                        @"box-sizing": @"border-box",
                                                                        @"border-style": @"solid",
                                                                        @"content": @"''",
                                                                        @"left": @"3px",
                                                                        @"top": @"1px",
                                                                        @"position": @"absolute",
                                                                        @"z-index": @"300",
                                                                        @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                                        @"border-bottom-width": @"2px",
                                                                        @"border-right-width": @"2px",
                                                                        @"border-top-width": @"0px",
                                                                        @"border-left-width": @"0px"
                                                                        }
                                                                 size:CGSizeMake(10,10)],

    miniMenuItemDefaultOnStateHighlightedImage = [CPImage imageWithCSSDictionary:nil
                                                                beforeDictionary:nil
                                                                 afterDictionary:@{
                                                                                   @"border-color": A3ColorBackgroundWhite,
                                                                                   @"width": @"4px",
                                                                                   @"height": @"6px",
                                                                                   @"box-sizing": @"border-box",
                                                                                   @"border-style": @"solid",
                                                                                   @"content": @"''",
                                                                                   @"left": @"3px",
                                                                                   @"top": @"1px",
                                                                                   @"position": @"absolute",
                                                                                   @"z-index": @"300",
                                                                                   @"transform": @"matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 0, 0)",
                                                                                   @"border-bottom-width": @"2px",
                                                                                   @"border-right-width": @"2px",
                                                                                   @"border-top-width": @"0px",
                                                                                   @"border-left-width": @"0px"
                                                                                   }
                                                                            size:CGSizeMake(10,10)],

    miniMenuItemDefaultMixedStateImage = [CPImage imageWithCSSDictionary:nil
                                                        beforeDictionary:nil
                                                         afterDictionary:@{
                                                                           @"background-color": A3ColorMenuCheckmark,
                                                                           @"width": @"4px",
                                                                           @"height": @"1px",
                                                                           @"box-sizing": @"border-box",
                                                                           @"content": @"''",
                                                                           @"left": @"3px",
                                                                           @"top": @"4px",
                                                                           @"position": @"absolute",
                                                                           @"z-index": @"300"
                                                                           }
                                                                    size:CGSizeMake(10,10)],

    miniMenuItemDefaultMixedStateHighlightedImage = [CPImage imageWithCSSDictionary:nil
                                                                   beforeDictionary:nil
                                                                    afterDictionary:@{
                                                                                      @"background-color": A3ColorBackgroundWhite,
                                                                                      @"width": @"4px",
                                                                                      @"height": @"1px",
                                                                                      @"box-sizing": @"border-box",
                                                                                      @"content": @"''",
                                                                                      @"left": @"3px",
                                                                                      @"top": @"4px",
                                                                                      @"position": @"absolute",
                                                                                      @"z-index": @"300"
                                                                                      }
                                                                               size:CGSizeMake(10,10)],

    miniSubmenuIndicatorImage = [CPImage imageWithCSSDictionary:@{
                                                                  @"width": @"0px",
                                                                  @"height": @"0px",
                                                                  @"border-top": @"5px solid transparent",
                                                                  @"border-left": @"8px solid " + A3ColorMenuCheckmark,
                                                                  @"border-bottom": @"5px solid transparent"
                                                                  }
                                               beforeDictionary:nil
                                                afterDictionary:nil
                                                           size:CGSizeMake(8, 10)],

    miniSubmenuIndicatorHighlightedImage = [CPImage imageWithCSSDictionary:@{
                                                                             @"width": @"0px",
                                                                             @"height": @"0px",
                                                                             @"border-top": @"5px solid transparent",
                                                                             @"border-left": @"8px solid " + A3ColorBackgroundWhite,
                                                                             @"border-bottom": @"5px solid transparent"
                                                                             }
                                                          beforeDictionary:nil
                                                           afterDictionary:nil
                                                                      size:CGSizeMake(8, 10)],

    themeValues =
    [
     [@"submenu-indicator-color",                                   A3CPColorActiveText],
     [@"menu-item-selection-color",                                 @"A3CPColorBorderBlue"],
     [@"menu-item-text-color",                                      @"A3CPColorActiveText"],
     [@"menu-item-disabled-text-color",                             A3CPColorInactiveText],
     [@"menu-item-text-shadow-color",                               nil],
     [@"menu-item-default-off-state-image",                         [CPImage dummyCSSImageOfSize:CGSizeMake(14,14)]],
     [@"menu-item-default-off-state-highlighted-image",             [CPImage dummyCSSImageOfSize:CGSizeMake(14,14)]],

     [@"menu-item-default-on-state-image",                          menuItemDefaultOnStateImage],
     [@"menu-item-default-on-state-image",                          menuItemDefaultOnStateImage,                    CPThemeStateControlSizeRegular],
     [@"menu-item-default-on-state-image",                          smallMenuItemDefaultOnStateImage,               CPThemeStateControlSizeSmall],
     [@"menu-item-default-on-state-image",                          miniMenuItemDefaultOnStateImage,                CPThemeStateControlSizeMini],

     [@"menu-item-default-on-state-highlighted-image",              menuItemDefaultOnStateHighlightedImage],
     [@"menu-item-default-on-state-highlighted-image",              menuItemDefaultOnStateHighlightedImage,         CPThemeStateControlSizeRegular],
     [@"menu-item-default-on-state-highlighted-image",              smallMenuItemDefaultOnStateHighlightedImage,    CPThemeStateControlSizeSmall],
     [@"menu-item-default-on-state-highlighted-image",              miniMenuItemDefaultOnStateHighlightedImage,     CPThemeStateControlSizeMini],

     [@"menu-item-default-mixed-state-image",                       menuItemDefaultMixedStateImage],
     [@"menu-item-default-mixed-state-image",                       menuItemDefaultMixedStateImage,                 CPThemeStateControlSizeRegular],
     [@"menu-item-default-mixed-state-image",                       smallMenuItemDefaultMixedStateImage,            CPThemeStateControlSizeSmall],
     [@"menu-item-default-mixed-state-image",                       miniMenuItemDefaultMixedStateImage,             CPThemeStateControlSizeMini],

     [@"menu-item-default-mixed-state-highlighted-image",           menuItemDefaultMixedStateHighlightedImage],
     [@"menu-item-default-mixed-state-highlighted-image",           menuItemDefaultMixedStateHighlightedImage,      CPThemeStateControlSizeRegular],
     [@"menu-item-default-mixed-state-highlighted-image",           smallMenuItemDefaultMixedStateHighlightedImage, CPThemeStateControlSizeSmall],
     [@"menu-item-default-mixed-state-highlighted-image",           miniMenuItemDefaultMixedStateHighlightedImage,  CPThemeStateControlSizeMini],

     [@"submenu-indicator-image",                                   submenuIndicatorImage],
     [@"submenu-indicator-image",                                   submenuIndicatorImage,                          CPThemeStateControlSizeRegular],
     [@"submenu-indicator-image",                                   smallSubmenuIndicatorImage,                     CPThemeStateControlSizeSmall],
     [@"submenu-indicator-image",                                   smallSubmenuIndicatorImage,                     CPThemeStateControlSizeMini],

     [@"submenu-indicator-highlighted-image",                       submenuIndicatorHighlightedImage],
     [@"submenu-indicator-highlighted-image",                       submenuIndicatorHighlightedImage,               CPThemeStateControlSizeRegular],
     [@"submenu-indicator-highlighted-image",                       miniSubmenuIndicatorHighlightedImage,           CPThemeStateControlSizeSmall],
     [@"submenu-indicator-highlighted-image",                       miniSubmenuIndicatorHighlightedImage,           CPThemeStateControlSizeMini],

     [@"menu-item-separator-color",                                 A3CPColorInactiveBorder],
     [@"menu-item-separator-height",                                2.0],
     [@"menu-item-separator-view-height",                           12.0],
     [@"left-margin",                                               1.0],
     [@"right-margin",                                              17.0],
     [@"state-column-width",                                        19.0],
     [@"indentation-width",                                         12.0],

     [@"vertical-margin",                                           1.0],
     [@"vertical-margin",                                           1.0,       CPThemeStateControlSizeRegular],
     [@"vertical-margin",                                           1.0,       CPThemeStateControlSizeSmall],
     [@"vertical-margin",                                           1.0,       CPThemeStateControlSizeMini],

     [@"vertical-offset",                                           -1.0],
     [@"vertical-offset",                                           -1.0,      CPThemeStateControlSizeRegular],
     [@"vertical-offset",                                           -1.0,      CPThemeStateControlSizeSmall],
     [@"vertical-offset",                                           -1.0,      CPThemeStateControlSizeMini],

     [@"right-columns-margin",                                      30.0]
     ];

    [self registerThemeValues:themeValues forView:menuItemStandardView];

    return menuItemStandardView;
}

+ (_CPMenuView)themedMenuView
{
    var menuView = [[_CPMenuView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 100.0)],

    menuWindowMoreAboveImage = [CPImage imageWithCSSDictionary:@{
                                                                 @"top": @"5px",
                                                                 @"width": @"0px",
                                                                 @"height": @"0px",
                                                                 @"border-left": @"5px solid transparent",
                                                                 @"border-bottom": @"8px solid " + A3ColorMenuCheckmark,
                                                                 @"border-right": @"5px solid transparent"
                                                                 }
                                              beforeDictionary:nil
                                               afterDictionary:nil
                                                          size:CGSizeMake(10, 18)],

    menuWindowMoreBelowImage = [CPImage imageWithCSSDictionary:@{
                                                                 @"top": @"5px",
                                                                 @"width": @"0px",
                                                                 @"height": @"0px",
                                                                 @"border-left": @"5px solid transparent",
                                                                 @"border-top": @"8px solid " + A3ColorMenuCheckmark,
                                                                 @"border-right": @"5px solid transparent"
                                                                 }
                                              beforeDictionary:nil
                                               afterDictionary:nil
                                                          size:CGSizeMake(10, 18)],

    generalIconNew = PatternImage(@"menu-general-icon-new.png", 16.0, 16.0),
    generalIconNewHighlighted = PatternImage(@"menu-general-icon-new-highlighted.png", 16.0, 16.0),
    generalIconOpen = PatternImage(@"menu-general-icon-open.png", 16.0, 16.0),
    generalIconOpenHighlighted = PatternImage(@"menu-general-icon-open-highlighted.png", 16.0, 16.0),
    generalIconSave = PatternImage(@"menu-general-icon-save.png", 16.0, 16.0),
    generalIconSaveHighlighted = PatternImage(@"menu-general-icon-save-highlighted.png", 16.0, 16.0),

    menuWindowPopUpBackgroundStyleColor = [CPColor colorWithCSSDictionary:@{
                                                                            @"background-color": A3ColorMenuLightBackground, // A3ColorBackground,
                                                                            @"border-color": A3ColorMenuBorder,
                                                                            @"border-style": @"solid",
                                                                            @"border-width": @"1px",
                                                                            @"border-top-left-radius": @"6px",
                                                                            @"border-top-right-radius": @"6px",
                                                                            @"border-bottom-left-radius": @"7px",
                                                                            @"border-bottom-right-radius": @"7px",
                                                                            @"box-sizing": @"border-box" // @"border-box"
                                                                            }],

    menuWindowMenuBarBackgroundStyleColor = [CPColor colorWithCSSDictionary:@{
                                                                              @"background-color": A3ColorMenuLightBackground, // A3ColorBackground,
                                                                              @"border-top-color": A3ColorBackground,
                                                                              @"border-bottom-color": A3ColorMenuBorder,
                                                                              @"border-left-color": A3ColorMenuBorder,
                                                                              @"border-right-color": A3ColorMenuBorder,
                                                                              @"border-style": @"solid",
                                                                              @"border-top-width": @"0px",
                                                                              @"border-left-width": @"1px",
                                                                              @"border-right-width": @"1px",
                                                                              @"border-bottom-width": @"1px",
                                                                              @"border-top-left-radius": @"0px",
                                                                              @"border-top-right-radius": @"0px",
                                                                              @"border-bottom-left-radius": @"7px",
                                                                              @"border-bottom-right-radius": @"7px",
                                                                              @"box-sizing": @"border-box" // @"border-box"
                                                                              }],

    menuBarWindowBackgroundColor = [CPColor colorWithCSSDictionary:@{
                                                                     @"background-color": A3ColorMenuLightBackground, // A3ColorBackground,
                                                                     @"border-bottom-color": A3ColorMenuBorder, // A3ColorBackgroundHighlighted,
                                                                     @"border-bottom-style": @"solid",
                                                                     @"border-bottom-width": @"1px",
                                                                     @"border-radius": @"0px",
                                                                     @"box-sizing": @"border-box"
                                                                     }],

    menuBarWindowBackgroundSelectedColor = [CPColor colorWithCSSDictionary:@{
                                                                             @"background-color": A3ColorBorderBlueHighlighted,
                                                                             @"border-bottom-color": A3ColorBackgroundHighlighted,
                                                                             @"border-bottom-style": @"solid",
                                                                             @"border-bottom-width": @"1px",
                                                                             @"box-sizing": @"border-box"
                                                                             }],

    themeValues =
    [
     [@"menu-window-more-above-image",                       menuWindowMoreAboveImage], // FIXME: changer
     [@"menu-window-more-below-image",                       menuWindowMoreBelowImage], // FIXME: changer
     [@"menu-window-pop-up-background-style-color",          menuWindowPopUpBackgroundStyleColor],
     [@"menu-window-menu-bar-background-style-color",        menuWindowMenuBarBackgroundStyleColor],
     [@"menu-window-margin-inset",                           CGInsetMake(4.0, 0.0, 6.0, 0.0)], // was CGInsetMake(5.0, 1.0, 5.0, 1.0)
     [@"menu-window-scroll-indicator-height",                16.0],
     [@"menu-window-submenu-delta-x",                        -2.0],
     [@"menu-window-submenu-delta-y",                        -4.0], // equals to top inset of menu-window-margin-inset
     [@"menu-window-submenu-first-level-delta-y",            -1.0],

     [@"menu-bar-window-background-color",                   menuBarWindowBackgroundColor],
     [@"menu-bar-window-background-selected-color",          menuBarWindowBackgroundSelectedColor],
     [@"menu-bar-window-font",                               [CPFont systemFontOfSize:13.0]], // was bold
     [@"menu-bar-window-first-item-font",                    [CPFont boldSystemFontOfSize:13.0]],
     [@"menu-bar-window-height",                             23.0], // was 30.0
     [@"menu-bar-window-margin",                             10.0],
     [@"menu-bar-window-left-margin",                        10.0],
     [@"menu-bar-window-right-margin",                       10.0],

     [@"menu-bar-text-color",                                @"A3CPColorActiveText"], // was [CPColor colorWithRed:0.051 green:0.2 blue:0.275 alpha:1.0]
     [@"menu-bar-title-color",                               [CPColor redColor]], // was [CPColor colorWithRed:0.051 green:0.2 blue:0.275 alpha:1.0]  FIXME: supprimer ?
     [@"menu-bar-text-shadow-color",                         nil], // was [CPColor whiteColor]
     [@"menu-bar-title-shadow-color",                        nil], // was [CPColor whiteColor]
     [@"menu-bar-highlight-color",                           menuBarWindowBackgroundSelectedColor],
     [@"menu-bar-highlight-text-color",                      A3CPColorDefaultText], // was [CPColor whiteColor]
     [@"menu-bar-highlight-text-shadow-color",               nil], // was [CPColor blackColor]
     [@"menu-bar-height",                                    23.0], // was 30.0
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

#pragma mark -

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

+ (CPTabView)themedTabView
{
    var tabView = [[CPTabView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

    themeValues =
    [
     [@"nib2cib-adjustment-frame",  CGRectMake(7.0, -10.0, -14.0, -16.0)], // !!! Called in awakeFromNib, so not yet inverted (Y origin)
     [@"should-center-on-border",   YES],
     [@"box-content-inset",         CGInsetMake(16, 4, 4, 2)] // !!! left&top = 2 BUT we have to count the border of the box for width&height (so bottom&right = 2+1+1)
     ];

    [self registerThemeValues:themeValues forView:tabView];

    return tabView;
}

@end


#pragma mark -

//@implementation Aristo3HUDThemeDescriptor : BKThemeDescriptor
//{
//}
//
//+ (CPString)themeName
//{
//    return @"Aristo3-HUD";
//}
//
//+ (CPArray)themeShowcaseExcludes
//{
//    return ["alert"];
//}
//
//+ (CPColor)defaultShowcaseBackgroundColor
//{
//    return [CPColor blackColor];
//}
//
//+ (CPArray)defaultThemeOverridesAddedTo:(CPArray)themeValues
//{
//    var overrides = [CPArray arrayWithObjects:
//                     [@"text-color",         [CPColor colorWithHexString:@"cdcdcd"]],
//                     [@"text-color",         [CPColor colorWithCalibratedWhite:1.0 alpha:0.6], CPThemeStateDisabled],
//                     [@"text-shadow-color",  [CPColor blackColor]],
//                     [@"text-shadow-color",  [CPColor blackColor], CPThemeStateDisabled],
//                     [@"text-shadow-offset", CGSizeMake(0, 1.0)]
//                     ];
//
//    if (themeValues)
//        [overrides addObjectsFromArray:themeValues];
//
//    return overrides;
//}
//
//+ (CPPopUpButton)themedSegmentedControl
//{
//    var segmentedControl = [Aristo3ThemeDescriptor makeSegmentedControl];
//
//    [self registerThemeValues:[self defaultThemeOverridesAddedTo:nil] forView:segmentedControl inherit:themedSegmentedControlValues];
//
//    return segmentedControl;
//}
//
//+ (CPButton)button
//{
//    var button = [Aristo3ThemeDescriptor makeButton];
//
//    [self registerThemeValues:[self defaultThemeOverridesAddedTo:nil] forView:button inherit:themedButtonValues];
//
//    return button;
//}
//
//+ (CPButton)themedStandardButton
//{
//    var button = [self button];
//
//    [button setTitle:@"Cancel"];
//
//    return button;
//}
//
//+ (CPButton)themedDefaultButton
//{
//    var button = [self button];
//
//    [button setTitle:@"OK"];
//    [button setThemeState:CPThemeStateDefault];
//
//    return button;
//}
//
//+ (CPSlider)themedHorizontalSlider
//{
//    var slider = [Aristo3ThemeDescriptor makeHorizontalSlider];
//
//    [self registerThemeValues:[self defaultThemeOverridesAddedTo:nil] forView:slider inherit:themedHorizontalSliderValues];
//
//    return slider;
//}
//
//+ (CPSlider)themedVerticalSlider
//{
//    var slider = [Aristo3ThemeDescriptor makeVerticalSlider];
//
//    [self registerThemeValues:[self defaultThemeOverridesAddedTo:nil] forView:slider inherit:themedVerticalSliderValues];
//
//    return slider;
//}
//
//+ (CPSlider)themedCircularSlider
//{
//    var slider = [Aristo3ThemeDescriptor makeCircularSlider];
//
//    [self registerThemeValues:[self defaultThemeOverridesAddedTo:nil] forView:slider inherit:themedCircularSliderValues];
//
//    return slider;
//}
//
//+ (CPAlert)themedAlert
//{
//    var alert = [CPAlert new],
//
//    hudSpecificValues =
//    [
//     [@"message-text-color",             [CPColor whiteColor]],
//     [@"informative-text-color",         [CPColor whiteColor]],
//     [@"suppression-button-text-color",  [CPColor whiteColor]]
//     ];
//
//    [self registerThemeValues:hudSpecificValues forView:alert inherit:themedAlertValues];
//
//    return [alert themeView];
//}
//
//+ (CPProgressIndicator)themedBarProgressIndicator
//{
//    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 75, 16)];
//    [progressBar setDoubleValue:30];
//
//    [self registerThemeValues:nil forView:progressBar inherit:themedProgressIndicator];
//
//    return progressBar;
//
//}
//
//+ (CPProgressIndicator)themedIndeterminateBarProgressIndicator
//{
//    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 75, 16)];
//    [progressBar setIndeterminate:YES];
//
//    [self registerThemeValues:nil forView:progressBar inherit:themedIndeterminateProgressIndicator];
//
//    return progressBar;
//}
//
//+ (CPCheckBox)themedCheckBoxButton
//{
//    var button = [CPCheckBox checkBoxWithTitle:@"Checkbox"];
//
//    [button setThemeState:CPThemeStateSelected];
//
//    var imageNormal = PatternImage("HUD/check-box-image.png", 21.0, 21.0),
//    imageSelected = PatternImage("HUD/check-box-image-selected.png", 21.0, 21.0),
//    imageSelectedHighlighted = PatternImage("HUD/check-box-image-selected-highlighted.png", 21.0, 21.0),
//    imageSelectedDisabled = PatternImage("HUD/check-box-image-selected.png", 21.0, 21.0),
//    imageDisabled = PatternImage("HUD/check-box-image.png", 21.0, 21.0),
//    imageHighlighted = PatternImage("HUD/check-box-image-highlighted.png", 21.0, 21.0),
//    mixedHighlightedImage = PatternImage("HUD/check-box-image-mixed-highlighted.png", 21.0, 21.0),
//    mixedDisabledImage = PatternImage("HUD/check-box-image-mixed.png", 21.0, 21.0),
//    mixedImage = PatternImage("HUD/check-box-image-mixed.png", 21.0, 21.0),
//
//    hudSpecific =
//    [
//     [@"image",          imageNormal,                        CPThemeStateNormal],
//     [@"image",          imageSelected,                      CPThemeStateSelected],
//     [@"image",          imageSelectedHighlighted,           [CPThemeStateSelected, CPThemeStateHighlighted]],
//     [@"image",          imageHighlighted,                   CPThemeStateHighlighted],
//     [@"image",          imageDisabled,                      CPThemeStateDisabled],
//     [@"image",          imageSelectedDisabled,              [CPThemeStateSelected, CPThemeStateDisabled]],
//     [@"image",          mixedImage,                         CPButtonStateMixed],
//     [@"image",          mixedHighlightedImage,              [CPButtonStateMixed, CPThemeStateHighlighted]],
//     [@"image",          mixedDisabledImage,                 [CPButtonStateMixed, CPThemeStateDisabled]]
//     ];
//
//    [self registerThemeValues:[self defaultThemeOverridesAddedTo:hudSpecific] forView:button inherit:themedCheckBoxValues];
//
//    return button;
//}
//
//+ (CPCheckBox)themedMixedCheckBoxButton
//{
//    var button = [self themedCheckBoxButton];
//
//    [button setAllowsMixedState:YES];
//    [button setState:CPMixedState];
//
//    [self registerThemeValues:[self defaultThemeOverridesAddedTo:nil] forView:button];
//
//    return button;
//}
//
//+ (CPRadioButton)themedRadioButton
//{
//    var button = [CPRadio radioWithTitle:@"Radio button"],
//    regularImageNormal = PatternImage("HUD/radio-image.png", 21.0, 21.0),
//    regularImageSelected = PatternImage("HUD/radio-image-selected.png", 21.0, 21.0),
//    regularImageSelectedHighlighted = PatternImage("HUD/radio-image-selected-highlighted.png", 21.0, 21.0),
//    regularImageSelectedDisabled = PatternImage("HUD/radio-image-selected.png", 21.0, 21.0),
//    regularImageDisabled = PatternImage("HUD/radio-image.png", 21.0, 21.0),
//    regularImageHighlighted = PatternImage("HUD/radio-image-highlighted.png", 21.0, 21.0),
//
//    smallImageNormal = PatternImage("HUD/radio-image.png", 20.0, 20.0),
//    smallImageSelected = PatternImage("HUD/radio-image-selected.png", 20.0, 20.0),
//    smallImageSelectedHighlighted = PatternImage("HUD/radio-image-selected-highlighted.png", 20.0, 20.0),
//    smallImageSelectedDisabled = PatternImage("HUD/radio-image-selected.png", 20.0, 20.0),
//    smallImageDisabled = PatternImage("HUD/radio-image.png", 20.0, 20.0),
//    smallImageHighlighted = PatternImage("HUD/radio-image-highlighted.png", 20.0, 20.0),
//
//    miniImageNormal = PatternImage("HUD/radio-image.png", 16.0, 16.0),
//    miniImageSelected = PatternImage("HUD/radio-image-selected.png", 16.0, 16.0),
//    miniImageSelectedHighlighted = PatternImage("HUD/radio-image-selected-highlighted.png", 16.0, 16.0),
//    miniImageSelectedDisabled = PatternImage("HUD/radio-image-selected.png", 16.0, 16.0),
//    miniImageDisabled = PatternImage("HUD/radio-image.png", 16.0, 16.0),
//    miniImageHighlighted = PatternImage("HUD/radio-image-highlighted.png", 16.0, 16.0);
//
//    hudSpecific =
//    [
//     [@"image",                      regularImageNormal,                 CPThemeStateNormal],
//     [@"image",                      regularImageSelected,               CPThemeStateSelected],
//     [@"image",                      regularImageSelectedHighlighted,    [CPThemeStateSelected, CPThemeStateHighlighted]],
//     [@"image",                      regularImageHighlighted,            CPThemeStateHighlighted],
//     [@"image",                      regularImageDisabled,               CPThemeStateDisabled],
//     [@"image",                      regularImageSelectedDisabled,       [CPThemeStateSelected, CPThemeStateDisabled]],
//
//     [@"min-size",                   CGSizeMake(21.0, 21.0)],
//     [@"max-size",                   CGSizeMake(-1.0, -1.0)],
//     [@"nib2cib-adjustment-frame",   CGRectMake(-5.0, 2.0, 0.0, 0.0)],
//
//     // CPThemeStateControlSizeSmall
//     [@"image",                      smallImageNormal,                   [CPThemeStateControlSizeSmall, CPThemeStateNormal]],
//     [@"image",                      smallImageSelected,                 [CPThemeStateControlSizeSmall, CPThemeStateSelected]],
//     [@"image",                      smallImageSelectedHighlighted,      [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateHighlighted]],
//     [@"image",                      smallImageHighlighted,              [CPThemeStateControlSizeSmall, CPThemeStateHighlighted]],
//     [@"image",                      smallImageDisabled,                 [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
//     [@"image",                      smallImageSelectedDisabled,         [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateDisabled]],
//
//     [@"min-size",                   CGSizeMake(0, 20.0),                CPThemeStateControlSizeSmall],
//     [@"max-size",                   CGSizeMake(-1, 20.0),               CPThemeStateControlSizeSmall],
//     [@"nib2cib-adjustment-frame",   CGRectMake(-2.0, 2.0, 15.0, 0.0),   CPThemeStateControlSizeSmall],
//
//     // CPThemeStateControlSizeMini
//     [@"image",                      miniImageNormal,                    [CPThemeStateControlSizeMini, CPThemeStateNormal]],
//     [@"image",                      miniImageSelected,                  [CPThemeStateControlSizeMini, CPThemeStateSelected]],
//     [@"image",                      miniImageSelectedHighlighted,       [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateHighlighted]],
//     [@"image",                      miniImageHighlighted,               [CPThemeStateControlSizeMini, CPThemeStateHighlighted]],
//     [@"image",                      miniImageDisabled,                  [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
//     [@"image",                      miniImageSelectedDisabled,          [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateDisabled]],
//
//     [@"min-size",                   CGSizeMake(0, 16.0),                CPThemeStateControlSizeMini],
//     [@"max-size",                   CGSizeMake(-1, 16.0),               CPThemeStateControlSizeMini],
//     [@"nib2cib-adjustment-frame",   CGRectMake(0.0, 2.0, 15.0, 0.0),    CPThemeStateControlSizeMini],
//     ];
//
//    [self registerThemeValues:[self defaultThemeOverridesAddedTo:hudSpecific] forView:button inherit:themedRadioButtonValues];
//    return button;
//}
//
//@end
