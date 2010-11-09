@import <Foundation/Foundation.j>

@implementation CPPredicateTest : OJTestCase
{
    CPDictionary dict;
}

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        var d,
            objects;

        dict = [[CPDictionary alloc] init];
        [dict setObject: @"Title" forKey:@"title"];

        var keys = [CPArray arrayWithObjects:@"Name",@"Age",@"Children"];
        objects = [CPArray arrayWithObjects:@"John",[CPNumber numberWithInt:34],[CPArray arrayWithObjects:@"Kid1", @"Kid2"]];

        d = [CPDictionary dictionaryWithObjects:objects forKeys:keys];
        [dict setObject:d forKey:@"Record1"];

        objects = [CPArray arrayWithObjects:@"Mary",[CPNumber numberWithInt:30],[CPArray arrayWithObjects:@"Kid1", @"Girl1"]];

        d = [CPDictionary dictionaryWithObjects:objects forKeys:keys];
        [dict setObject:d forKey:@"Record2"];

    }
    return self;
}

- (void)testExpressionsInit
{
    var expression_keypath = [CPExpression expressionForKeyPath:@"name"];
    [self assertNotNull:expression_keypath message:"KeyPath Expression should not be nil"];
    [self assertTrue:[expression_keypath keyPath] == @"name" message:"-keyPath should not be \"name\""];
    
    var expression_str = [CPExpression expressionForConstantValue:@"j[a-z]an"];
    [self assertNotNull:expression_str message:"ConstantValue Expression should not be nil"];

    var expression_num = [CPExpression expressionForConstantValue:[CPNumber numberWithInt:1]];
    [self assertNotNull:expression_num message:"ConstantValue Expression should not be nil"];

    var expression_collection = [CPExpression expressionForConstantValue:[CPArray arrayWithObjects:@"a",@"b",@"d"]];
    [self assertNotNull:expression_collection message:"ConstantValue Expression should not be nil"];

    var expression_var = [CPExpression expressionForVariable:@"variable"];
    [self assertNotNull:expression_var message:"Variable Expression should not be nil"];

    var expression_function = [CPExpression expressionForFunction:@"sum:" arguments:[CPArray arrayWithObjects:expression_num,expression_num]];
    [self assertNotNull:expression_function message:"Function Expression should not be nil"];

    expression_function = [CPExpression expressionForFunction:expression_num selectorName:@"isEqual:" arguments:[CPArray arrayWithObjects:expression_num]];
    [self assertNotNull:expression_function message:"Function Expression with target and selector  should not be nil"];

    var expression_self = [CPExpression expressionForEvaluatedObject];
    [self assertNotNull:expression_self message:"Self Expression should not be nil"];

    var expression_aggregate = [CPExpression expressionForAggregate:[CPArray arrayWithObjects:expression_str,expression_num]];
    [self assertNotNull:expression_aggregate message:"Aggregate Expression should not be nil"];

    var expression_subquery = [CPExpression expressionForSubquery:expression_collection usingIteratorVariable:@"self" predicate:[CPPredicate predicateWithValue:YES]];
    [self assertNotNull:expression_subquery message:"Subquery Expression should not be nil"];

    var set = [CPExpression expressionForConstantValue:[CPSet setWithObjects:@"a",@"b",@"c"]];
    var array = [CPExpression expressionForConstantValue:[CPArray arrayWithObjects:@"a",@"b",@"d"]];

    var expression_intersect = [CPExpression expressionForIntersectSet:set with:array];
    [self assertNotNull:expression_intersect message:"IntersectSet Expression should not be nil"];

    var expression_unionset = [CPExpression expressionForUnionSet:set with:array];
    [self assertNotNull:expression_unionset message:"UnionSet Expression should not be nil"];

    var expression_minusset = [CPExpression expressionForMinusSet:set with:array];
    [self assertNotNull:expression_minusset message:"MinusSet Expression should not be nil"];
}

