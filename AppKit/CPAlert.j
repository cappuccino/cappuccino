/*
 * CPAlert.j
 * AppKit
 *
 * Created by Jake MacMullin.
 * Copyright 2008, Jake MacMullin.
 *
 * 11/10/2008 Ross Boucher
 *     - Make it conform to style guidelines, general cleanup and enhancements
 * 11/10/2010 Antoine Mercadal
 *     - Enhancements, better compliance with Cocoa API
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

@import "CPButton.j"
@import "CPColor.j"
@import "CPFont.j"
@import "CPImage.j"
@import "CPImageView.j"
@import "CPPanel.j"
@import "CPText.j"
@import "CPTextField.j"

@class CPCheckBox

@global CPApp

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

var bottomHeight = 71;

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
@implementation CPAlert : CPObject
{
    BOOL                _showHelp               @accessors(property=showsHelp);
    BOOL                _showSuppressionButton  @accessors(property=showsSuppressionButton);

    CPAlertStyle        _alertStyle             @accessors(property=alertStyle);
    CPString            _title                  @accessors(property=title);
    CPView              _accessoryView          @accessors(property=accessoryView);
    CPImage             _icon                   @accessors(property=icon);

    CPArray             _buttons                @accessors(property=buttons, readonly);
    CPCheckBox          _suppressionButton      @accessors(property=suppressionButton, readonly);

    id                  _delegate               @accessors(property=delegate);
    id                  _modalDelegate;
    SEL                 _didEndSelector;

    _CPAlertThemeView   _themeView              @accessors(property=themeView, readonly);
    CPWindow            _window                 @accessors(property=window, readonly);
    int                 _defaultWindowStyle;

    CPImageView         _alertImageView;
    CPTextField         _informativeLabel;
    CPTextField         _messageLabel;
    CPButton            _alertHelpButton;

    BOOL                _needsLayout;
}

#pragma mark Creating Alerts

/*!
    Returns a CPAlert object with the provided info

    @param aMessage the main body text of the alert
    @param defaultButton the title of the default button
    @param alternateButton if not nil, the title of a second button
    @param otherButton if not nil, the title of the third button
    @param informativeText if not nil the informative text of the alert
    @return fully initialized CPAlert
*/
+ (CPAlert)alertWithMessageText:(CPString)aMessage defaultButton:(CPString)defaultButtonTitle alternateButton:(CPString)alternateButtonTitle otherButton:(CPString)otherButtonTitle informativeTextWithFormat:(CPString)informativeText
{
    var newAlert = [[self alloc] init];

    [newAlert setMessageText:aMessage];
    [newAlert addButtonWithTitle:defaultButtonTitle];

    if (alternateButtonTitle)
        [newAlert addButtonWithTitle:alternateButtonTitle];

    if (otherButtonTitle)
        [newAlert addButtonWithTitle:otherButtonTitle];

    if (informativeText)
        [newAlert setInformativeText:informativeText];

    return newAlert;
}

/*!
    Return an CPAlert with type error

    @param anErrorMessage the message of the alert
    @return fully initialized CPAlert
*/
+ (CPAlert)alertWithError:(CPString)anErrorMessage
{
    var newAlert = [[self alloc] init];

    [newAlert setMessageText:anErrorMessage];
    [newAlert setAlertStyle:CPCriticalAlertStyle];

    return newAlert;
}

/*!
    Initializes a \c CPAlert panel with the default alert style \c CPWarningAlertStyle.
*/
- (id)init
{
    self = [super init];

    if (self)
    {
        _buttons            = [];
        _alertStyle         = CPWarningAlertStyle;
        _showHelp           = NO;
        _needsLayout        = YES;
        _defaultWindowStyle = _CPModalWindowMask;
        _themeView          = [_CPAlertThemeView new];

        _messageLabel       = [CPTextField labelWithTitle:@"Alert"];
        _alertImageView     = [[CPImageView alloc] init];
        _informativeLabel   = [[CPTextField alloc] init];
        _suppressionButton  = [CPCheckBox checkBoxWithTitle:@"Do not show this message again"];

        _alertHelpButton    = [[CPButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)];
        [_alertHelpButton setTarget:self];
        [_alertHelpButton setAction:@selector(_showHelp:)];
    }

    return self;
}

