/*
 * Aristo3DarkColors.j
 * AppKit
 *
 * Modified for Dark Grey Structural Theme
 */

/*
    The values of Aristo3's theme colours in the dark appearance: for each colour of
    Aristo3Colors.j, its value under DarkAqua. +[Aristo3ThemeDescriptor themedColor] registers
    the table keyed by CPThemeStateAppearanceDarkAqua; the vibrant and high-contrast dark
    appearances find it through -bestMatchFromAppearancesWithNames:. A colour that is not in
    this table keeps its value for every appearance.

    The set is a first, rudimentary one, so that dark mode shows which parts follow the
    appearance. Descriptor refinement comes after theme packaging.
*/

A3DefineDarkThemeColor(@"activeTextColor", [CPColor colorWithRed:255 green:255 blue:255 alpha:0.85]);
A3DefineDarkThemeColor(@"activeTextHighlightedColor", [CPColor colorWithRed:255 green:255 blue:255 alpha:1.00]);
A3DefineDarkThemeColor(@"inactiveTextColor", [CPColor colorWithRed:255 green:255 blue:255 alpha:0.40]);
A3DefineDarkThemeColor(@"inactiveWhiteTextColor", [CPColor colorWithRed:255 green:255 blue:255 alpha:0.25]);
A3DefineDarkThemeColor(@"defaultTextColor", [CPColor colorWithHexString:@"DEDEDE"]);
A3DefineDarkThemeColor(@"activeText65Color", [CPColor colorWithRed:255 green:255 blue:255 alpha:0.65]);

A3DefineDarkThemeColor(@"black50Color", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.50]);
A3DefineDarkThemeColor(@"black85Color", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.85]);
A3DefineDarkThemeColor(@"black25Color", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.25]);

A3DefineDarkThemeColor(@"activeBorderColor", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.60]);
A3DefineDarkThemeColor(@"activeBorderColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.60)"]);
A3DefineDarkThemeColor(@"inactiveBorderColor", [CPColor colorWithRed:0 green:0 blue:0 alpha:0.30]);
A3DefineDarkThemeColor(@"inactiveBorderColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.30)"]);
A3DefineDarkThemeColor(@"inactiveDarkBorderColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.50)"]);
A3DefineDarkThemeColor(@"notKeyDarkBorderColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.40)"]);
A3DefineDarkThemeColor(@"lightBackgroundColor", [CPColor colorWithCSSString:@"rgba(255,255,255,0.10)"]);

