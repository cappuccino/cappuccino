
@import "_CPWindowView.j"

var _CPStandardWindowViewBodyBackgroundColor = nil;

@implementation _CPDocModalWindowView : _CPWindowView
{
    CPView _bodyView;
    CPView _shadowView;
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
        var theClass = [self class],
            bounds = [self bounds];

       _bodyView = [[CPView alloc] initWithFrame:_CGRectMake(0.0, 0.0, _CGRectGetWidth(bounds), _CGRectGetHeight(bounds))];

        [_bodyView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [_bodyView setBackgroundColor:[theClass bodyBackgroundColor]];
        [_bodyView setHitTests:NO];

        [self addSubview:_bodyView];

        var bundle = [CPBundle bundleForClass:[CPWindow class]];
        _shadowView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, _CGRectGetWidth(bounds), 8)];
        [_shadowView setAutoresizingMask:CPViewWidthSizable];
        [_shadowView setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/CPWindowAttachedSheetShadow.png"] size:CGSizeMake(9,8)]]];
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

@end

