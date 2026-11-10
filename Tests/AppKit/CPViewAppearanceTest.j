/*
 *  CPViewAppearanceTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-10.
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
    The views that received the public hook, in the order of the calls.
*/
var CPViewAppearanceTestHookCalls = [];

var CPViewAppearanceTestNames = [
        CPAppearanceNameAqua,
        CPAppearanceNameDarkAqua,
        CPAppearanceNameLightContent,
        CPAppearanceNameVibrantLight,
        CPAppearanceNameVibrantDark,
        CPAppearanceNameAccessibilityHighContrastAqua,
        CPAppearanceNameAccessibilityHighContrastDarkAqua,
        CPAppearanceNameAccessibilityHighContrastVibrantLight,
        CPAppearanceNameAccessibilityHighContrastVibrantDark
    ];

/*
    Returns the theme state strings that the archive aData holds for its views.
*/
function CPViewAppearanceTestArchivedThemeStates(aData)
{
    var objects = [[aData plistObject] objectForKey:@"$objects"],
        states = [];

    for (var i = 0, count = [objects count]; i < count; i++)
    {
        var object = objects[i];

        if ([object isKindOfClass:[CPDictionary class]] && [object containsKey:@"CPViewThemeStateKey"])
            states.push(objects[[[object objectForKey:@"CPViewThemeStateKey"] objectForKey:@"CP$UID"]]);
    }

    return states;
}

/*
    Returns an archive of aView whose theme state string is aStateString, as an archive
    written before the archive of a theme state left the appearance states out.
*/
function CPViewAppearanceTestArchiveWithThemeState(aView, aStateString)
{
    var plistObject = [[CPKeyedArchiver archivedDataWithRootObject:aView] plistObject],
        objects = [plistObject objectForKey:@"$objects"];

    for (var i = 0, count = [objects count]; i < count; i++)
    {
        var object = objects[i];

        if ([object isKindOfClass:[CPDictionary class]] && [object containsKey:@"CPViewThemeStateKey"])
            objects[[[object objectForKey:@"CPViewThemeStateKey"] objectForKey:@"CP$UID"]] = aStateString;
    }

    return [CPData dataWithPlistObject:plistObject];
}

/*
    A view that records the hook calls, the appearance walks, the background setter calls and
    the drawing appearance of each layout and drawing method.
*/
@implementation CPViewAppearanceTestView : CPView
{
    int             hookCount;
    CPAppearance    appearanceInHook;
    CPAppearance    drawingAppearanceInHook;
    int             recomputeCount;
    int             layoutCount;
    int             backgroundSetterCount;
    JSObject        drawingAppearances;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        hookCount = 0;
        recomputeCount = 0;
        layoutCount = 0;
        backgroundSetterCount = 0;
        drawingAppearances = {};
    }

    return self;
}

- (void)viewDidChangeEffectiveAppearance
{
    hookCount++;
    appearanceInHook = [self effectiveAppearance];
    drawingAppearanceInHook = [CPAppearance currentDrawingAppearance];
    CPViewAppearanceTestHookCalls.push(self);
}

- (void)_recomputeAppearanceWithSuperviewEffectiveAppearance:(CPAppearance)anAppearance
{
    recomputeCount++;
    [super _recomputeAppearanceWithSuperviewEffectiveAppearance:anAppearance];
}

- (void)setBackgroundColor:(CPColor)aColor
{
    backgroundSetterCount++;
    [super setBackgroundColor:aColor];
}

- (void)viewWillLayout
{
    drawingAppearances["viewWillLayout"] = [CPAppearance currentDrawingAppearance];
}

- (void)layoutSubviews
{
    layoutCount++;
    drawingAppearances["layoutSubviews"] = [CPAppearance currentDrawingAppearance];
}

- (void)viewDidLayout
{
    [super viewDidLayout];
    drawingAppearances["viewDidLayout"] = [CPAppearance currentDrawingAppearance];
}

- (void)viewWillDraw
{
    drawingAppearances["viewWillDraw"] = [CPAppearance currentDrawingAppearance];
}

/*
    A view without drawRect: never needs display, so the display checks need this override.
*/
- (void)drawRect:(CGRect)aRect
{
}

@end

@implementation CPViewAppearanceTestRaisingView : CPView

- (void)layoutSubviews
{
    [CPException raise:CPInternalInconsistencyException reason:@"raised in layoutSubviews"];
}

@end

/*
    A subclass that overrides viewDidLayout without a call to super.
*/
@implementation CPViewAppearanceTestNoSuperLayoutView : CPView

- (void)viewDidLayout
{
}

