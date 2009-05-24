/*
 * AppController.j
 * Aristo
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc. All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/AppKit.j>


@implementation AristoThemeDescriptor : BKThemeDescriptor
{
}

+ (CPString)themeName
{
    return @"Aristo";
}

+ (CPButton)button
{
    var button = [[CPButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 24.0)],

        bezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"button-bezel-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"button-bezel-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"button-bezel-right.png" size:CGSizeMake(4.0, 24.0)]
            ]
        isVertical:NO]],

        highlightedBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"button-bezel-highlighted-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"button-bezel-highlighted-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"button-bezel-highlighted-right.png" size:CGSizeMake(4.0, 24.0)]
            ]
        isVertical:NO]],

        defaultBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"default-button-bezel-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"default-button-bezel-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"default-button-bezel-right.png" size:CGSizeMake(4.0, 24.0)]
            ]
        isVertical:NO]],

        defaultHighlightedBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"default-button-bezel-highlighted-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"default-button-bezel-highlighted-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"default-button-bezel-highlighted-right.png" size:CGSizeMake(4.0, 24.0)]
            ]
        isVertical:NO]];

    [button setValue:[CPFont boldSystemFontOfSize:12.0] forThemeAttribute:@"font" inState:CPThemeStateBordered];
    [button setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color"];
    [button setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateBordered];
    [button setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateBordered];
    [button setValue:CPLineBreakByTruncatingTail forThemeAttribute:@"line-break-mode"];
    
    [button setValue:bezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
    [button setValue:highlightedBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateHighlighted];
    [button setValue:CGInsetMake(0.0, 5.0, 0.0, 5.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBordered];

    [button setValue:defaultBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateDefault];
    [button setValue:defaultHighlightedBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateHighlighted|CPThemeStateDefault];
    [button setValue:[CPColor colorWithCalibratedRed:13.0/255.0 green:51.0/255.0 blue:70.0/255.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateDefault];

    [button setValue:CGSizeMake(0.0, 24.0) forThemeAttribute:@"min-size"];
    [button setValue:CGSizeMake(-1.0, 24.0) forThemeAttribute:@"max-size"];

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
    [button setDefaultButton:YES];

    return button;
}

+ (CPPopUpButton)themedPopUpButton
{
    var button = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 24.0) pullsDown:NO],
        color = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"button-bezel-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"button-bezel-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"popup-bezel-right.png" size:CGSizeMake(27.0, 24.0)]
            ]
        isVertical:NO]];
    
    [button setTitle:@"Pop Up"];
    
    [button setValue:color forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
    [button setValue:CGInsetMake(0, 27.0 + 5.0, 0, 5.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBordered];
    [button setValue:[CPFont boldSystemFontOfSize:12.0] forThemeAttribute:@"font"];
    [button setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color"];
    [button setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color"];
    [button setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset"];

    [button setValue:CGSizeMake(32.0, 24.0) forThemeAttribute:@"min-size"];
    [button setValue:CGSizeMake(-1.0, 24.0) forThemeAttribute:@"max-size"];    

    [button addItemWithTitle:@"item"];
    
    return button;
}

+ (CPPopUpButton)themedPullDownMenu
{
    var button = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 24.0) pullsDown:YES],
        color = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"button-bezel-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"button-bezel-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"popup-bezel-right-pullsdown.png" size:CGSizeMake(27.0, 24.0)]
            ]
        isVertical:NO]];

    [button setTitle:@"Pull Down"];

    [button setValue:color forThemeAttribute:@"bezel-color" inState:CPPopUpButtonStatePullsDown|CPThemeStateBordered];
    [button setValue:CGInsetMake(0, 27.0 + 5.0, 0, 5.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBordered];
    [button setValue:[CPFont boldSystemFontOfSize:12.0] forThemeAttribute:@"font"];
    [button setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color"];
    [button setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color"];
    [button setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset"];

    [button setValue:CGSizeMake(32.0, 24.0) forThemeAttribute:@"min-size"];
    [button setValue:CGSizeMake(-1.0, 24.0) forThemeAttribute:@"max-size"];

    [button addItemWithTitle:@"item"];

    return button;
}

+ (CPScroller)themedVerticalScroller
{
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 17.0, 170.0)],
        trackColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-vertical-track.png" size:CGSizeMake(17.0, 1.0)]),
        disabledTrackColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-vertical-track-disabled.png" size:CGSizeMake(17.0, 1.0)]);
        
    [scroller setValue:19.0 forThemeAttribute:@"minimum-knob-length" inState:CPThemeStateVertical];
    [scroller setValue:CGInsetMake(0.0, 1.0, 0.0, 1.0) forThemeAttribute:@"knob-inset" inState:CPThemeStateVertical];
    [scroller setValue:CGInsetMake(-9.0, 0.0, -9.0, 0.0) forThemeAttribute:@"track-inset" inState:CPThemeStateVertical];

    [scroller setValue:trackColor forThemeAttribute:@"knob-slot-color" inState:CPThemeStateVertical];
    [scroller setValue:disabledTrackColor forThemeAttribute:@"knob-slot-color" inState:CPThemeStateVertical | CPThemeStateDisabled];

    var arrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-up-arrow.png" size:CGSizeMake(17.0, 30.0)]),
        highlightedArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-up-arrow-highlighted.png" size:CGSizeMake(17.0, 30.0)]),
        disabledArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-up-arrow-disabled.png" size:CGSizeMake(17.0, 30.0)]);

    [scroller setValue:CGSizeMake(17.0, 30.0) forThemeAttribute:@"decrement-line-size" inState:CPThemeStateVertical];
    [scroller setValue:arrowColor forThemeAttribute:@"decrement-line-color" inState:CPThemeStateVertical];
    [scroller setValue:highlightedArrowColor forThemeAttribute:@"decrement-line-color" inState:CPThemeStateVertical | CPThemeStateHighlighted],
    [scroller setValue:disabledArrowColor forThemeAttribute:@"decrement-line-color" inState:CPThemeStateVertical | CPThemeStateDisabled];

    var arrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-down-arrow.png" size:CGSizeMake(17.0, 30.0)]),
        highlightedArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-down-arrow-highlighted.png" size:CGSizeMake(17.0, 30.0)]),
        disabledArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-down-arrow-disabled.png" size:CGSizeMake(17.0, 30.0)]);

    [scroller setValue:CGSizeMake(17.0, 30.0) forThemeAttribute:@"increment-line-size" inState:CPThemeStateVertical];
    [scroller setValue:arrowColor forThemeAttribute:@"increment-line-color" inState:CPThemeStateVertical];
    [scroller setValue:highlightedArrowColor forThemeAttribute:@"increment-line-color" inState:CPThemeStateVertical | CPThemeStateHighlighted];
    [scroller setValue:disabledArrowColor forThemeAttribute:@"increment-line-color" inState:CPThemeStateVertical | CPThemeStateDisabled];
    
    var knobColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"scroller-vertical-knob-top.png" size:CGSizeMake(15.0, 8.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-vertical-knob-center.png" size:CGSizeMake(15.0, 1.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-vertical-knob-bottom.png" size:CGSizeMake(15.0, 10.0)]
            ]
        isVertical:YES]);
    
    [scroller setValue:knobColor forThemeAttribute:@"knob-color" inState:CPThemeStateVertical];
    
    [scroller setFloatValue:0.1 knobProportion:0.5];

    return scroller;
}

+ (CPScroller)themedHorizontalScroller
{
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 170.0, 17.0)],
        trackColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-horizontal-track.png" size:CGSizeMake(1.0, 17.0)]),
        disabledTrackColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-horizontal-track-disabled.png" size:CGSizeMake(17.0, 1.0)]);

    [scroller setValue:19.0 forThemeAttribute:@"minimum-knob-length"];
    [scroller setValue:CGInsetMake(2.0, 0.0, 0.0, 0.0) forThemeAttribute:@"knob-inset"];
    [scroller setValue:CGInsetMake(0.0, -10.0, 0.0, -11.0) forThemeAttribute:@"track-inset"];

    [scroller setValue:trackColor forThemeAttribute:@"knob-slot-color"];
    [scroller setValue:disabledTrackColor forThemeAttribute:@"knob-slot-color" inState:CPThemeStateDisabled];

    var arrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-left-arrow.png" size:CGSizeMake(32.0, 17.0)]),
        highlightedArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-left-arrow-highlighted.png" size:CGSizeMake(32.0, 17.0)]),
        disabledArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-left-arrow-disabled.png" size:CGSizeMake(32.0, 17.0)]);

    [scroller setValue:CGSizeMake(32.0, 17.0) forThemeAttribute:@"decrement-line-size"];
    [scroller setValue:arrowColor forThemeAttribute:@"decrement-line-color"];
    [scroller setValue:highlightedArrowColor forThemeAttribute:@"decrement-line-color" inState:CPThemeStateHighlighted],
    [scroller setValue:disabledArrowColor forThemeAttribute:@"decrement-line-color" inState:CPThemeStateDisabled];

    var arrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-right-arrow.png" size:CGSizeMake(31.0, 17.0)]),
        highlightedArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-right-arrow-highlighted.png" size:CGSizeMake(31.0, 17.0)]),
        disabledArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-right-arrow-disabled.png" size:CGSizeMake(31.0, 17.0)]);

    [scroller setValue:CGSizeMake(31.0, 17.0) forThemeAttribute:@"increment-line-size"];
    [scroller setValue:arrowColor forThemeAttribute:@"increment-line-color"];
    [scroller setValue:highlightedArrowColor forThemeAttribute:@"increment-line-color" inState:CPThemeStateHighlighted];
    [scroller setValue:disabledArrowColor forThemeAttribute:@"increment-line-color" inState:CPThemeStateDisabled];
    
    var knobColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"scroller-horizontal-knob-left.png" size:CGSizeMake(11.0, 15.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-horizontal-knob-center.png" size:CGSizeMake(1.0, 15.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-horizontal-knob-right.png" size:CGSizeMake(9.0, 15.0)]
            ]
        isVertical:NO]);
    
    [scroller setValue:knobColor forThemeAttribute:@"knob-color"];
    
    [scroller setFloatValue:0.1 knobProportion:0.5];

    return scroller;
}

+ (CPTextField)themedStandardTextField
{
    var textfield = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 29.0)],
        bezelColor = [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-0.png" size:CGSizeMake(2.0, 3.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-1.png" size:CGSizeMake(1.0, 3.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-2.png" size:CGSizeMake(2.0, 3.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-3.png" size:CGSizeMake(2.0, 1.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-4.png" size:CGSizeMake(1.0, 1.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-5.png" size:CGSizeMake(2.0, 1.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-6.png" size:CGSizeMake(2.0, 2.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-7.png" size:CGSizeMake(1.0, 2.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-8.png" size:CGSizeMake(2.0, 2.0)]
            ]]],

        bezelFocusedColor = [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-focused-0.png" size:CGSizeMake(6.0, 7.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-focused-1.png" size:CGSizeMake(1.0, 7.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-focused-2.png" size:CGSizeMake(6.0, 7.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-focused-3.png" size:CGSizeMake(6.0, 1.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-focused-4.png" size:CGSizeMake(1.0, 1.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-focused-5.png" size:CGSizeMake(6.0, 1.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-focused-6.png" size:CGSizeMake(6.0, 5.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-focused-7.png" size:CGSizeMake(1.0, 5.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-square-focused-8.png" size:CGSizeMake(6.0, 5.0)]
            ]]];

    [textfield setBezeled:YES];

    [textfield setValue:bezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBezeled];
    [textfield setValue:bezelFocusedColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBezeled|CPThemeStateEditing];
    [textfield setValue:[CPFont systemFontOfSize:12.0] forThemeAttribute:@"font" inState:CPThemeStateBezeled];
    [textfield setValue:CGInsetMake(9.0, 7.0, 5.0, 8.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBezeled];

    [textfield setValue:CGInsetMake(4.0, 4.0, 3.0, 4.0) forThemeAttribute:@"bezel-inset" inState:CPThemeStateBezeled];
    [textfield setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"bezel-inset" inState:CPThemeStateBezeled|CPThemeStateEditing];

    [textfield setValue:[CPColor colorWithCalibratedRed:189.0 / 255.0 green:199.0 / 255.0 blue:211.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPTextFieldStatePlaceholder];

    [textfield setPlaceholderString:"placeholder"];
    [textfield setStringValue:""];
    [textfield setEditable:YES];

    return textfield;
}

+ (CPTextField)themedRoundedTextField
{   
    var textfield = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 30.0)],
        bezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-rounded-left.png" size:CGSizeMake(13.0, 22.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-rounded-center.png" size:CGSizeMake(1.0, 22.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-rounded-right.png" size:CGSizeMake(13.0, 22.0)]
            ] isVertical:NO]],

        bezelFocusedColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-rounded-focused-left.png" size:CGSizeMake(17.0, 30.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-rounded-focused-center.png" size:CGSizeMake(1.0, 30.0)],
                [_CPCibCustomResource imageResourceWithName:"textfield-bezel-rounded-focused-right.png" size:CGSizeMake(17.0, 30.0)]
            ] isVertical:NO]];

    [textfield setBezeled:YES];
    [textfield setBezelStyle:CPTextFieldRoundedBezel];

    [textfield setValue:bezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBezeled | CPTextFieldStateRounded];
    [textfield setValue:bezelFocusedColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBezeled | CPTextFieldStateRounded | CPThemeStateEditing];

    [textfield setValue:[CPFont systemFontOfSize:12.0] forThemeAttribute:@"font"];
    [textfield setValue:CGInsetMake(9.0, 14.0, 6.0, 14.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBezeled | CPTextFieldStateRounded];

    [textfield setValue:CGInsetMake(4.0, 4.0, 4.0, 4.0) forThemeAttribute:@"bezel-inset" inState:CPThemeStateBezeled|CPTextFieldStateRounded];
    [textfield setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"bezel-inset" inState:CPThemeStateBezeled|CPTextFieldStateRounded|CPThemeStateEditing];

    [textfield setValue:[CPColor colorWithCalibratedRed:189.0 / 255.0 green:199.0 / 255.0 blue:211.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPTextFieldStatePlaceholder];

    [textfield setPlaceholderString:"placeholder"];
    [textfield setStringValue:""];
    [textfield setEditable:YES];

    [textfield setValue:CGSizeMake(0.0, 30.0) forThemeAttribute:@"min-size" inState:CPThemeStateBezeled|CPTextFieldStateRounded];
    [textfield setValue:CGSizeMake(-1.0, 30.0) forThemeAttribute:@"max-size" inState:CPThemeStateBezeled|CPTextFieldStateRounded];

    return textfield;
}

+ (CPRadioButton)themedRadioButton
{
    var button = [[CPRadio alloc] initWithFrame:CGRectMake(0.0, 0.0, 120.0, 17.0)];

    [button setTitle:@"Hello Friend!"];

    var bezelColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"radio-bezel.png" size:CGSizeMake(17.0, 17.0)], nil, nil
            ]
        isVertical:NO]),
        bezelColorSelected = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"radio-bezel-selected.png" size:CGSizeMake(17.0, 17.0)], nil, nil
            ]
        isVertical:NO]);

    [button setValue:CPLeftTextAlignment forThemeAttribute:@"alignment" inState:CPThemeStateBordered];
    [button setValue:[CPFont boldSystemFontOfSize:12.0] forThemeAttribute:@"font" inState:CPThemeStateBordered];
    [button setValue:CGInsetMake(0.0, 0.0, 0.0, 20.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBordered];
    [button setValue:bezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];    
    [button setValue:bezelColorSelected forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateSelected];

    [button setValue:CGSizeMake(0.0, 17.0) forThemeAttribute:@"min-size"];

    return button;
}

+ (CPRadioButton)themedCheckBoxButton
{
    var button = [[CPCheckBox alloc] initWithFrame:CGRectMake(0.0, 0.0, 120.0, 17.0)];
    
    [button setTitle:@"Another option"];

    var bezelColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"check-box-bezel.png" size:CGSizeMake(15.0, 16.0)], nil, nil
            ]
        isVertical:NO]),
        bezelColorSelected = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"check-box-bezel-selected.png" size:CGSizeMake(15.0, 16.0)], nil, nil
            ]
        isVertical:NO]);
    
    [button setValue:CPLeftTextAlignment forThemeAttribute:@"alignment" inState:CPThemeStateBordered];
    [button setValue:[CPFont boldSystemFontOfSize:12.0] forThemeAttribute:@"font" inState:CPThemeStateBordered];
    [button setValue:CGInsetMake(0.0, 0.0, 0.0, 20.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBordered];
    [button setValue:bezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];    
    [button setValue:bezelColorSelected forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateSelected];

    [button setValue:CGSizeMake(0.0, 17.0) forThemeAttribute:@"min-size"];

    return button;
}

+ (CPPopUpButton)themedSegmentedControl
{
    var segmentedControl = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 24.0)];
    
    [segmentedControl setTrackingMode:CPSegmentSwitchTrackingSelectAny];
    [segmentedControl setSegmentCount:3];
    
    [segmentedControl setWidth:40.0 forSegment:0];
    [segmentedControl setLabel:@"foo" forSegment:0];
    [segmentedControl setTag:1 forSegment:0];
    
    [segmentedControl setWidth:60.0 forSegment:1];
    [segmentedControl setLabel:@"bar" forSegment:1];
    [segmentedControl setTag:2 forSegment:1];

    [segmentedControl setWidth:25.0 forSegment:2];
    [segmentedControl setLabel:@"1" forSegment:2];
    [segmentedControl setTag:3 forSegment:2];
    
    //various colors
    var centerBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-center.png" size:CGSizeMake(1.0, 24.0)]),
        dividerBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-divider.png" size:CGSizeMake(1.0, 24.0)]),
        centerHighlightedBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-center.png" size:CGSizeMake(1.0, 24.0)]),
        dividerHighlightedBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-divider.png" size:CGSizeMake(1.0, 24.0)]),
        leftHighlightedBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-left.png" size:CGSizeMake(4.0, 24.0)]),
        rightHighlightedBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-right.png" size:CGSizeMake(4.0, 24.0)]),
        inactiveCenterBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-inactive-center.png" size:CGSizeMake(1.0, 24.0)]),
        inactiveDividerBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-inactive-divider.png" size:CGSizeMake(1.0, 24.0)]),
        inactiveLeftBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-inactive-left.png" size:CGSizeMake(4.0, 24.0)]),
        inactiveRightBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-inactive-right.png" size:CGSizeMake(4.0, 24.0)]),
        leftBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-left.png" size:CGSizeMake(4.0, 24.0)]),
        rightBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-right.png" size:CGSizeMake(4.0, 24.0)]),
        pushedCenterBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-pushed-center.png" size:CGSizeMake(1.0, 24.0)]),
        pushedLeftBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-pushed-left.png" size:CGSizeMake(4.0, 24.0)]),
        pushedRightBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-pushed-right.png" size:CGSizeMake(4.0, 24.0)]);
        pushedHighlightedCenterBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-pushed-highlighted-center.png" size:CGSizeMake(1.0, 24.0)]),
        pushedHighlightedLeftBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-pushed-highlighted-left.png" size:CGSizeMake(4.0, 24.0)]),
        pushedHighlightedRightBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-pushed-highlighted-right.png" size:CGSizeMake(4.0, 24.0)]);

    [segmentedControl setValue:centerBezelColor forThemeAttribute:@"center-segment-bezel-color" inState:CPThemeStateNormal];
    [segmentedControl setValue:inactiveCenterBezelColor forThemeAttribute:@"center-segment-bezel-color" inState:CPThemeStateDisabled];
    [segmentedControl setValue:centerHighlightedBezelColor forThemeAttribute:@"center-segment-bezel-color" inState:CPThemeStateSelected];
    [segmentedControl setValue:pushedCenterBezelColor forThemeAttribute:@"center-segment-bezel-color" inState:CPThemeStateHighlighted];
    [segmentedControl setValue:pushedHighlightedCenterBezelColor forThemeAttribute:@"center-segment-bezel-color" inState:CPThemeStateHighlighted|CPThemeStateSelected];

    [segmentedControl setValue:dividerBezelColor forThemeAttribute:@"divider-bezel-color" inState:CPThemeStateNormal];
    [segmentedControl setValue:inactiveDividerBezelColor forThemeAttribute:@"divider-bezel-color" inState:CPThemeStateDisabled];
    [segmentedControl setValue:dividerHighlightedBezelColor forThemeAttribute:@"divider-bezel-color" inState:CPThemeStateSelected];
    [segmentedControl setValue:dividerBezelColor forThemeAttribute:@"divider-bezel-color" inState:CPThemeStateHighlighted];

    [segmentedControl setValue:rightBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateNormal];
    [segmentedControl setValue:inactiveRightBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateDisabled];
    [segmentedControl setValue:rightHighlightedBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateSelected];
    [segmentedControl setValue:pushedRightBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateHighlighted];
    [segmentedControl setValue:pushedHighlightedRightBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateHighlighted|CPThemeStateSelected];

    [segmentedControl setValue:leftBezelColor forThemeAttribute:@"left-segment-bezel-color" inState:CPThemeStateNormal];
    [segmentedControl setValue:inactiveLeftBezelColor forThemeAttribute:@"left-segment-bezel-color" inState:CPThemeStateDisabled];
    [segmentedControl setValue:leftHighlightedBezelColor forThemeAttribute:@"left-segment-bezel-color" inState:CPThemeStateSelected];
    [segmentedControl setValue:pushedLeftBezelColor forThemeAttribute:@"left-segment-bezel-color" inState:CPThemeStateHighlighted];
    [segmentedControl setValue:pushedHighlightedLeftBezelColor forThemeAttribute:@"left-segment-bezel-color" inState:CPThemeStateHighlighted|CPThemeStateSelected];

    [segmentedControl setValue:CGInsetMake(0.0, 4.0, 0.0, 4.0) forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];

    [segmentedControl setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"bezel-inset" inState:CPThemeStateNormal];

    [segmentedControl setValue:[CPFont boldSystemFontOfSize:12.0] forThemeAttribute:@"font"];
    [segmentedControl setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color"];
    [segmentedControl setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color"];
    [segmentedControl setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset"];
    [segmentedControl setValue:CPLineBreakByTruncatingTail forThemeAttribute:@"line-break-mode"];

    [segmentedControl setValue:1.0 forThemeAttribute:@"divider-thickness"];
    [segmentedControl setValue:24.0 forThemeAttribute:@"default-height"];

    return segmentedControl;
}

+ (CPSlider)themedHorizontalSlider
{
    var slider = [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, 24.0)],
        trackColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [_CPCibCustomResource imageResourceWithName:"horizontal-track-left.png" size:CGSizeMake(4.0, 5.0)],
            [_CPCibCustomResource imageResourceWithName:"horizontal-track-center.png" size:CGSizeMake(1.0, 5.0)],
            [_CPCibCustomResource imageResourceWithName:"horizontal-track-right.png" size:CGSizeMake(4.0, 5.0)]
        ]
        isVertical:NO]];

    [slider setValue:5.0 forThemeAttribute:@"track-width"];
    [slider setValue:trackColor forThemeAttribute:@"track-color"];
    
        var knobColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob.png" size:CGSizeMake(23.0, 24.0)]];
        knobHighlightedColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob-highlighted.png" size:CGSizeMake(23.0, 24.0)]];

    [slider setValue:CGSizeMake(23.0, 24.0) forThemeAttribute:@"knob-size"];
    [slider setValue:knobColor forThemeAttribute:@"knob-color"];
    [slider setValue:knobHighlightedColor forThemeAttribute:@"knob-color" inState:CPThemeStateHighlighted];
    
    return slider;
}

+ (CPSlider)themedVerticalSlider
{
    var slider = [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 24.0, 50.0)],
        trackColor =  [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [_CPCibCustomResource imageResourceWithName:"vertical-track-top.png" size:CGSizeMake(5.0, 6.0)],
            [_CPCibCustomResource imageResourceWithName:"vertical-track-center.png" size:CGSizeMake(5.0, 1.0)],
            [_CPCibCustomResource imageResourceWithName:"vertical-track-bottom.png" size:CGSizeMake(5.0, 4.0)]
        ]
        isVertical:YES]];
        
    [slider setValue:5.0 forThemeAttribute:@"track-width"];
    [slider setValue:trackColor forThemeAttribute:@"track-color" inState:CPThemeStateVertical];
    
        var knobColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob.png" size:CGSizeMake(23.0, 24.0)]];
        knobHighlightedColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob-highlighted.png" size:CGSizeMake(23.0, 24.0)]];
    
    [slider setValue:CGSizeMake(23.0, 24.0) forThemeAttribute:@"knob-size"];
    [slider setValue:knobColor forThemeAttribute:@"knob-color"];
    [slider setValue:knobHighlightedColor forThemeAttribute:@"knob-color" inState:CPThemeStateHighlighted];
    
    return slider;
}

+ (CPSlider)themedCircularSlider
{
    var slider = [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 34.0, 34.0)],
        trackColor = PatternColor([_CPCibCustomResource imageResourceWithName:"circularSliderBezel.png" size:CGSizeMake(34.0, 34.0)]);

    [slider setSliderType:CPCircularSlider];
    [slider setValue:trackColor forThemeAttribute:@"track-color" inState:CPThemeStateCircular];

    var knobColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"circularSliderKnob.png" size:CGSizeMake(5.0, 5.0)]],
        knobHighlightedColor = knobColor;

    [slider setValue:CGSizeMake(5.0, 5.0) forThemeAttribute:@"knob-size" inState:CPThemeStateCircular];
    [slider setValue:knobColor forThemeAttribute:@"knob-color" inState:CPThemeStateCircular];
    [slider setValue:knobHighlightedColor forThemeAttribute:@"knob-color" inState:CPThemeStateCircular|CPThemeStateHighlighted];

    return slider;
}

+ (CPButtonBar)themedButtonBar
{
    var buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 26.0)],
        color = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [_CPCibCustomResource imageResourceWithName:"buttonbar-bezel.png" size:CGSizeMake(1.0, 26.0)],
            [_CPCibCustomResource imageResourceWithName:"buttonbar-bezel.png" size:CGSizeMake(1.0, 26.0)],
            [_CPCibCustomResource imageResourceWithName:"buttonbar-bezel-right.png" size:CGSizeMake(13.0, 26.0)]
        ]
        isVertical:NO]];

    [buttonBar setValue:color forThemeAttribute:@"bezel-color"];
    
    return buttonBar;
}

@end

@implementation AristoHUDThemeDescriptor : BKThemeDescriptor
{
}

+ (CPString)themeName
{
    return @"Aristo-HUD";
}

+ (CPColor)defaultShowcaseBackgroundColor
{
    return [CPColor blackColor];
}

+ (CPButton)themedButton
{
    var button = [[CPButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 20.0)],

        bezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"HUD/button-bezel-left.png" size:CGSizeMake(13.0, 20.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/button-bezel-center.png" size:CGSizeMake(1.0, 20.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/button-bezel-right.png" size:CGSizeMake(13.0, 20.0)]
            ]
        isVertical:NO]],

        highlightedBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"HUD/button-bezel-highlighted-left.png" size:CGSizeMake(13.0, 20.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/button-bezel-highlighted-center.png" size:CGSizeMake(1.0, 20.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/button-bezel-highlighted-right.png" size:CGSizeMake(13.0, 20.0)]
            ]
        isVertical:NO]];

    [button setTitle:@"Cancel"];

    [button setValue:[CPFont systemFontOfSize:11.0] forThemeAttribute:@"font" inState:CPThemeStateBordered];
    [button setValue:[CPColor whiteColor] forThemeAttribute:@"text-color"];
    [button setValue:CPLineBreakByTruncatingTail forThemeAttribute:@"line-break-mode"];

    [button setValue:bezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
    [button setValue:highlightedBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateHighlighted];
    [button setValue:CGInsetMake(2.0, 5.0, 4.0, 5.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBordered];

    [button setValue:CGSizeMake(0.0, 20.0) forThemeAttribute:@"min-size"];
    [button setValue:CGSizeMake(-1.0, 20.0) forThemeAttribute:@"max-size"];

    return button;
}

@end

function PatternColor(anImage)
{
    return [CPColor colorWithPatternImage:anImage];
}
