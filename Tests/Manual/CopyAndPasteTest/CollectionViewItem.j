@import <AppKit/AppKit.j>
@import <AppKit/CPCollectionViewItem.j>
@import <AppKit/CPImage.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPTextField.j>

@implementation CollectionViewItem : CPCollectionViewItem
{
}

@end

@implementation CollectionViewView : CPView
{
    @outlet CPTextField textField @accessors;
    @outlet CPImageView imageView @accessors;

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
    var stringValue = [anObject isKindOfClass:CPString] ? anObject : "",
        image = [anObject isKindOfClass:CPImage] ? anObject : nil;

    [textField setStringValue:stringValue];
    [imageView setImage:image];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        textField = [self subviews][1];
        imageView = [self subviews][0];
    }

    return self;
}

@end
