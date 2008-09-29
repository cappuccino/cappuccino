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

import "CPButton.j"
import "CPColorPicker.j"
import "CPCookie.j"
import "CPKulerColorPicker.j"
import "CPPanel.j"
import "CPSliderColorPicker.j"
import "CPView.j"


CPColorPanelColorDidChangeNotification = @"CPColorPanelColorDidChangeNotification";

var PREVIEW_HEIGHT = 20.0,
    TOOLBAR_HEIGHT = 32.0,
    SWATCH_HEIGHT  = 14.0;

var SharedColorPanel = nil;

/*
    A color wheel
    @global
    @group CPColorPanelMode
*/
CPWheelColorPickerMode = 1;
/*
    Kuler color picker
    @global
    @group CPColorPanelMode
*/
CPKulerColorPickerMode = 2;
/*
    Slider based picker
    @global
    @group CPColorPanelMode
*/
CPSliderColorPickerMode = 3;

CPColorPickerViewWidth  = 265,
CPColorPickerViewHeight = 370;

/*
    <objj>CPColorPanel</objj> provides a reusable panel that can be used
    displayed on screen to prompt the user for a color selection. To
    obtain the panel, call the <code>sharedColorPanel</code> method.
*/
@implementation CPColorPanel : CPPanel
{    
    _CPColorPanelToolbar    _toolbar;
    _CPColorPanelSwatches   _swatchView;
    _CPColorPanelPreview    _previewView;
    
    CPTextField     _previewLabel;
    CPTextField     _swatchLabel;
        
    CPView          _activeView;
    
    CPColorPicker   _activePicker;
    CPColorPicker   _wheelPicker;
    CPColorPicker   _kulerPicker;
    CPColorPicker   _sliderPicker;
    
    CPColor         _color;
    
    id              _target;
    SEL             _action;       
    
    int             _mode;             
}

/*
    Returns (and if necessary, creates) the shared color panel.
*/
+ (CPColorPanel)sharedColorPanel
{
    if (!SharedColorPanel)
        SharedColorPanel = [[CPColorPanel alloc] init];
    
    return SharedColorPanel;
}

/*
    Sets the mode for the shared color panel.
    @param mode the mode to which the color panel will be set
*/
+ (void)setPickerMode:(CPColorPanelMode)mode
{
    var panel = [CPColorPanel sharedColorPanel];
    [panel setMode: mode];
}

/*
    To obtain the color panel, use <code>sharedColorPanel</code>.
    @ignore
*/
- (id)init
{
    self = [super initWithContentRect:CGRectMake(500.0, 50.0, 218.0, 360.0) 
                            styleMask:(CPHUDBackgroundWindowMask | CPTitledWindowMask | CPClosableWindowMask | CPResizableWindowMask)];
    
    if (self)
    {
        [self setTitle:@"Color Panel"];
        [self setLevel:CPFloatingWindowLevel];
        
        [self setFloatingPanel:YES];
        [self setBecomesKeyOnlyIfNeeded:YES];
        
        [self setMinSize:CGSizeMake(218.0, 360.0)];
        [self setMaxSize:CGSizeMake(327.0, 540.0)];
    }
    
    return self;
}

/*
    Sets the color of the panel, and updates the picker. Also posts a <code>CPColorPanelDidChangeNotification</code>.
*/
- (void)setColor:(CPColor)aColor
{
    _color = aColor;
    [_previewView setBackgroundColor: _color];
    
    [CPApp sendAction:@selector(changeColor:) to:nil from:self];

    if (_target && _action)
        objj_msgSend(_target, _action, self);
        
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPColorPanelColorDidChangeNotification
                      object:self];
}

/*
    Sets the selected color of the panel and optionally updates the picker.
    @param bool whether or not to update the picker
    @ignore
*/
 -(void)setColor:(CPColor)aColor updatePicker:(BOOL)bool
 {
    [self setColor: aColor];

    if(bool)
        [_activePicker setColor: _color];
 }
 

