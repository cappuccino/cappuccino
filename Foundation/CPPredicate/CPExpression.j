@import <Foundation/CPString.j>
@import <Foundation/CPArray.j>
@import <Foundation/CPKeyValueCoding.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPCoder.j>

/*!
    An expression that always returns the same value.
*/
CPConstantValueExpressionType = 0;
/*!
    An expression that always returns the parameter object itself.
*/
CPEvaluatedObjectExpressionType = 1;
/*!
    An expression that always returns whatever value is associated with the key specified by ‘variable’ in the bindings dictionary.
*/
CPVariableExpressionType = 2;
/*!
    An expression that returns something that can be used as a key path.
*/
CPKeyPathExpressionType = 3;
/*!
    An expression that returns the result of evaluating a function.
*/
CPFunctionExpressionType = 4;
/*!
    An expression that defines an aggregate of NSExpression objects.
*/
CPAggregateExpressionType = 5;
/*!
    An expression that filters a collection using a subpredicate.
*/
CPSubqueryExpressionType = 6;
/*!
    An expression that creates a union of the results of two nested expressions.
*/
CPUnionSetExpressionType = 7;
/*!
    An expression that creates an intersection of the results of two nested expressions.
*/
CPIntersectSetExpressionType = 8;
/*!
    An expression that combines two nested expression results by set subtraction.
*/
CPMinusSetExpressionType = 9;

/*!
    @ingroup foundation
    @class CPExpression
    @brief CPExpression is used to represent expressions in a predicate.

    Comparison operations in an CPPredicate are based on two expressions, as represented by instances of the CPExpression class. Expressions are created for constant values, key paths, and so on.

    Generally, anywhere in the CPExpression class hierarchy where there is composite API and subtypes that may only reasonably respond to a subset of that API, invoking a method that does not make sense for that subtype will cause an exception to be thrown.
*/

@implementation CPExpression : CPObject
{
    int _type;
}

// Initializing an Expression
/*!
    Initializes the receiver with the specified expression type.
    @param type The type of the new expression, as defined by CPExpressionType.
    @return An initialized CPExpression object of the type type.
*/
- (id)initWithExpressionType:(int)type
{
    _type = type;

    return self;
}

//Creating an Expression for a Value
/*!
    Returns a new expression that represents a given constant value.
    @param value The constant value the new expression is to represent.
    @return A new expression that represents the constant value.
*/
+ (CPExpression)expressionForConstantValue:(id)value
{
    return [[CPExpression_constant alloc] initWithValue:value];
}

/*!
    Returns a new expression that represents the object being evaluated.
    @return A new expression that represents the object being evaluated.
*/
+ (CPExpression)expressionForEvaluatedObject
{
    return [[CPExpression_self alloc] init];
}

/*!
    Returns a new expression that extracts a value from the variable bindings dictionary for a given key.
    @param string The key for the variable to extract from the variable bindings dictionary.
    @return A new expression that extracts from the variable bindings dictionary the value for the key string.
*/
+ (CPExpression)expressionForVariable:(CPString)string
{
    return [[CPExpression_variable alloc] initWithVariable:string];
}

/*!
    Returns a new expression that invokes valueForKeyPath: with a given key path.
    @param keyPath The key path that the new expression should evaluate.
    @return A new expression that invokes valueForKeyPath: with keyPath.
*/
+ (CPExpression)expressionForKeyPath:(CPString)keyPath
{
    return [[CPExpression_keypath alloc] initWithKeyPath:keyPath];
}

//Creating a Collection Expression
/*!
    Returns a new aggregate expression for a given collection.
    @param collection A collection object (an instance of CPArray, CPSet, or CPDictionary) that contains further expressions.
    @return A new expression that contains the expressions in collection.
*/
+ (CPExpression)expressionForAggregate:(CPArray)collection
{
    return [[CPExpression_aggregate alloc] initWithAggregate:collection];
}

/*!
    Returns a new CPExpression object that represent the union of a given set and collection.
    @param left An expression that evaluates to an CPSet object.
    @param right An expression that evaluates to a collection object (an instance of CPArray, CPSet, or CPDictionary).
    @return A new CPExpression object that represents the union of left and right.
*/
+ (CPExpression)expressionForUnionSet:(CPExpression)left with:(CPExpression)right
{
    return [[CPExpression_set alloc] initWithType:CPUnionSetExpressionType left:left right:right];
}

