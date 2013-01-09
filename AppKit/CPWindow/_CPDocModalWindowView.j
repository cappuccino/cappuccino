
@import "_CPWindowView.j"

var _CPStandardWindowViewBodyBackgroundColor = nil;

@implementation _CPDocModalWindowView : _CPWindowView
{
    CPView _bodyView;
    CPView _shadowView;
}

+ (CPString)defaultThemeClass
{
    return @"doc-modal-window-view";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[[CPColor whiteColor], [CPNull null], 8]
                                       forKeys:[ @"body-color", @"attached-sheet-shadow-color", @"height-shadow"]];
}

+ (CPColor)bodyBackgroundColor
{
    if (!_CPStandardWindowViewBodyBackgroundColor)
        _CPStandardWindowViewBodyBackgroundColor = [CPColor colorWithWhite:0.96 alpha:0.9];

    return _CPStandardWindowViewBodyBackgroundColor;
}

- (id)initWithFrame:(CPRect)aFrame styleMask:(unsigned)aStyleMask
{
    self = [super initWithFrame:aFrame styleMask:aStyleMask];

    if (self)
    {
        var bounds = [self bounds];

       _bodyView = [[CPView alloc] initWithFrame:_CGRectMake(0.0, 0.0, _CGRectGetWidth(bounds), _CGRectGetHeight(bounds))];

        [_bodyView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [_bodyView setHitTests:NO];

        [self addSubview:_bodyView];

        _shadowView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, _CGRectGetWidth(bounds), [self valueForThemeAttribute:@"height-shadow"])];
        [_shadowView setAutoresizingMask:CPViewWidthSizable];
        [self addSubview:_shadowView];
     }

    return self;
}

- (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    return aFrameRect;
}

- (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    return aContentRect;
}

- (void)_enableSheet:(BOOL)enable
{
    // do nothing, already a sheet
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    var bounds = [self bounds];

    [_bodyView setBackgroundColor:[self valueForThemeAttribute:@"body-color"]];

    [_shadowView setFrame:CGRectMake(0,0, _CGRectGetWidth(bounds), [self valueForThemeAttribute:@"height-shadow"])];
    [_shadowView setBackgroundColor:[self valueForThemeAttribute:@"attached-sheet-shadow-color"]];
}

@end

