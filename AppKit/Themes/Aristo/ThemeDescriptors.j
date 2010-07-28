/*
 * AppController.j
 * Aristo
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc. All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/AppKit.j>
@import <AppKit/CPTableHeaderView.j>


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
        isVertical:NO]],

        defaultDisabledBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"default-button-bezel-disabled-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"default-button-bezel-disabled-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"default-button-bezel-disabled-right.png" size:CGSizeMake(4.0, 24.0)]
            ]
        isVertical:NO]],
        
        disabledBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"button-bezel-disabled-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"button-bezel-disabled-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"button-bezel-disabled-right.png" size:CGSizeMake(4.0, 24.0)]
            ]
        isVertical:NO]];

    [button setValue:[CPFont boldSystemFontOfSize:12.0] forThemeAttribute:@"font" inState:CPThemeStateBordered];
    [button setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color"];
    [button setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateBordered];
    [button setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:0.6] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateBordered|CPThemeStateDisabled];
    [button setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateBordered];
    [button setValue:CPLineBreakByTruncatingTail forThemeAttribute:@"line-break-mode"];
    
    [button setValue:bezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
    [button setValue:highlightedBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateHighlighted];
    [button setValue:CGInsetMake(0.0, 5.0, 0.0, 5.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBordered];

    [button setValue:[CPColor colorWithCalibratedWhite:0.6 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [button setValue:disabledBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateDisabled];
    [button setValue:defaultDisabledBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateDefault|CPThemeStateDisabled];
    
    [button setValue:defaultBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateDefault];
    [button setValue:defaultHighlightedBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateHighlighted|CPThemeStateDefault];
    [button setValue:[CPColor colorWithCalibratedRed:13.0/255.0 green:51.0/255.0 blue:70.0/255.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateDefault];
    [button setValue:[CPColor colorWithCalibratedRed:13.0/255.0 green:51.0/255.0 blue:70.0/255.0 alpha:0.6] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled|CPThemeStateDefault];

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

    var disabledBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"button-bezel-disabled-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"button-bezel-disabled-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"popup-bezel-disabled-right.png" size:CGSizeMake(27.0, 24.0)]
            ]
        isVertical:NO]];
            
    [button setTitle:@"Pop Up"];
    
    [button setValue:color forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
    [button setValue:disabledBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateDisabled];

    [button setValue:CGInsetMake(0, 27.0 + 5.0, 0, 5.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBordered];
    [button setValue:[CPFont boldSystemFontOfSize:12.0] forThemeAttribute:@"font"];
    [button setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color"];
    [button setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color"];
    [button setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset"];

    [button setValue:CGSizeMake(32.0, 24.0) forThemeAttribute:@"min-size"];
    [button setValue:CGSizeMake(-1.0, 24.0) forThemeAttribute:@"max-size"];    

    [button addItemWithTitle:@"item"];

    [button setValue:[CPColor colorWithCalibratedWhite:0.6 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateBordered|CPThemeStateDisabled];
    [button setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:0.6] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateBordered|CPThemeStateDisabled];
    
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

    var disabledColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"button-bezel-disabled-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"button-bezel-disabled-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"popup-bezel-disabled-right-pullsdown.png" size:CGSizeMake(27.0, 24.0)]
            ]
        isVertical:NO]];

    [button setTitle:@"Pull Down"];

    [button setValue:color forThemeAttribute:@"bezel-color" inState:CPPopUpButtonStatePullsDown|CPThemeStateBordered];
    [button setValue:disabledColor forThemeAttribute:@"bezel-color" inState:CPThemeStateDisabled|CPPopUpButtonStatePullsDown|CPThemeStateBordered];

    [button setValue:CGInsetMake(0, 27.0 + 5.0, 0, 5.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBordered];
    [button setValue:[CPFont boldSystemFontOfSize:12.0] forThemeAttribute:@"font"];
    [button setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color"];
    [button setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color"];
    [button setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset"];

    [button setValue:CGSizeMake(32.0, 24.0) forThemeAttribute:@"min-size"];
    [button setValue:CGSizeMake(-1.0, 24.0) forThemeAttribute:@"max-size"];

    [button setValue:[CPColor colorWithCalibratedWhite:0.6 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateBordered|CPThemeStateDisabled];
    [button setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:0.6] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateBordered|CPThemeStateDisabled];

    [button addItemWithTitle:@"item"];

    return button;
}

+ (CPScroller)themedVerticalScroller
{
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 15.0, 170.0)],
        trackColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-vertical-track.png" size:CGSizeMake(15.0, 1.0)]),
        disabledTrackColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-vertical-track-disabled.png" size:CGSizeMake(15.0, 1.0)]);
        
    [scroller setValue:21.0 forThemeAttribute:@"minimum-knob-length" inState:CPThemeStateVertical];
    [scroller setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"knob-inset" inState:CPThemeStateVertical];
    [scroller setValue:CGInsetMake(-10.0, 0.0, -10.0, 0.0) forThemeAttribute:@"track-inset" inState:CPThemeStateVertical];

    [scroller setValue:trackColor forThemeAttribute:@"knob-slot-color" inState:CPThemeStateVertical];
    [scroller setValue:disabledTrackColor forThemeAttribute:@"knob-slot-color" inState:CPThemeStateVertical | CPThemeStateDisabled];

    var arrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-up-arrow.png" size:CGSizeMake(15.0, 24.0)]),
        highlightedArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-up-arrow-highlighted.png" size:CGSizeMake(15.0, 24.0)]),
        disabledArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-up-arrow-disabled.png" size:CGSizeMake(15.0, 24.0)]);

    [scroller setValue:CGSizeMake(15.0, 24.0) forThemeAttribute:@"decrement-line-size" inState:CPThemeStateVertical];
    [scroller setValue:arrowColor forThemeAttribute:@"decrement-line-color" inState:CPThemeStateVertical];
    [scroller setValue:highlightedArrowColor forThemeAttribute:@"decrement-line-color" inState:CPThemeStateVertical | CPThemeStateHighlighted],
    [scroller setValue:disabledArrowColor forThemeAttribute:@"decrement-line-color" inState:CPThemeStateVertical | CPThemeStateDisabled];

    var arrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-down-arrow.png" size:CGSizeMake(15.0, 24.0)]),
        highlightedArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-down-arrow-highlighted.png" size:CGSizeMake(15.0, 24.0)]),
        disabledArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-down-arrow-disabled.png" size:CGSizeMake(15.0, 24.0)]);

    [scroller setValue:CGSizeMake(15.0, 24.0) forThemeAttribute:@"increment-line-size" inState:CPThemeStateVertical];
    [scroller setValue:arrowColor forThemeAttribute:@"increment-line-color" inState:CPThemeStateVertical];
    [scroller setValue:highlightedArrowColor forThemeAttribute:@"increment-line-color" inState:CPThemeStateVertical | CPThemeStateHighlighted];
    [scroller setValue:disabledArrowColor forThemeAttribute:@"increment-line-color" inState:CPThemeStateVertical | CPThemeStateDisabled];
    
    var knobColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"scroller-vertical-knob-top.png" size:CGSizeMake(15.0, 10.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-vertical-knob-center.png" size:CGSizeMake(15.0, 1.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-vertical-knob-bottom.png" size:CGSizeMake(15.0, 10.0)]
            ]
        isVertical:YES]);

    var knobDisabledColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"scroller-vertical-knob-disabled-top.png" size:CGSizeMake(15.0, 10.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-vertical-knob-disabled-center.png" size:CGSizeMake(15.0, 1.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-vertical-knob-disabled-bottom.png" size:CGSizeMake(15.0, 10.0)]
            ]
        isVertical:YES]);
    
    [scroller setValue:knobColor forThemeAttribute:@"knob-color" inState:CPThemeStateVertical];
    [scroller setValue:knobDisabledColor forThemeAttribute:@"knob-color" inState:CPThemeStateVertical|CPThemeStateDisabled];
    
    [scroller setFloatValue:0.1];
    [scroller setKnobProportion:0.5];

    return scroller;
}

+ (CPScroller)themedHorizontalScroller
{
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 170.0, 15.0)],
        trackColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-horizontal-track.png" size:CGSizeMake(1.0, 15.0)]),
        disabledTrackColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-horizontal-track-disabled.png" size:CGSizeMake(1.0, 15.0)]);

    [scroller setValue:21.0 forThemeAttribute:@"minimum-knob-length"];
    [scroller setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"knob-inset"];
    [scroller setValue:CGInsetMake(0.0, -10.0, 0.0, -11.0) forThemeAttribute:@"track-inset"];

    [scroller setValue:trackColor forThemeAttribute:@"knob-slot-color"];
    [scroller setValue:disabledTrackColor forThemeAttribute:@"knob-slot-color" inState:CPThemeStateDisabled];

    var arrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-left-arrow.png" size:CGSizeMake(24.0, 15.0)]),
        highlightedArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-left-arrow-highlighted.png" size:CGSizeMake(24.0, 15.0)]),
        disabledArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-left-arrow-disabled.png" size:CGSizeMake(24.0, 15.0)]);

    [scroller setValue:CGSizeMake(24.0, 15.0) forThemeAttribute:@"decrement-line-size"];
    [scroller setValue:arrowColor forThemeAttribute:@"decrement-line-color"];
    [scroller setValue:highlightedArrowColor forThemeAttribute:@"decrement-line-color" inState:CPThemeStateHighlighted],
    [scroller setValue:disabledArrowColor forThemeAttribute:@"decrement-line-color" inState:CPThemeStateDisabled];

    var arrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-right-arrow.png" size:CGSizeMake(24.0, 15.0)]),
        highlightedArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-right-arrow-highlighted.png" size:CGSizeMake(24.0, 15.0)]),
        disabledArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"scroller-right-arrow-disabled.png" size:CGSizeMake(24.0, 15.0)]);

    [scroller setValue:CGSizeMake(24.0, 15.0) forThemeAttribute:@"increment-line-size"];
    [scroller setValue:arrowColor forThemeAttribute:@"increment-line-color"];
    [scroller setValue:highlightedArrowColor forThemeAttribute:@"increment-line-color" inState:CPThemeStateHighlighted];
    [scroller setValue:disabledArrowColor forThemeAttribute:@"increment-line-color" inState:CPThemeStateDisabled];
    
    var knobColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"scroller-horizontal-knob-left.png" size:CGSizeMake(10.0, 15.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-horizontal-knob-center.png" size:CGSizeMake(1.0, 15.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-horizontal-knob-right.png" size:CGSizeMake(10.0, 15.0)]
            ]
        isVertical:NO]);

    var knobDisabledColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"scroller-horizontal-knob-disabled-left.png" size:CGSizeMake(10.0, 15.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-horizontal-knob-disabled-center.png" size:CGSizeMake(1.0, 15.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-horizontal-knob-disabled-right.png" size:CGSizeMake(10.0, 15.0)]
            ]
        isVertical:NO]);

    [scroller setValue:knobColor forThemeAttribute:@"knob-color"];
    [scroller setValue:knobDisabledColor forThemeAttribute:@"knob-color" inState:CPThemeStateDisabled];

    [scroller setFloatValue:0.1];
    [scroller setKnobProportion:0.5];

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


    // tableview dataview stuff 
    [textfield setValue:[CPColor colorWithRed:51.0 / 255.0 green:51.0 / 255.0 blue:51.0 / 255.0 alpha:1.0] forThemeAttribute:"text-color" inState:CPThemeStateTableDataView];
    [textfield setValue:CPLineBreakByTruncatingTail forThemeAttribute:@"line-break-mode" inState:CPThemeStateTableDataView|CPThemeStateTableDataView];
    [textfield setValue:CPCenterVerticalTextAlignment forThemeAttribute:@"vertical-alignment" inState:CPThemeStateTableDataView|CPThemeStateTableDataView];
    [textfield setValue:CGInsetMake(0.0, 0.0, 0.0, 5.0) forThemeAttribute:@"content-inset" inState:CPThemeStateTableDataView|CPThemeStateTableDataView];
    [textfield setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateTableDataView|CPThemeStateSelectedTableDataView];
    [textfield setValue:[CPFont boldSystemFontOfSize:12.0] forThemeAttribute:@"font" inState:CPThemeStateTableDataView|CPThemeStateSelectedTableDataView];
    

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

    [button setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];

    var bezelColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"radio-bezel.png" size:CGSizeMake(17.0, 17.0)], nil, nil
            ]
        isVertical:NO]),
        bezelColorSelected = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"radio-bezel-selected.png" size:CGSizeMake(17.0, 17.0)], nil, nil
            ]
        isVertical:NO]),
        bezelColorSelectedHighlighted = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"radio-bezel-selected-highlighted.png" size:CGSizeMake(17.0, 17.0)], nil, nil
            ]
        isVertical:NO]),
        bezelColorSelectedDisabled = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"radio-bezel-selected-disabled.png" size:CGSizeMake(17.0, 17.0)], nil, nil
            ]
        isVertical:NO]),
        bezelColorDisabled = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"radio-bezel-disabled.png" size:CGSizeMake(17.0, 17.0)], nil, nil
            ]
        isVertical:NO]),
        bezelColorHighlighted = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"radio-bezel-highlighted.png" size:CGSizeMake(17.0, 17.0)], nil, nil
            ]
        isVertical:NO]);

    [button setValue:CPLeftTextAlignment forThemeAttribute:@"alignment" inState:CPThemeStateBordered];
    [button setValue:[CPFont systemFontOfSize:12.0] forThemeAttribute:@"font" inState:CPThemeStateBordered];
    [button setValue:CGInsetMake(0.0, 0.0, 0.0, 20.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBordered];
    [button setValue:bezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];    
    [button setValue:bezelColorSelected forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateSelected];
    [button setValue:bezelColorSelectedHighlighted forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateSelected | CPThemeStateHighlighted];
    [button setValue:bezelColorHighlighted forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateHighlighted];
    [button setValue:bezelColorDisabled forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateDisabled];
    [button setValue:bezelColorSelectedDisabled forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateDisabled | CPThemeStateSelected];

    [button setValue:CGSizeMake(0.0, 17.0) forThemeAttribute:@"min-size"];

    return button;
}

+ (CPRadioButton)themedCheckBoxButton
{
    var button = [[CPCheckBox alloc] initWithFrame:CGRectMake(0.0, 0.0, 120.0, 17.0)];
    
    [button setTitle:@"Another option"];

    [button setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];

    var bezelColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"check-box-bezel.png" size:CGSizeMake(15.0, 16.0)], nil, nil
            ]
        isVertical:NO]),
        bezelColorSelected = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"check-box-bezel-selected.png" size:CGSizeMake(15.0, 16.0)], nil, nil
            ]
        isVertical:NO]),
        bezelColorSelectedHighlighted = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"check-box-bezel-selected-highlighted.png" size:CGSizeMake(15.0, 16.0)], nil, nil
            ]
        isVertical:NO]),
        bezelColorSelectedDisabled = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"check-box-bezel-selected-disabled.png" size:CGSizeMake(15.0, 16.0)], nil, nil
            ]
        isVertical:NO]),
        bezelColorDisabled = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"check-box-bezel-disabled.png" size:CGSizeMake(15.0, 16.0)], nil, nil
            ]
        isVertical:NO]),
        bezelColorHighlighted = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"check-box-bezel-highlighted.png" size:CGSizeMake(15.0, 16.0)], nil, nil
            ]
        isVertical:NO]);
    
    [button setValue:CPLeftTextAlignment forThemeAttribute:@"alignment" inState:CPThemeStateBordered];
    [button setValue:[CPFont systemFontOfSize:12.0] forThemeAttribute:@"font" inState:CPThemeStateBordered];
    [button setValue:CGInsetMake(0.0, 0.0, 0.0, 20.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBordered];
    [button setValue:bezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];    
    [button setValue:bezelColorSelected forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateSelected];
    [button setValue:bezelColorSelectedHighlighted forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateSelected | CPThemeStateHighlighted];
    [button setValue:bezelColorHighlighted forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateHighlighted];
    [button setValue:bezelColorDisabled forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateDisabled];
    [button setValue:bezelColorSelectedDisabled forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateDisabled | CPThemeStateSelected];

    [button setValue:CGSizeMake(0.0, 17.0) forThemeAttribute:@"min-size"];

    return button;
}

+ (CPRadioButton)themedMixedCheckBoxButton
{
    button = [self themedCheckBoxButton];

    [button setAllowsMixedState:YES];
    [button setState:CPMixedState];

    var mixedSelectedColor = 
        PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"check-box-bezel-mixed-highlighted.png" size:CGSizeMake(15.0, 16.0)], nil, nil
            ]
        isVertical:NO]),
        
        mixedDisabledColor = 
        PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"check-box-bezel-mixed-disabled.png" size:CGSizeMake(15.0, 16.0)], nil, nil
            ]
        isVertical:NO]),
        
        mixedColor = 
        PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"check-box-bezel-mixed.png" size:CGSizeMake(15.0, 16.0)], nil, nil
            ]
        isVertical:NO]);

    [button setValue:mixedSelectedColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeState("mixed")|CPThemeStateHighlighted];
    [button setValue:mixedColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeState("mixed")];
    [button setValue:mixedDisabledColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeState("mixed")|CPThemeStateDisabled];
    
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

    [segmentedControl setWidth:35.0 forSegment:2];
    [segmentedControl setLabel:@"1" forSegment:2];
    [segmentedControl setTag:3 forSegment:2];
    
    //various colors
    var centerBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-center.png" size:CGSizeMake(1.0, 24.0)]),
        dividerBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-divider.png" size:CGSizeMake(1.0, 24.0)]),
        centerHighlightedBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-center.png" size:CGSizeMake(1.0, 24.0)]),
        dividerHighlightedBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-divider.png" size:CGSizeMake(1.0, 24.0)]),
        leftHighlightedBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-left.png" size:CGSizeMake(4.0, 24.0)]),
        rightHighlightedBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-right.png" size:CGSizeMake(4.0, 24.0)]),
        inactiveCenterBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-disabled-center.png" size:CGSizeMake(1.0, 24.0)]),
        inactiveDividerBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-disabled-divider.png" size:CGSizeMake(1.0, 24.0)]),
        inactiveLeftBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-disabled-left.png" size:CGSizeMake(4.0, 24.0)]),
        inactiveRightBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-disabled-right.png" size:CGSizeMake(4.0, 24.0)]),
        inactiveHighlightedCenterBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-disabled-center.png" size:CGSizeMake(1.0, 24.0)]),
        inactiveHighlightedDividerBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-disabled-divider.png" size:CGSizeMake(1.0, 24.0)]),
        inactiveHighlightedLeftBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-disabled-left.png" size:CGSizeMake(4.0, 24.0)]),
        inactiveHighlightedRightBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-disabled-right.png" size:CGSizeMake(4.0, 24.0)]),
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
    [segmentedControl setValue:inactiveHighlightedCenterBezelColor forThemeAttribute:@"center-segment-bezel-color" inState:CPThemeStateSelected|CPThemeStateDisabled];
    [segmentedControl setValue:centerHighlightedBezelColor forThemeAttribute:@"center-segment-bezel-color" inState:CPThemeStateSelected];
    [segmentedControl setValue:pushedCenterBezelColor forThemeAttribute:@"center-segment-bezel-color" inState:CPThemeStateHighlighted];
    [segmentedControl setValue:pushedHighlightedCenterBezelColor forThemeAttribute:@"center-segment-bezel-color" inState:CPThemeStateHighlighted|CPThemeStateSelected];

    [segmentedControl setValue:dividerBezelColor forThemeAttribute:@"divider-bezel-color" inState:CPThemeStateNormal];
    [segmentedControl setValue:inactiveDividerBezelColor forThemeAttribute:@"divider-bezel-color" inState:CPThemeStateDisabled];
    [segmentedControl setValue:inactiveHighlightedDividerBezelColor forThemeAttribute:@"divider-bezel-color" inState:CPThemeStateSelected|CPThemeStateDisabled];
    [segmentedControl setValue:dividerHighlightedBezelColor forThemeAttribute:@"divider-bezel-color" inState:CPThemeStateSelected];
    [segmentedControl setValue:dividerBezelColor forThemeAttribute:@"divider-bezel-color" inState:CPThemeStateHighlighted];

    [segmentedControl setValue:rightBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateNormal];
    [segmentedControl setValue:inactiveRightBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateDisabled];
    [segmentedControl setValue:inactiveHighlightedRightBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateSelected|CPThemeStateDisabled];
    [segmentedControl setValue:rightHighlightedBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateSelected];
    [segmentedControl setValue:pushedRightBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateHighlighted];
    [segmentedControl setValue:pushedHighlightedRightBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateHighlighted|CPThemeStateSelected];

    [segmentedControl setValue:leftBezelColor forThemeAttribute:@"left-segment-bezel-color" inState:CPThemeStateNormal];
    [segmentedControl setValue:inactiveLeftBezelColor forThemeAttribute:@"left-segment-bezel-color" inState:CPThemeStateDisabled];
    [segmentedControl setValue:inactiveHighlightedLeftBezelColor forThemeAttribute:@"left-segment-bezel-color" inState:CPThemeStateSelected|CPThemeStateDisabled];
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
        isVertical:NO]],
        
        trackDisabledColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [_CPCibCustomResource imageResourceWithName:"horizontal-track-disabled-left.png" size:CGSizeMake(4.0, 5.0)],
            [_CPCibCustomResource imageResourceWithName:"horizontal-track-disabled-center.png" size:CGSizeMake(1.0, 5.0)],
            [_CPCibCustomResource imageResourceWithName:"horizontal-track-disabled-right.png" size:CGSizeMake(4.0, 5.0)]
        ]
        isVertical:NO]];

    [slider setValue:5.0 forThemeAttribute:@"track-width"];
    [slider setValue:trackColor forThemeAttribute:@"track-color"];
    [slider setValue:trackDisabledColor forThemeAttribute:@"track-color" inState:CPThemeStateDisabled];
    
        var knobColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob.png" size:CGSizeMake(23.0, 24.0)]],
            knobHighlightedColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob-highlighted.png" size:CGSizeMake(23.0, 24.0)]],
            knobDisabledColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob-disabled.png" size:CGSizeMake(23.0, 24.0)]];

    [slider setValue:CGSizeMake(23.0, 24.0) forThemeAttribute:@"knob-size"];
    [slider setValue:knobColor forThemeAttribute:@"knob-color"];
    [slider setValue:knobHighlightedColor forThemeAttribute:@"knob-color" inState:CPThemeStateHighlighted];
    [slider setValue:knobDisabledColor forThemeAttribute:@"knob-color" inState:CPThemeStateDisabled];
    
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
        isVertical:YES]],
        trackDisabledColor =  [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [_CPCibCustomResource imageResourceWithName:"vertical-track-disabled-top.png" size:CGSizeMake(5.0, 6.0)],
            [_CPCibCustomResource imageResourceWithName:"vertical-track-disabled-center.png" size:CGSizeMake(5.0, 1.0)],
            [_CPCibCustomResource imageResourceWithName:"vertical-track-disabled-bottom.png" size:CGSizeMake(5.0, 4.0)]
        ]
        isVertical:YES]];
        
    [slider setValue:5.0 forThemeAttribute:@"track-width"];
    [slider setValue:trackColor forThemeAttribute:@"track-color" inState:CPThemeStateVertical];
    [slider setValue:trackDisabledColor forThemeAttribute:@"track-color" inState:CPThemeStateDisabled];
    
        var knobColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob.png" size:CGSizeMake(23.0, 24.0)]],
            knobHighlightedColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob-highlighted.png" size:CGSizeMake(23.0, 24.0)]],
            knobDisabledColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob-disabled.png" size:CGSizeMake(23.0, 24.0)]];

    [slider setValue:CGSizeMake(23.0, 24.0) forThemeAttribute:@"knob-size"];
    [slider setValue:knobColor forThemeAttribute:@"knob-color"];
    [slider setValue:knobHighlightedColor forThemeAttribute:@"knob-color" inState:CPThemeStateHighlighted];
    [slider setValue:knobDisabledColor forThemeAttribute:@"knob-color" inState:CPThemeStateDisabled];
    
    return slider;
}

+ (CPSlider)themedCircularSlider
{
    var slider = [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 34.0, 34.0)],
        trackColor = PatternColor([_CPCibCustomResource imageResourceWithName:"slider-circular-bezel.png" size:CGSizeMake(34.0, 34.0)]),
        trackDisabledColor = PatternColor([_CPCibCustomResource imageResourceWithName:"slider-circular-disabled-bezel.png" size:CGSizeMake(34.0, 34.0)]);

    [slider setSliderType:CPCircularSlider];
    [slider setValue:trackColor forThemeAttribute:@"track-color" inState:CPThemeStateCircular];
    [slider setValue:trackDisabledColor forThemeAttribute:@"track-color" inState:CPThemeStateDisabled|CPThemeStateCircular];

    var knobColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"slider-circular-knob.png" size:CGSizeMake(5.0, 5.0)]],
        knobDisabledColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"slider-circular-disabled-knob.png" size:CGSizeMake(5.0, 5.0)]],
        knobHighlightedColor = knobColor;

    [slider setValue:CGSizeMake(5.0, 5.0) forThemeAttribute:@"knob-size" inState:CPThemeStateCircular];
    [slider setValue:knobColor forThemeAttribute:@"knob-color" inState:CPThemeStateCircular];
    [slider setValue:knobDisabledColor forThemeAttribute:@"knob-color" inState:CPThemeStateDisabled|CPThemeStateCircular];
    [slider setValue:knobHighlightedColor forThemeAttribute:@"knob-color" inState:CPThemeStateCircular|CPThemeStateHighlighted];

    return slider;
}

+ (CPButtonBar)themedButtonBar
{
    var buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 147.0, 26.0)],
        color = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"buttonbar-bezel.png" size:CGSizeMake(1.0, 26.0)]];

    [buttonBar setHasResizeControl:YES];

    [buttonBar setValue:color forThemeAttribute:@"bezel-color"];

    var resizeColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"buttonbar-resize-control.png" size:CGSizeMake(5.0, 10.0)]];

    [buttonBar setValue:CGSizeMake(5.0, 10.0) forThemeAttribute:@"resize-control-size"];
    [buttonBar setValue:CGInsetMake(9.0, 4.0, 7.0, 4.0) forThemeAttribute:@"resize-control-inset"];
    [buttonBar setValue:resizeColor forThemeAttribute:@"resize-control-color"];

    var buttonBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"buttonbar-button-bezel-left.png" size:CGSizeMake(2.0, 25.0)],
                [_CPCibCustomResource imageResourceWithName:"buttonbar-button-bezel-center.png" size:CGSizeMake(1.0, 25.0)],
                [_CPCibCustomResource imageResourceWithName:"buttonbar-button-bezel-right.png" size:CGSizeMake(2.0, 25.0)]
            ]
        isVertical:NO]],

        buttonBezelHighlightedColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"buttonbar-button-bezel-highlighted-left.png" size:CGSizeMake(2.0, 25.0)],
                [_CPCibCustomResource imageResourceWithName:"buttonbar-button-bezel-highlighted-center.png" size:CGSizeMake(1.0, 25.0)],
                [_CPCibCustomResource imageResourceWithName:"buttonbar-button-bezel-highlighted-right.png" size:CGSizeMake(2.0, 25.0)]
            ]
        isVertical:NO]],

        buttonBezelDisabledColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"buttonbar-button-bezel-disabled-left.png" size:CGSizeMake(2.0, 25.0)],
                [_CPCibCustomResource imageResourceWithName:"buttonbar-button-bezel-disabled-center.png" size:CGSizeMake(1.0, 25.0)],
                [_CPCibCustomResource imageResourceWithName:"buttonbar-button-bezel-disabled-right.png" size:CGSizeMake(2.0, 25.0)]
            ]
        isVertical:NO]];

    [buttonBar setValue:buttonBezelColor forThemeAttribute:@"button-bezel-color"];
    [buttonBar setValue:buttonBezelHighlightedColor forThemeAttribute:@"button-bezel-color" inState:CPThemeStateHighlighted];
    [buttonBar setValue:buttonBezelDisabledColor forThemeAttribute:@"button-bezel-color" inState:CPThemeStateDisabled];
    [buttonBar setValue:[CPColor blackColor] forThemeAttribute:@"button-text-color"];

    var popup = [CPButtonBar actionPopupButton];
    [popup addItemWithTitle:"Item 1"];
    [popup addItemWithTitle:"Item 2"];

    [buttonBar setButtons:[[CPButtonBar plusButton], [CPButtonBar minusButton], popup]];

    return buttonBar;
}

+ (_CPTableColumnHeaderView)themedColumnHeader
{
    var header             = [[_CPTableColumnHeaderView alloc] initWithFrame:CGRectMake(0,0,50,24)],
        highlightedPressed = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"tableview-headerview-highlighted-pressed.png" size:CGSizeMake(1.0, 23.0)]],
        highlighted        = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"tableview-headerview-highlighted.png" size:CGSizeMake(1.0, 23.0)]],
        pressed            = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"tableview-headerview-pressed.png" size:CGSizeMake(1.0, 23.0)]],
        normal             = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"tableview-headerview.png" size:CGSizeMake(1.0, 23.0)]];


    [header setStringValue:@"Table Header"];

    [header setValue:normal forThemeAttribute:@"background-color"];
    [header setValue:CGInsetMake(0, 5, 0, 5) forThemeAttribute:@"text-inset"];
    [header setValue:[CPColor colorWithRed:51.0 / 255.0 green:51.0 / 255.0 blue:51.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color"];
    [header setValue:[CPFont boldSystemFontOfSize:12.0] forThemeAttribute:@"text-font"];
    [header setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color"];
    [header setValue:CGSizeMake(0,1) forThemeAttribute:@"text-shadow-offset"];
    [header setValue:CPLeftTextAlignment forThemeAttribute:@"text-alignment"];

    [header setValue:pressed forThemeAttribute:@"background-color" inState:CPThemeStateHighlighted];
    [header setValue:highlighted forThemeAttribute:@"background-color" inState:CPThemeStateSelected];
    [header setValue:highlightedPressed forThemeAttribute:@"background-color" inState:CPThemeStateHighlighted|CPThemeStateSelected];

    return header;
}

+ (CPTableHeaderView)themedTableHeaderRow
{
    var header = [[CPTableHeaderView alloc] initWithFrame:CGRectMake(0,0,50,24)],
        normal = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"tableview-headerview.png" size:CGSizeMake(1.0, 23.0)]];

    [header setValue:normal forThemeAttribute:@"background-color"];

    return header;
}

+ (_CPCornerView)themedCornerview
{
    var corner = [[_CPCornerView alloc] initWithFrame:CGRectMake(0,0,25, 23)],
        normal = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"tableview-headerview.png" size:CGSizeMake(1.0, 23.0)]];

    [corner setValue:normal forThemeAttribute:"background-color"];

    return corner;
}

+ (CPTableView)themedTableView
{
    // This is a bit more complicated than the rest because we actually set theme values for several different (table related) controls in this method

    var tableview = [[CPTableView alloc] initWithFrame:CGRectMake(0,0,200,200)];

    // Now theme the tableview
    var sortImage = [_CPCibCustomResource imageResourceWithName:"tableview-headerview-ascending.png" size:CGSizeMake(9.0, 8.0)],
        sortImageReversed = [_CPCibCustomResource imageResourceWithName:"tableview-headerview-descending.png" size:CGSizeMake(9.0, 8.0)],
        alternatingRowColors = [[CPColor whiteColor], [CPColor colorWithRed:245.0 / 255.0 green:249.0 / 255.0 blue:252.0 / 255.0 alpha:1.0]],
        gridColor = [CPColor colorWithHexString:@"dce0e2"],
        selectionColor = [CPColor colorWithHexString:@"5f83b9"],
        sourceListSelectionColor = [CPDictionary dictionaryWithObjects: [ CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [89.0/255.0, 153.0/255.0, 209.0/255.0,1.0, 33.0/255.0, 94.0/255.0, 208.0/255.0,1.0], [0,1], 2), 
                                                                          [CPColor colorWithCalibratedRed:(61.0/255.0) green:(123.0/255.0) blue:(218.0/255.0) alpha:1.0],
                                                                          [CPColor colorWithCalibratedRed:(31.0/255.0) green:(92.0/255.0) blue:(207.0/255.0) alpha:1.0]
                                                                        ]
                                                               forKeys: [CPSourceListGradient, CPSourceListTopLineColor, CPSourceListBottomLineColor]];

    [tableview setValue:alternatingRowColors forThemeAttribute:"alternating-row-colors"];
    [tableview setValue:gridColor forThemeAttribute:"grid-color"];
    [tableview setValue:[CPColor whiteColor] forThemeAttribute:"highlighted-grid-color"];
    [tableview setValue:selectionColor forThemeAttribute:"selection-color"];
    [tableview setValue:sourceListSelectionColor forThemeAttribute:"sourcelist-selection-color"];
    [tableview setValue:sortImage forThemeAttribute:"sort-image"];
    [tableview setValue:sortImageReversed forThemeAttribute:"sort-image-reversed"];

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

    [segmentedControl setWidth:35.0 forSegment:2];
    [segmentedControl setLabel:@"1" forSegment:2];
    [segmentedControl setTag:3 forSegment:2];
    
    //various colors
    var centerBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-center.png" size:CGSizeMake(1.0, 24.0)]),
        dividerBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-divider.png" size:CGSizeMake(1.0, 24.0)]),
        centerHighlightedBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-highlighted-center.png" size:CGSizeMake(1.0, 24.0)]),
        dividerHighlightedBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-highlighted-divider.png" size:CGSizeMake(1.0, 24.0)]),
        leftHighlightedBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-highlighted-left.png" size:CGSizeMake(4.0, 24.0)]),
        rightHighlightedBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-highlighted-right.png" size:CGSizeMake(4.0, 24.0)]),
        inactiveCenterBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-disabled-center.png" size:CGSizeMake(1.0, 24.0)]),
        inactiveDividerBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-disabled-divider.png" size:CGSizeMake(1.0, 24.0)]),
        inactiveLeftBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-disabled-left.png" size:CGSizeMake(4.0, 24.0)]),
        inactiveRightBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-disabled-right.png" size:CGSizeMake(4.0, 24.0)]),
        inactiveHighlightedCenterBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-highlighted-disabled-center.png" size:CGSizeMake(1.0, 24.0)]),
        inactiveHighlightedDividerBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-highlighted-disabled-divider.png" size:CGSizeMake(1.0, 24.0)]),
        inactiveHighlightedLeftBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-highlighted-disabled-left.png" size:CGSizeMake(4.0, 24.0)]),
        inactiveHighlightedRightBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-highlighted-disabled-right.png" size:CGSizeMake(4.0, 24.0)]),
        leftBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-left.png" size:CGSizeMake(4.0, 24.0)]),
        rightBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-right.png" size:CGSizeMake(4.0, 24.0)]),
        pushedCenterBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-pushed-center.png" size:CGSizeMake(1.0, 24.0)]),
        pushedLeftBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-pushed-left.png" size:CGSizeMake(4.0, 24.0)]),
        pushedRightBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-pushed-right.png" size:CGSizeMake(4.0, 24.0)]);
        pushedHighlightedCenterBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-pushed-highlighted-center.png" size:CGSizeMake(1.0, 24.0)]),
        pushedHighlightedLeftBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-pushed-highlighted-left.png" size:CGSizeMake(4.0, 24.0)]),
        pushedHighlightedRightBezelColor = PatternColor([_CPCibCustomResource imageResourceWithName:@"HUD/segmented-control-bezel-pushed-highlighted-right.png" size:CGSizeMake(4.0, 24.0)]);

    [segmentedControl setValue:centerBezelColor forThemeAttribute:@"center-segment-bezel-color" inState:CPThemeStateNormal];
    [segmentedControl setValue:inactiveCenterBezelColor forThemeAttribute:@"center-segment-bezel-color" inState:CPThemeStateDisabled];
    [segmentedControl setValue:inactiveHighlightedCenterBezelColor forThemeAttribute:@"center-segment-bezel-color" inState:CPThemeStateSelected|CPThemeStateDisabled];
    [segmentedControl setValue:centerHighlightedBezelColor forThemeAttribute:@"center-segment-bezel-color" inState:CPThemeStateSelected];
    [segmentedControl setValue:pushedCenterBezelColor forThemeAttribute:@"center-segment-bezel-color" inState:CPThemeStateHighlighted];
    [segmentedControl setValue:pushedHighlightedCenterBezelColor forThemeAttribute:@"center-segment-bezel-color" inState:CPThemeStateHighlighted|CPThemeStateSelected];

    [segmentedControl setValue:dividerBezelColor forThemeAttribute:@"divider-bezel-color" inState:CPThemeStateNormal];
    [segmentedControl setValue:inactiveDividerBezelColor forThemeAttribute:@"divider-bezel-color" inState:CPThemeStateDisabled];
    [segmentedControl setValue:inactiveHighlightedDividerBezelColor forThemeAttribute:@"divider-bezel-color" inState:CPThemeStateSelected|CPThemeStateDisabled];
    [segmentedControl setValue:dividerHighlightedBezelColor forThemeAttribute:@"divider-bezel-color" inState:CPThemeStateSelected];
    [segmentedControl setValue:dividerBezelColor forThemeAttribute:@"divider-bezel-color" inState:CPThemeStateHighlighted];

    [segmentedControl setValue:rightBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateNormal];
    [segmentedControl setValue:inactiveRightBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateDisabled];
    [segmentedControl setValue:inactiveHighlightedRightBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateSelected|CPThemeStateDisabled];
    [segmentedControl setValue:rightHighlightedBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateSelected];
    [segmentedControl setValue:pushedRightBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateHighlighted];
    [segmentedControl setValue:pushedHighlightedRightBezelColor forThemeAttribute:@"right-segment-bezel-color" inState:CPThemeStateHighlighted|CPThemeStateSelected];

    [segmentedControl setValue:leftBezelColor forThemeAttribute:@"left-segment-bezel-color" inState:CPThemeStateNormal];
    [segmentedControl setValue:inactiveLeftBezelColor forThemeAttribute:@"left-segment-bezel-color" inState:CPThemeStateDisabled];
    [segmentedControl setValue:inactiveHighlightedLeftBezelColor forThemeAttribute:@"left-segment-bezel-color" inState:CPThemeStateSelected|CPThemeStateDisabled];
    [segmentedControl setValue:leftHighlightedBezelColor forThemeAttribute:@"left-segment-bezel-color" inState:CPThemeStateSelected];
    [segmentedControl setValue:pushedLeftBezelColor forThemeAttribute:@"left-segment-bezel-color" inState:CPThemeStateHighlighted];
    [segmentedControl setValue:pushedHighlightedLeftBezelColor forThemeAttribute:@"left-segment-bezel-color" inState:CPThemeStateHighlighted|CPThemeStateSelected];

    [segmentedControl setValue:CGInsetMake(0.0, 4.0, 0.0, 4.0) forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];

    [segmentedControl setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"bezel-inset" inState:CPThemeStateNormal];

    [segmentedControl setValue:[CPFont boldSystemFontOfSize:12.0] forThemeAttribute:@"font"];
    [segmentedControl setValue:[CPColor colorWithCalibratedWhite:255.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color"];
    [segmentedControl setValue:[CPColor colorWithCalibratedWhite:0.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color"];
    [segmentedControl setValue:CGSizeMake(-1.0, -1.0) forThemeAttribute:@"text-shadow-offset"];
    [segmentedControl setValue:CPLineBreakByTruncatingTail forThemeAttribute:@"line-break-mode"];

    [segmentedControl setValue:1.0 forThemeAttribute:@"divider-thickness"];
    [segmentedControl setValue:24.0 forThemeAttribute:@"default-height"];

    return segmentedControl;
}

+ (CPButton)button
{
    var button = [[CPButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 24.0)],

        bezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"HUD/button-bezel-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/button-bezel-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/button-bezel-right.png" size:CGSizeMake(4.0, 24.0)]
            ]
        isVertical:NO]],

        highlightedBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"HUD/button-bezel-highlighted-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/button-bezel-highlighted-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/button-bezel-highlighted-right.png" size:CGSizeMake(4.0, 24.0)]
            ]
        isVertical:NO]],

        defaultBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"HUD/default-button-bezel-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/default-button-bezel-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/default-button-bezel-right.png" size:CGSizeMake(4.0, 24.0)]
            ]
        isVertical:NO]],

        defaultHighlightedBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"HUD/default-button-bezel-highlighted-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/default-button-bezel-highlighted-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/default-button-bezel-highlighted-right.png" size:CGSizeMake(4.0, 24.0)]
            ]
        isVertical:NO]],

        defaultDisabledBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"HUD/default-button-bezel-disabled-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/default-button-bezel-disabled-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/default-button-bezel-disabled-right.png" size:CGSizeMake(4.0, 24.0)]
            ]
        isVertical:NO]],
        
        disabledBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"HUD/button-bezel-disabled-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/button-bezel-disabled-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/button-bezel-disabled-right.png" size:CGSizeMake(4.0, 24.0)]
            ]
        isVertical:NO]];

    [button setValue:[CPFont boldSystemFontOfSize:12.0] forThemeAttribute:@"font" inState:CPThemeStateBordered];

    [button setValue:[CPColor colorWithCalibratedWhite:255.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color"];
    [button setValue:[CPColor colorWithCalibratedWhite:0.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateBordered];
    [button setValue:[CPColor colorWithCalibratedWhite:0.0 / 255.0 alpha:0.6] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateBordered|CPThemeStateDisabled];
    [button setValue:CGSizeMake(-1.0,-1.0) forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateBordered];
    [button setValue:CPLineBreakByTruncatingTail forThemeAttribute:@"line-break-mode"];
    
    [button setValue:bezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
    [button setValue:highlightedBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateHighlighted];
    [button setValue:CGInsetMake(0.0, 5.0, 0.0, 5.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBordered];

    [button setValue:[CPColor colorWithCalibratedWhite:0.97 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [button setValue:disabledBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateDisabled];
    [button setValue:defaultDisabledBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateDefault|CPThemeStateDisabled];
    
    [button setValue:defaultBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateDefault];
    [button setValue:defaultHighlightedBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered|CPThemeStateHighlighted|CPThemeStateDefault];
    [button setValue:[CPColor colorWithCalibratedRed:250.0/255.0 green:250.0/255.0 blue:250.0/255.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateDefault];
    [button setValue:[CPColor colorWithCalibratedRed:250.0/255.0 green:250.0/255.0 blue:250.0/255.0 alpha:0.6] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled|CPThemeStateDefault];

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

+ (CPScroller)themedVerticalScroller
{
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 15.0, 170.0)],
        trackColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-vertical-track.png" size:CGSizeMake(15.0, 1.0)]),
        disabledTrackColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-vertical-track-disabled.png" size:CGSizeMake(15.0, 1.0)]);
        
    [scroller setValue:21.0 forThemeAttribute:@"minimum-knob-length" inState:CPThemeStateVertical];
    [scroller setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"knob-inset" inState:CPThemeStateVertical];
    [scroller setValue:CGInsetMake(-9.0, 0.0, -9.0, 0.0) forThemeAttribute:@"track-inset" inState:CPThemeStateVertical];

    [scroller setValue:trackColor forThemeAttribute:@"knob-slot-color" inState:CPThemeStateVertical];
    [scroller setValue:disabledTrackColor forThemeAttribute:@"knob-slot-color" inState:CPThemeStateVertical | CPThemeStateDisabled];

    var arrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-up-arrow.png" size:CGSizeMake(15.0, 24.0)]),
        highlightedArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-up-arrow-highlighted.png" size:CGSizeMake(15.0, 24.0)]),
        disabledArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-up-arrow-disabled.png" size:CGSizeMake(15.0, 24.0)]);

    [scroller setValue:CGSizeMake(15.0, 24.0) forThemeAttribute:@"decrement-line-size" inState:CPThemeStateVertical];
    [scroller setValue:arrowColor forThemeAttribute:@"decrement-line-color" inState:CPThemeStateVertical];
    [scroller setValue:highlightedArrowColor forThemeAttribute:@"decrement-line-color" inState:CPThemeStateVertical | CPThemeStateHighlighted],
    [scroller setValue:disabledArrowColor forThemeAttribute:@"decrement-line-color" inState:CPThemeStateVertical | CPThemeStateDisabled];

    var arrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-down-arrow.png" size:CGSizeMake(15.0, 24.0)]),
        highlightedArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-down-arrow-highlighted.png" size:CGSizeMake(15.0, 24.0)]),
        disabledArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-down-arrow-disabled.png" size:CGSizeMake(15.0, 24.0)]);

    [scroller setValue:CGSizeMake(15.0, 24.0) forThemeAttribute:@"increment-line-size" inState:CPThemeStateVertical];
    [scroller setValue:arrowColor forThemeAttribute:@"increment-line-color" inState:CPThemeStateVertical];
    [scroller setValue:highlightedArrowColor forThemeAttribute:@"increment-line-color" inState:CPThemeStateVertical | CPThemeStateHighlighted];
    [scroller setValue:disabledArrowColor forThemeAttribute:@"increment-line-color" inState:CPThemeStateVertical | CPThemeStateDisabled];
    
    var knobColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"HUD/scroller-vertical-knob-top.png" size:CGSizeMake(15.0, 10.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/scroller-vertical-knob-center.png" size:CGSizeMake(15.0, 1.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/scroller-vertical-knob-bottom.png" size:CGSizeMake(15.0, 10.0)]
            ]
        isVertical:YES]);

    /*var knobDisabledColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"HUD/scroller-vertical-knob-disabled-top.png" size:CGSizeMake(15.0, 10.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/scroller-vertical-knob-disabled-center.png" size:CGSizeMake(15.0, 1.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/scroller-vertical-knob-disabled-bottom.png" size:CGSizeMake(15.0, 10.0)]
            ]
        isVertical:YES]);*/
    
    [scroller setValue:knobColor forThemeAttribute:@"knob-color" inState:CPThemeStateVertical];
    //[scroller setValue:knobDisabledColor forThemeAttribute:@"knob-color" inState:CPThemeStateVertical|CPThemeStateDisabled];
    
    [scroller setFloatValue:0.1];
    [scroller setKnobProportion:0.5];

    return scroller;
}