A3DefineDarkThemeColor(@"borderLightColor", [CPColor colorWithCSSString:@"rgb(85,85,85)"]);
A3DefineDarkThemeColor(@"borderMediumColor", [CPColor colorWithCSSString:@"rgb(45,45,45)"]);
A3DefineDarkThemeColor(@"borderDarkColor", [CPColor colorWithCSSString:@"rgb(25,25,25)"]);
A3DefineDarkThemeColor(@"borderBlueColor", [CPColor colorWithCSSString:@"rgb(10,100,210)"]);
A3DefineDarkThemeColor(@"borderBlueColor", [CPColor colorWithHexString:@"0A64D2"]);
A3DefineDarkThemeColor(@"borderBlueInactiveColor", [CPColor colorWithHexString:@"444444"]);
A3DefineDarkThemeColor(@"borderBlueLightColor", [CPColor colorWithCSSString:@"rgb(60,130,220)"]);
A3DefineDarkThemeColor(@"borderBlueHighlightedColor", [CPColor colorWithCSSString:@"rgb(40,150,255)"]);
A3DefineDarkThemeColor(@"backgroundColor", [CPColor colorWithCSSString:@"rgb(45,45,45)"]);
A3DefineDarkThemeColor(@"backgroundInactiveColor", [CPColor colorWithCSSString:@"rgb(38,38,38)"]);
A3DefineDarkThemeColor(@"backgroundHighlightedColor", [CPColor colorWithCSSString:@"rgb(65,65,65)"]);
A3DefineDarkThemeColor(@"backgroundWhiteColor", [CPColor colorWithCSSString:@"rgb(30,30,30)"]); // Inset base
A3DefineDarkThemeColor(@"backgroundDarkColor", [CPColor colorWithCSSString:@"rgb(25,25,25)"]);
A3DefineDarkThemeColor(@"backgroundDarkenedColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.35)"]);
A3DefineDarkThemeColor(@"backgroundLightlyDarkenedColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.15)"]);
A3DefineDarkThemeColor(@"buttonBackgroundHighlightedColor", [CPColor colorWithCSSString:@"rgb(75,75,75)"]);
A3DefineDarkThemeColor(@"background90Color", [CPColor colorWithCSSString:@"rgba(45,45,45,0.90)"]);
A3DefineDarkThemeColor(@"background50Color", [CPColor colorWithCSSString:@"rgba(45,45,45,0.50)"]);
A3DefineDarkThemeColor(@"buttonBackgroundHighlighted80Color", [CPColor colorWithCSSString:@"rgba(75,75,75,0.80)"]);
A3DefineDarkThemeColor(@"buttonBackgroundHighlighted50Color", [CPColor colorWithCSSString:@"rgba(75,75,75,0.50)"]);
A3DefineDarkThemeColor(@"backgroundDark35Color", [CPColor colorWithCSSString:@"rgba(25,25,25,0.35)"]);
A3DefineDarkThemeColor(@"backgroundBlack50Color", [CPColor colorWithCSSString:@"rgba(0,0,0,0.50)"]);
A3DefineDarkThemeColor(@"backgroundBlack35Color", [CPColor colorWithCSSString:@"rgba(0,0,0,0.35)"]);
A3DefineDarkThemeColor(@"backgroundBlack20Color", [CPColor colorWithCSSString:@"rgba(0,0,0,0.20)"]);
A3DefineDarkThemeColor(@"backgroundBlack14Color", [CPColor colorWithCSSString:@"rgba(0,0,0,0.14)"]);

A3DefineDarkThemeColor(@"borderRedColor", [CPColor colorWithCSSString:@"rgb(205,50,50)"]);
A3DefineDarkThemeColor(@"borderRedLightColor", [CPColor colorWithCSSString:@"rgb(235,90,90)"]);
A3DefineDarkThemeColor(@"borderRedHighlightedColor", [CPColor colorWithCSSString:@"rgb(255,80,80)"]);

// Windows

A3DefineDarkThemeColor(@"windowHeadActiveColor", [CPColor colorWithCSSString:@"rgb(54,54,54)"]);
A3DefineDarkThemeColor(@"windowHeadInactiveColor", [CPColor colorWithCSSString:@"rgb(38,38,38)"]);
A3DefineDarkThemeColor(@"windowButtonCloseColor", [CPColor colorWithCSSString:@"rgb(252,96,92)"]);
A3DefineDarkThemeColor(@"windowButtonCloseDarkColor", [CPColor colorWithCSSString:@"rgb(223,72,69)"]);
A3DefineDarkThemeColor(@"windowButtonCloseLightColor", [CPColor colorWithCSSString:@"rgb(254,176,174)"]);
A3DefineDarkThemeColor(@"windowButtonMinColor", [CPColor colorWithCSSString:@"rgb(253,188,64)"]);
A3DefineDarkThemeColor(@"windowButtonMinDarkColor", [CPColor colorWithCSSString:@"rgb(222,160,52)"]);
A3DefineDarkThemeColor(@"windowButtonMinLightColor", [CPColor colorWithCSSString:@"rgb(254,222,160)"]);
A3DefineDarkThemeColor(@"windowButtonZoomColor", [CPColor colorWithCSSString:@"rgb(52,200,74)"]);
A3DefineDarkThemeColor(@"windowButtonZoomDarkColor", [CPColor colorWithCSSString:@"rgb(40,171,53)"]);
A3DefineDarkThemeColor(@"windowButtonZoomLightColor", [CPColor colorWithCSSString:@"rgb(154,227,164)"]);
A3DefineDarkThemeColor(@"windowButtonUnsavedColor", [CPColor colorWithCSSString:@"rgba(200,200,200,0.65)"]);
A3DefineDarkThemeColor(@"windowButtonUnsavedLightColor", [CPColor colorWithCSSString:@"rgb(150,150,150)"]);
A3DefineDarkThemeColor(@"windowButtonBackgroundColor", [CPColor colorWithCSSString:@"rgb(75,75,75)"]);
A3DefineDarkThemeColor(@"windowButtonBackgroundLightColor", [CPColor colorWithCSSString:@"rgb(90,90,90)"]);
A3DefineDarkThemeColor(@"windowButtonBackgroundDarkColor", [CPColor colorWithCSSString:@"rgb(40,40,40)"]);
A3DefineDarkThemeColor(@"windowBorderColor", [CPColor colorWithCSSString:@"rgb(20,20,20)"]);

