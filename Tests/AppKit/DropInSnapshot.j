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

/*
    Reduces a value to a string that does not depend on object identity, so that
    two runs of the same framework produce the same snapshot.
*/
function DropInDescribeValue(aValue)
{
    if (aValue === nil || aValue === undefined)
        return "nil";

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

    if (typeof aValue === "object")
        return JSON.stringify(aValue);

    return String(aValue);
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

function DropInDefaultConstruction(aClass)
{
    var view = [[aClass alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)],
        result = {
            @"frameSize": DropInDescribeValue([view frameSize]),
            @"subviews": DropInSubviewClasses(view)
        };

    DropInConstructionGetters.forEach(function(aGetter)
    {
        if ([view respondsToSelector:CPSelectorFromString(aGetter)])
            result[aGetter] = DropInDescribeValue([view performSelector:CPSelectorFromString(aGetter)]);
    });

    return result;
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
*/
function DropInCreateSnapshot()
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
            snapshot.construction[name] = DropInDefaultConstruction(aClass);
        }
        catch (anException)
        {
        }
    });

    for (var style in DropInWindowStyles)
    {
        var aWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 400.0)
                                                  styleMask:DropInWindowStyles[style]];

        snapshot.windows[style] = DropInSubviewClasses([aWindow _windowView]);
    }

    return snapshot;
}
