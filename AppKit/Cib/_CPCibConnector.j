
@import <Foundation/CPObject.j>
@import <Foundation/CPKeyValueCoding.j>


var _CPCibConnectorSourceKey        = @"_CPCibConnectorSourceKey",
    _CPCibConnectorDestinationKey   = @"_CPCibConnectorDestinationKey",
    _CPCibConnectorLabelKey         = @"_CPCibConnectorLabelKey";

@implementation _CPCibConnector : CPObject
{
    id          _source;
    id          _destination;
    CPString    _label;
}

- (void)replaceObjects:(JSObject)replacementObjects
{
    var replacement = replacementObjects[[_source UID]];

    if (replacement !== undefined)
        _source = replacement;

    replacement = replacementObjects[[_destination UID]];

    if (replacement !== undefined)
        _destination = replacement;
}

@end

@implementation _CPCibConnector (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _source = [aCoder decodeObjectForKey:_CPCibConnectorSourceKey];
        _destination = [aCoder decodeObjectForKey:_CPCibConnectorDestinationKey];
        _label = [aCoder decodeObjectForKey:_CPCibConnectorLabelKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_source forKey:_CPCibConnectorSourceKey];
    [aCoder encodeObject:_destination forKey:_CPCibConnectorDestinationKey];
    [aCoder encodeObject:_label forKey:_CPCibConnectorLabelKey];
}

@end

@implementation _CPCibControlConnector : _CPCibConnector
{
}

- (void)establishConnection
{
    var selectorName = _label;
    
    if (![selectorName hasSuffix:@":"])
        selectorName += ':';

    var selector = CPSelectorFromString(selectorName);

    if (!selector)
        [CPException
            raise:CPInvalidArgumentException
           reason:@"-[" + [self className] + ' ' + _cmd + @"] selector "  + selectorName + @" does not exist."];

    if ([_source respondsToSelector:@selector(setAction:)])
        objj_msgSend(_source, @selector(setAction:), selector);
    
    else
        [CPException
            raise:CPInvalidArgumentException
           reason:@"-[" + [self className] + ' ' + _cmd + @"] " + [_source description] + " does not respond to setAction:"];

    if ([_source respondsToSelector:@selector(setTarget:)])
        objj_msgSend(_source, @selector(setTarget:), _destination);

    else
        [CPException
            raise:CPInvalidArgumentException
           reason:@"-[" + [self className] + ' ' + _cmd + @"] " + [_source description] + " does not respond to setTarget:"];
}

@end

@implementation _CPCibOutletConnector : _CPCibConnector
{
}

- (void)establishConnection
{
    [_source setValue:_destination forKey:_label];
}

@end
