/*
 * CPPredicateEditorRowTemplate.j
 * AppKit
 *
 * Created by cacaodev.
 * Copyright 2011, cacaodev.
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

@import <Foundation/CPPredicate.j>

@import "CPCheckBox.j"
@import "CPPopUpButton.j"
@import "CPMenuItem.j"
@import "CPTextField.j"

// NOTE: CPDatePicker is not implemented yet
@class CPDatePicker


CPUndefinedAttributeType     = 0;
CPInteger16AttributeType     = 100;
CPInteger32AttributeType     = 200;
CPInteger64AttributeType     = 300;
CPDecimalAttributeType       = 400;
CPDoubleAttributeType        = 500;
CPFloatAttributeType         = 600;
CPStringAttributeType        = 700;
CPBooleanAttributeType       = 800;
CPDateAttributeType          = 900;
CPBinaryDataAttributeType    = 1000;
CPTransformableAttributeType = 1800;

@implementation CPPredicateEditorRowTemplate : CPObject
{
    int            _templateType @accessors(readwrite, getter=_templateType, setter=_setTemplateType:);
    unsigned   _predicateOptions @accessors(readwrite, setter=_setOptions:);
    unsigned  _predicateModifier @accessors(readwrite, setter=_setModifier:);
    unsigned  _leftAttributeType @accessors(readwrite, getter=leftAttributeType, setter=_setLeftAttributeType:);
    unsigned _rightAttributeType @accessors(readwrite, getter=rightAttributeType, setter=_setRightAttributeType:);
    BOOL         _leftIsWildcard @accessors(property=leftIsWildcard);
    BOOL        _rightIsWildcard @accessors(property=rightIsWildcard);
    CPArray               _views @accessors(setter=setTemplateViews:);

}

/*!
    @ingroup appkit
    @class CPPredicateEditorRowTemplate

    @brief CPPredicateEditorRowTemplate describes available predicates and how to display them.

    You can create instances of CPPredicateEditorRowTemplate programmatically or in Interface Builder. By default, a non-compound row template has three views: a popup (or static text field) on the left, a popup or static text field for operators, and either a popup or other view on the right.  You can subclass CPPredicateEditorRowTemplate to create a row template with different numbers or types of views.

    CPPredicateEditorRowTemplate is a concrete class, but it has five primitive methods which are called by CPPredicateEditor: -#templateViews, -#matchForPredicate:, -#setPredicate:, -#displayableSubpredicatesOfPredicate:, and -#predicateWithSubpredicates:. CPPredicateEditorRowTemplate implements all of them, but you can override them for custom templates. The primitive methods are used by an instance of CPPredicateEditor as follows.

    First, an instance of CPPredicateEditor is created, and some row templates are set on it—either through a nib file or programmatically. The first thing predicate editor does is ask each of the templates for their views, using templateViews.

    After setting up the predicate editor, you typically send it a  CPPredicateEditor#setObjectValue: message to restore a saved predicate. CPPredicateEditor needs to determine which of its templates should display each predicate in the predicate tree. It does this by sending each of its row templates a matchForPredicate: message and choosing the one that returns the highest value.

    After finding the best match for a predicate, CPPredicateEditor copies that template to get fresh views, inserts them into the proper row, and then sets the predicate on the template using setPredicate:. Within that method, the CPPredicateEditorRowTemplate object must set its views' values to represent that predicate.

    CPPredicateEditorRowTemplate next asks the template for the “displayable sub-predicates” of the predicate by sending a -#displayableSubpredicatesOfPredicate: message. If a template represents a predicate in its entirety, or if the predicate has no subpredicates, it can return nil for this.  Otherwise, it should return a list of predicates to be made into sub-rows of that template's row. The whole process repeats for each sub-predicate.

    At this point, the user sees the predicate that was saved.  If the user then makes some changes to the views of the templates, this causes CPPredicateEditor to recompute its predicate by asking each of the templates to return the predicate represented by the new view values, passing in the subpredicates represented by the sub-rows (an empty array if there are none, or nil if they aren't supported by that predicate type).
*/

