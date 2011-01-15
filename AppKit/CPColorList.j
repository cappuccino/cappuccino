/*
 * CPColorList.j
 * AppKit
 *
 * Created by Stephen Paul Ierodiaconou
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

@import "CPColor.j"

@import <Foundation/CPArray.j>
@import <Foundation/CPBundle.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPException.j>
@import <Foundation/CPNotificationCenter.j>
@import <Foundation/CPObject.j>
@import <Foundation/CPPropertyListSerialization.j>
@import <Foundation/CPString.j>
@import <Foundation/CPURLConnection.j>
@import <Foundation/CPURLRequest.j>

// CPColorListDidChangeNotification : when a color list changes. The notification object is the NSColorList object that changed. This notification does not contain a userInfo dictionary.
CPColorListDidChangeNotification = @"ColorListDidChangeNotification";

CPColorListNotEditableException = @"CPColorListNotEditableException";

/*!
    @class CPColorList
    @ingroup appkit
    @brief A named ordered list of named color objects.

    Default color lists specified in (AppKit bundle)/Colors/lists.plist
    App specific lists specified in (App main bundle)/Colors/lists.plist

    In Cocoa:
    - Cocoa loads bundles from /System/Library/Colors/*.clr, ~/Library/Colors/*.clr in at least 2 formats, a text file format and a archived format
    - Color bundles are loaded lazily if from file system
    - Cocoa seems to have built in color list of 'Web Safe Colors' which is always loaded n ready to go
    - Cocoa clr bundles have localisation

    In Cappuccino:
    - color lists are either directly stored or referenced in the "<bundle path>Colors/lists.plist" file
    - if not directly stored in the plist color plists are loaded lazily
    - the color bundle plists are in 280north or XML plist format
    - each plist color bundle can have multiple color lists named with unique names
    - removeFile and the file writing part of writeToFile:path are not implemented by default

    FIXME: lists will need localisation support for color keys eventually
*/
@implementation CPColorList : CPObject
{
    CPString        _path;
    CPDictionary    _colors;
    CPArray         _keys;
    CPString        _name;
    BOOL            _editable;
    BOOL            _loaded;
}

/*!
    Returns an array of \c CPColorList found on the framework and application
    color list search paths. The actual color lists are not loaded if they
    reference an external file, they are loaded lazily as needed.
    The Default color lists are specified in \e (AppKit bundle)/Colors/lists.plist.
    The App specific lists are specified in \e (App main bundle)/Colors/lists.plist.
    These files are loaded using synchronous (blocking) requests.
    NOTE: This method does not return color lists created programatically unless
    they have somehow been saved to either of these color list search locations.
    @return an array of CPColorList objects of all the lists found on the standard search paths
*/
+ (CPArray)availableColorLists
{
    // search app default and system folders and return list names
    var allcolorlists = [CPArray array],
        allcolorlistkeys = [CPArray array],
        appkitbundle = [CPBundle bundleForClass:[CPColorList class]],
        appbundle = [CPBundle mainBundle];

    [CPColorList _loadAvailableColorLists:allcolorlists keys:allcolorlistkeys fromBundle:appbundle];
    [CPColorList _loadAvailableColorLists:allcolorlists keys:allcolorlistkeys fromBundle:appkitbundle];

    return allcolorlists;
}

