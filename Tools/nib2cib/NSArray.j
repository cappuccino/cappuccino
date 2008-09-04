
import <Foundation/CPObject.j>


@implementation NSArray : CPObject
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [aCoder _decodeArrayOfObjectsForKey:@"NS.objects"];
}

@end

@implementation NSMutableArray : NSArray
{
}
@end