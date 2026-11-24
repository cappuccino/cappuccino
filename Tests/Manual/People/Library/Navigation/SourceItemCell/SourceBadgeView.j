/*
 * SourceBadgeView.j
 * People
 *
 * Rounded count badge of a source list item.
 */

@import <AppKit/AppKit.j>

var BadgeFont       = nil,
    BadgeHPadding   = 7.0;

/*
    The height and the minimum width of a badge; the cell view lays the badge out with them.
*/
SourceBadgeHeight   = 16.0;
SourceBadgeMinWidth = 24.0;

@implementation SourceBadgeView : CPView
{
    CPTextField _badgeLabel;
    int         _badgeCount;
    BOOL        _isHighlighted;
}

+ (void)initialize
{
    if (self !== [SourceBadgeView class])
        return;

    BadgeFont = [CPFont boldSystemFontOfSize:11.0];
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        // A plain, inset-free label that is positioned by hand: the text field's
        // own vertical centering includes theme insets and ends up a pixel or two low.
        _badgeLabel = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        [_badgeLabel setFont:BadgeFont];
        [_badgeLabel setAlignment:CPCenterTextAlignment];
        [_badgeLabel setEditable:NO];
        [_badgeLabel setSelectable:NO];
        [_badgeLabel setBezeled:NO];
        [_badgeLabel setBordered:NO];
        [_badgeLabel setDrawsBackground:NO];
        [_badgeLabel setValue:CGInsetMakeZero() forThemeAttribute:@"content-inset"];
        [self addSubview:_badgeLabel];

        [self _updateColors];
    }

    return self;
}

+ (CPString)stringForCount:(int)aCount
{
    // Keep badges compact: 1234 -> "1.2k", 12345 -> "12k"
    if (aCount >= 10000)
        return Math.round(aCount / 1000) + "k";

    if (aCount >= 1000)
        return (Math.round(aCount / 100) / 10) + "k";

    return String(aCount);
}

- (void)setCount:(int)aCount
{
    _badgeCount = aCount;

    var hidden = aCount === CPNotFound || aCount === nil || aCount === undefined;

    [self setHidden:hidden];

    if (!hidden)
    {
        [_badgeLabel setStringValue:[SourceBadgeView stringForCount:aCount]];
        [self _layoutLabel];
    }

    [self setNeedsDisplay:YES];
}

- (void)setSelected:(BOOL)aFlag
{
    if (_isHighlighted === aFlag)
        return;

    _isHighlighted = aFlag;
    [self _updateColors];
    [self setNeedsDisplay:YES];
}

- (float)preferredWidth
{
    var size = [[_badgeLabel stringValue] sizeWithFont:BadgeFont];
    return MAX(SourceBadgeMinWidth, Math.ceil(size.width) + 2 * BadgeHPadding);
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    [self _layoutLabel];
}

- (void)_layoutLabel
{
    var bounds = [self bounds],
        textHeight = Math.ceil([[_badgeLabel stringValue] sizeWithFont:BadgeFont].height);

    [_badgeLabel setFrame:CGRectMake(0, Math.round((CGRectGetHeight(bounds) - textHeight) / 2), CGRectGetWidth(bounds), textHeight)];
}

- (void)_updateColors
{
    [_badgeLabel setTextColor:_isHighlighted ? [CPColor controlAccentColor] : [CPColor alternateSelectedControlTextColor]];
}

- (void)drawRect:(CGRect)aRect
{
    var bounds = [self bounds],
        radius = CGRectGetHeight(bounds) / 2,
        path = [CPBezierPath bezierPath];

    [path appendBezierPathWithRoundedRect:bounds xRadius:radius yRadius:radius];

    [(_isHighlighted ? [CPColor alternateSelectedControlTextColor] : [CPColor systemGrayColor]) set];
    [path fill];
}

@end
