var LEFT_MARGIN                 = 5.0,
    RIGHT_MARGIN                = 5.0,
    SUBMENU_INDICATOR_MARGIN    = 5.0,
    VERTICAL_MARGIN             = 4.0;

var SUBMENU_INDICATOR_COLOR                     = nil,
    _CPMenuItemSelectionColor                   = nil,
    _CPMenuItemTextShadowColor                  = nil,
    
    _CPMenuItemDefaultStateImages               = [],
    _CPMenuItemDefaultStateHighlightedImages    = [];

@implementation _CPMenuItemMenuBarView : CPView
{
    CPMenuItem              _menuItem @accessors(property=menuItem);

    CPFont                  _font;
    CPColor                 _textColor;
    CPColor                 _textShadowColor;

    BOOL                    _isDirty;

    _CPImageAndTextView     _imageAndTextView;
    CPView                  _submenuIndicatorView;
}

+ (void)initialize
{
    if (self !== [_CPMenuItemStandardView class])
        return;

    SUBMENU_INDICATOR_COLOR = [CPColor grayColor];

    _CPMenuItemSelectionColor =  [CPColor colorWithCalibratedRed:95.0 / 255.0 green:131.0 / 255.0 blue:185.0 / 255.0 alpha:1.0];
    _CPMenuItemTextShadowColor = [CPColor colorWithCalibratedRed:26.0 / 255.0 green: 73.0 / 255.0 blue:109.0 / 255.0 alpha:1.0]
    
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

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _imageAndTextView = [[_CPImageAndTextView alloc] initWithFrame:CGRectMake(LEFT_MARGIN, 0.0, 0.0, 0.0)];

        [_imageAndTextView setImagePosition:CPImageLeft];
        [_imageAndTextView setTextShadowOffset:CGSizeMake(0.0, 1.0)];
        [_imageAndTextView setAutoresizingMask:CPViewMinYMargin | CPViewMaxYMargin];

        [self addSubview:_imageAndTextView];

        _submenuIndicatorView = [[_CPMenuItemMenuBarSubmenuIndicatorView alloc] initWithFrame:CGRectMake(0.0, 0.0, 9.0, 6.0)];

        [_submenuIndicatorView setAutoresizingMask:CPViewMinYMargin | CPViewMaxYMargin];

        [self addSubview:_submenuIndicatorView];

        [self setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
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
        return [CPColor colorWithWhite:0.8 alpha:0.8];

    return _textShadowColor || [CPColor colorWithWhite:1.0 alpha:0.8];
}

- (void)update
{
    var x = LEFT_MARGIN,
        height = 0.0;

    [_imageAndTextView setFont:[_menuItem font] || _font];
    [_imageAndTextView setVerticalAlignment:CPCenterVerticalTextAlignment];
    [_imageAndTextView setImage:[_menuItem image]];
    [_imageAndTextView setText:[_menuItem title]];
    [_imageAndTextView setTextColor:[self textColor]];
    [_imageAndTextView setTextShadowColor:[self textShadowColor]];
    [_imageAndTextView setTextShadowOffset:CGSizeMake(0, 1)];
    [_imageAndTextView sizeToFit];

    var imageAndTextViewFrame = [_imageAndTextView frame];

    imageAndTextViewFrame.origin.x = x;
    x += CGRectGetWidth(imageAndTextViewFrame);
    height = MAX(height, CGRectGetHeight(imageAndTextViewFrame));

    var hasSubmenuIndicator = [_menuItem hasSubmenu] && [_menuItem action];

    if (hasSubmenuIndicator)
    {
        [_submenuIndicatorView setHidden:NO];

        var submenuViewFrame = [_submenuIndicatorView frame];

        submenuViewFrame.origin.x = x + SUBMENU_INDICATOR_MARGIN;

        x += CGRectGetWidth(submenuViewFrame);
        height = MAX(height, CGRectGetHeight(submenuViewFrame));
    }
    else
        [_submenuIndicatorView setHidden:YES];

    height += 2.0 * VERTICAL_MARGIN;

    imageAndTextViewFrame.origin.y = FLOOR((height - CGRectGetHeight(imageAndTextViewFrame)) / 2.0);
    [_imageAndTextView setFrame:imageAndTextViewFrame];
    
    if (hasSubmenuIndicator)
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

        [_imageAndTextView setTextColor:[CPColor whiteColor]];
        [_imageAndTextView setTextShadowColor:_CPMenuItemTextShadowColor];
    }
    else
    {
        [self setBackgroundColor:nil];
        
        [_imageAndTextView setTextColor:[self textColor]];
        [_imageAndTextView setTextShadowColor:[self textShadowColor]];
    }
}

@end

@implementation _CPMenuItemMenuBarSubmenuIndicatorView : CPView
{
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds];
    
    bounds.origin.y += 1.0;
    bounds.size.height -= 1.0;

    // Draw Inset
    CGContextBeginPath(context);
    
    CGContextMoveToPoint(context, CGRectGetMinX(bounds), CGRectGetMinY(bounds));
    CGContextAddLineToPoint(context, CGRectGetMidX(bounds), CGRectGetMaxY(bounds));
    CGContextAddLineToPoint(context, CGRectGetMaxX(bounds), CGRectGetMinY(bounds));
    
    CGContextClosePath(context);
    
    CGContextSetStrokeColor(context, [CPColor colorWithWhite:1.0 alpha:0.3]);
    CGContextStrokePath(context);

    bounds.size.width -= 2.0;
    bounds.origin.x += 1.0;
    bounds.origin.y -= 1.0;

    CGContextBeginPath(context);
    
    CGContextMoveToPoint(context, CGRectGetMinX(bounds), CGRectGetMinY(bounds));
    CGContextAddLineToPoint(context, CGRectGetMaxX(bounds), CGRectGetMinY(bounds));
    CGContextAddLineToPoint(context, CGRectGetMidX(bounds), CGRectGetMaxY(bounds));
    
    CGContextClosePath(context);
    
    CGContextSetFillColor(context, [CPColor colorWithWhite:0.1 alpha:0.7]);
    CGContextFillPath(context);

    CGContextSetStrokeColor(context, [CPColor colorWithWhite:0.1 alpha:0.1]);

    // Top dark inset
    CGContextBeginPath(context);

    CGContextMoveToPoint(context, CGRectGetMinX(bounds), CGRectGetMinY(bounds) + 0.5);
    CGContextAddLineToPoint(context, CGRectGetMaxX(bounds), CGRectGetMinY(bounds) + 0.5);

    CGContextClosePath(context);
    CGContextStrokePath(context);
}

@end
