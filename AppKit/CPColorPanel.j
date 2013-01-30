/*
 * CPColorPanel.j
 * AppKit
 *
 * Created by Ross Boucher.
 * Copyright 2008, 280 North, Inc.
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

@import "CPButton.j"
@import "CPCookie.j"
@import "CPPanel.j"
@import "CPPasteboard.j"
@import "CPView.j"

@class CPSlider

@global CPApp

/*
    A color wheel
    @global
    @group CPColorPanelMode
*/
CPWheelColorPickerMode = 1;

/*
    Slider based picker
    @global
    @group CPColorPanelMode
*/
CPSliderColorPickerMode = 2;

CPColorPickerViewWidth  = 265;
CPColorPickerViewHeight = 370;

CPColorPanelColorDidChangeNotification = @"CPColorPanelColorDidChangeNotification";

var PREVIEW_HEIGHT = 20.0,
    TOOLBAR_HEIGHT = 32.0,
    SWATCH_HEIGHT  = 14.0,
    ICON_WIDTH     = 32.0,
    ICON_PADDING   = 12.0;

var SharedColorPanel = nil,
    ColorPickerClasses = [];

/*!
    @ingroup appkit
    @class CPColorPanel

    CPColorPanel provides a reusable panel that can be used
    displayed on screen to prompt the user for a color selection. To
    obtain the panel, call the \c +sharedColorPanel method.
*/
@implementation CPColorPanel : CPPanel
{
    _CPColorPanelToolbar    _toolbar;
    _CPColorPanelSwatches   _swatchView;
    _CPColorPanelPreview    _previewView;

    CPSlider        _opacitySlider;

    CPArray         _colorPickers;
    CPView          _currentView;
    id              _activePicker;

    CPColor         _color;

    id              _target;
    SEL             _action;

    int             _mode;
}

/*!
    A list of color pickers is collected here, and any color panel created will contain
    any picker in this list up to this point. In other words, call before creating a color panel.
*/
+ (void)provideColorPickerClass:(Class)aColorPickerSubclass
{
    ColorPickerClasses.push(aColorPickerSubclass);
}

/*!
    Returns (and if necessary, creates) the shared color panel.
*/
+ (CPColorPanel)sharedColorPanel
{
    if (!SharedColorPanel)
        SharedColorPanel = [[CPColorPanel alloc] init];

    return SharedColorPanel;
}

/*!
    Sets the mode for the shared color panel.
    @param mode the mode to which the color panel will be set
*/
+ (void)setPickerMode:(CPColorPanelMode)mode
{
    var panel = [CPColorPanel sharedColorPanel];
    [panel setMode:mode];
}

/*
    To obtain the color panel, use \c +sharedColorPanel.
    @ignore
*/
- (id)init
{
    self = [super initWithContentRect:CGRectMake(500.0, 50.0, 219.0, 370.0)
                            styleMask:(CPTitledWindowMask | CPClosableWindowMask | CPResizableWindowMask)];

    if (self)
    {
        //[[self contentView] setBackgroundColor:[CPColor colorWithWhite:0.95 alpha:1.0]];

        [self setTitle:@"Color Panel"];
        [self setLevel:CPFloatingWindowLevel];

        [self setFloatingPanel:YES];
        [self setBecomesKeyOnlyIfNeeded:YES];

        [self setMinSize:CGSizeMake(219.0, 363.0)];
        [self setMaxSize:CGSizeMake(323.0, 537.0)];
    }

    return self;
}

/*!
    Sets the color of the panel, and updates the picker. Also posts a \c CPColorPanelDidChangeNotification.
*/
- (void)setColor:(CPColor)aColor
{
    _color = aColor;
    [_previewView setBackgroundColor:_color];

    [CPApp sendAction:@selector(changeColor:) to:nil from:self];

    if (_target && _action)
        [CPApp sendAction:_action to:_target from:self];

    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPColorPanelColorDidChangeNotification
                      object:self];

    [_activePicker setColor:_color];
    [_opacitySlider setFloatValue:[_color alphaComponent]];
}

