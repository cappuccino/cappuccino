@import "CPView.j"

@implementation _CPCornerView : CPView
{
}

+ (CPString)themeClass
{
    return @"cornerview";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[[CPNull null]]
                                       forKeys:[@"background-color"]];
}

- (void)layoutSubviews
{
    [self setBackgroundColor:[self currentValueForThemeAttribute:@"background-color"]];
}

- (void)_init
{
    [self setBackgroundColor:[self currentValueForThemeAttribute:@"background-color"]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame]
    
    if (self)
        [self _init];

    return self;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
        [self _init];

    return self;
}

@end
