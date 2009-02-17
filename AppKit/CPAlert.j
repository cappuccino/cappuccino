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

@import <AppKit/CPApplication.j>
@import <AppKit/CPButton.j>
@import <AppKit/CPColor.j>
@import <AppKit/CPFont.j>
@import <AppKit/CPImage.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPPanel.j>
@import <AppKit/CPTextField.j>

/*
    @global
    @group CPAlertStyle
*/
CPWarningAlertStyle =        0;
/*
    @global
    @group CPAlertStyle
*/
CPInformationalAlertStyle =  1;
/*
    @global
    @group CPAlertStyle
*/
CPCriticalAlertStyle =       2;


var CPAlertWarningImage,
    CPAlertInformationImage,
    CPAlertErrorImage;

/*
    CPAlert is an alert panel that can be displayed modally to present the
    user with a message and one or more options.

    It can be used to display an information message (<pre>CPInformationalAlertStyle</pre>),
    a warning message (<pre>CPWarningAlertStyle</pre> - which is the default), or a critical
    alert (<pre>CPCriticalAlertStyle</pre>). In each case the user can be presented with one
    or more options by adding buttons using the <pre>addButtonWithTitle:</pre> method.

    The panel is displayed modally by calling <pre>runModal</pre> and once the user has
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
    CPPanel         _alertPanel;

    CPTextField     _messageLabel;
    CPImageView     _alertImageView;

    CPAlertStyle    _alertStyle;
    CPString        _windowTitle;
    int             _windowStyle;
    int             _buttonCount;
    CPArray         _buttons;

    id              _delegate;
}

+ (void)initialize
{
    if (self != CPAlert)
        return;

    var bundle = [CPBundle bundleForClass:[self class]];   

    CPAlertWarningImage     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPAlert/dialog-warning.png"] 
                                                                 size:CGSizeMake(32.0, 32.0)];
                                                             
    CPAlertInformationImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPAlert/dialog-information.png"] 
                                                                 size:CGSizeMake(32.0, 32.0)];
                                                                 
    CPAlertErrorImage       = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPAlert/dialog-error.png"] 
                                                                 size:CGSizeMake(32.0, 32.0)];
}

/*!
    Initializes a <pre>CPAlert</pre> panel with the default alert style (<pre>CPWarningAlertStyle</pre>).
*/
- (id)init
{
    self = [super init];
    
    if (self)
    {
        _buttonCount = 0;
        _buttons = [CPArray array];
        _alertStyle = CPWarningAlertStyle;
        
        _messageLabel = [[CPTextField alloc] initWithFrame:CGRectMake(57.0, 10.0, 220.0, 80.0)];
        [_messageLabel setFont:[CPFont systemFontOfSize:12.0]];
        [_messageLabel setLineBreakMode:CPLineBreakByWordWrapping];
        [_messageLabel setAlignment:CPJustifiedTextAlignment];
        
        _alertImageView = [[CPImageView alloc] initWithFrame:CGRectMake(15.0, 12.0, 32.0, 32.0)];
        
        [self setWindowStyle:nil];
    }
    
    return self;
}

/*!
    Sets the window appearance.
    @param styleMask - Either CPHUDBackgroundWindowMask or nil for standard.
*/
- (void)setWindowStyle:(int)styleMask
{
    _windowStyle = styleMask;
    
    _alertPanel = [[CPPanel alloc] initWithContentRect:CGRectMake(0.0, 0.0, 300.0, 130.0) styleMask:styleMask ? styleMask | CPTitledWindowMask : CPTitledWindowMask];
    [_alertPanel setFloatingPanel:YES];
    [_alertPanel center];
    
    [_messageLabel setTextColor:(styleMask == CPHUDBackgroundWindowMask) ? [CPColor whiteColor] : [CPColor blackColor]];
    
    var count = [_buttons count];
    for(var i=0; i < count; i++)
    {
        var button = _buttons[i];
        
        [button setFrameSize:CGSizeMake([button frame].size.width, (styleMask == CPHUDBackgroundWindowMask) ? 20.0 : 18.0)];
        [button setBezelStyle:(styleMask == CPHUDBackgroundWindowMask) ? CPHUDBezelStyle : CPRoundedBezelStyle];
        
        [[_alertPanel contentView] addSubview:button];
    }
    
    [[_alertPanel contentView] addSubview:_messageLabel];
    [[_alertPanel contentView] addSubview:_alertImageView];
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
    Set’s the receiver’s message text, or title, to a given text.
    @param messageText - Message text for the alert.
*/
- (void)setMessageText:(CPString)messageText
{
    [_messageLabel setStringValue:messageText];
}

/*! 
    Return's the receiver's message text body.
*/
- (CPString)messageText
{
    return [_messageLabel stringValue];
}

/*!
    Adds a button with a given title to the receiver.
    Buttons will be added starting from the right hand side of the <pre>CPAlert</pre> panel.
    The first button will have the index 0, the second button 1 and so on.

    You really shouldn't need more than 3 buttons.
*/
- (void)addButtonWithTitle:(CPString)title
{
    var button = [[CPButton alloc] initWithFrame:CGRectMake(200.0 - (_buttonCount * 90.0), 98.0, 80.0, (_windowStyle == CPHUDBackgroundWindowMask) ? 20.0 : 18.0)];
    
    [button setTitle:title];
    [button setTarget:self];
    [button setTag:_buttonCount];
    [button setAction:@selector(_notifyDelegate:)];
    
    [button setBezelStyle:(_windowStyle == CPHUDBackgroundWindowMask) ? CPHUDBezelStyle : CPRoundRectBezelStyle];
    [[_alertPanel contentView] addSubview:button];
    
    _buttonCount++;
    [_buttons addObject:button];
}

/*!
    Displays the <pre>CPAlert</pre> panel as a modal dialog. The user will not be
    able to interact with any other controls until s/he has dismissed the alert
    by clicking on one of the buttons.
*/
- (void)runModal
{
    var theTitle;
    
    switch (_alertStyle)
    {
        case CPWarningAlertStyle:       [_alertImageView setImage:CPAlertWarningImage];
                                        theTitle = @"Warning";
                                        break;
        case CPInformationalAlertStyle: [_alertImageView setImage:CPAlertInformationImage];
                                        theTitle = @"Information";
                                        break;
        case CPCriticalAlertStyle:      [_alertImageView setImage:CPAlertErrorImage];
                                        theTitle = @"Error";
                                        break;
    }
    
    [_alertPanel setTitle:_windowTitle ? _windowTitle : theTitle];
    
    [CPApp runModalForWindow:_alertPanel];
}

/* @ignore */
- (void)_notifyDelegate:(id)button
{
    if (_delegate && [_delegate respondsToSelector:@selector(alertDidEnd:returnCode:)])
        [_delegate alertDidEnd:self returnCode:[button tag]];

    [CPApp abortModal];
    [_alertPanel close];
}

@end
