@import "CPControl.j"


var LEFT_MARGIN                 = 3.0,
    RIGHT_MARGIN                = 14.0 + 3.0,
    STATE_COLUMN_WIDTH          = 14.0,
    INDENTATION_WIDTH           = 17.0,
    VERTICAL_MARGIN             = 4.0,
    
    RIGHT_COLUMNS_MARGIN        = 30.0,
    KEY_EQUIVALENT_MARGIN       = 10.0;

var SUBMENU_INDICATOR_COLOR                     = nil,
    _CPMenuItemSelectionColor                   = nil,
    _CPMenuItemTextShadowColor                  = nil,
    
    _CPMenuItemDefaultStateImages               = [],
    _CPMenuItemDefaultStateHighlightedImages    = [];

@implementation _CPMenuItemStandardView : CPView
{
    CPMenuItem              _menuItem @accessors(property=menuItem);

    CPFont                  _font;
    CPColor                 _textColor;
    CPColor                 _textShadowColor;

    CGSize                  _minSize @accessors(readonly, property=minSize);
    BOOL                    _isDirty;

    CPImageView             _stateView;
    _CPImageAndTextView     _imageAndTextView;
    _CPImageAndTextView     _keyEquivalentView;
    CPView                  _submenuIndicatorView;
}

+ (void)initialize
{
    if (self !== [_CPMenuItemStandardView class])
        return;

    SUBMENU_INDICATOR_COLOR = [CPColor grayColor];

    _CPMenuItemSelectionColor =  [CPColor colorWithCalibratedRed:95.0 / 255.0 green:131.0 / 255.0 blue:185.0 / 255.0 alpha:1.0];
    _CPMenuItemTextShadowColor = [CPColor colorWithCalibratedRed:26.0 / 255.0 green: 73.0 / 255.0 blue:109.0 / 255.0 alpha:1.0];
    
    var bundle = [CPBundle bundleForClass:self];
    
    _CPMenuItemDefaultStateImages[CPOffState]               = nil;
    _CPMenuItemDefaultStateHighlightedImages[CPOffState]    = nil;

    _CPMenuItemDefaultStateImages[CPOnState]               = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPMenuItem/CPMenuItemOnState.png"] size:CGSizeMake(14.0, 14.0)];
    _CPMenuItemDefaultStateHighlightedImages[CPOnState]    = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPMenuItem/CPMenuItemOnStateHighlighted.png"] size:CGSizeMake(14.0, 14.0)];

    _CPMenuItemDefaultStateImages[CPMixedState]             = nil;
    _CPMenuItemDefaultStateHighlightedImages[CPMixedState]  = nil;
}

+ (id)view
{
    return [[self alloc] init];
}

