/*
 *  CPColorCSSValueTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-11.
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
    A value in a CSS dictionary of a colour or an image is a string, a colour, or an array of
    strings and colours. Each value is converted when it is written, in the current drawing
    appearance, so a dictionary that holds a named colour follows the appearance.
*/

var CPColorCSSValueTestPlaceholder = @"CPColorCSSValueTestPlaceholder";

/*
    A view that counts the writes of its background into the DOM. Node has no DOM, so the view
    turns the DOM on while CPView applies its background again after a change of appearance;
    that path writes nothing else.
*/
@implementation CPColorCSSValueTestView : CPView
{
    int     writeCount;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
        writeCount = 0;

    return self;
}

- (void)_writeBackgroundColor
{
    writeCount++;
}

- (void)_effectiveAppearanceDidChange
{
    var savedDOMAvailable = CPDOMAvailable;

    CPDOMAvailable = YES;

    try
    {
        [super _effectiveAppearanceDidChange];
    }
    finally
    {
        CPDOMAvailable = savedDOMAvailable;
    }
}

@end

/*
    A themed class whose theme gives a CSS colour with a placeholder of the dynamic set.
*/
@implementation CPColorCSSValueTestThemedView : CPView

+ (CPString)defaultThemeClass
{
    return @"css-value-test-view";
}

+ (CPDictionary)themeAttributes
{
    return @{ @"test-background": [CPNull null] };
}

@end

@implementation CPColorCSSValueTest : OJTestCase
{
    CPTheme     _previousTheme;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    _previousTheme = [CPTheme defaultTheme];
    [CPTheme setDefaultTheme:[self themeWithFillColor]];
}

- (void)tearDown
{
    [CPTheme setDefaultTheme:_previousTheme];
    [CPApp setAppearance:nil];
    [CPAppearance setCurrentAppearance:nil];
}

/*
    A theme that gives the theme colour cssValueTestFillColor red for every appearance and blue
    for DarkAqua.
*/
- (CPTheme)themeWithFillColor
{
    var theme = [[CPTheme alloc] initWithName:@"CPColorCSSValueTestTheme"],
        template = [CPColor colorWithWhite:0.0 alpha:1.0];

    [template setValue:@{ @"cssValueTestFillColor": [CPColor redColor] } forThemeAttribute:@"theme-colors"];
    [template setValue:@{ @"cssValueTestFillColor": [CPColor blueColor] } forThemeAttribute:@"theme-colors" inState:CPThemeStateAppearanceDarkAqua];
    [theme takeThemeFromObject:template];

    return theme;
}

- (CPColor)fillColor
{
    return [CPColor colorWithCatalogName:@"Theme" colorName:@"cssValueTestFillColor"];
}

- (CPAppearance)appearance:(CPString)aName
{
    return [CPAppearance appearanceNamed:aName];
}

/*
    Returns the result of aFunction, called with the appearance named aName as the current
    drawing appearance.
*/
- (id)in:(CPString)aName perform:(Function)aFunction
{
    var result = nil;

    [[self appearance:aName] performAsCurrentDrawingAppearance:function()
    {
        result = aFunction();
    }];

    return result;
}

- (CPColor)appearanceDependentCSSColor
{
    return [CPColor colorWithCSSDictionary:@{
                                             @"background-color": [self fillColor],
                                             @"border": @[@"1px solid ", [self fillColor]]
                                             }];
}

