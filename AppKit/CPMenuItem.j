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

@import <Foundation/CPCoder.j>
@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>

@import <AppKit/CPImage.j>
@import <AppKit/CPMenu.j>
@import <AppKit/CPView.j>

/*! @class CPMenuItem

    A CPMenuItem is added to a CPMenu.
    It has an action and a target for that action to be sent to
    whenever the item is 'activated'.
*/
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

/*!
    Initializes the menu item with a title, action, and keyboard equivalent.
    @param aTitle the menu item's title
    @param anAction the action that gets triggered when the item is selected
    @param aKeyEquivalent the keyboard shortcut for the item
    @return the initialized menu item
*/
- (id)initWithTitle:(CPString)aTitle action:(SEL)anAction keyEquivalent:(CPString)aKeyEquivalent
{
    self = [super init];
    
    if (self)
    {
        _title = aTitle;
        _action = anAction;
        
        _isEnabled = YES;
        
        _tag = 0;
        _state = CPOffState;
        
        _keyEquivalent = aKeyEquivalent || @"";
        _keyEquivalentModifierMask = CPPlatformActionKeyMask;
        
        _mnemonicLocation = CPNotFound;
    }
    
    return self;
}

// Enabling a Menu Item
/*!
    Sets whether the menu item is enabled or not
    @param isEnabled <code>YES</code> enables the item. <code>NO</code> disables it.
*/
- (void)setEnabled:(BOOL)isEnabled
{
    if ([_menu autoenablesItems])
        return;
        
    _isEnabled = isEnabled;
    
    [_menuItemView setDirty];
    
    [_menu itemChanged:self];
}

/*!
    Returns <code>YES</code> if the item is enabled.
*/
- (BOOL)isEnabled
{
    return _isEnabled;
}

// Managing Hidden Status
/*!
    Sets whether the item should be hidden. A hidden item can not be triggered by keyboard shortcuts.
    @param isHidden <code>YES</code> hides the item. <code>NO</code> reveals it.
*/
- (void)setHidden:(BOOL)isHidden
{
    if (_isHidden == isHidden)
        return;
    
    _isHidden = isHidden;

    [_menu itemChanged:self];
}

/*!
    Returns <code>YES</code> if the item is hidden.
*/
- (BOOL)isHidden
{
    return _isHidden;
}

/*!
    Returns <code>YES</code> if the item is hidden or if one of it's supermenus is hidden.
*/
- (BOOL)isHiddenOrHasHiddenAncestor
{
    if (_isHidden)
        return YES;
    
    var supermenu = [_menu supermenu];
    
    if ([[supermenu itemAtIndex:[supermenu indexOfItemWithSubmenu:_menu]] isHiddenOrHasHiddenAncestor])
        return YES;

    return NO;
}

// Managing Target and Action
/*!
    Sets the menu item's action target.
    @param aTarget the target for the action
*/
- (void)setTarget:(id)aTarget
{
    _target = aTarget;
}

/*!
    Returns the item's action target
*/
- (id)target
{
    return _target;
}

/*!
    Sets the action that gets sent to the item's target when triggered.
    @param anAction the action to send
*/
- (void)setAction:(SEL)anAction
{
    _action = anAction;
}

/*!
    Returns the item's action.
*/
- (SEL)action
{
    return _action;
}

// Managing the Title
/*!
    Sets the item's title.
    @param aTitle the item's new title
*/
- (void)setTitle:(CPString)aTitle
{
    _mnemonicLocation = CPNotFound;

    if (_title == aTitle)
        return;
    
    _title = aTitle;
    
    [_menuItemView setDirty];
    
    [_menu itemChanged:self];
}

/*!
    Returns the menu item's title.
*/
- (CPString)title
{
    return _title;
}

/*!
    Set's the item's text color
*/
- (void)setTextColor:(CPString)aColor
{
    //FIXME IMPLEMENT
}

/*!
    Sets the font for the text of this menu item
    @param aFont the font for the menu item
*/
- (void)setFont:(CPFont)aFont
{
    if (_font == aFont)
        return;
        
    _font = aFont;

    [_menu itemChanged:self];
    
    [_menuItemView setDirty];
}

