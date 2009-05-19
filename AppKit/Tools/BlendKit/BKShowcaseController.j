
@import <AppKit/CPTheme.j>
@import <AppKit/CPView.j>

@import "BKUtilities.j"


@implementation BKShowcaseController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        bounds = [contentView bounds],
        themeDescriptorClasses = BKThemeDescriptorClasses();
    
    var tabView = [[CPTabView alloc] initWithFrame:bounds];
    
    [tabView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    
    [contentView addSubview:tabView];
    
    var count = [themeDescriptorClasses count];
    
    while (count--)
    {
        var theClass = themeDescriptorClasses[count],
            item = [[CPTabViewItem alloc] initWithIdentifier:[theClass themeName]],
            templates = BKThemeObjectTemplatesForClass(theClass),
            templatesCount = [templates count],
            viewTemplates = [],
            itemSize = CGSizeMake(0.0, 0.0);
            
        while (templatesCount--)
        {
            var template = templates[templatesCount],
                object = [template valueForKey:@"themedObject"];

            if ([object isKindOfClass:[CPView class]])
            {            
                var size = [object frame].size,
                    labelWidth = [[template valueForKey:@"label"] sizeWithFont:[CPFont boldSystemFontOfSize:12.0]].width + 20.0;

                if (size.width > itemSize.width)
                    itemSize.width = size.width;
                    
                if (labelWidth > itemSize.width)
                    itemSize.width = labelWidth;
                
                if (size.height > itemSize.height)
                    itemSize.height = size.height;
                    
                [viewTemplates addObject:template];
            }
        }
        
        itemSize.height += 30;
        
        var collectionView = [[CPCollectionView alloc] initWithFrame:CGRectMakeZero()],
            collectionViewItem = [[CPCollectionViewItem alloc] init];
            
        [collectionViewItem setView:[[BKShowcaseCell alloc] init]];

        [collectionView setItemPrototype:collectionViewItem];
        [collectionView setMinItemSize:itemSize];
        [collectionView setMaxItemSize:itemSize];
        [collectionView setVerticalMargin:5.0];
        [collectionView setContent:viewTemplates];
        
        [item setLabel:[theClass themeName]];
        [item setView:collectionView];

        [tabView addTabViewItem:item];
    }

    [theWindow orderFront:self];
}

@end


@implementation BKShowcaseCell : CPView
{
    CPView      _view;
    CPTextField _label;
}

- (void)setSelected:(BOOL)isSelected
{
}

- (void)setRepresentedObject:(id)anObject
{
    if (!_label)
    {
        _label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        
        [_label setAlignment:CPCenterTextAlignment];
        [_label setAutoresizingMask:CPViewMinYMargin | CPViewWidthSizable];
        [_label setFont:[CPFont boldSystemFontOfSize:12.0]];
        
        [self addSubview:_label];
    }
    
    [_label setStringValue:[anObject valueForKey:@"label"]];
    [_label sizeToFit];
    
    [_label setFrame:CGRectMake(0.0, CGRectGetHeight([self bounds]) - CGRectGetHeight([_label frame]), 
        CGRectGetWidth([self bounds]), CGRectGetHeight([_label frame]))];
    
    if (_view)
        [_view removeFromSuperview];
        
    _view = [anObject valueForKey:@"themedObject"];

    [_view setTheme:nil];
    [_view setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [_view setFrameOrigin:CGPointMake((CGRectGetWidth([self bounds]) - CGRectGetWidth([_view frame])) / 2.0, (CGRectGetMinY([_label frame]) - CGRectGetHeight([_view frame])) / 2.0)];
    
    [self addSubview:_view];
}

@end
