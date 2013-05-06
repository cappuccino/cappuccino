/*
 * CPColorPicker.j
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

@import <Foundation/CPObject.j>

@import "CPView.j"

@class CPSlider

@global CPColorPickerViewWidth
@global CPColorPickerViewHeight
@global CPWheelColorPickerMode


/*!
    @ingroup appkit
    @class CPColorPicker

    CPColorPicker is an abstract superclass for all color picker subclasses. If you want a particular color picker, use CPColorPanel's \c +setPickerMode: method. The simplest way to implement your own color picker is to create a subclass of CPColorPicker.
*/
@implementation CPColorPicker : CPObject
{
    CPColorPanel    _panel;
    int             _mask;
}

/*!
    Initializes the color picker.
    @param aMask a unique unsigned int identifying your color picker
    @param aPanel the color panel that owns this picker
*/
- (id)initWithPickerMask:(int)aMask colorPanel:(CPColorPanel)aPanel
{
    if (self = [super init])
    {
        _panel = aPanel;
        _mask  = aMask;
    }

    return self;
}

/*!
    Returns the color panel that owns this picker
*/
- (CPColorPanel)colorPanel
{
    return _panel;
}

/*
    FIXME Not implemented.
    @return \c nil
    @ignore
*/
- (CPImage)provideNewButtonImage
{
    return nil;
}

/*!
    Sets the color picker's mode.
    @param mode the color panel mode
*/
- (void)setMode:(CPColorPanelMode)mode
{
}

/*!
    Sets the picker's color.
    @param aColor the new color for the picker
*/
- (void)setColor:(CPColor)aColor
{
}

@end

/*
    The wheel mode color picker.
    @ignore
*/
@implementation CPColorWheelColorPicker : CPColorPicker
{
    CPView          _pickerView;
    CPView          _brightnessSlider;
    __CPColorWheel  _hueSaturationView;

    CPColor         _cachedColor;
}

- (id)initWithPickerMask:(int)mask colorPanel:(CPColorPanel)owningColorPanel
{
    return [super initWithPickerMask:mask colorPanel: owningColorPanel];
}

- (id)initView
{
    var aFrame = CGRectMake(0, 0, CPColorPickerViewWidth, CPColorPickerViewHeight);

    _pickerView = [[CPView alloc] initWithFrame:aFrame];
    [_pickerView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    _brightnessSlider = [[CPSlider alloc] initWithFrame:CGRectMake(0, (aFrame.size.height - 34), aFrame.size.width, 15)];

    [_brightnessSlider setValue:15.0 forThemeAttribute:@"track-width"];
    [_brightnessSlider setValue:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[CPColorPicker class]] pathForResource:@"brightness_bar.png"]]] forThemeAttribute:@"track-color"];

    [_brightnessSlider setMinValue:0.0];
    [_brightnessSlider setMaxValue:100.0];
    [_brightnessSlider setFloatValue:100.0];

    [_brightnessSlider setTarget:self];
    [_brightnessSlider setAction:@selector(brightnessSliderDidChange:)];
    [_brightnessSlider setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];

    _hueSaturationView = [[__CPColorWheel alloc] initWithFrame:CGRectMake(0, 0, aFrame.size.width, aFrame.size.height - 38)];
    [_hueSaturationView setDelegate:self];
    [_hueSaturationView setAutoresizingMask:(CPViewWidthSizable | CPViewHeightSizable)];

    [_pickerView addSubview:_hueSaturationView];
    [_pickerView addSubview:_brightnessSlider];
}

- (void)brightnessSliderDidChange:(id)sender
{
    [self updateColor];
}

- (void)colorWheelDidChange:(id)sender
{
    [self updateColor];
}

- (void)updateColor
{
    var hue        = [_hueSaturationView angle],
        saturation = [_hueSaturationView distance],
        brightness = [_brightnessSlider floatValue];

    [_hueSaturationView setWheelBrightness:brightness / 100.0];
    [_brightnessSlider setBackgroundColor:[CPColor colorWithHue:hue / 360.0 saturation:saturation / 100.0 brightness:1]];

    var colorPanel = [self colorPanel],
        opacity = [colorPanel opacity];

    _cachedColor = [CPColor colorWithHue:hue / 360.0 saturation:saturation / 100.0 brightness:brightness / 100.0 alpha:opacity];

    [[self colorPanel] setColor:_cachedColor];
}

- (BOOL)supportsMode:(int)mode
{
    return (mode == CPWheelColorPickerMode) ? YES : NO;
}

- (int)currentMode
{
    return CPWheelColorPickerMode;
}

- (CPView)provideNewView:(BOOL)initialRequest
{
    if (initialRequest)
        [self initView];

    return _pickerView;
}

- (void)setColor:(CPColor)newColor
{
    if ([newColor isEqual:_cachedColor])
        return;

    var hsb = [newColor hsbComponents];

    [_hueSaturationView setPositionToColor:newColor];
    [_brightnessSlider setFloatValue:hsb[2] * 100.0];
    [_hueSaturationView setWheelBrightness:hsb[2]];

    [_brightnessSlider setBackgroundColor:[CPColor colorWithHue:hsb[0] saturation:hsb[1] brightness:1]];
}

