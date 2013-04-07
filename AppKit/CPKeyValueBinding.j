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
@import <Foundation/CPInvocation.j>
@import <Foundation/CPValueTransformer.j>
@import <Foundation/CPKeyValueObserving.j>

@class CPButton

var exposedBindingsMap = @{},
    bindingsMap = @{};

var CPBindingOperationAnd = 0,
    CPBindingOperationOr  = 1;

@implementation CPBinder : CPObject
{
    CPDictionary    _info;
    id              _source @accessors(getter=source);

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

    var info = theBinding._info,
        observedObject = [info objectForKey:CPObservedObjectKey],
        keyPath = [info objectForKey:CPObservedKeyPathKey];

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
    // We use [self init] here because subclasses override init. We can't override this method
    // because their initialization has to occur before this method in this class is executed.
    self = [self init];

    if (self)
    {
        _source = aSource;
        _info = @{
                CPObservedObjectKey: aDestination,
                CPObservedKeyPathKey: aKeyPath,
            };
        _suppressedNotifications = {};
        _placeholderForMarker = {};

        if (options)
            [_info setObject:options forKey:CPOptionsKey];

        [self _updatePlaceholdersWithOptions:options forBinding:aName];

        [aDestination addObserver:self forKeyPath:aKeyPath options:CPKeyValueObservingOptionNew context:aBinding];

        var bindings = [bindingsMap objectForKey:[_source UID]];

        if (!bindings)
        {
            bindings = @{};
            [bindingsMap setObject:bindings forKey:[_source UID]];
        }

        [bindings setObject:self forKey:aName];
        [self setValueFor:aBinding];
    }

    return self;
}

- (void)raiseIfNotApplicable:(id)aValue forKeyPath:(CPString)keyPath options:(CPDictionary)options
{
    if (aValue === CPNotApplicableMarker && [options objectForKey:CPRaisesForNotApplicableKeysBindingOption])
    {
       [CPException raise:CPGenericException
                   reason:@"Cannot transform non-applicable key on: " + _source + " key path: " + keyPath + " value: " + aValue];
    }
}

