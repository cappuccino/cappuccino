/*
 * Aristo3Colors.j
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

/*
    Aristo3's theme colours: the colours that have no System name. Each constant is a named
    colour of the theme catalog. It resolves at use to the value that the current theme gives
    for the current appearance, so a CSS dictionary that holds it follows the appearance.

    This file is the table of the values for every appearance (A3ThemeColorValues).
    Aristo3DarkColors.j gives the values for the dark appearance (A3DarkThemeColorValues), and
    the dark values of System colours that Aristo3 uses (A3DarkSystemColorValues).
    +[Aristo3ThemeDescriptor themedColor] registers the tables.

    A constant's colour name is its identifier without A3Color or A3CPColor, with a lower-case
    first letter and Color added: A3ColorBorderBlue is borderBlueColor. The two forms of one
    colour (A3Color... and A3CPColor...) are one name, and both constants hold one object.
*/
A3ThemeColorValues      = @{};
A3DarkThemeColorValues  = @{};
A3DarkSystemColorValues = @{};

/*
    Returns YES when two values of a table give the same colour. A channel above 1, as
    [CPColor colorWithRed:255 green:255 blue:255 alpha:0.35] has, gives the same colour as 1,
    because the browser clamps it.
*/
function A3ThemeColorValuesAreEqual(aColor, anotherColor)
{
    if ([aColor isKindOfClass:_CPDynamicColor] || [anotherColor isKindOfClass:_CPDynamicColor])
        return [aColor isEqual:anotherColor];

    var components = [aColor components],
        otherComponents = [anotherColor components];

    for (var i = 0; i < 3; i++)
        if (ROUND(MIN(MAX(components[i], 0.0), 1.0) * 255.0) !== ROUND(MIN(MAX(otherComponents[i], 0.0), 1.0) * 255.0))
            return NO;

    return components[3] === otherComponents[3];
}

/*
    Puts aValue into aTable under aName. A name defined twice with different values is a defect
    of the table, so the blend build stops.
*/
function A3PutThemeColorValue(aTable, aName, aValue)
{
    var previousValue = [aTable objectForKey:aName];

    if (!previousValue)
        [aTable setObject:aValue forKey:aName];
    else if (!A3ThemeColorValuesAreEqual(previousValue, aValue))
        [CPException raise:CPInvalidArgumentException reason:"Aristo3 defines the theme colour " + aName + " twice with different values"];
}

/*
    Defines the theme colour aName with aValue for every appearance, and returns the named
    colour.
*/
function A3DefineThemeColor(aName, aValue)
{
    A3PutThemeColorValue(A3ThemeColorValues, aName, aValue);

    return [CPColor colorWithCatalogName:@"Theme" colorName:aName];
}

/*
    Defines the value of the theme colour aName in the dark appearance.
*/
function A3DefineDarkThemeColor(aName, aValue)
{
    A3PutThemeColorValue(A3DarkThemeColorValues, aName, aValue);
}

/*
    Defines the value of the System colour aName in the dark appearance.
*/
function A3DefineDarkSystemColor(aName, aValue)
{
    A3PutThemeColorValue(A3DarkSystemColorValues, aName, aValue);
}

A3CPColorActiveText                 = A3DefineThemeColor(@"activeTextColor", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.85]);
A3CPColorActiveTextHighlighted      = A3DefineThemeColor(@"activeTextHighlightedColor", [CPColor colorWithRed:255 green:255 blue:255 alpha:0.90]);
A3CPColorInactiveText               = A3DefineThemeColor(@"inactiveTextColor", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.30]);
A3CPColorInactiveWhiteText          = A3DefineThemeColor(@"inactiveWhiteTextColor", [CPColor colorWithRed: 255 green:255 blue:255 alpha:0.6]);
A3CPColorDefaultText                = A3DefineThemeColor(@"defaultTextColor", [CPColor colorWithHexString:@"FFFFFF"]);
A3CPColorActiveText65               = A3DefineThemeColor(@"activeText65Color", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.65]);

A3CPColorBlack50                    = A3DefineThemeColor(@"black50Color", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.50]);
A3CPColorBlack85                    = A3DefineThemeColor(@"black85Color", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.85]);
A3CPColorBlack25                    = A3DefineThemeColor(@"black25Color", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.25]);

