/*
 * CPSearchField.j
 * AppKit
 *
 * Created by cacaodev.
 * Copyright 2009.
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

@import "CPTextField.j"

#include "Platform/Platform.h"

CPSearchFieldRecentsTitleMenuItemTag    = 1000;
CPSearchFieldRecentsMenuItemTag         = 1001;
CPSearchFieldClearRecentsMenuItemTag    = 1002;
CPSearchFieldNoRecentsMenuItemTag       = 1003;

var CPSearchFieldSearchImage = nil,
    CPSearchFieldFindImage = nil,
    CPSearchFieldCancelImage = nil,
    CPSearchFieldCancelPressedImage = nil;

/*! 
    @ingroup appkit
    @class CPSearchField
    The CPSearchField class defines the programmatic interface for text fields that are optimized for text-based searches. A CPSearchField object directly inherits from the CPTextField class. The search field implemented by these classes presents a standard user interface for searches, including a search button, a cancel button, and a pop-up icon menu for listing recent search strings and custom search categories.

    When the user types and then pauses, the text field's action message is sent to its target. You can query the text field's string value for the current text to search for. Do not rely on the sender of the action to be an CPMenu object because the menu may change. If you need to change the menu, modify the search menu template and call the setSearchMenuTemplate: method to update.    
*/
@implementation CPSearchField : CPTextField
{
    CPButton    _searchButton;
    CPButton    _cancelButton;
    CPMenu      _searchMenuTemplate;
    CPMenu      _searchMenu;

    CPString    _recentsAutosaveName;
    CPArray     _recentSearches;
    
    int         _maximumRecents;
    BOOL        _sendsWholeSearchString;
    BOOL        _sendsSearchStringImmediately;
    CPTimer     _partialStringTimer;
}

+ (void)initialize
{
    if (self != [CPSearchField class])
        return;

    var bundle = [CPBundle bundleForClass:self];
    CPSearchFieldSearchImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPSearchField/CPSearchFieldSearch.png"] size:CGSizeMake(25, 22)];
    CPSearchFieldFindImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPSearchField/CPSearchFieldFind.png"] size:CGSizeMake(25, 22)];
    CPSearchFieldCancelImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPSearchField/CPSearchFieldCancel.png"] size:CGSizeMake(22, 22)];
    CPSearchFieldCancelPressedImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPSearchField/CPSearchFieldCancelPressed.png"] size:CGSizeMake(22, 22)];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _recentSearches = [CPArray array];
        _maximumRecents = 10;
        _sendsWholeSearchString = NO;
        _sendsSearchStringImmediately = NO;
        _recentsAutosaveName = nil;

        [self _initWithFrame:frame];
#if PLATFORM(DOM)
        _cancelButton._DOMElement.style.cursor = "default";
        _searchButton._DOMElement.style.cursor = "default";
#endif          
    }
    
    return self;
}

- (void)_initWithFrame:(CGRect)frame
{
    [self setBezeled:YES];
    [self setBezelStyle:CPTextFieldRoundedBezel];
    [self setBordered:YES];
    [self setEditable:YES];
    [self setDelegate:self];
    
    _cancelButton = [[CPButton alloc] initWithFrame:CGRectMake(frame.size.width - 27,(frame.size.height-22)/2,22,22)];
    [self resetCancelButton];
    [_cancelButton setHidden:YES];
    [_cancelButton setAutoresizingMask:CPViewMinXMargin];
    [self addSubview:_cancelButton];
    
    _searchButton = [[CPButton alloc] initWithFrame:CGRectMake(5,(frame.size.height-25)/2,25,25)];
    [self resetSearchButton];
    [self addSubview:_searchButton];
}

// Managing Buttons
/*!
    Sets the button used to display the search-button image
    @param button The search button.
*/
- (void)setSearchButton:(CPButton)button
{ 
    _searchButton = button;
}

/*!
    Returns the button used to display the search-button image.
    @return The search button.
*/
- (CPButton)searchButton
{
    return _searchButton;
}

