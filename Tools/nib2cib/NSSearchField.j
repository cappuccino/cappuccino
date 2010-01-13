

@import <AppKit/CPSearchField.j>
@import "NSTextField.j"


@implementation CPSearchField (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
    }

    return self;
}

@end

@implementation NSSearchField : CPSearchField
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPSearchField class];
}

@end

@implementation NSSearchFieldCell : NSTextFieldCell
{
}
@end
