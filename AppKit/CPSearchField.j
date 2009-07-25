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

/*!
    @global
    @group Menu tags
*/
CPSearchFieldRecentsTitleMenuItemTag = 1000;
/*!
    @global
    @group Menu tags
*/
CPSearchFieldRecentsMenuItemTag = 1001;
/*!
    @global
    @group Menu tags
*/
CPSearchFieldClearRecentsMenuItemTag = 1002;
/*!
    @global
    @group Menu tags
*/
CPSearchFieldNoRecentsMenuItemTag = 1003;

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
    CPSearchFieldSearchImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPSearchField/CPSearchFieldSearch.png"]];
    CPSearchFieldFindImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPSearchField/CPSearchFieldFind.png"]];
    CPSearchFieldCancelImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPSearchField/CPSearchFieldCancel.png"]];
    CPSearchFieldCancelPressedImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPSearchField/CPSearchFieldCancelPressed.png"]];
}

- (id)initWithFrame:(CPRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
      {
          _recentSearches = [CPArray array];
          _maximumRecents = 10;
          _sendsWholeSearchString = NO;
          _sendsSearchStringImmediately = NO;
           
          [self setBezeled:YES];
          [self setBezelStyle:CPTextFieldRoundedBezel];
          [self setBordered:YES];
          [self setEditable:YES];
          [self setDelegate:self];
          
          _cancelButton = [[CPButton alloc] initWithFrame:CPMakeRect(frame.size.width - 27,(frame.size.height-22)/2,22,22)];
          [self resetCancelButton];


          [_cancelButton setHidden:YES];
          [self addSubview:_cancelButton];
          
          _searchButton = [[CPButton alloc] initWithFrame:CPMakeRect(5,(frame.size.height-25)/2,25,25)];
          [_searchButton setBezelStyle:CPRegularSquareBezelStyle];
          [_searchButton setBordered:NO];
          [_searchButton setImageScaling:CPScaleToFit];

#if PLATFORM(DOM)
    _cancelButton._DOMElement.style.cursor = "default";
    _searchButton._DOMElement.style.cursor = "default";
#endif
          
          [self setSearchMenuTemplate:[self _searchMenuTemplate]];
          [self addSubview:_searchButton];       
       }
    
    return self;
}

