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

@implementation CPKeyValueBinding : CPObject
{
    CPDictionary    _info;
    id              _source;
}

+ (void)exposeBinding:(CPString)aBinding forClass:(Class)aClass
{
    var bindings = [exposedBindingsMap objectForKey:[aClass hash]];

    if (!bindings)
    {
        bindings = [];
        [exposedBindingsMap setObject:bindings forKey:[aClass hash]];
    }

    bindings.push(aBinding);
}

+ (CPArray)exposedBindingsForClass:(Class)aClass
{
    return [[exposedBindingsMap objectForKey:[aClass hash]] copy];
}

+ (CPKeyValueBinding)getBinding:(CPString)aBinding forObject:(id)anObject
{
    return [[bindingsMap objectForKey:[anObject hash]] objectForKey:aBinding];
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
    return [bindingsMap objectForKey:[anObject hash]];
}

+ (void)unbind:(CPString)aBinding forObject:(id)anObject
{
    var bindings = [bindingsMap objectForKey:[anObject hash]];

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
    var bindings = [bindingsMap objectForKey:[anObject hash]];
    if (!bindings)
        return;

    var allKeys = [bindings allKeys],
        count = allKeys.length;

    while (count--)
        [anObject unbind:[bindings objectForKey:allKeys[count]]];

    [bindingsMap removeObjectForKey:[anObject hash]];
}

- (id)initWithBinding:(CPString)aBinding name:(CPString)aName to:(id)aDestination keyPath:(CPString)aKeyPath options:(CPDictionary)options from:(id)aSource
{
    self = [super init];

    if (self)
    {
        _source = aSource;
        _info   = [CPDictionary dictionaryWithObjects:[aDestination, aKeyPath] forKeys:[CPObservedObjectKey, CPObservedKeyPathKey]];

        if (options)
            [_info setObject:options forKey:CPOptionsKey];

        [aDestination addObserver:self forKeyPath:aKeyPath options:CPKeyValueObservingOptionNew context:aBinding];

        var bindings = [bindingsMap objectForKey:[_source hash]];
        if (!bindings)
        {
            bindings = [CPDictionary new];
            [bindingsMap setObject:bindings forKey:[_source hash]];
        }

        [bindings setObject:self forKey:aName];
        [self setValueFor:aBinding];
    }

    return self;
}

- (void)setValueFor:(CPString)aBinding
{
    var destination = [_info objectForKey:CPObservedObjectKey],
        keyPath = [_info objectForKey:CPObservedKeyPathKey],
        options = [_info objectForKey:CPOptionsKey],
        newValue = [destination valueForKeyPath:keyPath],
        isPlaceholder = CPIsControllerMarker(newValue);

    if (isPlaceholder)
    {
        switch (newValue)
        {
            case CPMultipleValuesMarker:
                newValue = [options objectForKey:CPMultipleValuesPlaceholderBindingOption] || @"Multiple Values";
                break;

            case CPNoSelectionMarker:
                newValue = [options objectForKey:CPNoSelectionPlaceholderBindingOption] || @"No Selection";
                break;

            case CPNotApplicableMarker:
                if ([options objectForKey:CPRaisesForNotApplicableKeysBindingOption])
                    [CPException raise:CPGenericException reason:@"can't transform non applicable key on: "+_source+" value: "+newValue];

                newValue = [options objectForKey:CPNotApplicablePlaceholderBindingOption] || @"Not Applicable";
                break;
        }
    }
    else
    {
        // Only transform the value if the current value is not a placeholder
        newValue = [self transformValue:newValue withOptions:options];
    }

    [_source setValue:newValue forKey:aBinding];

    if ([_source respondsToSelector:@selector(_setCurrentValueIsPlaceholder:)])
        [_source _setCurrentValueIsPlaceholder:isPlaceholder];
}

