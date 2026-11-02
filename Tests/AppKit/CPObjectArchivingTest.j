/*
 *  CPObjectArchivingTest.j
 *  AppKit
 *
 *  Created by David Richardson on 31/10/2026.
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

@import <AppKit/AppKit.j>

/*
    Views hold and share objects that are not views, and those objects are archived
    with them. An object that is archived and read back must keep the properties that
    an application reads. DropInArchiveTest.j and CPViewDecodedBehaviorTest.j cover
    the views.
*/

@implementation CPObjectArchivingTest : OJTestCase

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

- (id)archived:(id)anObject
{
    return [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:anObject]];
}

// MARK: Foundation collections and values

- (void)testAnArrayKeepsItsObjects
{
    [self assert:[@"One", 2, YES] equals:[self archived:[@"One", 2, YES]]];
}

- (void)testADictionaryKeepsItsEntries
{
    var dictionary = @{ @"one": @"first", @"two": 2 };

    [self assert:dictionary equals:[self archived:dictionary]];
}

- (void)testASetKeepsItsObjects
{
    var set = [CPSet setWithArray:[@"One", @"Two"]];

    [self assert:set equals:[self archived:set]];
}

- (void)testAnIndexSetKeepsItsIndexes
{
    var indexes = [CPMutableIndexSet indexSetWithIndexesInRange:CPMakeRange(2, 3)];

    [indexes addIndex:9];

    [self assert:indexes equals:[self archived:indexes]];
}

- (void)testAnIndexPathKeepsItsIndexes
{
    var indexPath = [CPIndexPath indexPathWithIndexes:[1, 2, 3] length:3];

    [self assert:indexPath equals:[self archived:indexPath]];
}

- (void)testADateKeepsItsTime
{
    var date = [CPDate dateWithTimeIntervalSince1970:1000.0];

    [self assert:1000.0 equals:[[self archived:date] timeIntervalSince1970]];
}

- (void)testNullStaysTheSingleton
{
    [self assert:[CPNull null] equals:[self archived:[CPNull null]]];
}

- (void)testADecimalNumberKeepsItsValue
{
    var number = [CPDecimalNumber decimalNumberWithString:@"12.5"];

    [self assert:[number stringValue] equals:[[self archived:number] stringValue]];
}

- (void)testAnAttributedStringKeepsItsText
{
    var string = [[CPAttributedString alloc] initWithString:@"Text" attributes:@{ @"key": @"value" }];

    [self assert:string equals:[self archived:string]];
}

- (void)testASortDescriptorKeepsItsDefinition
{
    var descriptor = [CPSortDescriptor sortDescriptorWithKey:@"name" ascending:NO selector:@selector(compare:)],
        decoded = [self archived:descriptor];

    [self assert:@"name" equals:[decoded key]];
    [self assertFalse:[decoded ascending]];
    [self assert:@selector(compare:) equals:[decoded selector]];
}

- (void)testACharacterSetKeepsItsMembers
{
    var decoded = [self archived:[CPCharacterSet characterSetWithCharactersInString:@"ab"]];

    [self assertTrue:[decoded characterIsMember:@"a"]];
    [self assertFalse:[decoded characterIsMember:@"c"]];
}

- (void)testAnErrorKeepsItsDefinition
{
    var error = [CPError errorWithDomain:@"Domain" code:7 userInfo:@{ @"key": @"value" }],
        decoded = [self archived:error];

    [self assert:@"Domain" equals:[decoded domain]];
    [self assert:7 equals:[decoded code]];
    [self assert:@"value" equals:[[decoded userInfo] objectForKey:@"key"]];
}

- (void)testAnExceptionKeepsItsDefinition
{
    var exception = [CPException exceptionWithName:@"Name" reason:@"Reason" userInfo:nil],
        decoded = [self archived:exception];

    [self assert:@"Name" equals:[decoded name]];
    [self assert:@"Reason" equals:[decoded reason]];
}

