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

A3CPColorActiveText             = [CPColor colorWithRed:0 green:0 blue:0 alpha:0.85];
A3CPColorInactiveText           = [CPColor colorWithRed:0 green:0 blue:0 alpha:0.25];
A3CPColorDefaultText            = [CPColor colorWithHexString:@"FFFFFF"];

A3CPColorActiveBorder           = [CPColor colorWithRed:0 green:0 blue:0 alpha:0.20]; // was 0.15
A3ColorActiveBorder             = @"rgba(0,0,0,0.20)"; // was 0.15
A3CPColorInactiveBorder         = [CPColor colorWithRed:0 green:0 blue:0 alpha:0.10];
A3ColorInactiveBorder           = @"rgba(0,0,0,0.10)";
A3ColorInactiveDarkBorder       = @"rgba(0,0,0,0.25)";
A3ColorNotKeyDarkBorder         = @"rgba(0,0,0,0.85)";

A3ColorBorderLight              = @"rgb(230,230,230)";
A3ColorBorderMedium             = @"rgb(213,213,213)";
A3ColorBorderDark               = @"rgb(205,205,205)";
A3ColorBorderBlue               = @"rgb(23,128,251)";
A3CPColorBorderBlue             = [CPColor colorWithHexString:@"1780FB"];
A3CPColorBorderBlueInactive     = [CPColor colorWithHexString:@"DCDCDC"];
A3ColorBorderBlueLight          = @"rgb(150,200,250)";
A3ColorBorderBlueHighlighted    = @"rgb(0,103,216)";
A3ColorBackground               = @"rgb(236,236,236)";
A3ColorBackgroundInactive       = @"rgb(240,240,240)";
A3ColorBackgroundHighlighted    = @"rgb(231,231,231)";
A3ColorBackgroundWhite          = @"rgb(255,255,255)";
A3ColorBackgroundDark           = @"rgb(159,159,159)";

A3ColorBorderRed                = @"rgb(192,26,25)";
A3ColorBorderRedLight           = @"rgb(239,102,103)";
A3ColorBorderRedHighlighted     = @"rgb(144,19,19)";

// Windows

A3ColorWindowHeadActive         = @"rgb(216,216,216)";
A3ColorWindowHeadInactive       = @"rgb(246,246,246)";
A3ColorWindowButtonClose        = @"rgb(252,96,92)";
A3ColorWindowButtonCloseDark    = @"rgb(223,72,69)";
A3ColorWindowButtonCloseLight   = @"rgb(254,176,174)";
A3ColorWindowButtonMin          = @"rgb(253,188,64)";
A3ColorWindowButtonMinDark      = @"rgb(222,160,52)";
A3ColorWindowButtonMinLight     = @"rgb(254,222,160)";
A3ColorWindowButtonZoom         = @"rgb(52,200,74)";
A3ColorWindowButtonZoomDark     = @"rgb(40,171,53)";
A3ColorWindowButtonZoomLight    = @"rgb(154,227,164)";
A3ColorWindowButtonUnsaved      = @"rgba(50,50,50,0.65)";
A3ColorWindowButtonUnsavedLight = @"rgb(100,100,100)";
A3ColorWindowBorder             = @"rgb(189,189,189)";

// Menus

A3ColorMenuLightBackground      = @"rgb(246,246,246)";
A3ColorMenuBackground           = @"rgb(206,206,206)";
A3ColorMenuCheckmark            = @"rgba(0,0,0,0.85)";
A3ColorMenuBorder               = @"rgba(0,0,0,0.20)";

// Textfields

A3ColorTextfieldActiveBorder    = @"rgba(0,0,0,0.25)";
A3ColorTextfieldInactiveBorder  = @"rgba(0,0,0,0.20)";

// Tables

A3CPColorTableRow               = [CPColor whiteColor];
A3CPColorTableAlternateRow      = [CPColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
A3CPColorTableDivider           = [CPColor colorWithRed:214.0/255.0 green:214.0/255.0 blue:214.0/255.0 alpha:1.0];
A3ColorTableDivider             = @"rgb(214,214,214)";
A3ColorTableHeaderSeparator     = @"rgb(229,229,229)";
A3CPColorTableHeaderText        = [CPColor colorWithRed:0 green:0 blue:0 alpha:0.40];
A3CPColorSelectedTableHeaderText    = [CPColor colorWithRed:0 green:0 blue:0 alpha:0.70];
A3ColorTableColumnHeaderPressed = @"rgba(0,0,0,0.10)";

// Scrollers

A3ColorScrollerDark             = @"rgba(0,0,0,0.50)";
A3ColorScrollerLight            = @"rgba(255,255,255,0.5)";
A3ColorScrollerLegacy           = @"rgba(0,0,0,0.20)";
A3ColorScrollerBackground       = @"rgb(250,250,250)";
A3ColorScrollerBorder           = @"rgb(232,232,232)";

// Sliders

A3ColorCircularSliderKnob       = @"rgba(0,0,0,0.5)";
A3ColorSliderDisabledKnob       = @"rgb(251,251,251)";
A3ColorSliderDisabledTrack      = @"rgb(140,140,140)";

// Steppers

A3ColorStepperArrow             = @"rgba(0,0,0,0.65)";
A3ColorHighlightedStepperArrow  = @"rgba(255,255,255,1)";