/*!
    @name Initializing a Template
*/

/*!
    @brief Initializes and returns a “pop-up-pop-up-pop-up”-style row template.
    @param leftExpressions An array of CPExpression objects that represent the left hand side of a predicate.
    @param rightExpressions An array of CPExpression objects that represent the right hand side of a predicate.
    @param modifier A modifier for the predicate (see @c CPComparisonPredicateModifier for possible values).
    @param operators An array of CPNumber objects specifying the operator type (see @c CPPredicateOperatorType for possible values).
    @param options Options for the predicate (see @c CPComparisonPredicateOptions for possible values).
    @return A row template of the “pop-up-pop-up-pop-up”-form, with the left and right popups representing the left and right expression arrays -#leftExpressions and -#rightExpressions, and the center popup representing the operators.
*/
- (id)initWithLeftExpressions:(CPArray)leftExpressions rightExpressions:(CPArray)rightExpressions modifier:(int)modifier operators:(CPArray)operators options:(int)options
{
    self = [super init];
    if (self != nil)
    {
        _templateType = 1;
        _leftIsWildcard = NO;
        _rightIsWildcard = NO;
        _leftAttributeType = 0;
        _rightAttributeType = 0;
        _predicateModifier = modifier;
        _predicateOptions = options;

        var leftView = [self _viewFromExpressions:leftExpressions],
            rightView = [self _viewFromExpressions:rightExpressions],
            middleView = [self _viewFromOperatorTypes:operators];

        _views = [[CPArray alloc] initWithObjects:leftView, middleView, rightView];
    }

    return self;
}

/*!
    @brief Initializes and returns a “pop-up-pop-up-view”-style row template.
    @param leftExpressions An array of CPExpression objects that represent the left hand side of a predicate.
    @param attributeType An attribute type for the right hand side of a predicate. This value dictates the type of view created, and how the control’s object value is coerced before putting it into a predicate.
    @param modifier A modifier for the predicate (see @c CPComparisonPredicateModifier for possible values).
    @param operators An array of CPNumber objects specifying the operator type (see @c CPPredicateOperatorType for possible values).
    @param options Options for the predicate (see CPComparisonPredicateOptions for possible values).
    @return A row template initialized using the given arguments.
*/
- (id)initWithLeftExpressions:(CPArray )leftExpressions rightExpressionAttributeType:(CPAttributeType)attributeType modifier:(CPComparisonPredicateModifier)modifier operators:(CPArray )operators options:(int)options
{
    self = [super init];
    if (self != nil)
    {
        var leftView = [self _viewFromExpressions:leftExpressions],
            middleView = [self _viewFromOperatorTypes:operators],
            rightView = [self _viewFromAttributeType:attributeType];

        _templateType = 1;
        _leftIsWildcard = NO;
        _rightIsWildcard = YES;
        _leftAttributeType = 0;
        _rightAttributeType = attributeType;
        _predicateModifier = modifier;
        _predicateOptions = options;
        _views = [[CPArray alloc] initWithObjects:leftView, middleView, rightView];
    }

    return self;
}

/*!
    @brief Initializes and returns a row template suitable for displaying compound predicates.
    @param compoundTypes An array of CPNumber objects specifying compound predicate types. See @c CPCompoundPredicateTypes for possible values.
    @return A row template initialized for displaying compound predicates of the types specified by @a compoundTypes.
    @discussion CPPredicateEditor contains such a template by default.
*/
- (id)initWithCompoundTypes:(CPArray )compoundTypes
{
    self = [super init];
    if (self != nil)
    {
        var leftView = [self _viewFromCompoundTypes:compoundTypes],
            rightView = [[CPPopUpButton alloc] init];

        [rightView addItemWithTitle:@"of the following are true"];

        _templateType = 2;
        _leftIsWildcard = NO;
        _rightIsWildcard = NO;
        _rightAttributeType = 0;
        _views = [[CPArray alloc] initWithObjects:leftView, rightView];
    }
    return self;
}

