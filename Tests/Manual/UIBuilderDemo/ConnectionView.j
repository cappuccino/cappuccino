
@import <Foundation/CPObject.j>

function treshold(value, limit)
{
    return value > 0 ? Math.min(value, limit) : Math.max(value, -limit);
}

@implementation ConnectionView : CPView
{
    CGPoint _startPoint;
    CGPoint _endPoint;
    CPColor _color;
}

- (id)initWithFrame:(CGRect)aRect
{
    self = [super initWithFrame:aRect];
    if (self)
    {
        [self setBackgroundColor:[CPColor clearColor]];
        _color = [CPColor redColor];
        [self setHidden:YES]; // Hidden by default
    }
    return self;
}

- (void)setStartPoint:(CGPoint)startPoint { _startPoint = startPoint; }
- (void)setEndPoint:(CGPoint)endPoint { _endPoint = endPoint; }
- (void)setColor:(CPColor)color { _color = color; }

- (void)drawRect:(CGRect)rect
{
    console.log("ConnectionView: drawRect - Drawing connection from ", _startPoint, " to ", _endPoint);
    if (_startPoint && _endPoint)
    {
        [self drawLinkFrom:_startPoint to:_endPoint color:_color];
    }
}

- (void)drawLinkFrom:(CGPoint)startPoint to:(CGPoint)endPoint color:(CPColor)insideColor
{
    var dist = Math.sqrt(Math.pow(startPoint.x - endPoint.x, 2) + Math.pow(startPoint.y - endPoint.y, 2));
    var p0 = CGPointMake(startPoint.x, startPoint.y);
    var p3 = CGPointMake(endPoint.x, endPoint.y);
    var p1 = CGPointMake(startPoint.x + treshold((endPoint.x - startPoint.x) / 2, 50), startPoint.y);
    var p2 = CGPointMake(endPoint.x -   treshold((endPoint.x - startPoint.x) / 2, 50), endPoint.y);
    var path = [CPBezierPath bezierPath];
    [path setLineWidth:0];
    [[CPColor grayColor] set];
    [path appendBezierPathWithOvalInRect:CGRectMake(startPoint.x-2.5,startPoint.y-2.5,5,5)];
    [path fill];
    path = [CPBezierPath bezierPath];
    [path setLineWidth:0];
    [insideColor set];
    [path appendBezierPathWithOvalInRect:CGRectMake(startPoint.x-1.5,startPoint.y-1.5,3,3)];
    [path fill];
    path = [CPBezierPath bezierPath];
    [path setLineWidth:0];
    [[CPColor grayColor] set];
    [path appendBezierPathWithOvalInRect:CGRectMake(endPoint.x-2.5,endPoint.y-2.5,5,5)];
    [path fill];
    path = [CPBezierPath bezierPath];
    [path setLineWidth:0];
    [insideColor set];
    [path appendBezierPathWithOvalInRect:CGRectMake(endPoint.x-1.5,endPoint.y-1.5,3,3)];
    [path fill];
    if (dist < 40)
    {
        path = [CPBezierPath bezierPath];
        [path setLineWidth:5];
        [path moveToPoint:startPoint];
        [path lineToPoint:endPoint];
        [[CPColor grayColor] set];
        [path stroke];
        path = [CPBezierPath bezierPath];
        [path setLineWidth:3];
        [path moveToPoint:startPoint];
        [path lineToPoint:endPoint];
        [insideColor set];
        [path stroke];
        return;
    }
    path = [CPBezierPath bezierPath];
    [path setLineWidth:5];
    [path moveToPoint:p0];
    [path curveToPoint:p3 controlPoint1:p1 controlPoint2:p2];
    [[CPColor grayColor] set];
    [path stroke];
    path = [CPBezierPath bezierPath];
    [path setLineWidth:3];
    [path moveToPoint:p0];
    [path curveToPoint:p3 controlPoint1:p1 controlPoint2:p2];
    [insideColor set];
    [path stroke];
}
@end
