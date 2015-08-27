var CPMenuValidatedUserInterfaceItemTestValidatedItems = [];

@class MenuTarget

@implementation CPMenuValidatedUserInterfaceItemTest : OJTestCase
{
    CPMenu                          _menu @accessors(property=menu);

    MenuTarget                      _menuTarget @accessors(property=menuTarget);
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    _menuTarget = [[MenuTarget alloc] init];
    [[CPApplication sharedApplication] setDelegate:_menuTarget];

    _menu = [[CPMenu alloc] init];

    [_menu addItem:[[CPMenuItem alloc] initWithTitle:@"implemented" action:@selector(implementedAction:) keyEquivalent:nil]];
    [_menu addItem:[[CPMenuItem alloc] initWithTitle:@"disabled" action:@selector(disabledAction:) keyEquivalent:nil]];
    [_menu addItem:[[CPMenuItem alloc] initWithTitle:@"unimplemented" action:@selector(unimplementedAction:) keyEquivalent:nil]];

    var parentItem = [[CPMenuItem alloc] initWithTitle:@"parent" action:nil keyEquivalent:nil];
    [_menu addItem:parentItem];

    [parentItem setSubmenu:[[CPMenu alloc] init]];
    [[parentItem submenu] addItem:[[CPMenuItem alloc] initWithTitle:@"Submenu 1" action:nil keyEquivalent:nil]];

    CPMenuValidatedUserInterfaceItemTestValidatedItems = [];

    // Update is what performs the autoenabling so we need to call it manually.
    // It's normally called automatically just before a menu becomes visible.
    [_menu update];
}

- (void)testAutoenable
{
    [self assertTrue:[[[self menu] itemWithTitle:@"implemented"] isEnabled] message:@"The implemented action should be enabled"];
    [self assertFalse:[[[self menu] itemWithTitle:@"disabled"] isEnabled] message:@"The disbabled action should be disabled"];
    [self assertFalse:[[[self menu] itemWithTitle:@"unimplemented"] isEnabled] message:@"The unimplemented action should be disabled"];
}

- (void)testThatParentMenusAreNotValidated
{
    var parentItem = [[self menu] itemWithTitle:@"parent"];

    [self assertTrue:[parentItem isEnabled] message:@"Parent items should never be disabled"];
    [self assertFalse:[[[self menuTarget] validatedItems] containsObject:parentItem] message:@"Parent items should never be validated"];
}

@end

@implementation MenuTarget : CPObject
{
    CPArray                     _validatedItems @accessors(property=validatedItems, readonly);
}

- (id)init
{
    if (self = [super init])
    {
        _validatedItems = [];
    }

    return self;
}

- (BOOL)validateMenuItem:(CPMenuItem)theMenuItem
{
    [_validatedItems addObject:theMenuItem];

    if ([theMenuItem action] === @selector(disabledAction:))
        return NO;

    return YES;
}

- (@action)implementedAction:(id)theSender
{

}

- (@action)disabledAction:(id)theSender
{

}

@end
