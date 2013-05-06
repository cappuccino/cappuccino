/*
 * CPApplication.j
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

@import "CPColorPicker.j"
@import "CPSlider.j"
@import "CPTextField.j"
@import "CPView.j"

@global CPColorPickerViewWidth
@global CPColorPickerViewHeight
@global CPSliderColorPickerMode


/*
    @ignore
*/
@implementation CPSliderColorPicker : CPColorPicker
{
    CPView      _contentView;

    CPSlider    _redSlider;
    CPSlider    _greenSlider;
    CPSlider    _blueSlider;
    CPSlider    _hueSlider;
    CPSlider    _saturationSlider;
    CPSlider    _brightnessSlider;

    CPTextField _rgbLabel;
    CPTextField _hsbLabel;
    CPTextField _redLabel;
    CPTextField _greenLabel;
    CPTextField _blueLabel;
    CPTextField _hueLabel;
    CPTextField _saturationLabel;
    CPTextField _brightnessLabel;
    CPTextField _hexLabel;
    CPTextField _hexValue;

    CPTextField _hexValue;
    CPTextField _redValue;
    CPTextField _greenValue;
    CPTextField _blueValue;
    CPTextField _hueValue;
    CPTextField _saturationValue;
    CPTextField _brightnessValue;
}

- (id)initWithPickerMask:(int)mask colorPanel:(CPColorPanel)owningColorPanel
{
    return [super initWithPickerMask:mask colorPanel:owningColorPanel];
}

