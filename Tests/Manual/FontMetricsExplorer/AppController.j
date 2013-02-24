/*
 * AppController.j
 * CPFontMetricsExplorer
 *
 * Created by Aparajita Fishman on August 23, 2010.
 */

@import <Foundation/CPObject.j>

CPLogRegister(CPLogConsole);


var Ascender    = 0,
    Descender   = 0,
    LineHeight  = 0;

var GridSize = 9.0;

var SharedAppController = nil;


@implementation AppController : CPObject
{
    CPWindow                theWindow;

    @outlet CPPopUpButton   fontMenu;
    @outlet CPSlider        sizeSlider;
    @outlet CPTextField     sizeText;
    @outlet CPTextField     ascenderText;
    @outlet CPTextField     descenderText;
    @outlet CPTextField     lineHeightText;
    @outlet MetricsView     metricsView @accessors(readonly);
    @outlet BaselineView    baselineView @accessors(readonly);
}

- (void)awakeFromCib
{
    SharedAppController = self;

    var fonts = [[CPFontManager sharedFontManager] availableFonts],
        systemFont = [CPFont systemFontOfSize:12],
        family = [systemFont familyName],
        names = family.split(/,\s*/),
        index = CPNotFound;

    for (var i = 0; i < names.length; ++i)
    {
        index = [fonts indexOfObjectPassingTest:function(elem, index, context) { return elem === context; } context:names[i]];

        if (index !== CPNotFound)
            break;
    }

    [fontMenu removeAllItems];
    [fontMenu addItemsWithTitles:fonts];
    [fontMenu selectItemAtIndex:index !== CPNotFound ? index : 0];

    [sizeText takeIntegerValueFrom:sizeSlider];

    [self update];
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
}

- (void)setFontFamily:(id)sender
{
    [self update];
}

- (void)setFontSize:(id)sender
{
    [self update];
}

- (void)update
{
    var font = [CPFont fontWithName:[fontMenu titleOfSelectedItem] size:[sizeSlider integerValue]];

    Ascender = [font ascender],
    Descender = [font descender],
    LineHeight = [font defaultLineHeightForFont];

    [sizeText takeIntegerValueFrom:sizeSlider];
    [ascenderText setIntegerValue:Ascender];
    [descenderText setIntegerValue:Descender];
    [lineHeightText setIntegerValue:LineHeight];

    [metricsView updateWithFont:font];
}

@end


@implementation MetricsView : CPView
{
    @outlet CPTextField     sampleText;

    CPColor gridColor;
}

- (id)initWithFrame:(CGRect)aRect
{
    var self = [super initWithFrame:aRect];

    if (self)
        gridColor = [CPColor colorWithHexString:@"e4f4ff"];

    return self;
}

- (void)awakeFromCib
{
    [self setBackgroundColor:[CPColor whiteColor]];
}

- (void)drawRect:(CGRect)dirtyRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds],
        maxX = CGRectGetMaxX(bounds),
        maxY = CGRectGetMaxY(bounds);

    CGContextSetLineWidth(context, 1.0);
    CGContextSetStrokeColor(context, gridColor);
    CGContextBeginPath(context);

    for (var y = 0.5; y <= maxY; y += GridSize)
    {
        CGContextMoveToPoint(context, 0.0, y);
        CGContextAddLineToPoint(context, maxX, y);
    }

    for (var x = 0.5; x <= maxX; x += GridSize)
    {
        CGContextMoveToPoint(context, x, 0.0);
        CGContextAddLineToPoint(context, x, maxY);
    }

    CGContextStrokePath(context);
}

- (void)updateWithFont:(CPFont)aFont
{
    var frame = [sampleText frame],
        ascender = [aFont ascender],
        descender = [aFont descender],
        lineHeight = [aFont defaultLineHeightForFont],
        insets = [sampleText currentValueForThemeAttribute:@"content-inset"],
        frameSize = CGSizeMake(CGRectGetWidth(frame), insets.top + lineHeight + insets.bottom),

        // Place the label so that the baseline is at the 7th line (y == 63)
        textTop = 63.0 - ascender - insets.top;

    [sampleText setFont:aFont];
    [sampleText setFrame:CGRectMake(CGRectGetMinX(frame), textTop, frameSize.width, frameSize.height)];

    [[SharedAppController baselineView] updateWithText:sampleText ascender:ascender descender:descender];
}

- (void)setSampleText
{
    var text = prompt("Enter the text to display:", [sampleText stringValue]);

    if (text)
        [sampleText setStringValue:text];
}

@end


@implementation BaselineView : CPView
{
    float textTop;
    float ascender;
    float descender;
    float lineHeight;
}

- (id)initWithFrame:(CGRect)frame
{
    var self = [super initWithFrame:frame];

    if (self)
    {
        textTop = 0;
        ascender = 0;
        lineHeight = 0;
    }

    return self;
}

- (void)updateWithText:(CPTextField)aTextField ascender:(float)ascenderHeight descender:(float)descenderHeight
{
    textTop = CGRectGetMinY([aTextField frame]) + [aTextField currentValueForThemeAttribute:@"content-inset"].top;
    ascender = ascenderHeight;
    descender = descenderHeight;

    [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)dirtyRect
{
    if (ascender === 0)
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds],
        minX = CGRectGetMinX(bounds),
        maxX = CGRectGetMaxX(bounds);

    CGContextSetLineWidth(context, 1.0);
    CGContextSetStrokeColor(context, [CPColor redColor]);
    CGContextBeginPath(context);

    var y = [textTop, textTop + ascender, textTop + ascender - descender],
        count = y.length;

    while (count--)
    {
        CGContextMoveToPoint(context, minX, y[count] + 0.5);
        CGContextAddLineToPoint(context, maxX, y[count] + 0.5);
    }

    CGContextStrokePath(context);
}

- (void)mouseDown:(CPEvent)anEvent
{
    [super mouseDown:anEvent];
}

- (void)mouseUp:(CPEvent)anEvent
{
    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];

    if (CGRectContainsPoint([self bounds], point))
        [[SharedAppController metricsView] setSampleText];
}

@end