- (id)copy
{
    var copy = [super copy];
    
    [copy setCancelButton:[_cancelButton copy]];
    [copy setSearchButton:[_searchButton copy]];
    [copy setrecentsAutosaveName:[_recentsAutosaveName copy]];
    [copy setSendsWholeSearchString:[_sendsWholeSearchString copy]];
    [copy setSendsSearchStringImmediately:[_sendsSearchStringImmediately copy]];
    [copy setMaximumRecents:_maximumRecents];
    [copy setSearchMenutemplate:[_searchMenuTemplate copy]];
    
    return copy;
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
        
    if (_searchMenuTemplate == nil)
    {
        searchButtonImage = CPSearchFieldSearchImage;
        action = [self action];
        target = [self target];
    }
    else
    {
        searchButtonImage = CPSearchFieldFindImage;
        action = @selector(_showMenu:);
        target = self;
    }
    
    [button setImage:searchButtonImage];
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
    [button setBezelStyle:CPRegularSquareBezelStyle];
    [button setBordered:NO];
    [button setImageScaling:CPScaleToFit];
    [button setImage:CPSearchFieldCancelImage];
    [button setAlternateImage:CPSearchFieldCancelPressedImage];
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
- (CPRect)searchButtonRectForBounds:(CPRect)rect // fix
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
    The receiver looks for the tag constants described in “Menu tags” to determine how to populate the menu with items related to recent searches. See “Configuring a Search Menu” for a sample of how you might set up the search menu template.
*/
- (void)setSearchMenuTemplate:(CPMenu)menu
{
    _searchMenuTemplate = menu;
    
    [self resetSearchButton];
    [self _updateSearchMenu];
}

// Managing Search Modes
/*!
    Returns a Boolean value indicating whether the receiver sends the search action message when the user clicks the search button (or presses return) or after each keystroke.
    @return <code>YES</code> if the action message is sent all at once when the user clicks the search button or presses return; otherwise, NO if the search string is sent after each keystroke. The default value is NO.
*/
- (BOOL)sendsWholeSearchString
{ 
    return _sendsWholeSearchString; 
}

/*!
    Sets whether the receiver sends the search action message when the user clicks the search button (or presses return) or after each keystroke.
    @param flag <code>YES</code> to send the action message all at once when the user clicks the search button or presses return; otherwise, NO to send the search string after each keystroke.
*/
- (void)setSendsWholeSearchString:(BOOL)flag
{
    _sendsWholeSearchString = flag;
}

/*!
    Returns a Boolean value indicating whether the receiver sends its action immediately upon being notified of changes to the search field text or after a brief pause.
    @return <code>YES</code> if the text field sends its action immediately upon notification of any changes to the search field; otherwise, NO.
*/
- (BOOL)sendsSearchStringImmediately
{ 
    return _sendsSearchStringImmediately; 
}

/*!
    Sets whether the text field sends its action message to the target immediately upon notification of any changes to the search field text or after a brief pause.
    @param flag <code>YES</code> to send the text field's action immediately upon notification of any changes to the search field; otherwise, NO if you want the text field to pause briefly before sending its action message. Pausing gives the user the opportunity to type more text into the search field before initiating the search.
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
    @return An array of <code><CPString</code> objects, each of which contains a search string either displayed in the search menu or from a recent autosave archive. If there have been no recent searches and no prior searches saved under an autosave name, this array may be empty. 
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
    var max = MIN([self maximumRecents],[searches count]);
    var searches = [searches subarrayWithRange:CPMakeRange(0,max)];
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
    _recentsAutosaveName = name;
    
    if(name != nil)
      [self _registerForAutosaveNotification];
    else
      [self _deregisterForAutosaveNotification];
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
    [_cancelButton setHidden:([[self stringValue] length] == 0)];
}

- (void)controlTextDidChange:(CPNotification)aNotification
{
    if(!_sendsWholeSearchString)
    {
        if(_sendsSearchStringImmediately)
            [self _sendPartialString];
        else
        {
            [_partialStringTimer invalidate];
            var timeInterval = [CPSearchField _keyboardDelayForPartialSearchString:[self stringValue]];
    
            _partialStringTimer = [CPTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(_sendPartialString) userInfo:nil repeats:NO];         
        }
    }
    [self _updateCancelButtonVisibility];
}

- (void)sendAction:(SEL)anAction to:(id)anObject
{
    [super sendAction:anAction to:anObject];

    [_partialStringTimer invalidate];

    var current_value = [self objectValue];
    if(current_value != nil && current_value != "" && ![_recentSearches containsObject:current_value])
    {
        [self _addStringToRecentSearches:current_value];
        [self _updateSearchMenu];
    }
    
    [self _updateCancelButtonVisibility];
}

- (void)_addStringToRecentSearches:(CPString)string
{
    var newSearches = [CPMutableArray arrayWithArray:_recentSearches];
    [newSearches addObject:string];
    [self setRecentSearches:newSearches];
}

- (BOOL)trackMouse:(CPEvent)event
{
    var rect;
    var point;
    var location = [event locationInWindow];
    
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

- (CPMenu)_searchMenuTemplate
{
    var template, item;
    
    template = [[CPMenu alloc] init];
    
    item = [[CPMenuItem alloc] initWithTitle:@"Recent searches" action:NULL keyEquivalent:@""];
    [item setTag:CPSearchFieldRecentsTitleMenuItemTag];
    [item setEnabled:NO];
    [template addItem:item];
    
    item = [[CPMenuItem alloc] initWithTitle:@"Recent search item" action:@selector(_searchFieldSearch:) keyEquivalent:@""];
    [item setTag:CPSearchFieldRecentsMenuItemTag];
    [item setTarget:self];
    [template addItem:item];
    
    item = [[CPMenuItem alloc] initWithTitle:@"Clear recent searches" action:@selector(_searchFieldClearRecents:) keyEquivalent:@""];
    [item setTag:CPSearchFieldClearRecentsMenuItemTag];
    [item setTarget:self];
    [template addItem:item];
    
    item = [[CPMenuItem alloc] initWithTitle:@"No recent searches" action:NULL keyEquivalent:@""];
    [item setTag:CPSearchFieldNoRecentsMenuItemTag];
    [item setEnabled:NO];
    [template addItem:item];
    
    return template;
}

- (void)_updateSearchMenu
{
    if(_searchMenuTemplate == nil)
        return;
        
    var i, menu = [[CPMenu alloc] init];
    var countOfRecents = [_recentSearches count];
    
    for (i = 0; i < [_searchMenuTemplate numberOfItems]; i++)
    {
        var item = [_searchMenuTemplate itemAtIndex:i];
        var tag = [item tag];
        
        if(tag == CPSearchFieldClearRecentsMenuItemTag && countOfRecents != 0)
        {
            var separator = [CPMenuItem separatorItem];
            [menu addItem:separator];
        }
        
        if (!(tag == CPSearchFieldRecentsTitleMenuItemTag && countOfRecents == 0) &&
            !(tag == CPSearchFieldClearRecentsMenuItemTag && countOfRecents == 0) &&
            !(tag == CPSearchFieldNoRecentsMenuItemTag && countOfRecents != 0)    &&
            !(tag == CPSearchFieldRecentsMenuItemTag))
        {     
            var templateItem = [[CPMenuItem alloc] initWithTitle:[item title] action:[item action] keyEquivalent:[item keyEquivalent]];
            [templateItem setTarget:[item target]];
            [templateItem setEnabled:[item isEnabled]];
            [templateItem setTag:[item tag]];
            [menu addItem:templateItem];
        }
        else if (tag == CPSearchFieldRecentsMenuItemTag)
        {
            var j;
            for (j = 0; j < countOfRecents; j++)
            {
                var rencentItem = [[CPMenuItem alloc] initWithTitle:[_recentSearches objectAtIndex:j] action:[item action] keyEquivalent:[item keyEquivalent]];
                [rencentItem setTarget:[item target]];
                [menu addItem:rencentItem];
            }
        }
    }    
    _searchMenu = menu;
}


- (void)_showMenu:(id)sender
{
    if(_searchMenu == nil || ![self isEnabled])
        return;
        
    [super selectText:nil];
    
    var origin = CPMakePoint([self frame].origin.x, [self frame].origin.y + [self frame].size.height);
    var anEvent = [CPEvent keyEventWithType:CPRightMouseDown location:origin modifierFlags:0 timestamp:[CPDate date] windowNumber:1 context:[[CPGraphicsContext currentContext] graphicsPort] characters:"" charactersIgnoringModifiers:"" isARepeat:NO keyCode:0];
    
    [CPMenu popUpContextMenu:_searchMenu withEvent:anEvent forView:sender];
}

- (void)_sendPartialString
{
    [[self target] performSelector:[self action] withObject:self];
}

- (void)_searchFieldCancel:(id)sender
{   
    [self setObjectValue:nil];
    [self _sendPartialString];
    [self _updateCancelButtonVisibility];
    [sender setHidden:YES];
}

- (void)_searchFieldSearch:(id)sender
{
    [self setObjectValue:[sender title]];
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

- (void)_updateAutosavedRecents:(id)notification
{
    var name = [notification object];
    var list = [self recentSearches];

    [[CPUserDefaults standardUserDefaults] setObject:list forKey:name];

}

- (void)_autosaveRecentSearchList
{  
    if(_recentsAutosaveName != nil) 
        [[CPNotificationCenter defaultCenter] postNotificationName:@"CPAutosavedRecentsChangedNotification" object:_recentsAutosaveName];
}

- (void)_loadRecentSearchList
{
    var list,
        name = [self recentsAutosaveName];
    
    list = [[CPUserDefaults standardUserDefaults] objectForKey:name];
    _recentSearches = list;
}

/*
- (BOOL)trackMouse:(CPEvent)theEvent inRect:(CPRect)cellFrame ofView:(CPView)aTextView untilMouseUp:(BOOL)flag
{
}

- (BOOL)_trimRecentSearchList
{
}

- (void)_trackButton:(CPButton)button forEvent:(CPEvent)event inRect:(CPRect)rect ofView:(id)view
{
}

- (id)_selectOrEdit:(CPRect)rect inView:(id)view target:(id)target editor:(id)editor event:(id)event start:(int)start end:(int)end
{
}

- (void)resetCursorRect:(CPRect)rect inView:(id)view
{
}
*/

@end

var CPSearchButtonKey                   = @"CPSearchButtonKey",
    CPCancelButtonKey                   = @"CPCancelButtonKey",
    CPRecentsAutosaveNameKey            = @"CPRecentsAutosaveNameKey",
    CPSendsWholeSearchStringKey         = @"CPSendsWholeSearchStringKey",
    CPSendsSearchStringImmediatelyKey   = @"CPSendsSearchStringImmediatelyKey",
    CPMaximumRecentsKey                 = @"CPMaximumRecentsKey",
    CPSearchMenuTemplateKey             = @"CPSearchMenuTemplateKey";   

@implementation CPSearchField (CPCoding)

- (void)encodeWithCoder:(CPCoder)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeObject:_searchButton forKey:CPSearchButtonKey];
    [coder encodeObject:_cancelButton forKey:CPCancelButtonKey];
    [coder encodeObject:_recentsAutosaveName forKey:CPRecentsAutosaveNameKey];
    [coder encodeBool:_sendsWholeSearchString forKey:CPSendsWholeSearchStringKey];
    [coder encodeBool:_sendsSearchStringImmediately forKey:CPSendsSearchStringImmediatelyKey];
    [coder encodeInt:_maximumRecents forKey:CPMaximumRecentsKey];
    [coder encodeObject:_searchMenuTemplate forKey:CPSearchMenuTemplateKey];
}

- (id)initWithCoder:(CPCoder)coder
{
    self = [super initWithCoder:coder];
    
    _searchButton             = [coder decodeObjectForKey:CPSearchButtonKey];
    _cancelButton             = [coder decodeObjectForKey:CPCancelButtonKey];
    _recentsAutosaveName      = [coder decodeObjectForKey:CPRecentsAutosaveNameKey];
    _sendsWholeSearchString   = [coder decodeBoolForKey:CPSendsWholeSearchStringKey];
    _sendsSearchStringImmediately = [coder decodeBoolForKey:CPSendsSearchStringImmediatelyKey];
    _maximumRecents           = [coder decodeIntForKey:CPMaximumRecentsKey];
    [self setSearchMenuTemplate:[coder decodeObjectForKey:CPSearchMenuTemplateKey]];
    [self resetCancelButton];
    [self setDelegate:self];

    return self;
}

@end