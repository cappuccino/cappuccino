/*
 * CPAlert.j
 * AppKit
 *
 * Created by Jake MacMullin.
 * Copyright 2008, Jake MacMullin.
 *
 * 11/10/2008 Ross Boucher
 *     - Make it conform to style guidelines, general cleanup and ehancements
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>

@import "CPApplication.j"
@import "CPButton.j"
@import "CPColor.j"
@import "CPFont.j"
@import "CPImage.j"
@import "CPImageView.j"
@import "CPPanel.j"
@import "CPTextField.j"

/*
    @global
    @group CPAlertStyle
*/
CPWarningAlertStyle         = 0;
/*
    @global
    @group CPAlertStyle
*/
CPInformationalAlertStyle   = 1;
/*
    @global
    @group CPAlertStyle
*/
CPCriticalAlertStyle        = 2;

/*!
    @ingroup appkit

    CPAlert is an alert panel that can be displayed modally to present the
    user with a message and one or more options.

    It can be used to display an information message \c CPInformationalAlertStyle,
    a warning message \c CPWarningAlertStyle (the default), or a critical
    alert \c CPCriticalAlertStyle. In each case the user can be presented with one
    or more options by adding buttons using the \c -addButtonWithTitle: method.

    The panel is displayed modally by calling \c -runModal and once the user has
    dismissed the panel, a message will be sent to the panel's delegate (if set), informing
    it which button was clicked (see delegate methods).

    @delegate -(void)alertDidEnd:(CPAlert)theAlert returnCode:(int)returnCode;
    Called when the user dismisses the alert by clicking one of the buttons.
    @param theAlert the alert panel that the user dismissed
    @param returnCode the index of the button that the user clicked (starting from 0,
           representing the first button added to the alert which appears on the
           right, 1 representing the next button to the left and so on)
*/
@implementation CPAlert : CPView
{
    CPPanel         _alertPanel;

    CPTextField     _messageLabel;
    CPTextField     _informativeLabel;
    CPImageView     _alertImageView;

    CPAlertStyle    _alertStyle;
    CPString        _windowTitle;
    int             _windowStyle;
    CPArray         _buttons;

    id              _delegate;
    SEL             _didEndSelector;
    id              _modalDelegate;
}

+ (CPString)defaultThemeClass
{
    return @"alert";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[CGSizeMake(400.0, 110.0), CGInsetMake(15, 15, 15, 50), 6, 10,
                                                CPJustifiedTextAlignment, [CPColor blackColor], [CPFont boldSystemFontOfSize:13.0], [CPNull null], CGSizeMakeZero(),
                                                CPJustifiedTextAlignment, [CPColor blackColor], [CPFont systemFontOfSize:12.0], [CPNull null], CGSizeMakeZero(),
                                                CGPointMake(15, 12),
                                                [CPNull null],
                                                [CPNull null],
                                                [CPNull null]
                                                ]
                                       forKeys:[@"size", @"content-inset", @"informative-offset", @"button-offset",
                                                @"message-text-alignment", @"message-text-color", @"message-text-font", @"message-text-shadow-color", @"message-text-shadow-offset",
                                                @"informative-text-alignment", @"informative-text-color", @"informative-text-font", @"informative-text-shadow-color", @"informative-text-shadow-offset",
                                                @"image-offset",
                                                @"information-image",
                                                @"warning-image",
                                                @"error-image"
                                                ]];
}

/*!
    Initializes a \c CPAlert panel with the default alert style \c CPWarningAlertStyle.
*/
- (id)init
{
    if (self = [super init])
    {
        _buttons = [CPArray array];
        _alertStyle = CPWarningAlertStyle;
        _alertPanel = nil;
        _windowStyle = nil;
        _didEndSelector = nil;

        _messageLabel = [CPTextField labelWithTitle:@"Alert"];
        _alertImageView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
        _informativeLabel = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    }

    return self;
}

