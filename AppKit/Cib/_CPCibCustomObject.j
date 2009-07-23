
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

- (void)setCustomClassName:(CPString)aClassName
{
    _className = aClassName;
}

- (CPString)description
{
    return [super description] + " (" + [self customClassName] + ')';
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

    // Hey this is us!
    if (theClass === [self class])
    {
        _className = @"CPObject";

        return self;
    }

    if (!theClass)
    {
#if DEBUG
        CPLog("Unknown class \"" + _className + "\" in cib file");
#endif
        theClass = [CPObject class];
    }

    if (theClass === [CPApplication class])
        return [CPApplication sharedApplication];
    
    return [[theClass alloc] init];
}

@end