/*!
    @name Primitive Methods
*/

/*!
    @brief Returns a positive number if the receiver can represent a given predicate, and 0 if it cannot.
    @return A positive number if the template can represent predicate, and @c 0 if it cannot.
    @discussion By default, returns values in the range @c 0 to @c 1.
    The highest match among all the templates determines which template is responsible for displaying the predicate. You can override this to determine which predicates your custom template handles.
*/
- (double)matchForPredicate:(CPPredicate)predicate
{
    // How exactly this value (float 0-1) is computed ?
    if ([self _templateType] == 2 && [predicate isKindOfClass:[CPCompoundPredicate class]])
    {
        if ([[self compoundTypes] containsObject:[predicate compoundPredicateType]])
                return 1;
    }
    else if ([self _templateType] == 1 && [predicate isKindOfClass:[CPComparisonPredicate class]])
    {
        if (!_leftIsWildcard && ![[self leftExpressions] containsObject:[predicate leftExpression]])
            return 0;

        if (![[self operators] containsObject:[predicate predicateOperatorType]])
            return 0;

        if (!_rightIsWildcard && ![[self rightExpressions] containsObject:[predicate rightExpression]])
            return 0;

        return 1;
    }

    return 0;
}

/*!
    @brief Returns the views for the receiver.
    @return The views for the receiver.
    @discussion Instances of CPPopUpButton are treated specially by CPPredicateEditor; their menu items are merged into a single popup button, and matching menu item titles are combined. In this way, a single tree is built from the separate templates.
*/
- (CPArray)templateViews
{
    return _views;
}

/*!
    @brief Sets the value of the views according to the given predicate.
    @param predicate The predicate value for the receiver.
    @discussion This method is only called if -#matchForPredicate: returned a positive value for the receiver.

    You can override this to set the values of custom views.
*/
- (void)setPredicate:(CPPredicate)predicate
{
    if (_templateType == 2)
        [self _setCompoundPredicate:predicate];
    else
        [self _setComparisonPredicate:predicate];
}

/*!
    @brief Returns the subpredicates that should be made sub-rows of a given predicate.
    @param predicate A predicate object.
    @return The subpredicates that should be made sub-rows of @a predicate. For compound predicates (instances of CPCompoundPredicate), the array of subpredicates; for other types of predicate, returns @c nil. If a template represents a predicate in its entirety, or if the predicate has no subpredicates, returns @c nil.
    @discussion You can override this method to create custom templates that handle complicated compound predicates.
*/
- (CPArray)displayableSubpredicatesOfPredicate:(CPPredicate)predicate
{
    if ([predicate isKindOfClass:[CPCompoundPredicate class]])
    {
        var subpredicates = [predicate subpredicates];
        if ([subpredicates count] == 0)
            return nil;

        return subpredicates;
    }

    return nil;
}

/*!
    @brief Returns the predicate represented by the receiver’s views' values and the given sub-predicates.
    @param subpredicates An array of predicates.
    @return The predicate represented by the values of the template's views and the given @a subpredicates. You can override this method to return the predicate represented by your custom views.
    @discussion This method is only called if -#matchForPredicate: returned a positive value for the receiver.

    You can override this method to return the predicate represented by a custom view.
*/
- (CPPredicate)predicateWithSubpredicates:(CPArray)subpredicates
{
    if (_templateType == 2)
    {
        var type = [[_views[0] selectedItem] representedObject];
        return [[CPCompoundPredicate alloc] initWithType:type subpredicates:subpredicates];
    }

    if (_templateType == 1)
    {
        var lhs = [self _leftExpression],
            rhs = [self _rightExpression],
            operator = [[_views[1] selectedItem] representedObject];

        return [CPComparisonPredicate predicateWithLeftExpression:lhs
                                                  rightExpression:rhs
                                                         modifier:[self modifier]
                                                             type:operator
                                                          options:[self options]];
    }

    return nil;
}

/*!
    @name Information About a Row Template
*/

