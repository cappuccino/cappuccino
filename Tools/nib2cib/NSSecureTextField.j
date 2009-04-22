
@import <AppKit/CPSecureTextField.j>

@import "NSTextField.j"


@implementation NSSecureTextField : CPSecureTextField
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPSecureTextField class];
}

@end

@implementation NSSecureTextFieldCell : NSTextFieldCell
{
}
@end
