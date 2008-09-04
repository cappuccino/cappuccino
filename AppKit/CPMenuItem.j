/*
 * CPMenuItem.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

import <Foundation/CPCoder.j>
import <Foundation/CPObject.j>
import <Foundation/CPString.j>

import <AppKit/CPImage.j>
import <AppKit/CPMenu.j>
import <AppKit/CPView.j>


@implementation CPMenuItem : CPObject
{
    CPString        _title;
    //CPAttributedString  _attributedTitle;
    
    CPFont          _font;
                  
    id              _target;
    SEL             _action;
                    
    BOOL            _isEnabled;
    BOOL            _isHidden;
                    
    int             _tag;
    int             _state;
                    
    CPImage         _image;
    CPImage         _alternateImage;
    CPImage         _onStateImage;
    CPImage         _offStateImage;
    CPImage         _mixedStateImage;
                    
    CPMenu          _submenu;
    CPMenu          _menu;
                    
    CPString        _keyEquivalent;
    unsigned        _keyEquivalentModifierMask;
                    
    int             _mnemonicLocation;
                    
    BOOL            _isAlternate;
    int             _indentationLevel;
                    
    CPString        _toolTip;
    id              _representedObject;
    CPView          _view;
    
    _CPMenuItemView _menuItemView;
}

- (id)initWithTitle:(CPString)aTitle action:(SEL)anAction keyEquivalent:(CPString)aKeyEquivalent
{
    self = [super init];
    
    if (self)
    {
        _title = aTitle;
        _action = anAction;
        
        _isEnabled = YES;
        
        _state = CPOffState;
        
        _keyEquivalent = aKeyEquivalent;
        _keyEquivalentModifierMask = CPPlatformActionKeyMask;
        
        _mnemonicLocation = CPNotFound;
    }
    
    return self;
}

// Enabling a Menu Item

- (void)setEnabled:(BOOL)isEnabled
{
    if ([_menu autoenablesItems])
        return;
        
    _isEnabled = isEnabled;
    
    [_menuItemView setDirty];
    
    [_menu itemChanged:self];
}

- (BOOL)isEnabled
{
    return _isEnabled;
}

// Managing Hidden Status

- (void)setHidden:(BOOL)isHidden
{
    _isHidden = isHidden;
}

- (BOOL)isHidden
{
    return _isHidden;
}

- (BOOL)isHiddenOrHasHiddenAncestor
{
    if (_isHidden)
        return YES;
    
    if ([[[_menu supermenu] indexOfItemWithSubmenu:_menu] isHiddenOrHasHiddenAncestor])
        return YES;

    return NO;
}

// Managing Target and Action

- (void)setTarget:(id)aTarget
{
    _target = aTarget;
}

- (id)target
{
    return _target;
}

- (void)setAction:(SEL)anAction
{
    _action = anAction;
}

- (SEL)action
{
    return _action;
}

// Managing the Title

- (void)setTitle:(CPString)aTitle
{
    _mnemonicLocation = CPNotFound;

    if (_title == aTitle)
        return;
    
    _title = aTitle;
    
    [_menuItemView setDirty];
    
    [_menu itemChanged:self];
}

- (CPString)title
{
    return _title;
}

- (void)setFont:(CPFont)aFont
{
    if (_font == aFont)
        return;
        
    _font = aFont;

    [_menu itemChanged:self];
    
    [_menuItemView setDirty];
}

- (CPFont)font
{
    return _font;
}

/*
- (void)setAttributedTitle:(CPAttributedString)aTitle
{
}

- (CPAttributedString)attributedTitle
{
}
*/

// Managing the Tag

- (void)setTag:(int)aTag
{
    _tag = aTag;
}

- (int)tag
{
    return _tag;
}

- (void)setState:(int)aState
{
    if (_state == aState)
        return;
    
    _state = aState;
    
    [_menu itemChanged:self];

    [_menuItemView setDirty];
}

- (int)state
{
    return _state;
}

// Managing the Image

- (void)setImage:(CPImage)anImage
{
    if (_image == anImage)
        return;
    
    _image = anImage;

    [_menuItemView setDirty];
    
    [_menu itemChanged:self];
}

- (CPImage)image
{
    return _image;
}

- (void)setAlternateImage:(CPImage)anImage
{
    _alternateImage = anImage;
}

