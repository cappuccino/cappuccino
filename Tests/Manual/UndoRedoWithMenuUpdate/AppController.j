
@implementation AppController : CPObject
{
    CPTextField     label;
    CPSlider        theSlider;
    CPUndoManager   undoManager @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];


    label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

    [label setStringValue:@"Hello World!"];
    [label setFont:[CPFont boldSystemFontOfSize:24.0]];

    [label sizeToFit];

    [label setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [label setCenter:[contentView center]];

    [contentView addSubview:label];

    theSlider = [[CPSlider alloc] initWithFrame:CGRectMake(100, 100, 180, 24)];
    [theSlider setMinValue:36];
    [theSlider setMaxValue:238];
    [theSlider setObjectValue:([theSlider minValue] + [theSlider maxValue]) / 2];
    [theSlider setTarget:self];
    [theSlider setAction:@selector(doSlider:)];
    [contentView addSubview:theSlider];


    [theWindow orderFront:self];



    // Uncomment the following line to turn on the standard menu bar.
    [CPMenu setMenuBarVisible:YES];

// setup the menus to manage
    undoManager = [[CPUndoManager alloc] init];

    var editmenuItem = [[[CPApplication sharedApplication] mainMenu] itemWithTitle: @"Edit"];
    [[editmenuItem submenu] setAutoenablesItems:YES];

    var undoMenuItem = [[editmenuItem submenu] itemWithTitle:@"Undo"];

    [undoMenuItem setTag:@"Undo"];
    [undoMenuItem setTarget:self];

    var redoMenuItem = [[editmenuItem submenu] itemWithTitle:@"Redo"];

    [redoMenuItem setTag:@"Redo"];
    [redoMenuItem setTarget:self];
}


- (void)doSlider:sender
{
    [self setSliderValue:[sender objectValue]];
}


- (void)setSliderValue:aValue
{
    [[undoManager prepareWithInvocationTarget:self] setSliderValue:[label objectValue]];
    [theSlider setObjectValue:aValue];
    [undoManager setActionName:@"slideto: " + aValue];

    [label setObjectValue:aValue];
    [label sizeToFit];
}

- (void)undo:(id)sender
{
    [undoManager undo];
    [[sender _menuItemView] highlight:NO];
}

- (void)redo:(id)sender
{
    [undoManager redo];
    [[sender _menuItemView] highlight:NO];
}

//this will be called whenver the user clicks on an autoenabled menu
- (BOOL)validateMenuItem:(id)anItem
{
    switch ([anItem tag])
    {
        case @"Undo" :
            [anItem setTitle:[undoManager undoMenuItemTitle]];
            return([undoManager canUndo]);
            break;
        case @"Redo" :
            [anItem setTitle:[undoManager redoMenuItemTitle]];
            return([undoManager canRedo]);
            break;
        default:
            return [anItem isEnabled];
    }
}

@end



////////////// autoenablesItems from here  http://github.com/farcaller/cappuccino/commit/5d1af7192d2afe5b938c5bcdd197f15c79811b7f
////////////// Currently waiting to be pulled into master

@implementation CPMenu(autoenablesItems)

- (void)update
{
    var cnt = [_items count];
    for (var i = 0; i < cnt; ++i)
    {
        var item = [_items objectAtIndex:i];
        if ([[item target] respondsToSelector:@selector(validateMenuItem:)])
            [item _setEnabledByMenu:[[item target] validateMenuItem:item]];
        else
            [item _setEnabledByMenu:[item isEnabled]]; /// BD Change from NO
    }
}

@end



@implementation CPMenuItem(autoenablesItems)

// a private function to toggle availability as part of update check
- (void)_setEnabledByMenu:(BOOL)isEnabled
{
    if (![_menu autoenablesItems])
        return;

    _isEnabled = isEnabled;
    [_menuItemView setDirty];
}

// Performs autoenable processing, returns isEnabled to propagate state to NativeHost
- (BOOL)_performAutoenable
{
    if ([_menu autoenablesItems])
    {
        if (_target)
        {
            if ([_target respondsToSelector:@selector(validateMenuItem:)])
            {
                var isEnabled = [_target validateMenuItem:self];

                _isEnabled = isEnabled;
                [_menuItemView setDirty];
                return _isEnabled;
            }
            else
                return YES; // enabled by default
        }
        else
        {
            // XXX: will toggle state as part of _target check, required to sync stane with NativeHost
            _isEnabled = isEnabled;
            [_menuItemView setDirty];

            return NO;
        }
    }
    else
    {
       // XXX: should it return NO, if target is nil?..
        return [self isEnabled];
    }
}


@end


@implementation _CPMenuManager(autoenablesItems)

- (void)showMenu:(CPMenu)newMenu fromMenu:(CPMenu)baseMenu atPoint:(CGPoint)aGlobalLocation
{
    var count = _menuContainerStack.length,
        index = count;

    // Hide all menus up to the base menu...
    while (index--)
    {
        var menuContainer = _menuContainerStack[index],
            menu = [menuContainer menu];

        // If we reach the base menu, or this menu is already being shown, break.
        if (menu === baseMenu)
            break;

        // If this menu is already being shown, unhighlight and return.
        if (menu === newMenu)//&& [menu supermenu] === baseMenu)
        {
            [newMenu _highlightItemAtIndex:CPNotFound];
            return;
        }

        [menuContainer orderOut:self];
        [menuContainer setMenu:nil];

        [_CPMenuWindow poolMenuWindow:menuContainer];
        [_menuContainerStack removeObjectAtIndex:index];
    }

    if (!newMenu)
        return;

    if ([newMenu autoenablesItems])
        [newMenu update];
    // Unhighlight any previously highlighted item.
    [newMenu _highlightItemAtIndex:CPNotFound];

    var menuWindow = [_CPMenuWindow menuWindowWithMenu:newMenu font:[_menuContainerStack[0] font]];

    [_menuContainerStack addObject:menuWindow];

    [menuWindow setConstraintRect:_constraintRect];

    // If our parent menu is a menu bar...
    if (baseMenu === [self trackingMenu] && [[self trackingMenuContainer] isMenuBar])
        [menuWindow setBackgroundStyle:_CPMenuWindowMenuBarBackgroundStyle];
    else
        [menuWindow setBackgroundStyle:_CPMenuWindowPopUpBackgroundStyle];

    [menuWindow setFrameOrigin:aGlobalLocation];
    [menuWindow orderFront:self];
}

@end
//////////////////////////// end of autoenablesItems