#pragma mark Accessors

- (CPTheme)theme
{
    return [_themeView theme];
}

/*!
    set the theme to use

    @param the theme to use
*/
- (void)setTheme:(CPTheme)aTheme
{
    if (aTheme === [self theme])
        return;

    if (aTheme === [CPTheme defaultHudTheme])
        _defaultWindowStyle = CPTitledWindowMask | CPHUDBackgroundWindowMask;
    else
        _defaultWindowStyle = CPTitledWindowMask;

    _window = nil; // will be regenerated at next layout
    _needsLayout = YES;
    [_themeView setTheme:aTheme];
}

- (void)setValue:(id)aValue forThemeAttribute:(CPString)aName
{
    [_themeView setValue:aValue forThemeAttribute:aName];
}

- (void)setValue:(id)aValue forThemeAttribute:(CPString)aName inState:(CPThemeState)aState
{
    [_themeView setValue:aValue forThemeAttribute:aName inState:aState];
}


/*! @deprecated
*/
- (void)setWindowStyle:(int)aStyle
{
    CPLog.warn("DEPRECATED: setWindowStyle: is deprecated. use setTheme: instead");
    [self setTheme:(aStyle === CPHUDBackgroundWindowMask) ? [CPTheme defaultHudTheme] : [CPTheme defaultTheme]];
}

/*! @deprecated
*/
- (int)windowStyle
{
    CPLog.warn("DEPRECATED: windowStyle: is deprecated. use theme instead");
    return _defaultWindowStyle;
}


/*!
    set the text of the alert's message

    @param aText CPString containing the text
*/
- (void)setMessageText:(CPString)aText
{
    [_messageLabel setStringValue:aText];
    _needsLayout = YES;
}

/*!
    return the content of the message text
    @return CPString containing the message text
*/
- (CPString)messageText
{
    return [_messageLabel stringValue];
}

/*!
    set the text of the alert's informative text

    @param aText CPString containing the informative text
*/
- (void)setInformativeText:(CPString)aText
{
    [_informativeLabel setStringValue:aText];
    _needsLayout = YES;
}

/*!
    return the content of the message text

    @return CPString containing the message text
*/
- (CPString)informativeText
{
    return [_informativeLabel stringValue];
}

/*!
    Sets the title of the alert window.
    This API is not present in Cocoa.
    @param aTitle CPString containing the window title
*/
- (void)setTitle:(CPString)aTitle
{
    _title = aTitle;
    [_window setTitle:aTitle];
}

/*!
    set the accessory view

    @param aView the accessory view
*/
- (void)setAccessoryView:(CPView)aView
{
    _accessoryView = aView;
    _needsLayout = YES;
}

/*!
    set if alert shows the suppression button

    @param shouldShowSuppressionButton YES or NO
*/
- (void)setShowsSuppressionButton:(BOOL)shouldShowSuppressionButton
{
    _showSuppressionButton = shouldShowSuppressionButton;
    _needsLayout = YES;
}

#pragma mark Accessing Buttons

/*!
    Adds a button with a given title to the receiver.
    Buttons will be added starting from the right hand side of the \c CPAlert panel.
    The first button will have the index 0, the second button 1 and so on.

    The first button will automatically be given a key equivalent of Return,
    and any button titled "Cancel" will be given a key equivalent of Escape.

    You really shouldn't need more than 3 buttons.

    @param title the title of the button
*/
- (void)addButtonWithTitle:(CPString)aTitle
{
    var bounds = [[_window contentView] bounds],
        count = [_buttons count],

        button = [[CPButton alloc] initWithFrame:CGRectMakeZero()];

    [button setTitle:aTitle];
    [button setTag:count];
    [button setTarget:self];
    [button setAction:@selector(_takeReturnCodeFrom:)];

    [[_window contentView] addSubview:button];

    if (count == 0)
        [button setKeyEquivalent:CPCarriageReturnCharacter];
    else if ([aTitle lowercaseString] === @"cancel")
        [button setKeyEquivalent:CPEscapeFunctionKey];

    [_buttons insertObject:button atIndex:0];
}

