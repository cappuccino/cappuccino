
@import "CPView.j"

@implementation _CPCornerView : CPView
{
}

- (void)_init
{
    [self setBackgroundColor:[CPColor colorWithPatternImage:CPAppKitImage("tableview-headerview.png", CGSizeMake(1.0, 23.0))]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self _init];
    }

    return self;
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetStrokeColor(context, [CPColor colorWithHexString:@"dce0e2"]);

    var points = [
                    CGPointMake(aRect.origin.x, aRect.origin.y + 0.5), 
                    CGPointMake(aRect.origin.x, aRect.origin.y + aRect.size.height)
                 ];

    CGContextStrokeLineSegments(context, points, 2);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    {
        [self _init];
    }

    return self;
}

@end