/*!
    Returns the menu item's font
*/
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
/*!
    Sets the menu item's tag
    @param aTag the tag for the item
*/
- (void)setTag:(int)aTag
{
    _tag = aTag;
}

/*!
    Returns the item's tag
*/
- (int)tag
{
    return _tag;
}

/*!
    Sets the state of the menu item. Possible states are:
<pre>
CPMixedState
CPOnState
CPOffState
</pre>
*/
- (void)setState:(int)aState
{
    if (_state == aState)
        return;
    
    _state = aState;
    
    [_menu itemChanged:self];

    [_menuItemView setDirty];
}

/*!
    Returns the menu item's current state. Possible states are:
<pre>
CPMixedState
CPOnState
CPOffState
</pre>
*/
- (int)state
{
    return _state;
}

// Managing the Image
/*!
    Sets the menu item's image
    @param anImage the menu item's image
*/
- (void)setImage:(CPImage)anImage
{
    if (_image == anImage)
        return;
    
    _image = anImage;

    [_menuItemView setDirty];
    
    [_menu itemChanged:self];
}

/*!
    Returns the menu item's image
*/
- (CPImage)image
{
    return _image;
}

/*!
    Sets the menu item's alternate image
    @param anImage the menu item's alternate image
*/
- (void)setAlternateImage:(CPImage)anImage
{
    _alternateImage = anImage;
}

/*!
    Returns the menu item's alternate image
*/
- (CPImage)alternateImage
{
    return _alternateImage;
}

/*!
    Sets the image that is shown when the
    menu item is in the 'on' state.
    @param anImage the image to show
*/
- (void)setOnStateImage:(CPImage)anImage
{
    if (_onStateImage == anImage)
        return;
    
    _onStateImage = anImage;
    [_menu itemChanged:self];
}

/*!
    Returns the image shown when the menu item is in the 'on' state.
*/
- (CPImage)onStateImage
{
    return _onStateImage;
}

/*!
    Sets the image that is shown when the menu item is in the 'off' state.
    @param anImage the image to show
*/
- (void)setOffStateImage:(CPImage)anImage
{
    if (_offStateImage == anImage)
        return;
    
    _offStateImage = anImage;
    [_menu itemChanged:self];
}

/*!
    Returns the image shown when the menu item is in the 'off' state.
*/
- (CPImage)offStateImage
{
    return _offStateImage;
}

/*!
    Sets the image that is shown when the menu item is in the 'mixed' state.
    @param anImage the image to show
*/
- (void)setMixedStateImage:(CPImage)anImage
{
    if (_mixedStateImage == anImage)
        return;
    
    _mixedStateImage = anImage;
    [_menu itemChanged:self];
}

/*!
    Returns the image shown when the menu item is
    in the 'mixed' state.
*/
- (CPImage)mixedStateImage
{
    return _mixedStateImage;
}

// Managing Subemenus
/*!
    Sets the submenu for this item
    @param aMenu the submenu
*/
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

/*!
    Returns the submenu of the item. <code>nil</code> if there is no submenu.
*/
- (CPMenu)submenu
{
    return _submenu;
}

/*!
    Returns <code>YES</code> if the menu item has a submenu.
*/
- (BOOL)hasSubmenu
{
    return _submenu ? YES : NO;
}

// Getting a Separator Item

/*!
    Returns a new menu item separator.
*/
+ (CPMenuItem)separatorItem
{
    return [[_CPMenuItemSeparator alloc] init];
}

/*!
    Returns <code>YES</code> if the menu item is a separator.
*/
- (BOOL)isSeparatorItem
{
    return NO;
}

// Managing the Owning Menu
/*!
    Set the container menu of this item.
    @param aMenu the item's container menu
*/
- (void)setMenu:(CPMenu)aMenu
{
    _menu = aMenu;
}

/*!
    Returns the container menu of this item
*/
- (CPMenu)menu
{
    return _menu;
}

//

/*!
    Sets the keyboard shortcut for this menu item
    @param aString the keyboard shortcut
*/
- (void)setKeyEquivalent:(CPString)aString
{
    _keyEquivalent = aString || @"";
}

