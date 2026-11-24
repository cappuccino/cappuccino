/*
 * SourceIconView.j
 * People
 *
 * Small vector icon of a source list item, drawn with CPBezierPath.
 */

@import <AppKit/AppKit.j>

@implementation SourceIconView : CPView
{
    CPString    _iconKind;
    BOOL        _isHighlighted;
}

- (void)setKind:(CPString)aKind
{
    if (_iconKind === aKind)
        return;

    _iconKind = aKind;
    [self setNeedsDisplay:YES];
}

- (void)setSelected:(BOOL)aFlag
{
    if (_isHighlighted === aFlag)
        return;

    _isHighlighted = aFlag;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)aRect
{
    var bounds = [self bounds],
        w = CGRectGetWidth(bounds),
        h = CGRectGetHeight(bounds);

    if (_iconKind === @"all")
    {
        var color = _isHighlighted ? [CPColor alternateSelectedControlTextColor] : [CPColor controlAccentColor],
            head = [CPBezierPath bezierPath],
            body = [CPBezierPath bezierPath];

        [color set];
        [head appendBezierPathWithOvalInRect:CGRectMake(w / 2 - 3.5, 1.5, 7, 7)];
        [head fill];
        [body appendBezierPathWithRoundedRect:CGRectMake(w / 2 - 6.5, 9.5, 13, 6) xRadius:3 yRadius:3];
        [body fill];
        return;
    }

    // Folder shape for groups and smart folders.
    var fill = _isHighlighted ? [CPColor alternateSelectedControlTextColor] :
               (_iconKind === @"smart" ? [CPColor systemPurpleColor] : [CPColor controlAccentColor]),
        folder = [CPBezierPath bezierPath];

    [folder moveToPoint:CGPointMake(1, 3)];
    [folder lineToPoint:CGPointMake(6, 3)];
    [folder lineToPoint:CGPointMake(8, 5)];
    [folder lineToPoint:CGPointMake(w - 1, 5)];
    [folder lineToPoint:CGPointMake(w - 1, h - 2)];
    [folder lineToPoint:CGPointMake(1, h - 2)];
    [folder closePath];

    [fill set];
    [folder fill];

    if (_iconKind === @"smart")
    {
        // Gear-ish dot to distinguish smart folders.
        var mark = [CPBezierPath bezierPath],
            markColor = _isHighlighted ? [CPColor systemPurpleColor] : [CPColor alternateSelectedControlTextColor];

        [markColor set];
        [mark appendBezierPathWithOvalInRect:CGRectMake(w / 2 - 2.5, 7.5, 5, 5)];
        [mark fill];
    }
}

@end
