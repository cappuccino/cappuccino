
@import "_CPWindowView.j"

var _CPStandardWindowViewBodyBackgroundColor = nil;

@implementation _CPDocModalWindowView : _CPWindowView
{
    CPView _bodyView;
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
        
       _bodyView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), CGRectGetHeight(bounds))];
        
        [_bodyView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [_bodyView setBackgroundColor:[theClass bodyBackgroundColor]];
        [_bodyView setHitTests:NO];
        
        [self addSubview:_bodyView];
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

@end