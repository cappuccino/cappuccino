/*
 * AppController.j
 * A
 *
 * Created by __Me__ on __Date__.
 * Copyright 2008 __MyCompanyName__. All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPThemedAttribute.j>

@implementation AristoThemeDescriptor : CPObject
{
}

+ (CPString)themeName
{
    return @"Aristo";
}

+ (CPScroller)themedVerticalScroller
{
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 17.0, 170.0)],
        trackColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-vertical-track.png" size:CGSizeMake(17.0, 1.0)]),
        disabledTrackColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-vertical-track-disabled.png" size:CGSizeMake(17.0, 1.0)]);
        
    [scroller setValue:CGSizeMake(15.0, 19.0) forThemedAttributeName:@"minimum-knob-size" inControlState:CPControlStateVertical];

    [scroller setValue:CGInsetMake(9.0, 9.0, 9.0, 9.0) forThemedAttributeName:@"track-overlap-inset" inControlState:CPControlStateVertical];
    [scroller setValue:trackColor forThemedAttributeName:@"knob-slot-color" inControlState:CPControlStateVertical];
    [scroller setValue:disabledTrackColor forThemedAttributeName:@"knob-slot-color" inControlState:CPControlStateVertical | CPControlStateDisabled];

    var arrowColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-up-arrow.png" size:CGSizeMake(17.0, 30.0)]),
        highlightedArrowColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-up-arrow-highlighted.png" size:CGSizeMake(17.0, 30.0)]),
        disabledArrowColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-up-arrow-disabled.png" size:CGSizeMake(17.0, 30.0)]);

    [scroller setValue:CGSizeMake(17.0, 30.0) forThemedAttributeName:@"decrement-line-size" inControlState:CPControlStateVertical];
    [scroller setValue:arrowColor forThemedAttributeName:@"decrement-line-color" inControlState:CPControlStateVertical];
    [scroller setValue:highlightedArrowColor forThemedAttributeName:@"decrement-line-color" inControlState:CPControlStateVertical | CPControlStateHighlighted],
    [scroller setValue:disabledArrowColor forThemedAttributeName:@"decrement-line-color" inControlState:CPControlStateVertical | CPControlStateDisabled];

    var arrowColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-down-arrow.png" size:CGSizeMake(17.0, 30.0)]),
        highlightedArrowColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-down-arrow-highlighted.png" size:CGSizeMake(17.0, 30.0)]),
        disabledArrowColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-down-arrow-disabled.png" size:CGSizeMake(17.0, 30.0)]);

    [scroller setValue:CGSizeMake(17.0, 30.0) forThemedAttributeName:@"increment-line-size"];
    [scroller setValue:arrowColor forThemedAttributeName:@"increment-line-color" inControlState:CPControlStateVertical];
    [scroller setValue:highlightedArrowColor forThemedAttributeName:@"increment-line-color" inControlState:CPControlStateVertical | CPControlStateHighlighted];
    [scroller setValue:disabledArrowColor forThemedAttributeName:@"increment-line-color" inControlState:CPControlStateVertical | CPControlStateDisabled];
    
    var knobColor = PatterColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"scroller-vertical-knob-top.png" size:CGSizeMake(15.0, 8.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-vertical-knob-center.png" size:CGSizeMake(15.0, 1.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-vertical-knob-bottom.png" size:CGSizeMake(15.0, 10.0)]
            ]
        isVertical:YES]);
    
    [scroller setValue:knobColor forThemedAttributeName:@"knob-color" inControlState:CPControlStateVertical];
    
    [scroller setFloatValue:0.1 knobProportion:0.5];

    return scroller;
}

+ (CPScroller)themedHorizontalScroller
{CPControlStateHorizontal = 0;
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 170.0, 17.0)],
        trackColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-horizontal-track.png" size:CGSizeMake(1.0, 17.0)]),
        disabledTrackColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-vertical-track-disabled.png" size:CGSizeMake(17.0, 1.0)]);
    [scroller setBackgroundColor:[CPColor blueColor]];
    [scroller setValue:CGSizeMake(19.0, 15.0) forThemedAttributeName:@"minimum-knob-size" inControlState:CPControlStateHorizontal];

    [scroller setValue:CGInsetMake(9.0, 9.0, 9.0, 9.0) forThemedAttributeName:@"track-overlap-inset" inControlState:CPControlStateHorizontal];
    [scroller setValue:trackColor forThemedAttributeName:@"knob-slot-color" inControlState:CPControlStateHorizontal];
    [scroller setValue:disabledTrackColor forThemedAttributeName:@"knob-slot-color" inControlState:CPControlStateHorizontal | CPControlStateDisabled];

    var arrowColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-left-arrow.png" size:CGSizeMake(32.0, 17.0)]),
        highlightedArrowColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-up-arrow-highlighted.png" size:CGSizeMake(17.0, 30.0)]),
        disabledArrowColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-up-arrow-disabled.png" size:CGSizeMake(17.0, 30.0)]);

    [scroller setValue:CGSizeMake(32.0, 17.0) forThemedAttributeName:@"decrement-line-size" inControlState:CPControlStateHorizontal];
    [scroller setValue:arrowColor forThemedAttributeName:@"decrement-line-color" inControlState:CPControlStateHorizontal];
    [scroller setValue:highlightedArrowColor forThemedAttributeName:@"decrement-line-color" inControlState:CPControlStateHorizontal | CPControlStateHighlighted],
    [scroller setValue:disabledArrowColor forThemedAttributeName:@"decrement-line-color" inControlState:CPControlStateHorizontal | CPControlStateDisabled];

    var arrowColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-right-arrow.png" size:CGSizeMake(31.0, 17.0)]),
        highlightedArrowColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-down-arrow-highlighted.png" size:CGSizeMake(17.0, 30.0)]),
        disabledArrowColor = PatterColor([_CPCibCustomResource imageResourceWithName:"scroller-down-arrow-disabled.png" size:CGSizeMake(17.0, 30.0)]);

    [scroller setValue:CGSizeMake(31.0, 17.0) forThemedAttributeName:@"increment-line-size"];
    [scroller setValue:arrowColor forThemedAttributeName:@"increment-line-color" inControlState:CPControlStateHorizontal];
    [scroller setValue:highlightedArrowColor forThemedAttributeName:@"increment-line-color" inControlState:CPControlStateHorizontal | CPControlStateHighlighted];
    [scroller setValue:disabledArrowColor forThemedAttributeName:@"increment-line-color" inControlState:CPControlStateHorizontal | CPControlStateDisabled];
    
    var knobColor = PatterColor([[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"scroller-horizontal-knob-left.png" size:CGSizeMake(11.0, 15.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-horizontal-knob-center.png" size:CGSizeMake(1.0, 15.0)],
                [_CPCibCustomResource imageResourceWithName:"scroller-horizontal-knob-right.png" size:CGSizeMake(9.0, 15.0)]
            ]
        isVertical:NO]);
    
    [scroller setValue:knobColor forThemedAttributeName:@"knob-color" inControlState:CPControlStateHorizontal];
    
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

    [textfield setValue:bezelColor forThemedAttributeName:@"bezel-color" inControlState:CPControlStateBezeled];
    [textfield setValue:bezelFocusedColor forThemedAttributeName:@"bezel-color" inControlState:CPControlStateBezeled|CPControlStateEditing];

    [textfield setValue:[CPFont systemFontOfSize:12.0] forThemedAttributeName:@"font"];

    [textfield setValue:CGInsetMake(9.0, 8.0, 5.0, 7.0) forThemedAttributeName:@"content-inset" inControlState:CPControlStateBezeled];

    [textfield setValue:CGInsetMake(4.0, 4.0, 3.0, 4.0) forThemedAttributeName:@"bezel-inset" inControlState:CPControlStateBezeled];
    [textfield setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemedAttributeName:@"bezel-inset" inControlState:CPControlStateBezeled|CPControlStateEditing];

    [textfield setValue:[CPColor colorWithCalibratedRed:189.0 / 255.0 green:199.0 / 255.0 blue:211.0 / 255.0 alpha:1.0] forThemedAttributeName:@"text-color" inControlState:CPTextFieldStatePlaceholder];

    [textfield setPlaceholderString:"cheese cheese"];
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

    [textfield setValue:bezelColor forThemedAttributeName:@"bezel-color" inControlState:CPControlStateBezeled | CPTextFieldStateRounded];
    [textfield setValue:bezelFocusedColor forThemedAttributeName:@"bezel-color" inControlState:CPControlStateBezeled | CPTextFieldStateRounded | CPControlStateEditing];

    [textfield setValue:[CPFont systemFontOfSize:12.0] forThemedAttributeName:@"font"];
    [textfield setValue:CGInsetMake(9.0, 14.0, 6.0, 14.0) forThemedAttributeName:@"content-inset" inControlState:CPControlStateBezeled | CPTextFieldStateRounded];

    [textfield setValue:CGInsetMake(4.0, 4.0, 4.0, 4.0) forThemedAttributeName:@"bezel-inset" inControlState:CPControlStateBezeled|CPTextFieldStateRounded];
    [textfield setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemedAttributeName:@"bezel-inset" inControlState:CPControlStateBezeled|CPTextFieldStateRounded|CPControlStateEditing];

    [textfield setValue:[CPColor colorWithCalibratedRed:189.0 / 255.0 green:199.0 / 255.0 blue:211.0 / 255.0 alpha:1.0] forThemedAttributeName:@"text-color" inControlState:CPTextFieldStatePlaceholder];

    [textfield setPlaceholderString:"cheese cheese"];
    [textfield setStringValue:""];
    [textfield setEditable:YES];

    return textfield;
}

+ (CPButton)themedButton
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

                
    [button setTitle:@"Cancel"];
    
    [button setValue:[CPFont boldSystemFontOfSize:12.0] forThemedAttributeName:@"font" inControlState:CPControlStateBordered];
    [button setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemedAttributeName:@"text-color"];
    [button setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0] forThemedAttributeName:@"text-shadow-color" inControlState:CPControlStateBordered];
    [button setValue:CGSizeMake(0.0, 1.0) forThemedAttributeName:@"text-shadow-offset" inControlState:CPControlStateBordered];
    [button setValue:CPLineBreakByTruncatingTail forThemedAttributeName:@"line-break-mode"];
    
    [button setValue:bezelColor forThemedAttributeName:@"bezel-color" inControlState:CPControlStateBordered];
    [button setValue:highlightedBezelColor forThemedAttributeName:@"bezel-color" inControlState:CPControlStateBordered|CPControlStateHighlighted];
    [button setValue:CGInsetMake(0.0, 5.0, 0.0, 5.0) forThemedAttributeName:@"content-inset" inControlState:CPControlStateBordered];

    [button setValue:defaultBezelColor forThemedAttributeName:@"bezel-color" inControlState:CPControlStateBordered|CPControlStateDefault];
    [button setValue:defaultHighlightedBezelColor forThemedAttributeName:@"bezel-color" inControlState:CPControlStateBordered|CPControlStateHighlighted|CPControlStateDefault];
    [button setValue:[CPColor colorWithCalibratedRed:13.0/255.0 green:51.0/255.0 blue:70.0/255.0 alpha:1.0] forThemedAttributeName:@"text-color" inControlState:CPControlStateDefault];

    [button setValue:24.0 forThemedAttributeName:@"default-height"];

    return button;
}

+ (CPPopUpButton)themedPopUpButton
{
    var button = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 24.0) pullsDown:NO],color = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [_CPCibCustomResource imageResourceWithName:"button-bezel-left.png" size:CGSizeMake(4.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"button-bezel-center.png" size:CGSizeMake(1.0, 24.0)],
                [_CPCibCustomResource imageResourceWithName:"popup-bezel-right.png" size:CGSizeMake(27.0, 24.0)]
            ]
        isVertical:NO]];
    
    [button setTitle:@"Pop Up"];
    
    [button setValue:color forThemedAttributeName:@"bezel-color" inControlState:CPControlStateBordered];
    [button setValue:CGInsetMake(0, 5, 0, 27.0 + 5.0) forThemedAttributeName:@"content-inset" inControlState:CPControlStateBordered];
    [button setValue:[CPFont boldSystemFontOfSize:12.0] forThemedAttributeName:@"font"];
    [button setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemedAttributeName:@"text-color"];
    [button setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0] forThemedAttributeName:@"text-shadow-color"];
    [button setValue:CGSizeMake(0.0, 1.0) forThemedAttributeName:@"text-shadow-offset"];

    [button addItemWithTitle:@"item"];
    
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
    var centerBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-center.png" size:CGSizeMake(1.0, 24.0)]],
        dividerBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-divider.png" size:CGSizeMake(1.0, 24.0)]],
        centerHighlightedBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-center.png" size:CGSizeMake(1.0, 24.0)]],
        dividerHighlightedBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-divider.png" size:CGSizeMake(1.0, 24.0)]],
        leftHighlightedBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-left.png" size:CGSizeMake(4.0, 24.0)]],
        rightHighlightedBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-highlighted-right.png" size:CGSizeMake(4.0, 24.0)]],
        inactiveCenterBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-inactive-center.png" size:CGSizeMake(1.0, 24.0)]],
        inactiveDividerBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-inactive-divider.png" size:CGSizeMake(1.0, 24.0)]],
        inactiveLeftBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-inactive-left.png" size:CGSizeMake(4.0, 24.0)]],
        inactiveRightBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-inactive-right.png" size:CGSizeMake(4.0, 24.0)]],
        leftBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-left.png" size:CGSizeMake(4.0, 24.0)]],
        rightBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-right.png" size:CGSizeMake(4.0, 24.0)]],
        pushedCenterBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-pushed-center.png" size:CGSizeMake(1.0, 24.0)]],
        pushedLeftBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-pushed-left.png" size:CGSizeMake(4.0, 24.0)]],
        pushedRightBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-pushed-right.png" size:CGSizeMake(4.0, 24.0)]];
        pushedHighlightedCenterBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-pushed-highlighted-center.png" size:CGSizeMake(1.0, 24.0)]],
        pushedHighlightedLeftBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-pushed-highlighted-left.png" size:CGSizeMake(4.0, 24.0)]],
        pushedHighlightedRightBezelColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:@"segmented-control-bezel-pushed-highlighted-right.png" size:CGSizeMake(4.0, 24.0)]];

    [segmentedControl setValue:centerBezelColor forThemedAttributeName:@"center-segment-bezel-color" inControlState:CPControlStateNormal];
    [segmentedControl setValue:inactiveCenterBezelColor forThemedAttributeName:@"center-segment-bezel-color" inControlState:CPControlStateDisabled];
    [segmentedControl setValue:centerHighlightedBezelColor forThemedAttributeName:@"center-segment-bezel-color" inControlState:CPControlStateSelected];
    [segmentedControl setValue:pushedCenterBezelColor forThemedAttributeName:@"center-segment-bezel-color" inControlState:CPControlStateHighlighted];
    [segmentedControl setValue:pushedHighlightedCenterBezelColor forThemedAttributeName:@"center-segment-bezel-color" inControlState:CPControlStateHighlighted|CPControlStateSelected];

    [segmentedControl setValue:dividerBezelColor forThemedAttributeName:@"divider-bezel-color" inControlState:CPControlStateNormal];
    [segmentedControl setValue:inactiveDividerBezelColor forThemedAttributeName:@"divider-bezel-color" inControlState:CPControlStateDisabled];
    [segmentedControl setValue:dividerHighlightedBezelColor forThemedAttributeName:@"divider-bezel-color" inControlState:CPControlStateSelected];
    [segmentedControl setValue:dividerBezelColor forThemedAttributeName:@"divider-bezel-color" inControlState:CPControlStateHighlighted];

    [segmentedControl setValue:rightBezelColor forThemedAttributeName:@"right-segment-bezel-color" inControlState:CPControlStateNormal];
    [segmentedControl setValue:inactiveRightBezelColor forThemedAttributeName:@"right-segment-bezel-color" inControlState:CPControlStateDisabled];
    [segmentedControl setValue:rightHighlightedBezelColor forThemedAttributeName:@"right-segment-bezel-color" inControlState:CPControlStateSelected];
    [segmentedControl setValue:pushedRightBezelColor forThemedAttributeName:@"right-segment-bezel-color" inControlState:CPControlStateHighlighted];
    [segmentedControl setValue:pushedHighlightedRightBezelColor forThemedAttributeName:@"right-segment-bezel-color" inControlState:CPControlStateHighlighted|CPControlStateSelected];

    [segmentedControl setValue:leftBezelColor forThemedAttributeName:@"left-segment-bezel-color" inControlState:CPControlStateNormal];
    [segmentedControl setValue:inactiveLeftBezelColor forThemedAttributeName:@"left-segment-bezel-color" inControlState:CPControlStateDisabled];
    [segmentedControl setValue:leftHighlightedBezelColor forThemedAttributeName:@"left-segment-bezel-color" inControlState:CPControlStateSelected];
    [segmentedControl setValue:pushedLeftBezelColor forThemedAttributeName:@"left-segment-bezel-color" inControlState:CPControlStateHighlighted];
    [segmentedControl setValue:pushedHighlightedLeftBezelColor forThemedAttributeName:@"left-segment-bezel-color" inControlState:CPControlStateHighlighted|CPControlStateSelected];

    [segmentedControl setValue:CGInsetMake(0.0, 4.0, 0.0, 4.0) forThemedAttributeName:@"content-inset" inControlState:CPControlStateNormal];

    [segmentedControl setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemedAttributeName:@"bezel-inset" inControlState:CPControlStateNormal];

    [segmentedControl setValue:[CPFont boldSystemFontOfSize:12.0] forThemedAttributeName:@"font"];
    [segmentedControl setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemedAttributeName:@"text-color"];
    [segmentedControl setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0] forThemedAttributeName:@"text-shadow-color"];

    [segmentedControl setValue:1.0 forThemedAttributeName:@"divider-thickness"];
    [segmentedControl setValue:24.0 forThemedAttributeName:@"default-height"];
    
    return segmentedControl;
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
    
    [button setTitle:@"Pop Up"];

    [button setValue:color forThemedAttributeName:@"bezel-color" inControlState:CPPopUpButtonStatePullsDown|CPControlStateBordered];
    [button setValue:CGInsetMake(0, 5, 0, 27.0 + 5.0) forThemedAttributeName:@"content-inset" inControlState:CPControlStateBordered];
    [button setValue:[CPFont boldSystemFontOfSize:12.0] forThemedAttributeName:@"font"];
    [button setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemedAttributeName:@"text-color"];
    [button setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0] forThemedAttributeName:@"text-shadow-color"];
    [button setValue:CGSizeMake(0.0, 1.0) forThemedAttributeName:@"text-shadow-offset"];
    
    [button addItemWithTitle:@"item"];

    return button;
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

    [slider setValue:5.0 forThemedAttributeName:@"track-width"];
    [slider setValue:trackColor forThemedAttributeName:@"track-color"];
    
        var knobColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob.png" size:CGSizeMake(23.0, 24.0)]];
        knobHighlightedColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob-highlighted.png" size:CGSizeMake(23.0, 24.0)]];

    [slider setValue:CGSizeMake(23.0, 24.0) forThemedAttributeName:@"knob-size"];
    [slider setValue:knobColor forThemedAttributeName:@"knob-color"];
    [slider setValue:knobHighlightedColor forThemedAttributeName:@"knob-color" inControlState:CPControlStateHighlighted];
    
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
        
    [slider setValue:5.0 forThemedAttributeName:@"track-width"];
    [slider setValue:trackColor forThemedAttributeName:@"track-color" inControlState:CPControlStateVertical];
    
        var knobColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob.png" size:CGSizeMake(23.0, 24.0)]];
        knobHighlightedColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob-highlighted.png" size:CGSizeMake(23.0, 24.0)]];
    
    [slider setValue:CGSizeMake(23.0, 24.0) forThemedAttributeName:@"knob-size"];
    [slider setValue:knobColor forThemedAttributeName:@"knob-color"];
    [slider setValue:knobHighlightedColor forThemedAttributeName:@"knob-color" inControlState:CPControlStateHighlighted];
    
    return slider;
}

+ (CPSlider)themedCircularSlider
{
    var slider = [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 32.0, 32.0)],
        trackColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"circularSliderBezel.png" size:CGSizeMake(32.0, 32.0)]];

    [slider setSliderType:CPCircularSlider];
    [slider setValue:trackColor forThemedAttributeName:@"track-color" inControlState:CPControlStateCircular];
    [slider setValue:trackColor forThemedAttributeName:@"track-color" inControlState:CPControlStateCircular|CPControlStateVertical];

    var knobColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"circularSliderKnob.png" size:CGSizeMake(5.0, 5.0)]],
        knobHighlightedColor = knobColor;

    [slider setValue:CGSizeMake(5.0, 5.0) forThemedAttributeName:@"knob-size" inControlState:CPControlStateCircular];
    [slider setValue:knobColor forThemedAttributeName:@"knob-color" inControlState:CPControlStateCircular];
    [slider setValue:knobHighlightedColor forThemedAttributeName:@"knob-color" inControlState:CPControlStateCircular|CPControlStateHighlighted];

    return slider;
}

/*
    var buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 30.0)],
        color = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [_CPCibCustomResource imageResourceWithName:"buttonbar-bezel.png" size:CGSizeMake(1.0, 30.0)],
            [_CPCibCustomResource imageResourceWithName:"buttonbar-bezel.png" size:CGSizeMake(1.0, 30.0)],
            [_CPCibCustomResource imageResourceWithName:"buttonbar-bezel-right.png" size:CGSizeMake(13.0, 30.0)]
        ]
        isVertical:NO]];

    [buttonBar setValue:color forThemedAttributeName:@"bezel-color"];
    [buttonBar setNeedsLayout];
    
    views.push(buttonBar);
    
    return views;
*/
@end

function PatterColor(anImage)
{
    return [CPColor colorWithPatternImage:anImage];
}
