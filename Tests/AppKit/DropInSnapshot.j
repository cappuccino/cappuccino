/*
 *  DropInSnapshot.j
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
 An application that updates its frameworks relies on more than documented
 behavior. It relies on the defaults a class supplies when no theme overrides
 them, on the public methods it calls and overrides, and on the state a control
 has when it is created. Together these form the drop-in contract.

 This file records that contract as plain data. DropInBaselineGenerator.j saves
 a snapshot as the baseline, and DropInBaselineTest.j compares the running
 frameworks with it. Additions are allowed. Changes and removals are not.
 */

var DropInConstructionGetters = [
    @"acceptsFirstResponder",
    @"alignment",
    @"autoresizingMask",
    @"backgroundColor",
    @"bezelStyle",
    @"controlSize",
    @"drawsBackground",
    @"isBordered",
    @"isEditable",
    @"isEnabled",
    @"isHidden",
    @"isSelectable",
    @"lineBreakMode",
    @"verticalAlignment"
],

DropInWindowStyles = {
    @"borderless":      CPBorderlessWindowMask,
    @"titled":          CPTitledWindowMask,
    @"closable":        CPClosableWindowMask,
    @"resizable":       CPClosableWindowMask | CPResizableWindowMask,
    @"miniaturizable":  CPClosableWindowMask | CPMiniaturizableWindowMask,
    @"full":            CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask,
    @"hud":             CPHUDBackgroundWindowMask,
    @"hudClosable":     CPHUDBackgroundWindowMask | CPClosableWindowMask
};

function DropInIsPublicName(aName)
{
    return aName.charAt(0) !== "_" && aName.charAt(0) !== "$";
}

function DropInSerializeObject(val, seen)
{
    if (val === null || val === undefined)
        return nil;

    if (typeof val === "function")
        return "[Function]";

    if (typeof val !== "object")
        return val;

    if (seen.indexOf(val) !== -1)
        return "[Circular]";

    seen.push(val);

    var result;

    if (Array.isArray(val))
    {
        result = [];
        for (var i = 0; i < val.length; i++)
        {
            result[i] = DropInSerializeObject(val[i], seen);
        }
    }
    else
    {
        result = {};
        var keys = Object.keys(val).sort();
        for (var i = 0; i < keys.length; i++)
        {
            var k = keys[i];
            result[k] = DropInSerializeObject(val[k], seen);
        }
    }

    seen.pop();

    return result;
}

function DropInSafeJSONStringify(aValue)
{
    return JSON.stringify(DropInSerializeObject(aValue, []));
}

/*
 Reduces a value to a string that does not depend on object identity, so that
 two runs of the same framework produce the same snapshot.
 */
function DropInDescribeValue(aValue)
{
    if (aValue === nil || aValue === undefined)
        return "nil";

    /*
     Booleans, numbers and strings answer to isa as well, so they must be handled
     first, or they are recorded by class and their values are never compared.
     */
    if (typeof aValue === "boolean" || typeof aValue === "number" || typeof aValue === "string")
        return String(aValue);

    if (aValue === [CPNull null])
        return "CPNull";

    if (aValue.isa)
    {
        if ([aValue isKindOfClass:[CPColor class]])
            return "CPColor:" + [aValue cssString];

        /*
         The system font is a global setting that applications and tests change,
         so a default that uses it records only that fact.
         */
        if ([aValue isKindOfClass:[CPFont class]])
            return [aValue isSystem] ? "CPFont:system" + ([aValue isBold] ? " bold" : "") : "CPFont:" + [aValue cssString];

        if ([aValue isKindOfClass:[CPArray class]])
            return "[" + aValue.map(DropInDescribeValue).join(", ") + "]";

        return aValue.isa.name;
    }

    return DropInSafeJSONStringify(aValue);
}

function DropInMethodNames(aClass)
{
    return class_copyMethodList(aClass).map(function(aMethod)
                                            {
        return method_getName(aMethod);
    }).filter(DropInIsPublicName).sort();
}

function DropInThemeAttributes(aClass)
{
    if (class_copyMethodList(aClass.isa).map(method_getName).indexOf("themeAttributes") === -1)
        return nil;

    var attributes = [aClass themeAttributes];

    if (!attributes)
        return nil;

    var result = {},
    keys = [[attributes allKeys] sortedArrayUsingSelector:@selector(compare:)];

    keys.forEach(function(aKey)
                 {
        result[aKey] = DropInDescribeValue([attributes objectForKey:aKey]);
    });

    return result;
}

function DropInSubviewClasses(aView)
{
    return [aView subviews].map(function(aSubview)
                                {
        return aSubview.isa.name;
    }).filter(DropInIsPublicName).sort();
}

function DropInViewState(aView, throwIfError)
{
    var result = {
        @"frameSize": DropInDescribeValue([aView frameSize]),
        @"subviews": DropInSubviewClasses(aView)
    };

    DropInConstructionGetters.forEach(function(aGetter)
                                      {
        var selector = CPSelectorFromString(aGetter);

        if ([aView respondsToSelector:selector])
        {
            try
            {
                result[aGetter] = DropInDescribeValue([aView performSelector:selector]);
            }
            catch (anException)
            {
                if (throwIfError)
                    throw anException;

                result[aGetter] = "[Exception: " + String(anException) + "]";
            }
        }
    });

    return result;
}

function DropInDefaultConstruction(aClass, throwIfError)
{
    return DropInViewState([[aClass alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)], throwIfError);
}

