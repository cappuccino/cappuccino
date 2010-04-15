
@import <AppKit/CPView.j>

#include "CoreGraphics/CGGeometry.h"


@implementation CPButtonBar : CPView
{
    BOOL    _hasResizeControl;
    BOOL    _resizeControlIsLeftAligned;
    CPArray _buttons;
}

+ (id)plusButton
{
    var button = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, 35, 25)],
        image = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:self] pathForResource:@"plus_button.png"] size:CGSizeMake(11, 12)];

    [button setImage:image];
    [button setImagePosition:CPImageOnly];

    return button;
}

+ (id)minusButton
{
    var button = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, 35, 25)],
        image = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:self] pathForResource:@"minus_button.png"] size:CGSizeMake(11, 4)];

    [button setImage:image];
    [button setImagePosition:CPImageOnly];

    return button;
}

+ (CPString)themeClass
{
    return @"button-bar";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[CGInsetMake(0.0, 0.0, 0.0, 0.0), CGSizeMakeZero(), [CPNull null], [CPNull null], [CPNull null]]
                                       forKeys:[@"resize-control-inset", @"resize-control-size", @"resize-control-color", @"bezel-color", @"button-bezel-color"]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _buttons = [];
        [self setNeedsLayout];
    }

    return self;
}

- (void)awakeFromCib
{
    var view = [self superview],
        subview = self;

    while (view)
    {
        if ([view isKindOfClass:[CPSplitView class]])
        {
            var viewIndex = [[view subviews] indexOfObject:subview];
            [view setButtonBar:self forDividerAtIndex:viewIndex];

            break;
        }

        subview = view;
        view = [view superview];
    }
}

- (void)setButtons:(CPArray)buttons
{
    _buttons = [CPArray arrayWithArray:buttons];

    for (var i = 0, count = [_buttons count]; i < count; i++)
    {
        var button = _buttons[i];

        var normalColor = [self valueForThemeAttribute:@"button-bezel-color" inState:CPThemeStateNormal],
            highlightedColor = [self valueForThemeAttribute:@"button-bezel-color" inState:CPThemeStateHighlighted],
            disabledColor = [self valueForThemeAttribute:@"button-bezel-color" inState:CPThemeStateDisabled];

        [button setValue:normalColor forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal|CPThemeStateBordered];    
        [button setValue:highlightedColor forThemeAttribute:@"bezel-color" inState:CPThemeStateHighlighted|CPThemeStateBordered];    
        [button setValue:disabledColor forThemeAttribute:@"bezel-color" inState:CPThemeStateDisabled|CPThemeStateBordered];    

        // FIXME shouldn't need this
        [button setValue:normalColor forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal|CPThemeStateBordered|CPPopUpButtonStatePullsDown];    
        [button setValue:highlightedColor forThemeAttribute:@"bezel-color" inState:CPThemeStateHighlighted|CPThemeStateBordered|CPPopUpButtonStatePullsDown];    
        [button setValue:disabledColor forThemeAttribute:@"bezel-color" inState:CPThemeStateDisabled|CPThemeStateBordered|CPPopUpButtonStatePullsDown];    

        [button setBordered:YES];
    }
    
    [self setNeedsLayout];
}

- (CPArray)buttons
{
    return [CPArray arrayWithArray:_buttons];
}

- (void)setHasResizeControl:(BOOL)shouldHaveResizeControl
{
    if (_hasResizeControl === shouldHaveResizeControl)
        return;

    _hasResizeControl = !!shouldHaveResizeControl;
    [self setNeedsLayout];
}

- (BOOL)hasResizeControl
{
    return _hasResizeControl;
}

- (void)setResizeControlIsLeftAligned:(BOOL)shouldBeLeftAligned
{
    if (_resizeControlIsLeftAligned === shouldBeLeftAligned)
        return;

    _resizeControlIsLeftAligned = !!shouldBeLeftAligned;
    [self setNeedsLayout];
}