- (void)testSetExpressionEvaluation
{
    var left = [CPExpression expressionForConstantValue:[CPSet setWithObjects:@"a",@"b",@"c"]];
    var right = [CPExpression expressionForConstantValue:[CPArray arrayWithObjects:@"a",@"b",@"d"]];

    var expression = [CPExpression expressionForIntersectSet:left with:right];
    var eval = [[expression expressionValueWithObject:nil context:nil] constantValue];
    [self assertTrue:[eval isEqualToSet:[CPSet setWithObjects:@"a",@"b"]] message:"Result should be {(a, b)}, is " + eval];

    expression = [CPExpression expressionForUnionSet:left with:right];
    eval = [[expression expressionValueWithObject:nil context:nil] constantValue];
    [self assertTrue:[eval isEqualToSet:[CPSet setWithObjects:@"a",@"b",@"c",@"d"]] message:"Result should be {(a, b, c, d)}, is " + eval];
    
    expression = [CPExpression expressionForMinusSet:left with:right];
    eval = [[expression expressionValueWithObject:nil context:nil] constantValue];
    [self assertTrue:[eval isEqualToSet:[CPSet setWithObjects:@"c"]] message:"Result should be {(c)}, is " + eval];
}

- (void)testFunctionExpressionEvaluation
{
    var expression = [CPExpression expressionForConstantValue:[1,2,3]];
    var function_exp = [CPExpression expressionForFunction:"sum:" arguments:[expression]];

    var pred = [[CPComparisonPredicate alloc] initWithLeftExpression:function_exp rightExpression:[CPExpression expressionForConstantValue:6] modifier:CPDirectPredicateModifier type:CPEqualToPredicateOperatorType options:0];
    [self assertTrue:[pred evaluateWithObject:nil] message:[pred description] + " should be true"];
    
    var operand = [CPExpression expressionForConstantValue:@"text"];
    var arg = [CPExpression expressionForConstantValue:2];
    function_exp = [CPExpression expressionForFunction:operand selectorName:@"substringFromIndex:" arguments:[arg]];
    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:function_exp rightExpression:[CPExpression expressionForConstantValue:@"xt"] modifier:CPDirectPredicateModifier type:CPEqualToPredicateOperatorType options:0];
    [self assertTrue:[pred evaluateWithObject:nil] message:[pred description] + " should be true"];
}

- (void)testVariableExpressionEvaluation
{
// Replace with constant
    var expression = [CPExpression expressionForVariable:@"variable"],
        bindings = [CPDictionary dictionaryWithObject:20 forKey:@"variable"],
        eval = [expression expressionValueWithObject:@"variable" context:bindings];    
    [self assertTrue:(eval == 20) message:"'"+ eval  + "' should be 20"];

// Replace with constant expression
    bindings = [CPDictionary dictionaryWithObject:[CPExpression expressionForConstantValue:10] forKey:@"variable"];
    eval = [expression expressionValueWithObject:nil context:bindings];
    [self assertTrue:(eval == 10) message:"'"+ eval  + "' should be 10"];

// Replace with keypath expression
    bindings = [CPDictionary dictionaryWithObject:[CPExpression expressionForKeyPath:@"Record1.Age"] forKey:@"variable"];
    eval = [expression expressionValueWithObject:dict context:bindings];
    [self assertTrue:(eval == 34) message:"'"+ eval  + "' should be 34"];
}

- (void)testSubqueryExpressionEvaluation
{
    var collection = [CPExpression expressionForKeyPath:@"Record1.Children"],
        iteratorVariable = @"x",    
        predicate = [CPPredicate predicateWithFormat:@"$x BEGINSWITH 'Kid'"];
    
    var expression = [CPExpression expressionForSubquery:collection usingIteratorVariable:iteratorVariable predicate:predicate];
    
    var eval = [expression expressionValueWithObject:dict context:nil];
    var expected = [CPArray arrayWithObjects:"Kid1", "Kid2"];
    [self assertTrue:([eval isEqual:expected]) message:"'"+ [expression predicateFormat]  + "' result is "+ eval + "but should be " + expected];
}

- (void)testOptions
{
    var pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:@"àa"] rightExpression:[CPExpression expressionForConstantValue:@"aà"] modifier:CPDirectPredicateModifier type:CPLikePredicateOperatorType options:3];
    [self assertTrue:[pred evaluateWithObject:nil] message:"/"+ [pred description]  + "/ should be true"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:@"aB"] rightExpression:[CPExpression expressionForConstantValue:@"Ab"] modifier:CPDirectPredicateModifier type:CPLikePredicateOperatorType options:1];
    [self assertTrue:[pred evaluateWithObject:nil] message:"/"+ [pred description]  + "/ should be true"];
}

