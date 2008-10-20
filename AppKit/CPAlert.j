/*
 * CPAlert.j
 * AppKit
 *
 * Created by Jake MacMullin.
 * Copyright 2008, Jake MacMullin.
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

import <Foundation/CPObject.j>
import <Foundation/CPString.j>

import <AppKit/CPApplication.j>
import <AppKit/CPButton.j>
import <AppKit/CPColor.j>
import <AppKit/CPFont.j>
import <AppKit/CPImage.j>
import <AppKit/CPImageView.j>
import <AppKit/CPPanel.j>
import <AppKit/CPTextField.j>

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

/*
    <objj>CPAlert</objj> is an alert panel that can be displayed modally to present the
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
	CPString         _messageText;
	CPPanel          _alertPanel;
	CPTextField      _messageLabel;
	CPAlertStyle     _alertStyle;
	int              _buttonCount;
	id               _delegate;
}

/*
    Initializes a <pre>CPAlert</pre> panel with the default alert style (<pre>CPWarningAlertStyle</pre>).
*/
- (id)init
{
	self = [super init];
	_buttonCount = 0;
	_alertStyle = CPWarningAlertStyle;
	
	_alertPanel = [[CPPanel alloc] initWithContentRect:CGRectMake(0, 0, 300, 150) styleMask:CPHUDBackgroundWindowMask|CPTitledWindowMask];
	[_alertPanel setFloatingPanel:YES];
	[_alertPanel center];
	
	_messageLabel = [[CPTextField alloc] initWithFrame: CGRectMake(70,10, 200, 100)];
    [_messageLabel setFont: [CPFont fontWithName: "Helvetica Neue" size: 12.0]];
    [_messageLabel setTextColor: [CPColor whiteColor]];
    [_messageLabel setLineBreakMode:CPLineBreakByWordWrapping];

	[[_alertPanel contentView] addSubview: _messageLabel];
	
	return self;
}

/*
    Sets the receiver’s delegate.
    @param delegate - Delegate for the alert. nil removes the delegate.
*/
- (void)setDelegate:(id)delegate
{
	_delegate = delegate;
}

/*
    Gets the receiver's delegate.
*/
- (void)delegate
{
	return _delegate;
}

/*
    Sets the alert style of the receiver.
	@param style - Alert style for the alert.
*/
- (void)setAlertStyle:(CPAlertStyle)style
{
	_alertStyle = style;
}

/*
    Gets the alert style.
*/
- (CPAlertStyle)alertStyle
{
	return _alertStyle;
}

/*
    Set’s the receiver’s message text, or title, to a given text.
    @param messageText - Message text for the alert.
*/
- (void)setMessageText:(CPString)messageText
{
	_messageText = messageText;
	[_messageLabel setStringValue:_messageText];
}

/*
    Adds a button with a given title to the receiver.
    Buttons will be added starting from the right hand side of the <pre>CPAlert</pre> panel.
    The first button will have the index 0, the second button 1 and so on.

    You really shouldn't need more than 3 buttons.
*/
- (void)addButtonWithTitle:(CPString)title
{
	var button = [[CPButton alloc] initWithFrame:CGRectMake(190 - (_buttonCount * 90),80,80,18)];
	[button setTitle:title];
	[button setTarget:self];
	[button setTag:_buttonCount];
	[button setAction:@selector(notifyDelegate:)];
	[[_alertPanel contentView] addSubview:button];
	_buttonCount++;
}

/*
    Displays the <pre>CPAlert</pre> panel as a modal dialog. The user will not be
    able to interact with any other controls until s/he has dismissed the alert
    by clicking on one of the buttons.
*/
- (void)runModal
{
	var alertImage;
	var bundle = [CPBundle bundleForClass:[self class]];
	switch (_alertStyle)
	{
	    case CPWarningAlertStyle:          alertImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPAlert/dialog-warning.png"] size:CGSizeMake(32,32)];
                                           break;
	    case CPInformationalAlertStyle:    alertImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPAlert/dialog-information.png"] size:CGSizeMake(32,32)];
                                           break;
	    case CPCriticalAlertStyle:         alertImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPAlert/dialog-error.png"] size:CGSizeMake(32,32)];	
                                           break;
	}
    var alertImageView = [[CPImageView alloc] initWithFrame:CGRectMake(25,12,32,32)];
	[alertImageView setImage:alertImage];
	[[_alertPanel contentView] addSubview: alertImageView];
	[CPApp runModalForWindow:_alertPanel];
}

/* @ignore */
- (void)notifyDelegate:(id)button
{
	if (_delegate && [_delegate respondsToSelector:@selector(alertDidEnd:returnCode:)])
	{
		[_delegate alertDidEnd:self returnCode:[button tag]];
	}
	[CPApp abortModal];
	[_alertPanel close];
}