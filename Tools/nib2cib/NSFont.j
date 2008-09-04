
import <AppKit/CPFont.j>

@implementation CPFont (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    // FIXME: bold?
    return [self _initWithName:[aCoder decodeObjectForKey:@"NSName"] size:[aCoder decodeDoubleForKey:@"NSSize"] bold:NO];
}

@end

@implementation NSFont : CPFont
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPFont class];
}

@end
