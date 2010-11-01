
@import <Foundation/CPObject.j>

@import "CGGeometry.j"
@import "CPWindow.j"


var _CPCibWindowTemplateMinSizeKey                  = @"_CPCibWindowTemplateMinSizeKey",
    _CPCibWindowTemplateMaxSizeKey                  = @"_CPCibWindowTemplateMaxSizeKey",
    
    _CPCibWindowTemplateViewClassKey                = @"_CPCibWindowTemplateViewClassKey",
    _CPCibWindowTemplateWindowClassKey              = @"_CPCibWindowTemplateWindowClassKey",
    
    _CPCibWindowTemplateWindowRectKey               = @"_CPCibWindowTemplateWindowRectKey",
    _CPCibWindowTemplateWindowStyleMaskKey          = @"_CPCibWindowTempatStyleMaskKey",
    _CPCibWindowTemplateWindowTitleKey              = @"_CPCibWindowTemplateWindowTitleKey",
    _CPCibWindowTemplateWindowViewKey               = @"_CPCibWindowTemplateWindowViewKey",

    _CPCibWindowTemplateWindowAutorecalculatesKeyViewLoop = @"_CPCibWindowTemplateWindowAutorecalculatesKeyViewLoop";
    _CPCibWindowTemplateWindowIsFullPlatformWindowKey     = @"_CPCibWindowTemplateWindowIsFullPlatformWindowKey";

@implementation _CPCibWindowTemplate : CPObject
{
    CGSize      _minSize;
    CGSize      _maxSize;
    //CGSize      _screenRect;

    id          _viewClass;
    //unsigned  _wtFlags;
    CPString    _windowClass;
    CGRect      _windowRect;
    unsigned    _windowStyleMask;

    CPString    _windowTitle;
    CPView      _windowView;

    BOOL        _windowAutorecalculatesKeyViewLoop;
    BOOL        _windowIsFullPlatformWindow;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _windowClass = @"CPWindow";
        _windowRect = CGRectMake(0.0, 0.0, 400.0, 200.0);
        _windowStyleMask = CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask;

        _windowTitle = @"Window";
        _windowView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 200.0)];

        _windowIsFullPlatformWindow = NO;
    }

    return self;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        if ([aCoder containsValueForKey:_CPCibWindowTemplateMinSizeKey])
            _minSize = [aCoder decodeSizeForKey:_CPCibWindowTemplateMinSizeKey];
        if ([aCoder containsValueForKey:_CPCibWindowTemplateMaxSizeKey])
            _maxSize = [aCoder decodeSizeForKey:_CPCibWindowTemplateMaxSizeKey];
    
        _viewClass = [aCoder decodeObjectForKey:_CPCibWindowTemplateViewClassKey];
        
        _windowClass = [aCoder decodeObjectForKey:_CPCibWindowTemplateWindowClassKey];
        _windowRect = [aCoder decodeRectForKey:_CPCibWindowTemplateWindowRectKey];
        _windowStyleMask = [aCoder decodeIntForKey:_CPCibWindowTemplateWindowStyleMaskKey];
        
        _windowTitle = [aCoder decodeObjectForKey:_CPCibWindowTemplateWindowTitleKey];
        _windowView = [aCoder decodeObjectForKey:_CPCibWindowTemplateWindowViewKey];

        _windowAutorecalculatesKeyViewLoop = !![aCoder decodeObjectForKey:_CPCibWindowTemplateWindowAutorecalculatesKeyViewLoop];
        _windowIsFullPlatformWindow = !![aCoder decodeObjectForKey:_CPCibWindowTemplateWindowIsFullPlatformWindowKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    if (_minSize)
        [aCoder encodeSize:_minSize forKey:_CPCibWindowTemplateMinSizeKey];
    if (_maxSize)
        [aCoder encodeSize:_maxSize forKey:_CPCibWindowTemplateMaxSizeKey];
    
    [aCoder encodeObject:_viewClass forKey:_CPCibWindowTemplateViewClassKey];
    
    [aCoder encodeObject:_windowClass forKey:_CPCibWindowTemplateWindowClassKey];
    [aCoder encodeRect:_windowRect forKey:_CPCibWindowTemplateWindowRectKey];
    [aCoder encodeInt:_windowStyleMask forKey:_CPCibWindowTemplateWindowStyleMaskKey];
    
    [aCoder encodeObject:_windowTitle forKey:_CPCibWindowTemplateWindowTitleKey];
    [aCoder encodeObject:_windowView forKey:_CPCibWindowTemplateWindowViewKey];

    if (_windowAutorecalculatesKeyViewLoop)
        [aCoder encodeObject:_windowAutorecalculatesKeyViewLoop forKey:_CPCibWindowTemplateWindowAutorecalculatesKeyViewLoop];

    if (_windowIsFullPlatformWindow)
        [aCoder encodeObject:_windowIsFullPlatformWindow forKey:_CPCibWindowTemplateWindowIsFullPlatformWindowKey];
}

- (CPString)customClassName
{
    return _windowClass;
}


- (void)setCustomClassName:(CPString)aClassName
{
    _windowClass = aClassName;
}

- (CPString)windowClass
{
    return _windowClass;
}

- (id)_cibInstantiate
{
    var windowClass = CPClassFromString([self windowClass]);
    
/*    if (!windowClass)
        [NSException raise:NSInvalidArgumentException format:@"Unable to locate NSWindow class %@, using NSWindow",_windowClass];
        class=[NSWindow class];*/
        
    var theWindow = [[windowClass alloc] initWithContentRect:_windowRect styleMask:_windowStyleMask];
    
    if (_minSize)
        [theWindow setMinSize:_minSize];
    if (_maxSize)
        [theWindow setMaxSize:_maxSize];

    //[result setHidesOnDeactivate:(_wtFlags&0x80000000)?YES:NO];
    [theWindow setTitle:_windowTitle];

    // FIXME: we can't autoresize yet...
    [_windowView setAutoresizesSubviews:NO];

    [theWindow setContentView:_windowView];

    [_windowView setAutoresizesSubviews:YES];
    
    if ([_viewClass isKindOfClass:[CPToolbar class]])
    {
       [theWindow setToolbar:_viewClass];
    }

    [theWindow setAutorecalculatesKeyViewLoop:_windowAutorecalculatesKeyViewLoop];
    [theWindow setFullBridge:_windowIsFullPlatformWindow];

    return theWindow;
}

@end