// Menus

A3DefineDarkThemeColor(@"menuLightBackgroundColor", [CPColor colorWithCSSString:@"rgb(55,55,55)"]);
A3DefineDarkThemeColor(@"menuBackgroundColor", [CPColor colorWithCSSString:@"rgb(45,45,45)"]);
A3DefineDarkThemeColor(@"menuCheckmarkColor", [CPColor colorWithCSSString:@"rgba(255,255,255,0.85)"]);
A3DefineDarkThemeColor(@"menuBorderColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.60)"]);

// Textfields

A3DefineDarkThemeColor(@"textfieldActiveBorderColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.70)"]);
A3DefineDarkThemeColor(@"textfieldInactiveBorderColor", [CPColor colorWithCSSString:@"rgba(0,0,0,0.40)"]);

// Tables

/*
    The background of the table view, the first of its alternating row colours, has the
    System name controlBackgroundColor (see A3CPColorTableRow in Aristo3Colors.j).
*/
A3DefineDarkSystemColor(@"controlBackgroundColor", [CPColor colorWithRed:45.0/255.0 green:45.0/255.0 blue:45.0/255.0 alpha:1.0]);
A3DefineDarkThemeColor(@"tableAlternateRowColor", [CPColor colorWithRed:38.0/255.0 green:38.0/255.0 blue:38.0/255.0 alpha:1.0]);
A3DefineDarkThemeColor(@"tableDividerColor", [CPColor colorWithRed:25.0/255.0 green:25.0/255.0 blue:25.0/255.0 alpha:1.0]);
A3DefineDarkThemeColor(@"tableDividerColor", [CPColor colorWithCSSString:@"rgb(25,25,25)"]);
A3DefineDarkThemeColor(@"tableHeaderSeparatorColor", [CPColor colorWithCSSString:@"rgb(20,20,20)"]);
A3DefineDarkThemeColor(@"tableHeaderTextColor", [CPColor colorWithRed:255 green:255 blue:255 alpha:0.60]);
A3DefineDarkThemeColor(@"selectedTableHeaderTextColor", [CPColor colorWithRed:255 green:255 blue:255 alpha:0.85]);
A3DefineDarkThemeColor(@"tableColumnHeaderPressedColor", [CPColor colorWithCSSString:@"rgba(255,255,255,0.10)"]);

// Scrollers

A3DefineDarkThemeColor(@"scrollerDarkColor", [CPColor colorWithCSSString:@"rgba(255,255,255,0.50)"]);
A3DefineDarkThemeColor(@"scrollerLightColor", [CPColor colorWithCSSString:@"rgba(255,255,255,0.25)"]);
A3DefineDarkThemeColor(@"scrollerLegacyColor", [CPColor colorWithCSSString:@"rgba(255,255,255,0.30)"]);
A3DefineDarkThemeColor(@"scrollerBackgroundColor", [CPColor colorWithCSSString:@"rgb(35,35,35)"]);
A3DefineDarkThemeColor(@"scrollerBorderColor", [CPColor colorWithCSSString:@"rgb(20,20,20)"]);

// Sliders

A3DefineDarkThemeColor(@"circularSliderKnobColor", [CPColor colorWithCSSString:@"rgba(255,255,255,0.80)"]);
A3DefineDarkThemeColor(@"sliderDisabledKnobColor", [CPColor colorWithCSSString:@"rgb(60,60,60)"]);
A3DefineDarkThemeColor(@"sliderDisabledTrackColor", [CPColor colorWithCSSString:@"rgb(40,40,40)"]);

// Steppers

A3DefineDarkThemeColor(@"stepperArrowColor", [CPColor colorWithCSSString:@"rgba(255,255,255,0.65)"]);
A3DefineDarkThemeColor(@"highlightedStepperArrowColor", [CPColor colorWithCSSString:@"rgba(255,255,255,1)"]);