#pragma mark Layout

/*!
    @ignore
*/
- (void)_layoutMessageView
{
    var inset = [_themeView currentValueForThemeAttribute:@"content-inset"],
        sizeWithFontCorrection = 6.0,
        messageLabelWidth,
        messageLabelTextSize;

    [_messageLabel setTextColor:[_themeView currentValueForThemeAttribute:@"message-text-color"]];
    [_messageLabel setFont:[_themeView currentValueForThemeAttribute:@"message-text-font"]];
    [_messageLabel setTextShadowColor:[_themeView currentValueForThemeAttribute:@"message-text-shadow-color"]];
    [_messageLabel setTextShadowOffset:[_themeView currentValueForThemeAttribute:@"message-text-shadow-offset"]];
    [_messageLabel setAlignment:[_themeView currentValueForThemeAttribute:@"message-text-alignment"]];
    [_messageLabel setLineBreakMode:CPLineBreakByWordWrapping];

    messageLabelWidth = CGRectGetWidth([[_window contentView] frame]) - inset.left - inset.right;
    messageLabelTextSize = [[_messageLabel stringValue] sizeWithFont:[_messageLabel font] inWidth:messageLabelWidth];

    [_messageLabel setFrame:CGRectMake(inset.left, inset.top, messageLabelTextSize.width, messageLabelTextSize.height + sizeWithFontCorrection)];
}

/*!
    @ignore
*/
- (void)_layoutInformativeView
{
    var inset = [_themeView currentValueForThemeAttribute:@"content-inset"],
        defaultElementsMargin = [_themeView currentValueForThemeAttribute:@"default-elements-margin"],
        sizeWithFontCorrection = 6.0,
        informativeLabelWidth,
        informativeLabelOriginY,
        informativeLabelTextSize;

    [_informativeLabel setTextColor:[_themeView currentValueForThemeAttribute:@"informative-text-color"]];
    [_informativeLabel setFont:[_themeView currentValueForThemeAttribute:@"informative-text-font"]];
    [_informativeLabel setTextShadowColor:[_themeView currentValueForThemeAttribute:@"informative-text-shadow-color"]];
    [_informativeLabel setTextShadowOffset:[_themeView currentValueForThemeAttribute:@"informative-text-shadow-offset"]];
    [_informativeLabel setAlignment:[_themeView currentValueForThemeAttribute:@"informative-text-alignment"]];
    [_informativeLabel setLineBreakMode:CPLineBreakByWordWrapping];

    informativeLabelWidth = CGRectGetWidth([[_window contentView] frame]) - inset.left - inset.right;
    informativeLabelOriginY = [_messageLabel frameOrigin].y + [_messageLabel frameSize].height + defaultElementsMargin;
    informativeLabelTextSize = [[_informativeLabel stringValue] sizeWithFont:[_informativeLabel font] inWidth:informativeLabelWidth];

    [_informativeLabel setFrame:CGRectMake(inset.left, informativeLabelOriginY, informativeLabelTextSize.width, informativeLabelTextSize.height + sizeWithFontCorrection)];
}

/*!
    @ignore
*/
- (void)_layoutAccessoryView
{
    if (!_accessoryView)
        return;

    var inset = [_themeView currentValueForThemeAttribute:@"content-inset"],
        defaultElementsMargin = [_themeView currentValueForThemeAttribute:@"default-elements-margin"],
        accessoryViewWidth = CGRectGetWidth([[_window contentView] frame]) - inset.left - inset.right,
        accessoryViewOriginY = CGRectGetMaxY([_informativeLabel frame]) + defaultElementsMargin;

    [_accessoryView setFrameOrigin:CGPointMake(inset.left, accessoryViewOriginY)];
    [[_window contentView] addSubview:_accessoryView];
}

