
import <AppKit/_CPCibWindowTemplate.j>


@implementation _CPCibWindowTemplate (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _minSize = [aCoder decodeSizeForKey:@"NSMinSize"];
        _maxSize = [aCoder decodeSizeForKey:@"NSMaxSize"];
        _screenRect = [aCoder decodeRectForKey:@"NSScreenRect"]; // screen created on
        _viewClass = [aCoder decodeObjectForKey:@"NSViewClass"];
        _wtFlags = [aCoder decodeIntForKey:@"NSWTFlags"];
        _windowBacking = [aCoder decodeIntForKey:@"NSWindowBacking"];
        
        // Convert NSWindows to CPWindows.
        _windowClass = CP_NSMapClassName([aCoder decodeObjectForKey:@"NSWindowClass"]);
        
        _windowRect = [aCoder decodeRectForKey:@"NSWindowRect"];
        _windowStyleMask = [aCoder decodeIntForKey:@"NSWindowStyleMask"];
        _windowTitle = [aCoder decodeObjectForKey:@"NSWindowTitle"];
        _windowView = [aCoder decodeObjectForKey:@"NSWindowView"];
        
        /*
        _windowRect.origin.y -= _screenRect.size.height - [[NSScreen mainScreen] frame].size.height;
        if (![_windowClass isEqualToString:@"NSPanel"])
           _windowRect.origin.y -= [NSMainMenuView menuHeight];   // compensation for the additional menu bar
        */
   }

   return self;
}

@end

@implementation NSWindowTemplate : _CPCibWindowTemplate
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (id)awakeAfterUsingCoder:(CPCoder)aCoder
{
    return self;
}

- (Class)classForKeyedArchiver
{
    return [_CPCibWindowTemplate class];
}

@end