@end

@implementation CPViewAppearanceTestTextField : CPTextField
{
    CPAppearance    layoutAppearance;
}

- (void)layoutSubviews
{
    layoutAppearance = [CPAppearance currentDrawingAppearance];
    [super layoutSubviews];
}

@end

/*
    A dynamic colour whose value comes from a function of the appearance name.
*/
@implementation CPViewAppearanceTestColor : _CPDynamicColor
{
    Function    _valueFunction;
}

- (id)initWithValueFunction:(Function)aFunction
{
    if (self = [super _initDynamicColor])
        _valueFunction = aFunction;

    return self;
}

- (CPColor)_valueInAppearance:(CPAppearance)anAppearance
{
    return _valueFunction([anAppearance name]);
}

- (_CPDynamicColor)_dynamicCopy
{
    return [[CPViewAppearanceTestColor alloc] initWithValueFunction:_valueFunction];
}

@end

@implementation CPViewAppearanceTest : OJTestCase
{
    CPWindow    window;
    CPArray     observedValues;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 300.0) styleMask:CPTitledWindowMask];
    observedValues = [];
    CPViewAppearanceTestHookCalls = [];
}

- (void)tearDown
{
    [CPApp setAppearance:nil];
    [CPAppearance setCurrentAppearance:nil];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)aChange context:(id)aContext
{
    [observedValues addObject:[aChange objectForKey:CPKeyValueChangeNewKey]];
}

- (CPAppearance)appearance:(CPString)aName
{
    return [CPAppearance appearanceNamed:aName];
}

- (CPViewAppearanceTestView)newView
{
    return [[CPViewAppearanceTestView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
}

/*
    Returns YES when aView holds the state of anAppearance and no other appearance state.
*/
- (BOOL)view:(CPView)aView holdsOnlyTheStateOf:(CPAppearance)anAppearance
{
    var state = _CPThemeStateForAppearanceName([anAppearance name]);

    return [aView hasThemeState:state] && String([aView themeState].without(state)).indexOf("appearance-") === -1;
}

/*
    Returns a dynamic colour that gives a new colour at each resolution: a dark grey in
    VibrantDark, a light grey in every other appearance.
*/
- (CPViewAppearanceTestColor)greyColor
{
    return [[CPViewAppearanceTestColor alloc] initWithValueFunction:function(aName)
    {
        return aName === CPAppearanceNameVibrantDark ? [CPColor colorWithWhite:0.1 alpha:1.0] : [CPColor colorWithWhite:0.9 alpha:1.0];
    }];
}

// MARK: Chain and states

- (void)testALoneViewTakesTheApplicationAppearanceAndHoldsOnlyTheNormalState
{
    var view = [self newView];

    [self assert:[CPApp effectiveAppearance] same:[view effectiveAppearance]];
    [self assert:String(CPThemeStateNormal) equals:String([view themeState])];
}

- (void)testAViewThatEntersAnAquaHierarchyHoldsTheAquaState
{
    var view = [self newView];

    [self assert:CPAppearanceNameAqua equals:[[window effectiveAppearance] name]];

    [[window contentView] addSubview:view];

    [self assert:String(CPThemeStateAppearanceAqua) equals:String([view themeState])];
}

- (void)testEachAppearanceGivesItsOwnStateAndNoOther
{
    for (var i = 0; i < CPViewAppearanceTestNames.length; i++)
    {
        var appearance = [self appearance:CPViewAppearanceTestNames[i]],
            view = [self newView];

        [view setAppearance:appearance];
        [[window contentView] addSubview:view];

        [self assertTrue:[self view:view holdsOnlyTheStateOf:appearance] message:CPViewAppearanceTestNames[i] + @" gives " + String([view themeState])];
    }
}

- (void)testAViewWithADecodedAppearanceHoldsTheStateOfItsName
{
    var vibrantDark = [self appearance:CPAppearanceNameVibrantDark],
        original = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];

    [original setAppearance:vibrantDark];

    var decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:original]];

    [self assert:vibrantDark same:[decoded appearance]];

    [[window contentView] addSubview:decoded];

    [self assertTrue:[self view:decoded holdsOnlyTheStateOf:vibrantDark]];
}

- (void)testAViewFromAnOlderArchiveTakesTheStateOfItsHierarchy
{
    var data = CPViewAppearanceTestArchiveWithThemeState([[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)], String(CPThemeStateAppearanceVibrantDark)),
        decoded = [CPKeyedUnarchiver unarchiveObjectWithData:data];

    [self assertTrue:[decoded hasThemeState:CPThemeStateAppearanceVibrantDark] message:@"The archive holds the old state"];

    [[window contentView] addSubview:decoded];

    [self assertTrue:[self view:decoded holdsOnlyTheStateOf:[self appearance:CPAppearanceNameAqua]]];
}

