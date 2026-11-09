/*
 *  CPImageNamedTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-09.
 *  Copyright David Richardson 2026.
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

@import <AppKit/CPImage.j>
@import <AppKit/CPAppearance.j>
@import <AppKit/CPTheme.j>
@import <AppKit/_CPCibCustomResource.j>

/*
    Each system image constant and AppKit's string for it, from AppKit's NSImageName constants
    on macOS 27 without the Touch Bar names.
*/
var CPImageNamedTestAppKitNames = [
        [CPImageNameActionTemplate, @"NSActionTemplate"],
        [CPImageNameAddTemplate, @"NSAddTemplate"],
        [CPImageNameAdvanced, @"NSAdvanced"],
        [CPImageNameApplicationIcon, @"NSApplicationIcon"],
        [CPImageNameBluetoothTemplate, @"NSBluetoothTemplate"],
        [CPImageNameBonjour, @"NSBonjour"],
        [CPImageNameBookmarksTemplate, @"NSBookmarksTemplate"],
        [CPImageNameCaution, @"NSCaution"],
        [CPImageNameColorPanel, @"NSColorPanel"],
        [CPImageNameColumnViewTemplate, @"NSColumnViewTemplate"],
        [CPImageNameComputer, @"NSComputer"],
        [CPImageNameDotMac, @"NSDotMac"],
        [CPImageNameEnterFullScreenTemplate, @"NSEnterFullScreenTemplate"],
        [CPImageNameEveryone, @"NSEveryone"],
        [CPImageNameExitFullScreenTemplate, @"NSExitFullScreenTemplate"],
        [CPImageNameFlowViewTemplate, @"NSFlowViewTemplate"],
        [CPImageNameFolder, @"NSFolder"],
        [CPImageNameFolderBurnable, @"NSFolderBurnable"],
        [CPImageNameFolderSmart, @"NSFolderSmart"],
        [CPImageNameFollowLinkFreestandingTemplate, @"NSFollowLinkFreestandingTemplate"],
        [CPImageNameFontPanel, @"NSFontPanel"],
        [CPImageNameGoBackTemplate, @"NSGoBackTemplate"],
        [CPImageNameGoForwardTemplate, @"NSGoForwardTemplate"],
        [CPImageNameGoLeftTemplate, @"NSGoLeftTemplate"],
        [CPImageNameGoRightTemplate, @"NSGoRightTemplate"],
        [CPImageNameHomeTemplate, @"NSHomeTemplate"],
        [CPImageNameIChatTheaterTemplate, @"NSIChatTheaterTemplate"],
        [CPImageNameIconViewTemplate, @"NSIconViewTemplate"],
        [CPImageNameInfo, @"NSInfo"],
        [CPImageNameInvalidDataFreestandingTemplate, @"NSInvalidDataFreestandingTemplate"],
        [CPImageNameLeftFacingTriangleTemplate, @"NSLeftFacingTriangleTemplate"],
        [CPImageNameListViewTemplate, @"NSListViewTemplate"],
        [CPImageNameLockLockedTemplate, @"NSLockLockedTemplate"],
        [CPImageNameLockUnlockedTemplate, @"NSLockUnlockedTemplate"],
        [CPImageNameMenuMixedStateTemplate, @"NSMenuMixedStateTemplate"],
        [CPImageNameMenuOnStateTemplate, @"NSMenuOnStateTemplate"],
        [CPImageNameMobileMe, @"NSMobileMe"],
        [CPImageNameMultipleDocuments, @"NSMultipleDocuments"],
        [CPImageNameNetwork, @"NSNetwork"],
        [CPImageNamePathTemplate, @"NSPathTemplate"],
        [CPImageNamePreferencesGeneral, @"NSPreferencesGeneral"],
        [CPImageNameQuickLookTemplate, @"NSQuickLookTemplate"],
        [CPImageNameRefreshFreestandingTemplate, @"NSRefreshFreestandingTemplate"],
        [CPImageNameRefreshTemplate, @"NSRefreshTemplate"],
        [CPImageNameRemoveTemplate, @"NSRemoveTemplate"],
        [CPImageNameRevealFreestandingTemplate, @"NSRevealFreestandingTemplate"],
        [CPImageNameRightFacingTriangleTemplate, @"NSRightFacingTriangleTemplate"],
        [CPImageNameShareTemplate, @"NSShareTemplate"],
        [CPImageNameSlideshowTemplate, @"NSSlideshowTemplate"],
        [CPImageNameSmartBadgeTemplate, @"NSSmartBadgeTemplate"],
        [CPImageNameStatusAvailable, @"NSStatusAvailable"],
        [CPImageNameStatusNone, @"NSStatusNone"],
        [CPImageNameStatusPartiallyAvailable, @"NSStatusPartiallyAvailable"],
        [CPImageNameStatusUnavailable, @"NSStatusUnavailable"],
        [CPImageNameStopProgressFreestandingTemplate, @"NSStopProgressFreestandingTemplate"],
        [CPImageNameStopProgressTemplate, @"NSStopProgressTemplate"],
        [CPImageNameTrashEmpty, @"NSTrashEmpty"],
        [CPImageNameTrashFull, @"NSTrashFull"],
        [CPImageNameUser, @"NSUser"],
        [CPImageNameUserAccounts, @"NSUserAccounts"],
        [CPImageNameUserGroup, @"NSUserGroup"],
        [CPImageNameUserGuest, @"NSUserGuest"],
    ];