/*!
    Sets the window appearance. If CPHUDBackgroundWindowMask is set, the default HUD theme
    will be activated.

    @param styleMask - Either CPHUDBackgroundWindowMask or nil for standard.
*/
- (void)setWindowStyle:(int)styleMask
{
    _windowStyle = styleMask;

    [self setTheme:(_windowStyle & CPHUDBackgroundWindowMask) ? [CPTheme defaultHudTheme] : [CPTheme defaultTheme]];

    // We'll need to recreate the panel to get the new window style.
    _alertPanel = nil;
}

- (void)_createPanel
{
    var frame = CGRectMakeZero();
    frame.size = [self currentValueForThemeAttribute:@"size"];
    _alertPanel = [[CPPanel alloc] initWithContentRect:frame styleMask:_windowStyle ? _windowStyle | CPTitledWindowMask : CPTitledWindowMask];

    var contentView = [_alertPanel contentView],
        count = [_buttons count];

    if (count)
    {
        while (count--)
            [contentView addSubview:_buttons[count]];
    }
    else
        [self addButtonWithTitle:@"OK"];

    [contentView addSubview:_messageLabel];
    [contentView addSubview:_alertImageView];
    [contentView addSubview:_informativeLabel];
}

/*!
    Sets the window's title. If this is not defined, a default title based on your warning level will be used.
    @param aTitle the title to use in place of the default. Set to nil to use default.
*/
- (void)setTitle:(CPString)aTitle
{
    _windowTitle = aTitle;
}

/*!
    Gets the window's title.
*/
- (CPString)title
{
    return _windowTitle;
}

/*!
    Gets the window's style.
*/
- (int)windowStyle
{
    return _windowStyle;
}

/*!
    Sets the receiver’s delegate.
    @param delegate - Delegate for the alert. nil removes the delegate.
*/
- (void)setDelegate:(id)delegate
{
    _delegate = delegate;
}

/*!
    Gets the receiver's delegate.
*/
- (void)delegate
{
    return _delegate;
}

/*!
    Sets the alert style of the receiver.
    @param style - Alert style for the alert.
*/
- (void)setAlertStyle:(CPAlertStyle)style
{
    _alertStyle = style;
}

/*!
    Gets the alert style.
*/
- (CPAlertStyle)alertStyle
{
    return _alertStyle;
}

/*!
    Sets the receiver’s message text, or title, to a given text.
    @param messageText - Message text for the alert.
*/
- (void)setMessageText:(CPString)messageText
{
    [_messageLabel setStringValue:messageText];
}

/*!
    Returns the receiver's message text body.
*/
- (CPString)messageText
{
    return [_messageLabel stringValue];
}

/*!
    Sets the receiver's informative text, shown below the message text.
    @param informativeText - The informative text.
*/
- (void)setInformativeText:(CPString)informativeText
{
    [_informativeLabel setStringValue:informativeText];
}

/*!
    Returns the receiver's informative text.
*/
- (CPString)informativeText
{
    return [_informativeLabel stringValue];
}

/*!
    Adds a button with a given title to the receiver.
    Buttons will be added starting from the right hand side of the \c CPAlert panel.
    The first button will have the index 0, the second button 1 and so on.

    The first button will automatically be given a key equivalent of Return,
    and any button titled "Cancel" will be given a key equivalent of Escape.

    You really shouldn't need more than 3 buttons.
*/
- (void)addButtonWithTitle:(CPString)title
{
    var bounds = [[_alertPanel contentView] bounds],
        button = [[CPButton alloc] initWithFrame:CGRectMakeZero()],
        _buttonCount = [_buttons count];

    [button setTitle:title];
    [button setTarget:self];
    [button setTag:_buttonCount];
    [button setAction:@selector(_dismissAlert:)];

    [[_alertPanel contentView] addSubview:button];

    if (_buttonCount == 0)
        [button setKeyEquivalent:CPCarriageReturnCharacter];
    else if ([title lowercaseString] === "cancel")
        [button setKeyEquivalent:CPEscapeFunctionKey];
    else
        [button setKeyEquivalent:nil];

    [_buttons insertObject:button atIndex:0];
}

