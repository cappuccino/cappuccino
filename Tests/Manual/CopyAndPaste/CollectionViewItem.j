@import <AppKit/AppKit.j>
@import <AppKit/CPCollectionViewItem.j>

@implementation CollectionViewItem : CPCollectionViewItem
{
}

@end

@implementation CollectionViewView : CPView
{
    @outlet CPTextField textField @accessors;

    boolean selected @accessors;
}

- (void)setSelected:(BOOL)aFlag
{
    selected = aFlag;

    [self setBackgroundColor:aFlag ? [CPColor blueColor] : nil];
    [textField setTextColor:aFlag ? [CPColor whiteColor] : [CPColor blackColor]];
}

- (void)setRepresentedObject:(id)anObject
{
    [textField setStringValue:anObject || ""];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        textField = [self subviews][0];
    }

    return self;
}

@end