- (void)testModifier
{
    var pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record2.Children"] rightExpression:[CPExpression expressionForConstantValue:@"Gi"] modifier:CPAnyPredicateModifier type:CPBeginsWithPredicateOperatorType options:0];
    [self assertTrue:[pred evaluateWithObject:dict] message:"'"+ [pred description]  + "' should be true"];

        pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Children"] rightExpression:[CPExpression expressionForConstantValue:@"Kid"] modifier:CPAllPredicateModifier type:CPBeginsWithPredicateOperatorType options:0];
    [self assertTrue:[pred evaluateWithObject:dict] message:"'"+ [pred description]  + "' should be true"];
}

- (void)testOperators
{
    var pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:"Farenight 451"] rightExpression:[CPExpression expressionForConstantValue:"(F|g)\\w+\\s\\d{3}"] modifier:CPDirectPredicateModifier type:CPMatchesPredicateOperatorType options:2];
   [self assertTrue:[pred evaluateWithObject:nil] message:"'"+ [pred description]  + "' should be true"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:@"b"] rightExpression:[CPExpression expressionForConstantValue:@"[a-c]"] modifier:CPDirectPredicateModifier type:CPLikePredicateOperatorType options:1];
   [self assertTrue:[pred evaluateWithObject:nil] message:"'"+ [pred description]  + "' should be true"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:@"Aa"] rightExpression:[CPExpression expressionForConstantValue:@"ab"] modifier:CPDirectPredicateModifier type:CPLessThanPredicateOperatorType options:0];
   [self assertTrue:[pred evaluateWithObject:nil] message:"'"+ [pred description]  + "' should be true"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:@"Ac"] rightExpression:[CPExpression expressionForConstantValue:@"ab"] modifier:CPDirectPredicateModifier type:CPLessThanPredicateOperatorType options:2];
   [self assertTrue:[pred evaluateWithObject:nil] message:"'"+ [pred description]  + "' should be true"];

}

- (void)testCompoundPredicate
{
    var predOne = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Name"] rightExpression:[CPExpression expressionForConstantValue:@"J"] modifier:CPDirectPredicateModifier type:CPBeginsWithPredicateOperatorType options:0];

    var predTwo = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Age"] rightExpression:[CPExpression expressionForConstantValue:[CPNumber numberWithInt:40]] modifier:CPDirectPredicateModifier type:CPLessThanPredicateOperatorType options:0];

    var pred = [[CPCompoundPredicate alloc] initWithType:CPAndPredicateType subpredicates:[CPArray arrayWithObjects:predOne,predTwo]];

    [self assertTrue:[pred evaluateWithObject:dict] message:"'"+ [pred description]  + "' should be true"];
}

- (void)testNilComparisons
{
// Custom Selector Predicate
    var pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Name"] rightExpression:[CPExpression expressionForConstantValue:nil] customSelector:@selector(yes:)];

    [self assertTrue:[pred evaluateWithObject:dict] message:"'"+ [pred description]  + "' should be true"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:nil] rightExpression:[CPExpression expressionForConstantValue:nil] customSelector:@selector(yes:)];

    [self assertFalse:[pred evaluateWithObject:dict] message:"'"+ [pred description]  + "' should be false"];
        
    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Name"] rightExpression:[CPExpression expressionForConstantValue:nil] modifier:CPDirectPredicateModifier type:CPBeginsWithPredicateOperatorType options:0];
    
    [self assertFalse:[pred evaluateWithObject:dict] message:"'"+ [pred description]  + "' should be false"];

// Predicates with operators
    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Age"] rightExpression:[CPExpression expressionForConstantValue:nil] modifier:CPDirectPredicateModifier type:CPGreaterThanPredicateOperatorType options:0];

    [self assertFalse:[pred evaluateWithObject:dict] message:"'"+ [pred description]  + "' should be false"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:nil] rightExpression:[CPExpression expressionForConstantValue:nil] modifier:CPDirectPredicateModifier type:CPGreaterThanOrEqualToPredicateOperatorType options:0];

    [self assertTrue:[pred evaluateWithObject:dict] message:"'"+ [pred description]  + "' should be true"];
    
    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:nil] rightExpression:[CPExpression expressionForConstantValue:nil] modifier:CPDirectPredicateModifier type:CPBeginsWithPredicateOperatorType options:0];
    
    [self assertFalse:[pred evaluateWithObject:dict] message:"'"+ [pred description]  + "' should be false"];
}