/*!
    @ignore
*/
+ (CPArray)_loadAvailableColorLists:(CPArray)colorlists keys:(CPArray)colorlistkeys fromBundle:(CPBundle)bundle
{
    var plist = [CPURLConnection sendSynchronousRequest:[CPURLRequest requestWithURL:[bundle pathForResource:@"Colors/lists.plist"]] returningResponse:nil],
        lists = [CPPropertyListSerialization propertyListFromData:plist format:CPPropertyListXMLFormat_v1_0],
        keys = [lists keyEnumerator],
        key;

    while (key = [keys nextObject])
    {
        var object = [lists objectForKey:key];

        if ([object isKindOfClass:[CPArray class]])
        {
            var count = [object count],
                i = 0;

            for (; i < count; i++)
            {
                var colorlistname = [object objectAtIndex:i];
                if (![colorlistkeys containsObject:colorlistname])
                {
                    [colorlists addObject:[[CPColorList alloc] initWithName:colorlistname
                                                                   fromFile:[bundle pathForResource:@"Colors/" + key]]];
                    [colorlistkeys addObject:colorlistname];
                }
            }
        }
        else if ([object isKindOfClass:[CPDictionary class]] || [object isKindOfClass:[CPMutableDictionary class]])
        {
            if (![colorlistkeys containsObject:key])
            {
                [colorlists addObject:[[CPColorList alloc] _initWithName:key fromPlistObject:object]];
                [colorlistkeys addObject:key];
            }
        }
    }
}

/*!
    Returns a new CPColorList initialised with the color list named \c aName
    from the standard search paths.
    @param the string name of the color list to load
    @return the new CPColorList with name \c aName or \e nil if it cannot be found
*/
+ (CPColorList)colorListNamed:(CPString)aName
{
    // return list with name, (note name does not include any file suffix)
    // nil if not available
    var colorlists = [CPColorList availableColorLists],
        i = 0,
        count = [colorlists count];

    for (; i < count; i++)
    {
        if ([aName compare:[[colorlists objectAtIndex:i] name]] == CPOrderedSame)
            return [colorlists objectAtIndex:i];
    }

    return nil;
}

/*!
    Initialises the receiver object with given name \c name. It does not attempt to
    load from the color list paths or check if there is another list with the
    same name in the color list paths. Calls \c initWithName:fromFile: with \c path
    equals to \e nil.
    @param name the name of list
*/
- (id)initWithName:(CPString)name
{
    return [self initWithName:name fromFile:nil];
}

/*!
    Initialises the receiving color list with the named list \c name from the file
    \c path. If \c path is \e nil then a new color list object is created. If \c path
    is a color list plist then this is used as the list source. However, note that the
    actual file is not loaded until a request is made to read or write the colors of
    the list. The file is retrieved lazily as a synchronous request. This is a
    blocking operation.
    @param name the name of the list. Should be unique if \c path is \e nil, or the name of a color list in the file pointed to by \c path
    @param path the path to the color list plist file
    @return the initialised CPColorList
*/
- (id)initWithName:(CPString)name fromFile:(CPString)path
{
    self = [super init];

    if (self)
    {
        _loaded = YES;
        _name = name;
        _colors = [CPDictionary dictionary];
        _keys = [];

        if (path === nil)
        {
            _editable = YES;
            _path = "";
        }
        else
        {
            // FIXME: actually here Cocoa returns nil if the name doesnt match the path.
            // However to check this we cant load lazily.
            _editable = NO;
            _path = path;
            _loaded = NO;
        }
    }

    return self;
}

// Internal, creates a ColorList from a Cappuccino Color List PList
/*!
    @ignore
*/
- (id)_initWithName:(CPString)name fromPlistObject:(CPDictionary)plist
{
    self = [self initWithName:name fromFile:nil];
    _loaded = YES;
    [self _parsePlistObject:plist];
    return self;
}

// Lazy load
/*!
    @ignore
*/
- (id)_loadColorList
{
    var plist = [CPURLConnection sendSynchronousRequest:[CPURLRequest requestWithURL:_path] returningResponse:nil],
        lists = [CPPropertyListSerialization propertyListFromData:plist format:CPPropertyListXMLFormat_v1_0];

    // Cocoa returns nil if 'name' does not exist in given color bundle
    if (![lists containsKey:_name])
        return nil;

    _loaded = YES;

    return [self _parsePlistObject:[lists objectForKey:_name]];
}

