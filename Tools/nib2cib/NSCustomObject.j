
import <AppKit/_CPCibCustomObject.j>


@implementation _CPCibCustomObject (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self){
        _className = [aCoder decodeObjectForKey:@"NSClassName"];
    print(":::"+_className);
    }
    return self;
}

@end

@implementation NSCustomObject : _CPCibCustomObject
{
}

- (id)initWithCoder:(CPCoder)aCoder
{print("i-nit form coder");
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPCibCustomObject class];
}

- (id)awakeAfterUsingCoder:(CPCoder)aCoder
{
    print("awaking from coder...");
    return self;
}

@end