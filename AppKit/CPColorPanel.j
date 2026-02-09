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
@class _CPColorPanelToolbar
@class _CPColorPanelSwatches
@class _CPColorPanelPreview

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

 CPColorPanel provides a reusable panel that can be displayed on screen to
 prompt the user for a color selection. To obtain the panel, call the
 \c +sharedColorPanel method.

 <h3>Architecture: Responder Chain Communication</h3>

 <p>CPColorPanel communicates with color wells and other targets exclusively through the
 <strong>responder chain</strong>. When the user selects a color in the panel, the panel
 sends \c -changeColor: to \c nil (the first responder). This message travels up the
 responder chain to the first object that implements it—typically the active color well
 that has made itself first responder.</p>

 <p>This architecture provides loose coupling and automatic target resolution.
 The panel is a singleton (\c +sharedColorPanel) because only one color selection
 context should exist application-wide.</p>
 */
@implementation CPColorPanel : CPPanel
{
	_CPColorPanelSwatches   _swatchView;
	_CPColorPanelPreview    _previewView;

	CPSlider        _opacitySlider;

	CPArray         _colorPickers;
	CPView          _currentView;
	id              _activePicker;

	CPColor         _color;

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
	// Enforce singleton pattern
	if (SharedColorPanel)
		[CPException raise:CPInternalInconsistencyException
					reason:@"CPColorPanel is a singleton. Use +sharedColorPanel."];

	self = [super initWithContentRect:CGRectMake(500.0, 50.0, 219.0, 370.0)
							styleMask:(CPTitledWindowMask | CPClosableWindowMask | CPResizableWindowMask)];

	if (self)
	{
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
 Sets the color of the panel and sends \c -changeColor: up the responder chain.

 This is the primary method for color changes. When called, the panel:
 1. Updates its internal color state
 2. Updates the preview view
 3. Updates UI components that need to track the current color (like opacity slider)
 4. Sends \c -changeColor: to \c nil (first responder) via the responder chain

 The responder chain delivers the message to the first object that implements it,
 typically the active color well. No direct manipulation of pickers or UI components.

 @param aColor the new color to display and broadcast
 */
- (void)setColor:(CPColor)aColor
{
	if ([_color isEqual:aColor])
		return;

	_color = aColor;

	// Update preview view
	[_previewView setBackgroundColor:_color];

	// Update opacity slider to track current color (component tracking, not manipulation)
	// This ensures the slider always applies alpha to the correct color
	if (_opacitySlider)
		[_opacitySlider setFloatValue:[_color alphaComponent]];

	// Update active picker so its UI reflects the new color
	if (_activePicker)
		[_activePicker setColor:_color];

	// Primary communication mechanism: responder chain
	[CPApp sendAction:@selector(changeColor:) to:nil from:self];
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
	return [_color alphaComponent];
}

/*!
 Sets the mode (look) of the color panel.
 @param mode the mode in which to display the color panel
 */
- (void)setMode:(CPColorPanelMode)mode
{
	_mode = mode;
}

/*!
 Returns the color panel's current display mode.
 */
- (CPColorPanelMode)mode
{
	return _mode;
}

/*!
 Internal method to switch between color picker views.
 Components should not receive direct color updates - they'll get them via responder chain.
 */
- (void)_setPicker:(id)sender
{
	var picker = _colorPickers[[sender tag]],
	view = [picker provideNewView:NO] || [picker provideNewView:YES];

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

	// Inform picker of current color so it can initialize its UI
	[_activePicker setColor:_color];
}

- (void)orderFront:(id)aSender
{
	[self _loadContentsIfNecessary];
	[super orderFront:aSender];
}

/*!
 Internal setup method - creates UI components but avoids direct coupling
 */
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

	// Preview view setup
	var previewBox = [[CPView alloc] initWithFrame:CGRectMake(76, TOOLBAR_HEIGHT + 10, CGRectGetWidth(bounds) - 86, PREVIEW_HEIGHT)];
	_previewView = [[_CPColorPanelPreview alloc] initWithFrame:CGRectInset([previewBox bounds], 2.0, 2.0)];
	[_previewView setAutoresizingMask:CPViewWidthSizable];
	[previewBox setBackgroundColor:[CPColor colorWithWhite:0.8 alpha:1.0]];
	[previewBox setAutoresizingMask:CPViewWidthSizable];
	[previewBox addSubview:_previewView];

	// Swatch view setup
	var swatchBox = [[CPView alloc] initWithFrame:CGRectMake(76, TOOLBAR_HEIGHT + 10 + PREVIEW_HEIGHT + 5, CGRectGetWidth(bounds) - 86, SWATCH_HEIGHT + 2.0)];
	[swatchBox setBackgroundColor:[CPColor colorWithWhite:0.8 alpha:1.0]];
	[swatchBox setAutoresizingMask:CPViewWidthSizable];
	_swatchView = [[_CPColorPanelSwatches alloc] initWithFrame:CGRectInset([swatchBox bounds], 1.0, 1.0)];
	[_swatchView setAutoresizingMask:CPViewWidthSizable];
	[swatchBox addSubview:_swatchView];

	// Opacity slider
	_opacitySlider = [[CPSlider alloc] initWithFrame:CGRectMake(76, TOOLBAR_HEIGHT + PREVIEW_HEIGHT + 34, CGRectGetWidth(bounds) - 86, 15.0)];
	[_opacitySlider setMinValue:0.0];
	[_opacitySlider setMaxValue:1.0];
	[_opacitySlider setAutoresizingMask:CPViewWidthSizable];
	[_opacitySlider setTarget:self];
	[_opacitySlider setAction:@selector(_opacityChanged:)];

	// Add all components to content view
	[contentView addSubview:_toolbar];
	[contentView addSubview:previewBox];
	[contentView addSubview:swatchBox];
	[contentView addSubview:_opacitySlider];

	_activePicker = nil;
	[_previewView setBackgroundColor:_color];
	[_opacitySlider setFloatValue:[_color alphaComponent]];

	if (buttonForLater)
		[self _setPicker:buttonForLater];
}

/*!
 Handle opacity changes through responder chain pattern
 */
- (void)_opacityChanged:(id)sender
{
	var alpha = [sender floatValue],
	newColor = [_color colorWithAlphaComponent:alpha];

	// Update color state directly to avoid setColor: updating the slider we're dragging
	_color = newColor;
	[_previewView setBackgroundColor:_color];
	[CPApp sendAction:@selector(changeColor:) to:nil from:self];
}

@end

/*!
 Drag type for color data
 */
CPColorDragType = "CPColorDragType";

/*
 Cookie name for persistent swatch storage
 */
var CPColorPanelSwatchesCookie = "CPColorPanelSwatchesCookie";

/*!
 @ignore
 Swatch view implementation - handles drag/drop and click selection
 */
@implementation _CPColorPanelSwatches : CPView
{
	CPArray         _swatches;
	CPColor         _dragColor;
	CPCookie        _swatchCookie;
}

- (id)initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];

	[self setBackgroundColor:[CPColor grayColor]];
	[self registerForDraggedTypes:[CPArray arrayWithObject:CPColorDragType]];

	var whiteColor = [CPColor whiteColor];
	_swatchCookie = [[CPCookie alloc] initWithName:CPColorPanelSwatchesCookie];
	var colorList = [self _startingColorList];

	_swatches = [];

	for (var i = 0; i < 50; i++)
	{
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

- (CPArray)_startingColorList
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

	return [JSON.parse(cookieValue) arrayByApplyingBlock:function(value) {
		return [CPColor colorWithHexString:value];
	}];
}