- (BOOL)resizeControlIsLeftAligned
{
    return _resizeControlIsLeftAligned;
}

- (CGRect)resizeControlFrame
{
    var inset = [self currentValueForThemeAttribute:@"resize-control-inset"],
        size = [self currentValueForThemeAttribute:@"resize-control-size"],
        currentSize = [self bounds],
        leftOrigin = _resizeControlIsLeftAligned ? 0 : currentSize.size.width - size.width - inset.right - inset.left;

    return CGRectMake(leftOrigin, 0, size.width + inset.left + inset.right, size.height + inset.top + inset.bottom);
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "resize-control-view")
    {
        var inset = [self currentValueForThemeAttribute:@"resize-control-inset"],
            size = [self currentValueForThemeAttribute:@"resize-control-size"],
            currentSize = [self bounds];

        if (_resizeControlIsLeftAligned)
            return CGRectMake(inset.left, inset.top, size.width, size.height);
        else
            return CGRectMake(currentSize.size.width - size.width - inset.right, inset.top, size.width, size.height);
    }

    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "resize-control-view")
        return [[CPView alloc] initWithFrame:CGRectMakeZero()];

    return [super createEphemeralSubviewNamed:aName];
}

- (void)layoutSubviews
{
    [self setBackgroundColor:[self currentValueForThemeAttribute:@"bezel-color"]];

    var buttonsNotHidden = [CPArray arrayWithArray:_buttons],
        count = [buttonsNotHidden count];

    while (count--)
        if ([buttonsNotHidden[count] isHidden])
            [buttonsNotHidden removeObject:buttonsNotHidden[count]];

    var currentButtonOffset = _resizeControlIsLeftAligned ? CGRectGetMaxX([self bounds]) + 1 : -1,
        height = CGRectGetHeight([self bounds]) - 1;

    for (var i = 0, count = [buttonsNotHidden count]; i < count; i++)
    {   
        var button = buttonsNotHidden[i],
            width = CGRectGetWidth([button frame]);

        if (_resizeControlIsLeftAligned)
        {
            [button setFrame:CGRectMake(currentButtonOffset - width, 1, width, height)];
            currentButtonOffset -= width - 1;
        }
        else
        {
            [button setFrame:CGRectMake(currentButtonOffset, 1, width, height)];
            currentButtonOffset += width - 1;
        }

        [self addSubview:button];
    }

    if (_hasResizeControl)
    {
        var resizeControlView = [self layoutEphemeralSubviewNamed:@"resize-control-view"
                                                       positioned:CPWindowAbove
                                  relativeToEphemeralSubviewNamed:nil];

        [resizeControlView setAutoresizingMask: _resizeControlIsLeftAligned ? CPViewMaxXMargin : CPViewMinXMargin];
        [resizeControlView setBackgroundColor:[self currentValueForThemeAttribute:@"resize-control-color"]];
    }
}

@end

var CPButtonBarHasResizeControlKey = @"CPButtonBarHasResizeControlKey",
    CPButtonBarResizeControlIsLeftAlignedKey = @"CPButtonBarResizeControlIsLeftAlignedKey",
    CPButtonBarButtonsKey = @"CPButtonBarButtonsKey";

@implementation CPButtonBar (CPCoding)

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeBool:_hasResizeControl forKey:CPButtonBarHasResizeControlKey];
    [aCoder encodeBool:_resizeControlIsLeftAligned forKey:CPButtonBarResizeControlIsLeftAlignedKey];
    [aCoder encodeObject:_buttons forKey:CPButtonBarButtonsKey];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _buttons = [aCoder decodeObjectForKey:CPButtonBarButtonsKey] || [];
        _hasResizeControl = [aCoder decodeBoolForKey:CPButtonBarHasResizeControlKey];
        _resizeControlIsLeftAligned = [aCoder decodeBoolForKey:CPButtonBarResizeControlIsLeftAlignedKey];
    }

    return self;
}

@end