- (CPImage)alternateImage
{
    return _alternateImage;
}

- (void)setOnStateImage:(CPImage)anImage
{
    if (_onStateImage == anImage)
        return;
    
    _onStateImage = anImage;
    [_menu itemChanged:self];
}

- (CPImage)onStateImage
{
    return _onStateImage;
}

- (void)setOffStateImage:(CPImage)anImage
{
    if (_offStateImage == anImage)
        return;
    
    _offStateImage = anImage;
    [_menu itemChanged:self];
}

- (CPImage)offStateImage
{
    return _offStateImage;
}

- (void)setMixedStateImage:(CPImage)anImage
{
    if (_mixedStateImage == anImage)
        return;
    
    _mixedStateImage = anImage;
    [_menu itemChanged:self];
}

- (CPImage)mixedStateImage
{
    return _mixedStateImage;
}

// Managing Subemenus

- (void)setSubmenu:(CPMenu)aMenu
{
    var supermenu = [_submenu supermenu];
    
    if (supermenu == self)
        return;
    
    if (supermenu)
        return alert("bad");
    
    [_submenu setSupermenu:_menu];
    
    _submenu = aMenu;
    
    [_menuItemView setDirty];
    
    [_menu itemChanged:self];
}

- (CPMenu)submenu
{
    return _submenu;
}

- (BOOL)hasSubmenu
{
    return _submenu ? YES : NO;
}

// Getting a Separator Item

+ (CPMenuItem)separatorItem
{
    return [[_CPMenuItemSeparator alloc] init];
}

- (BOOL)isSeparatorItem
{
    return NO;
}

// Managing the Owning Menu

- (void)setMenu:(CPMenu)aMenu
{
    _menu = aMenu;
}

- (CPMenu)menu
{
    return _menu;
}

//

- (void)setKeyEquivalent:(CPString)aString
{
    _keyEquivalent = aString;
}

- (CPString)keyEquivalent
{
    return _keyEquivalent;
}

- (void)setKeyEquivalentModifierMask:(unsigned)aMask
{
    _keyEquivalentModifierMask = aMask;
}

- (unsigned)keyEquivalentModifierMask
{
    return _keyEquivalentModifierMask;
}

// Managing Mnemonics

- (void)setMnemonicLocation:(unsigned)aLocation
{
    _mnemonicLocation = aLocation;
}

- (unsigned)mnemonicLocation
{
    return _mnemonicLocation;
}

- (void)setTitleWithMnemonicLocation:(CPString)aTitle
{
    var location = [aTitle rangeOfString:@"&"].location;
    
    if (location == CPNotFound)
        [self setTitle:aTitle];
    else
    {
        [self setTitle:[aTitle substringToIndex:location] + [aTitle substringFromIndex:location + 1]];
        [self setMnemonicLocation:location];
    }    
}

- (CPString)mnemonic
{
    return _mnemonicLocation == CPNotFound ? @"" : [_title characterAtIndex:_mnemonicLocation];
}

// Managing Alternates

- (void)setAlternate:(BOOL)isAlternate
{
    _isAlternate = isAlternate;
}

- (BOOL)isAlternate
{
    return _isAlternate;
}

// Managing Indentation Levels

- (void)setIndentationLevel:(unsigned)aLevel
{
    if (aLevel < 0)
        alert("bad");
        
    _indentationLevel = MIN(15, aLevel);
}

- (unsigned)indentationLevel
{
    return _indentationLevel;
}

// Managing Tool Tips
- (void)setToolTip:(CPString)aToolTip
{
    _toolTip = aToolTip;
}

- (CPString)toolTip
{
    return _toolTip;
}

// Representing an Object

- (void)setRepresentedObject:(id)anObject
{
    _representedObject = anObject;
}

- (id)representedObject
{
    return _representedObject;
}

// Managing the View

- (void)setView:(CPView)aView
{
    if (_view == aView)
        return;
    
    _view = aView;
    
    [_menuItemView setDirty];
    
    [_menu itemChanged:self];
}

- (CPView)view
{
    return _view;
}

// Getting Highlighted Status

- (BOOL)isHighlighted
{
    return [[self menu] highlightedItem] == self;
}

//

- (id)_menuItemView
{
    if (!_menuItemView)
        _menuItemView = [[_CPMenuItemView alloc] initWithFrame:CGRectMakeZero() forMenuItem:self];
    
    return _menuItemView;
}