/*!
    Returns a new CPExpression object that represent the intersection of a given set and collection.
    @param left An expression that evaluates to an CPSet object.
    @param right An expression that evaluates to a collection object (an instance of CPArray, CPSet, or CPDictionary).
    @return A new CPExpression object that represents the intersection of left and right.
*/
+ (CPExpression)expressionForIntersectSet:(CPExpression)left with:(CPExpression)right
{
    return [[CPExpression_set alloc] initWithType:CPIntersectSetExpressionType left:left right:right];
}

/*!
    Returns a new CPExpression object that represent the subtraction of a given collection from a given set.
    @param left An expression that evaluates to an CPSet object.
    @param left An expression that evaluates to a collection object (an instance of CPArray, CPSet, or CPDictionary).
    @return A new CPExpression object that represents the subtraction of right from left.
*/
+ (CPExpression)expressionForMinusSet:(CPExpression)left with:(CPExpression)right
{
    return [[CPExpression_set alloc] initWithType:CPMinusSetExpressionType left:left right:right];
}

// Creating an Expression for a Function
/*!
    Returns a new expression that will invoke one of the predefined functions.
    @param function_name The name of the function to invoke.
    @param parameters An array containing NSExpression objects that will be used as parameters during the invocation of selector.

    For a selector taking no parameters, the array should be empty. For a selector taking one or more parameters, the array should contain one NSExpression object which will evaluate to an instance of the appropriate type for each parameter.

    If there is a mismatch between the number of parameters expected and the number you provide during evaluation, an exception may be raised or missing parameters may simply be replaced by nil (which occurs depends on how many parameters are provided, and whether you have over- or underflow).
    @return A new expression that invokes the function name using the parameters in parameters.

    The name parameter can be one of the following predefined functions:
 @verbatim
    name              parameter array contents                           returns
   -------------------------------------------------------------------------------------------------------------------------------------
    sum:              CPExpression instances representing numbers        CPNumber
    count:            CPExpression instances representing numbers        CPNumber
    min:              CPExpression instances representing numbers        CPNumber
    max:              CPExpression instances representing numbers        CPNumber
    average:          CPExpression instances representing numbers        CPNumber
    median:           CPExpression instances representing numbers        CPNumber
    mode:             CPExpression instances representing numbers        CPArray     (returned array will contain all occurrences of the mode)
    stddev:           CPExpression instances representing numbers        CPNumber
    add:to:           CPExpression instances representing numbers        CPNumber
    from:subtract:    two CPExpression instances representing numbers    CPNumber
    multiply:by:      two CPExpression instances representing numbers    CPNumber
    divide:by:        two CPExpression instances representing numbers    CPNumber
    modulus:by:       two CPExpression instances representing numbers    CPNumber
    sqrt:             one CPExpression instance representing numbers     CPNumber
    log:              one CPExpression instance representing a number    CPNumber
    ln:               one CPExpression instance representing a number    CPNumber
    raise:toPower:    one CPExpression instance representing a number    CPNumber
    exp:              one CPExpression instance representing a number    CPNumber
    floor:            one CPExpression instance representing a number    CPNumber
    ceiling:          one CPExpression instance representing a number    CPNumber
    abs:              one CPExpression instance representing a number    CPNumber
    trunc:            one CPExpression instance representing a number    CPNumber
    uppercase:        one CPExpression instance representing a string    CPString
    lowercase:        one CPExpression instance representing a string    CPString
    random            none                                               CPNumber (integer)
    random:           one CPExpression instance representing a number    CPNumber (integer) such that 0 <= rand < param
    now               none                                               [CPDate now]
    bitwiseAnd:with:  two CPExpression instances representing numbers    CPNumber    (numbers will be treated as CPInteger)
    bitwiseOr:with:   two CPExpression instances representing numbers    CPNumber    (numbers will be treated as CPInteger)
    bitwiseXor:with:  two CPExpression instances representing numbers    CPNumber    (numbers will be treated as CPInteger)
    leftshift:by:     two CPExpression instances representing numbers    CPNumber    (numbers will be treated as CPInteger)
    rightshift:by:    two CPExpression instances representing numbers    CPNumber    (numbers will be treated as CPInteger)
    onesComplement:   one CPExpression instance representing a numbers   CPNumber    (numbers will be treated as CPInteger)
 @endverbatim

    This method raises an exception immediately if the selector is invalid; it raises an exception at runtime if the parameters are incorrect.
*/
+ (CPExpression)expressionForFunction:(CPString)function_name arguments:(CPArray)parameters
{
    return [[CPExpression_function alloc] initWithSelector:CPSelectorFromString(function_name) arguments:parameters];
}