// Internal
/*!
    @ignore
*/
- (void)_parsePlistObject:(CPDictionary)plist
{
    // Mode/string, Names/langcode/dic(ckey,string), Keys/array/ckey, Colors/dic(ckey,array/rgba)

    // TODO: depending on current default locale load correct lang
    var strings = [[plist objectForKey:@"Names"] objectForKey:@"en"],
        keys = [plist objectForKey:@"Keys"],
        colors = [plist objectForKey:@"Colors"],
        mode = [plist objectForKey:@"Mode"],
        i = 0,
        count = [keys count];

    // create _keys & _colors
    for (; i < count; i++)
    {
        var key = [keys objectAtIndex:i],
            localisedkey = [strings objectForKey:key],
            colordata = [colors objectForKey:key],
            color;

        [_keys addObject:localisedkey];

        switch (mode)
        {
            case @"CSSSTR": color = [CPColor colorWithCSSString:colordata[0]];
                            break;
            case @"HEXSTR": color = [CPColor colorWithHexString:colordata[0]];
                            break;
            case @"HSBA":   color = [CPColor colorWithHue:colordata[0] saturation:colordata[1] brightness:colordata[2] alpha:colordata[3]];
                            break;
            case @"RGBA":
            default:        color = [CPColor colorWithRed:colordata[0] green:colordata[1] blue:colordata[2] alpha:colordata[3]];
                            break;
        }

        [_colors setObject:color forKey:localisedkey];
    }
}

/*!
    Returns the name of the CPColorList.
    @return the CPString name of the list.
*/
- (CPString)name
{
    return _name;
}

/*!
    Returns the CPColor object from the list with name \c key.
    @return the color object or \e nil if it doesn't exist
*/
- (CPColor)colorWithKey:(CPString)key
{
    if (!_loaded)
        [self _loadColorList];

    return [_colors objectForKey:key];
}

/*!
    Sets the CPColor object for the given name \c key. If the key
    already exists in the list then it is updated with the new color object.
    Posts \e CPColorListDidChangeNotification on success. If the key does
    not exist it is added to the end of the color list
    using \c -insertColor:key:atIndex:
    @throws CPColorListNotEditableException if the list is not editable
    @param color the color object to store
    @param key the color name or key string
*/
- (void)setColor:(CPColor)color forKey:(CPString)key
{
    if (!_editable)
        [CPException raise:CPColorListNotEditableException reason:@"setColor:forKey: CPColorList '" + [self name] + "' is not editable."]

    if (!_loaded)
        [self _loadColorList];

    if ([_keys containsObject:key])
    {
        [_colors setObject:color forKey:key];
        [[CPNotificationCenter defaultCenter] postNotificationName:CPColorListDidChangeNotification object:self];
    }
    else
        [self insertColor:color key:key atIndex:[_keys count]];
}

/*!
    Insert a color with name \c key at location \c location in the receiver color list.
    Posts \e CPColorListDidChangeNotification on success. If the key \c key already exists
    in the list it is first removed from that location.
    @throws CPColorListNotEditableException if the list is not editable
    @param color a color object to add
    @param key the name of the color
    @param location the point at which to insert the color in to the list
*/
- (void)insertColor:(CPColor)color key:(CPString)key atIndex:(unsigned)location
{
    if (!_editable)
        [CPException raise:CPColorListNotEditableException reason:@"insertColor:key:atIndex: CPColorList '" + [self name] + "' is not editable."]

    if (!_loaded)
        [self _loadColorList];

    if ([_keys containsObject:key])
    {
        [_colors removeObjectForKey:key];
        [_keys removeObject:key];
    }

    [_colors setObject:color forKey:key];
    [_keys insertObject:key atIndex:location];

    [[CPNotificationCenter defaultCenter] postNotificationName:CPColorListDidChangeNotification object:self];
}