+ (CPScroller)themedHorizontalScroller
{
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 170.0, 15.0)],
        trackColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-horizontal-track.png" size:CGSizeMake(1.0, 15.0)]),
        disabledTrackColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-horizontal-track-disabled.png" size:CGSizeMake(1.0, 15.0)]);

    [scroller setValue:21.0 forThemeAttribute:@"minimum-knob-length"];
    [scroller setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"knob-inset"];
    [scroller setValue:CGInsetMake(0.0, -7.0, 0.0, -9.0) forThemeAttribute:@"track-inset"];

    [scroller setValue:trackColor forThemeAttribute:@"knob-slot-color"];
    [scroller setValue:disabledTrackColor forThemeAttribute:@"knob-slot-color" inState:CPThemeStateDisabled];

    var arrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-left-arrow.png" size:CGSizeMake(24.0, 15.0)]),
        highlightedArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-left-arrow-highlighted.png" size:CGSizeMake(24.0, 15.0)]),
        disabledArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-left-arrow-disabled.png" size:CGSizeMake(24.0, 15.0)]);

    [scroller setValue:CGSizeMake(24.0, 15.0) forThemeAttribute:@"decrement-line-size"];
    [scroller setValue:arrowColor forThemeAttribute:@"decrement-line-color"];
    [scroller setValue:highlightedArrowColor forThemeAttribute:@"decrement-line-color" inState:CPThemeStateHighlighted],
    [scroller setValue:disabledArrowColor forThemeAttribute:@"decrement-line-color" inState:CPThemeStateDisabled];

    var arrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-right-arrow.png" size:CGSizeMake(24.0, 15.0)]),
        highlightedArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-right-arrow-highlighted.png" size:CGSizeMake(24.0, 15.0)]),
        disabledArrowColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/scroller-right-arrow-disabled.png" size:CGSizeMake(24.0, 15.0)]);

    [scroller setValue:CGSizeMake(24.0, 15.0) forThemeAttribute:@"increment-line-size"];
    [scroller setValue:arrowColor forThemeAttribute:@"increment-line-color"];
    [scroller setValue:highlightedArrowColor forThemeAttribute:@"increment-line-color" inState:CPThemeStateHighlighted];
    [scroller setValue:disabledArrowColor forThemeAttribute:@"increment-line-color" inState:CPThemeStateDisabled];
    
    var knobColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"HUD/scroller-horizontal-knob-left.png" size:CGSizeMake(10.0, 15.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/scroller-horizontal-knob-center.png" size:CGSizeMake(1.0, 15.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/scroller-horizontal-knob-right.png" size:CGSizeMake(10.0, 15.0)]
            ]
        isVertical:NO]);

    /*var knobDisabledColor = PatternColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"HUD/scroller-horizontal-knob-disabled-left.png" size:CGSizeMake(10.0, 15.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/scroller-horizontal-knob-disabled-center.png" size:CGSizeMake(1.0, 15.0)],
                [_CPCibCustomResource imageResourceWithName:"HUD/scroller-horizontal-knob-disabled-right.png" size:CGSizeMake(10.0, 15.0)]
            ]
        isVertical:NO]);*/

    [scroller setValue:knobColor forThemeAttribute:@"knob-color"];
    //[scroller setValue:knobDisabledColor forThemeAttribute:@"knob-color" inState:CPThemeStateDisabled];

    [scroller setFloatValue:0.1];
    [scroller setKnobProportion:0.5];

    return scroller;
}