// MARK: Change semantics

- (void)testSetAppearanceCallsTheHookAtOnceParentBeforeChildren
{
    var parent = [self newView],
        child = [self newView],
        grandchild = [self newView];

    [child addSubview:grandchild];
    [parent addSubview:child];
    [[window contentView] addSubview:parent];
    CPViewAppearanceTestHookCalls = [];

    [parent setAppearance:[self appearance:CPAppearanceNameDarkAqua]];

    [self assert:[parent, child, grandchild] equals:CPViewAppearanceTestHookCalls];
}

- (void)testAViewWhoseOwnAppearanceEqualsTheNewOneReceivesNoCall
{
    var parent = [self newView],
        child = [self newView],
        grandchild = [self newView];

    [child setAppearance:[self appearance:CPAppearanceNameDarkAqua]];
    [child addSubview:grandchild];
    [parent addSubview:child];
    [[window contentView] addSubview:parent];
    CPViewAppearanceTestHookCalls = [];

    [parent setAppearance:[self appearance:CPAppearanceNameDarkAqua]];

    [self assert:[parent] equals:CPViewAppearanceTestHookCalls];
}

- (void)testANewViewReceivesACallOnlyWhenItEntersAnotherAppearance
{
    var view = [self newView],
        darkParent = [self newView],
        darkChild = [self newView];

    [[window contentView] addSubview:view];
    [self assert:0 equals:view.hookCount];

    [darkParent setAppearance:[self appearance:CPAppearanceNameDarkAqua]];
    [[window contentView] addSubview:darkParent];

    [darkParent addSubview:darkChild];
    [self assert:1 equals:darkChild.hookCount];
}

- (void)testInsideTheHookTheNewAppearanceIsEffectiveAndCurrent
{
    var parent = [self newView],
        child = [self newView],
        vibrantDark = [self appearance:CPAppearanceNameVibrantDark];

    [parent addSubview:child];
    [[window contentView] addSubview:parent];

    [parent setAppearance:vibrantDark];

    [self assert:vibrantDark same:parent.appearanceInHook];
    [self assert:vibrantDark same:parent.drawingAppearanceInHook];
    [self assert:vibrantDark same:child.appearanceInHook];
    [self assert:vibrantDark same:child.drawingAppearanceInHook];
    [self assert:[CPApp effectiveAppearance] same:[CPAppearance currentDrawingAppearance]];
}

- (void)testAnObserverOfTheEffectiveAppearanceReceivesTheNewValue
{
    var parent = [self newView],
        child = [self newView],
        darkAqua = [self appearance:CPAppearanceNameDarkAqua];

    [parent addSubview:child];
    [[window contentView] addSubview:parent];

    [child addObserver:self forKeyPath:@"effectiveAppearance" options:CPKeyValueObservingOptionNew context:nil];

    try
    {
        [parent setAppearance:darkAqua];
    }
    finally
    {
        [child removeObserver:self forKeyPath:@"effectiveAppearance"];
    }

    [self assert:[darkAqua] equals:observedValues];
}

/*
    The parent's record is right by chance when it enters the window, and its child's is not.
    A walk that stopped at an unchanged view would leave the child in DarkAqua.
*/
- (void)testAWalkDoesNotStopAtAnUnchangedView
{
    var parent = [self newView],
        child = [self newView],
        aqua = [self appearance:CPAppearanceNameAqua];

    [[window contentView] addSubview:parent];
    [parent removeFromSuperview];

    [CPApp setAppearance:[self appearance:CPAppearanceNameDarkAqua]];
    [parent addSubview:child];
    [self assertTrue:[self view:child holdsOnlyTheStateOf:[self appearance:CPAppearanceNameDarkAqua]]];

    [CPApp setAppearance:nil];
    [self assertTrue:[self view:parent holdsOnlyTheStateOf:aqua] message:@"The detached parent keeps its record"];

    [[window contentView] addSubview:parent];

    [self assertTrue:[self view:parent holdsOnlyTheStateOf:aqua]];
    [self assertTrue:[self view:child holdsOnlyTheStateOf:aqua]];
}