/*!
    @brief Returns the left hand expressions for the receiver.
    @return The left hand expressions for the receiver.
*/
- (CPArray)leftExpressions
{
    if (_templateType == 1 && !_leftIsWildcard)
    {
        var view = [_views objectAtIndex:0];
        return [[view itemArray] valueForKey:@"representedObject"];
    }

    return nil;
}

/*!
    @brief Returns the right hand expressions for the receiver.
    @return The right hand expressions for the receiver.
*/
- (CPArray)rightExpressions
{
    if (_templateType == 1 && !_rightIsWildcard)
    {
        var view = [_views objectAtIndex:2];
        return [[view itemArray] valueForKey:@"representedObject"];
    }

    return nil;
}

/*!
    @brief Returns the compound predicate types for the receiver.
    @return An array of CPNumber objects specifying compound predicate types. See @c CompoundPredicateTypes for possible values.
*/
- (CPArray)compoundTypes
{
    if (_templateType == 2)
    {
        var view = [_views objectAtIndex:0];
        return [[view itemArray] valueForKey:@"representedObject"];
    }

    return nil;
}

/*!
    @brief Returns the comparison predicate modifier for the receiver.
    @return The comparison predicate modifier for the receiver.
*/
- (CPComparisonPredicateModifier)modifier
{
    if (_templateType == 1)
        return _predicateModifier;

    return nil;
}

/*!
    @brief Returns Returns the array of operators for the receiver.
    @return The array of operators for the receiver.
*/
- (CPArray)operators
{
    if (_templateType == 1)
    {
        var view = [_views objectAtIndex:1];
        return [[view itemArray] valueForKey:@"representedObject"];
    }

    return nil;
}

/*!
    @brief Returns the comparison predicate options for the receiver.
    @return The comparison predicate options for the receiver. See @c CPComparisonPredicateOptions for possible values. Returns @c 0 if this does not apply (for example, for a compound template initialized with -#initWithCompoundTypes:).
*/
- (int)options
{
    if (_templateType == 1)
        return _predicateOptions;

    return nil;
}

/*!
    @brief Returns the attribute type of the receiver’s right expression.
    @return The attribute type of the receiver’s right expression.
*/
- (CPAttributeType)rightExpressionAttributeType
{
    return _rightAttributeType;
}

/*!
    @brief Returns the attribute type of the receiver’s left expression.
    @return The attribute type of the receiver’s left expression.
*/
- (CPAttributeType)leftExpressionAttributeType
{
    return _leftAttributeType;
}

/*! @cond */
+ (id)_bestMatchForPredicate:(CPPredicate)predicate inTemplates:(CPArray)templates quality:(double)quality
{
    var count = [templates count],
        match_value = 0,
        templateIndex = CPNotFound,
        i;

    for (i = 0; i < count; i++)
    {
        var template = [templates objectAtIndex:i],
            amatch = [template matchForPredicate:predicate];

        if (amatch > match_value)
        {
            templateIndex = i;
            match_value = amatch;
        }
    }

    if (templateIndex == CPNotFound)
    {
        [CPException raise:CPRangeException reason:@"Unable to find template matching predicate: " +  [predicate predicateFormat]];
        return nil;
    }

    return [templates objectAtIndex:templateIndex];
}

- (void)_setCompoundPredicate:(CPCompoundPredicate)predicate
{
    var left = [_views objectAtIndex:0],
        type = [predicate compoundPredicateType],
        index = [left indexOfItemWithRepresentedObject:type];

    [left selectItemAtIndex:index];
}

- (void)_setComparisonPredicate:(CPComparisonPredicate)predicate
{
    var left = [_views objectAtIndex:0],
        middle = [_views objectAtIndex:1],
        right = [_views objectAtIndex:2],
        leftExpression = [predicate leftExpression],
        rightExpression = [predicate rightExpression],
        operator = [predicate predicateOperatorType];

    if (_leftIsWildcard)
        [left setObjectValue:[leftExpression constantValue]];
    else
    {
        var index = [left indexOfItemWithRepresentedObject:leftExpression];
        [left selectItemAtIndex:index];
    }

    var op_index = [middle indexOfItemWithRepresentedObject:operator];
    [middle selectItemAtIndex:op_index];

    if (_rightIsWildcard)
        [right setObjectValue:[rightExpression constantValue]];
    else
    {
        var index = [right indexOfItemWithRepresentedObject:rightExpression];
        [right selectItemAtIndex:index];
    }
}