/*!
    Sets the selected color of the panel and optionally updates the picker.
    @param bool whether or not to update the picker
    @ignore
*/
- (void)setColor:(CPColor)aColor updatePicker:(BOOL)bool
{
    [self setColor:aColor];

    if (bool)
        [_activePicker setColor:_color];
}

/*!
    Returns the panel's currently selected color.
*/
- (CPColor)color
{
    return _color;
}

- (float)opacity
{
    return [_opacitySlider floatValue];
}

/*!
    Sets the target for the color panel. Messages are sent
    to the target when colors are selected in the panel.
*/
- (void)setTarget:(id)aTarget
{
    _target = aTarget;
}

/*!
    Returns the current target. The target receives messages
    when colors are selected in the panel.
*/
- (id)target
{
    return _target;
}

/*!
    Sets the action that gets sent to the target.
    This action is sent whenever a color is selected in the panel.
    @param anAction the action that will be sent
*/
- (void)setAction:(selector)anAction
{
    _action = anAction;
}

/*!
    Returns the current target action.
*/
- (selector)action
{
    return _action;
}

/*!
    Sets the mode (look) of the color panel.
    @param mode the mode in which to display the color panel
*/
- (void)setMode:(CPColorPanelMode)mode
{
    _mode = mode;
}

- (void)_setPicker:(id)sender
{
    var picker = _colorPickers[[sender tag]],
        view = [picker provideNewView:NO];

    if (!view)
        view = [picker provideNewView:YES];

    if (view == _currentView)
        return;

    if (_currentView)
        [view setFrame:[_currentView frame]];
    else
    {
        var height = (TOOLBAR_HEIGHT + 10 + PREVIEW_HEIGHT + 5 + SWATCH_HEIGHT + 32),
            bounds = [[self contentView] bounds];

        [view setFrameSize:CGSizeMake(bounds.size.width - 10, bounds.size.height - height)];
        [view setFrameOrigin:CGPointMake(5, height)];
    }

    [_currentView removeFromSuperview];
    [[self contentView] addSubview:view];

    _currentView = view;
    _activePicker = picker;

    [picker setColor:[self color]];
}

/*!
    Returns the color panel's current display mode.
*/
- (CPColorPanelMode)mode
{
    return _mode;
}

- (void)orderFront:(id)aSender
{
    [self _loadContentsIfNecessary];
    [super orderFront:aSender];
}

