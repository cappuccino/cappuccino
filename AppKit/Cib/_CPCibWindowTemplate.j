
import <Foundation/CPObject.j>


var _CPCibWindowTemplateMinSizeKey          = @"_CPCibWindowTemplateMinSizeKey",
    _CPCibWindowTemplateMaxSizeKey          = @"_CPCibWindowTemplateMaxSizeKey",
    
    _CPCibWindowTemplateViewClassKey        = @"_CPCibWindowTemplateWindowClassKey",
    
    _CPCibWindowTemplateWindowRectKey       = @"_CPCibWindowTemplateWindowRectKey",
    _CPCibWindowTemplateWindowStyleMaskKey  = @"_CPCibWindowTempatStyleMaskKey",
    _CPCibWindowTemplateWindowTitleKey      = @"_CPCibWindowTemplateWindowTitleKey",
    _CPCibWindowTemplateWindowViewKey       = @"_CPCibWindowTemplateWindowViewKey";

@implementation _CPCibWindowTemplate : CPObject
{
    CGSize      _minSize;
    CGSize      _maxSize;
    //CGSize      _screenRect;
    
    CPString    _viewClass;
    //unsigned  _wtFlags;
    CPString    _windowClass;
    CGRect      _windowRect;
    unsigned    _windowStyleMask;
    
    CPString    _windowTitle;
    CPView      _windowView;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _minSize = [aCoder decodeSizeForKey:_CPCibWindowTemplateMinSizeKey];
        _maxSize = [aCoder decodeSizeForKey:_CPCibWindowTemplateMaxSizeKey];
    
        _viewClass = [aCoder decodeObjectForKey:_CPCibWindowTemplateViewClassKey];
        
        _windowClass = [aCoder decodeObjectForKey:_CPCibWindowTemplateViewClassKey];
        _windowRect = [aCoder decodeRectForKey:_CPCibWindowTemplateWindowRectKey];
        _windowStyleMask = [aCoder decodeIntForKey:_CPCibWindowTemplateWindowStyleMaskKey];
        
        _windowTitle = [aCoder decodeObjectForKey:_CPCibWindowTemplateWindowTitleKey];
        _windowView = [aCoder decodeObjectForKey:_CPCibWindowTemplateWindowViewKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeSize:_minSize forKey:_CPCibWindowTemplateMinSizeKey];
    [aCoder encodeSize:_maxSize forKey:_CPCibWindowTemplateMaxSizeKey];
    
    [aCoder encodeObject:_viewClass forKey:_CPCibWindowTemplateViewClassKey];
    
    [aCoder encodeObject:_windowClass forKey:_CPCibWindowTemplateViewClassKey];
    [aCoder encodeRect:_windowRect forKey:_CPCibWindowTemplateWindowRectKey];
    [aCoder encodeInt:_windowStyleMask forKey:_CPCibWindowTemplateWindowStyleMaskKey];
    
    [aCoder encodeObject:_windowTitle forKey:_CPCibWindowTemplateWindowTitleKey];
    [aCoder encodeObject:_windowView forKey:_CPCibWindowTemplateWindowViewKey];
}

- (id)_cibInstantiate
{
    var windowClass = CPClassFromString(_windowClass);
    
/*    if (!windowClass)
        [NSException raise:NSInvalidArgumentException format:@"Unable to locate NSWindow class %@, using NSWindow",_windowClass];
        class=[NSWindow class];*/
        
    var theWindow = [[windowClass alloc] initWithContentRect:_windowRect styleMask:CPHUDBackgroundWindowMask | CPClosableWindowMask];//styleMask:_windowStyleMask];
//    alert(CPStringFromRect(_windowRect));
//    alert(CPStringFromSize(_minSize));
//    alert(CPStringFromSize(_maxSize));
    //[theWindow setMinSize:_minSize];
    //[theWindow setMaxSize:_maxSize];
    [theWindow setLevel:CPFloatingWindowLevel];

   //[result setHidesOnDeactivate:(_wtFlags&0x80000000)?YES:NO];
    [theWindow setTitle:_windowTitle];

    // FIXME: we can't autoresize yet...
    [_windowView setAutoresizesSubviews:NO];

    [theWindow setContentView:_windowView];

    [_windowView setAutoresizesSubviews:YES];
    
    return theWindow;
}

@end
