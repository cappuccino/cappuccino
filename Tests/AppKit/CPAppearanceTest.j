/*
 *  CPAppearanceTest.j
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

@import <AppKit/CPAppearance.j>
@import <AppKit/CPApplication.j>

/*
    The expected matches for appearances of normal contrast are the results of AppKit's
    -[NSAppearance bestMatchFromAppearancesWithNames:] on macOS 27, for the same names and
    lists. AppKit reports a high-contrast appearance under its plain name unless Increase
    Contrast is on, so the high-contrast expectations follow the rule in CPAppearance.j.
*/
@implementation CPAppearanceTest : OJTestCase

- (void)tearDown
{
    [CPAppearance setCurrentAppearance:nil];

    if (typeof CPApp !== "undefined" && CPApp)
        [CPApp setAppearance:nil];
}

- (CPString)match:(CPString)aName in:(CPArray)someNames
{
    return [[CPAppearance appearanceNamed:aName] bestMatchFromAppearancesWithNames:someNames];
}

// MARK: Names

- (void)testNamesUseAppKitStringsWithTheCPPrefix
{
    var expectedNames = [
        [CPAppearanceNameAqua,                                  @"NSAppearanceNameAqua"],
        [CPAppearanceNameDarkAqua,                              @"NSAppearanceNameDarkAqua"],
        [CPAppearanceNameVibrantLight,                          @"NSAppearanceNameVibrantLight"],
        [CPAppearanceNameVibrantDark,                           @"NSAppearanceNameVibrantDark"],
        [CPAppearanceNameLightContent,                          @"NSAppearanceNameLightContent"],
        [CPAppearanceNameAccessibilityHighContrastAqua,         @"NSAppearanceNameAccessibilityAqua"],
        [CPAppearanceNameAccessibilityHighContrastDarkAqua,     @"NSAppearanceNameAccessibilityDarkAqua"],
        [CPAppearanceNameAccessibilityHighContrastVibrantLight, @"NSAppearanceNameAccessibilityVibrantLight"],
        [CPAppearanceNameAccessibilityHighContrastVibrantDark,  @"NSAppearanceNameAccessibilityVibrantDark"]
    ];

    expectedNames.forEach(function(aPair)
    {
        [self assert:aPair[1].replace(/^NS/, "CP") equals:aPair[0]];
    });
}

// MARK: Best match

- (void)testAMatchKeepsLightness
{
    [self assertNull:[self match:CPAppearanceNameAqua in:[CPAppearanceNameDarkAqua]]];
    [self assertNull:[self match:CPAppearanceNameDarkAqua in:[CPAppearanceNameAqua]]];
    [self assertNull:[self match:CPAppearanceNameVibrantDark in:[CPAppearanceNameAqua]]];

    [self assert:CPAppearanceNameAqua equals:[self match:CPAppearanceNameAqua in:[CPAppearanceNameDarkAqua, CPAppearanceNameAqua]]];
    [self assert:CPAppearanceNameDarkAqua equals:[self match:CPAppearanceNameDarkAqua in:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua]]];
}

- (void)testAVibrantAppearanceFallsBackToThePlainAppearance
{
    [self assert:CPAppearanceNameAqua equals:[self match:CPAppearanceNameVibrantLight in:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua]]];
    [self assert:CPAppearanceNameDarkAqua equals:[self match:CPAppearanceNameVibrantDark in:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua]]];

    [self assert:CPAppearanceNameVibrantDark
          equals:[self match:CPAppearanceNameVibrantDark in:[CPAppearanceNameDarkAqua, CPAppearanceNameVibrantDark]]];
}

- (void)testAPlainAppearanceMatchesNoVibrantOrHighContrastName
{
    [self assertNull:[self match:CPAppearanceNameAqua in:[CPAppearanceNameVibrantLight, CPAppearanceNameAccessibilityHighContrastAqua]]];
    [self assertNull:[self match:CPAppearanceNameDarkAqua in:[CPAppearanceNameVibrantDark, CPAppearanceNameAccessibilityHighContrastDarkAqua]]];
    [self assertNull:[self match:CPAppearanceNameVibrantLight in:[CPAppearanceNameAccessibilityHighContrastVibrantLight]]];
}

- (void)testAHighContrastAppearanceGivesUpVibrancyBeforeHighContrast
{
    var highContrastVibrantDark = CPAppearanceNameAccessibilityHighContrastVibrantDark;

    [self assert:CPAppearanceNameAccessibilityHighContrastDarkAqua
          equals:[self match:highContrastVibrantDark in:[CPAppearanceNameVibrantDark, CPAppearanceNameAccessibilityHighContrastDarkAqua]]];
    [self assert:CPAppearanceNameVibrantDark
          equals:[self match:highContrastVibrantDark in:[CPAppearanceNameDarkAqua, CPAppearanceNameVibrantDark]]];
    [self assert:CPAppearanceNameDarkAqua equals:[self match:highContrastVibrantDark in:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua]]];
    [self assertNull:[self match:highContrastVibrantDark in:[CPAppearanceNameAqua, CPAppearanceNameAccessibilityHighContrastAqua]]];
}

