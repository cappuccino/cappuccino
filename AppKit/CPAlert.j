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

var CPAlertLabelOffset      = 3.0;

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
    CPTextField     _messageLabel       @accessors(getter=messageText);
    CPTextField     _informativeLabel   @accessors(getter=informativeText);
    CPAlertStyle    _alertStyle         @accessors(property=alertStyle);
    id              _delegate           @accessors(property=delegate);
    CPView          _accessoryView      @accessors(property=accessoryView);


    CPImageView     _alertImageView;

    int             _windowStyle;
    CPArray         _buttons;

    CPPanel         _alertPanel;
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
                                                [CPNull null],
                                                [CPNull null]
                                                ]
                                       forKeys:[@"size", @"content-inset", @"informative-offset", @"button-offset",
                                                @"message-text-alignment", @"message-text-color", @"message-text-font", @"message-text-shadow-color", @"message-text-shadow-offset",
                                                @"informative-text-alignment", @"informative-text-color", @"informative-text-font", @"informative-text-shadow-color", @"informative-text-shadow-offset",
                                                @"image-offset",
                                                @"information-image",
                                                @"warning-image",
                                                @"error-image",
                                                @"bezel-color"
                                                ]];
}

+ alertWithMessageText:(CPString)aMessage defaultButton:(CPString)defaultButtonText alternateButton:(CPString)alternateButtonText otherButton:(CPString)otherButtonText informativeTextWithFormat:(CPString)informativeText
{
    var alert = [[CPAlert alloc] init];

    [alert setMessageText:aMessage];
    [alert addButtonWithTitle:defaultButtonText];

    if (alternateButtonText)
        [alert addButtonWithTitle:alternateButtonText];

    if (otherButtonText)
        [alert addButtonWithTitle:otherButtonText];

    if (informativeText)
        [alert setInformativeText:informativeText];

    return alert;
}

+ alertWithError:(CPString)anErrorMessage
{
    var alert = [[CPAlert alloc] init];

    [alert setMessageText:anErrorMessage];
    [alert setStyle:CPCriticalAlertStyle];

    return alert;
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
        _didEndSelector = nil;

        _messageLabel = [CPTextField labelWithTitle:@"Alert"];
        _alertImageView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
        _informativeLabel = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    }

    return self;
}

