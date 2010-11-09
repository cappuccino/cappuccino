/*
 * AppController.j
 * ButtonLayoutIssue
 *
 * Created by You on October 19, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

var ReadMeText = @"Click one of the Add Button buttons to create a button, \n" +
                  "then click \"Call sizeToFit\" twice with the index of the button.";

@implementation AppController : CPObject
{
  CPView contentView;
  CPView _navBar;

  CPTextField _indexField;

  CPArray _contentStack;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];
    contentView = [theWindow contentView];

    var addOldButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];

    _contentStack = [CPArray array];

    _navBar = [[CPView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([contentView frame]), 30)];
    [_navBar setBackgroundColor:[CPColor redColor]];
    [contentView addSubview:_navBar];

    [addOldButton setTitle:@"Add Old Button"];

    [addOldButton sizeToFit];

    [addOldButton setTarget:self];
    [addOldButton setAction:@selector(addOldButton:)];

    [addOldButton setFrameOrigin:CGPointMake(10, CGRectGetMaxY([_navBar frame]) + 10)];

    [contentView addSubview:addOldButton];

    var addNewButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];

    [addNewButton setTitle:@"Add New Button"];

    [addNewButton sizeToFit];

    [addNewButton setTarget:self];
    [addNewButton setAction:@selector(addNewButton:)];

    [addNewButton setFrameOrigin:CGPointMake(CGRectGetMaxX([addOldButton frame]) + 10, CGRectGetMaxY([_navBar frame]) + 10)];

    [contentView addSubview:addNewButton];

    var sizeToFitButton = [CPButton buttonWithTitle:@"Call sizeToFit on button on button at index:"];

    [sizeToFitButton setFrameOrigin:CGPointMake(10, CGRectGetMaxY([addOldButton frame]) + 10)];
    [contentView addSubview:sizeToFitButton];
    [sizeToFitButton setTarget:self];
    [sizeToFitButton setAction:@selector(sizeButtonToFit:)];

    _indexField = [CPTextField textFieldWithStringValue:@"0" placeholder:@"" width:100];
    [_indexField setFrameOrigin:CGPointMake(
      CGRectGetMaxX([sizeToFitButton frame]) + 10,
      CGRectGetMinY([sizeToFitButton frame]) + (CGRectGetHeight([sizeToFitButton frame]) - CGRectGetHeight([_indexField frame])) / 2.0
    )];

    [contentView addSubview:_indexField];

    var readme = [CPTextField labelWithTitle:ReadMeText];

    [readme setFrameOrigin:CGPointMake(CGRectGetMinX([sizeToFitButton frame]), CGRectGetMaxY([sizeToFitButton frame]) + 10)];

    [contentView addSubview:readme];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (void)_rebuildNavBar
{
    var buttons = [_navBar subviews],
        xMargin = 15,
        xOffset = xMargin;

    for (var i = 0, count = [_contentStack count]; i < count; i++)
    {
        var navButton,
            title = [self titleForContentView:_contentStack[i] inViewWithToolbar:self];

        if (i < [buttons count])
            navButton = [buttons objectAtIndex:i];
        else
        {
            navButton = [[(title === "Broken" ? OldButton : CPButton) alloc] initWithFrame:CGRectMakeZero()];
            [buttons addObject:navButton];
            navButton._MMViewWithToolbar_index = i;
            [navButton setTarget:self];
            [navButton setAction:@selector(_navBaraddButton:)];
        }

        [navButton setTitle:title];
        [navButton sizeToFit];
        [navButton setFrameOrigin:CGPointMake(
            xOffset,
            (CGRectGetHeight([_navBar frame]) - CGRectGetHeight([navButton frame])) / 2.0
        )];

        xOffset = CGRectGetMaxX([navButton frame]) + xMargin;
        [navButton setHidden:NO];
    }

    for (var i = [_contentStack count]; i < [buttons count]; i++)
        [buttons[i] setHidden:YES];

    [_navBar setSubviews:buttons];
}

- (void)addOldButton:(id)sender
{
    [_contentStack addObject:"Broken"];
    [_indexField setStringValue:[CPString stringWithFormat:@"%d", [_contentStack count] - 1]];
    [self _rebuildNavBar];
}

- (void)addNewButton:(id)sender
{
    [_contentStack addObject:"Fixed"];
    [_indexField setStringValue:[CPString stringWithFormat:@"%d", [_contentStack count] - 1]];
    [self _rebuildNavBar];
}

- (void)sizeButtonToFit:(id)sender
{
    [[[_navBar subviews] objectAtIndex:[_indexField intValue]] sizeToFit];
}

- (CPString)titleForContentView:(id)aView inViewWithToolbar:(id)viewWithToolbar
{
    return [aView description];
}

@end

@implementation OldButton : CPButton

- (void)sizeToFit
{
    [self layoutSubviews];

    var size,
        contentView = [self ephemeralSubviewNamed:@"content-view"];

    if (contentView)
    {
        [contentView sizeToFit];
        size = [contentView frameSize];
    }
    else
    {
        size = [([self title] || " ") sizeWithFont:[self currentValueForThemeAttribute:@"font"]];
    }

    var contentInset = [self currentValueForThemeAttribute:@"content-inset"],
        minSize = [self currentValueForThemeAttribute:@"min-size"],
        maxSize = [self currentValueForThemeAttribute:@"max-size"];

    size.width = MAX(size.width + contentInset.left + contentInset.right, minSize.width);
    size.height = MAX(size.height + contentInset.top + contentInset.bottom, minSize.height);

    if (maxSize.width >= 0.0)
        size.width = MIN(size.width, maxSize.width);

    if (maxSize.height >= 0.0)
        size.height = MIN(size.height, maxSize.height);

    [self setFrameSize:size];

    // This bit is in the new version. Without it the layout is not displayed correctly.
    // if (contentView)
    //     [self layoutSubviews];

}

@end

@implementation _CPImageAndTextView (sizeToFitFix)

- (void)sizeToFit
{
    var size = CGSizeMakeZero();

    if ((_imagePosition !== CPNoImage) && _image)
    {
        var imageSize = [_image size];

        size.width += imageSize.width;
        size.height += imageSize.height;
    }

    if ((_imagePosition !== CPImageOnly) && [_text length] > 0)
    {
        if (!_textSize)
            _textSize = [_text sizeWithFont:_font ? _font : [CPFont systemFontOfSize:12.0]];

        if (_text === "Fixed")
        {
            // In the new code we make sure not to add the image offset if there is not image.
            if (!_image || _imagePosition === CPImageOverlaps)
            {
                size.width = MAX(size.width, _textSize.width);
                size.height = MAX(size.height, _textSize.height);
            }
            else if (_imagePosition === CPImageLeft || _imagePosition === CPImageRight)
            {
                size.width += _textSize.width + _imageOffset;
                size.height = MAX(size.height, _textSize.height);
            }
            else if (_imagePosition === CPImageAbove || _imagePosition === CPImageBelow)
            {
                size.width = MAX(size.width, _textSize.width);
                size.height += _textSize.height + _imageOffset;
            }
        }
        else
        {
            // In the old code, if there was no image and an image position other than CPImageOverlaps,
            // the image offset would mistakenly get added to the width.
            if (_imagePosition === CPImageLeft || _imagePosition === CPImageRight)
            {
                size.width += _textSize.width + _imageOffset;
                size.height = MAX(size.height, _textSize.height);
            }
            else if (_imagePosition === CPImageAbove || _imagePosition === CPImageBelow)
            {
                size.width = MAX(size.width, _textSize.width);
                size.height += _textSize.height + _imageOffset;
            }
            else // if (_imagePosition == CPImageOverlaps)
            {
                size.width = MAX(size.width, _textSize.width);
                size.height = MAX(size.height, _textSize.height);
            }
        }
    }

    [self setFrameSize:size];
}

@end