@end

@implementation _CPMenuItemSeparator : CPMenuItem
{
}

- (id)init
{
    return [super initWithTitle:@"" action:nil keyEquivalent:@""];
}

- (BOOL)isSeparatorItem
{
    return YES;
}

@end

var CPMenuItemTitleKey              = @"CPMenuItemTitleKey",
    CPMenuItemTargetKey             = @"CPMenuItemTargetKey",
    CPMenuItemActionKey             = @"CPMenuItemActionKey",
    
    CPMenuItemIsEnabledKey          = @"CPMenuItemIsEnabledKey",
    CPMenuItemIsHiddenKey           = @"CPMenuItemIsHiddenKey",
    
    CPMenuItemImageKey              = @"CPMenuItemImageKey",
    CPMenuItemAlternateImageKey     = @"CPMenuItemAlternateImageKey",
    
    CPMenuItemSubmenuKey            = @"CPMenuItemSubmenuKey",
    CPMenuItemMenuKey               = @"CPMenuItemMenuKey",
    
    CPMenuItemRepresentedObjectKey  = @"CPMenuItemRepresentedObjectKey";

@implementation CPMenuItem (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _title = [aCoder decodeObjectForKey:CPMenuItemTitleKey];
        
//        _font;
                  
        _target = [aCoder decodeObjectForKey:CPMenuItemTargetKey];
        _action = [aCoder decodeObjectForKey:CPMenuItemActionKey];

        _isEnabled = [aCoder decodeObjectForKey:CPMenuItemIsEnabledKey];
        _isHidden = [aCoder decodeObjectForKey:CPMenuItemIsHiddenKey];

//    int             _tag;
//    int             _state;
                    
        _image = [aCoder decodeObjectForKey:CPMenuItemImageKey];
        _alternateImage = [aCoder decodeObjectForKey:CPMenuItemAlternateImageKey];
//    CPImage         _onStateImage;
//    CPImage         _offStateImage;
//    CPImage         _mixedStateImage;

        _submenu = [aCoder decodeObjectForKey:CPMenuItemSubmenuKey];
        _menu = [aCoder decodeObjectForKey:CPMenuItemMenuKey];
                    
//    CPString        _keyEquivalent;
//    unsigned        _keyEquivalentModifierMask;

//    int             _mnemonicLocation;

//    BOOL            _isAlternate;
//    int             _indentationLevel;
                    
//    CPString        _toolTip;

    _representedObject = [aCoder decodeObjectForKey:CPMenuItemRepresentedObjectKey];
//    id              _representedObject;
//    CPView          _view;
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_title forKey:CPMenuItemTitleKey];
        
    [aCoder encodeObject:_target forKey:CPMenuItemTargetKey];
    [aCoder encodeObject:_action forKey:CPMenuItemActionKey];

    [aCoder encodeObject:_isEnabled forKey:CPMenuItemIsEnabledKey];
    [aCoder encodeObject:_isHidden forKey:CPMenuItemIsHiddenKey];

    [aCoder encodeObject:_image forKey:CPMenuItemImageKey];
    [aCoder encodeObject:_alternateImage forKey:CPMenuItemAlternateImageKey];
    
    [aCoder encodeObject:_submenu forKey:CPMenuItemSubmenuKey];
    [aCoder encodeObject:_menu forKey:CPMenuItemMenuKey];
    
    [aCoder encodeObject:_representedObject forKey:CPMenuItemRepresentedObjectKey];
}

@end

var LEFT_MARGIN                 = 3.0,
    RIGHT_MARGIN                = 16.0,
    STATE_COLUMN_WIDTH          = 14.0,
    INDENTATION_WIDTH           = 17.0;
    
var _CPMenuItemSelectionColor                   = nil,
    
    _CPMenuItemDefaultStateImages               = [],
    _CPMenuItemDefaultStateHighlightedImages    = [],
    
    _CPMenuItemViewMenuBarArrowImage            = nil,
    _CPMenuItemViewMenuBarArrowActivatedImage   = nil;

@implementation _CPMenuItemView : CPView
{
    CPMenuItem              _menuItem;

    CPFont                  _font;

    CGSize                  _minSize;
    BOOL                    _isDirty;
    BOOL                    _showsStateColumn;
    BOOL                    _belongsToMenuBar;

    CPImageView             _stateView;
    _CPImageAndTitleView    _imageAndTitleView;
    CPImageView             _submenuImageView;
}