/*
    A coder that the cib loader accepts for resolving a custom resource.
*/
@implementation CPImageNamedTestCoder : CPObject

- (CPBundle)bundle
{
    return [CPBundle mainBundle];
}

@end

@implementation CPImageNamedTest : OJTestCase
{
    CPTheme     _previousTheme;
}

/*
    Each test starts with a theme that gives no images, so that a system image takes its
    default unless the test sets another theme.
*/
- (void)setUp
{
    _previousTheme = [CPTheme defaultTheme];
    [CPTheme setDefaultTheme:[[CPTheme alloc] initWithName:@"CPImageNamedTestEmpty"]];
}

- (void)tearDown
{
    [CPTheme setDefaultTheme:_previousTheme];
    [CPAppearance setCurrentAppearance:nil];
    [CPImage imageNamed:CPImageNameAddTemplate]._sizeOverride = nil;
}

/*
    A theme that gives the add image for every appearance, for DarkAqua and for high-contrast
    DarkAqua.
*/
- (CPTheme)themeWithAddImages
{
    var theme = [[CPTheme alloc] initWithName:@"CPImageNamedTestAddImages"],
        template = [[CPImage alloc] init];

    [template setValue:[[CPImage alloc] initByReferencingFile:@"normal.png" size:CGSizeMake(10, 10)] forThemeAttribute:@"add-template"];
    [template setValue:[[CPImage alloc] initByReferencingFile:@"dark.png" size:CGSizeMake(10, 10)] forThemeAttribute:@"add-template" inState:CPThemeStateAppearanceDarkAqua];
    [template setValue:[[CPImage alloc] initByReferencingFile:@"hc-dark.png" size:CGSizeMake(10, 10)] forThemeAttribute:@"add-template" inState:CPThemeStateAppearanceAccessibilityHighContrastDarkAqua];
    [theme takeThemeFromObject:template];

    return theme;
}

- (CPTheme)themeWithAddImage:(CPImage)anImage
{
    var theme = [[CPTheme alloc] initWithName:@"CPImageNamedTestAddImage"],
        template = [[CPImage alloc] init];

    [template setValue:anImage forThemeAttribute:@"add-template"];
    [theme takeThemeFromObject:template];

    return theme;
}

- (CPString)addImageFilenameIn:(CPString)anAppearanceName
{
    var filename = nil;

    [[CPAppearance appearanceNamed:anAppearanceName] performAsCurrentDrawingAppearance:function()
    {
        filename = [[CPImage imageNamed:CPImageNameAddTemplate] filename];
    }];

    return filename;
}

// MARK: Names

- (void)testNamesUseAppKitStringsWithTheCPPrefix
{
    CPImageNamedTestAppKitNames.forEach(function(aPair)
    {
        if (aPair[1] === @"NSColorPanel")
            [self assert:@"CPImageNameColorPanel" equals:aPair[0]];
        else
            [self assert:aPair[1].replace(/^NS/, "CP") equals:aPair[0]];
    });
}

- (void)testEachSystemImageNameGivesItsSharedImage
{
    CPImageNamedTestAppKitNames.concat([[CPImageNameColorPanelHighlighted]]).forEach(function(aPair)
    {
        var image = [CPImage imageNamed:aPair[0]];

        [self assertNotNull:image message:aPair[0]];
        [self assert:image same:[CPImage imageNamed:aPair[0]]];
        [self assert:aPair[0] equals:[image name]];
    });
}

- (void)testAnUnknownNameGivesNil
{
    [self assertNull:[CPImage imageNamed:@"CPImageNamedTestNoSuchImage"]];
}

// MARK: Defaults

- (void)testWithoutAThemeValueASystemImageIsEmpty
{
    var image = [CPImage imageNamed:CPImageNameAddTemplate];

    [self assert:@"" equals:[image filename]];
    [self assertTrue:CGSizeEqualToSize(CGSizeMakeZero(), [image size])];
    [self assert:CPImageLoadStatusCompleted equals:[image loadStatus]];
    [self assertFalse:[image isCSSBased]];
}

- (void)testTheColorPanelImagesKeepTheirAppKitResources
{
    [self assertTrue:[[[CPImage imageNamed:CPImageNameColorPanel] filename] hasSuffix:@"CPImage/CPImageNameColorPanel.png"]];
    [self assertTrue:CGSizeEqualToSize(CGSizeMake(26, 29), [[CPImage imageNamed:CPImageNameColorPanel] size])];
    [self assertTrue:[[[CPImage imageNamed:CPImageNameColorPanelHighlighted] filename] hasSuffix:@"CPImage/CPImageNameColorPanelHighlighted.png"]];
}