+ (CPSlider)themedHorizontalSlider
{
    var slider = [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, 24.0)],
        trackColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [_CPCibCustomResource imageResourceWithName:"HUD/horizontal-track-left.png" size:CGSizeMake(4.0, 5.0)],
            [_CPCibCustomResource imageResourceWithName:"HUD/horizontal-track-center.png" size:CGSizeMake(1.0, 5.0)],
            [_CPCibCustomResource imageResourceWithName:"HUD/horizontal-track-right.png" size:CGSizeMake(4.0, 5.0)]
        ]
        isVertical:NO]],
        
        trackDisabledColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [_CPCibCustomResource imageResourceWithName:"HUD/horizontal-track-disabled-left.png" size:CGSizeMake(4.0, 5.0)],
            [_CPCibCustomResource imageResourceWithName:"HUD/horizontal-track-disabled-center.png" size:CGSizeMake(1.0, 5.0)],
            [_CPCibCustomResource imageResourceWithName:"HUD/horizontal-track-disabled-right.png" size:CGSizeMake(4.0, 5.0)]
        ]
        isVertical:NO]];

    [slider setValue:5.0 forThemeAttribute:@"track-width"];
    [slider setValue:trackColor forThemeAttribute:@"track-color"];
    [slider setValue:trackDisabledColor forThemeAttribute:@"track-color" inState:CPThemeStateDisabled];
    
        var knobColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"HUD/knob.png" size:CGSizeMake(23.0, 24.0)]],
            knobHighlightedColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"HUD/knob-highlighted.png" size:CGSizeMake(23.0, 24.0)]],
            knobDisabledColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"HUD/knob-disabled.png" size:CGSizeMake(23.0, 24.0)]];

    [slider setValue:CGSizeMake(23.0, 24.0) forThemeAttribute:@"knob-size"];
    [slider setValue:knobColor forThemeAttribute:@"knob-color"];
    [slider setValue:knobHighlightedColor forThemeAttribute:@"knob-color" inState:CPThemeStateHighlighted];
    [slider setValue:knobDisabledColor forThemeAttribute:@"knob-color" inState:CPThemeStateDisabled];
    
    return slider;
}