- (CPImage)provideNewButtonImage
{
    return [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:CPColorPicker] pathForResource:"wheel_button.png"] size:CGSizeMake(32, 32)];
}

- (CPImage)provideNewAlternateButtonImage
{
    return [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:CPColorPicker] pathForResource:"wheel_button_h.png"] size:CGSizeMake(32, 32)];
}

@end

/* @ignore */
@implementation __CPColorWheel : CPView
{
    DOMElement  _wheelImage;
    DOMElement  _blackWheelImage;

    CPView      _crosshair;

    id          _delegate;

    float       _angle;
    float       _distance;

    float       _radius;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
#if PLATFORM(DOM)
        var path = [[CPBundle bundleForClass:CPColorPicker] pathForResource:@"wheel.png"];

        _wheelImage = new Image();
        _wheelImage.src = path;
        _wheelImage.style.position = "absolute";

        path = [[CPBundle bundleForClass:CPColorPicker] pathForResource:@"wheel_black.png"];

        _blackWheelImage = new Image();
        _blackWheelImage.src = path;
        _blackWheelImage.style.opacity = "0";
        _blackWheelImage.style.filter = "alpha(opacity=0)"
        _blackWheelImage.style.position = "absolute";

        _DOMElement.appendChild(_wheelImage);
        _DOMElement.appendChild(_blackWheelImage);
#endif

        [self setWheelSize:aFrame.size];

        _crosshair = [[CPView alloc] initWithFrame:CGRectMake(_radius - 2, _radius - 2, 4, 4)];
        [_crosshair setBackgroundColor:[CPColor blackColor]];

        var view = [[CPView alloc] initWithFrame:CGRectInset([_crosshair bounds], 1.0, 1.0)];
        [view setBackgroundColor:[CPColor whiteColor]];

        [_crosshair addSubview:view];

        [self addSubview:_crosshair];
    }

    return self;
}

- (void)setWheelBrightness:(float)brightness
{
#if PLATFORM(DOM)
    _blackWheelImage.style.opacity = 1.0 - brightness;
    _blackWheelImage.style.filter = "alpha(opacity=" + (1.0 - brightness) * 100 + ")"
#endif
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    [self setWheelSize:aSize];
}

- (void)setWheelSize:(CGSize)aSize
{
    var min = MIN(aSize.width, aSize.height);

#if PLATFORM(DOM)
    _blackWheelImage.style.width = min;
    _blackWheelImage.style.height = min;
    _blackWheelImage.width = min;
    _blackWheelImage.height = min;
    _blackWheelImage.style.top = (aSize.height - min) / 2.0 + "px";
    _blackWheelImage.style.left = (aSize.width - min) / 2.0 + "px";

    _wheelImage.style.width = min;
    _wheelImage.style.height = min;
    _wheelImage.width = min;
    _wheelImage.height = min;
    _wheelImage.style.top = (aSize.height - min) / 2.0 + "px";
    _wheelImage.style.left = (aSize.width - min) / 2.0 + "px";
#endif

    _radius = min / 2.0;

    [self setAngle:[self degreesToRadians:_angle] distance:(_distance / 100.0) * _radius];
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

- (id)delegate
{
    return _delegate;
}

- (float)angle
{
    return _angle;
}

- (float)distance
{
    return _distance;
}

- (void)mouseDown:(CPEvent)anEvent
{
    [self reposition:anEvent];
}

- (void)mouseDragged:(CPEvent)anEvent
{
    [self reposition:anEvent];
}

- (void)reposition:(CPEvent)anEvent
{
    var bounds   = [self bounds],
        location = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        midX     = CGRectGetMidX(bounds),
        midY     = CGRectGetMidY(bounds),
        distance = MIN(SQRT((location.x - midX) * (location.x - midX) + (location.y - midY) * (location.y - midY)), _radius),
        angle    = ATAN2(location.y - midY, location.x - midX);

    [self setAngle:angle distance:distance];

    [_delegate colorWheelDidChange:self];
}

- (void)setAngle:(int)angle distance:(float)distance
{
    var bounds = [self bounds],
        midX   = CGRectGetMidX(bounds),
        midY   = CGRectGetMidY(bounds);

    _angle     = [self radiansToDegrees:angle];
    _distance  = (distance / _radius) * 100.0;

    [_crosshair setFrameOrigin:CGPointMake(COS(angle) * distance + midX - 2.0, SIN(angle) * distance + midY - 2.0)];
}

- (void)setPositionToColor:(CPColor)aColor
{
    var hsb    = [aColor hsbComponents],
        bounds = [self bounds],
        angle    = [self degreesToRadians:hsb[0] * 360.0],
        distance = hsb[1] * _radius;

    [self setAngle:angle distance:distance];
}

- (int)radiansToDegrees:(float)radians
{
    return ((-radians / PI) * 180 + 360) % 360;
}

- (float)degreesToRadians:(float)degrees
{
    return -(((degrees - 360) / 180) * PI);
}

@end