- (void)layoutPanel
{
    if (!_alertPanel)
        [self _createPanel];

    var inset = [self currentValueForThemeAttribute:@"content-inset"],
        iconOffset = [self currentValueForThemeAttribute:@"image-offset"],
        theTitle,
        theImage;

    switch (_alertStyle)
    {
        case CPWarningAlertStyle:       theImage = [self currentValueForThemeAttribute:@"warning-image"];
                                        theTitle = @"Warning";
                                        break;
        case CPInformationalAlertStyle: theImage = [self currentValueForThemeAttribute:@"information-image"];
                                        theTitle = @"Information";
                                        break;
        case CPCriticalAlertStyle:      theImage = [self currentValueForThemeAttribute:@"error-image"];
                                        theTitle = @"Error";
                                        break;
    }

    [_alertImageView setImage:theImage];

    var imageSize = theImage ? [theImage size] : CGSizeMakeZero();
    [_alertImageView setFrame:CGRectMake(iconOffset.x, iconOffset.y, imageSize.width, imageSize.height)];

    [_alertPanel setTitle:_windowTitle ? _windowTitle : theTitle];
    [_alertPanel setFloatingPanel:YES];
    [_alertPanel center];

    [_messageLabel setTextColor:[self currentValueForThemeAttribute:@"message-text-color"]];
    [_messageLabel setFont:[self currentValueForThemeAttribute:@"message-text-font"]];
    [_messageLabel setTextShadowColor:[self currentValueForThemeAttribute:@"message-text-shadow-color"]];
    [_messageLabel setTextShadowOffset:[self currentValueForThemeAttribute:@"message-text-shadow-offset"]];
    [_messageLabel setAlignment:[self currentValueForThemeAttribute:@"message-text-alignment"]];
    [_messageLabel setLineBreakMode:CPLineBreakByWordWrapping];

    [_informativeLabel setTextColor:[self currentValueForThemeAttribute:@"informative-text-color"]];
    [_informativeLabel setFont:[self currentValueForThemeAttribute:@"informative-text-font"]];
    [_informativeLabel setTextShadowColor:[self currentValueForThemeAttribute:@"informative-text-shadow-color"]];
    [_informativeLabel setTextShadowOffset:[self currentValueForThemeAttribute:@"informative-text-shadow-offset"]];
    [_informativeLabel setLineBreakMode:CPLineBreakByWordWrapping];

    // FIXME sizeWithFontCorrection shouldn't be needed.
    var bounds = [[_alertPanel contentView] bounds],
        offsetX = CGRectGetWidth(bounds) - inset.right,
        informativeOffset = [self currentValueForThemeAttribute:@"informative-offset"],
        buttonOffset = [self currentValueForThemeAttribute:@"button-offset"],

        textWidth = offsetX - inset.left,
        messageSize = [([_messageLabel stringValue] || " ") sizeWithFont:[_messageLabel font] inWidth:textWidth],
        informationString = [_informativeLabel stringValue],
        informativeSize = [(informationString || " ") sizeWithFont:[_informativeLabel font] inWidth:textWidth],
        sizeWithFontCorrection = 6.0;

    [_messageLabel setFrame:CGRectMake(inset.left, inset.top, textWidth, messageSize.height + sizeWithFontCorrection)];
    [_informativeLabel setFrame:CGRectMake(inset.left, CGRectGetMaxY([_messageLabel frame]) + informativeOffset, textWidth, informativeSize.height + sizeWithFontCorrection)];
    // Don't let an empty informative label partially cover the buttons.
    [_informativeLabel setHidden:!informationString];

    var aRepresentativeButton = _buttons[0],
        buttonY = MAX(CGRectGetMaxY([_alertImageView frame]), CGRectGetMaxY(informationString ? [_informativeLabel frame] : [_messageLabel frame])) + buttonOffset; // the lower of the bottom of the text and the bottom of the icon.

    [aRepresentativeButton setTheme:[self theme]];
    [aRepresentativeButton sizeToFit];

    // Make the window just tall enough to fit everything. Bit of a hack really.
    var minimumSize = [self currentValueForThemeAttribute:@"size"],
        desiredHeight = MAX(minimumSize.height, buttonY + CGRectGetHeight([aRepresentativeButton bounds]) + inset.bottom),
        deltaY = desiredHeight - CGRectGetHeight(bounds),
        frameSize = CGSizeMakeCopy([_alertPanel frame].size);

    frameSize.height += deltaY;
    [_alertPanel setFrameSize:frameSize];

    var count = [_buttons count];

    while (count--)
    {
        var button = _buttons[count];
        [button setTheme:[self theme]];
        [button sizeToFit];

        var buttonBounds = [button bounds],
            width = MAX(80.0, CGRectGetWidth(buttonBounds)),
            height = CGRectGetHeight(buttonBounds);

        offsetX -= width;
        [button setFrame:CGRectMake(offsetX, buttonY, width, height)];
        offsetX -= 10;
    }
}