- (CPColorCSSValueTestView)newView
{
    return [[CPColorCSSValueTestView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
}

// MARK: Conversion

- (void)testAStringConvertsToItself
{
    [self assert:@"1px solid rgb(1, 2, 3)" equals:_CPCSSValueString(@"1px solid rgb(1, 2, 3)")];
}

- (void)testAColorConvertsToItsCSSStringInTheCurrentAppearance
{
    var fillColor = [self fillColor];

    [self assert:[[CPColor redColor] cssString] equals:[self in:CPAppearanceNameAqua perform:function() { return _CPCSSValueString(fillColor); }]];
    [self assert:[[CPColor blueColor] cssString] equals:[self in:CPAppearanceNameDarkAqua perform:function() { return _CPCSSValueString(fillColor); }]];
    [self assert:[[CPColor greenColor] cssString] equals:_CPCSSValueString([CPColor greenColor])];
}

- (void)testAnArrayConvertsToItsMembersJoined
{
    var value = @[@"0 0 0 3px ", [self fillColor], @", inset ", @[@"0 1px ", [CPColor greenColor]]],
        text = [self in:CPAppearanceNameDarkAqua perform:function() { return _CPCSSValueString(value); }];

    [self assert:@"0 0 0 3px " + [[CPColor blueColor] cssString] + @", inset 0 1px " + [[CPColor greenColor] cssString] equals:text];
}

- (void)testANumberConvertsToItsText
{
    [self assert:@"300" equals:_CPCSSValueString(300)];
    [self assert:@"0.5" equals:_CPCSSValueString(0.5)];
}

- (void)testAnotherKindRaises
{
    [self assertThrows:function() { _CPCSSValueString(@{ @"a": @"b" }); }];
    [self assertThrows:function() { _CPCSSValueString([CPNull null]); }];
    [self assertThrows:function() { _CPCSSValueString(nil); }];
    [self assertThrows:function() { _CPCSSValueString(@[@"1px solid ", [CPNull null]]); }];
}

- (void)testANamedColorWithAnAlphaConvertsWithThatAlpha
{
    var fillColor = [[self fillColor] colorWithAlphaComponent:0.5];

    [self assert:[[[CPColor redColor] colorWithAlphaComponent:0.5] cssString] equals:[self in:CPAppearanceNameAqua perform:function() { return _CPCSSValueString(fillColor); }]];
    [self assert:[[[CPColor blueColor] colorWithAlphaComponent:0.5] cssString] equals:[self in:CPAppearanceNameDarkAqua perform:function() { return _CPCSSValueString(fillColor); }]];
}

- (void)testAnObjectIsAppearanceDependentWhenADictionaryHoldsAColor
{
    [self assertTrue:_CPCSSObjectIsAppearanceDependent([self appearanceDependentCSSColor])];
    [self assertTrue:_CPCSSObjectIsAppearanceDependent([CPColor colorWithCSSDictionary:@{} beforeDictionary:nil afterDictionary:@{ @"border": @[@"1px solid ", [self fillColor]] }])];
    [self assertFalse:_CPCSSObjectIsAppearanceDependent([CPColor colorWithCSSDictionary:@{ @"background-color": @"rgb(1, 2, 3)" }])];
}

/*
    Node has no DOM, so the test gives the method an element, a style node and a document that
    record what it writes.
*/
- (void)testTheMainAndBeforeValuesConvertIntoTheElementAndTheStyleText
{
    var view = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 10.0)],
        cssColor = [CPColor colorWithCSSDictionary:@{ @"border": @[@"1px solid ", [self fillColor]] }
                                  beforeDictionary:@{ @"background-color": [self fillColor] }
                                   afterDictionary:nil],
        element = { style: {} },
        styleNode = { firstChild: { data: "" }, replaceChild: function(aNewChild, anOldChild) { this.firstChild = aNewChild; } },
        previousState = @[],
        hadDocument = global.hasOwnProperty("document"),
        savedDocument = global.document;

    global.document = { createTextNode: function(aText) { return { data: aText }; } };

    try
    {
        [self in:CPAppearanceNameDarkAqua perform:function()
        {
            [cssColor applyCSSColorForView:view onDOMElement:element styleNode:styleNode previousState:@ref(previousState)];
        }];
    }
    finally
    {
        if (hadDocument)
            global.document = savedDocument;
        else
            delete global.document;
    }

    var blue = [[CPColor blueColor] cssString];

    [self assert:@"1px solid " + blue equals:element.style["border"]];
    [self assertTrue:styleNode.firstChild.data.indexOf(@"::before { background-color: " + blue + @"; }") !== -1 message:styleNode.firstChild.data];
}

// MARK: Comparison in the background setter

- (void)testAnAppearanceChangeRewritesAnAppearanceDependentCSSBackground
{
    var view = [self newView],
        cssColor = [self appearanceDependentCSSColor];

    [view setAppearance:[self appearance:CPAppearanceNameAqua]];
    [view setBackgroundColor:cssColor];

    [self assertTrue:view._backgroundColorCSSText.indexOf([[CPColor redColor] cssString]) !== -1 message:view._backgroundColorCSSText];

    [view setAppearance:[self appearance:CPAppearanceNameDarkAqua]];

    [self assert:cssColor same:view._backgroundColorResolved message:@"the resolved colour is the same object"];
    [self assert:1 equals:view.writeCount];
    [self assertTrue:view._backgroundColorCSSText.indexOf([[CPColor blueColor] cssString]) !== -1 message:view._backgroundColorCSSText];
}

/*
    VibrantLight finds no value of its own and takes the value for every appearance, as Aqua
    does, so the CSS is the same.
*/
- (void)testNoRewriteWhenTheNewAppearanceGivesTheSameCSS
{
    var view = [self newView];

    [view setAppearance:[self appearance:CPAppearanceNameAqua]];
    [view setBackgroundColor:[self appearanceDependentCSSColor]];
    [view setAppearance:[self appearance:CPAppearanceNameVibrantLight]];

    [self assert:0 equals:view.writeCount];
}

