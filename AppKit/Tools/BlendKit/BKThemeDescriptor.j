
@import <Foundation/CPObject.j>


var ItemSizes               = { },
    ThemedObjects           = { },
    BackgroundColors        = { },

    LightCheckersColor      = nil,
    DarkCheckersColor       = nil,
    WindowBackgroundColor   = nil;

@implementation BKThemeDescriptor : CPObject
{
}

+ (CPArray)allThemeDescriptorClasses
{
    // Grab Theme Descriptor Classes.
    var themeDescriptorClasses = [];

    for (candidate in window)
    {
        var theClass = objj_getClass(candidate),
            theClassName = class_getName(theClass);

        if (theClassName === "BKThemeDescriptor")
            continue;

        var index = theClassName.indexOf("ThemeDescriptor");

        if ((index >= 0) && (index === theClassName.length - "ThemeDescriptor".length))
            themeDescriptorClasses.push(theClass);
    }

    [themeDescriptorClasses sortUsingSelector:@selector(compare:)];

    return themeDescriptorClasses;
}

+ (CPColor)lightCheckersColor
{
    if (!LightCheckersColor)
        LightCheckersColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[BKThemeDescriptor class]] pathForResource:@"light-checkers.png"] size:CGSizeMake(12.0, 12.0)]];

    return LightCheckersColor;
}

+ (CPColor)darkCheckersColor
{
    if (!DarkCheckersColor)
        DarkCheckersColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[BKThemeDescriptor class]] pathForResource:@"dark-checkers.png"] size:CGSizeMake(12.0, 12.0)]];

    return DarkCheckersColor;
}

+ (CPColor)windowBackgroundColor
{
    return [_CPStandardWindowView bodyBackgroundColor];
}

+ (CPColor)defaultShowcaseBackgroundColor
{
    return [self lightCheckersColor];
}

+ (CPColor)showcaseBackgroundColor
{
    var className = [self className];

    if (!BackgroundColors[className])
        BackgroundColors[className] = [self defaultShowcaseBackgroundColor];

    return BackgroundColors[className];
}

+ (void)setShowcaseBackgroundColor:(CPColor)aColor
{
    BackgroundColors[[self className]] = aColor;
}

+ (CGSize)itemSize
{
    var className = [self className];

    if (!ItemSizes[className])
        [self calculateThemedObjectTemplates];

    return CGSizeMakeCopy(ItemSizes[className]);
}

+ (CPArray)themedObjectTemplates
{
    var className = [self className];

    if (!ThemedObjects[className])
        [self calculateThemedObjectTemplates];

    return ThemedObjects[className];
}

+ (void)calculateThemedObjectTemplates
{
    var templates = [],
        itemSize = CGSizeMake(0.0, 0.0),
        methods = class_copyMethodList([self class].isa),
        index = 0,
        count = [methods count];

    for (; index < count; ++index)
    {
        var method = methods[index],
            selector = method_getName(method);

        if (selector.indexOf("themed") !== 0)
            continue;

        var impl = method_getImplementation(method),
            object = impl(self, selector);

        if (!object)
            continue;

        var template = [[BKThemeObjectTemplate alloc] init];

        [template setValue:object forKey:@"themedObject"];
        [template setValue:BKLabelFromIdentifier(selector) forKey:@"label"];

        [templates addObject:template];

        if ([object isKindOfClass:[CPView class]])
        {
            var size = [object frame].size,
                labelWidth = [[template valueForKey:@"label"] sizeWithFont:[CPFont boldSystemFontOfSize:12.0]].width + 20.0;

            if (size.width > itemSize.width)
                itemSize.width = size.width;

            if (labelWidth > itemSize.width)
                itemSize.width = labelWidth;

            if (size.height > itemSize.height)
                itemSize.height = size.height;
        }
    }

    var className = [self className];

    ItemSizes[className] = itemSize;
    ThemedObjects[className] = templates;
}

+ (int)compare:(BKThemeDescriptor)aThemeDescriptor
{
    return [[self themeName] compare:[aThemeDescriptor themeName]];
}

@end

function BKLabelFromIdentifier(anIdentifier)
{
    var string = anIdentifier.substr("themed".length);
        index = 0,
        count = string.length,
        label = "",
        lastCapital = null,
        isLeadingCapital = YES;

    for (; index < count; ++index)
    {
        var character = string.charAt(index),
            isCapital = /^[A-Z]/.test(character);

        if (isCapital)
        {        
            if (!isLeadingCapital)
            {
                if (lastCapital === null)
                    label += ' ' + character.toLowerCase();
                else
                    label += character;
            }

            lastCapital = character;
        }
        else
        {
            if (isLeadingCapital && lastCapital !== null)
                label += lastCapital;

            label += character;

            lastCapital = null;
            isLeadingCapital = NO;
        }
    }

    return label;
}