- (void)reverseSetValueFor:(CPString)aBinding
{
    var destination = [_info objectForKey:CPObservedObjectKey],
        keyPath = [_info objectForKey:CPObservedKeyPathKey],
        options = [_info objectForKey:CPOptionsKey],
        newValue = [_source valueForKeyPath:aBinding];

    newValue = [self reverseTransformValue:newValue withOptions:options];
    [destination setValue:newValue forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)context
{
    if (!changes)
        return;

    [self setValueFor:context];
}

- (id)transformValue:(id)aValue withOptions:(CPDictionary)options
{
    var valueTransformerName,
        valueTransformer,
        placeholder;

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


    if (aValue === undefined || aValue === nil)
        aValue = [options objectForKey:CPNullPlaceholderBindingOption] || nil;

    return aValue;
}

- (id)reverseTransformValue:(id)aValue withOptions: (CPDictionary)options
{
    var valueTransformerName = [options objectForKey:CPValueTransformerNameBindingOption],
        valueTransformer;

    if (valueTransformerName)
        valueTransformer = [CPValueTransformer valueTransformerForName:valueTransformerName];
    else
        valueTransformer = [options objectForKey:CPValueTransformerBindingOption];

    if (valueTransformer && [[valueTransformer class] allowsReverseTransformation])
        aValue = [valueTransformer transformedValue:aValue];

    return aValue;
}

@end

@implementation CPObject (KeyValueBindingCreation)

+ (void)exposeBinding:(CPString)aBinding
{
    [CPKeyValueBinding exposeBinding:aBinding forClass:[self class]];
}

- (CPArray)exposedBindings
{
    var exposedBindings = [],
        theClass = [self class];

    while (theClass)
    {
        var temp = [CPKeyValueBinding exposedBindingsForClass:theClass];

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
        return CPLog.error("Invalid object or path on "+self+" for "+aBinding);

    //if (![[self exposedBindings] containsObject:aBinding])
    //    CPLog.warn("No binding exposed on "+self+" for "+aBinding);

    [self unbind:aBinding];
    [[CPKeyValueBinding alloc] initWithBinding:[self _replacementKeyPathForBinding:aBinding] name:aBinding to:anObject keyPath:aKeyPath options:options from:self];
}

- (CPDictionary)infoForBinding:(CPString)aBinding
{
    return [CPKeyValueBinding infoForBinding:aBinding forObject:self];
}

- (void)unbind:(CPString)aBinding
{
    [CPKeyValueBinding unbind:aBinding forObject:self];
}

- (id)_replacementKeyPathForBinding:(CPString)binding
{
    return binding;
}

@end

@implementation _CPKeyValueOrBinding : CPKeyValueBinding
{
}

- (void)setValueFor:(CPString)aBinding
{
    var bindings = [bindingsMap valueForKey:[_source hash]];

    if (!bindings)
        return;

    [_source setValue:resolveMultipleValues(aBinding, bindings, CPBindingOperationOr) forKey:aBinding];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)context
{
    [self setValueFor:context];
}

@end

@implementation _CPKeyValueAndBinding : CPKeyValueBinding
{
}

- (void)setValueFor:(CPString)aBinding
{
    var bindings = [bindingsMap objectForKey:[_source hash]];

    if (!bindings)
        return;

    [_source setValue:resolveMultipleValues(aBinding, bindings, CPBindingOperationAnd) forKey:aBinding];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObejct change:(CPDictionary)changes context:(id)context
{
    [self setValueFor:context];
}

@end

var resolveMultipleValues = function resolveMultipleValues(/*CPString*/key, /*CPDictionary*/bindings, /*GSBindingOperationKind*/operation)
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
}

var invokeAction = function invokeAction(/*CPString*/targetKey, /*CPString*/argumentKey, /*CPDictionary*/bindings)
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
}

// Keys in options dictionary

// Keys in dictionary returned by infoForBinding
CPObservedObjectKey     = @"CPObservedObjectKey";
CPObservedKeyPathKey    = @"CPObservedKeyPathKey";
CPOptionsKey            = @"CPOptionsKey";

// special markers
CPMultipleValuesMarker  = @"CPMultipleValuesMarker";
CPNoSelectionMarker     = @"CPNoSelectionMarker";
CPNotApplicableMarker   = @"CPNotApplicableMarker";

// Binding name constants
CPAlignmentBinding      = @"CPAlignmentBinding";
CPEditableBinding       = @"CPEditableBinding";
CPEnabledBinding        = @"CPEnabledBinding";
CPFontBinding           = @"CPFontBinding";
CPHiddenBinding         = @"CPHiddenBinding";
CPSelectedIndexBinding  = @"CPSelectedIndexBinding";
CPTextColorBinding      = @"CPTextColorBinding";
CPToolTipBinding        = @"CPToolTipBinding";
CPValueBinding          = @"value";

//Binding options constants
CPAllowsEditingMultipleValuesSelectionBindingOption = @"CPAllowsEditingMultipleValuesSelectionBindingOption";
CPAllowsNullArgumentBindingOption                   = @"CPAllowsNullArgumentBindingOption";
CPConditionallySetsEditableBindingOption            = @"CPConditionallySetsEditableBindingOption";
CPConditionallySetsEnabledBindingOption             = @"CPConditionallySetsEnabledBindingOption";
CPConditionallySetsHiddenBindingOption              = @"CPConditionallySetsHiddenBindingOption";
CPContinuouslyUpdatesValueBindingOption             = @"CPContinuouslyUpdatesValueBindingOption";
CPCreatesSortDescriptorBindingOption                = @"CPCreatesSortDescriptorBindingOption";
CPDeletesObjectsOnRemoveBindingsOption              = @"CPDeletesObjectsOnRemoveBindingsOption";
CPDisplayNameBindingOption                          = @"CPDisplayNameBindingOption";
CPDisplayPatternBindingOption                       = @"CPDisplayPatternBindingOption";
CPHandlesContentAsCompoundValueBindingOption        = @"CPHandlesContentAsCompoundValueBindingOption";
CPInsertsNullPlaceholderBindingOption               = @"CPInsertsNullPlaceholderBindingOption";
CPInvokesSeparatelyWithArrayObjectsBindingOption    = @"CPInvokesSeparatelyWithArrayObjectsBindingOption";
CPMultipleValuesPlaceholderBindingOption            = @"CPMultipleValuesPlaceholderBindingOption";
CPNoSelectionPlaceholderBindingOption               = @"CPNoSelectionPlaceholderBindingOption";
CPNotApplicablePlaceholderBindingOption             = @"CPNotApplicablePlaceholderBindingOption";
CPNullPlaceholderBindingOption                      = @"CPNullPlaceholderBindingOption";
CPPredicateFormatBindingOption                      = @"CPPredicateFormatBindingOption";
CPRaisesForNotApplicableKeysBindingOption           = @"CPRaisesForNotApplicableKeysBindingOption";
CPSelectorNameBindingOption                         = @"CPSelectorNameBindingOption";
CPSelectsAllWhenSettingContentBindingOption         = @"CPSelectsAllWhenSettingContentBindingOption";
CPValidatesImmediatelyBindingOption                 = @"CPValidatesImmediatelyBindingOption";
CPValueTransformerNameBindingOption                 = @"CPValueTransformerNameBindingOption";
CPValueTransformerBindingOption                     = @"CPValueTransformerBindingOption";

CPIsControllerMarker = function(/*id*/anObject)
{
    return anObject === CPMultipleValuesMarker || anObject === CPNoSelectionMarker || anObject === CPNotApplicableMarker;
}