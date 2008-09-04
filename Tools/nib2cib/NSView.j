
import <AppKit/CPView.j>


//unsigned int rotatedFromBase:1;
//unsigned int rotatedOrScaledFromBase:1;
//unsigned int autosizing:6;
//unsigned int autoresizeSubviews:1;
//unsigned int wantsGState:1;
//unsigned int needsDisplay:1;
//unsigned int validGState:1;
//unsigned int newGState:1;
//unsigned int noVerticalAutosizing:1;
//unsigned int frameChangeNotesSuspended:1;
//unsigned int needsFrameChangeNote:1;
//unsigned int focusChangeNotesSuspended:1;
//unsigned int boundsChangeNotesSuspended:1;
//unsigned int needsBoundsChangeNote:1;
//unsigned int removingWithoutInvalidation:1;
//unsigned int interfaceStyle0:1;
//unsigned int needsDisplayForBounds:1;
//unsigned int specialArchiving:1;
//unsigned int interfaceStyle1:1;
//unsigned int retainCount:6;
//unsigned int retainCountOverMax:1;
//unsigned int aboutToResize:1;

@implementation CPView (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    _frame = CGRectMakeZero();
    
    if ([aCoder containsValueForKey:@"NSFrame"])
        _frame = [aCoder decodeRectForKey:@"NSFrame"];
    else if ([aCoder containsValueForKey:@"NSFrameSize"])
        _frame.size = [aCoder decodeSizeForKey:@"NSFrameSize"];   

    self = [super NS_initWithCoder:aCoder];
    
    if (self)
    {
        _bounds = CGRectMake(0.0, 0.0, CGRectGetWidth(_frame), CGRectGetHeight(_frame));
    
        _window = [aCoder decodeObjectForKey:@"NSWindow"];
        _superview = [aCoder decodeObjectForKey:@"NSSuperview"];
        _subviews = [aCoder decodeObjectForKey:@"NSSubviews"];

        if (!_subviews)
            _subviews = [];
        
        var vFlags = [aCoder decodeIntForKey:@"NSvFlags"];
        
        _autoresizingMask = vFlags & (0x3F << 1);
        _autoresizesSubviews = vFlags & (1 << 8);
        
        _hitTests = YES;
        _isHidden = NO;//[aCoder decodeObjectForKey:CPViewIsHiddenKey];
        _opacity = 1.0;//[aCoder decodeIntForKey:CPViewOpacityKey];
        
        if (YES/*[_superview isFlipped]*/)
        {
            var height = CGRectGetHeight([self bounds]),
                count = [_subviews count];
          
            while (count--)
            {
                var subview = _subviews[count],
                    frame = [subview frame];
                
                [subview setFrameOrigin:CGPointMake(CGRectGetMinX(frame), height - CGRectGetMaxY(frame))];
            }
        }
    }
    
    return self;
}

@end

@implementation NSView : CPView
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [[CPView alloc] NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPView class];
}

@end

