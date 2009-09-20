
@import <Foundation/CPObject.j>


@implementation _CPCibProxyObject : CPObject
{
    CPString _identifier;
}
@end

var _CPCibProxyObjectIdentifierKey  = @"CPIdentifier";

@implementation _CPCibProxyObject (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
        _identifier = [aCoder decodeObjectForKey:_CPCibProxyObjectIdentifierKey];

    if ([aCoder respondsToSelector:@selector(externalObjectForProxyIdentifier:)])
        return [aCoder externalObjectForProxyIdentifier:_identifier];

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_identifier forKey:_CPCibProxyObjectIdentifierKey];
}

@end
