@import <AppKit/CPTheme.j>

@implementation CPThemeTest : OJTestCase
{
}

- (void)testCreatingThemeState
{
    var themeState = new ThemeState({'test': true, 'test1': true});
    [self assertTrue:themeState._stateNames['test'] message:"Creating a new ThemeState sets the statenames correctly."];
    [self assertTrue:themeState._stateNames['test1'] message:"Creating a new ThemeState sets the statenames correctly."];
    [self assertTrue:(themeState._stateNameCount === 2) message:"Creating a new ThemeState sets count of state names correctly."];
    [self assertTrue:(String(themeState) === "test+test1") message:"Creating a new ThemeState sets its string value to its sorted state names"];

    themeState = new ThemeState();
    [self assertTrue:themeState._stateNames['normal'] message:"Creating a new ThemeState with no states sets the ThemeState to be a normal themestate"];
    [self assertTrue:(themeState._stateNameCount === 1) message:"Creating a new ThemeState with no states creates a new ThemeState with one state (normal)."];

    themeState = new ThemeState({'boo': true, 'normal': true});
    [self assertTrue:themeState._stateNames['boo'] message:"Creating a new combined ThemeState with normal and something else only sets the other theme state."];
    [self assertFalse:themeState._stateNames['normal'] message:"Creating a new combined ThemeState with normal and something else only sets the other theme state."];
    [self assertTrue:(themeState._stateNameCount === 1) message:"Creating a new ThemeState with no states creates a new ThemeState with one state (normal)."];
}

- (void)testCreatingThemeStateWithCPThemeState
{
    var themeState1 = CPThemeState('normal');
    var themeState2 = CPThemeState('normal');
    [self assertTrue:(themeState1 === themeState2) message:"Creating two themestates with the same string returns the same object for both"];


    themeState1 = CPThemeState('smee+blee');
    themeState2 = CPThemeState('blee+smee');

    [self assertTrue:(themeState1 === themeState2) message:"Creating two combined themestates with the same component themestates returns the same object for both"];

    var themeState3 = CPThemeState('hello', themeState1, themeState2);
    [self assertTrue:(String(themeState3) === "blee+hello+smee") message:"Can create a combined themestate with both string and object arguments"];

    var themeState4 = CPThemeState(themeState3);
    [self assertTrue:(themeState4 === themeState3) message:"Creating a new ThemeState off an old one returns the same object"];

    var themeState5 = CPThemeState('a', 'theme', 'state');
    [self assertTrue:(String(themeState5) === 'a+state+theme') message:"Creating a new ThemeState using multiple strings works."];
}

- (void)testThemeAttributeValueForState
{
    var themeAttribute = [[_CPThemeAttribute alloc] initWithName:@"test" defaultValue:5];
    [self assertTrue:([themeAttribute valueForState:CPThemeState("aState")] == 5) message:"Return the default value for the theme attribute if the theme attribute has no value defined for the given state"];

    [themeAttribute setValue:7 forState:CPThemeState("aState")];
    [self assertTrue:([themeAttribute valueForState:CPThemeState("aState")] == 7) message:"Return the correct value for the state if the state is defined"];

    [themeAttribute setValue:8 forState:CPThemeState('normal')];
    [self assertTrue:([themeAttribute valueForState:CPThemeState("aState1")] == 8) message:"Return the normal value for the state if the theme attribute has no value defined for the given state but has a value for the normal state defined"];

    [themeAttribute setValue:10 forState:CPThemeState('aState3+aState4')];
    [self assertTrue:([themeAttribute valueForState:CPThemeState("aState3")] == 8) message:"Return the normal value for the state if the state is only a partial match on the theme attributes defined states"];
    [self assertTrue:([themeAttribute valueForState:CPThemeState("aState4+aState3")] == 10) message:"Correctly match combined states on the theme attribute"];

    [themeAttribute setValue:9 forState:CPThemeState('aState3')];
    [self assertTrue:([themeAttribute valueForState:CPThemeState("aState8+aState3+aState4")] == 10) message:"Return the largest partial subset match for a combined state that isn't a perfect match"];
}

@end