/*!
    Resets the search button to its default attributes.
    This method resets the target, action, regular image, and pressed image. By default, when users click the search button or press the Return key, the action defined for the receiver is sent to its designated target. This method gives you a way to customize the search button for specific situations and then reset the button defaults without having to undo changes individually.
*/
- (void)resetSearchButton
{
    var searchButtonImage, 
        action, 
        target,
        button = [self searchButton];
        
    if (_searchMenuTemplate === nil)
    {
        searchButtonImage = CPSearchFieldSearchImage;
        action = @selector(_sendAction:);
        target = self;
    }
    else
    {
        searchButtonImage = CPSearchFieldFindImage;
        action = @selector(_showMenu:);
        target = self;
    }
    
    [button setBordered:NO];
    [button setImageScaling:CPScaleToFit];
    [button setImage:searchButtonImage];
    [button setAutoresizingMask:CPViewMaxXMargin];
    [button setTarget:target];
    [button setAction:action];
}

/*!
    Sets the button object used to display the cancel-button image.
    @param button The cancel button.
*/
- (void)setCancelButton:(CPButton)button
{
    _cancelButton = button;
}

/*!
    Returns the button object used to display the cancel-button image.
    @return The cancel button.
*/
- (CPButton)cancelButton
{
    return _cancelButton;
}

/*!
    Resets the cancel button to its default attributes.
    This method resets the target, action, regular image, and pressed image. By default, when users click the cancel button, the delete: action message is sent up the responder chain. This method gives you a way to customize the cancel button for specific situations and then reset the button defaults without having to undo changes individually.
*/
- (void)resetCancelButton
{
    var button = [self cancelButton];
    [button setBordered:NO];
    [button setImageScaling:CPScaleToFit];
    [button setImage:CPSearchFieldCancelImage];
    [button setAlternateImage:CPSearchFieldCancelPressedImage];
    [button setAutoresizingMask:CPViewMinXMargin];
    [button setTarget:self];
    [button setAction:@selector(_searchFieldCancel:)];
}

// Custom Layout
/*!
    Modifies the bounding rectangle for the search-text field.
    @param rect The current bounding rectangle for the search text field.
    @return The updated bounding rectangle to use for the search text field. The default value is the value passed into the rect parameter.
    Subclasses can override this method to return a new bounding rectangle for the text-field object. You might use this method to provide a custom layout for the search field control.
*/
- (CPRect)searchTextRectForBounds:(CPRect)rect
{
    var leftOffset = 0, width = rect.size.width;
    
    if (_searchButton)
    {
        var searchRect = [_searchButton frame];
        leftOffset = searchRect.origin.x + searchRect.size.width;
    }
    
    if (_cancelButton)
    {
        var cancelRect = [_cancelButton frame];
        width = cancelRect.origin.x - leftOffset;
    }
    
    return CPMakeRect(leftOffset,rect.origin.y,width,rect.size.height);
}

/*!
    Modifies the bounding rectangle for the search button.
    @param rect The current bounding rectangle for the search button.
    Subclasses can override this method to return a new bounding rectangle for the search button. You might use this method to provide a custom layout for the search field control.
*/
- (CPRect)searchButtonRectForBounds:(CPRect)rect
{
    return [_searchButton frame];
}

/*!
    Modifies the bounding rectangle for the cancel button.
    @param rect The updated bounding rectangle to use for the cancel button. The default value is the value passed into the rect parameter.
    Subclasses can override this method to return a new bounding rectangle for the cancel button. You might use this method to provide a custom layout for the search field control.
*/
- (CPRect)cancelButtonRectForBounds:(CPRect)rect
{
    return [_cancelButton frame];
}

// Managing Menu Templates
/*!
    Returns the menu template object used to dynamically construct the search pop-up icon menu.
    @return The current menu template.
*/
- (CPMenu)searchMenuTemplate
{
    return _searchMenuTemplate;
}

