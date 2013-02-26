
@import <AppKit/CPTableView.j>

@implementation CPTableCellView (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{    
    self = [super NS_initWithCoder:aCoder];
        
    return self;
}

@end

@implementation NSTableCellView : CPTableCellView
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPTableCellView class];
}

@end
