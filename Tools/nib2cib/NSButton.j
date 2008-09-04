
import <AppKit/CPButton.j>

import "NSCell.j"
import "NSControl.j"


@implementation CPButton (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];
    
    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];
        
        [self setBordered:[cell isBordered]];
        [self setBezelStyle:[cell bezelStyle]];
        
        [self setTitle:[cell title]];
    }
    
    return self;
}

@end

@implementation NSButton : CPButton
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPButton class];
}

@end

@implementation NSButtonCell : NSCell
{
    BOOL        _isBordered;
    unsigned    _bezelStyle;
    
    CPString    _title;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    
    if (self)
    {   
        var buttonFlags = [aCoder decodeIntForKey:@"NSButtonFlags"],
            buttonFlags2 = [aCoder decodeIntForKey:@"NSButtonFlags2"];
        
        _isBordered = (buttonFlags & 0x00800000) ? YES : NO;
        _bezelStyle = (buttonFlags2 & 0x7) | ((buttonFlags2 & 0x20) >> 2);
        
        
        // NSContents for NSButton is actually the title
        _title = [aCoder decodeObjectForKey:@"NSContents"];
    }
    
    return self;
}

- (BOOL)isBordered
{
    return _isBordered;
}

- (int)bezelStyle
{
    return _bezelStyle;
}

- (CPString)title
{
    return _title;
}

@end
