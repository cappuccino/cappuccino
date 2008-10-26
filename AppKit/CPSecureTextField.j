@import "CPTextField.j"

#include "Platform/Platform.h"


var TOP_PADDING                 = 4.0,
    BOTTOM_PADDING              = 3.0;
    HORIZONTAL_PADDING          = 3.0;

var CPSecureTextFieldDOMInputElement    = nil;

@implementation CPSecureTextField : CPTextField
{
}

#if PLATFORM(DOM)
+ (DOMElement)_inputElement
{
    if (!CPSecureTextFieldDOMInputElement)
    {
        CPSecureTextFieldDOMInputElement = document.createElement("input");
        CPSecureTextFieldDOMInputElement.type = "password";
        CPSecureTextFieldDOMInputElement.style.position = "absolute";
        CPSecureTextFieldDOMInputElement.style.top = "0px";
        CPSecureTextFieldDOMInputElement.style.left = "0px";
        CPSecureTextFieldDOMInputElement.style.width = "100%"
        CPSecureTextFieldDOMInputElement.style.height = "100%";
        CPSecureTextFieldDOMInputElement.style.border = "0px";
        CPSecureTextFieldDOMInputElement.style.padding = "0px";
        CPSecureTextFieldDOMInputElement.style.whiteSpace = "pre";
        CPSecureTextFieldDOMInputElement.style.background = "transparent";
        CPSecureTextFieldDOMInputElement.style.outline = "none";
        CPSecureTextFieldDOMInputElement.style.paddingLeft = HORIZONTAL_PADDING + "px";
        CPSecureTextFieldDOMInputElement.style.paddingTop = TOP_PADDING - 2.0 + "px";
        CPSecureTextFieldDOMInputElement.style.margin = "0px";
    }
    
    return CPSecureTextFieldDOMInputElement;
}
#endif

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
#if PLATFORM(DOM)
        _DOMElement.removeChild(_DOMTextElement);
        
        _DOMTextElement = document.createElement("input");
        _DOMTextElement.type = "password";
        _DOMTextElement.style.position = "absolute";
        _DOMTextElement.style.top = TOP_PADDING + "px";
        _DOMTextElement.style.left = HORIZONTAL_PADDING + "px";
        _DOMTextElement.style.width = MAX(0.0, CGRectGetWidth(aFrame) - 2.0 * HORIZONTAL_PADDING) + "px";
        _DOMTextElement.style.height = MAX(0.0, CGRectGetHeight(aFrame) - TOP_PADDING - BOTTOM_PADDING) + "px";
        _DOMTextElement.style.whiteSpace = "pre";
        _DOMTextElement.style.cursor = "default";
        _DOMTextElement.style.zIndex = 100;
        _DOMTextElement.style.border = "0";
        _DOMTextElement.style.font = _DOMElement.style.font;
        _DOMTextElement.style.padding = "0px";
        _DOMTextElement.style.margin = "0px";

        _DOMElement.appendChild(_DOMTextElement);
#endif
    }
    
    return self;
}

- (void)setFont:(CPFont)aFont
{
    [super setFont:aFont];
    
#if PLATFORM(DOM)
    if (_DOMTextElement)
        _DOMTextElement.style.font = _DOMElement.style.font;
#endif
}

- (CPString)stringValue
{
    // All of this needs to be better.
#if PLATFORM(DOM)
    if ([[self window] firstResponder] == self)
        return [[self class] _inputElement].value;
#endif

    return _DOMTextElement.value;
}

- (void)setStringValue:(CPString)aStringValue
{
    _value = aStringValue;
    
#if PLATFORM(DOM)
    _DOMTextElement.value = _value;
#endif
}

@end