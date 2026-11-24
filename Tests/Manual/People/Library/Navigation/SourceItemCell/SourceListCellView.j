/*
 * SourceListCellView.j
 * People
 *
 * View-based outline cell of the source list: icon, title and count badge.
 */

@import <AppKit/AppKit.j>

@import "../../Library.j"
@import "SourceIconView.j"
@import "SourceBadgeView.j"

/*
    The identifier of the cell view; the source list asks the outline view for views with it.
*/
SourceCellIdentifier = @"SourceCell";

@implementation SourceListCellView : CPTableCellView
{
    SourceIconView  _iconView;
    CPTextField     _titleField;
    SourceBadgeView _badgeView;
    BOOL            _isHeader;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        var height = CGRectGetHeight(aFrame);

        _iconView = [[SourceIconView alloc] initWithFrame:CGRectMake(2, (height - 16) / 2, 18, 16)];
        [_iconView setAutoresizingMask:CPViewMinYMargin | CPViewMaxYMargin];
        [self addSubview:_iconView];

        _titleField = [[CPTextField alloc] initWithFrame:CGRectMake(24, 0, CGRectGetWidth(aFrame) - 24, height)];
        [_titleField setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [_titleField setVerticalAlignment:CPCenterVerticalTextAlignment];
        [_titleField setLineBreakMode:CPLineBreakByTruncatingTail];
        [_titleField setEditable:NO];
        [_titleField setBezeled:NO];
        [_titleField setDrawsBackground:NO];
        [self addSubview:_titleField];

        _badgeView = [[SourceBadgeView alloc] initWithFrame:CGRectMake(CGRectGetWidth(aFrame) - 30, (height - SourceBadgeHeight) / 2, SourceBadgeMinWidth, SourceBadgeHeight)];
        [_badgeView setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin | CPViewMaxYMargin];
        [self addSubview:_badgeView];

        [self setIdentifier:SourceCellIdentifier];
    }

    return self;
}

- (void)configureWithItem:(SourceItem)anItem count:(int)aCount
{
    _isHeader = [anItem isSection];

    var bounds = [self bounds],
        width = CGRectGetWidth(bounds),
        height = CGRectGetHeight(bounds);

    [_titleField setStringValue:[anItem name]];

    if (_isHeader)
    {
        [_iconView setHidden:YES];
        [_badgeView setHidden:YES];
        [_titleField setFont:[CPFont boldSystemFontOfSize:11.0]];
        [_titleField setFrame:CGRectMake(0, 0, width, height)];
    }
    else
    {
        var kind = [anItem isKindOfClass:[SmartFolder class]] ? @"smart" :
                   [anItem isKindOfClass:[LibraryGroup class]] ? @"group" : @"all";

        [_iconView setHidden:NO];
        [_iconView setKind:kind];
        [_titleField setFont:[CPFont systemFontOfSize:12.0]];

        [_badgeView setCount:aCount];

        var badgeWidth = [_badgeView isHidden] ? 0 : [_badgeView preferredWidth];

        [_badgeView setFrame:CGRectMake(width - badgeWidth - 8, Math.round((height - SourceBadgeHeight) / 2), badgeWidth, SourceBadgeHeight)];
        [_titleField setFrame:CGRectMake(24, 0, MAX(0, width - 24 - badgeWidth - 14), height)];
    }

    [self _updateSelectionAppearance];
}

- (void)setThemeState:(ThemeState)aState
{
    [super setThemeState:aState];
    [self _updateSelectionAppearance];
}

- (void)unsetThemeState:(ThemeState)aState
{
    [super unsetThemeState:aState];
    [self _updateSelectionAppearance];
}

- (void)_updateSelectionAppearance
{
    /*
        CPTableView marks data views of selected rows with CPThemeStateSelectedDataView and,
        only while the table is focused (first responder in the key window), additionally
        with CPThemeStateFirstResponder. The unfocused selection colour is a light gray, so
        the selected text colour is only legible in the focused case. A title without a
        colour of its own takes the theme's text colour, which follows the appearance.
    */
    var selected = [self hasThemeState:CPThemeStateSelectedDataView],
        emphasized = selected && [self hasThemeState:CPThemeStateFirstResponder];

    [_iconView setSelected:emphasized];
    [_badgeView setSelected:emphasized];

    if (_isHeader)
        [_titleField setTextColor:[CPColor secondaryLabelColor]];
    else
        [_titleField setTextColor:emphasized ? [CPColor alternateSelectedControlTextColor] : nil];
}

@end
