/*
 * AppController.j
 *
 * Created by __Me__ on __Date__.
 * Copyright 2008 __MyCompanyName__. All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/_CPCibCustomResource.j>


@implementation AppController : CPObject
{
}

- (CPArray)themeNames
{
    return ["Default"];
}

- (void)viewsForDefaultTheme
{
    var views = [],
        bundle = [CPBundle mainBundle];

    // Horizontal Slider

    var horizontalTrackColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [_CPCibCustomResource imageResourceWithName:"horizontal-track-left.png" size:CGSizeMake(2.0, 4.0)],
            [_CPCibCustomResource imageResourceWithName:"horizontal-track-center.png" size:CGSizeMake(1.0, 4.0)],
            [_CPCibCustomResource imageResourceWithName:"horizontal-track-right.png" size:CGSizeMake(2.0, 4.0)]
        ]
        isVertical:NO]],
        horizontalSlider = [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, 24.0)];

    [horizontalSlider setTrackWidth:4.0];
    [horizontalSlider setHorizontalTrackColor:horizontalTrackColor];

    var knobColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob.png" size:CGSizeMake(11.0, 11.0)]],
        knobHighlightedColor = [CPColor colorWithPatternImage:[_CPCibCustomResource imageResourceWithName:"knob-highlighted.png" size:CGSizeMake(12.0, 12.0)]];

    [horizontalSlider setKnobSize:CGSizeMake(12.0, 12.0)];
    [horizontalSlider setKnobColor:knobColor];
    [horizontalSlider setKnobColor:knobHighlightedColor forControlState:CPControlStateHighlighted];

    views.push(horizontalSlider);

    // Vertical Slider

    var verticalTrackColor =  [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [_CPCibCustomResource imageResourceWithName:"vertical-track-top.png" size:CGSizeMake(4.0, 2.0)],
            [_CPCibCustomResource imageResourceWithName:"vertical-track-center.png" size:CGSizeMake(4.0, 1.0)],
            [_CPCibCustomResource imageResourceWithName:"vertical-track-bottom.png" size:CGSizeMake(4.0, 2.0)]
        ]
        isVertical:YES]],
        verticalSlider = [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 24.0, 50.0)];

    [verticalSlider setTrackWidth:4];
    [verticalSlider setVerticalTrackColor:verticalTrackColor];

    [verticalSlider setKnobSize:CGSizeMake(12.0, 12.0)];
    [verticalSlider setKnobColor:knobColor];
    [verticalSlider setKnobColor:knobHighlightedColor forControlState:CPControlStateHighlighted];

    views.push(verticalSlider);

    return views;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        bounds = [contentView bounds],
        themeNames = [self themeNames],
        index = 0,
        count = themeNames.length;

    var tabView = [[CPTabView alloc] initWithFrame:bounds];

    [tabView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    [contentView addSubview:tabView];

    for (; index < count; ++index)
    {
        var item = [[CPTabViewItem alloc] initWithIdentifier:themeNames[index]],
            selectorName = "viewsFor" + themeNames[index] + "Theme",
            views = [self performSelector:selectorName],
            viewsCount = [views count],
            itemSize = CGSizeMake(0.0, 0.0);

        while (viewsCount--)
        {
            var size = [views[viewsCount] frame].size;

            if (size.width > itemSize.width)
                itemSize.width = size.width;

            if (size.height > itemSize.height)
                itemSize.height = size.height;
        }

        itemSize.height += 30;
        itemSize.width += 40;

        var collectionView = [[CPCollectionView alloc] initWithFrame:CGRectMakeZero()],
            collectionViewItem = [[CPCollectionViewItem alloc] init];

        [collectionViewItem setView:[[ThemedView alloc] init]];

        [collectionView setItemPrototype:collectionViewItem];
        [collectionView setMinItemSize:itemSize];
        [collectionView setMaxItemSize:itemSize];
        [collectionView setVerticalMargin:5.0];
        [collectionView setContent:views];

        [item setLabel:themeNames[index]];
        [item setView:collectionView];

        [tabView addTabViewItem:item];
    }

    [theWindow orderFront:self];
}

@end

@implementation ThemedView : CPView
{
    CPView      _view;
    CPTextField _label;
}

- (void)setRepresentedObject:(id)anObject
{
    if (!_label)
    {
        _label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

        [_label setAlignment:CPCenterTextAlignment];
        [_label setAutoresizingMask:CPViewMinYMargin | CPViewWidthSizable];
        [_label setFont:[CPFont boldSystemFontOfSize:0]];

        [self addSubview:_label];
    }

    [_label setStringValue:[anObject className]];
    [_label sizeToFit];

    [_label setFrame:CGRectMake(0.0, CGRectGetHeight([self bounds]) - CGRectGetHeight([_label frame]),
        CGRectGetWidth([self bounds]), CGRectGetHeight([_label frame]))];

    if (_view)
        [_view removeFromSuperview];

    _view = anObject;

    [_view setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [_view setFrameOrigin:CGPointMake((CGRectGetWidth([self bounds]) - CGRectGetWidth([_view frame])) / 2.0, (CGRectGetMinY([_label frame]) - CGRectGetHeight([_view frame])) / 2.0)];

    [self addSubview:_view];
}

@end
