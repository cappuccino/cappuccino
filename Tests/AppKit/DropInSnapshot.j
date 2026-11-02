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

/*
 The getters that report a BOOL, and the getters that report a view's content.
 */
var DropInBooleanGetters = [
    @"acceptsFirstResponder",
    @"drawsBackground",
    @"isBordered",
    @"isEditable",
    @"isEnabled",
    @"isHidden",
    @"isSelectable"
],

DropInContentGetters = [
    @"color",
    @"doubleValue",
    @"indexOfSelectedItem",
    @"maxValue",
    @"minValue",
    @"numberOfColumns",
    @"numberOfItems",
    @"numberOfTabViewItems",
    @"objectValue",
    @"segmentCount",
    @"state",
    @"string",
    @"stringValue",
    @"tag",
    @"title"
];

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
        /*
         A date is recorded by its instant in UTC. Its description is in the time zone
         of the machine that runs the test, so it differs between machines.
         */
        if ([aValue isKindOfClass:[CPDate class]])
            return "CPDate:" + (isNaN(aValue.getTime()) ? "invalid" : aValue.toISOString());

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
 Lists the public views below a view, in order. A private view is the class's own
 concern and is left out, but the public views inside it are the view's content.
 An observed view has a generated isa, so its name comes from its class method.
 */
function DropInPublicSubviews(aView)
{
    return [aView subviews].reduce(function(aList, aSubview)
    {
        return aList.concat(DropInIsPublicName([aSubview className]) ? [aSubview] : DropInPublicSubviews(aSubview));
    }, []);
}

/*
 Describes the state of one view. An unset BOOL is nil and means NO, so a BOOL is
 recorded by its truth value.
 */
function DropInViewTreeState(aView)
{
    var state = {};

    DropInConstructionGetters.concat(DropInContentGetters).forEach(function(aGetter)
    {
        var selector = CPSelectorFromString(aGetter);

        if (![aView respondsToSelector:selector])
            return;

        var value = [aView performSelector:selector];

        /*
         A control that holds a date gives its string value in the time zone of the
         machine that runs the test, because the browser formats it, not Cappuccino. It
         is recorded by the date's instant instead, so that every machine records the
         same snapshot.
         */
        if (aGetter === @"stringValue" && [aView respondsToSelector:@selector(objectValue)] && [[aView objectValue] isKindOfClass:[CPDate class]])
            value = [aView objectValue];

        state[aGetter] = DropInDescribeValue(DropInBooleanGetters.indexOf(aGetter) !== -1 ? !!value : value);
    });

    return state;
}

/*
 Describes a view and everything public below it.
 */
function DropInViewTree(aView)
{
    return {
        @"class": [aView className],
        @"frame": DropInDescribeValue([aView frame]),
        @"state": DropInViewTreeState(aView),
        @"subviews": DropInPublicSubviews(aView).map(function(aSubview)
        {
            return DropInViewTree(aSubview);
        })
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
 A scroll view takes its scroller style from a global setting, and that style changes
 the frames and views inside it. Applications and tests change the setting, so a
 description that is saved or compared is always made with the same style.
 */
function DropInWithFixedScrollerStyle(aFunction)
{
    var scrollerStyle = [CPScrollView globalScrollerStyle];

    [CPScrollView setGlobalScrollerStyle:CPScrollerStyleLegacy];

    try
    {
        return aFunction();
    }
    finally
    {
        [CPScrollView setGlobalScrollerStyle:scrollerStyle];
    }
}

/*
 Loads a cib and describes its top level objects, sorted so that the order in
 which the cib lists them does not matter. Layout changes frames and adds subviews,
 so it is complete before anything is described.
 */
function DropInCibTree(aCibName, aRawString)
{
    var topLevelObjects = [],
    cib = [[CPCib alloc] _initWithData:[CPData dataWithRawString:aRawString] bundle:nil cibName:aCibName];

    return DropInWithFixedScrollerStyle(function()
    {
        [cib instantiateCibWithExternalNameTable:@{ CPCibOwner: [[_DropInCibOwner alloc] init], CPCibTopLevelObjects: topLevelObjects }];
        [_CPDisplayServer run];

        return topLevelObjects.map(DropInObjectTree).map(function(aTree)
                                                         {
            return JSON.stringify(aTree);
        }).sort();
    });
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
