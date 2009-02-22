
@import <AppKit/CPView.j>

#include "CoreGraphics/CGGeometry.h"


@implementation CPButtonBar : CPControl
{
}

+ (id)themedAttributes
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
        [bezelView setBackgroundColor:[self currentValueForThemedAttributeName:@"bezel-color"]];
}

- (void)addSubview:(CPView)aSubview
{
    [super addSubview:aSubview];

    [aSubview setAutoresizingMask:CPViewMinXMargin];
}

@end