/*
    Returns the panel's currently selected color.
*/
- (CPColor)color
{
    return _color;
}

/*
    Sets the target for the color panel. Messages are sent
    to the target when colors are selected in the panel.
*/
- (void)setTarget:(id)aTarget
{
    _target = aTarget;
}

/*
    Returns the current target. The target receives messages
    when colors are selected in the panel.
*/
- (id)target
{
    return _target;
}

/*
    Sets the action that gets sent to the target.
    This action is sent whenever a color is selected in the panel.
    @param anAction the action that will be sent
*/
- (void)setAction:(selector)anAction
{
    _action = anAction;
}

/*
    Returns the current target action.
*/
- (selector)action
{
    return _action;
}

/*
    Sets the mode (look) of the color panel.
    @param mode the mode in which to display the color panel
*/
- (void)setMode:(CPColorPanelMode)mode
{
    if(mode == _mode) 
        return;
                
    var frame = CPRectCreateCopy([_currentView frame]);
    [_currentView removeFromSuperview];
    
    switch(mode)
    {
        case CPWheelColorPickerMode:  _activePicker = _wheelPicker; break;
        case CPKulerColorPickerMode:  _activePicker = _kulerPicker; break;
        case CPSliderColorPickerMode: _activePicker = _sliderPicker; break;
    }
    
    _currentView = [_activePicker provideNewView: NO]; 
    [_activePicker setColor: _color]; 

    _mode = mode;

    [_currentView setFrame: frame];
    [_currentView setAutoresizingMask: (CPViewWidthSizable | CPViewHeightSizable)];
    [[self contentView] addSubview: _currentView];
}

/*
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
        
    var contentView = [self contentView],
        bounds = [contentView bounds];
    
    _toolbar = [[_CPColorPanelToolbar alloc] initWithFrame: CPRectMake(0, 0, CGRectGetWidth(bounds), TOOLBAR_HEIGHT)];
    [_toolbar setAutoresizingMask: CPViewWidthSizable];  

    // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/25-implement-cpbox
    var previewBox = [[CPView alloc] initWithFrame:CGRectMake(76, TOOLBAR_HEIGHT + 10, CGRectGetWidth(bounds) - 86, PREVIEW_HEIGHT)];
    
    _previewView = [[_CPColorPanelPreview alloc] initWithFrame:CGRectInset([previewBox bounds], 2.0, 2.0)];
                                                         
    [_previewView setColorPanel:self];
    [_previewView setAutoresizingMask:CPViewWidthSizable];  
    
    [previewBox setBackgroundColor:[CPColor grayColor]];
    [previewBox setAutoresizingMask:CPViewWidthSizable];
    
    [previewBox addSubview:_previewView];
        
    _previewLabel = [[CPTextField alloc] initWithFrame: CPRectMake(10, TOOLBAR_HEIGHT + 14, 60, 15)];
    [_previewLabel setStringValue: "Preview:"];
    [_previewLabel setTextColor:[CPColor whiteColor]];
    [_previewLabel setAlignment:CPRightTextAlignment];

    // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/25-implement-cpbox
    var swatchBox = [[CPView alloc] initWithFrame:CGRectMake(76, TOOLBAR_HEIGHT + 10 + PREVIEW_HEIGHT + 5, CGRectGetWidth(bounds) - 86, SWATCH_HEIGHT + 2.0)];

    [swatchBox setBackgroundColor:[CPColor grayColor]];
    [swatchBox setAutoresizingMask:CPViewWidthSizable];
    
    _swatchView = [[_CPColorPanelSwatches alloc] initWithFrame:CGRectInset([swatchBox bounds], 1.0, 1.0)];
                                                                     
    [_swatchView setColorPanel: self];
    [_swatchView setAutoresizingMask: CPViewWidthSizable];  

    [swatchBox addSubview:_swatchView];

    _swatchLabel = [[CPTextField alloc] initWithFrame: CPRectMake(10, TOOLBAR_HEIGHT + 8 + PREVIEW_HEIGHT + 5, 60, 15)];
    [_swatchLabel setStringValue: "Swatches:"];
    [_swatchLabel setTextColor:[CPColor whiteColor]];
    [_swatchLabel setAlignment:CPRightTextAlignment];

    _wheelPicker = [[CPColorWheelColorPicker alloc] initWithPickerMask: 1|2|3 colorPanel: self];
    _currentView = [_wheelPicker provideNewView: YES];

    var height = (TOOLBAR_HEIGHT+10+PREVIEW_HEIGHT+5+SWATCH_HEIGHT+10);
    [_currentView setFrameSize: CPSizeMake(bounds.size.width - 10, bounds.size.height - height)];
    [_currentView setFrameOrigin: CPPointMake(5, TOOLBAR_HEIGHT+10+PREVIEW_HEIGHT+5+SWATCH_HEIGHT+10)];
    [_currentView setAutoresizingMask: (CPViewWidthSizable | CPViewHeightSizable)];

    _kulerPicker = [[CPKulerColorPicker alloc] initWithPickerMask: 1|2|3 colorPanel: self];
    [_kulerPicker provideNewView: YES];

    _sliderPicker = [[CPSliderColorPicker alloc] initWithPickerMask: 1|2|3 colorPanel: self];
    [_sliderPicker provideNewView: YES];

    [contentView addSubview: _toolbar];
    [contentView addSubview: previewBox];
    [contentView addSubview: _previewLabel];
    [contentView addSubview: swatchBox];
    [contentView addSubview: _swatchLabel];
    [contentView addSubview: _currentView];
    
    _target = nil;
    _action = nil;
    
    _activePicker = _wheelPicker;
    
    [self setColor:[CPColor whiteColor]];
    [_activePicker setColor:[CPColor whiteColor]];
}

@end

var iconSize   = 32,
    totalIcons = 3;

/* @ignore */
@implementation _CPColorPanelToolbar : CPView
{
    CPImage  _wheelImage;
    CPImage  _wheelAlternateImage;
    CPButton _wheelButton;
    
    CPImage  _sliderImage;
    CPImage  _sliderAlternateImage;
    CPButton _sliderButton; 
    
    CPImage  _kulerImage;
    CPImage  _kulerAlternateImage;
    CPButton _kulerButton;    
}

