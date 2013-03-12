
@import <AppKit/CPTableView.j>

@implementation CPTableCellView (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    return [super NS_initWithCoder:aCoder];
}

@end

@implementation NSTableCellView : CPTableCellView

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPTableCellView class];
}

@end
