@import <Foundation/CPSortDescriptor.j>

@implementation CPSortDescriptor (NSCoding)
{
}

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        _key = [aCoder decodeObjectForKey:@"NSKey"];
        _selector = CPSelectorFromString([aCoder decodeObjectForKey:@"NSSelector"]);
        _ascending = [aCoder decodeBoolForKey:@"NSAscending"];
    }

    return self;
}

@end

@implementation NSSortDescriptor : CPSortDescriptor
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPSortDescriptor class];
}

@end