+ (void)initialize
{
    if (self != [_CPMenuItemView class])
        return;
    
    _CPMenuItemSelectionColor = [CPColor colorWithCalibratedRed:81.0 / 255.0 green:83.0 / 255.0 blue:109.0 / 255.0 alpha:1.0];
    
    var bundle = [CPBundle bundleForClass:self];
    
    _CPMenuItemDefaultStateImages[CPOffState]               = nil;
    _CPMenuItemDefaultStateHighlightedImages[CPOffState]    = nil;

    _CPMenuItemDefaultStateImages[CPOnState]               = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPMenuItem/CPMenuItemOnState.png"] size:CGSizeMake(14.0, 14.0)];
    _CPMenuItemDefaultStateHighlightedImages[CPOnState]    = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPMenuItem/CPMenuItemOnStateHighlighted.png"] size:CGSizeMake(14.0, 14.0)];

    _CPMenuItemDefaultStateImages[CPMixedState]             = nil;
    _CPMenuItemDefaultStateHighlightedImages[CPMixedState]  = nil;
}

+ (float)leftMargin
{
    return LEFT_MARGIN + STATE_COLUMN_WIDTH;
}

- (id)initWithFrame:(CGRect)aFrame forMenuItem:(CPMenuItem)aMenuItem
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _menuItem = aMenuItem;
        _showsStateColumn = YES;
        _isDirty = YES;
        
        [self setAutoresizingMask:CPViewWidthSizable];
        
        [self synchronizeWithMenuItem];
    }
    
    return self;
}

- (CGSize)minSize
{
    return _minSize;
}

- (void)setDirty
{
    _isDirty = YES;
}

- (void)synchronizeWithMenuItem
{
    if (!_isDirty)
        return;
        
    _isDirty = NO;
        
    var view = [_menuItem view];
    
    if (view)
    {
        [_imageAndTitleView removeFromSuperview];
        _imageAndTitleView = nil;
        
        [_stateView removeFromSuperview];
        _stateView = nil;
        
        [_submenuImageView removeFromSuperview];
        _submenuImageView = nil;
        
        _minSize = [view frame].size;
        
        [self setFrameSize:_minSize];
        
        [self addSubview:view];
        
        return;
    }
    
    // State Column
    var x = _belongsToMenuBar ? 0.0 : (LEFT_MARGIN + [_menuItem indentationLevel] * INDENTATION_WIDTH);
    
    if (_showsStateColumn)
    {
        if (!_stateView)
        {
            _stateView = [[CPImageView alloc] initWithFrame:CGRectMake(x, (CGRectGetHeight([self frame]) - STATE_COLUMN_WIDTH) / 2.0, STATE_COLUMN_WIDTH, STATE_COLUMN_WIDTH)];
            
            [_stateView setAutoresizingMask:CPViewMinYMargin | CPViewMaxYMargin];
            
            [self addSubview:_stateView];
        }
        
        var state = [_menuItem state];
            
        switch (state)
        {
            case CPOffState:
            case CPOnState:
            case CPMixedState:  [_stateView setImage:_CPMenuItemDefaultStateImages[state]];
                                break;
                                
            default:            [_stateView setImage:nil];
        }
        
        x += STATE_COLUMN_WIDTH;
    }
    else
    {
        [_stateView removeFromSuperview];
        
        _stateView = nil;
    }
    
    // Image and Title
    
    if (!_imageAndTitleView)
    {
        _imageAndTitleView = [[_CPImageAndTitleView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
        
        [_imageAndTitleView setImagePosition:CPImageLeft];
        
        [self addSubview:_imageAndTitleView];
    }
    
    var font = [_menuItem font];
    
    if (!font)
        font = _font;
    
    [_imageAndTitleView setFont:font];
    [_imageAndTitleView setImage:[_menuItem image]];
    [_imageAndTitleView setTitle:[_menuItem title]];
    [_imageAndTitleView setTextColor:[_menuItem isEnabled] ? [CPColor blackColor] : [CPColor darkGrayColor]];
    [_imageAndTitleView setFrameOrigin:CGPointMake(x, 0.0)];
    
    [_imageAndTitleView sizeToFit];
    
    var frame = [_imageAndTitleView frame];
    
    x += CGRectGetWidth(frame);
    
    // Submenu Arrow
    if ([_menuItem hasSubmenu])
    {
        if (!_submenuImageView)
        {
            _submenuImageView = [[CPImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 10.0)];
            
            [self addSubview:_submenuImageView];
        }
                    
        if (_belongsToMenuBar && !_CPMenuItemViewMenuBarArrowImage)
            _CPMenuItemViewMenuBarArrowImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[_CPMenuItemView class]] pathForResource:@"_CPMenuItemView/_CPMenuItemViewMenuBarArrow.png"] size:CGSizeMake(10.0, 10.0)];
        
        [_submenuImageView setHidden:NO];
        [_submenuImageView setImage:_belongsToMenuBar ? _CPMenuItemViewMenuBarArrowImage : nil];
        [_submenuImageView setFrameOrigin:CGPointMake(x, (CGRectGetHeight(frame) - 10.0) / 2.0)];
        
        x += 10.0;
    }
    else
        [_submenuImageView setHidden:YES];

    _minSize = CGSizeMake(x + (_belongsToMenuBar ? 0.0 : RIGHT_MARGIN), CGRectGetHeight(frame));
 
    [self setFrameSize:_minSize];
}