- (CPExpression)_leftExpression
{
    return [self _expressionFromView:_views[0] forAttributeType:_leftAttributeType];
}

- (CPExpression)_rightExpression
{
    return [self _expressionFromView:_views[2] forAttributeType:_rightAttributeType];
}

- (CPExpression)_expressionFromView:(CPView)aView forAttributeType:(CPAttributeType)attributeType
{
    if (attributeType == 0)
        return [[aView selectedItem] representedObject];

    var value;
    if (attributeType >= CPInteger16AttributeType && attributeType <= CPFloatAttributeType)
        value = [aView intValue];
    else if (attributeType == CPBooleanAttributeType)
        value = [aView state];
    else
        value = [aView stringValue];

    return [CPExpression expressionForConstantValue:value];
}

- (int)_rowType
{
    return (_templateType - 1);
}

- (id)copy
{
    return [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:self]];
}

+ (id)_operatorsForAttributeType:(CPAttributeType)attributeType
{
    var operators_array = [CPMutableArray array];

    switch (attributeType)
    {
        case CPInteger16AttributeType   : [operators_array addObjects:4,5,0,2,1,3];
            break;
        case CPInteger32AttributeType   : [operators_array addObjects:4,5,0,2,1,3];
            break;
        case CPInteger64AttributeType   : [operators_array addObjects:4,5,0,2,1,3];
            break;
        case CPDecimalAttributeType     : [operators_array addObjects:4,5,0,2,1,3];
            break;
        case CPDoubleAttributeType      : [operators_array addObjects:4,5,0,2,1,3];
            break;
        case CPFloatAttributeType       : [operators_array addObjects:4,5,0,2,1,3];
            break;
        case CPStringAttributeType      : [operators_array addObjects:99,4,5,8,9];
            break;
        case CPBooleanAttributeType     : [operators_array addObjects:4,5];
            break;
        case CPDateAttributeType        : [operators_array addObjects:4,5,0,2,1,3];
            break;
        default : CPLogConsole("Cannot create operators for an CPAttributeType " + attributeType);
            break;
    }

    return operators_array;
}

- (int)_templateType
{
    return _templateType;
}

- (id)_displayValueForPredicateOperator:(int)operator
{
    var value;

    switch (operator)
    {
        case CPLessThanPredicateOperatorType            : value = @"is less than";
            break;
        case CPLessThanOrEqualToPredicateOperatorType   : value = @"is less than or equal to";
            break;
        case CPGreaterThanPredicateOperatorType         : value = @"is greater than";
            break;
        case CPGreaterThanOrEqualToPredicateOperatorType : value = @"is greater than or equal to";
            break;
        case CPEqualToPredicateOperatorType             : value = @"is";
            break;
        case CPNotEqualToPredicateOperatorType          : value = @"is not";
            break;
        case CPMatchesPredicateOperatorType             : value = @"matches";
            break;
        case CPLikePredicateOperatorType                : value = @"is like";
            break;
        case CPBeginsWithPredicateOperatorType          : value = @"begins with";
            break;
        case CPEndsWithPredicateOperatorType            : value = @"ends with";
            break;
        case CPInPredicateOperatorType                  : value = @"in";
            break;
        case CPContainsPredicateOperatorType            : value = @"contains";
            break;
        case CPBetweenPredicateOperatorType             : value = @"between";
            break;
        default : CPLogConsole(@"unknown predicate operator %d" + operator);
    }

    return value;
}