/*!
    Sets the menu template object used to dynamically construct the receiver's pop-up icon menu.
    @param menu The menu template to use.
    The receiver looks for the tag constants described in ŇMenu tagsÓ to determine how to populate the menu with items related to recent searches. See ŇConfiguring a Search MenuÓ for a sample of how you might set up the search menu template.
*/
- (void)setSearchMenuTemplate:(CPMenu)menu
{
    _searchMenuTemplate = menu;
    
    [self resetSearchButton];
    [self _loadRecentSearchList];
    [self _updateSearchMenu];
}

// Managing Search Modes
/*!
    Returns a Boolean value indicating whether the receiver sends the search action message when the user clicks the search button (or presses return) or after each keystroke.
    @return \c YES if the action message is sent all at once when the user clicks the search button or presses return; otherwise, NO if the search string is sent after each keystroke. The default value is NO.
*/
- (BOOL)sendsWholeSearchString
{ 
    return _sendsWholeSearchString; 
}

/*!
    Sets whether the receiver sends the search action message when the user clicks the search button (or presses return) or after each keystroke.
    @param flag \c YES to send the action message all at once when the user clicks the search button or presses return; otherwise, NO to send the search string after each keystroke.
*/
- (void)setSendsWholeSearchString:(BOOL)flag
{
    _sendsWholeSearchString = flag;
}

/*!
    Returns a Boolean value indicating whether the receiver sends its action immediately upon being notified of changes to the search field text or after a brief pause.
    @return \c YES if the text field sends its action immediately upon notification of any changes to the search field; otherwise, NO.
*/
- (BOOL)sendsSearchStringImmediately
{ 
    return _sendsSearchStringImmediately; 
}

/*!
    Sets whether the text field sends its action message to the target immediately upon notification of any changes to the search field text or after a brief pause.
    @param flag \c YES to send the text field's action immediately upon notification of any changes to the search field; otherwise, NO if you want the text field to pause briefly before sending its action message. Pausing gives the user the opportunity to type more text into the search field before initiating the search.
*/
- (void)setSendsSearchStringImmediately:(BOOL)flag
{
    _sendsSearchStringImmediately = flag;
}

// Managing Recent Search Strings
/*!
    Returns the maximum number of recent search strings to display in the custom search menu.
    @return The maximum number of search strings that can appear in the menu. This value is between 0 and 254.
*/
- (int)maximumRecents
{ 
    return _maximumRecents;
}

/*!
    Sets the maximum number of search strings that can appear in the search menu.
    @param maxRecents The maximum number of search strings that can appear in the menu. This value can be between 0 and 254. Specifying a value less than 0 sets the value to the default, which is 10. Specifying a value greater than 254 sets the maximum to 254.
*/
- (void)setMaximumRecents:(int)max
{
    if (max > 254)
        max = 254;
    else if (max < 0)
        max = 10;
    
    _maximumRecents = max;
}

/*!
    Returns the list of recent search strings for the control.
    @return An array of \c CPString objects, each of which contains a search string either displayed in the search menu or from a recent autosave archive. If there have been no recent searches and no prior searches saved under an autosave name, this array may be empty. 
 */
- (CPArray)recentSearches
{
    return _recentSearches;
}

/*!
    Sets the list of recent search strings to list in the pop-up icon menu of the receiver.
    @param searches An array of CPString objects containing the search strings.
    You might use this method to set the recent list of searches from an archived copy.
*/
- (void)setRecentSearches:(CPArray)searches
{
    var max = MIN([self maximumRecents], [searches count]),
        searches = [searches subarrayWithRange:CPMakeRange(0, max)];
    
    _recentSearches = searches;    
    [self _autosaveRecentSearchList];
}

/*!
    Returns the key under which the prior list of recent search strings has been archived.
    @return The autosave name, which is used as a key in the standard user defaults to save the recent searches. The default value is nil, which causes searches not to be autosaved.
*/
- (CPString)recentsAutosaveName
{
    return _recentsAutosaveName; 
}

/*!
    Sets the autosave name under which the receiver automatically archives the list of recent search strings.
    @param name The autosave name, which is used as a key in the standard user defaults to save the recent searches. If you specify nil or an empty string for this parameter, no autosave name is set and searches are not autosaved.
*/
- (void)setRecentsAutosaveName:(CPString)name
{
    if (_recentsAutosaveName != nil)
        [self _deregisterForAutosaveNotification];
        
    _recentsAutosaveName = name;
    
    if (_recentsAutosaveName != nil)
      [self _registerForAutosaveNotification];
}

