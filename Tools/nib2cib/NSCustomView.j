
import <AppKit/CPCustomView.j>

import "NSView.j"


@implementation NSCustomView : CPView
{
    CPString    _className;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];
    
    if (self)
        _className = [aCoder decodeObjectForKey:@"NSClassName"];
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_NSCustomViewMapClassName(_className) forKey:@"CPCustomViewClassNameKey"];
}

- (CPString)classForKeyedArchiver
{
    return [CPCustomView class];
}

@end

function _NSCustomViewMapClassName(aClassName)
{
    if (aClassName == @"NSView")
        return "CPView";
    
    return aClassName;
}