/*!
    @ignore
*/
- (void)_layoutSuppressionButton
{
    if (!_showSuppressionButton)
        return;

    var inset = [_themeView currentValueForThemeAttribute:@"content-inset"],
        suppressionViewXOffset = [_themeView currentValueForThemeAttribute:@"suppression-button-x-offset"],
        suppressionViewYOffset = [_themeView currentValueForThemeAttribute:@"suppression-button-y-offset"],
        defaultElementsMargin = [_themeView currentValueForThemeAttribute:@"default-elements-margin"],
        suppressionButtonViewOriginY = CGRectGetMaxY([(_accessoryView || _informativeLabel) frame]) + defaultElementsMargin + suppressionViewYOffset;

    [_suppressionButton setTextColor:[_themeView currentValueForThemeAttribute:@"suppression-button-text-color"]];
    [_suppressionButton setFont:[_themeView currentValueForThemeAttribute:@"suppression-button-text-font"]];
    [_suppressionButton setTextShadowColor:[_themeView currentValueForThemeAttribute:@"suppression-button-text-shadow-color"]];
    [_suppressionButton setTextShadowOffset:[_themeView currentValueForThemeAttribute:@"suppression-button-text-shadow-offset"]];
    [_suppressionButton sizeToFit];

    [_suppressionButton setFrameOrigin:CGPointMake(inset.left + suppressionViewXOffset, suppressionButtonViewOriginY)];
    [[_window contentView] addSubview:_suppressionButton];
}

/*!
    @ignore
*/
- (CGSize)_layoutButtonsFromView:(CPView)lastView
{
    var inset = [_themeView currentValueForThemeAttribute:@"content-inset"],
        minimumSize = [_themeView currentValueForThemeAttribute:@"size"],
        buttonOffset = [_themeView currentValueForThemeAttribute:@"button-offset"],
        helpLeftOffset = [_themeView currentValueForThemeAttribute:@"help-image-left-offset"],
        aRepresentativeButton = [_buttons objectAtIndex:0],
        defaultElementsMargin = [_themeView currentValueForThemeAttribute:@"default-elements-margin"],
        panelSize = [[_window contentView] frame].size,
        buttonsOriginY,
        buttonMarginY,
        buttonMarginX,
        theme = [self theme],
        offsetX;

    [aRepresentativeButton setTheme:[self theme]];
    [aRepresentativeButton sizeToFit];

    panelSize.height = CGRectGetMaxY([lastView frame]) + defaultElementsMargin + [aRepresentativeButton frameSize].height;
    if (panelSize.height < minimumSize.height)
        panelSize.height = minimumSize.height;

    buttonsOriginY = panelSize.height - [aRepresentativeButton frameSize].height + buttonOffset;
    offsetX = panelSize.width - inset.right;

    switch ([_window styleMask])
    {
        case _CPModalWindowMask:
            buttonMarginY = [_themeView currentValueForThemeAttribute:@"modal-window-button-margin-y"];
            buttonMarginX = [_themeView currentValueForThemeAttribute:@"modal-window-button-margin-x"];
            break;

        default:
            buttonMarginY = [_themeView currentValueForThemeAttribute:@"standard-window-button-margin-y"];
            buttonMarginX = [_themeView currentValueForThemeAttribute:@"standard-window-button-margin-x"];
            break;
    }

    for (var i = [_buttons count] - 1; i >= 0 ; i--)
    {
        var button = _buttons[i];
        [button setTheme:[self theme]];
        [button sizeToFit];

        var buttonFrame = [button frame],
            width = MAX(80.0, CGRectGetWidth(buttonFrame)),
            height = CGRectGetHeight(buttonFrame);

        offsetX -= width;
        [button setFrame:CGRectMake(offsetX + buttonMarginX, buttonsOriginY + buttonMarginY, width, height)];
        offsetX -= 10;
    }

    if (_showHelp)
    {
        var helpImage = [_themeView currentValueForThemeAttribute:@"help-image"],
            helpImagePressed = [_themeView currentValueForThemeAttribute:@"help-image-pressed"],
            helpImageSize = helpImage ? [helpImage size] : CGSizeMakeZero(),
            helpFrame = CGRectMake(helpLeftOffset, buttonsOriginY, helpImageSize.width, helpImageSize.height);

        [_alertHelpButton setImage:helpImage];
        [_alertHelpButton setAlternateImage:helpImagePressed];
        [_alertHelpButton setBordered:NO];
        [_alertHelpButton setFrame:helpFrame];
    }

    panelSize.height += [aRepresentativeButton frameSize].height + inset.bottom + buttonOffset;
    return panelSize;
}

