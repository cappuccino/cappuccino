@import <AppKit/AppKit.j>

@implementation CPFontTest : OJTestCase
{
    CPFont _systemFont;
    CPFont _boldSystemFont;

    CPFont _customFont;
    CPFont _boldCustomFont;
}

- (void)setUp
{
    _systemFont = [CPFont systemFontOfSize:15];
    _boldSystemFont = [CPFont boldSystemFontOfSize:15];

    _customFont = [CPFont fontWithName:@"Marker Felt, Lucida Grande, Helvetica" size:30];
    _boldCustomFont = [CPFont boldFontWithName:@"Helvetica" size:30];
}

- (void)testSystemFontCSSString
{
    var font = _CPFontConcatNameWithFallback([CPFont systemFontFace]);

    [self assert:[_systemFont cssString] equals:@"15px " + font];
}

- (void)testBoldSystemFontCSSString
{
    var font = _CPFontConcatNameWithFallback([CPFont systemFontFace]);

    [self assert:[_boldSystemFont cssString] equals:@"bold 15px " + font];
}

- (void)testCustomFontCSSString
{
    [self assert:[_customFont cssString] equals:@"30px \"Marker Felt\", \"Lucida Grande\", Helvetica, Arial, sans-serif"];
}

- (void)testBoldCustomFontCSSString
{
    [self assert:[_boldCustomFont cssString] equals:@"bold 30px Helvetica, Arial, sans-serif"];
}

- (void)testIsEqual
{
    [self assert:_customFont equals:_customFont];
    [self assert:_systemFont equals:_systemFont];
    [self assert:_systemFont notEqual:_customFont];
    [self assert:_customFont notEqual:"a string"];
    [self assert:_customFont notEqual:nil];
}

- (void)testConstructorsIsBoldIsItalic
{
    [self testConstructor:@selector(fontWithName:size:) args:["Arial", 12] isBold:NO isItalic:NO];
    [self testConstructor:@selector(boldFontWithName:size:) args:["Arial", 13] isBold:YES isItalic:NO];
    [self testConstructor:@selector(fontWithName:size:italic:) args:["Arial", 14, YES] isBold:NO isItalic:YES];
    [self testConstructor:@selector(boldFontWithName:size:italic:) args:["Arial", 15, NO] isBold:YES isItalic:NO];
}

- (void)testConstructor:(SEL)aSelector args:(CPArray)args isBold:(BOOL)bold isItalic:(BOOL)italic
{
    var inv = [CPInvocation invocationWithMethodSignature:nil];
    [inv setTarget:CPFont];
    [inv setSelector:aSelector];
    [args enumerateObjectsUsingBlock:function(arg, idx)
    {
        [inv setArgument:arg atIndex:idx + 2];
    }];

    [inv invoke];
    var font = [inv returnValue];

    [self assertTrue:([font isBold] == bold) message: [font description] + " should be bold: " + bold];
    [self assertTrue:([font isItalic] == italic) message: [font description] + " should be italic: " + italic];

    // get from cache
    [inv invoke];
    var cachedFont = [inv returnValue];
    [self assert:cachedFont equals:font];

    [self assertTrue:([cachedFont isBold] == bold) message:" cached " + [cachedFont description] + " should be bold: " + bold];
    [self assertTrue:([cachedFont isItalic] == italic) message:" cached " + [cachedFont description] + " should be italic: " + italic];
}

- (void)testSizes
{
    var font = [CPFont fontWithName:@"Arial" size:0],
        systemSize = [CPFont systemFontSize];

    [self assertTrue:([font size] === systemSize) message:" font size should be system size (" + systemSize + ")"];

    var sysfont1 = [CPFont systemFontOfSize:12];
    [self assertTrue:([sysfont1 size] === 12) message:" font size should be 12"];

    var sysfont2 = [CPFont systemFontOfSize:0];
    [self assertTrue:([sysfont2 size] === systemSize) message:" font size should be system size (" + systemSize + ")"];

    var sysfont3 = [CPFont systemFontOfSize:-1];
    [self assertTrue:([sysfont3 size] === systemSize) message:" font size should be system size (" + systemSize + ")"];

    var newSystemSize = 13;
    [CPFont setSystemFontSize:newSystemSize];
    [self assertTrue:([sysfont2 size] === systemSize) message:" font size should be old system size (" + systemSize + ")"];
    [self assertTrue:([sysfont3 size] === newSystemSize) message:" font size should be new system size (" + newSystemSize + ")"];
}

- (void)testFaces
{
    var font = [CPFont fontWithName:@"Georgia" size:0],
        systemFace = [CPFont systemFontFace];

    [self assertTrue:([font familyName] === @"Georgia") message:" font face should be Georgia"];

    var sysfont = [CPFont systemFontOfSize:12];
    [self assertTrue:([sysfont familyName] === systemFace) message:" font face should be system face (" + systemFace + ")"];

    var newSystemFace = @"Georgia";
    [CPFont setSystemFontFace:newSystemFace];
    [self assertTrue:([sysfont familyName] === newSystemFace) message:" font face should be new system face (" + newSystemFace + ")"];
}

@end

var _CPFontStripRegExp = new RegExp("(^\\s*[\"']?|[\"']?\\s*$)", "g");

var _CPFontConcatNameWithFallback = function(aName)
{
    var names = _CPFontNormalizedNameArray(aName),
        fallbackFaces = ["Arial", "sans-serif"];

    // Remove the fallback names used in the names passed in
    for (var i = 0; i < names.length; ++i)
    {
        for (var j = 0; j < fallbackFaces.length; ++j)
        {
            if (names[i].toLowerCase() === fallbackFaces[j].toLowerCase())
            {
                fallbackFaces.splice(j, 1);
                break;
            }
        }

        if (names[i].indexOf(" ") > 0)
            names[i] = '"' + names[i] + '"';
    }

    return names.concat(fallbackFaces).join(", ");
};

var _CPFontNormalizedNameArray = function(aName)
{
    var names = aName.split(",");

    for (var i = 0; i < names.length; ++i)
        names[i] = names[i].replace(_CPFontStripRegExp, "");

    return names;
};
