/*
 * SettingsWindowController.j
 * SmartFoldersDemo
 *
 * Settings window with the application's appearance: Light, Dark or Auto, which follows
 * the system. The choice is kept in the user defaults and applied at launch.
 * Exercises CPSegmentedControl, CPPanel and CPApplication's appearance.
 */

@import <AppKit/AppKit.j>

var SettingsAppearanceKey   = @"SmartFoldersDemoAppearance",
    SettingsAppearanceNames = [CPAppearanceNameAqua, CPAppearanceNameDarkAqua, nil],
    SettingsAutoSegment     = 2;

@implementation SettingsWindowController : CPWindowController
{
    CPSegmentedControl  _appearanceControl;
}

/*
    Applies the appearance kept in the user defaults. Without one, the application follows
    the system appearance.
*/
+ (void)applySavedAppearance
{
    var segment = [[CPUserDefaults standardUserDefaults] objectForKey:SettingsAppearanceKey];

    [self _applyAppearanceOfSegment:segment == nil ? SettingsAutoSegment : segment];
}

+ (void)_applyAppearanceOfSegment:(int)aSegment
{
    var name = SettingsAppearanceNames[aSegment];

    [CPApp setAppearance:name ? [CPAppearance appearanceNamed:name] : nil];
}

- (id)init
{
    var panel = [[CPPanel alloc] initWithContentRect:CGRectMake(0, 0, 320, 90) styleMask:CPTitledWindowMask | CPClosableWindowMask];

    if (self = [super initWithWindow:panel])
    {
        [panel setTitle:@"Settings"];

        var contentView = [panel contentView],
            label = [CPTextField labelWithTitle:@"Appearance:"];

        [label sizeToFit];
        [label setFrameOrigin:CGPointMake(20, 34)];
        [contentView addSubview:label];

        _appearanceControl = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(110, 30, 180, 24)];
        [_appearanceControl setSegmentCount:3];
        [_appearanceControl setLabel:@"Light" forSegment:0];
        [_appearanceControl setLabel:@"Dark" forSegment:1];
        [_appearanceControl setLabel:@"Auto" forSegment:2];
        [_appearanceControl setWidth:60 forSegment:0];
        [_appearanceControl setWidth:60 forSegment:1];
        [_appearanceControl setWidth:60 forSegment:2];
        [_appearanceControl setTarget:self];
        [_appearanceControl setAction:@selector(appearanceDidChange:)];
        [contentView addSubview:_appearanceControl];

        var segment = [[CPUserDefaults standardUserDefaults] objectForKey:SettingsAppearanceKey];
        [_appearanceControl setSelectedSegment:segment == nil ? SettingsAutoSegment : segment];

        [panel center];
    }

    return self;
}

- (void)appearanceDidChange:(id)aSender
{
    var segment = [aSender selectedSegment];

    [[CPUserDefaults standardUserDefaults] setObject:segment forKey:SettingsAppearanceKey];
    [[self class] _applyAppearanceOfSegment:segment];
}

@end
