
@import <Foundation/CPObject.j>


var _CPCibCustomObjectClassName = @"_CPCibCustomObjectClassName";

@implementation _CPCibCustomObject : CPObject
{
    CPString _className;
}

- (CPString)customClassName
{
    return _className;
}

@end

@implementation _CPCibCustomObject (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
        _className = [aCoder decodeObjectForKey:_CPCibCustomObjectClassName];
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_className forKey:_CPCibCustomObjectClassName];
}

- (id)_cibInstantiate
{
    var theClass = CPClassFromString(_className);
    
    if (!theClass)
        CPLog("Unknown class \"" + _className + "\" in cib file");
        
    if (theClass === [CPApplication class])
        return [CPApplication sharedApplication];
    
    return [[theClass alloc] init];
}

@end