- (id)initView
{
    var aFrame = CGRectMake(0, 0, CPColorPickerViewWidth, CPColorPickerViewHeight);

    _contentView = [[CPView alloc] initWithFrame:aFrame];
    [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    _rgbLabel = [[CPTextField alloc] initWithFrame:CGRectMake(0, 10, 100, 20)];
    [_rgbLabel setStringValue:"Red, Green, Blue"];
    [_rgbLabel setTextColor:[CPColor blackColor]];

    _redLabel = [[CPTextField alloc] initWithFrame:CGRectMake(0, 37, 15, 20)];
    [_redLabel setStringValue:"R"];
    [_redLabel setTextColor:[CPColor blackColor]];

    _redSlider = [[CPSlider alloc] initWithFrame:CGRectMake(15, 35, aFrame.size.width - 70, 20)];
    [_redSlider setMaxValue:1.0];
    [_redSlider setMinValue:0.0];
    [_redSlider setTarget:self];
    [_redSlider setAction:@selector(sliderChanged:)];
    [_redSlider setAutoresizingMask:CPViewWidthSizable];

    // red value input box
    _redValue = [[CPTextField alloc] initWithFrame:CGRectMake(aFrame.size.width - 45, 30, 45, 28)];
    [_redValue setAutoresizingMask:CPViewMinXMargin];
    [_redValue setEditable:YES];
    [_redValue setBezeled:YES];
    [_redValue setDelegate:self];
    [_contentView addSubview:_redValue];

    _greenLabel = [[CPTextField alloc] initWithFrame:CGRectMake(0, 63, 15, 20)];
    [_greenLabel setStringValue:"G"];
    [_greenLabel setTextColor:[CPColor blackColor]];

    _greenSlider = [[CPSlider alloc] initWithFrame:CGRectMake(15, 61, aFrame.size.width - 70, 20)];
    [_greenSlider setMaxValue:1.0];
    [_greenSlider setMinValue:0.0];
    [_greenSlider setTarget:self];
    [_greenSlider setAction:@selector(sliderChanged:)];
    [_greenSlider setAutoresizingMask:CPViewWidthSizable];

    // green value input box
    _greenValue = [[CPTextField alloc] initWithFrame:CGRectMake(aFrame.size.width - 45, 56, 45, 28)];
    [_greenValue setAutoresizingMask:CPViewMinXMargin];
    [_greenValue setEditable:YES];
    [_greenValue setBezeled:YES];
    [_greenValue setDelegate:self];
    [_contentView addSubview:_greenValue];

    _blueLabel = [[CPTextField alloc] initWithFrame:CGRectMake(0, 90, 15, 20)];
    [_blueLabel setStringValue:"B"];
    [_blueLabel setTextColor:[CPColor blackColor]];

    _blueSlider = [[CPSlider alloc] initWithFrame:CGRectMake(15, 87, aFrame.size.width - 70, 20)];
    [_blueSlider setMaxValue:1.0];
    [_blueSlider setMinValue:0.0];
    [_blueSlider setTarget:self];
    [_blueSlider setAction:@selector(sliderChanged:)];
    [_blueSlider setAutoresizingMask:CPViewWidthSizable];

    // blue value input box
    _blueValue = [[CPTextField alloc] initWithFrame:CGRectMake(aFrame.size.width - 45, 82, 45, 28)];
    [_blueValue setAutoresizingMask:CPViewMinXMargin];
    [_blueValue setEditable:YES];
    [_blueValue setBezeled:YES];
    [_blueValue setDelegate:self];
    [_contentView addSubview:_blueValue];

    _hsbLabel = [[CPTextField alloc] initWithFrame:CGRectMake(0, 120, 190, 20)];
    [_hsbLabel setStringValue:"Hue, Saturation, Brightness"];
    [_hsbLabel setTextColor:[CPColor blackColor]];

    _hueLabel = [[CPTextField alloc] initWithFrame:CGRectMake(0, 145, 15, 20)];
    [_hueLabel setStringValue:"H"];
    [_hueLabel setTextColor:[CPColor blackColor]];

    _hueSlider = [[CPSlider alloc] initWithFrame:CGRectMake(15, 143, aFrame.size.width - 70, 20)];
    [_hueSlider setMaxValue:0.999];
    [_hueSlider setMinValue:0.0];
    [_hueSlider setTarget:self];
    [_hueSlider setAction:@selector(sliderChanged:)];
    [_hueSlider setAutoresizingMask:CPViewWidthSizable];

    // hue value input box
    _hueValue = [[CPTextField alloc] initWithFrame:CGRectMake(aFrame.size.width - 45, 138, 45, 28)];
    [_hueValue setAutoresizingMask:CPViewMinXMargin];
    [_hueValue setEditable:YES];
    [_hueValue setBezeled:YES];
    [_hueValue setDelegate:self];
    [_contentView addSubview:_hueValue];

    _saturationLabel = [[CPTextField alloc] initWithFrame:CGRectMake(0, 170, 15, 20)];
    [_saturationLabel setStringValue:"S"];
    [_saturationLabel setTextColor:[CPColor blackColor]];

    _saturationSlider = [[CPSlider alloc] initWithFrame:CGRectMake(15, 168, aFrame.size.width - 70, 20)];
    [_saturationSlider setMaxValue:1.0];
    [_saturationSlider setMinValue:0.0];
    [_saturationSlider setTarget:self];
    [_saturationSlider setAction:@selector(sliderChanged:)];
    [_saturationSlider setAutoresizingMask:CPViewWidthSizable];

    // saturation value input box
    _saturationValue = [[CPTextField alloc] initWithFrame:CGRectMake(aFrame.size.width - 45, 164, 45, 28)];
    [_saturationValue setAutoresizingMask:CPViewMinXMargin];
    [_saturationValue setEditable:YES];
    [_saturationValue setBezeled:YES];
    [_saturationValue setDelegate:self];
    [_contentView addSubview:_saturationValue];

    _brightnessLabel = [[CPTextField alloc] initWithFrame:CGRectMake(0, 196, 15, 20)];
    [_brightnessLabel setStringValue:"B"];
    [_brightnessLabel setTextColor:[CPColor blackColor]];

    _brightnessSlider = [[CPSlider alloc] initWithFrame:CGRectMake(15, 194, aFrame.size.width - 70, 20)];
    [_brightnessSlider setMaxValue:1.0];
    [_brightnessSlider setMinValue:0.0];
    [_brightnessSlider setTarget:self];
    [_brightnessSlider setAction:@selector(sliderChanged:)];
    [_brightnessSlider setAutoresizingMask:CPViewWidthSizable];

    // brightness value input box
    _brightnessValue = [[CPTextField alloc] initWithFrame:CGRectMake(aFrame.size.width - 45, 190, 45, 28)];
    [_brightnessValue setAutoresizingMask:CPViewMinXMargin];
    [_brightnessValue setEditable:YES];
    [_brightnessValue setBezeled:YES];
    [_brightnessValue setDelegate:self];
    [_contentView addSubview:_brightnessValue];

    _hexLabel = [[CPTextField alloc] initWithFrame:CGRectMake(0, 230, 30, 20)];
    [_hexLabel setStringValue:"Hex"];
    [_hexLabel setTextColor:[CPColor blackColor]];

    //hex input box
    _hexValue = [[CPTextField alloc] initWithFrame:CGRectMake(32, 225, 80, 28)];
    [_hexValue setEditable:YES];
    [_hexValue setBezeled:YES];
    [_hexValue setDelegate:self];
    [_contentView addSubview:_hexValue];

    [_contentView addSubview:_rgbLabel];
    [_contentView addSubview:_redLabel];
    [_contentView addSubview:_greenLabel];
    [_contentView addSubview:_blueLabel];
    [_contentView addSubview:_redSlider];
    [_contentView addSubview:_greenSlider];
    [_contentView addSubview:_blueSlider];

    [_contentView addSubview:_hsbLabel];
    [_contentView addSubview:_hueLabel];
    [_contentView addSubview:_saturationLabel];
    [_contentView addSubview:_brightnessLabel];
    [_contentView addSubview:_hueSlider];
    [_contentView addSubview:_saturationSlider];
    [_contentView addSubview:_brightnessSlider];

    [_contentView addSubview:_hexLabel];
}

- (CPView)provideNewView:(BOOL)initialRequest
{
    if (initialRequest)
        [self initView];

    return _contentView;
}

- (int)currentMode
{
    return CPSliderColorPickerMode;
}

- (BOOL)supportsMode:(int)mode
{
    return (mode == CPSliderColorPickerMode) ? YES : NO;
}

- (void)sliderChanged:(id)sender
{
    var newColor,
        colorPanel = [self colorPanel],
        alpha = [colorPanel opacity];

    switch (sender)
    {
        case    _hueSlider:
        case    _saturationSlider:
        case    _brightnessSlider:      newColor = [CPColor colorWithHue:[_hueSlider floatValue]
                                                              saturation:[_saturationSlider floatValue]
                                                              brightness:[_brightnessSlider floatValue]
                                                                   alpha:alpha];

                                        [self updateRGBSliders:newColor];
                                        break;

        case    _redSlider:
        case    _greenSlider:
        case    _blueSlider:            newColor = [CPColor colorWithCalibratedRed:[_redSlider floatValue]
                                                                             green:[_greenSlider floatValue]
                                                                              blue:[_blueSlider floatValue]
                                                                             alpha:alpha];

                                        [self updateHSBSliders:newColor];
                                        break;
    }

    [self updateLabels];
    [self updateHex:newColor];
    [colorPanel setColor:newColor];
}

- (void)setColor:(CPColor)aColor
{
    if (!aColor)
        [CPException raise:CPInvalidArgumentException reason:"aColor can't be nil"];

    [self updateRGBSliders:aColor];
    [self updateHSBSliders:aColor];
    [self updateHex:aColor];
    [self updateLabels];
}

- (void)updateHSBSliders:(CPColor)aColor
{
    var hsb = [aColor hsbComponents];

    [_hueSlider setFloatValue:hsb[0]];
    [_saturationSlider setFloatValue:hsb[1]];
    [_brightnessSlider setFloatValue:hsb[2]];
}

- (void)updateHex:(CPColor)aColor
{
    [_hexValue setStringValue:[aColor hexString]];
}

- (void)updateRGBSliders:(CPColor)aColor
{
    var rgb = [aColor components];

    [_redSlider setFloatValue:rgb[0]];
    [_greenSlider setFloatValue:rgb[1]];
    [_blueSlider setFloatValue:rgb[2]];
}

- (void)updateLabels
{
    [_hueValue setStringValue:ROUND([_hueSlider floatValue] * 360.0)];
    [_saturationValue setStringValue:ROUND([_saturationSlider floatValue] * 100.0)];
    [_brightnessValue setStringValue:ROUND([_brightnessSlider floatValue] * 100.0)];

    [_redValue setStringValue:ROUND([_redSlider floatValue] * 255)];
    [_greenValue setStringValue:ROUND([_greenSlider floatValue] * 255)];
    [_blueValue setStringValue:ROUND([_blueSlider floatValue] * 255)];
}

- (CPImage)provideNewButtonImage
{
    return [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:CPColorPicker] pathForResource:"slider_button.png"] size:CGSizeMake(32, 32)];
}

