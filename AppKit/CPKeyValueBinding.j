/*
 * CPKeyValueBinding.j
 * AppKit
 *
 * Created by Ross Boucher 1/13/09
 * Copyright 280 North, Inc.
 *
 * Adapted from GNUStep
 * Released under the LGPL.
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
@import <Foundation/CPArray.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPValueTransformer.j>


var exposedBindingsMap = [CPDictionary new],
    bindingsMap = [CPDictionary new];

var CPBindingOperationAnd = 0,
    CPBindingOperationOr  = 1;

@implementation CPBinder : CPObject
{
    CPDictionary    _info;
    id              _source;

    JSObject        _suppressedNotifications;
    JSObject        _placeholderForMarker;
}

+ (void)exposeBinding:(CPString)aBinding forClass:(Class)aClass
{
    var bindings = [exposedBindingsMap objectForKey:[aClass UID]];

    if (!bindings)
    {
        bindings = [];
        [exposedBindingsMap setObject:bindings forKey:[aClass UID]];
    }

    bindings.push(aBinding);
}

+ (CPArray)exposedBindingsForClass:(Class)aClass
{
    return [[exposedBindingsMap objectForKey:[aClass UID]] copy];
}

+ (CPBinder)getBinding:(CPString)aBinding forObject:(id)anObject
{
    return [[bindingsMap objectForKey:[anObject UID]] objectForKey:aBinding];
}

+ (CPDictionary)infoForBinding:(CPString)aBinding forObject:(id)anObject
{
    var theBinding = [self getBinding:aBinding forObject:anObject];

    if (theBinding)
        return theBinding._info;

    return nil;
}

+ (CPDictionary)allBindingsForObject:(id)anObject
{
    return [bindingsMap objectForKey:[anObject UID]];
}

+ (void)unbind:(CPString)aBinding forObject:(id)anObject
{
    var bindings = [bindingsMap objectForKey:[anObject UID]];

    if (!bindings)
        return;

    var theBinding = [bindings objectForKey:aBinding];

    if (!theBinding)
        return;

    var infoDictionary = theBinding._info,
        observedObject = [infoDictionary objectForKey:CPObservedObjectKey],
        keyPath = [infoDictionary objectForKey:CPObservedKeyPathKey];

    [observedObject removeObserver:theBinding forKeyPath:keyPath];
    [bindings removeObjectForKey:aBinding];
}

+ (void)unbindAllForObject:(id)anObject
{
    var bindings = [bindingsMap objectForKey:[anObject UID]];
    if (!bindings)
        return;

    var allKeys = [bindings allKeys],
        count = allKeys.length;

    while (count--)
        [anObject unbind:[bindings objectForKey:allKeys[count]]];

    [bindingsMap removeObjectForKey:[anObject UID]];
}

- (id)initWithBinding:(CPString)aBinding name:(CPString)aName to:(id)aDestination keyPath:(CPString)aKeyPath options:(CPDictionary)options from:(id)aSource
{
    self = [super init];

    if (self)
    {
        _source = aSource;
        _info   = [CPDictionary dictionaryWithObjects:[aDestination, aKeyPath] forKeys:[CPObservedObjectKey, CPObservedKeyPathKey]];
        _suppressedNotifications = {};
        _placeholderForMarker = {};

        if (options)
            [_info setObject:options forKey:CPOptionsKey];

        [self _updatePlaceholdersWithOptions:options];

        [aDestination addObserver:self forKeyPath:aKeyPath options:CPKeyValueObservingOptionNew context:aBinding];

        var bindings = [bindingsMap objectForKey:[_source UID]];
        if (!bindings)
        {
            bindings = [CPDictionary new];
            [bindingsMap setObject:bindings forKey:[_source UID]];
        }

        [bindings setObject:self forKey:aName];
        [self setValueFor:aBinding];
    }

    return self;
}

- (void)setValueFor:(CPString)theBinding
{
    var destination = [_info objectForKey:CPObservedObjectKey],
        keyPath = [_info objectForKey:CPObservedKeyPathKey],
        options = [_info objectForKey:CPOptionsKey],
        newValue = [destination valueForKeyPath:keyPath],
        isPlaceholder = CPIsControllerMarker(newValue);

    if (isPlaceholder)
    {
        if (newValue === CPNotApplicableMarker && [options objectForKey:CPRaisesForNotApplicableKeysBindingOption])
        {
           [CPException raise:CPGenericException
                       reason:@"Cannot transform non-applicable key on: " + _source + " key path: " + keyPath + " value: " + newValue];
        }

        var value = [self _placeholderForMarker:newValue];
        [self setPlaceholderValue:value withMarker:newValue forBinding:theBinding];
    }
    else
    {
        var value = [self transformValue:newValue withOptions:options];
        [self setValue:value forBinding:theBinding];
    }
}

- (void)setPlaceholderValue:(id)aValue withMarker:(CPString)aMarker forBinding:(CPString)aBinding
{
    [_source setValue:aValue forKey:aBinding];
}

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    [_source setValue:aValue forKey:aBinding];
}

- (void)reverseSetValueFor:(CPString)aBinding
{
    var destination = [_info objectForKey:CPObservedObjectKey],
        keyPath = [_info objectForKey:CPObservedKeyPathKey],
        options = [_info objectForKey:CPOptionsKey],
        newValue = [self valueForBinding:aBinding];

    newValue = [self reverseTransformValue:newValue withOptions:options];

    [self suppressSpecificNotificationFromObject:destination keyPath:keyPath];
    [destination setValue:newValue forKeyPath:keyPath];
    [self unsuppressSpecificNotificationFromObject:destination keyPath:keyPath];
}

- (id)valueForBinding:(CPString)aBinding
{
    return [_source valueForKeyPath:aBinding];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)context
{
    if (!changes)
        return;

    var objectSuppressions = _suppressedNotifications[[anObject UID]];
    if (objectSuppressions && objectSuppressions[aKeyPath])
        return;

    [self setValueFor:context];
}

- (id)transformValue:(id)aValue withOptions:(CPDictionary)options
{
    var valueTransformerName = [options objectForKey:CPValueTransformerNameBindingOption],
        valueTransformer;

    if (valueTransformerName)
    {
        valueTransformer = [CPValueTransformer valueTransformerForName:valueTransformerName];

        if (!valueTransformer)
        {
            var valueTransformerClass = CPClassFromString(valueTransformerName);
            if (valueTransformerClass)
            {
                valueTransformer = [[valueTransformerClass alloc] init];
                [valueTransformerClass setValueTransformer:valueTransformer forName:valueTransformerName];
            }
        }
    }
    else
        valueTransformer = [options objectForKey:CPValueTransformerBindingOption];

    if (valueTransformer)
        aValue = [valueTransformer transformedValue:aValue];

    if (aValue === undefined || aValue === nil || aValue === [CPNull null])
        aValue = [options objectForKey:CPNullPlaceholderBindingOption] || nil;

    return aValue;
}

- (id)reverseTransformValue:(id)aValue withOptions:(CPDictionary)options
{
    var valueTransformerName = [options objectForKey:CPValueTransformerNameBindingOption],
        valueTransformer;

    if (valueTransformerName)
        valueTransformer = [CPValueTransformer valueTransformerForName:valueTransformerName];
    else
        valueTransformer = [options objectForKey:CPValueTransformerBindingOption];

    if (valueTransformer && [[valueTransformer class] allowsReverseTransformation])
        aValue = [valueTransformer reverseTransformedValue:aValue];

    return aValue;
}

- (BOOL)continuouslyUpdatesValue
{
    var options = [_info objectForKey:CPOptionsKey];
    return [[options objectForKey:CPContinuouslyUpdatesValueBindingOption] boolValue];
}

- (BOOL)handlesContentAsCompoundValue
{
    var options = [_info objectForKey:CPOptionsKey];
    return [[options objectForKey:CPHandlesContentAsCompoundValueBindingOption] boolValue];
}

/*!
    Use this to avoid reacting to the notifications coming out of a reverseTransformedValue:.
*/
- (void)suppressSpecificNotificationFromObject:(id)anObject keyPath:(CPString)aKeyPath
{
    if (!anObject)
        return;

    var uid = [anObject UID],
        objectSuppressions = _suppressedNotifications[uid];
    if (!objectSuppressions)
        _suppressedNotifications[uid] = objectSuppressions = {};

    objectSuppressions[aKeyPath] = YES;
}