- (id)initWithFrame:(CPRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    var width  = aFrame.size.width;
    var center = width / 2.0;
    var start  = center - ((totalIcons * iconSize) + (totalIcons - 1) * 8.0) / 2.0;
    
    _wheelButton = [[CPButton alloc] initWithFrame:CPRectMake(start, 0, iconSize, iconSize)];
        
    start += iconSize + 8;
    
    var path     = [[CPBundle bundleForClass: _CPColorPanelToolbar] pathForResource:@"wheel_button.png"]; 
    _wheelImage  = [[CPImage alloc] initWithContentsOfFile:path size: CPSizeMake(iconSize, iconSize)];
    
    path                 = [[CPBundle bundleForClass: _CPColorPanelToolbar] pathForResource:@"wheel_button_h.png"];
    _wheelAlternateImage = [[CPImage alloc] initWithContentsOfFile:path size: CPSizeMake(iconSize, iconSize)];
    
    [_wheelButton setBordered:NO];
    [_wheelButton setImage: _wheelImage];
    [_wheelButton setAlternateImage: _wheelAlternateImage];
    [_wheelButton setTarget: self];
    [_wheelButton setAction: @selector(setMode:)];
    [_wheelButton setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin];

    [self addSubview: _wheelButton];
 
    _sliderButton = [[CPButton alloc] initWithFrame:CPRectMake(start, 0, iconSize, iconSize)];
    
    start += iconSize + 8;

    path          = [[CPBundle bundleForClass: _CPColorPanelToolbar] pathForResource:@"slider_button.png"];
    _sliderImage  = [[CPImage alloc] initWithContentsOfFile:path size: CPSizeMake(iconSize, iconSize)];

    path                  = [[CPBundle bundleForClass: _CPColorPanelToolbar] pathForResource:@"slider_button_h.png"];
    _sliderAlternateImage = [[CPImage alloc] initWithContentsOfFile:path size: CPSizeMake(iconSize, iconSize)];

    [_sliderButton setBordered:NO];
    [_sliderButton setImage: _sliderImage];    
    [_sliderButton setAlternateImage: _sliderAlternateImage];    
    [_sliderButton setTarget: self];
    [_sliderButton setAction: @selector(setMode:)];
    [_sliderButton setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin];

    [self addSubview: _sliderButton];
     
    _kulerButton = [[CPButton alloc] initWithFrame:CPRectMake(start, 0, iconSize, iconSize)];
    start += iconSize + 8;

    path         = [[CPBundle bundleForClass: _CPColorPanelToolbar] pathForResource:@"kuler_button.png"];
    _kulerImage  = [[CPImage alloc] initWithContentsOfFile:path size: CPSizeMake(iconSize, iconSize)];

    path                 = [[CPBundle bundleForClass: _CPColorPanelToolbar] pathForResource:@"kuler_button_h.png"];
    _kulerAlternateImage = [[CPImage alloc] initWithContentsOfFile:path size: CPSizeMake(iconSize, iconSize)];

    [_kulerButton setBordered:NO];
    [_kulerButton setImage: _kulerImage];    
    [_kulerButton setAlternateImage: _kulerAlternateImage];    
    [_kulerButton setTarget: self];
    [_kulerButton setAction: @selector(setMode:)];
    [_kulerButton setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin];
    
    [self addSubview: _kulerButton];
    
    return self;
}

