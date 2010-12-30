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

    CGContextSetFillColor(context, [CPColor colorWithHexString:@"E1EAFF"]);
    CGContextFillRect(context, innerRect);
}

@end


@implementation CustomDrawView : CPView
{
    id _delegate @accessors(property=delegate);
}

- (void)drawRect:(CGRect)dirtyRect
{
    if (_delegate && [_delegate respondsToSelector:@selector(viewWillDraw:dirtyRect:)])
        [_delegate viewWillDraw:self dirtyRect:dirtyRect];
}

@end