/*!
    Use this to cancel suppressSpecificNotificationFromObject:keyPath:.
*/
- (void)unsuppressSpecificNotificationFromObject:(id)anObject keyPath:(CPString)aKeyPath
{
    if (!anObject)
        return;

    var uid = [anObject UID],
        objectSuppressions = _suppressedNotifications[uid];
    if (!objectSuppressions)
        return;

    delete objectSuppressions[aKeyPath];
}

- (void)_updatePlaceholdersWithOptions:(CPDictionary)options
{
    var count = [CPBinderPlaceholderMarkers count];

    while (count--)
    {
        var marker = CPBinderPlaceholderMarkers[count],
            optionName = CPBinderPlaceholderOptions[count],
            isExplicit = [options containsKey:optionName],
            placeholder = isExplicit ? [options objectForKey:optionName] : nil;
        [self _setPlaceholder:placeholder forMarker:marker isDefault:!isExplicit];
    }
}

- (void)_placeholderForMarker:aMarker
{
    var placeholder = _placeholderForMarker[aMarker];
    if (placeholder)
        return placeholder['value'];
    return nil;
}

- (void)_setPlaceholder:(id)aPlaceholder forMarker:(id)aMarker isDefault:(BOOL)isDefault
{
    if (isDefault)
    {
        var existingPlaceholder = _placeholderForMarker[aMarker];

        // Don't overwrite an explicitly set placeholder with a default.
        if (existingPlaceholder && !existingPlaceholder['isDefault'])
            return;
    }

    _placeholderForMarker[aMarker] = { 'isDefault': isDefault, 'value': aPlaceholder };
}

