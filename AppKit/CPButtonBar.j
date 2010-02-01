
@import <AppKit/CPView.j>

#include "CoreGraphics/CGGeometry.h"


@implementation CPButtonBar : CPControl
{
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
        [self setNeedsLayout];

    return self;
}

+ (CPString)themeClass
{
    return @"button-bar";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[nil]
                                       forKeys:[@"bezel-color"]];
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "bezel-view")
        return [self bounds];
    
    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "bezel-view")
    {
        var view = [[CPView alloc] initWithFrame:_CGRectMakeZero()];

        [view setHitTests:NO];
        
        return view;
    }
    
    return [super createEphemeralSubviewNamed:aName];
}

- (void)layoutSubviews
{
    var bezelView = [self layoutEphemeralSubviewNamed:@"bezel-view"
                                           positioned:CPWindowBelow
                      relativeToEphemeralSubviewNamed:@""];
      
    if (bezelView)
        [bezelView setBackgroundColor:[self currentValueForThemeAttribute:@"bezel-color"]];
}

- (void)addSubview:(CPView)aSubview
{
    [super addSubview:aSubview];

    [aSubview setAutoresizingMask:CPViewMinXMargin];
}

@end
