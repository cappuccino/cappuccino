
import <AppKit/CPResponder.j>


@implementation CPResponder (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
        [self setNextResponder:[aCoder decodeObjectForKey:@"NSNextResponder"]];
    
    return self;
}

@end

@implementation NSResponder : CPResponder
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPResponder class];
}

@end