/*!
    @ignore
*/
- (void)layout
{
    if (!_needsLayout)
        return;

    if (!_window)
        [self _createWindowWithStyle:nil];

    var iconOffset = [_themeView currentValueForThemeAttribute:@"image-offset"],
        theImage = _icon,
        finalSize;

    if (!theImage)
        switch (_alertStyle)
        {
            case CPWarningAlertStyle:
                theImage = [_themeView currentValueForThemeAttribute:@"warning-image"];
                break;
            case CPInformationalAlertStyle:
                theImage = [_themeView currentValueForThemeAttribute:@"information-image"];
                break;
            case CPCriticalAlertStyle:
                theImage = [_themeView currentValueForThemeAttribute:@"error-image"];
                break;
        }

    [_alertImageView setImage:theImage];

    var imageSize = theImage ? [theImage size] : CGSizeMakeZero();
    [_alertImageView setFrame:CGRectMake(iconOffset.x, iconOffset.y, imageSize.width, imageSize.height)];

    [self _layoutMessageView];
    [self _layoutInformativeView];
    [self _layoutAccessoryView];
    [self _layoutSuppressionButton];

    var lastView = _informativeLabel;
    if (_showSuppressionButton)
        lastView = _suppressionButton;
    else if (_accessoryView)
        lastView = _accessoryView;

    finalSize = [self _layoutButtonsFromView:lastView];
    if ([_window styleMask] & CPDocModalWindowMask)
        finalSize.height -= 26; // adjust the absence of title bar

    [_window setFrameSize:finalSize];
    [_window center];

    if ([_window styleMask] & _CPModalWindowMask || [_window styleMask] & CPHUDBackgroundWindowMask)
    {
        [_window setMovable:YES];
        [_window setMovableByWindowBackground:YES];
    }

    _needsLayout = NO;
}

#pragma mark Displaying Alerts

/*!
    Displays the \c CPAlert panel as a modal dialog. The user will not be
    able to interact with any other controls until s/he has dismissed the alert
    by clicking on one of the buttons.
*/
- (void)runModal
{
    if (!([_window styleMask] & _defaultWindowStyle))
    {
        _needsLayout = YES;
        [self _createWindowWithStyle:_defaultWindowStyle];
    }

    [self layout];
    [CPApp runModalForWindow:_window];
}

/*!
    Runs the receiver modally as an alert sheet attached to a specified window.

    @param window The parent window for the sheet.
    @param modalDelegate The delegate for the modal-dialog session.
    @param alertDidEndSelector Message the alert sends to modalDelegate after the sheet is dismissed.
    @param contextInfo Contextual data passed to modalDelegate in didEndSelector message.
*/
- (void)beginSheetModalForWindow:(CPWindow)aWindow modalDelegate:(id)modalDelegate didEndSelector:(SEL)alertDidEndSelector contextInfo:(id)contextInfo
{
    if (!([_window styleMask] & CPDocModalWindowMask))
    {
        _needsLayout = YES;
        [self _createWindowWithStyle:CPDocModalWindowMask];
    }

    [self layout];

    _modalDelegate = modalDelegate;
    _didEndSelector = alertDidEndSelector;

    [CPApp beginSheet:_window modalForWindow:aWindow modalDelegate:self didEndSelector:@selector(_alertDidEnd:returnCode:contextInfo:) contextInfo:contextInfo];
}