- (void)setMode:(id)sender
{
    if(sender == _kulerButton)
        [[CPColorPanel sharedColorPanel] setMode: CPKulerColorPickerMode];
    else if(sender == _wheelButton)
        [[CPColorPanel sharedColorPanel] setMode: CPWheelColorPickerMode];
    else
        [[CPColorPanel sharedColorPanel] setMode: CPSliderColorPickerMode];
}

@end

CPColorDragType = "CPColorDragType";
var CPColorPanelSwatchesCookie = "CPColorPanelSwatchesCookie";

/* @ignore */
@implementation _CPColorPanelSwatches : CPView
{
    CPView[]        _swatches;
    CPColor         _dragColor;
    CPColorPanel    _colorPanel;
    CPCookie        _swatchCookie;
}

-(id)initWithFrame:(CPRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    [self setBackgroundColor: [CPColor grayColor]];
    
    [self registerForDraggedTypes:[CPArray arrayWithObjects:CPColorDragType]];

    var whiteColor = [CPColor whiteColor];

    _swatchCookie = [[CPCookie alloc] initWithName: CPColorPanelSwatchesCookie];
    var colorList = [self startingColorList];
        
    _swatches = [];
    
    for(var i=0; i < 50; i++)
    {
        // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/25-implement-cpbox
        var view = [[CPView alloc] initWithFrame: CPRectMake(13*i+1, 1, 12, 12)],
            fillView = [[CPView alloc] initWithFrame:CGRectInset([view bounds], 1.0, 1.0)];
        
        [view setBackgroundColor:whiteColor];
        [fillView setBackgroundColor: (i < colorList.length) ? colorList[i] : whiteColor];

        [view addSubview:fillView];

        [self addSubview: view];
        
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
    if(cookieValue == "")
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
    
    var cookieValue = eval(cookieValue);
    var result = [];
    
    for(var i=0; i<cookieValue.length; i++)
        result.push([CPColor colorWithHexString: cookieValue[i]]);

    return result;
}

- (CPArray)saveColorList
{
    var result = [];
    // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/25-implement-cpbox
    for(var i=0; i<_swatches.length; i++)
        result.push([[[_swatches[i] subviews][0] backgroundColor] hexString]);
        
    var future = new Date();
    future.setYear(2019);
    
    [_swatchCookie setValue: CPJSObjectCreateJSON(result) expires:future domain: nil];
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
    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    
    if(point.x > [self bounds].size.width - 1 || point.x < 1)
        return NO;

    [_colorPanel setColor: [self colorAtIndex:FLOOR(point.x / 13)] updatePicker: YES];
}

- (void)mouseDragged:(CPEvent)anEvent
{
    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];

     if(point.x > [self bounds].size.width - 1 || point.x < 1)
        return NO;

    [[CPPasteboard pasteboardWithName:CPDragPboard] declareTypes:[CPArray arrayWithObject:CPColorDragType] owner:self];
 
    var swatch = _swatches[FLOOR(point.x / 13)];
    
    // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/25-implement-cpbox
    _dragColor = [[swatch subviews][0] backgroundColor];
    
    var bounds = CPRectCreateCopy([swatch bounds]);

    // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/25-implement-cpbox
    var dragView = [[CPView alloc] initWithFrame: bounds];
        dragFillView = [[CPView alloc] initWithFrame:CGRectInset(bounds, 1.0, 1.0)];
    
    [dragView setBackgroundColor:[CPColor blackColor]];
    [dragFillView setBackgroundColor:_dragColor];
    
    [dragView addSubview:dragFillView];

    [self dragView: dragView
                at: CPPointMake(point.x - bounds.size.width / 2.0, point.y - bounds.size.height / 2.0)
            offset: CPPointMake(0.0, 0.0)
             event: anEvent
        pasteboard: nil
            source: self
         slideBack: YES];
}

