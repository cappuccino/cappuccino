@import <AppKit/CPTextField.j>

@import "NSControl.j"
@import "NSCell.j"

@implementation CPTextField (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];
    
    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];
        
        [self sendActionOn:CPKeyUpMask|CPKeyDownMask];
        
		[self setEditable:[cell isEditable]];
		[self setSelectable:[cell isSelectable]];
		
		[self setBordered:[cell isBordered]];
		[self setBezeled:[cell isBezeled]];
        [self setBezelStyle:[cell bezelStyle]];
        [self setDrawsBackground:[cell drawsBackground]];
        
        //[self setLineBreakMode:???];
        [self setTextFieldBackgroundColor:[cell backgroundColor]];
        
		[self setPlaceholderString:[cell placeholderString]];
        
        [self setTextColor:[cell textColor]];
		
        var frame = [self frame];

        [self setFrameOrigin:CGPointMake(frame.origin.x - 4.0, frame.origin.y - 4.0)];
        [self setFrameSize:CGSizeMake(frame.size.width + 8.0, frame.size.height + 8.0)];

        CPLog.debug([self stringValue] + " => isBordered=" + [self isBordered] + ", isBezeled="  + [self isBezeled] + ", bezelStyle=" + [self bezelStyle] + "("+[cell stringValue]+", " + [cell placeholderString] + ")");
	}
	
	return self;
}

@end

@implementation NSTextField : CPTextField
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPTextField class];
}

@end

@implementation NSTextFieldCell : NSCell
{
    CPTextFieldBezelStyle   _bezelStyle         @accessors(readonly, getter=bezelStyle);
    BOOL                    _drawsBackground    @accessors(readonly, getter=drawsBackground);
    CPColor                 _backgroundColor    @accessors(readonly, getter=backgroundColor);
    CPColor                 _textColor          @accessors(readonly, getter=textColor);
    CPString                _placeholderString  @accessors(readonly, getter=placeholderString);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    
    if (self)
    {
    	_bezelStyle         = [aCoder decodeObjectForKey:@"NSTextBezelStyle"] || CPTextFieldSquareBezel;
        _drawsBackground    = [aCoder decodeBoolForKey:@"NSDrawsBackground"];
        _backgroundColor    = [aCoder decodeObjectForKey:@"NSBackgroundColor"];
        _textColor          = [aCoder decodeObjectForKey:@"NSTextColor"];
        _placeholderString  = [aCoder decodeObjectForKey:@"NSPlaceholderString"];
    }
    
    return self;
}

@end
