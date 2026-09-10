/*
 * AppController.j
 * CPButtonImageTest
 *
 * Created by Aparajita Fishman on August 31, 2010.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "SCMultiLineLabel.j"
@import "SCString.j"

var BrowserColumnTheme     = 0,
    BrowserColumnClass     = 1,
    BrowserColumnAttribute = 2,
    BrowserColumnState     = 3,

    ColumnTitles = ["Theme", "Class", "Attribute", "State"],

    ImageDescriptionFormat = "<%s> {\n   filename: \"%s\",\n   size: { width:%f, height:%f }\n}",
    ValueLabelTemplate = "Attribute value#0#:# <span style=\"font-weight:normal\">($0 / $1 / $2 / $3):</span>#";


@implementation AppController : CPObject
{
    CPWindow            theWindow;

    CPBrowser           browser;
    CPArray             rootNodes;

    SCMultiLineLabel    valueLabel;
    SCMultiLineLabel    valueView;
}

- (void)awakeFromCib
{
    SharedController = self;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    [theWindow setFullPlatformWindow:YES];

    var contentView = [theWindow contentView],
        themeNames = [[[CPApplication sharedApplication] themeBlend] themeNames],
        frame = CGRectMake(20, 20, 800, 20),
        browserFrame = CGRectMake(20, 50, 800, 300),
        label = [[SCMultiLineLabel alloc] initWithFrame:frame];

    [label setFont:[CPFont boldSystemFontOfSize:14]];
    [label setStringValue:@"Browse theme attributes from ThemeDescriptors.j"];
    [contentView addSubview:label];

    rootNodes = [];
    browser = [[CPBrowser alloc] initWithFrame:browserFrame];

    for (var i = 0; i < themeNames.length; ++i)
    {
        var node = [[ThemeNode alloc] initWithBrowser:browser value:[CPTheme themeNamed:themeNames[i]] type:NodeTypeTheme];
        rootNodes.push(node);
    }

    [browser setLastColumn:3];
    [browser setMinColumnWidth:200];
    [browser setTarget:self];
    [browser setAction:@selector(browserClicked:)];
    [browser setDelegate:self];

    var box = [CPBox boxEnclosingView:browser];

    [contentView addSubview:box];

    var frame = CGRectMake(CGRectGetMinX(browserFrame), CGRectGetMaxY(browserFrame) + 20, CGRectGetWidth(browserFrame), 17),
        valueLabel = [[SCMultiLineLabel alloc] initWithFrame:frame],
        fonts = [[CPFontManager sharedFontManager] availableFonts],
        frame = CGRectMake(CGRectGetMinX(frame), CGRectGetMaxY(frame) + 7, CGRectGetWidth(browserFrame), 250);

    [valueLabel setStyled:YES];
    [valueLabel setFont:[CPFont boldSystemFontOfSize:12]];
    [valueLabel setColor:[CPColor colorWithHexString:@"444444"]];
    [valueLabel setStringValue:[SCString stringWithTemplate:ValueLabelTemplate, @"", @"", @"", @""]];
    [contentView addSubview:valueLabel];

    valueView = [[SCMultiLineLabel alloc] initWithFrame:frame];

    if ([fonts indexOfObjectIdenticalTo:@"Courier"])
        [valueView setFont:[CPFont fontWithName:@"Courier" size:12]];
    else if ([fonts indexOfObjectIdenticalTo:@"Courier New"])
        [valueView setFont:[CPFont fontWithName:@"Courier New" size:12]];

    [valueView setContentInset:CGInsetMake(7, 7, 7, 7)];

    box = [CPBox boxEnclosingView:valueView];
    [contentView addSubview:box];
}

- (void)browserClicked:(id)sender
{
    var column = [browser selectedColumn];

    if (column != BrowserColumnState)
        return;

    var row = [browser selectedRowInColumn:BrowserColumnTheme],
        theme = [[browser itemAtRow:row inColumn:BrowserColumnTheme] value],
        row = [browser selectedRowInColumn:BrowserColumnClass],
        className = [[browser itemAtRow:row inColumn:BrowserColumnClass] value],
        row = [browser selectedRowInColumn:BrowserColumnAttribute],
        attribute = [[browser itemAtRow:row inColumn:BrowserColumnAttribute] value],
        row = [browser selectedRowInColumn:BrowserColumnState],
        state = [[browser itemAtRow:row inColumn:BrowserColumnState] value]["key"];

    var value = [theme valueForAttributeWithName:[attribute name] inState:state forClass:className];

    [valueLabel setStringValue:[SCString stringWithTemplate:ValueLabelTemplate, [theme name], className, [attribute name], String(state)]]
    [self showValueDescription:value];
}

- (void)showValueDescription:(id)aValue
{
    var description = "";

    if (!aValue.isa)
    {
        if (typeof(aValue) === "object")
        {
            if (aValue.hasOwnProperty("width") && aValue.hasOwnProperty("height"))
                description = [CPString stringWithFormat:@"CGSize: { width:%f, height:%f }", aValue.width, aValue.height];
            else if (aValue.hasOwnProperty("x") && aValue.hasOwnProperty("y"))
                description = [CPString stringWithFormat:@"CGPoint: { x:%f, y:%f }", aValue.x, aValue.y];
            else if (aValue.hasOwnProperty("origin") && aValue.hasOwnProperty("size"))
                description = [CPString stringWithFormat:@"CGRect: { x:%f, y:%f }, { width:%f, height:%f }", aValue.origin.x, aValue.origin.y, aValue.size.width, aValue.size.height];
            else if (aValue.hasOwnProperty("top") && aValue.hasOwnProperty("right") && aValue.hasOwnProperty("bottom") && aValue.hasOwnProperty("left"))
                description = [CPString stringWithFormat:@"CGInset: { top:%f, right:%f, bottom:%f, left:%f }", aValue.top, aValue.right, aValue.bottom, aValue.left];
            else
            {
                description = "Object\n{\n";

                for (var property in aValue)
                {
                    if (aValue.hasOwnProperty(property))
                        description += "   " + property + ":" + aValue[property] + "\n";
                }

                description += "}";
            }
        }
        else
            description = "Unknown object";
    }
    else if ([aValue isKindOfClass:[CPImage class]])
        description = [self imageDescription:aValue];
    else if ([aValue isKindOfClass:[CPColor class]])
        description = [self colorDescription:aValue];
    else
        description = [aValue description];

    [valueView setStringValue:description];
}

- (CPString)imageDescription:(CPImage)anImage
{
    var filename = [anImage filename],
        size = [anImage size];

    if (filename.indexOf("data:") === 0)
    {
        var index = filename.indexOf(",");

        if (index > 0)
            filename = [CPString stringWithFormat:@"%s,%s...%s", filename.substr(0, index), filename.substr(index + 1, 10), filename.substr(filename.length - 10)];
        else
            filename = "data:<unknown type>";
    }

    return [CPString stringWithFormat:ImageDescriptionFormat, [anImage className], filename, size.width, size.height];
}

- (CPString)colorDescription:(CPColor)aColor
{
    var patternImage = [aColor patternImage];

    if (!patternImage || !([patternImage isThreePartImage] || [patternImage isNinePartImage]))
        return [aColor description];

    var description = "<CPColor> {\n",
        slices = [patternImage imageSlices];

    if ([patternImage isThreePartImage])
        description += "   orientation: " + ([patternImage isVertical] ? "vertical" : "horizontal") + ",\n";

    description += "   patternImage: [\n";

    for (var i = 0; i < slices.length; ++i)
    {
        var imageDescription = [self imageDescription:slices[i]];

        description += imageDescription.replace(/^/mg, "      ") + ",\n";
    }

    description = description.substr(0, description.length - 2) + "\n   ]\n}";
    return description;
}

- (CPString)browser:(id)aBrowser titleOfColumn:(CPInteger)column
{
    return ColumnTitles[column];
}

- (id)browser:(id)aBrowser numberOfChildrenOfItem:(id)anItem
{
    if (!anItem)
        return [rootNodes count];

    return [[anItem children] count];
}

- (id)browser:(id)aBrowser child:(int)index ofItem:(id)anItem
{
    if (!anItem)
        return [rootNodes objectAtIndex:index];

    return [[anItem children] objectAtIndex:index];
}

- (id)browser:(id)aBrowser objectValueForItem:(id)anItem
{
    return [anItem objectValue];
}

- (id)browser:(id)aBrowser isLeafItem:(id)anItem
{
    return [anItem type] === NodeTypeValue;
}

@end

var NodeTypeTheme     = 0,
    NodeTypeClass     = 1,
    NodeTypeAttribute = 2,
    NodeTypeValue     = 3;

@implementation ThemeNode : CPObject
{
    CPBrowser   browser;
    int         type        @accessors(readonly);
    id          value       @accessors(readonly);
    CPArray     children    @accessors(readonly);
}

- (id)initWithBrowser:(CPBrowser)aBrowser value:(id)aValue type:(int)aType
{
    if (self = [super init])
    {
        browser = aBrowser;
        value = aValue;
        type = aType;
        children = nil;
    }

    return self;
}

- (id)objectValue
{
    switch (type)
    {
        case NodeTypeTheme:
            return [value name];

        case NodeTypeClass:
            return value;

        case NodeTypeAttribute:
            return [value name];

        case NodeTypeValue:
            return CPThemeStateName(value["key"]);
    }
}

- (CPArray)children
{
    if (children)
        return children;

    children = [];

    switch (type)
    {
        case NodeTypeTheme:
            var classes = [value classNames].sort();

            for (var i = 0; i < classes.length; ++i)
                children.push([[ThemeNode alloc] initWithBrowser:browser value:classes[i] type:NodeTypeClass]);
            break;

        case NodeTypeClass:
            var selectedRow = [browser selectedRowInColumn:0],
                theme = [[browser itemAtRow:selectedRow inColumn:0] value],
                attributes = [theme attributesForClass:value],
                keys = [attributes allKeys].sort();

            // NOTE: I could use [attributes objectForKey:keys[i]] in the loop, but I want
            // to do code coverage of CPTheme.
            for (var i = 0; i < keys.length; ++i)
                children.push([[ThemeNode alloc] initWithBrowser:browser value:[theme attributeWithName:keys[i] forClass:value] type:NodeTypeAttribute]);
            break;

        case NodeTypeAttribute:
            var selectedRow = [browser selectedRowInColumn:0],
                theme = [[browser itemAtRow:selectedRow inColumn:0] value],
                selectedRow = [browser selectedRowInColumn:1],
                className = [[browser itemAtRow:selectedRow inColumn:1] value],
                attributeValues = [value values],
                keys = [attributeValues allKeys];

            [keys sortUsingFunction:attributeCompareFunc context:nil];

            // NOTE: I could use [attributes objectForKey:keys[i]] in the loop, but I want
            // to do code coverage of CPTheme.
            for (var i = 0; i < keys.length; ++i)
            {
                var nodeValue =
                {
                    key:keys[i],
                    attribute:[theme valueForAttributeWithName:[value name] inState:keys[i] forClass:className]
                };

                children.push([[ThemeNode alloc] initWithBrowser:browser value:nodeValue type:NodeTypeValue]);
            }
            break;

        case NodeTypeValue:
            break;
    }

    return children;
}

@end

var attributeCompareFunc = function(lhs, rhs)
{
    var lhsInt = parseInt(lhs),
        rhsInt = parseInt(rhs);

    if (lhsInt === rhsInt)
        return CPOrderedSame;
    else if (lhsInt > rhsInt)
        return CPOrderedDescending;
    else
        return CPOrderedAscending;
};