- (void)testPredicateParsing
{
    var predicate;
// TEST String
    predicate = [CPPredicate predicateWithFormat: @"%K == %@", @"Record1.Name", @"John"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"%K MATCHES[c] %@", @"Record1.Name", @"john"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"%K BEGINSWITH %@", @"Record1.Name", @"Jo"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"(%K == %@) AND (%K == %@)", @"Record1.Name", @"John", @"Record2.Name", @"Mary"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

// TEST integer
    predicate = [CPPredicate predicateWithFormat: @"%K == %d", @"Record1.Age", 34];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"%K < %d", @"Record1.Age", 40];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"%K BETWEEN %@", @"Record1.Age", [CPArray arrayWithObjects:[CPNumber numberWithInt: 20], [CPNumber numberWithInt:40]]];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"Record1.Age BETWEEN {%f,%f}", 20, 40];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"(%K == %d) OR (%K == %d)", @"Record1.Age", 34, @"Record2.Age", 34];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

// TEST float
    predicate = [CPPredicate predicateWithFormat: @"%K < %f", @"Record1.Age", 40.5];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"%f > %K", 40.5, @"Record1.Age"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

// TEST KeyPath
    predicate = [CPPredicate predicateWithFormat: @"%@ IN %K", @"Kid1", @"Record1.Children"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"%K CONTAINS %@", @"Record1.Children", @"Kid1"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"ANY %K == %@", @"Record2.Children", @"Girl1"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

// Test Aggregate
    predicate = [CPPredicate predicateWithFormat:@"{Record1 .Name, Record1.Age} = {'John',34}"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

// Test Symbolic token
    predicate = [CPPredicate predicateWithFormat:@"Record1.Children[FIRST] = 'Kid1'"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];
    
    predicate = [CPPredicate predicateWithFormat:@"Record1.Children[1] = 'Kid2'"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

// Test arithm
    var n = 2;
    predicate = [CPPredicate predicateWithFormat:@"SELF +1 = 3"];
    [self assertTrue:[predicate evaluateWithObject:n] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat:@"SELF- 1 = 1"];
    [self assertTrue:[predicate evaluateWithObject:n] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat:@"SELF / 2 = 1"];
    [self assertTrue:[predicate evaluateWithObject:n] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat:@"SELF / 2 = 1"];
    [self assertTrue:[predicate evaluateWithObject:n] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat:@"SELF* 2 = 4"];
    [self assertTrue:[predicate evaluateWithObject:n] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat:@"SELF** 3 = 8"];
    [self assertTrue:[predicate evaluateWithObject:n] message:[predicate description] + " should be true"];

// TEST Operator type    
    predicate = [CPPredicate predicateWithFormat: @"a CONTAINS[c] \"b\""];
    [self assertTrue:([predicate predicateOperatorType] == CPContainsPredicateOperatorType) message:[predicate description] + " operator should be a CPContainsPredicateOperatorType"];
    
    predicate = [CPPredicate predicateWithFormat: @"a BETWEEN {%f,%f}", 20, 40];
    [self assertTrue:([predicate predicateOperatorType] == CPBetweenPredicateOperatorType) message:[predicate description] + " operator should be a CPBetweenPredicateOperatorType"];

// TEST Empty string
    predicate = [CPPredicate predicateWithFormat: @"a CONTAINS \"\""];
    [self assertNotNull:predicate message:[predicate description] + " should not be nil"];
    
// TEST variable
    predicate = [CPPredicate predicateWithFormat: @"$x CONTAINS \"\""];
    [self assertTrue:[[predicate leftExpression] expressionType] == CPVariableExpressionType message:"Left Expression should be a CPVariableExpressionType"];
/*
  Variable in multiple paths will fail. Left exp should be FUNCTION(keyPathExp"keypath", valueForKey:, variableExp"variable")
    predicate = [CPPredicate predicateWithFormat: @"keypath.$variable CONTAINS \"\""];
  var type = [[predicate leftExpression] expressionType];
    [self assertTrue: type == CPFunctionExpressionType message:"Left Expression should be a CPFunctionExpressionType is " + type];
*/
}

@end

@implementation CPObject (PredicateTesting)

- (BOOL)yes:(id)object
{
    return YES;
}

@end