- (CPImage)provideNewAlternateButtonImage
{
    return [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:CPColorPicker] pathForResource:"slider_button_h.png"] size:CGSizeMake(32, 32)];
}

- (void)controlTextDidEndEditing:(CPNotification)aNotification
{
    var field = [aNotification object],
        value = [[field stringValue] stringByTrimmingWhitespace];

    if (field === _hexValue)
    {
        var newColor = [CPColor colorWithHexString:value];

        if (newColor)
        {
            [self setColor:newColor];
            [[self colorPanel] setColor:newColor];
        }
    }
    else
    {
        switch (field)
        {
            case _redValue:        [_redSlider setFloatValue:MAX(MIN(ROUND(value), 255) / 255.0, 0)];
                                   [self sliderChanged:_redSlider];
                                   break;

            case _greenValue:      [_greenSlider setFloatValue:MAX(MIN(ROUND(value), 255) / 255.0, 0)];
                                   [self sliderChanged:_greenSlider];
                                   break;

            case _blueValue:       [_blueSlider setFloatValue:MAX(MIN(ROUND(value), 255) / 255.0, 0)];
                                   [self sliderChanged:_blueSlider];
                                   break;

            case _hueValue:        [_hueSlider setFloatValue:MAX(MIN(ROUND(value), 360) / 360.0, 0)];
                                   [self sliderChanged:_hueSlider];
                                   break;

            case _saturationValue: [_saturationSlider setFloatValue:MAX(MIN(ROUND(value), 100) / 100.0, 0)];
                                   [self sliderChanged:_saturationSlider];
                                   break;

            case _brightnessValue: [_brightnessSlider setFloatValue:MAX(MIN(ROUND(value), 100) / 100.0, 0)];
                                   [self sliderChanged:_brightnessSlider];
                                   break;
        }
    }
}

@end
