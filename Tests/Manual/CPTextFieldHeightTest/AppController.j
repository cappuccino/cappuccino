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

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    [theWindow setFrameOrigin:CGPointMake(30, 20)];

    var newWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(400, 40, 400, 400) styleMask:CPTitledWindowMask];

    [newWindow setTitle:@"sizeToFit"];

    var label = [[OldTextField alloc] initWithFrame:CGRectMake(15, 15, 200, 10)];

    [label setLineBreakMode:CPLineBreakByWordWrapping];
    [label setStringValue:@"Old sizeToFit, CPLineBreakByWordWrapping:\nIgnores original width, does not wrap onto several lines, as you can see by this text that does not wrap."];
    [label sizeToFit];
    [[newWindow contentView] addSubview:label];

    label = [[CPTextField alloc] initWithFrame:CGRectMake(15, 70, 200, 10)];

    [label setLineBreakMode:CPLineBreakByWordWrapping];
    [label setStringValue:@"New sizeToFit, CPLineBreakByWordWrapping:\nWraps onto several lines, keeping the original width, as you can see by this text that has wrapped."];
    [label sizeToFit];
    [[newWindow contentView] addSubview:label];

    label = [[OldTextField alloc] initWithFrame:CGRectMake(15, 180, 200, 10)];

    [label setLineBreakMode:CPLineBreakByClipping];
    [label setStringValue:@"Old sizeToFit, CPLineBreakByClipping:\nDoes not wrap, as you can see by this text that does not wrap."];
    [label sizeToFit];
    [[newWindow contentView] addSubview:label];

    label = [[CPTextField alloc] initWithFrame:CGRectMake(15, 225, 200, 10)];

    [label setLineBreakMode:CPLineBreakByClipping];
    [label setStringValue:@"New sizeToFit, CPLineBreakByClipping:\nDoes not wrap, as you can see by this text that does not wrap."];
    [label sizeToFit];
    [[newWindow contentView] addSubview:label];

    [newWindow orderFront:nil];
}

@end

@implementation OldTextField : CPTextField

- (void)sizeToFit
{
    console.log("old");
    var size = [([self stringValue] || " ") sizeWithFont:[self currentValueForThemeAttribute:@"font"]],
        contentInset = [self currentValueForThemeAttribute:@"content-inset"],
        minSize = [self currentValueForThemeAttribute:@"min-size"],
        maxSize = [self currentValueForThemeAttribute:@"max-size"];

    size.width = MAX(size.width + contentInset.left + contentInset.right, minSize.width);
    size.height = MAX(size.height + contentInset.top + contentInset.bottom, minSize.height);

    if (maxSize.width >= 0.0)
        size.width = MIN(size.width, maxSize.width);

    if (maxSize.height >= 0.0)
        size.height = MIN(size.height, maxSize.height);

    if ([self isEditable])
        size.width = CGRectGetWidth([self frame]);

    [self setFrameSize:size];
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
            // Make sure the frame is big enough
            var minSize = [self _minimumFrameSize];

            minSize.width = MAX(CGRectGetWidth([self frame]), minSize.width);
            [self setFrameSize:minSize];
        }
    }

    return self;
}

@end