/*!
    Returns the keyboard shortcut for this menu item
*/
- (CPString)keyEquivalent
{
    return _keyEquivalent;
}

/*!
    Sets the modifier mask used for the item's keyboard shortcut.
    Can be a combination of:
<pre>
CPShiftKeyMask
CPAlternateKeyMask
CPCommandKeyMask
CPControlKeyMask
</pre>
*/
- (void)setKeyEquivalentModifierMask:(unsigned)aMask
{
    _keyEquivalentModifierMask = aMask;
}

/*!
    Returns the item's keyboard shortcut modifier mask.
    Can be a combination of:
<pre>
CPShiftKeyMask
CPAlternateKeyMask
CPCommandKeyMask
CPControlKeyMask
</pre>
*/
- (unsigned)keyEquivalentModifierMask
{
    return _keyEquivalentModifierMask;
}

// Managing Mnemonics
/*!
    Sets the index of the mnemonic character in the title. The character
    will be underlined and is used as a shortcut for navigation.
    @param aLocation the index of the character in the title
*/
- (void)setMnemonicLocation:(unsigned)aLocation
{
    _mnemonicLocation = aLocation;
}

/*!
    Returns the index of the mnemonic character in the title.
*/
- (unsigned)mnemonicLocation
{
    return _mnemonicLocation;
}

/*!
    Sets the title of the menu item and the mnemonic character. The mnemonic chracter should be preceded by an '&'.
    @param aTitle the title string with a denoted mnemonic
*/
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

/*!
    Returns the menu items mnemonic character
*/
- (CPString)mnemonic
{
    return _mnemonicLocation == CPNotFound ? @"" : [_title characterAtIndex:_mnemonicLocation];
}

// Managing Alternates

/*!
    Sets whether this item is an alternate for the previous menu item.
    @param isAlternate <code>YES</code> denotes that this menu item is an alternate
*/
- (void)setAlternate:(BOOL)isAlternate
{
    _isAlternate = isAlternate;
}

/*!
    Returns <code>YES</code> if the menu item is an alternate for the previous item.
*/
- (BOOL)isAlternate
{
    return _isAlternate;
}

// Managing Indentation Levels

/*!
    Sets the indentation level of the menu item. Must be a value between 0 and 15 (inclusive).
    @param aLevel the item's new indentation level
    @throws CPInvalidArgumentException if aLevel is less than 0
*/
- (void)setIndentationLevel:(unsigned)aLevel
{
    if (aLevel < 0)
        [CPException raise:CPInvalidArgumentException reason:"setIndentationLevel: argument must be greater than 0."];
        
    _indentationLevel = MIN(15, aLevel);
}

/*!
    Returns the menu item's indentation level. This is a value between 0 and 15 (inclusive).
*/
- (unsigned)indentationLevel
{
    return _indentationLevel;
}

// Managing Tool Tips
/*!
    Sets the tooltip for the menu item.
    @param aToolTip the tool tip for the item
*/
- (void)setToolTip:(CPString)aToolTip
{
    _toolTip = aToolTip;
}

/*!
    Returns the item's tooltip
*/
- (CPString)toolTip
{
    return _toolTip;
}

// Representing an Object

/*!
    Sets the menu item's represented object. This is a kind of tag for the developer. Not a UI feature.
    @param anObject the represented object
*/
- (void)setRepresentedObject:(id)anObject
{
    _representedObject = anObject;
}

/*!
    Returns the item's represented object.
*/
- (id)representedObject
{
    return _representedObject;
}

// Managing the View

/*!
    Sets the view for the menu item
    @param aView the menu's item's view
*/
- (void)setView:(CPView)aView
{
    if (_view == aView)
        return;
    
    _view = aView;
    
    [_menuItemView setDirty];
    
    [_menu itemChanged:self];
}

/*!
    Returns the menu item's view
*/
- (CPView)view
{
    return _view;
}

// Getting Highlighted Status

/*!
    Returns <code>YES</code> if the menu item is highlighted.
*/
- (BOOL)isHighlighted
{
    return [[self menu] highlightedItem] == self;
}

//

