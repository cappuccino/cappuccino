
import <Foundation/CPObject.j>

import "NSFont.j"


@implementation NSCell : CPObject
{
    CPFont  _font;
    id      _contents;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _font = [aCoder decodeObjectForKey:@"NSFont"];
        _contents = [aCoder decodeObjectForKey:@"NSContents"];
    }
    
    return self;
}

- (id)replacementObjectForCoder:(CPCoder)aCoder
{
    return nil;
}

//- (void)encodeWithCoder:(CPCoder)aCoder
//{


- (CPFont)font
{
    return _font;
}

- (id)contents
{
    return _contents;
}

@end