A3CPColorActiveBorder               = A3DefineThemeColor(@"activeBorderColor", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.20]);
A3ColorActiveBorder                 = A3DefineThemeColor(@"activeBorderColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.20)"]);
A3CPColorInactiveBorder             = A3DefineThemeColor(@"inactiveBorderColor", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.10]);
A3ColorInactiveBorder               = A3DefineThemeColor(@"inactiveBorderColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.10)"]);
A3ColorInactiveDarkBorder           = A3DefineThemeColor(@"inactiveDarkBorderColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.25)"]);
A3ColorNotKeyDarkBorder             = A3DefineThemeColor(@"notKeyDarkBorderColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.85)"]);
A3ColorTransparent                  = @"rgba(0,0,0,0)"; // A fully clear colour has no name.
A3ColorLightBackground              = A3DefineThemeColor(@"lightBackgroundColor", [CPColor colorWithCSSString:@"rgba(255,255,255,0.5)"]);

A3ColorBorderLight                  = A3DefineThemeColor(@"borderLightColor", [CPColor colorWithCSSString:@"rgb(230,230,230)"]);
A3ColorBorderMedium                 = A3DefineThemeColor(@"borderMediumColor", [CPColor colorWithCSSString:@"rgb(213,213,213)"]);
A3ColorBorderDark                   = A3DefineThemeColor(@"borderDarkColor", [CPColor colorWithCSSString:@"rgb(205,205,205)"]);
A3ColorBorderBlue                   = A3DefineThemeColor(@"borderBlueColor", [CPColor colorWithCSSString:@"rgb(23,128,251)"]);
A3CPColorBorderBlue                 = A3DefineThemeColor(@"borderBlueColor", [CPColor colorWithHexString:@"1780FB"]);
A3CPColorBorderBlueInactive         = A3DefineThemeColor(@"borderBlueInactiveColor", [CPColor colorWithHexString:@"DCDCDC"]);
A3ColorBorderBlueLight              = A3DefineThemeColor(@"borderBlueLightColor", [CPColor colorWithCSSString:@"rgb(150,200,250)"]);
A3ColorBorderBlueHighlighted        = A3DefineThemeColor(@"borderBlueHighlightedColor", [CPColor colorWithCSSString:@"rgb(0,103,216)"]);
A3ColorBackground                   = A3DefineThemeColor(@"backgroundColor", [CPColor colorWithCSSString:@"rgb(236,236,236)"]);
A3ColorBackgroundInactive           = A3DefineThemeColor(@"backgroundInactiveColor", [CPColor colorWithCSSString:@"rgb(240,240,240)"]);
A3ColorBackgroundHighlighted        = A3DefineThemeColor(@"backgroundHighlightedColor", [CPColor colorWithCSSString:@"rgb(231,231,231)"]);
A3ColorBackgroundWhite              = A3DefineThemeColor(@"backgroundWhiteColor", [CPColor colorWithCSSString:@"rgb(255,255,255)"]);
A3ColorBackgroundDark               = A3DefineThemeColor(@"backgroundDarkColor", [CPColor colorWithCSSString:@"rgb(159,159,159)"]);
A3ColorBackgroundDarkened           = A3DefineThemeColor(@"backgroundDarkenedColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.15)"]);
A3ColorBackgroundLightlyDarkened    = A3DefineThemeColor(@"backgroundLightlyDarkenedColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.05)"]);
A3ColorButtonBackgroundHighlighted  = A3DefineThemeColor(@"buttonBackgroundHighlightedColor", [CPColor colorWithCSSString:@"rgb(191,191,191)"]);
A3ColorBackground90                 = A3DefineThemeColor(@"background90Color", [CPColor colorWithCSSString:@"rgba(236,236,236,0.90)"]);
A3ColorBackground50                 = A3DefineThemeColor(@"background50Color", [CPColor colorWithCSSString:@"rgba(236,236,236,0.50)"]);
A3ColorButtonBackgroundHighlighted80= A3DefineThemeColor(@"buttonBackgroundHighlighted80Color", [CPColor colorWithCSSString:@"rgba(191,191,191,0.80)"]);
A3ColorButtonBackgroundHighlighted50= A3DefineThemeColor(@"buttonBackgroundHighlighted50Color", [CPColor colorWithCSSString:@"rgba(191,191,191,0.50)"]);
A3ColorBackgroundDark35             = A3DefineThemeColor(@"backgroundDark35Color", [CPColor colorWithCSSString:@"rgba(159,159,159,0.35)"]);
A3ColorBackgroundBlack50            = A3DefineThemeColor(@"backgroundBlack50Color", [CPColor colorWithCSSString:@"rgba(0,0,0,0.50)"]);
A3ColorBackgroundBlack35            = A3DefineThemeColor(@"backgroundBlack35Color", [CPColor colorWithCSSString:@"rgba(0,0,0,0.35)"]);
A3ColorBackgroundBlack20            = A3DefineThemeColor(@"backgroundBlack20Color", [CPColor colorWithCSSString:@"rgba(0,0,0,0.20)"]);
A3ColorBackgroundBlack14            = A3DefineThemeColor(@"backgroundBlack14Color", [CPColor colorWithCSSString:@"rgba(0,0,0,0.14)"]);