// MARK: Theme values

- (void)testAThemeValueGivesTheImage
{
    [CPTheme setDefaultTheme:[self themeWithAddImages]];

    [self assert:@"normal.png" equals:[self addImageFilenameIn:CPAppearanceNameAqua]];
    [self assertTrue:CGSizeEqualToSize(CGSizeMake(10, 10), [[CPImage imageNamed:CPImageNameAddTemplate] size])];
}

- (void)testTheThemeValueForTheDrawingAppearanceWins
{
    [CPTheme setDefaultTheme:[self themeWithAddImages]];

    [self assert:@"dark.png" equals:[self addImageFilenameIn:CPAppearanceNameDarkAqua]];
    [self assert:@"dark.png" equals:[self addImageFilenameIn:CPAppearanceNameVibrantDark]];
    [self assert:@"hc-dark.png" equals:[self addImageFilenameIn:CPAppearanceNameAccessibilityHighContrastDarkAqua]];
    [self assert:@"normal.png" equals:[self addImageFilenameIn:CPAppearanceNameAccessibilityHighContrastAqua]];
}

- (void)testASystemImageFollowsAThemeChange
{
    var image = [CPImage imageNamed:CPImageNameAddTemplate];

    [self assert:@"" equals:[image filename]];

    [CPTheme setDefaultTheme:[self themeWithAddImages]];

    [self assert:@"normal.png" equals:[image filename]];
}

// MARK: Forwarding

- (void)testASystemImageForwardsACSSImage
{
    var cssDictionary = @{ @"background-color": @"red" };

    [CPTheme setDefaultTheme:[self themeWithAddImage:[CPImage imageWithCSSDictionary:cssDictionary size:CGSizeMake(16, 16)]]];

    var image = [CPImage imageNamed:CPImageNameAddTemplate];

    [self assertTrue:[image isCSSBased]];
    [self assertTrue:[image hasCSSDictionary]];
    [self assert:cssDictionary same:[image cssDictionary]];
}

- (void)testASystemImageForwardsTheMethodsOfImageSubclasses
{
    var slices = [[[CPImage alloc] initByReferencingFile:@"left.png" size:CGSizeMake(2, 10)],
                  [[CPImage alloc] initByReferencingFile:@"center.png" size:CGSizeMake(1, 10)],
                  [[CPImage alloc] initByReferencingFile:@"right.png" size:CGSizeMake(2, 10)]];

    [CPTheme setDefaultTheme:[self themeWithAddImage:[[CPThreePartImage alloc] initWithImageSlices:slices isVertical:NO]]];

    var image = [CPImage imageNamed:CPImageNameAddTemplate];

    [self assertTrue:[image isThreePartImage]];
    [self assertTrue:[image respondsToSelector:@selector(imageSlices)]];
    [self assert:slices equals:[image imageSlices]];
}

- (void)testASystemImagePostsItsLoadNotificationWhenTheResolvedImageLoads
{
    var resolvedImage = [[CPImage alloc] initByReferencingFile:@"later.png" size:CGSizeMake(10, 10)],
        image = [CPImage imageNamed:CPImageNameAddTemplate],
        postedObjects = [];

    [CPTheme setDefaultTheme:[self themeWithAddImage:resolvedImage]];

    var observer = [[CPNotificationCenter defaultCenter] addObserverForName:CPImageDidLoadNotification object:image queue:nil usingBlock:function(aNotification)
    {
        postedObjects.push([aNotification object]);
    }];

    [self assert:CPImageLoadStatusInitialized equals:[image loadStatus]];

    [resolvedImage _imageDidLoad];

    [[CPNotificationCenter defaultCenter] removeObserver:observer];

    [self assert:[image] equals:postedObjects];
    [self assert:CPImageLoadStatusCompleted equals:[image loadStatus]];
}

- (void)testASizeSetOnASystemImageReplacesTheResolvedSize
{
    var image = [CPImage imageNamed:CPImageNameAddTemplate];

    [CPTheme setDefaultTheme:[self themeWithAddImages]];
    [image setSize:CGSizeMake(20, 20)];

    [self assertTrue:CGSizeEqualToSize(CGSizeMake(20, 20), [image size])];
}

// MARK: Archiving and cibs

- (void)testASystemImageIsArchivedByName
{
    var image = [CPImage imageNamed:CPImageNameAddTemplate];

    [self assert:image same:[CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:image]]];
}

- (void)testACibResourceWithASystemImageNameGivesTheSystemImage
{
    var coder = [[CPImageNamedTestCoder alloc] init],
        addResource = [_CPCibCustomResource imageResourceWithName:@"CPAddTemplate" size:CGSizeMake(11, 12)],
        checkmarkResource = [_CPCibCustomResource imageResourceWithName:@"CPMenuCheckmark" size:CGSizeMake(11, 12)];

    [self assert:[CPImage imageNamed:CPImageNameAddTemplate] same:[addResource awakeAfterUsingCoder:coder]];
    [self assertNull:[checkmarkResource awakeAfterUsingCoder:coder]];
}

@end
