@import <Foundation/CPBundle.j>

@implementation CPBundleTest : OJTestCase
{

}

+ (void)setUp
{

}

+ (void)tearDown
{

}

- (void)setUp
{

}

- (void)tearDown
{

}

- (void)testCreationMainBundle
{
    var bundle = [CPBundle mainBundle];
}

- (void)testLoadingBundle
{
    var bundle = [CPBundle bundleWithPath:@"Tests/Foundation/BundleTest"];
    [bundle loadWithDelegate:self];

    [self assert:[bundle objectForInfoDictionaryKey:"CPBundleDefaultLanguage"] equals:"fr"];
    [self assert:[bundle objectForInfoDictionaryKey:"CPBundleLocalizableStrings"] equals:["Localizable.strings"]];
}

- (void)testLocalization
{
    var bundle = [CPBundle bundleWithPath:@"Tests/Foundation/BundleTest"];
    [bundle loadWithDelegate:self];

    [self assert:[bundle localizedStringForKey:"Label from file" value:"" table:"Localizable"] equals:"Label traduit de fr.lproj du premier context"];
    [self assert:[bundle localizedStringForKey:"Wrong key" value:"Default value" table:"Localizable"] equals:"Default value"];
    [self assert:[bundle localizedStringForKey:"Wrong key" value:"" table:"Localizable"] equals:"Wrong key"];

    [self assert:CPCopyLocalizedStringFromTableInBundle("Label from file", "Localizable", bundle, "My first context.") equals:"Label traduit de fr.lproj du premier context"];
    [self assert:CPCopyLocalizedStringFromTableInBundle("Label from file", "", bundle, "My first context.") equals:"Label traduit de fr.lproj du premier context"];
    [self assert:CPCopyLocalizedStringFromTableInBundle("Label from file", "Localizable", bundle, "") equals:"Label traduit de fr.lproj du premier context"];
    [self assert:CPCopyLocalizedStringFromTableInBundle("Wrong key", "Localizable", bundle, "") equals:"Wrong key"];
    [self assert:CPCopyLocalizedStringFromTableInBundle("Wrong key", "coucou", bundle, "") equals:"Wrong key"];

    [self assert:CPCopyLocalizedStringFromTableInBundle("Label from file", "Localizable", bundle, "My second context.") equals:"Label traduit de fr.lproj du second context"];
}

@end

@implementation CPBundleTest (CPBundleTestBundleDelegate)

- (void)bundleDidFinishLoading:(CPBundle)aBundle
{

}

@end