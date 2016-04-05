/*
 * LPMultiLineLabel.j
 *
 * Based on LPMultiLineTextField by Ludwig Pettersson.
 *
 */
@import <AppKit/CPTextField.j>

@implementation SCMultiLineLabel : CPView
{
    id          _DOMTextareaElement;
    CPString    _stringValue;
    CGInset     _contentInset   @accessors(readonly, getter=contentInset);
    CPColor     _color          @accessors(readonly, getter=color);
    CPFont      _font           @accessors(readonly, getter=font);
    BOOL        _styled         @accessors(readonly, getter=isStyled);
}

- (DOMElement)_DOMTextareaElement
{
    if (!_DOMTextareaElement)
    {
        _DOMTextareaElement = document.createElement(_styled ? "div" : "textarea");
        _DOMTextareaElement.style.position = @"absolute";
        _DOMTextareaElement.style.background = @"none";
        _DOMTextareaElement.style.border = @"0";
        _DOMTextareaElement.style.outline = @"0";
        _DOMTextareaElement.style.zIndex = @"100";
        _DOMTextareaElement.style.resize = @"none";
        _DOMTextareaElement.style.padding = @"0";
        _DOMTextareaElement.style.margin = @"0";
        _DOMTextareaElement.style.overflowX = @"hidden";

        _DOMTextareaElement.onblur = function(){
                [[CPTextFieldInputOwner window] makeFirstResponder:nil];
                CPTextFieldInputOwner = nil;
            };

        self._DOMElement.appendChild(_DOMTextareaElement);
    }

    return _DOMTextareaElement;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        var theme = [CPTheme defaultTheme];

        _contentInset = CGInsetMakeZero();
        _color = [theme valueForAttributeWithName:@"text-color" forClass:[CPTextField class]];
        _font = [theme valueForAttributeWithName:@"font" forClass:[CPTextField class]];
    }

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    var contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                        relativeToEphemeralSubviewNamed:@"bezel-view"];
    [contentView setHidden:YES];

    var DOMElement = [self _DOMTextareaElement],
        bounds = [self bounds];

    DOMElement.style.paddingTop = _contentInset.top + @"px";
    DOMElement.style.paddingBottom = _contentInset.bottom + @"px";
    DOMElement.style.paddingLeft = _contentInset.left + @"px";
    DOMElement.style.paddingRight = _contentInset.right + @"px";

    DOMElement.style.width = (CGRectGetWidth(bounds) - _contentInset.left - _contentInset.right) + @"px";
    DOMElement.style.height = (CGRectGetHeight(bounds) - _contentInset.top - _contentInset.bottom) + @"px";

    DOMElement.style.color = [_color cssString];
    DOMElement.style.font = [_font cssString];

    if (_styled)
        DOMElement.innerHTML = _stringValue || @"";
    else
        DOMElement.value = _stringValue || @"";
}

- (CPString)stringValue
{
    return (!!_DOMTextareaElement) ? _DOMTextareaElement.value : @"";
}

- (void)setStringValue:(CPString)aString
{
    if (_stringValue === aString)
        return;

    _stringValue = aString;
    [self setNeedsLayout];
}

- (void)setContentInset:(CGInset)inset
{
    if (CGInsetEqualToInset(_contentInset, inset))
        return;

    _contentInset = CGInsetMakeCopy(inset);
    [self setNeedsLayout];
}

- (void)setColor:(CPColor)aColor
{
    if ([_color isEqual:aColor])
        return;

    _color = aColor;
    [self setNeedsLayout];
}

- (void)setFont:(CPFont)aFont
{
    if ([_font isEqual:aFont])
        return;

    _font = aFont;
    [self setNeedsLayout];
}

- (void)setStyled:(BOOL)flag
{
    flag = !!flag;

    if (_styled === flag)
        return;

    _styled = flag;
    _DOMTextareaElement = nil;
    [self setNeedsLayout];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "bezel-view")
    {
        var view = [[CPView alloc] initWithFrame:CGRectMakeZero()];

        [view setHitTests:NO];

        return view;
    }
    else
    {
        var view = [[_CPImageAndTextView alloc] initWithFrame:CGRectMakeZero()];

        [view setHitTests:NO];

        return view;
    }

    return [super createEphemeralSubviewNamed:aName];
}

@end