A3ColorBorderRed                    = A3DefineThemeColor(@"borderRedColor", [CPColor colorWithCSSString:@"rgb(192,26,25)"]);
A3ColorBorderRedLight               = A3DefineThemeColor(@"borderRedLightColor", [CPColor colorWithCSSString:@"rgb(239,102,103)"]);
A3ColorBorderRedHighlighted         = A3DefineThemeColor(@"borderRedHighlightedColor", [CPColor colorWithCSSString:@"rgb(144,19,19)"]);

// Windows

A3ColorWindowHeadActive             = A3DefineThemeColor(@"windowHeadActiveColor", [CPColor colorWithCSSString:@"rgb(216,216,216)"]);
A3ColorWindowHeadInactive           = A3DefineThemeColor(@"windowHeadInactiveColor", [CPColor colorWithCSSString:@"rgb(246,246,246)"]);
A3ColorWindowButtonClose            = A3DefineThemeColor(@"windowButtonCloseColor", [CPColor colorWithCSSString:@"rgb(252,96,92)"]);
A3ColorWindowButtonCloseDark        = A3DefineThemeColor(@"windowButtonCloseDarkColor", [CPColor colorWithCSSString:@"rgb(223,72,69)"]);
A3ColorWindowButtonCloseLight       = A3DefineThemeColor(@"windowButtonCloseLightColor", [CPColor colorWithCSSString:@"rgb(254,176,174)"]);
A3ColorWindowButtonMin              = A3DefineThemeColor(@"windowButtonMinColor", [CPColor colorWithCSSString:@"rgb(253,188,64)"]);
A3ColorWindowButtonMinDark          = A3DefineThemeColor(@"windowButtonMinDarkColor", [CPColor colorWithCSSString:@"rgb(222,160,52)"]);
A3ColorWindowButtonMinLight         = A3DefineThemeColor(@"windowButtonMinLightColor", [CPColor colorWithCSSString:@"rgb(254,222,160)"]);
A3ColorWindowButtonZoom             = A3DefineThemeColor(@"windowButtonZoomColor", [CPColor colorWithCSSString:@"rgb(52,200,74)"]);
A3ColorWindowButtonZoomDark         = A3DefineThemeColor(@"windowButtonZoomDarkColor", [CPColor colorWithCSSString:@"rgb(40,171,53)"]);
A3ColorWindowButtonZoomLight        = A3DefineThemeColor(@"windowButtonZoomLightColor", [CPColor colorWithCSSString:@"rgb(154,227,164)"]);
A3ColorWindowButtonUnsaved          = A3DefineThemeColor(@"windowButtonUnsavedColor", [CPColor colorWithCSSString:@"rgba(50,50,50,0.65)"]);
A3ColorWindowButtonUnsavedLight     = A3DefineThemeColor(@"windowButtonUnsavedLightColor", [CPColor colorWithCSSString:@"rgb(100,100,100)"]);
A3ColorWindowButtonBackground       = A3DefineThemeColor(@"windowButtonBackgroundColor", [CPColor colorWithCSSString:@"rgb(128,128,128)"]);
A3ColorWindowButtonBackgroundLight  = A3DefineThemeColor(@"windowButtonBackgroundLightColor", [CPColor colorWithCSSString:@"rgb(192,192,192)"]);
A3ColorWindowButtonBackgroundDark   = A3DefineThemeColor(@"windowButtonBackgroundDarkColor", [CPColor colorWithCSSString:@"rgb(96,96,96)"]);
A3ColorWindowBorder                 = A3DefineThemeColor(@"windowBorderColor", [CPColor colorWithCSSString:@"rgb(189,189,189)"]);