+ (CPSlider)themedVerticalSlider
{
    var slider = [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 24.0, 50.0)],
        trackColor =  [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [_CPCibCustomResource imageResourceWithName:"HUD/vertical-track-top.png" size:CGSizeMake(5.0, 6.0)],
            [_CPCibCustomResource imageResourceWithName:"HUD/vertical-track-center.png" size:CGSizeMake(5.0, 1.0)],
            [_CPCibCustomResource imageResourceWithName:"HUD/vertical-track-bottom.png" size:CGSizeMake(5.0, 4.0)]
        ]
        isVertical:YES]],
        trackDisabledColor =  [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [_CPCibCustomResource imageResourceWithName:"HUD/vertical-track-disabled-top.png" size:CGSizeMake(5.0, 6.0)],
            [_CPCibCustomResource imageResourceWithName:"HUD/vertical-track-disabled-center.png" size:CGSizeMake(5.0, 1.0)],
            [_CPCibCustomResource imageResourceWithName:"HUD/vertical-track-disabled-bottom.png" size:CGSizeMake(5.0, 4.0)]
        ]
        isVertical:YES]];
        
    [slider setValue:5.0 forThemeAttribute:@"track-width"];
    [slider setValue:trackColor forThemeAttribute:@"track-color" inState:CPThemeStateVertical];
    [slider setValue:trackDisabledColor forThemeAttribute:@"track-color" inState:CPThemeStateDisabled];
    
        var knobColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"HUD/knob.png" size:CGSizeMake(23.0, 24.0)]],
            knobHighlightedColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"HUD/knob-highlighted.png" size:CGSizeMake(23.0, 24.0)]],
            knobDisabledColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"HUD/knob-disabled.png" size:CGSizeMake(23.0, 24.0)]];

    [slider setValue:CGSizeMake(23.0, 24.0) forThemeAttribute:@"knob-size"];
    [slider setValue:knobColor forThemeAttribute:@"knob-color"];
    [slider setValue:knobHighlightedColor forThemeAttribute:@"knob-color" inState:CPThemeStateHighlighted];
    [slider setValue:knobDisabledColor forThemeAttribute:@"knob-color" inState:CPThemeStateDisabled];
    
    return slider;
}
+ (CPSlider)themedCircularSlider
{
    var slider = [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 34.0, 34.0)],
        trackColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/slider-circular-bezel.png" size:CGSizeMake(34.0, 34.0)]),
        trackDisabledColor = PatternColor([_CPCibCustomResource imageResourceWithName:"HUD/slider-circular-disabled-bezel.png" size:CGSizeMake(34.0, 34.0)]);

    [slider setSliderType:CPCircularSlider];
    [slider setValue:trackColor forThemeAttribute:@"track-color" inState:CPThemeStateCircular];
    [slider setValue:trackDisabledColor forThemeAttribute:@"track-color" inState:CPThemeStateDisabled|CPThemeStateCircular];

    var knobColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"HUD/slider-circular-knob.png" size:CGSizeMake(5.0, 5.0)]],
        knobDisabledColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"HUD/slider-circular-disabled-knob.png" size:CGSizeMake(5.0, 5.0)]],
        knobHighlightedColor = knobColor;

    [slider setValue:CGSizeMake(5.0, 5.0) forThemeAttribute:@"knob-size" inState:CPThemeStateCircular];
    [slider setValue:knobColor forThemeAttribute:@"knob-color" inState:CPThemeStateCircular];
    [slider setValue:knobDisabledColor forThemeAttribute:@"knob-color" inState:CPThemeStateDisabled|CPThemeStateCircular];
    [slider setValue:knobHighlightedColor forThemeAttribute:@"knob-color" inState:CPThemeStateCircular|CPThemeStateHighlighted];

    return slider;
}

@end

function PatternColor(anImage)
{
    return [CPColor colorWithPatternImage:anImage];
}