+ (float)_standardLeftMargin
{
    return LEFT_MARGIN + STATE_COLUMN_WIDTH;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _stateView = [[CPImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];

        [_stateView setImageScaling:CPScaleNone];

        [self addSubview:_stateView];

        _imageAndTextView = [[_CPImageAndTextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];

        [_imageAndTextView setImagePosition:CPImageLeft];
        [_imageAndTextView setTextShadowOffset:CGSizeMake(0.0, 1.0)];

        [self addSubview:_imageAndTextView];

        _keyEquivalentView = [[_CPImageAndTextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];

        [_keyEquivalentView setImagePosition:CPNoImage];
        [_keyEquivalentView setTextShadowOffset:CGSizeMake(0.0, 1.0)];
        [_keyEquivalentView setAutoresizingMask:CPViewMinXMargin];

        [self addSubview:_keyEquivalentView];

        _submenuIndicatorView = [[_CPMenuItemSubmenuIndicatorView alloc] initWithFrame:CGRectMake(0.0, 0.0, 8.0, 10.0)];

        [_submenuIndicatorView setColor:SUBMENU_INDICATOR_COLOR];
        [_submenuIndicatorView setAutoresizingMask:CPViewMinXMargin];

        [self addSubview:_submenuIndicatorView];

        [self setAutoresizingMask:CPViewWidthSizable];
    }

    return self;
}

- (CPColor)textColor
{
    if (![_menuItem isEnabled])
        return [CPColor lightGrayColor];

    return _textColor || [CPColor colorWithCalibratedRed:70.0 / 255.0 green:69.0 / 255.0 blue:69.0 / 255.0 alpha:1.0];
}

- (CPColor)textShadowColor
{
    if (![_menuItem isEnabled])
        return nil;

    return _textShadowColor || [CPColor colorWithWhite:1.0 alpha:0.8];
}

- (void)setFont:(CPFont)aFont
{
    _font = aFont;
}

- (void)update
{
    var x = LEFT_MARGIN + [_menuItem indentationLevel] * INDENTATION_WIDTH,
        height = 0.0,
        hasStateColumn = [[_menuItem menu] showsStateColumn];

    if (hasStateColumn)
    {
        [_stateView setHidden:NO];
        [_stateView setImage:_CPMenuItemDefaultStateImages[[_menuItem state]] || nil];

        x += STATE_COLUMN_WIDTH;
    }
    else
        [_stateView setHidden:YES];

    [_imageAndTextView setFont:[_menuItem font] || _font];
    [_imageAndTextView setVerticalAlignment:CPCenterVerticalTextAlignment];
    [_imageAndTextView setImage:[_menuItem image]];
    [_imageAndTextView setText:[_menuItem title]];
    [_imageAndTextView setTextColor:[self textColor]];
    [_imageAndTextView setTextShadowColor:[self textShadowColor]];
    [_imageAndTextView setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [_imageAndTextView sizeToFit];

    var imageAndTextViewFrame = [_imageAndTextView frame];

    imageAndTextViewFrame.origin.x = x;
    x += CGRectGetWidth(imageAndTextViewFrame);
    height = MAX(height, CGRectGetHeight(imageAndTextViewFrame));

    var hasKeyEquivalent = !![_menuItem keyEquivalent],
        hasSubmenu = [_menuItem hasSubmenu];

    if (hasKeyEquivalent || hasSubmenu)
        x += RIGHT_COLUMNS_MARGIN;

    if (hasKeyEquivalent)
    {
        [_keyEquivalentView setFont:[_menuItem font] || _font];
        [_keyEquivalentView setVerticalAlignment:CPCenterVerticalTextAlignment];
        [_keyEquivalentView setImage:[_menuItem image]];
        [_keyEquivalentView setText:[_menuItem keyEquivalentStringRepresentation]];
        [_keyEquivalentView setTextColor:[self textColor]];
        [_keyEquivalentView setTextShadowColor:[self textShadowColor]];
        [_keyEquivalentView setTextShadowOffset:CGSizeMake(0, 1)];
        [_keyEquivalentView setFrameOrigin:CGPointMake(x, VERTICAL_MARGIN)];
        [_keyEquivalentView sizeToFit];
        
        var keyEquivalentViewFrame = [_keyEquivalentView frame];

        keyEquivalentViewFrame.origin.x = x;
        x += CGRectGetWidth(keyEquivalentViewFrame);
        height = MAX(height, CGRectGetHeight(keyEquivalentViewFrame));

        if (hasSubmenu)
            x += RIGHT_COLUMNS_MARGIN;
    }
    else
        [_keyEquivalentView setHidden:YES];

    if (hasSubmenu)
    {
        [_submenuIndicatorView setHidden:NO];

        var submenuViewFrame = [_submenuIndicatorView frame];

        submenuViewFrame.origin.x = x;

        x += CGRectGetWidth(submenuViewFrame);
        height = MAX(height, CGRectGetHeight(submenuViewFrame));
    }
    else
        [_submenuIndicatorView setHidden:YES];

    height += 2.0 * VERTICAL_MARGIN;

    imageAndTextViewFrame.origin.y = FLOOR((height - CGRectGetHeight(imageAndTextViewFrame)) / 2.0);
    [_imageAndTextView setFrame:imageAndTextViewFrame];

    if (hasStateColumn)
        [_stateView setFrameSize:CGSizeMake(STATE_COLUMN_WIDTH, height)];

    if (hasKeyEquivalent)
    {
        keyEquivalentViewFrame.origin.y = FLOOR((height - CGRectGetHeight(keyEquivalentViewFrame)) / 2.0);
        [_keyEquivalentView setFrame:keyEquivalentViewFrame];
    }
    
    if (hasSubmenu)
    {
        submenuViewFrame.origin.y = FLOOR((height - CGRectGetHeight(submenuViewFrame)) / 2.0);
        [_submenuIndicatorView setFrame:submenuViewFrame];
    }

    _minSize = CGSizeMake(x + RIGHT_MARGIN, height);
    
    [self setAutoresizesSubviews:NO];
    [self setFrameSize:_minSize];
    [self setAutoresizesSubviews:YES];
}

- (void)highlight:(BOOL)shouldHighlight
{
    // FIXME: This should probably be even throw.
    if (![_menuItem isEnabled])
        return; 

    if (shouldHighlight)
    {
        [self setBackgroundColor:_CPMenuItemSelectionColor];

        [_imageAndTextView setImage:[_menuItem alternateImage] || [_menuItem image]];
        [_imageAndTextView setTextColor:[CPColor whiteColor]];
        [_keyEquivalentView setTextColor:[CPColor whiteColor]];
        [_submenuIndicatorView setColor:[CPColor whiteColor]];

        [_imageAndTextView setTextShadowColor:_CPMenuItemTextShadowColor];
        [_keyEquivalentView setTextShadowColor:_CPMenuItemTextShadowColor];
    }
    else
    {
        [self setBackgroundColor:nil];

        [_imageAndTextView setImage:[_menuItem image]];
        [_imageAndTextView setTextColor:[self textColor]];
        [_keyEquivalentView setTextColor:[self textColor]];
        [_submenuIndicatorView setColor:SUBMENU_INDICATOR_COLOR];

        [_imageAndTextView setTextShadowColor:[self textShadowColor]];
        [_keyEquivalentView setTextShadowColor:[self textShadowColor]];
    }
    
    if ([[_menuItem menu] showsStateColumn])
    {
        if (shouldHighlight)
            [_stateView setImage:_CPMenuItemDefaultStateHighlightedImages[[_menuItem state]] || nil];
        else
            [_stateView setImage:_CPMenuItemDefaultStateImages[[_menuItem state]] || nil];
    }
}

@end

@implementation _CPMenuItemSubmenuIndicatorView : CPView
{
    CPColor _color;
}

- (void)setColor:(CPColor)aColor
{
    if (_color === aColor)
        return;

    _color = aColor;

    [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds];
    
    CGContextBeginPath(context);
    
    CGContextMoveToPoint(context, CGRectGetMinX(bounds), CGRectGetMinY(bounds));
    CGContextAddLineToPoint(context, CGRectGetMaxX(bounds), CGRectGetMidY(bounds));
    CGContextAddLineToPoint(context, CGRectGetMinX(bounds), CGRectGetMaxY(bounds));
    
    CGContextClosePath(context);
    
    CGContextSetFillColor(context, _color);
    CGContextFillPath(context);
}

@end