/* @ignore */
- (void)_loadContentsIfNecessary
{
    if (_toolbar)
        return;

    if (!_color)
        _color = [CPColor whiteColor];

    _colorPickers = [];

    var count = [ColorPickerClasses count];
    for (var i = 0; i < count; i++)
    {
        var currentPickerClass = ColorPickerClasses[i],
            currentPicker = [[currentPickerClass alloc] initWithPickerMask:0 colorPanel:self];

        _colorPickers.push(currentPicker);
    }

    var contentView = [self contentView],
        bounds = [contentView bounds];

    _toolbar = [[CPView alloc] initWithFrame:CGRectMake(0, 6, CGRectGetWidth(bounds), TOOLBAR_HEIGHT)];
    [_toolbar setAutoresizingMask:CPViewWidthSizable];

    var totalToolbarWidth = count * ICON_WIDTH + (count - 1) * ICON_PADDING,
        leftOffset = (CGRectGetWidth(bounds) - totalToolbarWidth) / 2.0,
        buttonForLater = nil;

    for (var i = 0; i < count; i++)
    {
        var image = [_colorPickers[i] provideNewButtonImage],
            highlightImage = [_colorPickers[i] provideNewAlternateButtonImage],
            button = [[CPButton alloc] initWithFrame:CGRectMake(leftOffset + i * (ICON_WIDTH + ICON_PADDING), 0, ICON_WIDTH, ICON_WIDTH)];

        [button setTag:i];
        [button setTarget:self];
        [button setAction:@selector(_setPicker:)];
        [button setBordered:NO];
        [button setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin];

        [button setImage:image];
        [button setAlternateImage:highlightImage];

        [_toolbar addSubview:button];

        if (!buttonForLater)
            buttonForLater = button;
    }

    // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/25-implement-cpbox
    var previewBox = [[CPView alloc] initWithFrame:CGRectMake(76, TOOLBAR_HEIGHT + 10, CGRectGetWidth(bounds) - 86, PREVIEW_HEIGHT)];

    _previewView = [[_CPColorPanelPreview alloc] initWithFrame:CGRectInset([previewBox bounds], 2.0, 2.0)];

    [_previewView setColorPanel:self];
    [_previewView setAutoresizingMask:CPViewWidthSizable];

    [previewBox setBackgroundColor:[CPColor colorWithWhite:0.8 alpha:1.0]];
    [previewBox setAutoresizingMask:CPViewWidthSizable];

    [previewBox addSubview:_previewView];

    var _previewLabel = [[CPTextField alloc] initWithFrame:CGRectMake(10, TOOLBAR_HEIGHT + 10, 60, 15)];
    [_previewLabel setStringValue:"Preview:"];
    [_previewLabel setTextColor:[CPColor blackColor]];
    [_previewLabel setAlignment:CPRightTextAlignment];

    // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/25-implement-cpbox
    var swatchBox = [[CPView alloc] initWithFrame:CGRectMake(76, TOOLBAR_HEIGHT + 10 + PREVIEW_HEIGHT + 5, CGRectGetWidth(bounds) - 86, SWATCH_HEIGHT + 2.0)];

    [swatchBox setBackgroundColor:[CPColor colorWithWhite:0.8 alpha:1.0]];
    [swatchBox setAutoresizingMask:CPViewWidthSizable];

    _swatchView = [[_CPColorPanelSwatches alloc] initWithFrame:CGRectInset([swatchBox bounds], 1.0, 1.0)];

    [_swatchView setColorPanel:self];
    [_swatchView setAutoresizingMask:CPViewWidthSizable];

    [swatchBox addSubview:_swatchView];

    var _swatchLabel = [[CPTextField alloc] initWithFrame:CGRectMake(10, TOOLBAR_HEIGHT + 8 + PREVIEW_HEIGHT + 6, 60, 15)];
    [_swatchLabel setStringValue:"Swatches:"];
    [_swatchLabel setTextColor:[CPColor blackColor]];
    [_swatchLabel setAlignment:CPRightTextAlignment];


    var opacityLabel = [[CPTextField alloc] initWithFrame:CGRectMake(10, TOOLBAR_HEIGHT + PREVIEW_HEIGHT + 35, 60, 20)];
    [opacityLabel setStringValue:"Opacity:"];
    [opacityLabel setTextColor:[CPColor blackColor]];
    [opacityLabel setAlignment:CPRightTextAlignment];

    _opacitySlider = [[CPSlider alloc] initWithFrame:CGRectMake(76, TOOLBAR_HEIGHT + PREVIEW_HEIGHT + 34, CGRectGetWidth(bounds) - 86, 20.0)];

    [_opacitySlider setMinValue:0.0];
    [_opacitySlider setMaxValue:1.0];
    [_opacitySlider setAutoresizingMask:CPViewWidthSizable];

    [_opacitySlider setTarget:self];
    [_opacitySlider setAction:@selector(setOpacity:)];

    [contentView addSubview:_toolbar];
    [contentView addSubview:previewBox];
    [contentView addSubview:_previewLabel];
    [contentView addSubview:swatchBox];
    [contentView addSubview:_swatchLabel];
    [contentView addSubview:opacityLabel];
    [contentView addSubview:_opacitySlider];

    _target = nil;
    _action = nil;
    _activePicker = nil;

    [_previewView setBackgroundColor:_color];

    if (buttonForLater)
        [self _setPicker:buttonForLater];
}