// Private methods and subclassing

- (CPRect)contentRectForBounds:(CPRect)bounds
{
    var superbounds = [super contentRectForBounds:bounds];    
    return [self searchTextRectForBounds:superbounds];
}

+ (double)_keyboardDelayForPartialSearchString:(CPString)string
{
    return (6 - MIN([string length],4))/10;
}

- (CPMenu)menu
{
    return _searchMenu;
}

- (BOOL)isOpaque
{
  return [super isOpaque] && [_cancelButton isOpaque] && [_searchButton isOpaque];
}

- (void)_updateCancelButtonVisibility
{
    [_cancelButton setHidden:([[self stringValue] length] === 0)];
}

- (void)controlTextDidChange:(CPNotification)aNotification
{
    if (![self sendsWholeSearchString])
    {
        if ([self sendsSearchStringImmediately])
            [self _sendPartialString];
        else
        {
            [_partialStringTimer invalidate];
            var timeInterval = [CPSearchField _keyboardDelayForPartialSearchString:[self stringValue]];
    
            _partialStringTimer = [CPTimer scheduledTimerWithTimeInterval:timeInterval 
                                                                   target:self 
                                                                 selector:@selector(_sendPartialString) 
                                                                 userInfo:nil 
                                                                  repeats:NO];         
        }
    }
    
    [self _updateCancelButtonVisibility];
}

- (void)_sendAction:(id)sender
{
    [self sendAction:[self action] to:[self target]];
}

- (void)sendAction:(SEL)anAction to:(id)anObject
{
    [super sendAction:anAction to:anObject];

    [_partialStringTimer invalidate];

    [self _addStringToRecentSearches:[self stringValue]];
    [self _updateCancelButtonVisibility];
}

- (void)_addStringToRecentSearches:(CPString)string
{
    if (string === nil || string === @"" || [_recentSearches containsObject:string])
        return;
        
    var searches = [CPMutableArray arrayWithArray:_recentSearches];
    [searches addObject:string];
    [self setRecentSearches:searches];
    [self _updateSearchMenu];
}

- (BOOL)trackMouse:(CPEvent)event
{
    var rect,
        point,
        location = [event locationInWindow];
    
    point = [self convertPoint:location fromView:nil];
    
    rect = [self searchButtonRectForBounds:[self frame]];
    if (CPRectContainsPoint(rect,point))
    {
        return [[self searchButton] trackMouse:event];
    }
    
    rect = [self cancelButtonRectForBounds:[self frame]];
    if (CPRectContainsPoint(rect,point))
    {
        return [[self cancelButton] trackMouse:event];
    }
    
    return [super trackMouse:event];
}

- (CPMenu)_defaultSearchMenuTemplate
{
    var template, item;
    
    template = [[CPMenu alloc] init];
    
    item = [[CPMenuItem alloc] initWithTitle:@"Recent searches" 
                                      action:NULL 
                               keyEquivalent:@""];
    [item setTag:CPSearchFieldRecentsTitleMenuItemTag];
    [item setEnabled:NO];
    [template addItem:item];
    
    item = [[CPMenuItem alloc] initWithTitle:@"Recent search item" 
                                      action:@selector(_searchFieldSearch:) 
                               keyEquivalent:@""];
    [item setTag:CPSearchFieldRecentsMenuItemTag];
    [item setTarget:self];
    [template addItem:item];
    
    item = [[CPMenuItem alloc] initWithTitle:@"Clear recent searches" 
                                      action:@selector(_searchFieldClearRecents:) 
                               keyEquivalent:@""];
    [item setTag:CPSearchFieldClearRecentsMenuItemTag];
    [item setTarget:self];
    [template addItem:item];
    
    item = [[CPMenuItem alloc] initWithTitle:@"No recent searches" 
                                      action:NULL 
                               keyEquivalent:@""];
    [item setTag:CPSearchFieldNoRecentsMenuItemTag];
    [item setEnabled:NO];
    [template addItem:item];
    
    return template;
}

