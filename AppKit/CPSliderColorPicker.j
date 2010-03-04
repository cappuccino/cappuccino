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

#if PLATFORM(DOM)
    DOMElement  _redValue;
    DOMElement  _greenValue;
    DOMElement  _blueValue;
    DOMElement  _hueValue;
    DOMElement  _saturationValue;
    DOMElement  _brightnessValue;
    DOMElement  _hexValue;
#endif
}

- (id)initWithPickerMask:(int)mask colorPanel:(CPColorPanel)owningColorPanel 
{
    return [super initWithPickerMask:mask colorPanel: owningColorPanel];
}
  
-(id)initView
{
    aFrame = CPRectMake(0, 0, CPColorPickerViewWidth, CPColorPickerViewHeight);    
    
    _contentView = [[CPView alloc] initWithFrame:aFrame];
    [_contentView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
    
    _rgbLabel = [[CPTextField alloc] initWithFrame: CPRectMake(0, 10, 100, 20)];
    [_rgbLabel setStringValue: "Red, Green, Blue"];
    [_rgbLabel setTextColor:[CPColor blackColor]];

    _redLabel = [[CPTextField alloc] initWithFrame: CPRectMake(0, 35, 15, 20)];
    [_redLabel setStringValue: "R"];
    [_redLabel setTextColor:[CPColor blackColor]];
    
    _redSlider = [[CPSlider alloc] initWithFrame: CPRectMake(15, 35, aFrame.size.width - 70, 20)];
    [_redSlider setMaxValue: 1.0];
    [_redSlider setMinValue: 0.0];
    [_redSlider setTarget: self];
    [_redSlider setAction: @selector(sliderChanged:)];
    [_redSlider setAutoresizingMask: CPViewWidthSizable];

#if PLATFORM(DOM)
    var updateFunction = function(aDOMEvent) 
    { 
        if(isNaN(this.value))
            return;
           
        switch(this)
        {
            case _redValue:        [_redSlider setFloatValue:MAX(MIN(ROUND(this.value), 255) / 255.0, 0)]; 
                                   //[self sliderChanged: _redSlider];
                                   break;
                                   
            case _greenValue:      [_greenSlider setFloatValue:MAX(MIN(ROUND(this.value), 255) / 255.0, 0)]; 
                                   //[self sliderChanged: _greenSlider];
                                   break;
                                   
            case _blueValue:       [_blueSlider setFloatValue:MAX(MIN(ROUND(this.value), 255) / 255.0, 0)]; 
                                   //[self sliderChanged: _blueSlider];
                                   break;

            case _hueValue:        [_hueSlider setFloatValue:MAX(MIN(ROUND(this.value), 360), 0)]; 
                                   //[self sliderChanged: _hueSlider];
                                   break;
                                   
            case _saturationValue: [_saturationSlider setFloatValue:MAX(MIN(ROUND(this.value), 100), 0)]; 
                                   //[self sliderChanged: _saturationSlider];
                                   break;

            case _brightnessValue: [_brightnessSlider setFloatValue:MAX(MIN(ROUND(this.value), 100), 0)]; 
                                   //[self sliderChanged: _brightnessSlider];
                                   break;
        }
        
        this.blur();
    };

    var keypressFunction = function(aDOMEvent)
    {
        aDOMEvent = aDOMEvent || window.event;
        if (aDOMEvent.keyCode == 13) 
        { 
            updateFunction(aDOMEvent);
            
            if(aDOMEvent.preventDefault)
                aDOMEvent.preventDefault(); 
            else if(aDOMEvent.stopPropagation)
                aDOMEvent.stopPropagation();
        } 
    }

    //red value input box
    var redValue = [[CPView alloc] initWithFrame: CPRectMake(aFrame.size.width - 45, 35, 45, 20)];
    [redValue setAutoresizingMask: CPViewMinXMargin];
    
    _redValue = document.createElement("input");
    _redValue.style.width = "40px";
    _redValue.style.backgroundColor = "transparent";
    _redValue.style.border = "1px solid black";
    _redValue.style.color = "black";
    _redValue.style.position = "absolute";
    _redValue.style.top = "0px";
    _redValue.style.left = "0px";
    _redValue.onchange = updateFunction;
    
    redValue._DOMElement.appendChild(_redValue);
    [_contentView addSubview: redValue];
#endif

    _greenLabel = [[CPTextField alloc] initWithFrame: CPRectMake(0, 58, 15, 20)];
    [_greenLabel setStringValue: "G"];
    [_greenLabel setTextColor:[CPColor blackColor]];

    _greenSlider = [[CPSlider alloc] initWithFrame: CPRectMake(15, 58, aFrame.size.width - 70, 20)];
    [_greenSlider setMaxValue: 1.0];
    [_greenSlider setMinValue: 0.0];
    [_greenSlider setTarget: self];
    [_greenSlider setAction: @selector(sliderChanged:)];
    [_greenSlider setAutoresizingMask: CPViewWidthSizable];

#if PLATFORM(DOM)
    //green value input box
    var greenValue = [[CPView alloc] initWithFrame: CPRectMake(aFrame.size.width - 45, 58, 45, 20)];
    [greenValue setAutoresizingMask: CPViewMinXMargin];

    _greenValue = _redValue.cloneNode(false);
    _greenValue.onchange = updateFunction;
    
    greenValue._DOMElement.appendChild(_greenValue);
    [_contentView addSubview: greenValue];
#endif

    _blueLabel = [[CPTextField alloc] initWithFrame: CPRectMake(0, 81, 15, 20)];
    [_blueLabel setStringValue: "B"];
    [_blueLabel setTextColor:[CPColor blackColor]];

    _blueSlider = [[CPSlider alloc] initWithFrame: CPRectMake(15, 81, aFrame.size.width - 70, 20)];
    [_blueSlider setMaxValue: 1.0];
    [_blueSlider setMinValue: 0.0];
    [_blueSlider setTarget: self];
    [_blueSlider setAction: @selector(sliderChanged:)];
    [_blueSlider setAutoresizingMask: CPViewWidthSizable];

#if PLATFORM(DOM)
    //blue value input box
    var blueValue = [[CPView alloc] initWithFrame: CPRectMake(aFrame.size.width - 45, 81, 45, 20)];
    [blueValue setAutoresizingMask: CPViewMinXMargin];

    _blueValue = _redValue.cloneNode(false);
    _blueValue.onchange = updateFunction;

    blueValue._DOMElement.appendChild(_blueValue);
    [_contentView addSubview: blueValue];
#endif
    _hsbLabel = [[CPTextField alloc] initWithFrame: CPRectMake(0, 120, 190, 20)];
    [_hsbLabel setStringValue: "Hue, Saturation, Brightness"];
    [_hsbLabel setTextColor:[CPColor blackColor]];

    _hueLabel = [[CPTextField alloc] initWithFrame: CPRectMake(0, 145, 15, 20)];
    [_hueLabel setStringValue: "H"];
    [_hueLabel setTextColor:[CPColor blackColor]];
    
    _hueSlider = [[CPSlider alloc] initWithFrame: CPRectMake(15, 145, aFrame.size.width - 70, 20)];
    [_hueSlider setMaxValue: 359.0];
    [_hueSlider setMinValue: 0.0];
    [_hueSlider setTarget: self];
    [_hueSlider setAction: @selector(sliderChanged:)];
    [_hueSlider setAutoresizingMask: CPViewWidthSizable];

#if PLATFORM(DOM)
    //red value input box
    var hueValue = [[CPView alloc] initWithFrame: CPRectMake(aFrame.size.width - 45, 145, 45, 20)];
    [hueValue setAutoresizingMask: CPViewMinXMargin];

    _hueValue = _redValue.cloneNode(false);
    _hueValue.onchange = updateFunction;

    hueValue._DOMElement.appendChild(_hueValue);
    [_contentView addSubview: hueValue];
#endif
    _saturationLabel = [[CPTextField alloc] initWithFrame: CPRectMake(0, 168, 15, 20)];
    [_saturationLabel setStringValue: "S"];
    [_saturationLabel setTextColor:[CPColor blackColor]];

    _saturationSlider = [[CPSlider alloc] initWithFrame: CPRectMake(15, 168, aFrame.size.width - 70, 20)];
    [_saturationSlider setMaxValue: 100.0];
    [_saturationSlider setMinValue: 0.0];
    [_saturationSlider setTarget: self];
    [_saturationSlider setAction: @selector(sliderChanged:)];
    [_saturationSlider setAutoresizingMask: CPViewWidthSizable];

#if PLATFORM(DOM)
    //green value input box
    var saturationValue = [[CPView alloc] initWithFrame: CPRectMake(aFrame.size.width - 45, 168, 45, 20)];
    [saturationValue setAutoresizingMask: CPViewMinXMargin];

    _saturationValue = _redValue.cloneNode(false);
    _saturationValue.onchange = updateFunction;

    saturationValue._DOMElement.appendChild(_saturationValue);
    [_contentView addSubview: saturationValue];
#endif
    _brightnessLabel = [[CPTextField alloc] initWithFrame: CPRectMake(0, 191, 15, 20)];
    [_brightnessLabel setStringValue: "B"];
    [_brightnessLabel setTextColor:[CPColor blackColor]];

    _brightnessSlider = [[CPSlider alloc] initWithFrame: CPRectMake(15, 191, aFrame.size.width - 70, 20)];
    [_brightnessSlider setMaxValue: 100.0];
    [_brightnessSlider setMinValue: 0.0];
    [_brightnessSlider setTarget: self];
    [_brightnessSlider setAction: @selector(sliderChanged:)];
    [_brightnessSlider setAutoresizingMask: CPViewWidthSizable];

#if PLATFORM(DOM)
    //blue value input box
    var brightnessValue = [[CPView alloc] initWithFrame: CPRectMake(aFrame.size.width - 45, 191, 45, 20)];
    [brightnessValue setAutoresizingMask: CPViewMinXMargin];

    _brightnessValue = _redValue.cloneNode(false);
    _brightnessValue.onchange = updateFunction;

    brightnessValue._DOMElement.appendChild(_brightnessValue);
    [_contentView addSubview: brightnessValue];
#endif
    _hexLabel = [[CPTextField alloc] initWithFrame: CPRectMake(0, 230, 30, 20)];
    [_hexLabel setStringValue: "Hex"];
    [_hexLabel setTextColor:[CPColor blackColor]];

#if PLATFORM(DOM)
    //hex input box
    _hexValue = _redValue.cloneNode(false);
    _hexValue.style.top = "228px";
    _hexValue.style.width = "80px";
    _hexValue.style.left = "35px";
    _hexValue.onkeypress = function(aDOMEvent) 
    { 
        aDOMEvent = aDOMEvent || window.event;
        if (aDOMEvent.keyCode == 13) 
        { 
            var newColor = [CPColor colorWithHexString: this.value];
            
            if(newColor)
            {
                [self setColor: newColor];
                [[self colorPanel] setColor: newColor];
            }
            
            if(aDOMEvent.preventDefault)
                aDOMEvent.preventDefault(); 
            else if(aDOMEvent.stopPropagation)
                aDOMEvent.stopPropagation();
            
            this.blur();
        } 
    };

    _contentView._DOMElement.appendChild(_hexValue);
#endif

    [_contentView addSubview: _rgbLabel];
    [_contentView addSubview: _redLabel];
    [_contentView addSubview: _greenLabel];
    [_contentView addSubview: _blueLabel];
    [_contentView addSubview: _redSlider];
    [_contentView addSubview: _greenSlider];
    [_contentView addSubview: _blueSlider];
    
    [_contentView addSubview: _hsbLabel];
    [_contentView addSubview: _hueLabel];
    [_contentView addSubview: _saturationLabel];
    [_contentView addSubview: _brightnessLabel];
    [_contentView addSubview: _hueSlider];
    [_contentView addSubview: _saturationSlider];
    [_contentView addSubview: _brightnessSlider];
    
    [_contentView addSubview: _hexLabel];
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

-(void)sliderChanged:(id)sender
{
    var newColor,
        colorPanel = [self colorPanel],
        alpha = [colorPanel opacity];

    switch(sender)
    {
        case    _hueSlider:
        case    _saturationSlider:
        case    _brightnessSlider:      newColor = [CPColor colorWithHue: [_hueSlider floatValue]
                                                              saturation: [_saturationSlider floatValue]
                                                              brightness: [_brightnessSlider floatValue]
                                                                   alpha: alpha];
                                                              
                                        [self updateRGBSliders: newColor];
                                        break;
                                        
        case    _redSlider:
        case    _greenSlider:
        case    _blueSlider:            newColor = [CPColor colorWithCalibratedRed: [_redSlider floatValue]
                                                                             green: [_greenSlider floatValue]
                                                                              blue: [_blueSlider floatValue]
                                                                             alpha: alpha];
                                                              
                                        [self updateHSBSliders: newColor];
                                        break;
    }
        
    [self updateLabels];
    [self updateHex: newColor];
    [colorPanel setColor: newColor];
}

-(void)setColor:(CPColor)aColor
{
    [self updateRGBSliders: aColor];
    [self updateHSBSliders: aColor];
    [self updateHex: aColor];
    [self updateLabels];
}

-(void)updateHSBSliders:(CPColor)aColor
{
    var hsb = [aColor hsbComponents];
        
    [_hueSlider setFloatValue:hsb[0]];
    [_saturationSlider setFloatValue:hsb[1]];
    [_brightnessSlider setFloatValue:hsb[2]];
}

- (void)updateHex:(CPColor)aColor
{
#if PLATFORM(DOM)
    _hexValue.value = [aColor hexString];
#endif
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
#if PLATFORM(DOM)
    _hueValue.value        = ROUND([_hueSlider floatValue]);      
    _saturationValue.value = ROUND([_saturationSlider floatValue]);
    _brightnessValue.value = ROUND([_brightnessSlider floatValue]);
    
    _redValue.value        = ROUND([_redSlider floatValue] * 255);
    _greenValue.value      = ROUND([_greenSlider floatValue] * 255);
    _blueValue.value       = ROUND([_blueSlider floatValue] * 255);
#endif
}

- (CPImage)provideNewButtonImage
{
    return [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:CPColorPicker] pathForResource:"slider_button.png"] size:CGSizeMake(32, 32)];
}

- (CPImage)provideNewAlternateButtonImage
{
    return [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:CPColorPicker] pathForResource:"slider_button_h.png"] size:CGSizeMake(32, 32)];
}

@end