- (void)setOpacity:(id)sender
{
    var components = [[self color] components],
        alpha = [sender floatValue];

    [self setColor:[_color colorWithAlphaComponent:alpha] updatePicker:YES];
}

@end


CPColorDragType = "CPColorDragType";

var CPColorPanelSwatchesCookie = "CPColorPanelSwatchesCookie";

/* @ignore */
@implementation _CPColorPanelSwatches : CPView
{
    CPArray         _swatches;
    CPColor         _dragColor;
    CPColorPanel    _colorPanel;
    CPCookie        _swatchCookie;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    [self setBackgroundColor:[CPColor grayColor]];

    [self registerForDraggedTypes:[CPArray arrayWithObjects:CPColorDragType]];

    var whiteColor = [CPColor whiteColor];

    _swatchCookie = [[CPCookie alloc] initWithName:CPColorPanelSwatchesCookie];
    var colorList = [self startingColorList];

    _swatches = [];

    for (var i = 0; i < 50; i++)
    {
        // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/25-implement-cpbox
        var view = [[CPView alloc] initWithFrame:CGRectMake(13 * i + 1, 1, 12, 12)],
            fillView = [[CPView alloc] initWithFrame:CGRectInset([view bounds], 1.0, 1.0)];

        [view setBackgroundColor:whiteColor];
        [fillView setBackgroundColor:(i < colorList.length) ? colorList[i] : whiteColor];

        [view addSubview:fillView];

        [self addSubview:view];

        _swatches.push(view);
    }

    return self;
}

- (BOOL)isOpaque
{
    return YES;
}

- (CPArray)startingColorList
{
    var cookieValue = [_swatchCookie value];

    if (!cookieValue)
    {
        return [
            [CPColor blackColor],
            [CPColor darkGrayColor],
            [CPColor grayColor],
            [CPColor lightGrayColor],
            [CPColor whiteColor],
            [CPColor redColor],
            [CPColor greenColor],
            [CPColor blueColor],
            [CPColor yellowColor]
        ];
    }

    var cookieValue = eval(cookieValue),
        result = [];

    for (var i = 0; i < cookieValue.length; i++)
        result.push([CPColor colorWithHexString:cookieValue[i]]);

    return result;
}

- (CPArray)saveColorList
{
    var result = [];
    // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/25-implement-cpbox
    for (var i = 0; i < _swatches.length; i++)
        result.push([[[_swatches[i] subviews][0] backgroundColor] hexString]);

    var future = new Date();
    future.setYear(2019);

    [_swatchCookie setValue:JSON.stringify(result) expires:future domain:nil];
}

- (void)setColorPanel:(CPColorPanel)panel
{
    _colorPanel = panel;
}

- (CPColorPanel)colorPanel
{
    return _colorPanel;
}

- (CPColor)colorAtIndex:(int)index
{
    return [[_swatches[index] subviews][0] backgroundColor];
}

- (void)setColor:(CPColor)aColor atIndex:(int)index
{
    // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/25-implement-cpbox
    [[_swatches[index] subviews][0] setBackgroundColor:aColor];
    [self saveColorList];
}

- (void)mouseUp:(CPEvent)anEvent
{
    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        bounds = [self bounds];

    if (!CGRectContainsPoint(bounds, point) || point.x > [self bounds].size.width - 1 || point.x < 1)
        return NO;

    [_colorPanel setColor:[self colorAtIndex:FLOOR(point.x / 13)] updatePicker:YES];
}

