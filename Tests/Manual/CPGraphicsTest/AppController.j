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
}

- (void)awakeFromCib
{
    [view1 setDelegate:self];
    [view2 setDelegate:self];
    [view3 setDelegate:self];
    [view4 setDelegate:self];
}

- (void)viewWillDraw:(CPView)aView dirtyRect:(CGRect)dirtyRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        innerRect;

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
    else if (aView === gradientView0 || aView === gradientView1)
    {
        var bounds = [aView bounds],
            locations,
            colors;

        if (aView === gradientView0)
        {
            locations = [0.0, 0.25, 0.50, 0.75, 1.0];
            colors = [[CPColor blackColor], [CPColor redColor], [CPColor greenColor], [CPColor blueColor], [CPColor whiteColor]];
        }
        else
        {
            locations = [0.0, 0.35, 0.66, 1.0];
            var mainColor = [CPColor blackColor];
            colors = [[mainColor colorWithAlphaComponent:0.0], mainColor, mainColor, [mainColor colorWithAlphaComponent:0.0]];
        }

        var gradient = [[CPGradient alloc] initWithColors:colors atLocations:locations colorSpace:[CPColorSpace sRGBColorSpace]];
        [gradient drawInRect:bounds angle:0];
    }

    if (!(aView === gradientView0 || aView === gradientView1))
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