- (void)testALocaleKeepsItsIdentifier
{
    var locale = [[CPLocale alloc] initWithLocaleIdentifier:@"fr_FR"];

    [self assert:@"fr_FR" equals:[[self archived:locale] localeIdentifier]];
}

- (void)testANumberFormatterKeepsItsStyle
{
    var formatter = [[CPNumberFormatter alloc] init];

    [formatter setNumberStyle:CPNumberFormatterDecimalStyle];

    [self assert:CPNumberFormatterDecimalStyle equals:[[self archived:formatter] numberStyle]];
}

- (void)testADateFormatterKeepsItsFormat
{
    var formatter = [[CPDateFormatter alloc] init];

    [formatter setDateFormat:@"yyyy-MM-dd"];

    [self assert:@"yyyy-MM-dd" equals:[[self archived:formatter] dateFormat]];
}

- (void)testAComparisonPredicateStillEvaluates
{
    var decoded = [self archived:[CPPredicate predicateWithFormat:@"self BEGINSWITH 'a'"]];

    [self assertTrue:[decoded evaluateWithObject:@"apple"]];
    [self assertFalse:[decoded evaluateWithObject:@"pear"]];
}

- (void)testACompoundPredicateStillEvaluates
{
    var decoded = [self archived:[CPPredicate predicateWithFormat:@"self BEGINSWITH 'a' AND self ENDSWITH 'e'"]];

    [self assertTrue:[decoded evaluateWithObject:@"apple"]];
    [self assertFalse:[decoded evaluateWithObject:@"apricot"]];
}

// MARK: AppKit values

- (void)testAColorKeepsItsComponents
{
    var color = [CPColor colorWithRed:0.25 green:0.5 blue:0.75 alpha:0.5];

    [self assert:[color cssString] equals:[[self archived:color] cssString]];
}

- (void)testANamedFontKeepsItsDefinition
{
    var font = [CPFont boldFontWithName:@"Courier" size:21.0],
        decoded = [self archived:font];

    [self assert:[font cssString] equals:[decoded cssString]];
    [self assertTrue:[decoded isBold]];
}

- (void)testASystemFontStaysASystemFont
{
    var decoded = [self archived:[CPFont systemFontOfSize:15.0]];

    [self assertTrue:[decoded isSystem]];
    [self assert:15.0 equals:[decoded size]];
}

- (void)testAnImageKeepsItsDefinition
{
    var image = [[CPImage alloc] initWithContentsOfFile:@"image.png" size:CGSizeMake(16.0, 32.0)],
        decoded = [self archived:image];

    [self assert:@"image.png" equals:[decoded filename]];
    [self assertTrue:CGSizeEqualToSize(CGSizeMake(16.0, 32.0), [decoded size])];
}

- (void)testAShadowKeepsItsDefinition
{
    var shadow = [[CPShadow alloc] init];

    [shadow setShadowOffset:CGSizeMake(2.0, 3.0)];
    [shadow setShadowBlurRadius:4.0];
    [shadow setShadowColor:[CPColor redColor]];

    var decoded = [self archived:shadow];

    [self assertTrue:CGSizeEqualToSize(CGSizeMake(2.0, 3.0), [decoded shadowOffset])];
    [self assert:4.0 equals:[decoded shadowBlurRadius]];
    [self assert:[[CPColor redColor] cssString] equals:[[decoded shadowColor] cssString]];
}

- (void)testANewShadowKeepsItsDefaults
{
    var decoded = [self archived:[[CPShadow alloc] init]];

    [self assertTrue:CGSizeEqualToSize(CGSizeMakeZero(), [decoded shadowOffset])];
    [self assert:0.0 equals:[decoded shadowBlurRadius]];
    [self assert:1.0 / 3.0 equals:[[decoded shadowColor] alphaComponent]];
}

- (void)testAParagraphStyleKeepsItsAlignment
{
    var style = [[CPMutableParagraphStyle alloc] init];

    [style setAlignment:CPCenterTextAlignment];

    [self assert:CPCenterTextAlignment equals:[[self archived:style] alignment]];
}