- (void)testASecondSetWithTheSameColorAndAppearanceDoesNotWriteAgain
{
    var view = [self newView],
        cssColor = [self appearanceDependentCSSColor],
        savedDOMAvailable = CPDOMAvailable;

    [view setAppearance:[self appearance:CPAppearanceNameDarkAqua]];

    CPDOMAvailable = YES;

    try
    {
        [view setBackgroundColor:cssColor];
        [view setBackgroundColor:cssColor];
    }
    finally
    {
        CPDOMAvailable = savedDOMAvailable;
    }

    [self assert:1 equals:view.writeCount];
}

- (void)testACSSColorWithStringsOnlyKeepsTheComparisonOfTheSameObject
{
    var view = [self newView];

    [view setAppearance:[self appearance:CPAppearanceNameAqua]];
    [view setBackgroundColor:[CPColor colorWithCSSDictionary:@{ @"background-color": @"rgb(1, 2, 3)" }]];
    [view setAppearance:[self appearance:CPAppearanceNameDarkAqua]];

    [self assertNull:view._backgroundColorCSSText];
    [self assert:0 equals:view.writeCount];
}

// MARK: Archiving

- (void)testAnArchiveRoundTripKeepsColorsAndArraysInADictionary
{
    var fillColor = [self fillColor],
        cssColor = [CPColor colorWithCSSDictionary:@{ @"background-color": fillColor, @"border": @[@"1px solid ", fillColor] }
                                  beforeDictionary:@{ @"color": fillColor }
                                   afterDictionary:nil],
        decodedColor = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:cssColor]],
        border = [[decodedColor cssDictionary] objectForKey:@"border"];

    [self assert:fillColor same:[[decodedColor cssDictionary] objectForKey:@"background-color"]];
    [self assert:2 equals:[border count]];
    [self assert:@"1px solid " equals:border[0]];
    [self assert:fillColor same:border[1]];
    [self assert:fillColor same:[[decodedColor cssBeforeDictionary] objectForKey:@"color"]];
}

// MARK: Theme load

- (void)testTheResourcesPathReplacesStringsAndLeavesColorsAlone
{
    var fillColor = [self fillColor],
        theme = [[CPTheme alloc] initWithName:@"CPColorCSSValueTestPaths"],
        dictionary = @{
                       @"background-image": @"url(%%packed.png)",
                       @"mask-image": @[@"url(%%mask.svg) ", fillColor],
                       @"color": fillColor
                       };

    [theme _fixPathInCSSDictionary:dictionary withPathToResources:@"Resources/"];

    var maskImage = [dictionary objectForKey:@"mask-image"];

    [self assert:@"url(Resources/packed.png)" equals:[dictionary objectForKey:@"background-image"]];
    [self assert:@"url(Resources/mask.svg) " equals:maskImage[0]];
    [self assert:fillColor same:maskImage[1]];
    [self assert:fillColor same:[dictionary objectForKey:@"color"]];
}

- (void)testAPlaceholderTakesAStringFromAnApplicationSet
{
    var fillColor = [self fillColor],
        theme = [[CPTheme alloc] initWithName:@"CPColorCSSValueTestPlaceholders"],
        dictionary = @{ @"background-color": CPColorCSSValueTestPlaceholder, @"color": fillColor };

    [theme _applyDynamicSet:[CPDictionary dictionaryWithObject:@"rgb(1, 2, 3)" forKey:CPColorCSSValueTestPlaceholder] toCSSDictionary:dictionary];

    [self assert:@"rgb(1, 2, 3)" equals:[dictionary objectForKey:@"background-color"]];
    [self assert:fillColor same:[dictionary objectForKey:@"color"]];
}

- (void)testTheDefaultDynamicSetOfAThemeGivesANamedColor
{
    var fillColor = [self fillColor],
        theme = [[CPTheme alloc] initWithName:@"CPColorCSSValueTestDynamicSet"],
        template = [[CPColorCSSValueTestThemedView alloc] initWithFrame:CGRectMakeZero()],
        themedClass = [CPColorCSSValueTestThemedView class];

    [template setValue:[CPColor colorWithCSSDictionary:@{ @"background-color": CPColorCSSValueTestPlaceholder }] forThemeAttribute:@"test-background"];
    [template setValue:[CPDictionary dictionaryWithObject:fillColor forKey:CPColorCSSValueTestPlaceholder] forThemeAttribute:@"dynamic-set"];
    [theme takeThemeFromObject:template];

    [theme applyDynamicSet:[theme valueForAttributeWithName:@"dynamic-set" forClass:themedClass]];

    [self assert:fillColor same:[[[theme valueForAttributeWithName:@"test-background" forClass:themedClass] cssDictionary] objectForKey:@"background-color"]];
}

@end
