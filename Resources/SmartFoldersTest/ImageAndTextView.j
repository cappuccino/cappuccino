
@implementation ImageAndTextView : _CPImageAndTextView
{
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self _initShared];
    }

    return self;
}

- (void)_initShared
{
    //[self setLineBreakMode:CPLineBreakByTruncatingTail];
    [self setImagePosition:CPImageLeft];
    [self setAlignment:CPLeftTextAlignment];
    [self setVerticalAlignment:CPCenterVerticalTextAlignment];
}

- (id)initWithCoder:(CPCoder)coder
{
    self = [super initWithCoder:coder];
    [self _initShared];

    return self;
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [super encodeWithCoder:coder];
}

- (id)objectValue
{
    return [self text];
}

- (void)setObjectValue:(id)value
{
    [self setText:value];
}

- (void)setThemeState:(ThemeState)state
{
    if (state === CPThemeStateSelectedDataView)
    {
        [self setTextColor:[CPColor whiteColor]];
        [self setFont:[CPFont boldSystemFontOfSize:13]];
    }

    [super setThemeState:state];
}

- (void)unsetThemeState:(ThemeState)state
{
    if (state === CPThemeStateSelectedDataView)
    {
        [self setTextColor:[CPColor colorWithWhite:0.3  alpha:1]];
        [self setFont:[CPFont systemFontOfSize:13]];
    }

    [super unsetThemeState:state];
}
@end