/*
    @ignore
*/
- (id)_menuItemView
{
    if (!_menuItemView)
        _menuItemView = [[_CPMenuItemView alloc] initWithFrame:CGRectMakeZero() forMenuItem:self];
    
    return _menuItemView;
}

@end

/* @ignore */
@implementation _CPMenuItemSeparator : CPMenuItem
{
}

- (id)init
{
    self = [super initWithTitle:@"" action:nil keyEquivalent:nil];
    
    if (self)
        [self setEnabled:NO];
    
    return self;
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
    
    CPMenuItemTagKey                = @"CPMenuItemTagKey",
    
    CPMenuItemImageKey              = @"CPMenuItemImageKey",
    CPMenuItemAlternateImageKey     = @"CPMenuItemAlternateImageKey",
    
    CPMenuItemSubmenuKey            = @"CPMenuItemSubmenuKey",
    CPMenuItemMenuKey               = @"CPMenuItemMenuKey",
    
    CPMenuItemRepresentedObjectKey  = @"CPMenuItemRepresentedObjectKey";

@implementation CPMenuItem (CPCoding)
/*!
    Initializes the menu item from a coder.
    @param aCoder the coder from which to initialize
    @return the initialized menu item
*/
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

        _tag = [aCoder containsValueForKey:CPMenuItemTagKey] ? [aCoder decodeObjectForKey:CPMenuItemTagKey] : 0;

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

/*!
    Writes the menu item out to a coder.
    @param aCoder the coder to write the menu item out to
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_title forKey:CPMenuItemTitleKey];
        
    [aCoder encodeObject:_target forKey:CPMenuItemTargetKey];
    [aCoder encodeObject:_action forKey:CPMenuItemActionKey];

    [aCoder encodeObject:_isEnabled forKey:CPMenuItemIsEnabledKey];
    [aCoder encodeObject:_isHidden forKey:CPMenuItemIsHiddenKey];

    if (_tag !== 0)
        [aCoder encodeObject:_tag forKey:CPMenuItemTagKey];

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
    INDENTATION_WIDTH           = 17.0,
    VERTICAL_MARGIN             = 4.0;
    
var _CPMenuItemSelectionColor                   = nil,
    _CPMenuItemTextShadowColor                  = nil,
    
    _CPMenuItemDefaultStateImages               = [],
    _CPMenuItemDefaultStateHighlightedImages    = [];

/*
    @ignore
*/
@implementation _CPMenuItemView : CPView
{
    CPMenuItem              _menuItem;

    CPFont                  _font;
    CPColor                 _textColor;

    CGSize                  _minSize;
    BOOL                    _isDirty;
    BOOL                    _showsStateColumn;
    BOOL                    _belongsToMenuBar;

    CPImageView             _stateView;
    _CPImageAndTextView     _imageAndTextView;
    CPView                  _submenuView;
}

+ (void)initialize
{
    if (self != [_CPMenuItemView class])
        return;
    
    _CPMenuItemSelectionColor =  [CPColor colorWithCalibratedRed:81.0 / 255.0 green:83.0 / 255.0 blue:109.0 / 255.0 alpha:1.0];
    
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
    
    if ([_menuItem isSeparatorItem])
    {
        var line = [[CPView alloc] initWithFrame:CGRectMake(0.0, 5.0, 10.0, 1.0)];
        
        view = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 10.0)];
        
        [view setAutoresizingMask:CPViewWidthSizable];
        [line setAutoresizingMask:CPViewWidthSizable];
        
        [line setBackgroundColor:[CPColor lightGrayColor]];
        
        [view addSubview:line];
    }
    
    if (view)
    {
        [_imageAndTextView removeFromSuperview];
        _imageAndTextView = nil;
        
        [_stateView removeFromSuperview];
        _stateView = nil;
        
        [_submenuView removeFromSuperview];
        _submenuView = nil;
        
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
    
    if (!_imageAndTextView)
    {
        _imageAndTextView = [[_CPImageAndTextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 0.0)];
        
        [_imageAndTextView setImagePosition:CPImageLeft];
        [_imageAndTextView setTextShadowOffset:CGSizeMake(0.0, 1.0)];
        
        [self addSubview:_imageAndTextView];
    }
    
    var font = [_menuItem font];
    
    if (!font)
        font = _font;

    [_imageAndTextView setFont:font];
    [_imageAndTextView setVerticalAlignment:CPCenterVerticalTextAlignment];
    [_imageAndTextView setImage:[_menuItem image]];
    [_imageAndTextView setText:[_menuItem title]];
    [_imageAndTextView setTextColor:[self textColor]];
    [_imageAndTextView setFrameOrigin:CGPointMake(x, VERTICAL_MARGIN)];
    [_imageAndTextView sizeToFit];
    
    var frame = [_imageAndTextView frame];
    
//    frame.size.height += 1.0;
//    [_imageAndTextView setFrame:frame];
    
    frame.size.height += 2 * VERTICAL_MARGIN;
    
    x += CGRectGetWidth(frame);
    
    // Submenu Arrow
    if ([_menuItem hasSubmenu])
    {
        x += 3.0;
        
        if (!_submenuView)
        {
            _submenuView = [[_CPMenuItemArrowView alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 10.0)];
            
            [self addSubview:_submenuView];
        }
        
        [_submenuView setHidden:NO];
        [_submenuView setColor:_belongsToMenuBar ? [self textColor] : nil];
        [_submenuView setFrameOrigin:CGPointMake(x, (CGRectGetHeight(frame) - 10.0) / 2.0)];
        
        x += 10.0;
    }
    else
        [_submenuView setHidden:YES];

    _minSize = CGSizeMake(x + (_belongsToMenuBar ? 0.0 : RIGHT_MARGIN) + 3.0, CGRectGetHeight(frame));
 
    [self setFrameSize:_minSize];
}