- (void)setValueFor:(CPString)theBinding
{
    var destination = [_info objectForKey:CPObservedObjectKey],
        keyPath = [_info objectForKey:CPObservedKeyPathKey],
        options = [_info objectForKey:CPOptionsKey],
        newValue = [destination valueForKeyPath:keyPath];

    if (CPIsControllerMarker(newValue))
    {
        [self raiseIfNotApplicable:newValue forKeyPath:keyPath options:options];

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

    // If the value is nil AND the source doesn't respond to setPlaceholderString: then
    // we set the value to the placeholder. Otherwise, we do not want to short cut the process
    // of setting the placeholder that is based on the fact that the value is nil.
    if ((aValue === undefined || aValue === nil || aValue === [CPNull null])
        && ![_source respondsToSelector:@selector(setPlaceholderString:)])
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

- (void)_updatePlaceholdersWithOptions:(CPDictionary)options forBinding:(CPString)aBinding
{
    [self _updatePlaceholdersWithOptions:options];
}

- (JSObject)_placeholderForMarker:(id)aMarker
{
    var placeholder = _placeholderForMarker[[aMarker UID]];

    if (placeholder)
        return placeholder.value;

    return nil;
}

- (void)_setPlaceholder:(id)aPlaceholder forMarker:(id)aMarker isDefault:(BOOL)isDefault
{
    if (isDefault)
    {
        var existingPlaceholder = _placeholderForMarker[[aMarker UID]];

        // Don't overwrite an explicitly set placeholder with a default.
        if (existingPlaceholder && !existingPlaceholder.isDefault)
            return;
    }

    _placeholderForMarker[[aMarker UID]] = { 'isDefault': isDefault, 'value': aPlaceholder };
}

@end

@implementation CPObject (KeyValueBindingCreation)

+ (void)exposeBinding:(CPString)aBinding
{
    [CPBinder exposeBinding:aBinding forClass:[self class]];
}

+ (Class)_binderClassForBinding:(CPString)aBinding
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

- (CPString)_replacementKeyPathForBinding:(CPString)binding
{
    return binding;
}

@end

/*!
    @ignore
    Provides stub implementations that simply calls super for the "objectValue" binding.
    This class should not be necessary but assures backwards compliance with our old way of doing bindings.

    IMPORTANT!
    Every class with a value binding should implement a subclass to handle its specific value binding logic.
*/
@implementation _CPValueBinder : CPBinder

- (void)setValueFor:(CPString)theBinding
{
    [super setValueFor:@"objectValue"];
}

- (void)reverseSetValueFor:(CPString)theBinding
{
    [super reverseSetValueFor:@"objectValue"];
}

@end

@implementation _CPMultipleValueBooleanBinding : CPBinder
{
    CPBindingOperationKind _operation;
}

- (void)setValueFor:(CPString)aBinding
{
    var bindings = [bindingsMap valueForKey:[_source UID]];

    if (!bindings)
        return;

    var baseBinding = aBinding.replace(/\d$/, "");

    [_source setValue:[self resolveMultipleValuesForBinding:baseBinding bindings:bindings booleanOperation:_operation] forKey:baseBinding];
}

- (void)reverseSetValueFor:(CPString)theBinding
{
    // read-only
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)context
{
    [self setValueFor:context];
}

- (BOOL)resolveMultipleValuesForBinding:(CPString)aBinding bindings:(CPDictionary)bindings booleanOperation:(CPBindingOperationKind)operation
{
    var bindingName = aBinding,
        theBinding,
        count = 2;

    while (theBinding = [bindings objectForKey:bindingName])
    {
        var info    = theBinding._info,
            object  = [info objectForKey:CPObservedObjectKey],
            keyPath = [info objectForKey:CPObservedKeyPathKey],
            options = [info objectForKey:CPOptionsKey],
            value   = [object valueForKeyPath:keyPath];

        if (CPIsControllerMarker(value))
        {
            [self raiseIfNotApplicable:value forKeyPath:keyPath options:options];
            value = [theBinding _placeholderForMarker:value];
        }
        else
            value = [theBinding transformValue:value withOptions:options];

        if (operation === CPBindingOperationOr)
        {
            // Any true condition means true for OR
            if (value)
                return YES;
        }

        // Any false condition means false for AND
        else if (!value)
            return NO;

        bindingName = aBinding + (count++);
    }

    // If we get here, all OR conditions were false or all AND conditions were true
    return operation === CPBindingOperationOr ? NO : YES;
}

@end

@implementation CPMultipleValueAndBinding : _CPMultipleValueBooleanBinding

- (id)init
{
    if (self = [super init])
        _operation = CPBindingOperationAnd;

    return self;
}

@end

@implementation CPMultipleValueOrBinding : _CPMultipleValueBooleanBinding

- (id)init
{
    if (self = [super init])
        _operation = CPBindingOperationOr;

    return self;
}

@end

@implementation _CPMultipleValueActionBinding : CPBinder
{
    CPString _argumentBinding;
    CPString _targetBinding;
}

- (void)setValueFor:(CPString)theBinding
{
    // Called when the binding is first created
    [self checkForNullBinding:theBinding initializing:YES];
}

- (void)reverseSetValueFor:(CPString)theBinding
{
    // no-op
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)context
{
    // context is the binding name
    [self checkForNullBinding:context initializing:NO];
}

/*!
    @ignore

    When the value of a multiple-value argument binding changes,
    if the binding is marked not to allow null arguments, we have to check
    if the binding's value is nil and disable the button if it is.
    Otherwise the button is enabled.
*/
- (void)checkForNullBinding:(CPString)theBinding initializing:(BOOL)isInitializing
{
    // Only done for buttons
    if (![_source isKindOfClass:CPButton])
        return;

    // We start with the button enabled for the first argument during init,
    // and subsequent checks can disable it.
    if (isInitializing && theBinding === CPArgumentBinding)
        [_source setEnabled:YES];

    var bindings = [bindingsMap valueForKey:[_source UID]],
        binding  = [bindings objectForKey:theBinding],
        info     = binding._info,
        options  = [info objectForKey:CPOptionsKey];

    if (![options valueForKey:CPAllowsNullArgumentBindingOption])
    {
        var object  = [info objectForKey:CPObservedObjectKey],
            keyPath = [info objectForKey:CPObservedKeyPathKey],
            value   = [object valueForKeyPath:keyPath];

        if (value === nil || value === undefined)
        {
            [_source setEnabled:NO];
            return;
        }
    }

    // If a binding value changed and did not fail the null test, enable the button
    if (!isInitializing)
        [_source setEnabled:YES];
}

- (void)invokeAction
{
    var bindings = [bindingsMap valueForKey:[_source UID]],
        theBinding = [bindings objectForKey:CPTargetBinding],

        info     = theBinding._info,
        object   = [info objectForKey:CPObservedObjectKey],
        keyPath  = [info objectForKey:CPObservedKeyPathKey],
        options  = [info objectForKey:CPOptionsKey],

        target   = [object valueForKeyPath:keyPath],
        selector = [options objectForKey:CPSelectorNameBindingOption];

    if (!target || !selector)
        return;

    var invocation = [CPInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]],
        bindingName = CPArgumentBinding,
        count = 1;

    while (theBinding = [bindings objectForKey:bindingName])
    {
        info   = theBinding._info;
        object = [info objectForKey:CPObservedObjectKey];
        keyPath  = [info objectForKey:CPObservedKeyPathKey];

        [invocation setArgument:[object valueForKeyPath:keyPath] atIndex:++count];

        bindingName = CPArgumentBinding + count;
    }

    [invocation setSelector:selector];
    [invocation invokeWithTarget:target];
}

@end

@implementation CPActionBinding : _CPMultipleValueActionBinding

- (id)init
{
    if (self = [super init])
    {
        _argumentBinding = CPArgumentBinding;
        _targetBinding = CPTargetBinding;
    }

    return self;
}

@end

@implementation CPDoubleClickActionBinding : _CPMultipleValueActionBinding

- (id)init
{
    if (self = [super init])
    {
        _argumentBinding = CPArgumentBinding;
        _targetBinding = CPTargetBinding;
    }

    return self;
}

@end

/*!
    Abstract superclass for CPValueWithPatternBinding and CPTitleWithPatternBinding.
*/
@implementation _CPPatternBinding : CPBinder
{
    CPString _bindingKey;
    CPString _patternPlaceholder;
}

- (void)setValueFor:(CPString)aBinding
{
    var bindings = [bindingsMap valueForKey:[_source UID]];

    if (!bindings)
        return;

    // Strip off any trailing number from the binding name
    var baseBinding = aBinding.replace(/\d$/, ""),
        result = [self resolveMultipleValuesForBindings:bindings];

    if (result.isPlaceholder)
        [self setPlaceholderValue:result.value withMarker:result.marker forBinding:baseBinding];
    else
        [self setValue:result.value forBinding:baseBinding];
}

- (void)reverseSetValueFor:(CPString)theBinding
{
    // read-only
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)context
{
    [self setValueFor:context];
}

- (JSObject)resolveMultipleValuesForBindings:(CPDictionary)bindings
{
    var theBinding,
        result = { value:@"", isPlaceholder:NO, marker:nil };

    for (var count = 1; theBinding = [bindings objectForKey:_bindingKey + count]; ++count)
    {
        var info    = theBinding._info,
            object  = [info objectForKey:CPObservedObjectKey],
            keyPath = [info objectForKey:CPObservedKeyPathKey],
            options = [info objectForKey:CPOptionsKey],
            value   = [object valueForKeyPath:keyPath];

        if (count === 1)
            result.value = [options objectForKey:CPDisplayPatternBindingOption];

        if (CPIsControllerMarker(value))
        {
            [self raiseIfNotApplicable:value forKeyPath:keyPath options:options];

            result.isPlaceholder = YES;
            result.marker = value;

            value = [theBinding _placeholderForMarker:value];
        }
        else
            value = [theBinding transformValue:value withOptions:options];

        if (value === nil || value === undefined)
            value = @"";

        result.value = result.value.replace("%{" + _patternPlaceholder + count + "}@", [value description]);
    }

    return result;
}

@end


/*!
    Users of this class must override setValue:forKey: and if the
    key is CPDisplayPatternValueBinding, set the appropriate value
    for the control class. For example, CPTextField uses setObjectValue.
*/
@implementation CPValueWithPatternBinding : _CPPatternBinding

- (id)init
{
    if (self = [super init])
    {
        _bindingKey = CPDisplayPatternValueBinding;
        _patternPlaceholder = @"value";
    }

    return self;
}

@end


/*!
    Users of this class must override setValue:forKey: and if the
    key is CPDisplayPatternTitleBinding, set the appropriate value
    for the control class. For example, CPBox uses setTitle.
*/
@implementation CPTitleWithPatternBinding : _CPPatternBinding

- (id)init
{
    if (self = [super init])
    {
        _bindingKey = CPDisplayPatternTitleBinding;
        _patternPlaceholder = @"title";
    }

    return self;
}

@end

@implementation _CPStateMarker : CPObject
{
    CPString _name;
}

- (id)initWithName:(CPString)aName
{
    if (self = [super init])
        _name = aName

    return self;
}

- (CPString)description
{
    return "<" + _name + ">";
}

@end


// Keys in options dictionary

// Keys in dictionary returned by infoForBinding
CPObservedObjectKey     = @"CPObservedObjectKey";
CPObservedKeyPathKey    = @"CPObservedKeyPathKey";
CPOptionsKey            = @"CPOptionsKey";

// special markers
CPNoSelectionMarker     = [[_CPStateMarker alloc] initWithName:@"NO SELECTION MARKER"];
CPMultipleValuesMarker  = [[_CPStateMarker alloc] initWithName:@"MULTIPLE VALUES MARKER"];
CPNotApplicableMarker   = [[_CPStateMarker alloc] initWithName:@"NOT APPLICABLE MARKER"];
CPNullMarker            = [[_CPStateMarker alloc] initWithName:@"NULL MARKER"];

// Binding name constants
CPAlignmentBinding                        = @"alignment";
CPArgumentBinding                         = @"argument";
CPContentArrayBinding                     = @"contentArray";
CPContentBinding                          = @"content";
CPContentObjectBinding                    = @"contentObject";
CPContentObjectsBinding                   = @"contentObjects";
CPContentValuesBinding                    = @"contentValues";
CPDisplayPatternTitleBinding              = @"displayPatternTitle";
CPDisplayPatternValueBinding              = @"displayPatternValue";
CPDoubleClickArgumentBinding              = @"doubleClickArgument";
CPDoubleClickTargetBinding                = @"doubleClickTarget";
CPEditableBinding                         = @"editable";
CPEnabledBinding                          = @"enabled";
CPFontBinding                             = @"font";
CPFontNameBinding                         = @"fontName";
CPFontBoldBinding                         = @"fontBold";
CPHiddenBinding                           = @"hidden";
CPFilterPredicateBinding                  = @"filterPredicate";
CPMaxValueBinding                         = @"maxValue";
CPMinValueBinding                         = @"minValue";
CPPredicateBinding                        = @"predicate";
CPSelectedIndexBinding                    = @"selectedIndex";
CPSelectedLabelBinding                    = @"selectedLabel";
CPSelectedObjectBinding                   = @"selectedObject";
CPSelectedObjectsBinding                  = @"selectedObjects";
CPSelectedTagBinding                      = @"selectedTag";
CPSelectedValueBinding                    = @"selectedValue";
CPSelectedValuesBinding                   = @"selectedValues";
CPSelectionIndexesBinding                 = @"selectionIndexes";
CPTargetBinding                           = @"target";
CPTextColorBinding                        = @"textColor";
CPTitleBinding                            = @"title";
CPToolTipBinding                          = @"toolTip";
CPValueBinding                            = @"value";
CPValueURLBinding                         = @"valueURL";
CPValuePathBinding                        = @"valuePath";
CPDataBinding                             = @"data";

// Binding options constants
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