/*!
    Remove a named color from the receiver color list, if it is editable.
    Posts \e CPColorListDidChangeNotification on success. If \c key does not
    exist in the color list then nothing happens.
    @throws CPColorListNotEditableException if the list is not editable
    @param key the key of the color to remove
*/
- (void)removeColorWithKey:(CPString)key
{
    if (!_editable)
        [CPException raise:CPColorListNotEditableException reason:@"removeColorWithKey: CPColorList '" + [self name] + "' is not editable."]

    if (!_loaded)
        [self _loadColorList];

    if ([_keys containsObject:key])
    {
        [_colors removeObjectForKey:key];
        [_keys removeObject:key];

        [[CPNotificationCenter defaultCenter] postNotificationName:CPColorListDidChangeNotification object:self];
    }
}

/*!
    Returns the names of all the colors in the CPColorList. The keys are ordered
    according to the order the colors are added to the color list.
    @return the color list CPString keys array
*/
- (CPArray)allKeys
{
    if (!_loaded)
        [self _loadColorList];

    return [_keys copy];
}

/*!
    Return if the list is editable. Lists created in memory (not from a source plist)
    are editable as are those that are writeable. Writing of color lists is not
    available by default however.
    @return true is the color list can be edited
*/
- (BOOL)isEditable
{
    return _editable;
}

/*!
    In Cocoa this is used to delete a color list from the file system. In
    Cappuccino it is unimplemented and must be overridden using a subclass or
    category if to be used.
*/
- (void)removeFile
{
    [CPException raise:CPUnsupportedMethodException
                reason:@"removeFile: User should implement this method if appropriate."];
}

/*!
    In Cocoa this is used to write a color list to the file system. In
    Cappuccino it is unimplemented and must be overridden using a subclass or
    category if to be used.
    If implemented user should set _editable accordingly.
*/
- (BOOL)writeToFile:(CPString)path
{
    [CPException raise:CPUnsupportedMethodException reason:@"writeToFile: User should implement this method if appropriate. Remember to set _editable accordingly if you do so."];
}

/*!
    Formatted string output of a CPColorList object. This does not include the actual colors.
    @return the description string
*/
- (CPString)description
{
    return @"" + [self class] + " name:" + _name + " {path:" + _path + " loaded:" + _loaded + " editable:" + _editable + " colorcount:" + [_colors count] + "}";
}

@end

// CPCoding support

var CPColorListLoadedKey    = @"CPColorListLoadedKey",
    CPColorListEditableKey  = @"CPColorListEditableKey",
    CPColorListNameKey      = @"CPColorListNameKey",
    CPColorListKeysKey      = @"CPColorListKeysKey",
    CPColorListColorsKey    = @"CPColorListColorsKey",
    CPColorListPathKey      = @"CPColorListPathKey";

@implementation CPColorList (CPCoding)

/*!
    For use during object unarchiving.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [self initWithName:@""];

    if (self)
    {
        _name       = [aCoder decodeObjectForKey:CPColorListNameKey];
        _editable   = [aCoder decodeBoolForKey:CPColorListEditableKey];
        _loaded     = [aCoder decodeBoolForKey:CPColorListLoadedKey];
        _path       = [aCoder decodeObjectForKey:CPColorListPathKey];
        if (_loaded)
        {
            _colors     = [aCoder decodeObjectForKey:CPColorListColorsKey];
            _keys       = [aCoder decodeObjectForKey:CPColorListKeysKey];
        }
    }

    return self;
}

/*!
    For use during object archiving
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_name forKey:CPColorListNameKey];
    [aCoder encodeBool:_editable forKey:CPColorListEditableKey];
    [aCoder encodeBool:_loaded forKey:CPColorListEditableKey];
    [aCoder encodeObject:_path forKey:CPColorListPathKey];
    if (_loaded)
    {
        [aCoder encodeObject:_colors forKey:CPColorListColorsKey];
        [aCoder encodeObject:_keys forKey:CPColorListKeysKey];
    }
}

@end