- (void)testALayoutWithoutAChangeWalksNoAppearance
{
    var parent = [self newView],
        child = [self newView];

    [parent addSubview:child];
    [[window contentView] addSubview:parent];
    [_CPDisplayServer run];

    parent.recomputeCount = 0;
    child.recomputeCount = 0;
    parent.layoutCount = 0;

    [parent setNeedsLayout];
    [child setNeedsLayout];
    [_CPDisplayServer run];

    [self assert:1 equals:parent.layoutCount];
    [self assert:0 equals:parent.recomputeCount];
    [self assert:0 equals:child.recomputeCount];
}

- (void)testAViewDidLayoutOverrideWithoutSuperDoesNotStopTheState
{
    var view = [[CPViewAppearanceTestNoSuperLayoutView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)],
        darkAqua = [self appearance:CPAppearanceNameDarkAqua];

    [[window contentView] addSubview:view];
    [window setAppearance:darkAqua];
    [view setNeedsLayout];
    [view layoutIfNeeded];

    [self assertTrue:[self view:view holdsOnlyTheStateOf:darkAqua]];
}

// MARK: Drawing appearance

- (void)testLayoutAndDrawingRunInTheViewAppearance
{
    var view = [self newView],
        vibrantDark = [self appearance:CPAppearanceNameVibrantDark],
        methods = [@"viewWillLayout", @"layoutSubviews", @"viewDidLayout", @"viewWillDraw"];

    [view setAppearance:vibrantDark];
    [[window contentView] addSubview:view];

    [view setNeedsLayout];
    [view layoutIfNeeded];
    [view displayRect:[view bounds]];

    for (var i = 0; i < methods.length; i++)
        [self assert:vibrantDark same:view.drawingAppearances[methods[i]] message:methods[i]];

    [self assert:[CPApp effectiveAppearance] same:[CPAppearance currentDrawingAppearance]];
}

- (void)testSiblingsLayOutInTheirOwnAppearancesInOneRun
{
    var dark = [self newView],
        light = [self newView],
        vibrantDark = [self appearance:CPAppearanceNameVibrantDark],
        vibrantLight = [self appearance:CPAppearanceNameVibrantLight];

    [dark setAppearance:vibrantDark];
    [light setAppearance:vibrantLight];
    [[window contentView] addSubview:dark];
    [[window contentView] addSubview:light];

    dark.drawingAppearances = {};
    light.drawingAppearances = {};

    [dark setNeedsLayout];
    [light setNeedsLayout];
    [_CPDisplayServer run];

    [self assert:vibrantDark same:dark.drawingAppearances["layoutSubviews"]];
    [self assert:vibrantLight same:light.drawingAppearances["layoutSubviews"]];
}

- (void)testTheBlockAppearanceIsCurrentAgainAfterALayoutInsideIt
{
    var view = [self newView],
        darkAqua = [self appearance:CPAppearanceNameDarkAqua],
        vibrantDark = [self appearance:CPAppearanceNameVibrantDark],
        appearanceAfterLayout = nil;

    [view setAppearance:vibrantDark];
    [[window contentView] addSubview:view];
    [view setNeedsLayout];

    [darkAqua performAsCurrentDrawingAppearance:function()
    {
        [view layoutIfNeeded];
        appearanceAfterLayout = [CPAppearance currentDrawingAppearance];
    }];

    [self assert:vibrantDark same:view.drawingAppearances["layoutSubviews"]];
    [self assert:darkAqua same:appearanceAfterLayout];
}