@end

@implementation CPObject (KeyValueBindingCreation)

+ (void)exposeBinding:(CPString)aBinding
{
    [CPBinder exposeBinding:aBinding forClass:[self class]];
}

+ (Class)_binderClassForBinding:(CPString)theBinding
{
    return [CPBinder class];
}

- (CPArray)exposedBindings
{
    var exposedBindings = [],
        theClass = [self class];

    while (theClass)
    {
        var temp = [CPBinder exposedBindingsForClass:theClass];

        if (temp)
            [exposedBindings addObjectsFromArray:temp];

        theClass = [theClass superclass];
    }

    return exposedBindings;
}

- (Class)valueClassForBinding:(CPString)binding
{
    return [CPString class];
}

- (void)bind:(CPString)aBinding toObject:(id)anObject withKeyPath:(CPString)aKeyPath options:(CPDictionary)options
{
    if (!anObject || !aKeyPath)
        return CPLog.error("Invalid object or path on " + self + " for " + aBinding);

    //if (![[self exposedBindings] containsObject:aBinding])
    //    CPLog.warn("No binding exposed on " + self + " for " + aBinding);

    var binderClass = [[self class] _binderClassForBinding:aBinding];

    [self unbind:aBinding];
    [[binderClass alloc] initWithBinding:[self _replacementKeyPathForBinding:aBinding] name:aBinding to:anObject keyPath:aKeyPath options:options from:self];
}

- (CPDictionary)infoForBinding:(CPString)aBinding
{
    return [CPBinder infoForBinding:aBinding forObject:self];
}

- (void)unbind:(CPString)aBinding
{
    var binderClass = [[self class] _binderClassForBinding:aBinding];
    [binderClass unbind:aBinding forObject:self];
}

- (id)_replacementKeyPathForBinding:(CPString)binding
{
    return binding;
}

@end

/*!
    @ignore
    Provides stub implementations that simply call super for the "objectValue" binding
    This class should not be necessary but assures backwards compliance with our old way of doing bindings
    Every class with a value binding should implement a subclass to handle it's specific value binding logic
*/
@implementation _CPValueBinder : CPBinder
{
}