- (float)calculatedLeftMargin
{
    if (_belongsToMenuBar)
        return 0.0;
    
    return LEFT_MARGIN + ([[_menuItem menu] showsStateColumn] ? STATE_COLUMN_WIDTH : 0.0) + [_menuItem indentationLevel] * INDENTATION_WIDTH;
}

- (void)setShowsStateColumn:(BOOL)shouldShowStateColumn
{
    _showsStateColumn = shouldShowStateColumn;
}

- (void)setBelongsToMenuBar:(BOOL)shouldBelongToMenuBar
{
    _belongsToMenuBar = shouldBelongToMenuBar;
}

- (void)highlight:(BOOL)shouldHighlight
{
    // ASSERT(![_menuItem view]);
    
    if (_belongsToMenuBar)
        [_imageAndTitleView setImage:shouldHighlight ? [_menuItem alternateImage] : [_menuItem image]];
    
    else
    {
        [_imageAndTitleView setTextColor:shouldHighlight ? [CPColor whiteColor] : [CPColor blackColor]];
        
        if (shouldHighlight)
            [self setBackgroundColor:_CPMenuItemSelectionColor];
        else
            [self setBackgroundColor:nil];
            
        var state = [_menuItem state];
            
        switch (state)
        {
            case CPOffState:
            case CPOnState:
            case CPMixedState:  [_stateView setImage:shouldHighlight ? _CPMenuItemDefaultStateHighlightedImages[state] : _CPMenuItemDefaultStateImages[state]];
                                break;
                                
            default:            [_stateView setImage:nil];
        }
    }
}

- (void)activate:(BOOL)shouldActivate
{
    [_imageAndTitleView setImage:[_menuItem image]];
    
    if (shouldActivate)
    {
        if (!_CPMenuItemViewMenuBarArrowActivatedImage)
            _CPMenuItemViewMenuBarArrowActivatedImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[_CPMenuItemView class]] pathForResource:@"_CPMenuItemView/_CPMenuItemViewMenuBarArrowActivated.png"] size:CGSizeMake(10.0, 10.0)];
                    
        [_imageAndTitleView setTextColor:[CPColor whiteColor]];
        [_submenuImageView setImage:_CPMenuItemViewMenuBarArrowActivatedImage];
    }
    else
    {
        [_imageAndTitleView setTextColor:[CPColor blackColor]];
        [_submenuImageView setImage:_CPMenuItemViewMenuBarArrowImage];
    }
}

- (BOOL)eventOnSubmenu:(CPEvent)anEvent
{
    if (![_menuItem hasSubmenu])
        return NO;
        
    return CGRectContainsPoint([_submenuImageView frame], [self convertPoint:[anEvent locationInWindow] fromView:nil]);
}

- (BOOL)isHidden
{
    return [_menuItem isHidden];
}

- (CPMenuItem)menuItem
{
    return _menuItem;
}

- (void)setFont:(CPFont)aFont
{
    if (_font == aFont)
        return;
    
    _font = aFont;
    
    [self setDirty];
}

@end

