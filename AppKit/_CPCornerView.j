
@import "CPView.j"

@implementation _CPCornerView : CPView
{
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setBackgroundColor:[CPColor blueColor]];
    }
    
    return self;
}

@end