- (void)setValueFor:(CPString)theBinding
{
    [super setValueFor:@"objectValue"];
}

- (void)reverseSetValueFor:(CPString)theBinding
{
    [super reverseSetValueFor:@"objectValue"];
}

@end

@implementation _CPKeyValueOrBinding : CPBinder
{
}

- (void)setValueFor:(CPString)aBinding
{
    var bindings = [bindingsMap valueForKey:[_source UID]];

    if (!bindings)
        return;

    [_source setValue:resolveMultipleValues(aBinding, bindings, CPBindingOperationOr) forKey:aBinding];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)context
{
    [self setValueFor:context];
}

@end

@implementation _CPKeyValueAndBinding : CPBinder
{
}

- (void)setValueFor:(CPString)aBinding
{
    var bindings = [bindingsMap objectForKey:[_source UID]];

    if (!bindings)
        return;

    [_source setValue:resolveMultipleValues(aBinding, bindings, CPBindingOperationAnd) forKey:aBinding];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObejct change:(CPDictionary)changes context:(id)context
{
    [self setValueFor:context];
}

@end

var resolveMultipleValues = function(/*CPString*/key, /*CPDictionary*/bindings, /*GSBindingOperationKind*/operation)
{
    var bindingName = key,
        theBinding,
        count = 1;

    while (theBinding = [bindings objectForKey:bindingName])
    {
        var infoDictionary = theBinding._info,
            object  = [infoDictionary objectForKey:CPObservedObjectKey],
            keyPath = [infoDictionary objectForKey:CPObservedKeyPathKey],
            options = [infoDictionary objectForKey:CPOptionsKey];

        var value = [theBinding transformValue:[object valueForKeyPath:keyPath] withOptions:options];

        if (value == operation)
            return operation;

        bindingName = [CPString stringWithFormat:@"%@%i", key, ++count];
    }

    return !operation;
};

var invokeAction = function(/*CPString*/targetKey, /*CPString*/argumentKey, /*CPDictionary*/bindings)
{
    var theBinding = [bindings objectForKey:targetKey],
        infoDictionary = theBinding._info,

        object   = [infoDictionary objectForKey:CPObservedObjectKey],
        keyPath  = [infoDictionary objectForKey:CPObservedKeyPathKey],
        options  = [infoDictionary objectForKey:CPOptionsKey],

        target   = [object valueForKeyPath:keyPath],
        selector = [options objectForKey:CPSelectorNameBindingOption];

    if (!target || !selector)
        return;

    var invocation = [CPInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
    [invocation setSelector:selector];

    var bindingName = argumentKey,
        count = 1;

    while (theBinding = [bindings objectForKey:bindingName])
    {
        infoDictionary = theBinding._info;

        keyPath = [infoDictionary objectForKey:CPObserverKeyPathKey];
        object  = [[infoDictionary objectForKey:CPObservedObjectKey] valueForKeyPath:keyPath];

        if (object)
            [invocation setArgument:object atIndex:++count];

        bindingName = [CPString stringWithFormat:@"%@%i", argumentKey, count];
    }

    [invocation invoke];
};

// Keys in options dictionary

// Keys in dictionary returned by infoForBinding
CPObservedObjectKey     = @"CPObservedObjectKey";
CPObservedKeyPathKey    = @"CPObservedKeyPathKey";
CPOptionsKey            = @"CPOptionsKey";

// special markers
CPMultipleValuesMarker  = @"CPMultipleValuesMarker";
CPNoSelectionMarker     = @"CPNoSelectionMarker";
CPNotApplicableMarker   = @"CPNotApplicableMarker";
CPNullMarker            = @"CPNullMarker";

// Binding name constants
CPAlignmentBinding                        = @"alignment";
CPContentArrayBinding                     = @"contentArray";
CPContentBinding                          = @"content";
CPContentObjectBinding                    = @"contentObject";
CPContentObjectsBinding                   = @"contentObjects";
CPContentValuesBinding                    = @"contentValues";
CPEditableBinding                         = @"editable";
CPEnabledBinding                          = @"enabled";
CPFontBinding                             = @"font";
CPFontNameBinding                         = @"fontName";
CPFontBoldBinding                         = @"fontBold";
CPHiddenBinding                           = @"hidden";
CPFilterPredicateBinding                  = @"filterPredicate";
CPPredicateBinding                        = @"predicate";
CPSelectedIndexBinding                    = @"selectedIndex";
CPSelectedLabelBinding                    = @"selectedLabel";
CPSelectedObjectBinding                   = @"selectedObject";
CPSelectedObjectsBinding                  = @"selectedObjects";
CPSelectedTagBinding                      = @"selectedTag";
CPSelectedValueBinding                    = @"selectedValue";
CPSelectedValuesBinding                   = @"selectedValues";
CPSelectionIndexesBinding                 = @"selectionIndexes";
CPTextColorBinding                        = @"textColor";
CPTitleBinding                            = @"title";
CPToolTipBinding                          = @"toolTip";
CPValueBinding                            = @"value";
CPValueURLBinding                         = @"valueURL";
CPValuePathBinding                        = @"valuePath";
CPDataBinding                             = @"data";

//Binding options constants
CPAllowsEditingMultipleValuesSelectionBindingOption = @"CPAllowsEditingMultipleValuesSelection";
CPAllowsNullArgumentBindingOption                   = @"CPAllowsNullArgument";
CPConditionallySetsEditableBindingOption            = @"CPConditionallySetsEditable";
CPConditionallySetsEnabledBindingOption             = @"CPConditionallySetsEnabled";
CPConditionallySetsHiddenBindingOption              = @"CPConditionallySetsHidden";
CPContinuouslyUpdatesValueBindingOption             = @"CPContinuouslyUpdatesValue";
CPCreatesSortDescriptorBindingOption                = @"CPCreatesSortDescriptor";
CPDeletesObjectsOnRemoveBindingsOption              = @"CPDeletesObjectsOnRemove";
CPDisplayNameBindingOption                          = @"CPDisplayName";
CPDisplayPatternBindingOption                       = @"CPDisplayPattern";
CPHandlesContentAsCompoundValueBindingOption        = @"CPHandlesContentAsCompoundValue";
CPInsertsNullPlaceholderBindingOption               = @"CPInsertsNullPlaceholder";
CPInvokesSeparatelyWithArrayObjectsBindingOption    = @"CPInvokesSeparatelyWithArrayObjects";
CPMultipleValuesPlaceholderBindingOption            = @"CPMultipleValuesPlaceholder";
CPNoSelectionPlaceholderBindingOption               = @"CPNoSelectionPlaceholder";
CPNotApplicablePlaceholderBindingOption             = @"CPNotApplicablePlaceholder";
CPNullPlaceholderBindingOption                      = @"CPNullPlaceholder";
CPPredicateFormatBindingOption                      = @"CPPredicateFormat";
CPRaisesForNotApplicableKeysBindingOption           = @"CPRaisesForNotApplicableKeys";
CPSelectorNameBindingOption                         = @"CPSelectorName";
CPSelectsAllWhenSettingContentBindingOption         = @"CPSelectsAllWhenSettingContent";
CPValidatesImmediatelyBindingOption                 = @"CPValidatesImmediately";
CPValueTransformerNameBindingOption                 = @"CPValueTransformerName";
CPValueTransformerBindingOption                     = @"CPValueTransformer";

CPIsControllerMarker = function(/*id*/anObject)
{
    return anObject === CPMultipleValuesMarker || anObject === CPNoSelectionMarker || anObject === CPNotApplicableMarker || anObject === CPNullMarker;
};

var CPBinderPlaceholderMarkers = [CPMultipleValuesMarker, CPNoSelectionMarker, CPNotApplicableMarker, CPNullMarker],
    CPBinderPlaceholderOptions = [CPMultipleValuesPlaceholderBindingOption, CPNoSelectionPlaceholderBindingOption, CPNotApplicablePlaceholderBindingOption, CPNullPlaceholderBindingOption];

