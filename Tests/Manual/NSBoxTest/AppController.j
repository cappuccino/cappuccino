/*
 * AppController.j
 * CPButtonImageTest
 *
 * Created by Aparajita Fishman on August 31, 2010.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
    @outlet CPBox       customDrawBox;
    @outlet CPBox       standardBox;
    @outlet CPBox       customBox;
    @outlet CPView      dynamicBox;
    @outlet CPTextField dynamicLabel;

    CPImageView imageView;
    CPView      labelView;
}

- (void)awakeFromCib
{
    var image = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[CPView class]] pathForResource:@"standardApplicationIcon.png"]];

    imageView = [[CPImageView alloc] initWithFrame:[dynamicBox frame]];
    [imageView setImage:image];

    var box = [[CPBox alloc] initWithFrame:[dynamicBox frame]];

    [box setBorderType:CPLineBorder];
    [box setBorderWidth:4];
    [box setBorderColor:[CPColor colorWithHexString:@"00990E"]];
    [box setFillColor:[CPColor whiteColor]];

    labelView = [[CPView alloc] initWithFrame:[box frame]];
    [labelView setAutoresizesSubviews:NO];

    var label = [CPTextField labelWithTitle:@"Dynamic box"];

    [label setFrame:[dynamicLabel frame]];
    [label setAutoresizingMask:CPViewNotSizable];
    [label setAlignment:CPCenterTextAlignment];
    [labelView addSubview:label];

    [box setContentView:labelView];
    [box setAutoresizingMask:CPViewMinXMargin | CPViewHeightSizable];

    [[dynamicBox superview] replaceSubview:dynamicBox with:box];
    dynamicBox = box;
}

- (void)changeFillColor:(id)sender
{
    [customDrawBox setFillColor:[CPColor randomColor]];
}

- (void)changeBorderWidth:(id)sender
{
    [standardBox setBorderWidth:ROUND(RAND() * 7)];
}

- (void)changeBorderColor:(id)sender
{
    [customBox setBorderColor:[CPColor randomColor]];
    [customBox setCornerRadius:ROUND(RAND() * 10)];
}

- (void)changeContentView:(id)sender
{
    var contentView = [dynamicBox contentView];

    [dynamicBox setContentView:contentView === labelView ? imageView : labelView];
}

@end

@implementation BezelView : CPBox

- (void)drawRect:(CGRect)dirtyRect
{
    var sides = [CPMinYEdge, CPMaxYEdge, CPMinXEdge, CPMaxXEdge],
        grays = [0.75, 1.0, 0.75, 1.0],
        fillRect = CPDrawTiledRects(dirtyRect, dirtyRect, sides, grays),
        context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetFillColor(context, [self fillColor]);
    CGContextFillRect(context, fillRect);
}

@end