- (void)testAnAppearanceKeepsItsName
{
    var appearance = [CPAppearance appearanceNamed:CPAppearanceNameVibrantDark];

    [self assert:CPAppearanceNameVibrantDark equals:[[self archived:appearance] name]];
}

// MARK: Objects that belong to views

- (void)testAMenuKeepsItsItems
{
    var menu = [[CPMenu alloc] initWithTitle:@"Menu"],
        item = [[CPMenuItem alloc] initWithTitle:@"Item" action:@selector(performAction:) keyEquivalent:@"i"],
        submenu = [[CPMenu alloc] initWithTitle:@""];

    [item setTag:7];
    [item setState:CPOnState];
    [item setKeyEquivalentModifierMask:CPShiftKeyMask];
    [menu addItem:item];
    [menu addItem:[CPMenuItem separatorItem]];
    [menu setSubmenu:submenu forItem:[menu addItemWithTitle:@"Parent" action:nil keyEquivalent:@""]];

    var decoded = [self archived:menu],
        decodedItem = [decoded itemAtIndex:0];

    [self assert:@"Menu" equals:[decoded title]];
    [self assert:3 equals:[decoded numberOfItems]];
    [self assert:@"Item" equals:[decodedItem title]];
    [self assert:@selector(performAction:) equals:[decodedItem action]];
    [self assert:@"i" equals:[decodedItem keyEquivalent]];
    [self assert:CPShiftKeyMask equals:[decodedItem keyEquivalentModifierMask]];
    [self assert:7 equals:[decodedItem tag]];
    [self assert:CPOnState equals:[decodedItem state]];
    [self assert:decoded equals:[decodedItem menu]];
    [self assertTrue:[[decoded itemAtIndex:1] isSeparatorItem]];
    [self assert:@"Parent" equals:[[[decoded itemAtIndex:2] submenu] title]];
    [self assert:decoded equals:[[[decoded itemAtIndex:2] submenu] supermenu]];
}

- (void)testATableColumnKeepsItsDefinition
{
    var column = [[CPTableColumn alloc] initWithIdentifier:@"Column"];

    [column setWidth:120.0];
    [column setMinWidth:50.0];
    [column setMaxWidth:300.0];
    [column setEditable:YES];
    [column setHidden:YES];
    [[column headerView] setStringValue:@"Title"];
    [column setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];

    var decoded = [self archived:column];

    [self assert:@"Column" equals:[decoded identifier]];
    [self assert:120.0 equals:[decoded width]];
    [self assert:50.0 equals:[decoded minWidth]];
    [self assert:300.0 equals:[decoded maxWidth]];
    [self assertTrue:[decoded isEditable]];
    [self assertTrue:[decoded isHidden]];
    [self assert:@"Title" equals:[[decoded headerView] stringValue]];
    [self assert:@"name" equals:[[decoded sortDescriptorPrototype] key]];
}

- (void)testATabViewItemKeepsItsDefinition
{
    var item = [[CPTabViewItem alloc] initWithIdentifier:@"identifier"];

    [item setLabel:@"Label"];
    [item setView:[[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 20.0)]];

    var decoded = [self archived:item];

    [self assert:@"identifier" equals:[decoded identifier]];
    [self assert:@"Label" equals:[decoded label]];
    [self assertNotNull:[decoded view]];
}

- (void)testAnObjectControllerKeepsItsContent
{
    var controller = [[CPObjectController alloc] initWithContent:@"Content"];

    [controller setEditable:NO];

    var decoded = [self archived:controller];

    [self assert:@"Content" equals:[decoded content]];
    [self assertFalse:[decoded isEditable]];
}

- (void)testAnArrayControllerKeepsItsConfiguration
{
    var controller = [[CPArrayController alloc] initWithContent:[@"One", @"Two"]];

    [controller setAvoidsEmptySelection:NO];
    [controller setPreservesSelection:NO];

    var decoded = [self archived:controller];

    [self assertFalse:[decoded avoidsEmptySelection]];
    [self assertFalse:[decoded preservesSelection]];
}

@end
