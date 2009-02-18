/*
 * CPTheme.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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

@import <Foundation/CPObject.j>
@import <AppKit/_CPCibCustomResource.j>
@import <AppKit/_CPCibKeyedUnarchiver.j>

@import "CPThemedAttribute.j"


var CPThemesByName      = nil,
    CPThemeDefaultTheme = nil,

    CPThemeViewClass    = Nil,
    CPThemeWindowClass  = Nil;

@implementation CPTheme : CPObject
{
    CPString    _name;
    Class       _activeClass;
    JSObject    _classTable;
}

+ (void)initialize
{
    if (self !== [CPTheme class])
        return;
    
    CPThemesByName = {};
    
    CPThemeViewClass = [CPView class];
    CPThemeWindowClass = [CPWindow class];

    var bundle = [CPBundle bundleForClass:self];
        defaultThemePath = [bundle objectForInfoDictionaryKey:@"Default Themes Path"],
        defaultThemeName = [bundle objectForInfoDictionaryKey:@"Default Theme Name"];
    
    if (!defaultThemePath)
        return;
    
    defaultThemePath = [bundle pathForResource:defaultThemePath];
    
    var file = objj_files[defaultThemePath + "/Info.plist"];
    
    if (!file)
        return;
    
    // Oh boy are we tricky.
    var infoDictionary = CPPropertyListCreateFromData([CPData dataWithString:objj_files[defaultThemePath + "/Info.plist"].contents]);
    
        themes = [infoDictionary objectForKey:@"CPBundleReplacedFiles"],
        
        themeIndex = 0,
        themeCount = [themes count];
        
    for (; themeIndex < themeCount; ++themeIndex)
    {
        var unarchiver = [[_CPThemeKeyedUnarchiver alloc]
            initForReadingWithData:[CPData dataWithString:objj_files[defaultThemePath + '/' + themes[themeIndex]].contents]
                            bundle:file.bundle];
        
        [unarchiver decodeObjectForKey:@"root"];
         
        [unarchiver finishDecoding];
    }
    
    [self setDefaultTheme:[CPTheme themeNamed:defaultThemeName]];
}

+ (void)setDefaultTheme:(CPTheme)aTheme
{
    CPThemeDefaultTheme = aTheme;
}

+ (CPTheme)defaultTheme
{
    return CPThemeDefaultTheme;
}

+ (CPTheme)themeNamed:(CPString)aName
{
    return CPThemesByName[aName];
}

+ (void)loadThemesAtURL:(CPURL)aURL delegate:(id)aLoadDelegate
{
    
}

- (id)initWithName:(CPString)aName
{
    self = [super init];
    
    if (self)
    {
        _name = aName;
        _classTable = {};
        _classTable[[[self class] className]] = {};
        
        CPThemesByName[_name] = aName;
    }
    
    return self;
}

- (CPString)name
{
    return _name;
}

- (void)setActiveClass:(Class)aClass
{
    _activeClass = aClass;
}

- (Class)activeClass
{
    return _activeClass;
}

- (id)valueForAttributeName:(CPString)anAttributeName inClass:(CPClass)aClass
{
    if (!aClass)
        return nil;
    
    var className = [aClass className],
        table = _classTable[className];
    
    if (!table)
        return nil;
    
    var value = table[anAttributeName];
    
    if (!value)
        return nil;
    
    return value;
}

- (void)takeThemeFromObject:(id)anObject
{
    var attributes = [anObject _themedAttributes],
        attributeName = nil,
        attributeNames = [attributes keyEnumerator],
        objectClass = [anObject class];
        
    while (attributeName = [attributeNames nextObject])
        [self addValue:[attributes objectForKey:attributeName] forAttributeName:attributeName inClass:objectClass];
}

- (void)setDefaultValue:(id)aValue forAttributeName:(CPString)anAttributeName
{
    [self addValue:aValue forAttributeName:anAttributeName inClass:[self class]];
}

- (void)addValue:(id)aValue forAttributeName:(CPString)anAttributeName inClass:(Class)aClass
{
    if (!aValue)
        return;
    
    var className = [aClass className],
        table = _classTable[className];
        
    if (!table)
    {
        var classNames = [];
        
        while (!table && (aClass !== CPThemeViewClass) && (aClass !== CPThemeWindowClass))
        {            
            classNames.push(className);
            
            aClass = [aClass superclass];
            className = [aClass className];
            table = _classTable[className];
        }
        
        if (!table)
            table = _classTable[[[self class] className]];
        
        var count = [classNames count];
        
        while (count--)
        {
            className = classNames[count];
            
            _classTable[className] = {};
            _classTable[className].prototype = table;
            
            table = _classTable[className];
        }
    }

    var existingAttribute = table[anAttributeName];

    if (existingAttribute)
        table[anAttributeName] = [existingAttribute themedAttributeMergedWithThemedAttribute:aValue];
    else
        table[anAttributeName] = aValue;
}

@end

var CPThemeNameKey              = @"CPThemeNameKey",         
    CPThemeClassNamesArrayKey   = @"CPThemeClassNamesArrayKey";

@implementation CPTheme (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    _name = [aCoder decodeObjectForKey:CPThemeNameKey];
    _classTable = {};
    
    CPThemesByName[_name] = self;
    
    if (self)
    {
        var classNamesArray = [aCoder decodeObjectForKey:CPThemeClassNamesArrayKey],
            count = classNamesArray.length;
        
        while (count--)
        {
            var className = classNamesArray[count],
                theClass = objj_getClass(className),
                values = [aCoder decodeObjectForKey:className],
                keys = [values allKeys],
                keyCount = keys.length;
                
            while (keyCount--)
            {
                var key = keys[keyCount];
                
                [self addValue:[values objectForKey:key] forAttributeName:key inClass:theClass];
            }
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    var classNamesArray = [];
    
    for (var className in _classTable)
    {
        if (_classTable.hasOwnProperty(className))
        {
            var values = _classTable[className],
                valuesDictionary = [CPDictionary dictionary];
            
            for (var key in values)
                if (key !== "prototype" && values.hasOwnProperty(key))
                    [valuesDictionary setObject:values[key] forKey:key];
            
            [aCoder encodeObject:valuesDictionary forKey:className];
            
            classNamesArray.push(className);
        }
    }
    
    [aCoder encodeObject:_name forKey:CPThemeNameKey];
    [aCoder encodeObject:classNamesArray forKey:CPThemeClassNamesArrayKey];
}

@end

@implementation _CPThemeKeyedUnarchiver : CPKeyedUnarchiver
{
    CPBundle    _bundle;
}

- (id)initForReadingWithData:(CPData)data bundle:(CPBundle)aBundle
{
    self = [super initForReadingWithData:data];
    
    if (self)
        _bundle = aBundle;
    
    return self;
}

- (CPBundle)bundle
{
    return _bundle;
}

@end
