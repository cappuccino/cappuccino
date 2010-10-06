/*
 * AppController.j
 * CPTextFieldHeightTest
 *
 * Created by Aparajita Fishman on August 31, 2010.
 */

@import <Foundation/CPObject.j>

CPLogRegister(CPLogConsole);


@implementation AppController : CPObject
{
    CPWindow theWindow;
}

@end


var CPTextFieldIsEditableKey            = "CPTextFieldIsEditableKey",
    CPTextFieldIsSelectableKey          = "CPTextFieldIsSelectableKey",
    CPTextFieldIsBorderedKey            = "CPTextFieldIsBorderedKey",
    CPTextFieldIsBezeledKey             = "CPTextFieldIsBezeledKey",
    CPTextFieldBezelStyleKey            = "CPTextFieldBezelStyleKey",
    CPTextFieldDrawsBackgroundKey       = "CPTextFieldDrawsBackgroundKey",
    CPTextFieldLineBreakModeKey         = "CPTextFieldLineBreakModeKey",
    CPTextFieldAlignmentKey             = "CPTextFieldAlignmentKey",
    CPTextFieldBackgroundColorKey       = "CPTextFieldBackgroundColorKey",
    CPTextFieldPlaceholderStringKey     = "CPTextFieldPlaceholderStringKey";

@implementation CPTextField (Test)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self setEditable:[aCoder decodeBoolForKey:CPTextFieldIsEditableKey]];
        [self setSelectable:[aCoder decodeBoolForKey:CPTextFieldIsSelectableKey]];

        [self setDrawsBackground:[aCoder decodeBoolForKey:CPTextFieldDrawsBackgroundKey]];

        [self setTextFieldBackgroundColor:[aCoder decodeObjectForKey:CPTextFieldBackgroundColorKey]];

        [self setLineBreakMode:[aCoder decodeIntForKey:CPTextFieldLineBreakModeKey]];
        [self setAlignment:[aCoder decodeIntForKey:CPTextFieldAlignmentKey]];

        [self setPlaceholderString:[aCoder decodeObjectForKey:CPTextFieldPlaceholderStringKey]];

        if ([self tag] === 1)
        {
            // Make sure the frame height is big enough
            var minSize = [self _minimumFrameSize];

            [self setFrameSize:CGSizeMake(CGRectGetWidth([self bounds]), minSize.height)];
        }
    }

    return self;
}

@end