- (CGFloat)overlapOffsetWidth
{
    return LEFT_MARGIN + ([[_menuItem menu] showsStateColumn] ? STATE_COLUMN_WIDTH : 0.0);
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
        [_imageAndTextView setImage:shouldHighlight ? [_menuItem alternateImage] : [_menuItem image]];
    
    else if ([_menuItem isEnabled])
    {
        if (shouldHighlight)
        {
            [self setBackgroundColor:_CPMenuItemSelectionColor];
    
            [_imageAndTextView setTextColor:[CPColor whiteColor]];
            [_imageAndTextView setTextShadowColor:_CPMenuItemTextShadowColor];
        }
        else
        {
            [self setBackgroundColor:nil];
            
            [_imageAndTextView setTextColor:[self textColor]];
            [_imageAndTextView setTextShadowColor:nil];
        }
        
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
    [_imageAndTextView setImage:[_menuItem image]];
    
    if (shouldActivate)
    {
        [_imageAndTextView setTextColor:[CPColor whiteColor]];
        [_submenuView setColor:[CPColor whiteColor]];
    }
    else
    {
        [_imageAndTextView setTextColor:[self textColor]];
        [_submenuView setColor:[self textColor]];
    }
}

- (BOOL)eventOnSubmenu:(CPEvent)anEvent
{
    if (![_menuItem hasSubmenu])
        return NO;
        
    return CGRectContainsPoint([_submenuView frame], [self convertPoint:[anEvent locationInWindow] fromView:nil]);
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

- (void)setTextColor:(CPColor)aColor
{
    if (_textColor == aColor)
        return;
    
    _textColor = aColor;

    [_imageAndTextView setTextColor:[self textColor]];
    [_submenuView setColor:[self textColor]];
}

- (CPColor)textColor
{
    return [_menuItem isEnabled] ? (_textColor ? _textColor : [CPColor blackColor]) : [CPColor darkGrayColor];
}

@end

@implementation _CPMenuItemArrowView : CPView
{
    CPColor _color;
}

- (void)setColor:(CPColor)aColor
{
    if (_color == aColor)
        return;

    _color = aColor;
    
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];
    
    CGContextBeginPath(context);
    
    CGContextMoveToPoint(context, 1.0, 4.0);
    CGContextAddLineToPoint(context, 9.0, 4.0);
    CGContextAddLineToPoint(context, 5.0, 8.0);
    CGContextAddLineToPoint(context, 1.0, 4.0);
    
    CGContextClosePath(context);
    
    CGContextSetFillColor(context, _color);
    CGContextFillPath(context);
}

@end
