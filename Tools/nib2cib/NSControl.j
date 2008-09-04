
import <AppKit/CPControl.j>

import "NSCell.j"
import "NSView.j"


@implementation CPControl (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];
    
    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];
        
        _value = [cell contents];
        
        [self setFont:[cell font]];
        [self setEnabled:[aCoder decodeObjectForKey:@"NSEnabled"]];
    }
    
    return self;
}

@end

@implementation NSControl : CPControl
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPControl class];
}

@end