/*!
    Runs the receiver modally as an alert sheet attached to a specified window.

    @param window The parent window for the sheet.
*/
- (void)beginSheetModalForWindow:(CPWindow)aWindow
{
    [self beginSheetModalForWindow:aWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

#pragma mark Private

/*!
    @ignore
*/
- (void)_createWindowWithStyle:(int)forceStyle
{
    var frame = CGRectMakeZero();
    frame.size = [_themeView currentValueForThemeAttribute:@"size"];

    _window = [[CPPanel alloc] initWithContentRect:frame styleMask:forceStyle || _defaultWindowStyle];
    [_window setLevel:CPStatusWindowLevel];
    [_window setPlatformWindow:[[CPApp keyWindow] platformWindow]];

    if (_title)
        [_window setTitle:_title];

    var contentView = [_window contentView],
        count = [_buttons count];

    if (count)
        while (count--)
            [contentView addSubview:_buttons[count]];
    else
        [self addButtonWithTitle:@"OK"];

    [contentView addSubview:_messageLabel];
    [contentView addSubview:_alertImageView];
    [contentView addSubview:_informativeLabel];

    if (_showHelp)
        [contentView addSubview:_alertHelpButton];
}

/*!
    @ignore
*/
- (@action)_showHelp:(id)aSender
{
    if ([_delegate respondsToSelector:@selector(alertShowHelp:)])
        [_delegate alertShowHelp:self];
}

/*
    @ignore
*/
- (@action)_takeReturnCodeFrom:(id)aSender
{
    if ([_window isSheet])
    {
        [_window orderOut:nil];
        [CPApp endSheet:_window returnCode:[aSender tag]];
    }
    else
    {
        [CPApp abortModal];
        [_window close];

        [self _alertDidEnd:_window returnCode:[aSender tag] contextInfo:nil];
    }
}

/*!
    @ignore
*/
- (void)_alertDidEnd:(CPWindow)aWindow returnCode:(int)returnCode contextInfo:(id)contextInfo
{
    if (_didEndSelector)
        objj_msgSend(_modalDelegate, _didEndSelector, self, returnCode, contextInfo);

    _modalDelegate = nil;
    _didEndSelector = nil;

    if ([_delegate respondsToSelector:@selector(alertDidEnd:returnCode:)])
        [_delegate alertDidEnd:self returnCode:returnCode];
}

@end

@implementation _CPAlertThemeView : CPView

+ (CPString)defaultThemeClass
{
    return @"alert";
}

+ (id)themeAttributes
{
    return @{
            @"size": CGSizeMake(400.0, 110.0),
            @"content-inset": CGInsetMake(15, 15, 15, 50),
            @"informative-offset": 6,
            @"button-offset": 10,
            @"message-text-alignment": CPJustifiedTextAlignment,
            @"message-text-color": [CPColor blackColor],
            @"message-text-font": [CPFont boldSystemFontOfSize:13.0],
            @"message-text-shadow-color": [CPNull null],
            @"message-text-shadow-offset": CGSizeMakeZero(),
            @"informative-text-alignment": CPJustifiedTextAlignment,
            @"informative-text-color": [CPColor blackColor],
            @"informative-text-font": [CPFont systemFontOfSize:12.0],
            @"informative-text-shadow-color": [CPNull null],
            @"informative-text-shadow-offset": CGSizeMakeZero(),
            @"image-offset": CGPointMake(15, 12),
            @"information-image": [CPNull null],
            @"warning-image": [CPNull null],
            @"error-image": [CPNull null],
            @"help-image": [CPNull null],
            @"help-image-left-offset": 15,
            @"help-image-pressed": [CPNull null],
            @"suppression-button-y-offset": 0.0,
            @"suppression-button-x-offset": 0.0,
            @"default-elements-margin": 3.0,
            @"suppression-button-text-color": [CPColor blackColor],
            @"suppression-button-text-font": [CPFont systemFontOfSize:12.0],
            @"suppression-button-text-shadow-color": [CPNull null],
            @"suppression-button-text-shadow-offset": 0.0,
            @"modal-window-button-margin-y": 0.0,
            @"modal-window-button-margin-x": 0.0,
            @"standard-window-button-margin-y": 0.0,
            @"standard-window-button-margin-x": 0.0,
        };
}

@end
