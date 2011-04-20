@implementation CPMenuValidatedUserInterfaceItemTest : OJTestCase
{
    CPMenu                          _menu @accessors(property=menu);
}

- (void)setUp
{
    [[CPApplication sharedApplication] setDelegate:[[MenuTarget alloc] init]];

    _menu = [[CPMenu alloc] init];

    [_menu addItem:[[CPMenuItem alloc] initWithTitle:@"implemented" action:@selector(implementedAction:) keyEquivalent:nil]];
    [_menu addItem:[[CPMenuItem alloc] initWithTitle:@"disabled" action:@selector(disabledAction:) keyEquivalent:nil]];
    [_menu addItem:[[CPMenuItem alloc] initWithTitle:@"unimplemented" action:@selector(unimplementedAction:) keyEquivalent:nil]];
}

- (void)testAutoenable
{
    // Update is what actually performs the autoenabling so we need to call it manually.
    // It's normally called automatically just before a menu becomes visible.
    [[self menu] update];

    [self assertTrue:[[[self menu] itemWithTitle:@"implemented"] isEnabled] message:@"The implemented action should be enabled"];
    [self assertFalse:[[[self menu] itemWithTitle:@"disabled"] isEnabled] message:@"The disbabled action should be disabled"];
    [self assertFalse:[[[self menu] itemWithTitle:@"unimplemented"] isEnabled] message:@"The unimplemented action should be disabled"];
}

@end

@implementation MenuTarget : CPObject
{
}

- (BOOL)validateMenuItem:(CPMenuItem)theMenuItem
{
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