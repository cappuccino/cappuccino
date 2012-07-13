
@import <AppKit/CPControl.j>

@import "_CPMenuItemSeparatorView.j"
@import "_CPMenuItemStandardView.j"
@import "_CPMenuItemMenuBarView.j"


var LEFT_MARGIN                 = 3.0,
    RIGHT_MARGIN                = 16.0,
    STATE_COLUMN_WIDTH          = 14.0,
    INDENTATION_WIDTH           = 17.0,
    VERTICAL_MARGIN             = 4.0;

var _CPMenuItemSelectionColor                   = nil,
    _CPMenuItemTextShadowColor                  = nil,

    _CPMenuItemDefaultStateImages               = [],
    _CPMenuItemDefaultStateHighlightedImages    = [];

/*
    @ignore
*/
@implementation _CPMenuItemView : CPView
{
    CPMenuItem              _menuItem;
    CPView                  _view;

    CPFont                  _font;
    CPColor                 _textColor;
    CPColor                 _textShadowColor;

    CGSize                  _minSize;
    BOOL                    _isDirty;
    BOOL                    _showsStateColumn;

    _CPImageAndTextView     _imageAndTextView;
    CPView                  _submenuView;
}

+ (void)initialize
{
    if (self !== [_CPMenuItemView class])
        return;

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

+ (float)leftMargin
{
    return LEFT_MARGIN + STATE_COLUMN_WIDTH;
}

- (id)initWithFrame:(CGRect)aFrame forMenuItem:(CPMenuItem)aMenuItem
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _menuItem = aMenuItem;
        _showsStateColumn = YES;
        _isDirty = YES;

        [self setAutoresizingMask:CPViewWidthSizable];

        [self synchronizeWithMenuItem];
    }

    return self;
}

- (CGSize)minSize
{
    return _minSize;
}

- (void)setDirty
{
    _isDirty = YES;
}

- (void)synchronizeWithMenuItem
{
    var menuItemView = [_menuItem view];

    if ([_menuItem isSeparatorItem])
    {
        if (![_view isKindOfClass:[_CPMenuItemSeparatorView class]])
        {
            [_view removeFromSuperview];
            _view = [_CPMenuItemSeparatorView view];
        }
    }
    else if (menuItemView)
    {
        if (_view !== menuItemView)
        {
            [_view removeFromSuperview];
            _view = menuItemView;
        }
    }

    else if ([_menuItem menu] == [CPApp mainMenu])
    {
        if (![_view isKindOfClass:[_CPMenuItemMenuBarView class]])
        {
            [_view removeFromSuperview];
            _view = [_CPMenuItemMenuBarView view];
        }

        [_view setMenuItem:_menuItem];
    }
    else
    {
        if (![_view isKindOfClass:[_CPMenuItemStandardView class]])
        {
            [_view removeFromSuperview];
            _view = [_CPMenuItemStandardView view];
        }

        [_view setMenuItem:_menuItem];
    }

    if ([_view superview] !== self)
        [self addSubview:_view];

    if ([_view respondsToSelector:@selector(update)])
        [_view update];

    _minSize = [_view frame].size;
    [self setAutoresizesSubviews:NO];
    [self setFrameSize:_minSize];
    [self setAutoresizesSubviews:YES];
}

- (void)setShowsStateColumn:(BOOL)shouldShowStateColumn
{
    _showsStateColumn = shouldShowStateColumn;
}

- (void)highlight:(BOOL)shouldHighlight
{
    if ([_view respondsToSelector:@selector(highlight:)])
        [_view highlight:shouldHighlight];
}

- (BOOL)eventOnSubmenu:(CPEvent)anEvent
{
    if (![_menuItem hasSubmenu])
        return NO;

    return CGRectContainsPoint([_submenuView frame], [self convertPoint:[anEvent locationInWindow] fromView:nil]);
}

- (BOOL)isHidden
{
    return [_menuItem isHidden];
}

- (CPMenuItem)menuItem
{
    return _menuItem;
}

- (void)setFont:(CPFont)aFont
{
    if ([_font isEqual:aFont])
        return;

    _font = aFont;

    if ([_view respondsToSelector:@selector(setFont:)])
        [_view setFont:aFont];

    [self setDirty];
}

- (void)setTextColor:(CPColor)aColor
{
    if (_textColor == aColor)
        return;

    _textColor = aColor;

    [_imageAndTextView setTextColor:[self textColor]];
    [_submenuView setColor:[self textColor]];
}

- (CPColor)textColor
{
    return nil;
}

- (void)setTextShadowColor:(CPColor)aColor
{
    if (_textShadowColor == aColor)
        return;

    _textShadowColor = aColor;

    [_imageAndTextView setTextShadowColor:[self textShadowColor]];
    //[_submenuView setColor:[self textColor]];
}

- (CPColor)textShadowColor
{
    return [_menuItem isEnabled] ? (_textShadowColor ? _textShadowColor : [CPColor colorWithWhite:1.0 alpha:0.8]) : [CPColor colorWithWhite:0.8 alpha:0.8];
}

@end

@implementation _CPMenuItemArrowView : CPView
{
    CPColor _color;
}

- (void)setColor:(CPColor)aColor
{
    if (_color == aColor)
        return;

    _color = aColor;

    [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextBeginPath(context);

    CGContextMoveToPoint(context, 1.0, 4.0);
    CGContextAddLineToPoint(context, 9.0, 4.0);
    CGContextAddLineToPoint(context, 5.0, 8.0);
    CGContextAddLineToPoint(context, 1.0, 4.0);

    CGContextClosePath(context);

    CGContextSetFillColor(context, _color);
    CGContextFillPath(context);
}

@end