- (void)mouseDragged:(CPEvent)anEvent
{
    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];

     if (point.x > [self bounds].size.width - 1 || point.x < 1)
        return NO;

    [[CPPasteboard pasteboardWithName:CPDragPboard] declareTypes:[CPArray arrayWithObject:CPColorDragType] owner:self];

    var swatch = _swatches[FLOOR(point.x / 13)];

    // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/25-implement-cpbox
    _dragColor = [[swatch subviews][0] backgroundColor];

    var bounds = CGRectMakeCopy([swatch bounds]);

    // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/25-implement-cpbox
    var dragView = [[CPView alloc] initWithFrame:bounds],
        dragFillView = [[CPView alloc] initWithFrame:CGRectInset(bounds, 1.0, 1.0)];

    [dragView setBackgroundColor:[CPColor blackColor]];
    [dragFillView setBackgroundColor:_dragColor];

    [dragView addSubview:dragFillView];

    [self dragView:dragView
                at:CGPointMake(point.x - bounds.size.width / 2.0, point.y - bounds.size.height / 2.0)
            offset:CGPointMake(0.0, 0.0)
             event:anEvent
        pasteboard:nil
            source:self
         slideBack:YES];
}

- (void)pasteboard:(CPPasteboard)aPasteboard provideDataForType:(CPString)aType
{
    if (aType == CPColorDragType)
        [aPasteboard setData:[CPKeyedArchiver archivedDataWithRootObject:_dragColor] forType:aType];
}

- (void)performDragOperation:(id <CPDraggingInfo>)aSender
{
    var location = [self convertPoint:[aSender draggingLocation] fromView:nil],
        pasteboard = [aSender draggingPasteboard],
        swatch = nil;

    if (![pasteboard availableTypeFromArray:[CPColorDragType]] || location.x > [self bounds].size.width - 1 || location.x < 1)
        return NO;

    [self setColor:[CPKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:CPColorDragType]] atIndex:FLOOR(location.x / 13)];
}

@end

/* @ignore */
@implementation _CPColorPanelPreview : CPView
{
    CPColorPanel    _colorPanel;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    [self registerForDraggedTypes:[CPArray arrayWithObjects:CPColorDragType]];

    return self;
}

- (void)setColorPanel:(CPColorPanel)aPanel
{
    _colorPanel = aPanel;
}

- (CPColorPanel)colorPanel
{
    return _colorPanel;
}

- (void)performDragOperation:(id <CPDraggingInfo>)aSender
{
    var pasteboard = [aSender draggingPasteboard];

    if (![pasteboard availableTypeFromArray:[CPColorDragType]])
        return NO;

    var color = [CPKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:CPColorDragType]];
    [_colorPanel setColor:color updatePicker:YES];
}

- (BOOL)isOpaque
{
    return YES;
}

- (void)mouseDragged:(CPEvent)anEvent
{
    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];

    [[CPPasteboard pasteboardWithName:CPDragPboard] declareTypes:[CPColorDragType] owner:self];

    var bounds = CGRectMake(0, 0, 15, 15);

    // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/25-implement-cpbox
    var dragView = [[CPView alloc] initWithFrame:bounds],
        dragFillView = [[CPView alloc] initWithFrame:CGRectInset(bounds, 1.0, 1.0)];

    [dragView setBackgroundColor:[CPColor blackColor]];
    [dragFillView setBackgroundColor:[self backgroundColor]];

    [dragView addSubview:dragFillView];

    [self dragView:dragView
                at:CGPointMake(point.x - bounds.size.width / 2.0, point.y - bounds.size.height / 2.0)
            offset:CGPointMake(0.0, 0.0)
             event:anEvent
        pasteboard:nil
            source:self
         slideBack:YES];
}

- (void)pasteboard:(CPPasteboard)aPasteboard provideDataForType:(CPString)aType
{
    if (aType == CPColorDragType)
        [aPasteboard setData:[CPKeyedArchiver archivedDataWithRootObject:[self backgroundColor]] forType:aType];
}

@end

@import "CPColorPicker.j"
@import "CPSliderColorPicker.j"

[CPColorPanel provideColorPickerClass:CPColorWheelColorPicker];
[CPColorPanel provideColorPickerClass:CPSliderColorPicker];