/*!
    Returns an expression which will return the result of invoking on a given target a selector with a given name using given arguments.
    @param target A CPExpression object which will evaluate an object on which the selector identified by name may be invoked.
    @param function_name The name of the method to be invoked.
    @param parameters An array containing CPExpression objects which can be evaluated to provide parameters for the method specified by name.
    @return An expression which will return the result of invoking the selector named name on the result of evaluating the target expression with the parameters specified by evaluating the elements of parameters.
    See the description of expressionForFunction:arguments: for examples of how to construct the parameter array.
*/
+ (CPExpression)expressionForFunction:(CPExpression)target selectorName:(CPString)function_name arguments:(CPArray)parameters
{
    return [[CPExpression_function alloc] initWithTarget:target selector:CPSelectorFromString(function_name) arguments:parameters];
}

+ (CPExpression)expressionForSubquery:(CPExpression)expression usingIteratorVariable:(CPString)variable predicate:(CPPredicate)predicate
{
    return [[CPExpression_subquery alloc] initWithExpression:expression usingIteratorVariable:variable predicate:predicate];
}

// Getting Information About an Expression
/*!
    Returns the expression type for the receiver.
    @return The expression type for the receiver.
    This method raises an exception if it is not applicable to the receiver.
*/
- (int)expressionType
{
    return _type;
}

/*!
    Returns the constant value of the receiver.
    @return The constant value of the receiver.
    This method raises an exception if it is not applicable to the receiver.
*/
- (id)constantValue
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
    return nil;
}

/*!
    Returns the variable for the receiver.
    @return The variable for the receiver.
    This method raises an exception if it is not applicable to the receiver.
*/
- (CPString)variable
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
    return nil;
}

/*!
    Returns the key path for the receiver.
    @return The key path for the receiver.
    This method raises an exception if it is not applicable to the receiver.
*/
- (CPString)keyPath
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
    return nil;
}

/*!
    Returns the function for the receiver.
    @return The function for the receiver.
    This method raises an exception if it is not applicable to the receiver.
*/
- (CPString)function
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
    return nil;
}

/*!
    Returns the arguments for the receiver.
    @return The arguments for the receiver—that is, the array of expressions that will be passed as parameters during invocation of the selector on the operand of a function expression.
    This method raises an exception if it is not applicable to the receiver.
*/
- (CPArray)arguments
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
    return nil;
}

/*!
    Returns the collection of expressions in an aggregate expression, or the collection element of a subquery expression.
    @return The collection of expressions in an aggregate expression, or the collection element of a subquery expression.
    This method raises an exception if it is not applicable to the receiver.
*/
- (id)collection
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
    return nil;
}

/*!
    Returns the predicate in a subquery expression.
    @return The predicate in a subquery expression..
    This method raises an exception if it is not applicable to the receiver.
*/
- (CPPredicate)predicate
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
    return nil;
}

/*!
    Returns the operand for the receiver.
    @return The operand for the receiver—that is, the object on which the selector will be invoked.
    This method raises an exception if it is not applicable to the receiver.
*/
- (CPExpression)operand
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
    return nil;
}

/*!
    Returns the left expression of a set expression.
    @return The left expression of a set expression.
    This method raises an exception if it is not applicable to the receiver.
*/
- (CPExpression)leftExpression
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
    return nil;
}

/*!
    Returns the right expression of a set expression.
    @return The right expression of a set expression.
    This method raises an exception if it is not applicable to the receiver.
*/
- (CPExpression)rightExpression
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
    return nil;
}

- (CPExpression)_expressionWithSubstitutionVariables:(CPDictionary)variables
{
    return self;
}

@end

@import "CPExpression_constant.j"
@import "CPExpression_self.j"
@import "CPExpression_variable.j"
@import "CPExpression_keypath.j"
@import "CPExpression_function.j"
@import "CPExpression_aggregate.j"
@import "CPExpression_set.j"
@import "CPExpression_subquery.j"
