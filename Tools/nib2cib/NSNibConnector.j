
import <AppKit/_CPCibConnector.j>


@implementation _CPCibConnector (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _source = [aCoder decodeObjectForKey:@"NSSource"];
        _destination = [aCoder decodeObjectForKey:@"NSDestination"];
        _label = [aCoder decodeObjectForKey:@"NSLabel"];
#if DEBUG
        CPLog(@"Connection: " + [_source description] + " " + [_destination description] + " " + _label);
#endif
    }
    
    return self;
}

@end

@implementation NSNibConnector : _CPCibConnector
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [[_CPCibConnector alloc] NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPCibConnector class];
}

@end

@implementation NSNibControlConnector : _CPCibControlConnector
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [[_CPCibControlConnector alloc] NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPCibControlConnector class];
}

@end

@implementation NSNibOutletConnector : _CPCibOutletConnector
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [[_CPCibOutletConnector alloc] NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPCibOutletConnector class];
}

@end