- (void)_saveColorList
{
	var result = [];
	for (var i = 0; i < _swatches.length; i++)
		result.push([[[_swatches[i] subviews][0] backgroundColor] hexString]);

	var future = new Date();
	future.setYear(2019);
	[_swatchCookie setValue:JSON.stringify(result) expires:future domain:nil];
}

- (CPColor)colorAtIndex:(int)index
{
	return [[_swatches[index] subviews][0] backgroundColor];
}

- (void)setColor:(CPColor)aColor atIndex:(int)index
{
	[[_swatches[index] subviews][0] setBackgroundColor:aColor];
	[self _saveColorList];
}

- (void)mouseUp:(CPEvent)anEvent
{
	var point = [self convertPoint:[anEvent locationInWindow] fromView:nil],
	bounds = [self bounds];

	if (!CGRectContainsPoint(bounds, point) || point.x > bounds.size.width - 1 || point.x < 1)
		return;

	var index = FLOOR(point.x / 13);
	if (index < 0 || index >= _swatches.length)
		return;

	// Send color change via responder chain, not direct manipulation
	var colorPanel = [CPColorPanel sharedColorPanel];
	[colorPanel setColor:[self colorAtIndex:index]];
}

- (void)mouseDragged:(CPEvent)anEvent
{
	var point = [self convertPoint:[anEvent locationInWindow] fromView:nil],
	viewBounds = [self bounds];

	if (point.x > viewBounds.size.width - 1 || point.x < 1)
		return;

	var index = FLOOR(point.x / 13);
	if (index < 0 || index >= _swatches.length)
		return;

	[[CPPasteboard pasteboardWithName:CPDragPboard] declareTypes:[CPArray arrayWithObject:CPColorDragType] owner:self];

	var swatch = _swatches[index];
	_dragColor = [[swatch subviews][0] backgroundColor];

	var swatchBounds = CGRectMakeCopy([swatch bounds]),
	dragView = [[CPView alloc] initWithFrame:swatchBounds],
	dragFillView = [[CPView alloc] initWithFrame:CGRectInset(swatchBounds, 1.0, 1.0)];

	[dragView setBackgroundColor:[CPColor blackColor]];
	[dragFillView setBackgroundColor:_dragColor];
	[dragView addSubview:dragFillView];

	[self dragView:dragView
				at:CGPointMake(point.x - swatchBounds.size.width / 2.0, point.y - swatchBounds.size.height / 2.0)
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

- (CPDragOperation)draggingEntered:(id)aSender
{
	var pasteboard = [aSender draggingPasteboard];
	return [pasteboard availableTypeFromArray:[CPColorDragType]] ? CPDragOperationCopy : CPDragOperationNone;
}

- (CPDragOperation)draggingUpdated:(id)aSender
{
	return [self draggingEntered:aSender];
}

- (BOOL)performDragOperation:(id)aSender
{
	var location = [self convertPoint:[aSender draggingLocation] fromView:nil],
	pasteboard = [aSender draggingPasteboard];

	if (![pasteboard availableTypeFromArray:[CPColorDragType]] || location.x > [self bounds].size.width - 1 || location.x < 1)
		return NO;

	var index = FLOOR(location.x / 13);
	if (index < 0 || index >= _swatches.length)
		return NO;

	var color = [CPKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:CPColorDragType]];
	if (!color)
		return NO;

	[self setColor:color atIndex:index];

	// Notify via responder chain, not direct manipulation
	var colorPanel = [CPColorPanel sharedColorPanel];
	[colorPanel setColor:color];

	return YES;
}

@end

/*!
 @ignore
 Preview view implementation - handles drag operations
 */
@implementation _CPColorPanelPreview : CPView
{
}

- (id)initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];
	[self registerForDraggedTypes:[CPArray arrayWithObject:CPColorDragType]];
	return self;
}

- (BOOL)isOpaque
{
	return YES;
}

- (void)performDragOperation:(id)aSender
{
	var pasteboard = [aSender draggingPasteboard];

	if (![pasteboard availableTypeFromArray:[CPColorDragType]])
		return;

	var color = [CPKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:CPColorDragType]];
	if (!color)
		return;

	// Use responder chain via shared panel
	var colorPanel = [CPColorPanel sharedColorPanel];
	[colorPanel setColor:color];
}

- (void)mouseDragged:(CPEvent)anEvent
{
	var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];

	[[CPPasteboard pasteboardWithName:CPDragPboard] declareTypes:[CPColorDragType] owner:self];

	var bounds = CGRectMake(0, 0, 15, 15),
	dragView = [[CPView alloc] initWithFrame:bounds],
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

// Import and register default color pickers
@import "CPColorPicker.j"
@import "CPSliderColorPicker.j"

[CPColorPanel provideColorPickerClass:CPColorWheelColorPicker];
[CPColorPanel provideColorPickerClass:CPSliderColorPicker];