/*!
    Displays the \c CPAlert panel as a modal dialog. The user will not be
    able to interact with any other controls until s/he has dismissed the alert
    by clicking on one of the buttons.
*/
- (void)runModal
{
    [self layoutPanel];
    [CPApp runModalForWindow:_alertPanel];
}

/*!
    Runs the receiver modally as an alert sheet attached to a specified window.

    @param window The parent window for the sheet.
    @param modalDelegate The delegate for the modal-dialog session.
    @param alertDidEndSelector Message the alert sends to modalDelegate after the sheet is dismissed.
    @param contextInfo Contextual data passed to modalDelegate in didEndSelector message.
*/
- (void)beginSheetModalForWindow:(CPWindow)window modalDelegate:(id)modalDelegate didEndSelector:(SEL)alertDidEndSelector contextInfo:(void)contextInfo
{
    if (!(_windowStyle & CPDocModalWindowMask))
        [self setWindowStyle:CPDocModalWindowMask];
    [self layoutPanel];

    _didEndSelector = alertDidEndSelector;
    _modalDelegate = modalDelegate;

    [CPApp beginSheet:_alertPanel modalForWindow:window modalDelegate:self didEndSelector:@selector(_alertDidEnd:returnCode:contextInfo:) contextInfo:contextInfo];
}

/*!
    Runs the receiver modally as an alert sheet attached to a specified window.

    @param window The parent window for the sheet.
*/
- (void)beginSheetModalForWindow:(CPWindow)window
{
    if (!(_windowStyle & CPDocModalWindowMask))
        [self setWindowStyle:CPDocModalWindowMask];
    [self layoutPanel];

    [CPApp beginSheet:_alertPanel modalForWindow:window modalDelegate:self didEndSelector:@selector(_alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)_alertDidEnd:(CPWindow)aSheet returnCode:(CPInteger)returnCode contextInfo:(id)contextInfo
{
    if ([_delegate respondsToSelector:@selector(alertDidEnd:returnCode:)])
            [_delegate alertDidEnd:self returnCode:returnCode];

    if (_didEndSelector)
        objj_msgSend(_modalDelegate, _didEndSelector, self, returnCode, contextInfo);

    _didEndSelector = nil;
    _modalDelegate = nil;
}

/* @ignore */
- (void)_dismissAlert:(CPButton)button
{
    if ([_alertPanel isSheet])
        [CPApp endSheet:_alertPanel returnCode:[button tag]];
    else
    {
        [CPApp abortModal];
        [_alertPanel close];

        [self _alertDidEnd:nil returnCode:[button tag] contextInfo:nil];
    }
}

@end
