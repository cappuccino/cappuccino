@implementation Person : CPObject
{
    CPString    _name;
    int         _age;
}

- (id) init
{
    self = [super init];
    if(self){
        _name = @"Tyler Durden"
        _age = 27;
    }
    return self;
}

@end