// Split views

A3DefineDarkThemeColor(@"splitPaneDividerBackgroundColor", [CPColor colorWithCSSString:@"rgb(30,30,30)"]);
A3DefineDarkThemeColor(@"splitPaneDividerBorderColor", [CPColor colorWithCSSString:@"rgb(20,20,20)"]);

// Calendar

A3DefineDarkThemeColor(@"calendarButtonsColor", [CPColor colorWithCSSString:@"rgb(150,150,150)"]);
A3DefineDarkThemeColor(@"calendarHighlightedButtonsColor", [CPColor colorWithCSSString:@"rgb(200,200,200)"]);
A3DefineDarkThemeColor(@"calendarDarkColor", [CPColor colorWithRed:255 green:255 blue:255 alpha:0.35]);
A3DefineDarkThemeColor(@"calendarDarkColor", [CPColor colorWithCSSString:@"rgba(255,255,255,0.35)"]);
A3DefineDarkThemeColor(@"calendarActiveColor", [CPColor colorWithCSSString:@"rgb(10,100,210)"]);
A3DefineDarkThemeColor(@"calendarActiveNotKeyColor", [CPColor colorWithCSSString:@"rgba(255,255,255,0.15)"]);
A3DefineDarkThemeColor(@"calendarTitleColor", [CPColor colorWithRed:200/255 green:200/255 blue:200/255 alpha:1]);
A3DefineDarkThemeColor(@"calendarTileColor", [CPColor colorWithRed:255 green:255 blue:255 alpha:0.85]);
A3DefineDarkThemeColor(@"calendarCurrentDayTileColor", [CPColor colorWithHexString:@"0A64D2"]);
A3DefineDarkThemeColor(@"calendarOutOfRangeTileColor", [CPColor colorWithRed:255 green:255 blue:255 alpha:0.40]);
A3DefineDarkThemeColor(@"calendarSelectedTileColor", [CPColor colorWithRed:60/255 green:60/255 blue:60/255 alpha:1]);
A3DefineDarkThemeColor(@"calendarBackgroundColor", [CPColor colorWithCSSString:@"rgb(45,45,45)"]);

// Disclosure triangle

A3DefineDarkThemeColor(@"disclosureColor", [CPColor colorWithCSSString:@"rgb(160,160,160)"]);
A3DefineDarkThemeColor(@"disclosureDisabledColor", [CPColor colorWithCSSString:@"rgb(80,80,80)"]);
A3DefineDarkThemeColor(@"disclosurePushedColor", [CPColor colorWithCSSString:@"rgb(220,220,220)"]);

// Square buttons

A3DefineDarkThemeColor(@"squareButtonBackgroundColor", [CPColor colorWithCSSString:@"rgb(55,55,55)"]);

// Window shadow: the light value, until descriptor refinement.

A3DefineDarkThemeColor(@"windowViewWindowShadowColor", [CPColor colorWithCSSString:@"rgba(0, 0, 0, 0.25)"]);

// System colours

/*
    System colours with AppKit's DarkAqua value on macOS 27, in sRGB, as CPColor holds
    AppKit's Aqua values: the window background, the source-list background, secondary text,
    and the gray and purple tints. A System colour without a value here keeps its Aqua value
    in the dark appearance, so a window background stayed white, the source list stayed light
    and secondary text stayed black.
*/
A3DefineDarkSystemColor(@"windowBackgroundColor", [CPColor colorWithRed:0.1176 green:0.1176 blue:0.1176 alpha:1.0]);
A3DefineDarkSystemColor(@"_sourceListBackgroundColor", [CPColor colorWithRed:0.1765 green:0.1765 blue:0.1765 alpha:0.9]);
A3DefineDarkSystemColor(@"secondaryLabelColor", [CPColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.549]);
A3DefineDarkSystemColor(@"systemGrayColor", [CPColor colorWithRed:0.5961 green:0.5961 blue:0.6157 alpha:1.0]);
A3DefineDarkSystemColor(@"systemPurpleColor", [CPColor colorWithRed:0.8588 green:0.2039 blue:0.949 alpha:1.0]);