- (void)_updateSearchMenu
{
    if (_searchMenuTemplate === nil)
        return;
        
    var i, menu = [[CPMenu alloc] init],
        countOfRecents = [_recentSearches count],
        numberOfItems = [_searchMenuTemplate numberOfItems];
    
    for (i = 0; i < numberOfItems; i++)
    {
        var item = [_searchMenuTemplate itemAtIndex:i],
            tag = [item tag];
        
        if (!(tag === CPSearchFieldRecentsTitleMenuItemTag && countOfRecents === 0) &&
            !(tag === CPSearchFieldClearRecentsMenuItemTag && countOfRecents === 0) &&
            !(tag === CPSearchFieldNoRecentsMenuItemTag && countOfRecents != 0)    &&
            !(tag === CPSearchFieldRecentsMenuItemTag))
        {
            var itemAction, itemTarget;
            switch (tag)
            {
                case CPSearchFieldRecentsTitleMenuItemTag : itemAction = NULL; itemTarget = NULL; break;
                case CPSearchFieldClearRecentsMenuItemTag : itemAction = @selector(_searchFieldClearRecents:); itemTarget = self; break;
                case CPSearchFieldNoRecentsMenuItemTag : itemAction = NULL; itemTarget = NULL; break;
                default: itemAction = [item action]; itemTarget = [item target]; break;
            }
            
            if (tag === CPSearchFieldClearRecentsMenuItemTag || tag === CPSearchFieldRecentsTitleMenuItemTag)
            {
                var separator = [CPMenuItem separatorItem];
                [separator setEnabled:NO];
                [menu addItem:separator];
            }
        
            var templateItem = [[CPMenuItem alloc] initWithTitle:[item title] 
                                                          action:itemAction 
                                                   keyEquivalent:[item keyEquivalent]];
            [templateItem setTarget:itemTarget];
            [templateItem setEnabled:([item isEnabled] && itemAction != NULL)];
            [templateItem setTag:tag];
            [menu addItem:templateItem];
        }
        else if (tag === CPSearchFieldRecentsMenuItemTag)
        {
            var j;
            for (j = 0; j < countOfRecents; j++)
            {
                var rencentItem = [[CPMenuItem alloc] initWithTitle:[_recentSearches objectAtIndex:j] 
                                                             action:@selector(_searchFieldSearch:) 
                                                      keyEquivalent:[item keyEquivalent]];
                [rencentItem setTarget:self];
                [menu addItem:rencentItem];
            }
        }
    }    
    _searchMenu = menu;
}

- (void)_showMenu:(id)sender
{
    if (_searchMenu === nil || [_searchMenu numberOfItems] === 0 || ![self isEnabled])
        return;
        
    var aFrame = [[self superview] convertRect:[self frame] toView:nil],
        location = CPMakePoint(aFrame.origin.x + 10, aFrame.origin.y + aFrame.size.height - 4);
    
    var anEvent = [CPEvent mouseEventWithType:CPRightMouseDown location:location modifierFlags:0 timestamp:[[CPApp currentEvent] timestamp] windowNumber:[[self window] windowNumber] context:nil eventNumber:1 clickCount:1 pressure:0];
    
    [CPMenu popUpContextMenu:_searchMenu withEvent:anEvent forView:sender];
}

- (void)_sendPartialString
{
    [[self target] performSelector:[self action] withObject:self];
}

- (void)_searchFieldCancel:(id)sender
{   
    [self setObjectValue:@""];
    [self _sendPartialString];
    [self _updateCancelButtonVisibility];
}

- (void)_searchFieldSearch:(id)sender
{
    var searchString = [sender title];
    
    if ([sender tag] != CPSearchFieldRecentsMenuItemTag)
        [self _addStringToRecentSearches:searchString];
    
    [self setObjectValue:searchString];
    [self _sendPartialString];

    [self _updateCancelButtonVisibility];
}

- (void)_searchFieldClearRecents:(id)sender
{
    [self setRecentSearches:[CPArray array]];
    [self _updateSearchMenu];
 }

