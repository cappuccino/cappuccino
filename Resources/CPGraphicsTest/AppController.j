/*
 * AppController.j
 * CPGraphicsTest
 *
 * Created by Aparajita Fishman on August 23, 2010.
 */

@import <Foundation/CPObject.j>

@implementation AppController : CPObject
{
    @outlet CPWindow        window1;
    @outlet CPWindow        window2;
    @outlet CPWindow        window3;

    @outlet CustomDrawView  view1;
    @outlet CustomDrawView  view2;
    @outlet CustomDrawView  view3;
    @outlet CustomDrawView  view4;

    @outlet CustomDrawView  gradientView0;
    @outlet CustomDrawView  gradientView1;
    @outlet CustomDrawView  gradientView2;
    @outlet CustomDrawView  gradientView3;

    @outlet CustomDrawView pathView0;
    @outlet CustomDrawView pathView1;

    @outlet CustomDrawView linearGradientView;
    @outlet CustomDrawView radialGradientView;
}

- (void)awakeFromCib
{
}

- (void)viewWillDraw:(CPView)aView dirtyRect:(CGRect)dirtyRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        innerRect,
        bounds = [aView bounds];

    var grad0 = aView == gradientView0,
        grad1 = aView == gradientView1,
        grad2 = aView == gradientView2,
        grad3 = aView == gradientView3,
        isGradient = (grad0 || grad1 || grad2 || grad3);

    if (aView == view1 || aView == view2 || aView == view3 || aView == view4)
    {
        if (aView === view1 || aView === view2)
        {
            var bounds = [aView bounds],
                sides = [CPMinYEdge, CPMaxYEdge, CPMinXEdge, CPMaxXEdge],
                grays = [192.0 / 255.0, 1.0, 192.0 / 255.0, 1.0],
                clipRect = [aView bounds];

            if (aView === view2)
            {
                var remainder = CGRectMakeZero();
                CGRectDivide(bounds, clipRect, remainder, CGRectGetWidth(bounds) / 2, CGMinXEdge);
            }

            innerRect = CPDrawTiledRects(bounds, clipRect, sides, grays);
        }
        else if (aView === view3)
        {
            var bounds = [aView bounds],
                sides = [CPMinYEdge, CPMaxYEdge, CPMinXEdge, CPMaxXEdge],
                colors = [[CPColor redColor], [CPColor blueColor], [CPColor whiteColor], [CPColor yellowColor]];

            innerRect = CPDrawColorTiledRects(bounds, bounds, sides, colors);
        }
        else if (aView === view4)
        {
            var bounds = [aView bounds],
                sides = [CPMinYEdge, CPMaxYEdge, CPMinXEdge, CPMaxXEdge,
                         CPMinYEdge, CPMaxYEdge, CPMinXEdge, CPMaxXEdge,
                         CPMinYEdge, CPMaxYEdge, CPMinXEdge, CPMaxXEdge],
                colors = [[CPColor redColor], [CPColor blueColor], [CPColor whiteColor], [CPColor yellowColor],
                          [CPColor redColor], [CPColor blueColor], [CPColor whiteColor], [CPColor yellowColor],
                          [CPColor redColor], [CPColor blueColor], [CPColor whiteColor], [CPColor yellowColor]];

            innerRect = CPDrawColorTiledRects(bounds, bounds, sides, colors);
        }

        CGContextSetFillColor(context, [CPColor colorWithHexString:@"E1EAFF"]);
        CGContextFillRect(context, innerRect);
    }

    if (isGradient)
    {
        var colors,
            gradient;

        if (grad1 || grad3)
        {
            // Draw a pattern for the gradient to blend with.
            strokeGrid(bounds);
        }

        if (grad0)
        {
            var locationsGrad0 = [ 0.0, 0.25, 0.50, 0.75, 1.0 ];
            colors = [CPArray arrayWithObjects:[CPColor blackColor], [CPColor redColor], [CPColor greenColor], [CPColor blueColor], [CPColor whiteColor]];
            gradient = [[CPGradient alloc] initWithColors:colors atLocations:locationsGrad0 colorSpace:[CPColorSpace sRGBColorSpace]];
            [gradient drawInRect:bounds angle:0];
        }
        else if (grad1)
        {
            var mainColor = [CPColor orangeColor],
                locationsGrad1 = [ 0.0, 0.45, 0.56, 1.0 ];
            colors = [CPArray arrayWithObjects:[mainColor colorWithAlphaComponent:0.0], mainColor, mainColor, [mainColor colorWithAlphaComponent:0.0]];
            gradient = [[CPGradient alloc] initWithColors:colors atLocations:locationsGrad1 colorSpace:[CPColorSpace sRGBColorSpace]];
            [gradient drawInRect:bounds angle:90];
        }
        else if (grad2)
        {
            colors = [CPArray arrayWithObjects:[CPColor cyanColor], [CPColor magentaColor], [CPColor yellowColor], [CPColor blackColor]];
            gradient = [[CPGradient alloc] initWithColors:colors];
            [gradient drawInRect:bounds angle:225];
        }
        else
        {
            colors = [CPArray arrayWithObjects:[[CPColor cyanColor] colorWithAlphaComponent:0.5], [CPColor magentaColor], [CPColor clearColor], [CPColor whiteColor]];
            gradient = [[CPGradient alloc] initWithColors:colors];
            [gradient drawInRect:bounds angle:-20];
        }
    }

    if (aView === pathView0)
    {
        [[CPColor whiteColor] set];
        [[CPBezierPath bezierPathWithRect:bounds] fill];

        var aPath = [CPBezierPath bezierPath];

        [aPath moveToPoint:CGPointMake(10.0, 10.0)];
        [aPath lineToPoint:CGPointMake(4 * 10.0, 4 * 10.0)];
        [aPath moveToPoint:CGPointMake(60.0, 50.0)];
        [aPath curveToPoint:CGPointMake(8 * 18.0, 4 * 21.0)
              controlPoint1:CGPointMake(8 * 6.0, 4 * 2.0)
              controlPoint2:CGPointMake(8 * 28.0, 4* 10.0)];

        [aPath appendBezierPathWithRect:CGRectMake(4 * 2.0 + 0.5, 4 * 16.0 + 0.5, 4 * 8.0, 4 * 5.0)];
        [[CPColor blackColor] set];
        [aPath stroke];
    }
    else if (aView === pathView1)
    {
        [[CPColor whiteColor] set];
        [[CPBezierPath bezierPathWithRect:bounds] fill];

        var frame = bounds,
            shadow = [[CPShadow alloc] init];

        [shadow setShadowColor:[CPColor blackColor]];
        [shadow setShadowOffset:CGSizeMake(0, 3)];
        [shadow setShadowBlurRadius:5];

        //// Rounded Rectangle Drawing
        var roundedRectanglePath = [CPBezierPath bezierPathWithRoundedRect:CGRectMake(CGRectGetMinX(frame) + 3.5, CGRectGetMinY(frame) + 3.5, CGRectGetWidth(frame) - 7, CGRectGetHeight(frame) - 7) xRadius:7 yRadius:7];
        [[CPColor blackColor] setStroke];
        [roundedRectanglePath setLineWidth:1];
        var roundedRectanglePattern = [5, 1, 1, 1];
        [roundedRectanglePath setLineDash:roundedRectanglePattern phase:0];
        [roundedRectanglePath stroke];

        var starPath = [CPBezierPath bezierPath];
        [starPath moveToPoint:CGPointMake(CGRectGetMinX(frame) + 0.50000 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.20513 * CGRectGetHeight(frame))];
        [starPath lineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.43029 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.35357 * CGRectGetHeight(frame))];
        [starPath lineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.31200 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.40445 * CGRectGetHeight(frame))];
        [starPath lineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.38720 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.54707 * CGRectGetHeight(frame))];
        [starPath lineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.38381 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.72696 * CGRectGetHeight(frame))];
        [starPath lineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.50000 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.66667 * CGRectGetHeight(frame))];
        [starPath lineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.61619 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.72696 * CGRectGetHeight(frame))];
        [starPath lineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.61280 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.54707 * CGRectGetHeight(frame))];
        [starPath lineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.68800 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.40445 * CGRectGetHeight(frame))];
        [starPath lineToPoint:CGPointMake(CGRectGetMinX(frame) + 0.56971 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.35357 * CGRectGetHeight(frame))];
        [starPath closePath];
        [[CPColor yellowColor] setFill];
        [starPath fill];
        [CPGraphicsContext saveGraphicsState];
        [shadow set];
        [[CPColor whiteColor] setStroke];
        [starPath setLineWidth:3];
        var starPattern = [5, 1, 5, 1];
        [starPath setLineDash:starPattern phase:2];
        [starPath stroke];
        [CPGraphicsContext restoreGraphicsState];
    }
    // else
    else if (aView == linearGradientView)
    {
        var linearRect = dirtyRect,
            gradientColors = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [1, 0, 0, 1 , 0, 0, 1, 1], [0,1], 2);

        CGContextSaveGState(context);
        CGContextAddEllipseInRect(context, linearRect);
        CGContextClip(context);

        var startPoint = CGPointMake(CGRectGetMidX(linearRect), CGRectGetMinY(linearRect)),
            endPoint = CGPointMake(CGRectGetMidX(linearRect), CGRectGetMaxY(linearRect));

        CGContextDrawLinearGradient(context, gradientColors, startPoint, endPoint, 0);
        CGContextRestoreGState(context);
    }
    else if(aView == radialGradientView)
    {
        var gradientRect = dirtyRect,
            gradientColors = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [1, 0, 0, 1 , 0, 0, 1, 1], [0,1], 2);

        CGContextSaveGState(context);
        CGContextAddEllipseInRect(context, gradientRect);
        CGContextClip(context);

        CGContextDrawRadialGradient(context, gradientColors, CGPointMake(CGRectGetMidX(gradientRect), CGRectGetMidY(gradientRect)), 0, CGPointMake(CGRectGetMidX(gradientRect), CGRectGetMidY(gradientRect)), 50,0);
        CGContextRestoreGState(context);
    }
}

@end


@implementation CustomDrawView : CPView
{
    @outlet id _delegate @accessors(property=delegate);
}

- (void)drawRect:(CGRect)dirtyRect
{
    if (_delegate && [_delegate respondsToSelector:@selector(viewWillDraw:dirtyRect:)])
        [_delegate viewWillDraw:self dirtyRect:dirtyRect];
}

@end


function strokeGrid(/* CGRect */ rect)
{
    [CPBezierPath setDefaultLineWidth:1];
    [[CPColor whiteColor] setFill];
    [[[CPColor blueColor] colorWithAlphaComponent:0.5] setStroke];

    var mx = CGRectGetMaxX(rect),
        my = CGRectGetMaxY(rect);

    [CPBezierPath fillRect:rect];

    for (var x = rect.origin.x; x < mx; x += 6)
        [CPBezierPath strokeLineFromPoint:CGPointMake(x + 0.5, rect.origin.y + 0.5) toPoint:CGPointMake(x + 0.5, my - 0.5)];

    for (var y = rect.origin.y; y < my; y += 6)
        [CPBezierPath strokeLineFromPoint:CGPointMake(rect.origin.x + 0.5, y + 0.5) toPoint:CGPointMake(mx - 0.5, y + 0.5)];
}