/*
 Describes a view and its public subviews, in order. Private views are left out,
 because they are the class's own concern.
 */
function DropInViewTree(aView)
{
    return {
        @"class": aView.isa.name,
        @"frame": DropInDescribeValue([aView frame]),
        @"subviews": [aView subviews].filter(function(aSubview)
                                             {
            return DropInIsPublicName(aSubview.isa.name);
        }).map(DropInViewTree)
    };
}

function DropInMenuTree(aMenu)
{
    return [aMenu itemArray].map(function(anItem)
                                 {
        return {
            @"title": [anItem title],
            @"keyEquivalent": [anItem keyEquivalent],
            @"submenu": [anItem hasSubmenu] ? DropInMenuTree([anItem submenu]) : nil
        };
    });
}

/*
 Describes what a cib produced. Objects other than windows, views and menus are
 recorded by class alone.
 */
function DropInObjectTree(anObject)
{
    if ([anObject isKindOfClass:[CPWindow class]])
        return { @"class": anObject.isa.name, @"title": [anObject title], @"contentView": DropInViewTree([anObject contentView]) };

    if ([anObject isKindOfClass:[CPView class]])
        return DropInViewTree(anObject);

    if ([anObject isKindOfClass:[CPMenu class]])
        return { @"class": anObject.isa.name, @"items": DropInMenuTree(anObject) };

    return { @"class": anObject.isa.name };
}

/*
 The owner of the reference cibs. It has the outlets and actions that those cibs
 connect to it, so that loading them gives no warnings.
 */
@implementation _DropInCibOwner : CPObject
{
    id  folderNameField;
    id  predicateEditor;
    id  predicateSheet;
    id  textView;
    id  window;
}

- (void)closeSheet:(id)aSender
{
}

@end

/*
 Loads a cib and describes its top level objects, sorted so that the order in
 which the cib lists them does not matter.

 A scroll view takes its scroller style from a global setting when it is decoded,
 and that style changes the frames inside it. Applications and tests change the
 setting, so each cib loads with the same style. Layout also changes frames and
 adds subviews, so it is complete before anything is described.
 */
function DropInCibTree(aCibName, aRawString)
{
    var topLevelObjects = [],
    cib = [[CPCib alloc] _initWithData:[CPData dataWithRawString:aRawString] bundle:nil cibName:aCibName],
    scrollerStyle = [CPScrollView globalScrollerStyle];

    [CPScrollView setGlobalScrollerStyle:CPScrollerStyleLegacy];

    try
    {
        [cib instantiateCibWithExternalNameTable:@{ CPCibOwner: [[_DropInCibOwner alloc] init], CPCibTopLevelObjects: topLevelObjects }];
        [_CPDisplayServer run];

        return topLevelObjects.map(DropInObjectTree).map(function(aTree)
                                                         {
            return JSON.stringify(aTree);
        }).sort();
    }
    finally
    {
        [CPScrollView setGlobalScrollerStyle:scrollerStyle];
    }
}

function DropInClassIsView(aClass)
{
    var viewClass = [CPView class];

    for (; aClass; aClass = class_getSuperclass(aClass))
        if (aClass === viewClass)
            return YES;

    return NO;
}

function DropInSortedClasses()
{
    var classes = [],
    count = objj_getClassList(classes, 1 << 16);

    return classes.slice(0, count).filter(function(aClass)
                                          {
        return aClass && aClass.name.indexOf("$") !== 0;
    }).sort(function(lhs, rhs)
            {
        return lhs.name < rhs.name ? -1 : (lhs.name > rhs.name ? 1 : 0);
    });
}

/*
 Some classes cannot be created without a surrounding object, or without a DOM.
 A class that cannot be created is left out of the construction section, and the
 comparison does not report it. This reduces coverage, but it cannot report a
 false difference.

 A generator passes throwIfError, so that a getter that throws is not saved as
 expected state, and passes skipped, to list each class or window style that is
 left out.
 */
function DropInCreateSnapshot(throwIfError, skipped)
{
    var snapshot = {
        @"publicClasses": [],
        @"themeAttributes": {},
        @"instanceMethods": {},
        @"classMethods": {},
        @"construction": {},
        @"windows": {}
    };

    DropInSortedClasses().forEach(function(aClass)
                                  {
        var name = aClass.name,
        isPublic = DropInIsPublicName(name);

        try
        {
            var attributes = DropInThemeAttributes(aClass);

            if (attributes)
                snapshot.themeAttributes[name] = attributes;
        }
        catch (anException)
        {
            if (skipped)
                skipped.push(name + " theme attributes: " + String(anException).slice(0, 80));
        }

        if (!isPublic)
            return;

        snapshot.publicClasses.push(name);
        snapshot.instanceMethods[name] = DropInMethodNames(aClass);
        snapshot.classMethods[name] = DropInMethodNames(aClass.isa);

        if (!DropInClassIsView(aClass))
            return;

        try
        {
            snapshot.construction[name] = DropInDefaultConstruction(aClass, throwIfError);
        }
        catch (anException)
        {
            if (skipped)
                skipped.push(name + " construction: " + String(anException).slice(0, 80));
        }
    });

    for (var style in DropInWindowStyles)
    {
        try
        {
            var aWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 400.0)
                                                      styleMask:DropInWindowStyles[style]];

            snapshot.windows[style] = DropInSubviewClasses([aWindow _windowView]);
        }
        catch (anException)
        {
            if (skipped)
                skipped.push(style + " window style: " + String(anException).slice(0, 80));
        }
    }

    return snapshot;
}