- (void)_registerForAutosaveNotification
{
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateAutosavedRecents:) name:@"CPAutosavedRecentsChangedNotification" object:nil];
}

- (void)_deregisterForAutosaveNotification
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:@"CPAutosavedRecentsChangedNotification" object:nil];
}

- (void)_autosaveRecentSearchList
{  
    if (_recentsAutosaveName != nil) 
        [[CPNotificationCenter defaultCenter] postNotificationName:@"CPAutosavedRecentsChangedNotification" object:_recentsAutosaveName];
}

- (void)_updateAutosavedRecents:(id)notification
{
    var list = [self recentSearches],
        name = [notification object],
        bundle_name = [[[CPBundle mainBundle] infoDictionary] objectForKey:"CPBundleName"],
        cookie_name = [bundle_name lowercaseString] + "." + [notification object],

        cookie = [[CPCookie alloc] initWithName:cookie_name],
        cookie_value = [list componentsJoinedByString:@","];
    
    [cookie setValue:cookie_value 
             expires:[[CPDate alloc] initWithTimeIntervalSinceNow:3600*24*365] 
              domain:(window.location.href.hostname)];
}

- (void)_loadRecentSearchList
{
    var list,
        name = [self recentsAutosaveName];
    
    if (name === nil)
        return;

    var bundle_name = [[[CPBundle mainBundle] infoDictionary] objectForKey:"CPBundleName"],
        cookie_name = [bundle_name lowercaseString] + "." + name,     

        cookie = [[CPCookie alloc] initWithName:cookie_name];

    if (cookie != nil)
    {
        var cookie_value = [cookie value];
        list = (cookie_value != @"") ? [cookie_value componentsSeparatedByString:@","] : [CPArray array];
        _recentSearches = list;
    }
}

@end

var CPRecentsAutosaveNameKey            = @"CPRecentsAutosaveNameKey",
    CPSendsWholeSearchStringKey         = @"CPSendsWholeSearchStringKey",
    CPSendsSearchStringImmediatelyKey   = @"CPSendsSearchStringImmediatelyKey",
    CPMaximumRecentsKey                 = @"CPMaximumRecentsKey",
    CPSearchMenuTemplateKey             = @"CPSearchMenuTemplateKey";   

@implementation CPSearchField (CPCoding)

- (void)encodeWithCoder:(CPCoder)coder
{
    [_searchButton removeFromSuperview];
    [_cancelButton removeFromSuperview];

    [super encodeWithCoder:coder];    

    if (_searchButton)
        [self addSubview:_searchButton];
    if (_cancelButton)
        [self addSubview:_cancelButton];

    [coder encodeBool:_sendsWholeSearchString forKey:CPSendsWholeSearchStringKey];
    [coder encodeBool:_sendsSearchStringImmediately forKey:CPSendsSearchStringImmediatelyKey];
    [coder encodeInt:_maximumRecents forKey:CPMaximumRecentsKey];

    if (_recentsAutosaveName)
        [coder encodeObject:_recentsAutosaveName forKey:CPRecentsAutosaveNameKey];
    if (_searchMenuTemplate)
        [coder encodeObject:_searchMenuTemplate forKey:CPSearchMenuTemplateKey];
}

- (id)initWithCoder:(CPCoder)coder
{
    if (self = [super initWithCoder:coder])
    {
        [self _initWithFrame:[self frame]];

        _recentsAutosaveName      = [coder decodeObjectForKey:CPRecentsAutosaveNameKey];
        _sendsWholeSearchString   = [coder decodeBoolForKey:CPSendsWholeSearchStringKey];
        _sendsSearchStringImmediately = [coder decodeBoolForKey:CPSendsSearchStringImmediatelyKey];
        _maximumRecents           = [coder decodeIntForKey:CPMaximumRecentsKey];

        var template              = [coder decodeObjectForKey:CPSearchMenuTemplateKey];
        if (template)
            [self setSearchMenuTemplate:template];
            
        [self setDelegate:self];
    }

    return self;
}

@end