// Menus

A3ColorMenuLightBackground          = A3DefineThemeColor(@"menuLightBackgroundColor", [CPColor colorWithCSSString:@"rgb(246,246,246)"]);
A3ColorMenuBackground               = A3DefineThemeColor(@"menuBackgroundColor", [CPColor colorWithCSSString:@"rgb(206,206,206)"]);
A3ColorMenuCheckmark                = A3DefineThemeColor(@"menuCheckmarkColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.85)"]);
A3ColorMenuBorder                   = A3DefineThemeColor(@"menuBorderColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.20)"]);

// Textfields

A3ColorTextfieldActiveBorder        = A3DefineThemeColor(@"textfieldActiveBorderColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.25)"]);
A3ColorTextfieldInactiveBorder      = A3DefineThemeColor(@"textfieldInactiveBorderColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.20)"]);

// Tables

/*
    The first of the table's alternating row colours is the background of the table view,
    which has a System name. Aristo3 gives no value for it under Aqua, so it keeps CPColor's
    default, which is white.
*/
A3CPColorTableRow                   = [CPColor controlBackgroundColor];
A3CPColorTableAlternateRow          = A3DefineThemeColor(@"tableAlternateRowColor", [CPColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0]);
A3CPColorTableDivider               = A3DefineThemeColor(@"tableDividerColor", [CPColor colorWithRed:214.0/255.0 green:214.0/255.0 blue:214.0/255.0 alpha:1.0]);
A3ColorTableDivider                 = A3DefineThemeColor(@"tableDividerColor", [CPColor colorWithCSSString:@"rgb(214,214,214)"]);
A3ColorTableHeaderSeparator         = A3DefineThemeColor(@"tableHeaderSeparatorColor", [CPColor colorWithCSSString:@"rgb(229,229,229)"]);
A3CPColorTableHeaderText            = A3DefineThemeColor(@"tableHeaderTextColor", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.40]);
A3CPColorSelectedTableHeaderText    = A3DefineThemeColor(@"selectedTableHeaderTextColor", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.70]);
A3ColorTableColumnHeaderPressed     = A3DefineThemeColor(@"tableColumnHeaderPressedColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.10)"]);

// Scrollers

A3ColorScrollerDark                 = A3DefineThemeColor(@"scrollerDarkColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.50)"]);
A3ColorScrollerLight                = A3DefineThemeColor(@"scrollerLightColor", [CPColor colorWithCSSString:@"rgba(255,255,255,0.5)"]);
A3ColorScrollerLegacy               = A3DefineThemeColor(@"scrollerLegacyColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.20)"]);
A3ColorScrollerBackground           = A3DefineThemeColor(@"scrollerBackgroundColor", [CPColor colorWithCSSString:@"rgb(250,250,250)"]);
A3ColorScrollerBorder               = A3DefineThemeColor(@"scrollerBorderColor", [CPColor colorWithCSSString:@"rgb(232,232,232)"]);

// Sliders

A3ColorCircularSliderKnob           = A3DefineThemeColor(@"circularSliderKnobColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.5)"]);
A3ColorSliderDisabledKnob           = A3DefineThemeColor(@"sliderDisabledKnobColor", [CPColor colorWithCSSString:@"rgb(251,251,251)"]);
A3ColorSliderDisabledTrack          = A3DefineThemeColor(@"sliderDisabledTrackColor", [CPColor colorWithCSSString:@"rgb(140,140,140)"]);

// Steppers

A3ColorStepperArrow                 = A3DefineThemeColor(@"stepperArrowColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.65)"]);
A3ColorHighlightedStepperArrow      = A3DefineThemeColor(@"highlightedStepperArrowColor", [CPColor colorWithCSSString:@"rgba(255,255,255,1)"]);

// Split views