- (id)_displayValueForCompoundPredicateType:(unsigned int)predicateType
{
    var value;
    switch (predicateType)
    {
        case CPNotPredicateType: value = @"None";
            break;
        case CPAndPredicateType: value = @"All";
            break;
        case CPOrPredicateType: value = @"Any";
            break;
        default : value = [CPString stringWithFormat:@"unknown compound predicate type %d",predicateType];
    }

    return value;
}

- (id)_displayValueForConstantValue:(id)value
{
    return [value description]; // number, date, string, ... localize
}

- (id)_displayValueForKeyPath:(CPString)keyPath
{
    return keyPath; // localize
}

- (CPPopUpButton)_viewFromExpressions:(CPArray)expressions
{
    var popup = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0, 0, 100, 18)],
        count = [expressions count];

    for (var i = 0; i < count; i++)
    {
        var exp = expressions[i],
            type = [exp expressionType],
            title;

        switch (type)
        {
            case CPKeyPathExpressionType: title = [self _displayValueForKeyPath:[exp keyPath]];
                break;
            case CPConstantValueExpressionType: title = [self _displayValueForConstantValue:[exp constantValue]];
                break;
            default: [CPException raise:CPInvalidArgumentException reason:@"Invalid Expression type " + type];
                break;
        }

        var item = [[CPMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
        [item setRepresentedObject:exp];
        [popup addItem:item];
    }

    [popup sizeToFit];

    return popup;
}

- (CPPopUpButton)_viewFromOperatorTypes:(CPArray)operators
{
    var popup = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0, 0, 100, 18)],
        count = [operators count];

    for (var i = 0; i < count; i++)
    {
        var op = operators[i],
            title = [self _displayValueForPredicateOperator:op],
            item = [[CPMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];

        [item setRepresentedObject:op];
        [popup addItem:item];
    }

    [popup sizeToFit];

    return popup;
}

- (CPView)_viewFromCompoundTypes:(CPArray)compoundTypes
{
    var popup = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0, 0, 100, 18)],
        count = [compoundTypes count];

    for (var i = 0; i < count; i++)
    {
        var type = compoundTypes[i],
            title = [self _displayValueForCompoundPredicateType:type],
            item = [[CPMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];

        [item setRepresentedObject:type];
        [popup addItem:item];
    }

    [popup sizeToFit];

    return popup;
}

- (CPView)_viewFromAttributeType:(CPAttributeType)attributeType
{
    var view;

    if (attributeType >= CPInteger16AttributeType && attributeType <= CPFloatAttributeType)
    {
        view = [self _textFieldWithFrame:CGRectMake(0, 0, 50, 26)];
    }
    else if (attributeType == CPStringAttributeType)
    {
        view = [self _textFieldWithFrame:CGRectMake(0, 0, 150, 26)];
    }
    else if (attributeType == CPBooleanAttributeType)
    {
        view = [[CPCheckBox alloc] initWithFrame:CGRectMake(0, 0, 50, 26)];
    }
    else if (attributeType == CPDateAttributeType)
        view = [[CPDatePicker alloc] initWithFrame:CGRectMake(0, 0, 150, 26)];
    else
        return nil;

    [view setTag:attributeType];

    return view;
}

- (CPTextField)_textFieldWithFrame:(CGRect)frame
{
    var textField = [[CPTextField alloc] initWithFrame:frame];
    [textField setBezeled:YES];
    [textField setBezelStyle:CPTextFieldSquareBezel];
    [textField setBordered:YES];
    [textField setEditable:YES];
    [textField setFont:[CPFont systemFontOfSize:10]];
    [textField setSendsActionOnEndEditing:YES];

    return textField;
}

- (void)_setOptions:(unsigned int)options
{
    _predicateOptions = options;
}

- (void)_setModifier:(unsigned int)modifier
{
    _predicateModifier = modifier;
}

