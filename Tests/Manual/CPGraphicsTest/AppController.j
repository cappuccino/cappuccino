/*
 * AppController.j
 * CPGraphicsTest
 *
 * Created by Aparajita Fishman on August 23, 2010.
 */

@import <Foundation/CPObject.j>

@implementation AppController : CPObject
{
    CPWindow                theWindow;

    @outlet CustomDrawView  view1;
    @outlet CustomDrawView  view2;
    @outlet CustomDrawView  view3;
    @outlet CustomDrawView  view4;

    @outlet CustomDrawView  gradientView0;
    @outlet CustomDrawView  gradientView1;
    @outlet CustomDrawView  gradientView2;
    @outlet CustomDrawView  gradientView3;
}

- (void)awakeFromCib
{
}

- (void)viewWillDraw:(CPView)aView dirtyRect:(CGRect)dirtyRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        innerRect;

    var grad0 = aView == gradientView0,
        grad1 = aView == gradientView1,
        grad2 = aView == gradientView2,
        grad3 = aView == gradientView3,
        isGradient = (grad0 || grad1 || grad2 || grad3);

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
    else if (isGradient)
    {
        var bounds = [aView bounds],
            colors,
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

    if (!isGradient)
    {
        CGContextSetFillColor(context, [CPColor colorWithHexString:@"E1EAFF"]);
        CGContextFillRect(context, innerRect);
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
