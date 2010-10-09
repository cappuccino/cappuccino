/*
 * AppController.j
 * layoutEphemeralSubviewTest
 *
 * Created by Aparajita Fishman on October 8, 2010.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0, 0, 300, 250) styleMask:CPTitledWindowMask],
        contentView = [theWindow contentView],
        radio = [[OldRadio alloc] initWithFrame:CGRectMakeZero()];

    [theWindow center];
    [theWindow setTitle:@"layoutEphemeralSubview Test"];

    var label = [[CPTextField alloc] initWithFrame:CGRectMake(15, 15, 270, 80)];

    [label setLineBreakMode:CPLineBreakByWordWrapping];
    [label setStringValue:@"These checkboxes and radio buttons were created with an empty frame, then sized to fit. " +
                          @"Notice that the ones with the old code truncate the image, whereas the ones made with " +
                          @"the new code size correctly."];
    [label setFrameOrigin:CGPointMake(15, 20)];
    [contentView addSubview:label];

    label = [CPTextField labelWithTitle:@"Old code:"];
    [label setFrameOrigin:CGPointMake(15, 120)];
    [contentView addSubview:label];

    var checkbox = [[OldCheckBox alloc] initWithFrame:CGRectMakeZero()];

    [checkbox sizeToFit];
    [checkbox setFrameOrigin:CGPointMake(CGRectGetMaxX([label frame]) + 5, CGRectGetMinY([label frame]))];
    [contentView addSubview:checkbox];

    label = [CPTextField labelWithTitle:@"New code:"],
    [label setFrameOrigin:CGPointMake(15, CGRectGetMaxY([checkbox frame]) + 10)];
    [contentView addSubview:label];

    checkbox = [[CPCheckBox alloc] initWithFrame:CGRectMakeZero()];
    [checkbox sizeToFit];
    [checkbox setFrameOrigin:CGPointMake(CGRectGetMaxX([label frame]) + 5, CGRectGetMinY([label frame]))];
    [contentView addSubview:checkbox];

    label = [CPTextField labelWithTitle:@"Old code:"];
    [label setFrameOrigin:CGPointMake(15, CGRectGetMaxY([checkbox frame]) + 10)];
    [contentView addSubview:label];

    var radio = [[OldRadio alloc] initWithFrame:CGRectMakeZero()];

    [radio sizeToFit];
    [radio setFrameOrigin:CGPointMake(CGRectGetMaxX([label frame]) + 5, CGRectGetMinY([label frame]))];
    [contentView addSubview:radio];

    label = [CPTextField labelWithTitle:@"New code:"],
    [label setFrameOrigin:CGPointMake(15, CGRectGetMaxY([radio frame]) + 10)];
    [contentView addSubview:label];

    radio = [[CPRadio alloc] initWithFrame:CGRectMakeZero()];
    [radio sizeToFit];
    [radio setFrameOrigin:CGPointMake(CGRectGetMaxX([label frame]) + 5, CGRectGetMinY([label frame]))];
    [contentView addSubview:radio];

    [theWindow orderFront:self];
}

@end


@implementation OldCheckBox : CPCheckBox

- (CPView)layoutEphemeralSubviewNamed:(CPString)aViewName
                           positioned:(CPWindowOrderingMode)anOrderingMode
      relativeToEphemeralSubviewNamed:(CPString)relativeToViewName
{
    if (!_ephemeralSubviewsForNames)
    {
        _ephemeralSubviewsForNames = {};
        _ephemeralSubviews = [CPSet set];
    }

    var frame = [self rectForEphemeralSubviewNamed:aViewName];

    if (frame && !CGRectIsEmpty(frame))
    {
        if (!_ephemeralSubviewsForNames[aViewName])
        {
            _ephemeralSubviewsForNames[aViewName] = [self createEphemeralSubviewNamed:aViewName];

            [_ephemeralSubviews addObject:_ephemeralSubviewsForNames[aViewName]];

            if (_ephemeralSubviewsForNames[aViewName])
                [self addSubview:_ephemeralSubviewsForNames[aViewName] positioned:anOrderingMode relativeTo:_ephemeralSubviewsForNames[relativeToViewName]];
        }

        if (_ephemeralSubviewsForNames[aViewName])
            [_ephemeralSubviewsForNames[aViewName] setFrame:frame];
    }
    else if (_ephemeralSubviewsForNames[aViewName])
    {
        [_ephemeralSubviewsForNames[aViewName] removeFromSuperview];

        [_ephemeralSubviews removeObject:_ephemeralSubviewsForNames[aViewName]];
        delete _ephemeralSubviewsForNames[aViewName];
    }

    return _ephemeralSubviewsForNames[aViewName];
}

@end


@implementation OldRadio : CPRadio

- (CPView)layoutEphemeralSubviewNamed:(CPString)aViewName
                           positioned:(CPWindowOrderingMode)anOrderingMode
      relativeToEphemeralSubviewNamed:(CPString)relativeToViewName
{
    if (!_ephemeralSubviewsForNames)
    {
        _ephemeralSubviewsForNames = {};
        _ephemeralSubviews = [CPSet set];
    }

    var frame = [self rectForEphemeralSubviewNamed:aViewName];

    if (frame && !CGRectIsEmpty(frame))
    {
        if (!_ephemeralSubviewsForNames[aViewName])
        {
            _ephemeralSubviewsForNames[aViewName] = [self createEphemeralSubviewNamed:aViewName];

            [_ephemeralSubviews addObject:_ephemeralSubviewsForNames[aViewName]];

            if (_ephemeralSubviewsForNames[aViewName])
                [self addSubview:_ephemeralSubviewsForNames[aViewName] positioned:anOrderingMode relativeTo:_ephemeralSubviewsForNames[relativeToViewName]];
        }

        if (_ephemeralSubviewsForNames[aViewName])
            [_ephemeralSubviewsForNames[aViewName] setFrame:frame];
    }
    else if (_ephemeralSubviewsForNames[aViewName])
    {
        [_ephemeralSubviewsForNames[aViewName] removeFromSuperview];

        [_ephemeralSubviews removeObject:_ephemeralSubviewsForNames[aViewName]];
        delete _ephemeralSubviewsForNames[aViewName];
    }

    return _ephemeralSubviewsForNames[aViewName];
}

@end