- (void)testAnExceptionInLayoutSubviewsRestoresTheDrawingAppearance
{
    var view = [[CPViewAppearanceTestRaisingView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];

    [view setAppearance:[self appearance:CPAppearanceNameVibrantDark]];
    [[window contentView] addSubview:view];
    [view setNeedsLayout];

    [self assertThrows:function()
    {
        [view layoutIfNeeded];
    }];

    [self assert:[CPApp effectiveAppearance] same:[CPAppearance currentDrawingAppearance]];
}

- (void)testOutsideLayoutTheDrawingAppearanceIsTheApplicationAppearance
{
    var darkAqua = [self appearance:CPAppearanceNameDarkAqua];

    [self assert:[CPApp effectiveAppearance] same:[CPAppearance currentDrawingAppearance]];

    [CPApp setAppearance:darkAqua];

    [self assert:darkAqua same:[CPAppearance currentDrawingAppearance]];
}

// MARK: Resolved values

- (void)testADynamicBackgroundSetOutsideLayoutResolvesInTheViewAppearance
{
    var view = [self newView],
        color = [self greyColor];

    [view setAppearance:[self appearance:CPAppearanceNameVibrantDark]];
    [[window contentView] addSubview:view];

    [view setBackgroundColor:color];

    [self assert:color same:[view backgroundColor]];
    [self assertTrue:[view._backgroundColorResolved isEqual:[CPColor colorWithWhite:0.1 alpha:1.0]]];
}

- (void)testAnAppearanceChangeResolvesTheBackgroundAgainWithoutTheSetter
{
    var view = [self newView];

    [view setAppearance:[self appearance:CPAppearanceNameVibrantDark]];
    [[window contentView] addSubview:view];
    [view setBackgroundColor:[self greyColor]];

    [view setAppearance:[self appearance:CPAppearanceNameVibrantLight]];

    [self assertTrue:[view._backgroundColorResolved isEqual:[CPColor colorWithWhite:0.9 alpha:1.0]]];
    [self assert:1 equals:view.backgroundSetterCount];
}

/*
    The colour gives a new object at each resolution. A setter that did its work again would
    store the second object.
*/
- (void)testASecondSetWithTheSameColorAndAppearanceDoesNoWork
{
    var view = [self newView],
        color = [self greyColor];

    [[window contentView] addSubview:view];
    [view setBackgroundColor:color];

    var firstResolution = view._backgroundColorResolved;

    [view setBackgroundColor:color];

    [self assert:firstResolution same:view._backgroundColorResolved];
}

- (void)testCSSBasedResolutionsWithEqualComponentsApplyAgain
{
    var view = [self newView],
        darkCSS = [CPColor colorWithCSSDictionary:@{ @"background-color": @"#111111" }],
        lightCSS = [CPColor colorWithCSSDictionary:@{ @"background-color": @"#eeeeee" }],
        color = [[CPViewAppearanceTestColor alloc] initWithValueFunction:function(aName)
        {
            return aName === CPAppearanceNameVibrantDark ? darkCSS : lightCSS;
        }];

    [self assertTrue:[darkCSS isEqual:lightCSS] message:@"-isEqual: ignores the CSS dictionaries"];

    [view setAppearance:[self appearance:CPAppearanceNameVibrantDark]];
    [[window contentView] addSubview:view];
    [view setBackgroundColor:color];
    [self assert:darkCSS same:view._backgroundColorResolved];

    [view setAppearance:[self appearance:CPAppearanceNameVibrantLight]];
    [self assert:lightCSS same:view._backgroundColorResolved];
}

// MARK: Review additions

- (void)testSetFontOutsideLayoutLaysOutInTheViewAppearance
{
    var parent = [self newView],
        textField = [[CPViewAppearanceTestTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 24.0)],
        vibrantDark = [self appearance:CPAppearanceNameVibrantDark];

    [parent setAppearance:vibrantDark];
    [parent addSubview:textField];
    [[window contentView] addSubview:parent];

    textField.layoutAppearance = nil;
    [textField setFont:[CPFont boldSystemFontOfSize:17.0]];

    [self assert:vibrantDark same:textField.layoutAppearance];
}

- (void)testAnArchivedViewHoldsNoAppearanceState
{
    var parent = [self newView],
        child = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 10.0)];

    [parent setAppearance:[self appearance:CPAppearanceNameVibrantDark]];
    [parent addSubview:child];
    [[window contentView] addSubview:parent];
    [self assertTrue:[child hasThemeState:CPThemeStateAppearanceVibrantDark]];

    var data = [CPKeyedArchiver archivedDataWithRootObject:child],
        archivedStates = CPViewAppearanceTestArchivedThemeStates(data),
        decoded = [CPKeyedUnarchiver unarchiveObjectWithData:data];

    [self assert:1 equals:archivedStates.length];
    [self assert:-1 equals:archivedStates[0].indexOf("appearance-") message:@"The archive holds " + archivedStates[0]];
    [self assert:-1 equals:String([decoded themeState]).indexOf("appearance-")];
}

- (void)testAWalkWithoutAChangeLeavesNoPendingLayoutOrDisplay
{
    var parent = [self newView],
        child = [self newView];

    [parent addSubview:child];
    [[window contentView] addSubview:parent];
    [_CPDisplayServer run];

    [self assertFalse:[parent needsLayout] || [child needsLayout] || [parent needsDisplay] || [child needsDisplay] message:@"Nothing is pending before the walk"];

    [child setNeedsDisplay:YES];
    [self assertTrue:[child needsDisplay] message:@"The view can need display"];
    [_CPDisplayServer run];

    [parent setAppearance:[CPApp effectiveAppearance]];

    [self assertFalse:[parent needsLayout]];
    [self assertFalse:[child needsLayout]];
    [self assertFalse:[parent needsDisplay]];
    [self assertFalse:[child needsDisplay]];
}

@end