- (void)_createPanelWithStyle:(int)forceStyle
{
    var frame = CGRectMakeZero(),
        styleMask = [self currentValueForThemeAttribute:@"bezel-color"] ? CPBorderlessWindowMask : CPTitledWindowMask;

    frame.size = [self currentValueForThemeAttribute:@"size"];

    _alertPanel = [[CPPanel alloc] initWithContentRect:frame styleMask:forceStyle || styleMask];

    [_alertPanel setMovableByWindowBackground:YES];

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
    Gets the window
*/
- (CPWindow)window
{
    return [_alertPanel window];
}

- (void)setMessageText:(CPString)aText
{
    [_messageLabel setStringValue:aText];
}

- (void)setInformativeText:(CPString)aText
{
    [_informativeLabel setStringValue:aText];
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


- (void)_layoutMessageView
{
    var inset = [self currentValueForThemeAttribute:@"content-inset"],
        sizeWithFontCorrection = 6.0,
        messageLabelWidth,
        messageLabelTextSize;

    [_messageLabel setTextColor:[self currentValueForThemeAttribute:@"message-text-color"]];
    [_messageLabel setFont:[self currentValueForThemeAttribute:@"message-text-font"]];
    [_messageLabel setTextShadowColor:[self currentValueForThemeAttribute:@"message-text-shadow-color"]];
    [_messageLabel setTextShadowOffset:[self currentValueForThemeAttribute:@"message-text-shadow-offset"]];
    [_messageLabel setAlignment:[self currentValueForThemeAttribute:@"message-text-alignment"]];
    [_messageLabel setLineBreakMode:CPLineBreakByWordWrapping];

    messageLabelWidth = [_alertPanel frame].size.width - inset.left - inset.right,
    messageLabelTextSize = [[_messageLabel stringValue] sizeWithFont:[_messageLabel font] inWidth:messageLabelWidth];

    [_messageLabel setFrame:CGRectMake(inset.left, inset.top, messageLabelTextSize.width, messageLabelTextSize.height + sizeWithFontCorrection)];
}


#pragma mark -
#pragma mark Layouting

/*! @ignore
*/
- (void)_layoutInformativeView
{
    var inset = [self currentValueForThemeAttribute:@"content-inset"],
        sizeWithFontCorrection = 6.0,
        informativeLabelWidth,
        informativeLabelOriginY,
        informativeLabelTextSize;

    [_informativeLabel setTextColor:[self currentValueForThemeAttribute:@"informative-text-color"]];
    [_informativeLabel setFont:[self currentValueForThemeAttribute:@"informative-text-font"]];
    [_informativeLabel setTextShadowColor:[self currentValueForThemeAttribute:@"informative-text-shadow-color"]];
    [_informativeLabel setTextShadowOffset:[self currentValueForThemeAttribute:@"informative-text-shadow-offset"]];
    [_informativeLabel setLineBreakMode:CPLineBreakByWordWrapping];

    informativeLabelWidth = [_alertPanel frame].size.width - inset.left - inset.right,
    informativeLabelOriginY = [_messageLabel frameOrigin].y + [_messageLabel frameSize].height + CPAlertLabelOffset,
    informativeLabelTextSize = [[_informativeLabel stringValue] sizeWithFont:[_informativeLabel font] inWidth:informativeLabelWidth];

    [_informativeLabel setFrame:CGRectMake(inset.left, informativeLabelOriginY, informativeLabelTextSize.width, informativeLabelTextSize.height + sizeWithFontCorrection)];
}

/*! @ignore
*/
- (void)_layoutAccessoryView
{
    if (_accessoryView)
    {
        var inset = [self currentValueForThemeAttribute:@"content-inset"],
            accessoryViewWidth = [_alertPanel frame].size.width - inset.left - inset.right,
            accessoryViewOriginY = CPRectGetMaxY([_informativeLabel frame]) + CPAlertLabelOffset;

        [_accessoryView setFrameOrigin:CGPointMake(inset.left, accessoryViewOriginY)];
        [[_alertPanel contentView] addSubview:_accessoryView];
    }
}

/*! @ignore
*/
- (CGSize)_layoutButtonsFromView:(CPView)lastView
{
    var inset = [self currentValueForThemeAttribute:@"content-inset"],
        minimumSize = [self currentValueForThemeAttribute:@"size"],
        buttonOffset = [self currentValueForThemeAttribute:@"button-offset"],
        aRepresentativeButton = [_buttons objectAtIndex:0],
        panelSize = [_alertPanel frame].size,
        buttonsOriginY,
        offsetX;

    [aRepresentativeButton setTheme:[self theme]];
    [aRepresentativeButton sizeToFit];

    panelSize.height = CPRectGetMaxY([lastView frame]) + CPAlertLabelOffset + [aRepresentativeButton frameSize].height;

    if (panelSize.height < minimumSize.height)
        panelSize.height = minimumSize.height;

    buttonsOriginY = panelSize.height - [aRepresentativeButton frameSize].height + buttonOffset,
    offsetX = panelSize.width - inset.right;

    for (var i = [_buttons count] - 1; i >= 0 ; i--)
    {
        var button = _buttons[i];

        [button setTheme:[self theme]];
        [button sizeToFit];

        var buttonFrame = [button frame],
            width = MAX(80.0, CGRectGetWidth(buttonFrame)),
            height = CGRectGetHeight(buttonFrame);

        offsetX -= width;
        [button setFrame:CGRectMake(offsetX, buttonsOriginY, width, height)];
        offsetX -= 10;
    }

    panelSize.height += [aRepresentativeButton frameSize].height + inset.bottom + buttonOffset;
    return panelSize;
}

/*! @ignore
*/
- (void)layoutPanel
{
    if (!_alertPanel)
        [self _createPanelWithStyle:nil];

    var iconOffset = [self currentValueForThemeAttribute:@"image-offset"],
        theTitle = @"",
        theImage,
        finalSize;

    switch (_alertStyle)
    {
        case CPWarningAlertStyle:
            theImage = [self currentValueForThemeAttribute:@"warning-image"];
            theTitle = "Warning";
            break;
        case CPInformationalAlertStyle:
            theImage = [self currentValueForThemeAttribute:@"information-image"];
            theTitle = "Information";
            break;
        case CPCriticalAlertStyle:
            theImage = [self currentValueForThemeAttribute:@"error-image"];
            theTitle = @"Critical";
            break;
    }

    if ([_alertPanel styleMask] == CPTitledWindowMask)
        [_alertPanel setTitle:theTitle];

    [_alertImageView setImage:theImage];

    var imageSize = theImage ? [theImage size] : CGSizeMakeZero();
    [_alertImageView setFrame:CGRectMake(iconOffset.x, iconOffset.y, imageSize.width, imageSize.height)];

    [_alertPanel setFloatingPanel:YES];
    [_alertPanel center];
    [[_alertPanel contentView] setBackgroundColor:[self currentValueForThemeAttribute:@"bezel-color"]];


    [self _layoutMessageView];
    [self _layoutInformativeView];
    [self _layoutAccessoryView];
    finalSize = [self _layoutButtonsFromView:(_accessoryView || _informativeLabel)];

    if (([_alertPanel styleMask] & CPDocModalWindowMask) || ([_alertPanel styleMask] & CPBorderlessWindowMask))
        finalSize.height -= 26; // adjust the absence of title bar

    //alert panel size resetting
    [_alertPanel setFrameSize:finalSize];
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
    if (!([_alertPanel styleMask] & CPDocModalWindowMask))
        [self _createPanelWithStyle:CPDocModalWindowMask]
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