- (void)pasteboard:(CPPasteboard)aPasteboard provideDataForType:(CPString)aType
{
    if(aType == CPColorDragType)
        [aPasteboard setData:_dragColor forType:aType];
}

- (void)performDragOperation:(id <CPDraggingInfo>)aSender
{    
    var location = [self convertPoint:[aSender draggingLocation] fromView:nil],
        pasteboard = [aSender draggingPasteboard],
        swatch = nil;

    if(![pasteboard availableTypeFromArray:[CPColorDragType]] || location.x > [self bounds].size.width - 1 || location.x < 1)
        return NO;
        
    [self setColor:[pasteboard dataForType:CPColorDragType] atIndex: FLOOR(location.x / 13)];
}

@end

/* @ignore */
@implementation _CPColorPanelPreview : CPView
{
    CPColorPanel    _colorPanel;
}

- (id)initWithFrame:(CPRect)aFrame
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

    if(![pasteboard availableTypeFromArray:[CPColorDragType]])
        return NO;
        
    var color = [pasteboard dataForType:CPColorDragType];
    [_colorPanel setColor: color updatePicker: YES];
}

- (BOOL)isOpaque
{
    return YES;
}

- (void)mouseDragged:(CPEvent)anEvent
{
    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];

    [[CPPasteboard pasteboardWithName:CPDragPboard] declareTypes:[CPArray arrayWithObject:CPColorDragType] owner:self];    
    
    var bounds = CPRectMake(0, 0, 15, 15);
    
    // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/25-implement-cpbox
    var dragView = [[CPView alloc] initWithFrame: bounds];
        dragFillView = [[CPView alloc] initWithFrame:CGRectInset(bounds, 1.0, 1.0)];
    
    [dragView setBackgroundColor:[CPColor blackColor]];
    [dragFillView setBackgroundColor:[self backgroundColor]];
    
    [dragView addSubview:dragFillView];
    
    [self dragView: dragView
                at: CPPointMake(point.x - bounds.size.width / 2.0, point.y - bounds.size.height / 2.0)
            offset: CPPointMake(0.0, 0.0)
             event: anEvent
        pasteboard: nil
            source: self
         slideBack: YES];
}

- (void)pasteboard:(CPPasteboard)aPasteboard provideDataForType:(CPString)aType
{
    if(aType == CPColorDragType)
        [aPasteboard setData:[self backgroundColor] forType:aType];
}

@end