A3ColorSplitPaneDividerBackground   = A3DefineThemeColor(@"splitPaneDividerBackgroundColor", [CPColor colorWithCSSString:@"rgb(253,253,253)"]);
A3ColorSplitPaneDividerBorder       = A3DefineThemeColor(@"splitPaneDividerBorderColor", [CPColor colorWithCSSString:@"rgb(213,213,213)"]);

// Calendar

A3ColorCalendarButtons              = A3DefineThemeColor(@"calendarButtonsColor", [CPColor colorWithCSSString:@"rgb(50,50,50)"]);
A3ColorCalendarHighlightedButtons   = A3DefineThemeColor(@"calendarHighlightedButtonsColor", [CPColor colorWithCSSString:@"rgb(165,165,165)"]);
A3CPColorCalendarDark               = A3DefineThemeColor(@"calendarDarkColor", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.35]);
A3ColorCalendarDark                 = A3DefineThemeColor(@"calendarDarkColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.35)"]);
A3ColorCalendarActive               = A3DefineThemeColor(@"calendarActiveColor", [CPColor colorWithCSSString:@"rgb(23,128,251)"]);
A3ColorCalendarActiveNotKey         = A3DefineThemeColor(@"calendarActiveNotKeyColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.15)"]);
A3CPColorCalendarTitle              = A3DefineThemeColor(@"calendarTitleColor", [CPColor colorWithRed:65/255 green:65/255  blue:65/255  alpha:1]);
A3CPColorCalendarTile               = A3DefineThemeColor(@"calendarTileColor", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.85]); // [CPColor colorWithRed:40/255 green:40/255  blue:40/255  alpha:1];
A3CPColorCalendarCurrentDayTile     = A3DefineThemeColor(@"calendarCurrentDayTileColor", [CPColor colorWithHexString:@"1780FB"]);
A3CPColorCalendarOutOfRangeTile     = A3DefineThemeColor(@"calendarOutOfRangeTileColor", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.30]);
A3CPColorCalendarSelectedTile       = A3DefineThemeColor(@"calendarSelectedTileColor", [CPColor whiteColor]);
A3ColorCalendarBackground           = A3DefineThemeColor(@"calendarBackgroundColor", [CPColor colorWithCSSString:@"rgb(255,255,255)"]);

// Disclosure triangle

A3ColorDisclosure                   = A3DefineThemeColor(@"disclosureColor", [CPColor colorWithCSSString:@"rgb(140,140,140)"]);
A3ColorDisclosureDisabled           = A3DefineThemeColor(@"disclosureDisabledColor", [CPColor colorWithCSSString:@"rgb(191,191,191)"]);
A3ColorDisclosurePushed             = A3DefineThemeColor(@"disclosurePushedColor", [CPColor colorWithCSSString:@"rgb(115,115,115)"]);

// Square buttons

A3ColorSquareButtonBackground       = A3DefineThemeColor(@"squareButtonBackgroundColor", [CPColor colorWithCSSString:@"rgb(248,248,248)"]);

// Window shadow

A3ColorWindowViewWindowShadow       = A3DefineThemeColor(@"windowViewWindowShadowColor", [CPColor colorWithCSSString:@"rgba(0, 0, 0, 0.25)"]);

// Rule editor

/*
    The rows alternate between the table view background, which has a System name, and a pale
    blue. The slice borders separate the rows.
*/
A3CPColorRuleEditorAlternateRow             = A3DefineThemeColor(@"ruleEditorAlternateRowColor", [CPColor colorWithRed:235.0/255.0 green:239.0/255.0 blue:252.0/255.0 alpha:1.0]);
A3CPColorRuleEditorSliceTopBorder           = A3DefineThemeColor(@"ruleEditorSliceTopBorderColor", [CPColor colorWithWhite:0.9 alpha:1.0]);
A3CPColorRuleEditorSliceBottomBorder        = A3DefineThemeColor(@"ruleEditorSliceBottomBorderColor", [CPColor colorWithWhite:0.729412 alpha:1.0]);
A3CPColorRuleEditorSliceLastBottomBorder    = A3DefineThemeColor(@"ruleEditorSliceLastBottomBorderColor", [CPColor colorWithWhite:0.6 alpha:1.0]);

// Boxes

A3ColorBoxFill                              = A3DefineThemeColor(@"boxFillColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.08)"]);
A3ColorBoxBorder                            = A3DefineThemeColor(@"boxBorderColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.1)"]);