- (CPString)description
{
    if (_templateType == 2)
        return [CPString stringWithFormat:@"<%@ %p %@>",[self className],self,[[self compoundTypes] componentsJoinedByString:@", "]];
    else if (_templateType == 1 && _rightIsWildcard)
        return [CPString stringWithFormat:@"<%@ %p [%@] [%@] %d>",[self className],self,[[self leftExpressions] componentsJoinedByString:@", "],[[self operators] componentsJoinedByString:@", "],[self rightExpressionAttributeType]];
    else
        return [CPString stringWithFormat:@"<%@ %p [%@] [%@] [%@]>",[self className],self,[[self leftExpressions] componentsJoinedByString:@", "],[[self operators] componentsJoinedByString:@", "],[[self rightExpressions] componentsJoinedByString:@", "]];
}

/*
- (void)_setLeftExpressionObject:(id)object
{
}
- (void)_setRightExpressionObject:(id)object
{
}
- (BOOL)_predicateIsNoneAreTrue:(id)predicate
{
}
- (id)_viewFromExpressionObject:(id)object
{
}
*/
@end

var CPPredicateTemplateTypeKey = @"CPPredicateTemplateType",
    CPPredicateTemplateOptionsKey = @"CPPredicateTemplateOptions",
    CPPredicateTemplateModifierKey = @"CPPredicateTemplateModifier",
    CPPredicateTemplateLeftAttributeTypeKey = @"CPPredicateTemplateLeftAttributeType",
    CPPredicateTemplateRightAttributeTypeKey = @"CPPredicateTemplateRightAttributeType",
    CPPredicateTemplateLeftIsWildcardKey = @"CPPredicateTemplateLeftIsWildcard",
    CPPredicateTemplateRightIsWildcardKey = @"CPPredicateTemplateRightIsWildcard",
    CPPredicateTemplateViewsKey = @"CPPredicateTemplateViews";

@implementation CPPredicateEditorRowTemplate (CPCoding)

- (id)initWithCoder:(CPCoder)coder
{
    self = [super init];
    if (self != nil)
    {
        _templateType = [coder decodeIntForKey:CPPredicateTemplateTypeKey];
        _predicateOptions = [coder decodeIntForKey:CPPredicateTemplateOptionsKey];
        _predicateModifier = [coder decodeIntForKey:CPPredicateTemplateModifierKey];
        _leftAttributeType = [coder decodeIntForKey:CPPredicateTemplateLeftAttributeTypeKey];
        _rightAttributeType = [coder decodeIntForKey:CPPredicateTemplateRightAttributeTypeKey];
        _leftIsWildcard = [coder decodeBoolForKey:CPPredicateTemplateLeftIsWildcardKey];
        _rightIsWildcard = [coder decodeBoolForKey:CPPredicateTemplateRightIsWildcardKey];
        _views = [coder decodeObjectForKey:CPPredicateTemplateViewsKey];

        // In Xcode 4, when the menu item title == template's expression keypath, representedObject is empty.
        // So we need to regenerate expressions from titles.
        if (_templateType == 1 && _leftIsWildcard == NO)
        {
            var itemArray = [_views[0] itemArray],
                count = [itemArray count];

            for (var i = 0; i < count; i++)
            {
                var item = itemArray[i];
                if ([item representedObject] == nil)
                {
                    var exp = [CPExpression expressionForKeyPath:[item title]];
                    [item setRepresentedObject:exp];
                }
            }
        }
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeInt:_templateType forKey:CPPredicateTemplateTypeKey];
    [coder encodeInt:_predicateOptions forKey:CPPredicateTemplateOptionsKey];
    [coder encodeInt:_predicateModifier forKey:CPPredicateTemplateModifierKey];
    [coder encodeInt:_leftAttributeType forKey:CPPredicateTemplateLeftAttributeTypeKey];
    [coder encodeInt:_rightAttributeType forKey:CPPredicateTemplateRightAttributeTypeKey];
    [coder encodeBool:_leftIsWildcard forKey:CPPredicateTemplateLeftIsWildcardKey];
    [coder encodeBool:_rightIsWildcard forKey:CPPredicateTemplateRightIsWildcardKey];
    [coder encodeObject:_views forKey:CPPredicateTemplateViewsKey];
}

@end
/*! @endcond */