- (void)testAHighContrastAppearanceFallsBackToNormalContrast
{
    [self assert:CPAppearanceNameAccessibilityHighContrastAqua
          equals:[self match:CPAppearanceNameAccessibilityHighContrastAqua in:[CPAppearanceNameAqua, CPAppearanceNameAccessibilityHighContrastAqua]]];
    [self assert:CPAppearanceNameAqua equals:[self match:CPAppearanceNameAccessibilityHighContrastAqua in:[CPAppearanceNameAqua]]];
    [self assert:CPAppearanceNameVibrantLight
          equals:[self match:CPAppearanceNameAccessibilityHighContrastVibrantLight in:[CPAppearanceNameAqua, CPAppearanceNameVibrantLight]]];
}

- (void)testLightContentFallsBackToAqua
{
    [self assert:CPAppearanceNameAqua equals:[self match:CPAppearanceNameLightContent in:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua]]];
    [self assertNull:[self match:CPAppearanceNameLightContent in:[CPAppearanceNameDarkAqua]]];
}

- (void)testAnUnknownNameMatchesOnlyItself
{
    var unknownName = @"CPAppearanceTestUnknownAppearance";

    [self assertNull:[self match:unknownName in:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua]]];
    [self assert:unknownName equals:[self match:unknownName in:[CPAppearanceNameAqua, unknownName]]];
}

- (void)testAnEmptyListMatchesNothing
{
    [self assertNull:[self match:CPAppearanceNameAqua in:[]]];
}

// MARK: Drawing appearance

- (void)testTheDrawingAppearanceIsAquaByDefault
{
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameAqua] equals:[CPAppearance currentDrawingAppearance]];
}

- (void)testPerformAsCurrentDrawingAppearanceSetsItForTheBlockOnly
{
    var darkAqua = [CPAppearance appearanceNamed:CPAppearanceNameDarkAqua],
        appearanceInBlock = nil;

    [darkAqua performAsCurrentDrawingAppearance:function()
    {
        appearanceInBlock = [CPAppearance currentDrawingAppearance];
    }];

    [self assert:darkAqua equals:appearanceInBlock];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameAqua] equals:[CPAppearance currentDrawingAppearance]];
}

- (void)testPerformAsCurrentDrawingAppearanceNests
{
    var darkAqua = [CPAppearance appearanceNamed:CPAppearanceNameDarkAqua],
        vibrantDark = [CPAppearance appearanceNamed:CPAppearanceNameVibrantDark],
        appearanceAfterInnerBlock = nil;

    [darkAqua performAsCurrentDrawingAppearance:function()
    {
        [vibrantDark performAsCurrentDrawingAppearance:function() { }];
        appearanceAfterInnerBlock = [CPAppearance currentDrawingAppearance];
    }];

    [self assert:darkAqua equals:appearanceAfterInnerBlock];
}

- (void)testPerformAsCurrentDrawingAppearanceRestoresTheAppearanceAfterAnException
{
    var darkAqua = [CPAppearance appearanceNamed:CPAppearanceNameDarkAqua];

    [self assertThrows:function()
    {
        [darkAqua performAsCurrentDrawingAppearance:function()
        {
            [CPException raise:CPInternalInconsistencyException reason:@"raised inside the block"];
        }];
    }];

    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameAqua] equals:[CPAppearance currentDrawingAppearance]];
}

- (void)testSettingNilReturnsTheCurrentAppearanceToTheApplicationAppearance
{
    var vibrantDark = [CPAppearance appearanceNamed:CPAppearanceNameVibrantDark],
        darkAqua = [CPAppearance appearanceNamed:CPAppearanceNameDarkAqua];

    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    [CPAppearance setCurrentAppearance:vibrantDark];
    [self assert:vibrantDark same:[CPAppearance currentAppearance]];

    [CPAppearance setCurrentAppearance:nil];
    [self assert:[CPApp effectiveAppearance] same:[CPAppearance currentAppearance]];

    [CPApp setAppearance:darkAqua];
    [self assert:darkAqua same:[CPAppearance currentAppearance]];
}

// MARK: Archiving

- (void)testADecodedAppearanceIsTheSharedInstance
{
    var darkAqua = [CPAppearance appearanceNamed:CPAppearanceNameDarkAqua],
        decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:darkAqua]];

    [self assert:darkAqua same:decoded];
}

@end
