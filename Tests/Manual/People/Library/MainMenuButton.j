/*
 * MainMenuButton.j
 * People
 *
 * Created by David Richardson.
 * Copyright 2026, The Cappuccino Project.
 *
 * A button bar button with an ellipsis icon that pops up a copy of the main menu: one item
 * for each menu of the main menu, with a copy of that menu as its submenu. The sidebar's
 * button bar has one, and the people table's button bar has another for the time the sidebar
 * is collapsed. Each button has its own copy, because a menu item belongs to one menu only.
 *
 * The copied items keep their actions and have no target, so they go through the responder
 * chain and are validated as in the menu bar, titles included. The application builds the
 * main menu before the panes load.
 */

@import <AppKit/AppKit.j>

@import "MaskImage.j"

// Three dots, the "more" icon.
var MainMenuMask        = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNiAxNiI+PGNpcmNsZSBjeD0iMyIgY3k9IjgiIHI9IjEuNSIvPjxjaXJjbGUgY3g9IjgiIGN5PSI4IiByPSIxLjUiLz48Y2lyY2xlIGN4PSIxMyIgY3k9IjgiIHI9IjEuNSIvPjwvc3ZnPg==')",
    MainMenuIconSize    = CGSizeMake(16, 16);


@implementation MainMenuButton : CPObject
{
    CPButton    _button     @accessors(readonly, property=button);
    CPMenu      _menu;
}

/*
    Makes a plain button of aButtonBar that pops up the menu. The ellipsis says that it opens
    a menu, so it has no pull-down arrow, which the button bar's pull-down button draws.
*/
- (id)initWithButtonBar:(CPButtonBar)aButtonBar
{
    if (self = [super init])
    {
        _menu = [[CPMenu alloc] initWithTitle:@"Main Menu"];
        [self _addMainMenuCopyTo:_menu];

        _button = [aButtonBar buttonWithImage:MaskImage(MainMenuMask, MainMenuIconSize, [CPColor secondaryLabelColor])
                               alternateImage:MaskImage(MainMenuMask, MainMenuIconSize, [CPColor labelColor])];
        [_button setToolTip:@"Main menu"];
        [_button setTarget:self];
        [_button setAction:@selector(showMenu:)];
    }

    return self;
}

/*
    Opens the menu at the button's top left corner. The menu stays within the window, so near
    the bottom of the window it opens upwards.
*/
- (void)showMenu:(id)aSender
{
    [_menu popUpMenuPositioningItem:nil atLocation:CGPointMakeZero() inView:_button callback:nil];
}

- (void)_addMainMenuCopyTo:(CPMenu)aMenu
{
    var mainMenuItems = [[CPApp mainMenu] itemArray];

    for (var i = 0, count = [mainMenuItems count]; i < count; i++)
    {
        var mainMenuItem = mainMenuItems[i],
            submenu = [mainMenuItem submenu];

        if (!submenu)
            continue;

        var item = [aMenu addItemWithTitle:[mainMenuItem title] action:nil keyEquivalent:@""];
        [aMenu setSubmenu:[self _copyOfMenu:submenu] forItem:item];
    }
}

- (CPMenu)_copyOfMenu:(CPMenu)aMenu
{
    var copy = [[CPMenu alloc] initWithTitle:[aMenu title]],
        items = [aMenu itemArray];

    for (var i = 0, count = [items count]; i < count; i++)
    {
        var itemCopy = [items[i] copy],
            submenu = [items[i] submenu];

        [copy addItem:itemCopy];

        // -[CPMenuItem copy] does not copy the submenu.
        if (submenu)
            [copy setSubmenu:[self _copyOfMenu:submenu] forItem:itemCopy];
    }

    return copy;
}

@end
